import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../core/keep_awake.dart';
import '../../core/logger.dart';
import '../../data/db/queue_database.dart';
import '../../data/nuke/nuke_api_client.dart';
import '../../data/nuke/nuke_models.dart';
import '../media/folder_scanner.dart';
import '../media/media_classifier.dart';
import '../media/media_preparer.dart';

/// Slot [index] on the fixed grid: [cap] videos per 24h window, spaced
/// [interval] apart, starting at [origin] (first video = origin = folder-add + 15 min).
DateTime packedScheduleSlot({
  required int index,
  required DateTime origin,
  required int cap,
  Duration interval = AppConfig.scheduleSlotInterval,
}) {
  final safeCap = cap < 1 ? 1 : cap;
  return origin.add(Duration(hours: 24 * (index ~/ safeCap))).add(interval * (index % safeCap));
}

class EnqueueResult {
  const EnqueueResult({required this.added, this.firstSlot});
  final int added;
  final DateTime? firstSlot;
  bool get isEmpty => added == 0;
}

class QueueWorker {
  QueueWorker({
    required this.db,
    required this.preparer,
    required this.apiClientProvider,
    required this.accountIdProvider,
  });

  final QueueDatabase db;
  final MediaPreparer preparer;
  final NukeApiClient? Function() apiClientProvider;
  final Future<String?> Function() accountIdProvider;

  bool _running = false;
  bool _processing = false;
  Completer<void>? _pauseGate;
  Timer? _sweepTimer;
  bool _sweeping = false;

  bool get isPaused => _pauseGate != null;

  void updateApiClient(NukeApiClient api) {
    if (isPaused) {
      _pauseGate?.complete();
      _pauseGate = null;
    }
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await recoverInFlight();
    unawaited(reconcileScheduled());
    _sweepTimer = Timer.periodic(AppConfig.scheduleSweepInterval, (_) => unawaited(reconcileScheduled()));
    unawaited(_loop());
  }

  Future<void> stop() async {
    _running = false;
    _sweepTimer?.cancel();
    _sweepTimer = null;
  }

  Future<void> setPaused(bool paused) async {
    await db.setSetting(SettingKeys.paused, paused ? '1' : '0');
    if (paused) {
      _pauseGate ??= Completer<void>();
    } else {
      _pauseGate?.complete();
      _pauseGate = null;
    }
  }

  Future<void> recoverInFlight() async {
    final paused = await db.setting(SettingKeys.paused);
    if (paused == '1') {
      _pauseGate ??= Completer<void>();
    }
    final inflight = await db.inFlight();
    for (final job in inflight) {
      appLog.info('Recovering job ${job.id} status=${job.status}');
      if (job.zernioPostId != null && job.zernioPostId!.isNotEmpty) {
        await db.updateJob(
          job.id,
          QueueJobsCompanion(
            status: const Value(JobStatus.scheduled),
            stageLabel: const Value('Scheduled'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      } else {
        final prepared = job.preparedPath;
        if (prepared != null && prepared.contains('.partial.') && File(prepared).existsSync()) {
          await File(prepared).delete();
        }
        await db.updateJob(
          job.id,
          QueueJobsCompanion(
            status: const Value(JobStatus.pending),
            progress: const Value(0),
            stageLabel: const Value('Queued'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    }
  }

  Future<List<ClassifiedMedia>> scanAndValidate(String folderPath) async {
    final classified = scanFolder(ScanRequest(folderPath));
    final out = <ClassifiedMedia>[];
    for (final item in classified) {
      if (item.skipped || item.kind != MediaKind.video) {
        out.add(item);
        continue;
      }
      final reason = await _noVideoStreamReason(item.primaryPath);
      out.add(
        reason == null
            ? item
            : ClassifiedMedia(
                primaryPath: item.primaryPath,
                pairedPath: item.pairedPath,
                kind: item.kind,
                size: item.size,
                mtime: item.mtime,
                title: item.title,
                idempotencyKey: item.idempotencyKey,
                skipReason: reason,
              ),
      );
    }
    return out;
  }

  Future<String?> _noVideoStreamReason(String path) async {
    try {
      final streams = await preparer.ffmpeg.probeVideoStreams(path);
      if (streams.isEmpty) {
        return 'No video track found — likely an audio-only download fragment, not a real video.';
      }
    } catch (e) {
      appLog.warning('Video stream probe failed for $path: $e');
    }
    return null;
  }

  Future<EnqueueResult> enqueueClassified(String folderPath, List<ClassifiedMedia> classified) async {
    var added = 0;
    final now = DateTime.now().toUtc();
    final newIds = <String>[];
    for (final item in classified) {
      final existing = await db.jobByIdempotency(item.idempotencyKey);
      if (existing != null) continue;
      final id = const Uuid().v4();
      await db.insertJob(
        QueueJobsCompanion.insert(
          id: id,
          sourcePath: item.primaryPath,
          pairedPath: Value(item.pairedPath),
          fileSize: item.size,
          mtime: item.mtime,
          idempotencyKey: item.idempotencyKey,
          mediaKind: item.kind,
          status: item.skipped ? JobStatus.skipped : JobStatus.pending,
          stageLabel: Value(item.skipped ? item.skipReason! : 'Queued'),
          errorMessage: Value(item.skipReason),
          title: item.title,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!item.skipped) {
        newIds.add(id);
        added++;
      }
    }
    await db.setSetting(SettingKeys.lastFolder, folderPath);
    DateTime? firstSlot;
    if (newIds.isNotEmpty) {
      firstSlot = await _assignSlots(newIds);
    }
    return EnqueueResult(added: added, firstSlot: firstSlot);
  }

  Future<EnqueueResult> enqueueFolder(String folderPath) async {
    final classified = await scanAndValidate(folderPath);
    return enqueueClassified(folderPath, classified);
  }

  Future<DateTime> _origin() async {
    final active = await db.activeScheduledCount();
    final raw = await db.setting(SettingKeys.scheduleOrigin);
    final parsed = raw == null || raw.isEmpty ? null : DateTime.tryParse(raw)?.toUtc();
    if (active > 0 && parsed != null) return parsed;
    final origin = DateTime.now().toUtc().add(AppConfig.scheduleFirstLead);
    await db.setSetting(SettingKeys.scheduleOrigin, origin.toIso8601String());
    return origin;
  }

  Future<DateTime> _assignSlots(List<String> jobIds) async {
    final origin = await _origin();
    final latest = await db.latestAssignedSlot();
    var index = 0;
    if (latest != null) {
      while (true) {
        final slot = packedScheduleSlot(index: index, origin: origin, cap: AppConfig.dailyCap);
        if (slot.isAfter(latest.toUtc())) break;
        index++;
        if (index > 100000) break;
      }
    }
    DateTime? first;
    for (final id in jobIds) {
      final slot = packedScheduleSlot(index: index, origin: origin, cap: AppConfig.dailyCap);
      first ??= slot;
      await db.updateJob(
        id,
        QueueJobsCompanion(
          scheduledFor: Value(slot),
          stageLabel: Value('Queued for ${_slotLabel(slot)}'),
        ),
      );
      index++;
    }
    return first ?? origin;
  }

  Future<void> _loop() async {
    while (_running) {
      if (_pauseGate != null) {
        await _pauseGate!.future;
      }
      if (_processing) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }
      final job = await db.nextPending();
      if (job == null) {
        await KeepAwake.disable();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      if (apiClientProvider() == null) {
        await setPaused(true);
        await KeepAwake.disable();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      _processing = true;
      await KeepAwake.enable();
      try {
        await _process(job);
      } catch (e, st) {
        appLog.warning('Job ${job.id} failed', e, st);
        await db.updateJob(
          job.id,
          QueueJobsCompanion(
            status: const Value(JobStatus.failed),
            errorMessage: Value(e.toString()),
            stageLabel: const Value('Failed'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      } finally {
        _processing = false;
      }
    }
  }

  Future<void> _process(QueueJob job) async {
    final client = apiClientProvider();
    if (client == null) throw StateError('Nuke API client not available.');

    final accountId = await accountIdProvider();
    if (accountId == null || accountId.isEmpty) {
      throw StateError('YouTube is not connected.');
    }

    await db.updateJob(
      job.id,
      QueueJobsCompanion(
        status: const Value(JobStatus.preparing),
        stageLabel: const Value('Checking YouTube account…'),
        progress: const Value(1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );

    final health = await client.accountHealth(accountId);
    if (!health.canPost) {
      await setPaused(true);
      await db.updateJob(
        job.id,
        QueueJobsCompanion(
          status: const Value(JobStatus.pending),
          stageLabel: const Value('Paused — reconnect YouTube'),
          errorMessage: Value(
            'YouTube cannot post right now. Reconnect the channel. ${health.errorMessage ?? ''}'.trim(),
          ),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      return;
    }

    var publicUrl = job.publicUrl;
    if (publicUrl == null || publicUrl.isEmpty) {
      publicUrl = await _prepareAndUpload(job, client);
    }

    final slot = await _usableSlot(job);
    await db.updateJob(
      job.id,
      QueueJobsCompanion(
        publicUrl: Value(publicUrl),
        scheduledFor: Value(slot),
        status: const Value(JobStatus.publishing),
        stageLabel: Value('Scheduling for ${_slotLabel(slot)}…'),
        progress: const Value(100),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );

    final visibility = await db.setting(SettingKeys.visibility) ?? 'unlisted';
    final categoryId = await db.setting(SettingKeys.ytCategoryId);
    final playlistId = await db.setting(SettingKeys.ytPlaylistId);
    final firstComment = await db.setting(SettingKeys.ytFirstComment);
    final madeForKids = await db.setting(SettingKeys.ytMadeForKids) == '1';
    final containsAI = await db.setting(SettingKeys.ytContainsAI) == '1';

    NukePost post;
    try {
      post = await client.createYouTubePost(
        accountId: accountId,
        title: job.title,
        publicUrl: publicUrl,
        visibility: visibility,
        requestId: job.idempotencyKey,
        categoryId: categoryId,
        playlistId: playlistId,
        firstComment: firstComment,
        madeForKids: madeForKids,
        containsSyntheticMedia: containsAI,
        scheduledFor: slot,
      );
    } on NukeException catch (e) {
      if (e.isDuplicate) {
        final existing = e.existingPostId != null && e.existingPostId!.isNotEmpty
            ? await client.getPost(e.existingPostId!)
            : await client.findPostByMediaUrl(publicUrl);
        if (existing == null) rethrow;
        post = await client.reschedulePost(postId: existing.id, scheduledFor: slot);
      } else {
        rethrow;
      }
    }

    await db.updateJob(
      job.id,
      QueueJobsCompanion(
        zernioPostId: Value(post.id),
        publicUrl: Value(publicUrl),
        status: const Value(JobStatus.scheduled),
        scheduledFor: Value(slot),
        stageLabel: Value('Scheduled · ${_slotLabel(slot)}'),
        errorMessage: const Value(null),
        progress: const Value(100),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<String> _prepareAndUpload(QueueJob job, NukeApiClient client) async {
    final needsStitch = job.mediaKind == MediaKind.insv || job.mediaKind == MediaKind.insp;
    await db.updateJob(
      job.id,
      QueueJobsCompanion(
        status: Value(needsStitch ? JobStatus.stitching : JobStatus.preparing),
        stageLabel: Value(needsStitch ? 'Stitching 360°…' : 'Preparing…'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );

    final prepared = await preparer.prepare(
      job: job,
      onProgress: (progress, label) {
        unawaited(
          db.updateJob(
            job.id,
            QueueJobsCompanion(
              progress: Value(progress),
              stageLabel: Value(label),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          ),
        );
      },
    );

    await db.updateJob(
      job.id,
      QueueJobsCompanion(
        preparedPath: Value(prepared.path),
        status: const Value(JobStatus.uploading),
        stageLabel: const Value('Uploading…'),
        progress: const Value(0),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );

    final presign = await client.presign(
      filename: _uploadName(job, prepared.path),
      contentType: prepared.contentType,
      size: prepared.size,
    );

    await StreamUploader.putFile(
      uploadUrl: presign.uploadUrl,
      file: File(prepared.path),
      contentType: prepared.contentType,
      onProgress: (sent, total) {
        final pct = total == 0 ? 0 : ((sent / total) * 100).round();
        unawaited(
          db.updateJob(
            job.id,
            QueueJobsCompanion(
              progress: Value(pct),
              stageLabel: Value('Uploading $pct%'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          ),
        );
      },
    );
    return presign.publicUrl;
  }

  /// Prefer the slot assigned at enqueue. If that time is already too close
  /// for Nuke's 5-minute rule, slide this job and every later unpublished
  /// job forward on the same 15-minute grid so nothing is dumped to the end.
  Future<DateTime> _usableSlot(QueueJob job) async {
    final minOk = DateTime.now().toUtc().add(AppConfig.scheduleMinLead);
    final slot = job.scheduledFor?.toUtc();
    if (slot != null && slot.isAfter(minOk)) return slot;
    return _repackUnpublished(preferFirst: job.id, minOk: minOk);
  }

  Future<DateTime> _repackUnpublished({required String preferFirst, required DateTime minOk}) async {
    final origin = await _origin();
    final locked = await db.slotsAlreadyOnNuke();
    final movable = await db.unpublishedActiveJobs();
    movable.sort((a, b) {
      if (a.id == preferFirst) return -1;
      if (b.id == preferFirst) return 1;
      final sa = a.scheduledFor;
      final sb = b.scheduledFor;
      if (sa != null && sb != null) return sa.compareTo(sb);
      return a.createdAt.compareTo(b.createdAt);
    });
    var index = 0;
    DateTime? preferred;
    for (final j in movable) {
      late DateTime candidate;
      while (index < 100000) {
        candidate = packedScheduleSlot(index: index, origin: origin, cap: AppConfig.dailyCap);
        index++;
        if (candidate.isAfter(minOk) && !locked.contains(candidate.millisecondsSinceEpoch)) break;
      }
      await db.updateJob(
        j.id,
        j.status == JobStatus.pending
            ? QueueJobsCompanion(
                scheduledFor: Value(candidate),
                stageLabel: Value('Queued for ${_slotLabel(candidate)}'),
              )
            : QueueJobsCompanion(scheduledFor: Value(candidate)),
      );
      if (j.id == preferFirst) preferred = candidate;
    }
    return preferred ?? DateTime.now().toUtc().add(AppConfig.scheduleFirstLead);
  }

  Future<void> reconcileScheduled() async {
    if (_sweeping) return;
    _sweeping = true;
    try {
      final client = apiClientProvider();
      if (client == null) return;
      final due = await db.dueScheduledJobs();
      for (final job in due) {
        final postId = job.zernioPostId;
        if (postId == null || postId.isEmpty) continue;
        NukePost post;
        try {
          post = await client.getPost(postId);
        } catch (e) {
          appLog.warning('reconcileScheduled: getPost failed for job ${job.id}: $e');
          continue;
        }
        if (post.isPublished) {
          await db.updateJob(
            job.id,
            QueueJobsCompanion(
              status: const Value(JobStatus.published),
              stageLabel: const Value('Published ✓'),
              youtubeUrl: Value(post.platformPostUrl),
              publishedAt: Value(post.publishedAt ?? DateTime.now().toUtc()),
              progress: const Value(100),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        } else if (post.isFailed) {
          await db.updateJob(
            job.id,
            QueueJobsCompanion(
              status: const Value(JobStatus.failed),
              errorMessage: Value(post.errorMessage),
              stageLabel: const Value('Failed'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      }
    } finally {
      _sweeping = false;
    }
  }

  String _uploadName(QueueJob job, String preparedPath) {
    final ext = preparedPath.contains('.') ? preparedPath.split('.').last : 'mp4';
    return '${job.title}.$ext';
  }

  static String _slotLabel(DateTime slot) {
    final local = slot.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day} $hour:$minute $ampm';
  }
}
