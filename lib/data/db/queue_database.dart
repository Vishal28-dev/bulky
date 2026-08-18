import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/app_paths.dart';
import 'queue_tables.dart';

part 'queue_database.g.dart';

@DriftDatabase(tables: [QueueJobs, AppSettings])
class QueueDatabase extends _$QueueDatabase {
  QueueDatabase({required AppPaths paths})
      : super(
          driftDatabase(
            name: 'bulky_queue',
            native: DriftNativeOptions(
              databasePath: () async => paths.databaseFile.path,
            ),
          ),
        );

  QueueDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(queueJobs, queueJobs.scheduledFor);
            await m.addColumn(queueJobs, queueJobs.rescheduleCount);
            await m.addColumn(queueJobs, queueJobs.publishedAt);
          }
        },
      );

  Stream<List<QueueJob>> watchJobs() {
    return (select(queueJobs)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
  }

  Future<List<QueueJob>> allJobs() => select(queueJobs).get();

  Future<QueueJob?> jobById(String id) {
    return (select(queueJobs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<QueueJob?> jobByIdempotency(String key) {
    return (select(queueJobs)..where((t) => t.idempotencyKey.equals(key))).getSingleOrNull();
  }

  Future<QueueJob?> nextPending() {
    return (select(queueJobs)
          ..where((t) => t.status.equals(JobStatus.pending))
          ..orderBy([
            (t) => OrderingTerm.asc(t.scheduledFor),
            (t) => OrderingTerm.asc(t.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<QueueJob>> inFlight() {
    return (select(queueJobs)
          ..where(
            (t) =>
                t.status.equals(JobStatus.preparing) |
                t.status.equals(JobStatus.stitching) |
                t.status.equals(JobStatus.uploading) |
                t.status.equals(JobStatus.publishing),
          ))
        .get();
  }

  Future<void> insertJob(QueueJobsCompanion row) => into(queueJobs).insert(row);

  Future<void> updateJob(String id, QueueJobsCompanion row) {
    return (update(queueJobs)..where((t) => t.id.equals(id))).write(
      row.copyWith(updatedAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<int> cancelPending() {
    return (update(queueJobs)..where((t) => t.status.equals(JobStatus.pending))).write(
      QueueJobsCompanion(
        status: const Value(JobStatus.skipped),
        stageLabel: const Value('Cancelled'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<String?> setting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> clearAccountSettings() async {
    await (delete(appSettings)
          ..where((t) =>
              t.key.equals(SettingKeys.accountId) |
              t.key.equals(SettingKeys.accountUsername)))
        .go();
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  /// Count of jobs currently parked as [JobStatus.scheduled] — the batch/day
  /// and within-day offset for a newly-scheduled job are derived from this
  /// count rather than a separate counter, so they can never drift out of
  /// sync with what's actually persisted.
  Future<int> scheduledJobCount() async {
    final count = countAll(filter: queueJobs.status.equals(JobStatus.scheduled));
    final query = selectOnly(queueJobs)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Scheduled jobs whose [QueueJobs.scheduledFor] has already passed —
  /// candidates for the reconciliation sweep to check against Zernio.
  Future<List<QueueJob>> dueScheduledJobs() {
    final now = DateTime.now().toUtc();
    return (select(queueJobs)
          ..where((t) => t.status.equals(JobStatus.scheduled) & t.scheduledFor.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledFor)]))
        .get();
  }

  Future<DateTime?> latestAssignedSlot() async {
    final rows = await (select(queueJobs)
          ..where(
            (t) =>
                t.scheduledFor.isNotNull() &
                (t.status.equals(JobStatus.pending) |
                    t.status.equals(JobStatus.preparing) |
                    t.status.equals(JobStatus.stitching) |
                    t.status.equals(JobStatus.uploading) |
                    t.status.equals(JobStatus.publishing) |
                    t.status.equals(JobStatus.scheduled)),
          ))
        .get();
    DateTime? latest;
    for (final row in rows) {
      final slot = row.scheduledFor;
      if (slot == null) continue;
      if (latest == null || slot.isAfter(latest)) latest = slot;
    }
    return latest?.toUtc();
  }

  Future<int> activeScheduledCount() async {
    final rows = await (select(queueJobs)
          ..where(
            (t) =>
                t.status.equals(JobStatus.pending) |
                t.status.equals(JobStatus.preparing) |
                t.status.equals(JobStatus.stitching) |
                t.status.equals(JobStatus.uploading) |
                t.status.equals(JobStatus.publishing) |
                t.status.equals(JobStatus.scheduled),
          ))
        .get();
    return rows.length;
  }

  Future<Set<int>> slotsAlreadyOnNuke() async {
    final rows = await (select(queueJobs)
          ..where(
            (t) =>
                t.scheduledFor.isNotNull() &
                t.zernioPostId.isNotNull() &
                t.zernioPostId.equals('').not() &
                (t.status.equals(JobStatus.scheduled) | t.status.equals(JobStatus.publishing)),
          ))
        .get();
    return {
      for (final row in rows)
        if (row.scheduledFor != null) row.scheduledFor!.toUtc().millisecondsSinceEpoch,
    };
  }

  /// Jobs still on the local grid that have not been created on Nuke yet.
  Future<List<QueueJob>> unpublishedActiveJobs() {
    return (select(queueJobs)
          ..where(
            (t) =>
                (t.status.equals(JobStatus.pending) |
                    t.status.equals(JobStatus.preparing) |
                    t.status.equals(JobStatus.stitching) |
                    t.status.equals(JobStatus.uploading) |
                    t.status.equals(JobStatus.publishing) |
                    t.status.equals(JobStatus.scheduled)) &
                (t.zernioPostId.isNull() | t.zernioPostId.equals('')),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.scheduledFor),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }
}

class JobStatus {
  static const pending = 'pending';
  static const preparing = 'preparing';
  static const stitching = 'stitching';
  static const uploading = 'uploading';
  static const publishing = 'publishing';
  static const published = 'published';
  static const failed = 'failed';
  static const skipped = 'skipped';
  static const scheduled = 'scheduled';
}

class SettingKeys {
  static const accountId = 'accountId';
  static const accountUsername = 'accountUsername';
  static const visibility = 'visibility';
  static const lastFolder = 'lastFolder';
  static const paused = 'paused';
  // YouTube global settings
  static const ytCategoryId = 'ytCategoryId';
  static const ytPlaylistId = 'ytPlaylistId';
  static const ytFirstComment = 'ytFirstComment';
  static const ytMadeForKids = 'ytMadeForKids';
  static const ytContainsAI = 'ytContainsAI';
  // First slot of the current schedule chain (ISO8601 UTC) = folder-add + 15 min.
  static const scheduleOrigin = 'scheduleOrigin';
}

class MediaKind {
  static const video = 'video';
  static const sphericalVideo = 'spherical_video';
  static const image = 'image';
  static const insv = 'insv';
  static const insp = 'insp';
}
