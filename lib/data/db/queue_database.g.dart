// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_database.dart';

// ignore_for_file: type=lint
class $QueueJobsTable extends QueueJobs
    with TableInfo<$QueueJobsTable, QueueJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairedPathMeta = const VerificationMeta(
    'pairedPath',
  );
  @override
  late final GeneratedColumn<String> pairedPath = GeneratedColumn<String>(
    'paired_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mtimeMeta = const VerificationMeta('mtime');
  @override
  late final GeneratedColumn<DateTime> mtime = GeneratedColumn<DateTime>(
    'mtime',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaKindMeta = const VerificationMeta(
    'mediaKind',
  );
  @override
  late final GeneratedColumn<String> mediaKind = GeneratedColumn<String>(
    'media_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stageLabelMeta = const VerificationMeta(
    'stageLabel',
  );
  @override
  late final GeneratedColumn<String> stageLabel = GeneratedColumn<String>(
    'stage_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zernioPostIdMeta = const VerificationMeta(
    'zernioPostId',
  );
  @override
  late final GeneratedColumn<String> zernioPostId = GeneratedColumn<String>(
    'zernio_post_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _youtubeUrlMeta = const VerificationMeta(
    'youtubeUrl',
  );
  @override
  late final GeneratedColumn<String> youtubeUrl = GeneratedColumn<String>(
    'youtube_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preparedPathMeta = const VerificationMeta(
    'preparedPath',
  );
  @override
  late final GeneratedColumn<String> preparedPath = GeneratedColumn<String>(
    'prepared_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publicUrlMeta = const VerificationMeta(
    'publicUrl',
  );
  @override
  late final GeneratedColumn<String> publicUrl = GeneratedColumn<String>(
    'public_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledFor = GeneratedColumn<DateTime>(
    'scheduled_for',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rescheduleCountMeta = const VerificationMeta(
    'rescheduleCount',
  );
  @override
  late final GeneratedColumn<int> rescheduleCount = GeneratedColumn<int>(
    'reschedule_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourcePath,
    pairedPath,
    fileSize,
    mtime,
    idempotencyKey,
    mediaKind,
    status,
    progress,
    stageLabel,
    errorMessage,
    zernioPostId,
    youtubeUrl,
    preparedPath,
    publicUrl,
    title,
    attempt,
    createdAt,
    updatedAt,
    scheduledFor,
    rescheduleCount,
    publishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    if (data.containsKey('paired_path')) {
      context.handle(
        _pairedPathMeta,
        pairedPath.isAcceptableOrUnknown(data['paired_path']!, _pairedPathMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('mtime')) {
      context.handle(
        _mtimeMeta,
        mtime.isAcceptableOrUnknown(data['mtime']!, _mtimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mtimeMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('media_kind')) {
      context.handle(
        _mediaKindMeta,
        mediaKind.isAcceptableOrUnknown(data['media_kind']!, _mediaKindMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaKindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('stage_label')) {
      context.handle(
        _stageLabelMeta,
        stageLabel.isAcceptableOrUnknown(data['stage_label']!, _stageLabelMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('zernio_post_id')) {
      context.handle(
        _zernioPostIdMeta,
        zernioPostId.isAcceptableOrUnknown(
          data['zernio_post_id']!,
          _zernioPostIdMeta,
        ),
      );
    }
    if (data.containsKey('youtube_url')) {
      context.handle(
        _youtubeUrlMeta,
        youtubeUrl.isAcceptableOrUnknown(data['youtube_url']!, _youtubeUrlMeta),
      );
    }
    if (data.containsKey('prepared_path')) {
      context.handle(
        _preparedPathMeta,
        preparedPath.isAcceptableOrUnknown(
          data['prepared_path']!,
          _preparedPathMeta,
        ),
      );
    }
    if (data.containsKey('public_url')) {
      context.handle(
        _publicUrlMeta,
        publicUrl.isAcceptableOrUnknown(data['public_url']!, _publicUrlMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    }
    if (data.containsKey('reschedule_count')) {
      context.handle(
        _rescheduleCountMeta,
        rescheduleCount.isAcceptableOrUnknown(
          data['reschedule_count']!,
          _rescheduleCountMeta,
        ),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
      pairedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paired_path'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      mtime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mtime'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      mediaKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      stageLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_label'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      zernioPostId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zernio_post_id'],
      ),
      youtubeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_url'],
      ),
      preparedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prepared_path'],
      ),
      publicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_for'],
      ),
      rescheduleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reschedule_count'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
    );
  }

  @override
  $QueueJobsTable createAlias(String alias) {
    return $QueueJobsTable(attachedDatabase, alias);
  }
}

class QueueJob extends DataClass implements Insertable<QueueJob> {
  final String id;
  final String sourcePath;
  final String? pairedPath;
  final int fileSize;
  final DateTime mtime;
  final String idempotencyKey;
  final String mediaKind;
  final String status;
  final int progress;
  final String stageLabel;
  final String? errorMessage;
  final String? zernioPostId;
  final String? youtubeUrl;
  final String? preparedPath;
  final String? publicUrl;
  final String title;
  final int attempt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledFor;
  final int rescheduleCount;
  final DateTime? publishedAt;
  const QueueJob({
    required this.id,
    required this.sourcePath,
    this.pairedPath,
    required this.fileSize,
    required this.mtime,
    required this.idempotencyKey,
    required this.mediaKind,
    required this.status,
    required this.progress,
    required this.stageLabel,
    this.errorMessage,
    this.zernioPostId,
    this.youtubeUrl,
    this.preparedPath,
    this.publicUrl,
    required this.title,
    required this.attempt,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledFor,
    required this.rescheduleCount,
    this.publishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_path'] = Variable<String>(sourcePath);
    if (!nullToAbsent || pairedPath != null) {
      map['paired_path'] = Variable<String>(pairedPath);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['mtime'] = Variable<DateTime>(mtime);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['media_kind'] = Variable<String>(mediaKind);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    map['stage_label'] = Variable<String>(stageLabel);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || zernioPostId != null) {
      map['zernio_post_id'] = Variable<String>(zernioPostId);
    }
    if (!nullToAbsent || youtubeUrl != null) {
      map['youtube_url'] = Variable<String>(youtubeUrl);
    }
    if (!nullToAbsent || preparedPath != null) {
      map['prepared_path'] = Variable<String>(preparedPath);
    }
    if (!nullToAbsent || publicUrl != null) {
      map['public_url'] = Variable<String>(publicUrl);
    }
    map['title'] = Variable<String>(title);
    map['attempt'] = Variable<int>(attempt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || scheduledFor != null) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor);
    }
    map['reschedule_count'] = Variable<int>(rescheduleCount);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    return map;
  }

  QueueJobsCompanion toCompanion(bool nullToAbsent) {
    return QueueJobsCompanion(
      id: Value(id),
      sourcePath: Value(sourcePath),
      pairedPath: pairedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pairedPath),
      fileSize: Value(fileSize),
      mtime: Value(mtime),
      idempotencyKey: Value(idempotencyKey),
      mediaKind: Value(mediaKind),
      status: Value(status),
      progress: Value(progress),
      stageLabel: Value(stageLabel),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      zernioPostId: zernioPostId == null && nullToAbsent
          ? const Value.absent()
          : Value(zernioPostId),
      youtubeUrl: youtubeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(youtubeUrl),
      preparedPath: preparedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(preparedPath),
      publicUrl: publicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(publicUrl),
      title: Value(title),
      attempt: Value(attempt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      scheduledFor: scheduledFor == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledFor),
      rescheduleCount: Value(rescheduleCount),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
    );
  }

  factory QueueJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueJob(
      id: serializer.fromJson<String>(json['id']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
      pairedPath: serializer.fromJson<String?>(json['pairedPath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      mtime: serializer.fromJson<DateTime>(json['mtime']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      mediaKind: serializer.fromJson<String>(json['mediaKind']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      stageLabel: serializer.fromJson<String>(json['stageLabel']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      zernioPostId: serializer.fromJson<String?>(json['zernioPostId']),
      youtubeUrl: serializer.fromJson<String?>(json['youtubeUrl']),
      preparedPath: serializer.fromJson<String?>(json['preparedPath']),
      publicUrl: serializer.fromJson<String?>(json['publicUrl']),
      title: serializer.fromJson<String>(json['title']),
      attempt: serializer.fromJson<int>(json['attempt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      scheduledFor: serializer.fromJson<DateTime?>(json['scheduledFor']),
      rescheduleCount: serializer.fromJson<int>(json['rescheduleCount']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourcePath': serializer.toJson<String>(sourcePath),
      'pairedPath': serializer.toJson<String?>(pairedPath),
      'fileSize': serializer.toJson<int>(fileSize),
      'mtime': serializer.toJson<DateTime>(mtime),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'mediaKind': serializer.toJson<String>(mediaKind),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'stageLabel': serializer.toJson<String>(stageLabel),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'zernioPostId': serializer.toJson<String?>(zernioPostId),
      'youtubeUrl': serializer.toJson<String?>(youtubeUrl),
      'preparedPath': serializer.toJson<String?>(preparedPath),
      'publicUrl': serializer.toJson<String?>(publicUrl),
      'title': serializer.toJson<String>(title),
      'attempt': serializer.toJson<int>(attempt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'scheduledFor': serializer.toJson<DateTime?>(scheduledFor),
      'rescheduleCount': serializer.toJson<int>(rescheduleCount),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
    };
  }

  QueueJob copyWith({
    String? id,
    String? sourcePath,
    Value<String?> pairedPath = const Value.absent(),
    int? fileSize,
    DateTime? mtime,
    String? idempotencyKey,
    String? mediaKind,
    String? status,
    int? progress,
    String? stageLabel,
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> zernioPostId = const Value.absent(),
    Value<String?> youtubeUrl = const Value.absent(),
    Value<String?> preparedPath = const Value.absent(),
    Value<String?> publicUrl = const Value.absent(),
    String? title,
    int? attempt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> scheduledFor = const Value.absent(),
    int? rescheduleCount,
    Value<DateTime?> publishedAt = const Value.absent(),
  }) => QueueJob(
    id: id ?? this.id,
    sourcePath: sourcePath ?? this.sourcePath,
    pairedPath: pairedPath.present ? pairedPath.value : this.pairedPath,
    fileSize: fileSize ?? this.fileSize,
    mtime: mtime ?? this.mtime,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    mediaKind: mediaKind ?? this.mediaKind,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    stageLabel: stageLabel ?? this.stageLabel,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    zernioPostId: zernioPostId.present ? zernioPostId.value : this.zernioPostId,
    youtubeUrl: youtubeUrl.present ? youtubeUrl.value : this.youtubeUrl,
    preparedPath: preparedPath.present ? preparedPath.value : this.preparedPath,
    publicUrl: publicUrl.present ? publicUrl.value : this.publicUrl,
    title: title ?? this.title,
    attempt: attempt ?? this.attempt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    scheduledFor: scheduledFor.present ? scheduledFor.value : this.scheduledFor,
    rescheduleCount: rescheduleCount ?? this.rescheduleCount,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
  );
  QueueJob copyWithCompanion(QueueJobsCompanion data) {
    return QueueJob(
      id: data.id.present ? data.id.value : this.id,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      pairedPath: data.pairedPath.present
          ? data.pairedPath.value
          : this.pairedPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      mtime: data.mtime.present ? data.mtime.value : this.mtime,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      mediaKind: data.mediaKind.present ? data.mediaKind.value : this.mediaKind,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      stageLabel: data.stageLabel.present
          ? data.stageLabel.value
          : this.stageLabel,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      zernioPostId: data.zernioPostId.present
          ? data.zernioPostId.value
          : this.zernioPostId,
      youtubeUrl: data.youtubeUrl.present
          ? data.youtubeUrl.value
          : this.youtubeUrl,
      preparedPath: data.preparedPath.present
          ? data.preparedPath.value
          : this.preparedPath,
      publicUrl: data.publicUrl.present ? data.publicUrl.value : this.publicUrl,
      title: data.title.present ? data.title.value : this.title,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      rescheduleCount: data.rescheduleCount.present
          ? data.rescheduleCount.value
          : this.rescheduleCount,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueJob(')
          ..write('id: $id, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('pairedPath: $pairedPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mtime: $mtime, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('mediaKind: $mediaKind, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('stageLabel: $stageLabel, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('zernioPostId: $zernioPostId, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('preparedPath: $preparedPath, ')
          ..write('publicUrl: $publicUrl, ')
          ..write('title: $title, ')
          ..write('attempt: $attempt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('rescheduleCount: $rescheduleCount, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sourcePath,
    pairedPath,
    fileSize,
    mtime,
    idempotencyKey,
    mediaKind,
    status,
    progress,
    stageLabel,
    errorMessage,
    zernioPostId,
    youtubeUrl,
    preparedPath,
    publicUrl,
    title,
    attempt,
    createdAt,
    updatedAt,
    scheduledFor,
    rescheduleCount,
    publishedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueJob &&
          other.id == this.id &&
          other.sourcePath == this.sourcePath &&
          other.pairedPath == this.pairedPath &&
          other.fileSize == this.fileSize &&
          other.mtime == this.mtime &&
          other.idempotencyKey == this.idempotencyKey &&
          other.mediaKind == this.mediaKind &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.stageLabel == this.stageLabel &&
          other.errorMessage == this.errorMessage &&
          other.zernioPostId == this.zernioPostId &&
          other.youtubeUrl == this.youtubeUrl &&
          other.preparedPath == this.preparedPath &&
          other.publicUrl == this.publicUrl &&
          other.title == this.title &&
          other.attempt == this.attempt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.scheduledFor == this.scheduledFor &&
          other.rescheduleCount == this.rescheduleCount &&
          other.publishedAt == this.publishedAt);
}

class QueueJobsCompanion extends UpdateCompanion<QueueJob> {
  final Value<String> id;
  final Value<String> sourcePath;
  final Value<String?> pairedPath;
  final Value<int> fileSize;
  final Value<DateTime> mtime;
  final Value<String> idempotencyKey;
  final Value<String> mediaKind;
  final Value<String> status;
  final Value<int> progress;
  final Value<String> stageLabel;
  final Value<String?> errorMessage;
  final Value<String?> zernioPostId;
  final Value<String?> youtubeUrl;
  final Value<String?> preparedPath;
  final Value<String?> publicUrl;
  final Value<String> title;
  final Value<int> attempt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> scheduledFor;
  final Value<int> rescheduleCount;
  final Value<DateTime?> publishedAt;
  final Value<int> rowid;
  const QueueJobsCompanion({
    this.id = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.pairedPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mtime = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.mediaKind = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.stageLabel = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.zernioPostId = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.preparedPath = const Value.absent(),
    this.publicUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.attempt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.rescheduleCount = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueJobsCompanion.insert({
    required String id,
    required String sourcePath,
    this.pairedPath = const Value.absent(),
    required int fileSize,
    required DateTime mtime,
    required String idempotencyKey,
    required String mediaKind,
    required String status,
    this.progress = const Value.absent(),
    this.stageLabel = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.zernioPostId = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.preparedPath = const Value.absent(),
    this.publicUrl = const Value.absent(),
    required String title,
    this.attempt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.scheduledFor = const Value.absent(),
    this.rescheduleCount = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourcePath = Value(sourcePath),
       fileSize = Value(fileSize),
       mtime = Value(mtime),
       idempotencyKey = Value(idempotencyKey),
       mediaKind = Value(mediaKind),
       status = Value(status),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QueueJob> custom({
    Expression<String>? id,
    Expression<String>? sourcePath,
    Expression<String>? pairedPath,
    Expression<int>? fileSize,
    Expression<DateTime>? mtime,
    Expression<String>? idempotencyKey,
    Expression<String>? mediaKind,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<String>? stageLabel,
    Expression<String>? errorMessage,
    Expression<String>? zernioPostId,
    Expression<String>? youtubeUrl,
    Expression<String>? preparedPath,
    Expression<String>? publicUrl,
    Expression<String>? title,
    Expression<int>? attempt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? scheduledFor,
    Expression<int>? rescheduleCount,
    Expression<DateTime>? publishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePath != null) 'source_path': sourcePath,
      if (pairedPath != null) 'paired_path': pairedPath,
      if (fileSize != null) 'file_size': fileSize,
      if (mtime != null) 'mtime': mtime,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (mediaKind != null) 'media_kind': mediaKind,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (stageLabel != null) 'stage_label': stageLabel,
      if (errorMessage != null) 'error_message': errorMessage,
      if (zernioPostId != null) 'zernio_post_id': zernioPostId,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (preparedPath != null) 'prepared_path': preparedPath,
      if (publicUrl != null) 'public_url': publicUrl,
      if (title != null) 'title': title,
      if (attempt != null) 'attempt': attempt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (rescheduleCount != null) 'reschedule_count': rescheduleCount,
      if (publishedAt != null) 'published_at': publishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourcePath,
    Value<String?>? pairedPath,
    Value<int>? fileSize,
    Value<DateTime>? mtime,
    Value<String>? idempotencyKey,
    Value<String>? mediaKind,
    Value<String>? status,
    Value<int>? progress,
    Value<String>? stageLabel,
    Value<String?>? errorMessage,
    Value<String?>? zernioPostId,
    Value<String?>? youtubeUrl,
    Value<String?>? preparedPath,
    Value<String?>? publicUrl,
    Value<String>? title,
    Value<int>? attempt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? scheduledFor,
    Value<int>? rescheduleCount,
    Value<DateTime?>? publishedAt,
    Value<int>? rowid,
  }) {
    return QueueJobsCompanion(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      pairedPath: pairedPath ?? this.pairedPath,
      fileSize: fileSize ?? this.fileSize,
      mtime: mtime ?? this.mtime,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      mediaKind: mediaKind ?? this.mediaKind,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      stageLabel: stageLabel ?? this.stageLabel,
      errorMessage: errorMessage ?? this.errorMessage,
      zernioPostId: zernioPostId ?? this.zernioPostId,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      preparedPath: preparedPath ?? this.preparedPath,
      publicUrl: publicUrl ?? this.publicUrl,
      title: title ?? this.title,
      attempt: attempt ?? this.attempt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      publishedAt: publishedAt ?? this.publishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (pairedPath.present) {
      map['paired_path'] = Variable<String>(pairedPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (mtime.present) {
      map['mtime'] = Variable<DateTime>(mtime.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (mediaKind.present) {
      map['media_kind'] = Variable<String>(mediaKind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (stageLabel.present) {
      map['stage_label'] = Variable<String>(stageLabel.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (zernioPostId.present) {
      map['zernio_post_id'] = Variable<String>(zernioPostId.value);
    }
    if (youtubeUrl.present) {
      map['youtube_url'] = Variable<String>(youtubeUrl.value);
    }
    if (preparedPath.present) {
      map['prepared_path'] = Variable<String>(preparedPath.value);
    }
    if (publicUrl.present) {
      map['public_url'] = Variable<String>(publicUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor.value);
    }
    if (rescheduleCount.present) {
      map['reschedule_count'] = Variable<int>(rescheduleCount.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueJobsCompanion(')
          ..write('id: $id, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('pairedPath: $pairedPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mtime: $mtime, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('mediaKind: $mediaKind, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('stageLabel: $stageLabel, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('zernioPostId: $zernioPostId, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('preparedPath: $preparedPath, ')
          ..write('publicUrl: $publicUrl, ')
          ..write('title: $title, ')
          ..write('attempt: $attempt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('rescheduleCount: $rescheduleCount, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$QueueDatabase extends GeneratedDatabase {
  _$QueueDatabase(QueryExecutor e) : super(e);
  $QueueDatabaseManager get managers => $QueueDatabaseManager(this);
  late final $QueueJobsTable queueJobs = $QueueJobsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [queueJobs, appSettings];
}

typedef $$QueueJobsTableCreateCompanionBuilder =
    QueueJobsCompanion Function({
      required String id,
      required String sourcePath,
      Value<String?> pairedPath,
      required int fileSize,
      required DateTime mtime,
      required String idempotencyKey,
      required String mediaKind,
      required String status,
      Value<int> progress,
      Value<String> stageLabel,
      Value<String?> errorMessage,
      Value<String?> zernioPostId,
      Value<String?> youtubeUrl,
      Value<String?> preparedPath,
      Value<String?> publicUrl,
      required String title,
      Value<int> attempt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> scheduledFor,
      Value<int> rescheduleCount,
      Value<DateTime?> publishedAt,
      Value<int> rowid,
    });
typedef $$QueueJobsTableUpdateCompanionBuilder =
    QueueJobsCompanion Function({
      Value<String> id,
      Value<String> sourcePath,
      Value<String?> pairedPath,
      Value<int> fileSize,
      Value<DateTime> mtime,
      Value<String> idempotencyKey,
      Value<String> mediaKind,
      Value<String> status,
      Value<int> progress,
      Value<String> stageLabel,
      Value<String?> errorMessage,
      Value<String?> zernioPostId,
      Value<String?> youtubeUrl,
      Value<String?> preparedPath,
      Value<String?> publicUrl,
      Value<String> title,
      Value<int> attempt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> scheduledFor,
      Value<int> rescheduleCount,
      Value<DateTime?> publishedAt,
      Value<int> rowid,
    });

class $$QueueJobsTableFilterComposer
    extends Composer<_$QueueDatabase, $QueueJobsTable> {
  $$QueueJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pairedPath => $composableBuilder(
    column: $table.pairedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaKind => $composableBuilder(
    column: $table.mediaKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageLabel => $composableBuilder(
    column: $table.stageLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zernioPostId => $composableBuilder(
    column: $table.zernioPostId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preparedPath => $composableBuilder(
    column: $table.preparedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicUrl => $composableBuilder(
    column: $table.publicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rescheduleCount => $composableBuilder(
    column: $table.rescheduleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueJobsTableOrderingComposer
    extends Composer<_$QueueDatabase, $QueueJobsTable> {
  $$QueueJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pairedPath => $composableBuilder(
    column: $table.pairedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaKind => $composableBuilder(
    column: $table.mediaKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageLabel => $composableBuilder(
    column: $table.stageLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zernioPostId => $composableBuilder(
    column: $table.zernioPostId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preparedPath => $composableBuilder(
    column: $table.preparedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicUrl => $composableBuilder(
    column: $table.publicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rescheduleCount => $composableBuilder(
    column: $table.rescheduleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueJobsTableAnnotationComposer
    extends Composer<_$QueueDatabase, $QueueJobsTable> {
  $$QueueJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pairedPath => $composableBuilder(
    column: $table.pairedPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get mtime =>
      $composableBuilder(column: $table.mtime, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaKind =>
      $composableBuilder(column: $table.mediaKind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get stageLabel => $composableBuilder(
    column: $table.stageLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zernioPostId => $composableBuilder(
    column: $table.zernioPostId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preparedPath => $composableBuilder(
    column: $table.preparedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicUrl =>
      $composableBuilder(column: $table.publicUrl, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rescheduleCount => $composableBuilder(
    column: $table.rescheduleCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );
}

class $$QueueJobsTableTableManager
    extends
        RootTableManager<
          _$QueueDatabase,
          $QueueJobsTable,
          QueueJob,
          $$QueueJobsTableFilterComposer,
          $$QueueJobsTableOrderingComposer,
          $$QueueJobsTableAnnotationComposer,
          $$QueueJobsTableCreateCompanionBuilder,
          $$QueueJobsTableUpdateCompanionBuilder,
          (
            QueueJob,
            BaseReferences<_$QueueDatabase, $QueueJobsTable, QueueJob>,
          ),
          QueueJob,
          PrefetchHooks Function()
        > {
  $$QueueJobsTableTableManager(_$QueueDatabase db, $QueueJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
                Value<String?> pairedPath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<DateTime> mtime = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> mediaKind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<String> stageLabel = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> zernioPostId = const Value.absent(),
                Value<String?> youtubeUrl = const Value.absent(),
                Value<String?> preparedPath = const Value.absent(),
                Value<String?> publicUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> scheduledFor = const Value.absent(),
                Value<int> rescheduleCount = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueJobsCompanion(
                id: id,
                sourcePath: sourcePath,
                pairedPath: pairedPath,
                fileSize: fileSize,
                mtime: mtime,
                idempotencyKey: idempotencyKey,
                mediaKind: mediaKind,
                status: status,
                progress: progress,
                stageLabel: stageLabel,
                errorMessage: errorMessage,
                zernioPostId: zernioPostId,
                youtubeUrl: youtubeUrl,
                preparedPath: preparedPath,
                publicUrl: publicUrl,
                title: title,
                attempt: attempt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                scheduledFor: scheduledFor,
                rescheduleCount: rescheduleCount,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourcePath,
                Value<String?> pairedPath = const Value.absent(),
                required int fileSize,
                required DateTime mtime,
                required String idempotencyKey,
                required String mediaKind,
                required String status,
                Value<int> progress = const Value.absent(),
                Value<String> stageLabel = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> zernioPostId = const Value.absent(),
                Value<String?> youtubeUrl = const Value.absent(),
                Value<String?> preparedPath = const Value.absent(),
                Value<String?> publicUrl = const Value.absent(),
                required String title,
                Value<int> attempt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> scheduledFor = const Value.absent(),
                Value<int> rescheduleCount = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueJobsCompanion.insert(
                id: id,
                sourcePath: sourcePath,
                pairedPath: pairedPath,
                fileSize: fileSize,
                mtime: mtime,
                idempotencyKey: idempotencyKey,
                mediaKind: mediaKind,
                status: status,
                progress: progress,
                stageLabel: stageLabel,
                errorMessage: errorMessage,
                zernioPostId: zernioPostId,
                youtubeUrl: youtubeUrl,
                preparedPath: preparedPath,
                publicUrl: publicUrl,
                title: title,
                attempt: attempt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                scheduledFor: scheduledFor,
                rescheduleCount: rescheduleCount,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$QueueDatabase,
      $QueueJobsTable,
      QueueJob,
      $$QueueJobsTableFilterComposer,
      $$QueueJobsTableOrderingComposer,
      $$QueueJobsTableAnnotationComposer,
      $$QueueJobsTableCreateCompanionBuilder,
      $$QueueJobsTableUpdateCompanionBuilder,
      (QueueJob, BaseReferences<_$QueueDatabase, $QueueJobsTable, QueueJob>),
      QueueJob,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$QueueDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$QueueDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$QueueDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$QueueDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$QueueDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$QueueDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$QueueDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$QueueDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $QueueDatabaseManager {
  final _$QueueDatabase _db;
  $QueueDatabaseManager(this._db);
  $$QueueJobsTableTableManager get queueJobs =>
      $$QueueJobsTableTableManager(_db, _db.queueJobs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
