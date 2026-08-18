import 'package:drift/drift.dart';

class QueueJobs extends Table {
  TextColumn get id => text()();
  TextColumn get sourcePath => text()();
  TextColumn get pairedPath => text().nullable()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get mtime => dateTime()();
  TextColumn get idempotencyKey => text()();
  TextColumn get mediaKind => text()();
  TextColumn get status => text()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get stageLabel => text().withDefault(const Constant(''))();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get zernioPostId => text().nullable()();
  TextColumn get youtubeUrl => text().nullable()();
  TextColumn get preparedPath => text().nullable()();
  TextColumn get publicUrl => text().nullable()();
  TextColumn get title => text()();
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get scheduledFor => dateTime().nullable()();
  IntColumn get rescheduleCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get publishedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
