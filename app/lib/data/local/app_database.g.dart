// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedEssentialsTable extends CachedEssentials
    with TableInfo<$CachedEssentialsTable, CachedEssential> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEssentialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _targetPomodorosMeta = const VerificationMeta(
    'targetPomodoros',
  );
  @override
  late final GeneratedColumn<int> targetPomodoros = GeneratedColumn<int>(
    'target_pomodoros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedPomodorosMeta =
      const VerificationMeta('completedPomodoros');
  @override
  late final GeneratedColumn<int> completedPomodoros = GeneratedColumn<int>(
    'completed_pomodoros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    slot,
    title,
    targetPomodoros,
    completedPomodoros,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_essentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedEssential> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_pomodoros')) {
      context.handle(
        _targetPomodorosMeta,
        targetPomodoros.isAcceptableOrUnknown(
          data['target_pomodoros']!,
          _targetPomodorosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPomodorosMeta);
    }
    if (data.containsKey('completed_pomodoros')) {
      context.handle(
        _completedPomodorosMeta,
        completedPomodoros.isAcceptableOrUnknown(
          data['completed_pomodoros']!,
          _completedPomodorosMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedEssential map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEssential(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetPomodoros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_pomodoros'],
      )!,
      completedPomodoros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_pomodoros'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $CachedEssentialsTable createAlias(String alias) {
    return $CachedEssentialsTable(attachedDatabase, alias);
  }
}

class CachedEssential extends DataClass implements Insertable<CachedEssential> {
  final String id;
  final String localDate;
  final int slot;
  final String title;
  final int targetPomodoros;
  final int completedPomodoros;
  final DateTime? completedAt;
  const CachedEssential({
    required this.id,
    required this.localDate,
    required this.slot,
    required this.title,
    required this.targetPomodoros,
    required this.completedPomodoros,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_date'] = Variable<String>(localDate);
    map['slot'] = Variable<int>(slot);
    map['title'] = Variable<String>(title);
    map['target_pomodoros'] = Variable<int>(targetPomodoros);
    map['completed_pomodoros'] = Variable<int>(completedPomodoros);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  CachedEssentialsCompanion toCompanion(bool nullToAbsent) {
    return CachedEssentialsCompanion(
      id: Value(id),
      localDate: Value(localDate),
      slot: Value(slot),
      title: Value(title),
      targetPomodoros: Value(targetPomodoros),
      completedPomodoros: Value(completedPomodoros),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory CachedEssential.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEssential(
      id: serializer.fromJson<String>(json['id']),
      localDate: serializer.fromJson<String>(json['localDate']),
      slot: serializer.fromJson<int>(json['slot']),
      title: serializer.fromJson<String>(json['title']),
      targetPomodoros: serializer.fromJson<int>(json['targetPomodoros']),
      completedPomodoros: serializer.fromJson<int>(json['completedPomodoros']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localDate': serializer.toJson<String>(localDate),
      'slot': serializer.toJson<int>(slot),
      'title': serializer.toJson<String>(title),
      'targetPomodoros': serializer.toJson<int>(targetPomodoros),
      'completedPomodoros': serializer.toJson<int>(completedPomodoros),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  CachedEssential copyWith({
    String? id,
    String? localDate,
    int? slot,
    String? title,
    int? targetPomodoros,
    int? completedPomodoros,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => CachedEssential(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    slot: slot ?? this.slot,
    title: title ?? this.title,
    targetPomodoros: targetPomodoros ?? this.targetPomodoros,
    completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  CachedEssential copyWithCompanion(CachedEssentialsCompanion data) {
    return CachedEssential(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      slot: data.slot.present ? data.slot.value : this.slot,
      title: data.title.present ? data.title.value : this.title,
      targetPomodoros: data.targetPomodoros.present
          ? data.targetPomodoros.value
          : this.targetPomodoros,
      completedPomodoros: data.completedPomodoros.present
          ? data.completedPomodoros.value
          : this.completedPomodoros,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEssential(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('slot: $slot, ')
          ..write('title: $title, ')
          ..write('targetPomodoros: $targetPomodoros, ')
          ..write('completedPomodoros: $completedPomodoros, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localDate,
    slot,
    title,
    targetPomodoros,
    completedPomodoros,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEssential &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.slot == this.slot &&
          other.title == this.title &&
          other.targetPomodoros == this.targetPomodoros &&
          other.completedPomodoros == this.completedPomodoros &&
          other.completedAt == this.completedAt);
}

class CachedEssentialsCompanion extends UpdateCompanion<CachedEssential> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<int> slot;
  final Value<String> title;
  final Value<int> targetPomodoros;
  final Value<int> completedPomodoros;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const CachedEssentialsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.slot = const Value.absent(),
    this.title = const Value.absent(),
    this.targetPomodoros = const Value.absent(),
    this.completedPomodoros = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEssentialsCompanion.insert({
    required String id,
    required String localDate,
    required int slot,
    required String title,
    required int targetPomodoros,
    this.completedPomodoros = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       slot = Value(slot),
       title = Value(title),
       targetPomodoros = Value(targetPomodoros);
  static Insertable<CachedEssential> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<int>? slot,
    Expression<String>? title,
    Expression<int>? targetPomodoros,
    Expression<int>? completedPomodoros,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (slot != null) 'slot': slot,
      if (title != null) 'title': title,
      if (targetPomodoros != null) 'target_pomodoros': targetPomodoros,
      if (completedPomodoros != null) 'completed_pomodoros': completedPomodoros,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEssentialsCompanion copyWith({
    Value<String>? id,
    Value<String>? localDate,
    Value<int>? slot,
    Value<String>? title,
    Value<int>? targetPomodoros,
    Value<int>? completedPomodoros,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return CachedEssentialsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      slot: slot ?? this.slot,
      title: title ?? this.title,
      targetPomodoros: targetPomodoros ?? this.targetPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetPomodoros.present) {
      map['target_pomodoros'] = Variable<int>(targetPomodoros.value);
    }
    if (completedPomodoros.present) {
      map['completed_pomodoros'] = Variable<int>(completedPomodoros.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEssentialsCompanion(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('slot: $slot, ')
          ..write('title: $title, ')
          ..write('targetPomodoros: $targetPomodoros, ')
          ..write('completedPomodoros: $completedPomodoros, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _essentialIdMeta = const VerificationMeta(
    'essentialId',
  );
  @override
  late final GeneratedColumn<String> essentialId = GeneratedColumn<String>(
    'essential_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    opId,
    kind,
    essentialId,
    payload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('essential_id')) {
      context.handle(
        _essentialIdMeta,
        essentialId.isAcceptableOrUnknown(
          data['essential_id']!,
          _essentialIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_essentialIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      essentialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}essential_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int seq;
  final String opId;
  final String kind;
  final String essentialId;
  final String payload;
  final DateTime createdAt;
  const OutboxEntry({
    required this.seq,
    required this.opId,
    required this.kind,
    required this.essentialId,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['op_id'] = Variable<String>(opId);
    map['kind'] = Variable<String>(kind);
    map['essential_id'] = Variable<String>(essentialId);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      seq: Value(seq),
      opId: Value(opId),
      kind: Value(kind),
      essentialId: Value(essentialId),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      seq: serializer.fromJson<int>(json['seq']),
      opId: serializer.fromJson<String>(json['opId']),
      kind: serializer.fromJson<String>(json['kind']),
      essentialId: serializer.fromJson<String>(json['essentialId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'opId': serializer.toJson<String>(opId),
      'kind': serializer.toJson<String>(kind),
      'essentialId': serializer.toJson<String>(essentialId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxEntry copyWith({
    int? seq,
    String? opId,
    String? kind,
    String? essentialId,
    String? payload,
    DateTime? createdAt,
  }) => OutboxEntry(
    seq: seq ?? this.seq,
    opId: opId ?? this.opId,
    kind: kind ?? this.kind,
    essentialId: essentialId ?? this.essentialId,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      seq: data.seq.present ? data.seq.value : this.seq,
      opId: data.opId.present ? data.opId.value : this.opId,
      kind: data.kind.present ? data.kind.value : this.kind,
      essentialId: data.essentialId.present
          ? data.essentialId.value
          : this.essentialId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('kind: $kind, ')
          ..write('essentialId: $essentialId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, opId, kind, essentialId, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.seq == this.seq &&
          other.opId == this.opId &&
          other.kind == this.kind &&
          other.essentialId == this.essentialId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> seq;
  final Value<String> opId;
  final Value<String> kind;
  final Value<String> essentialId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const OutboxEntriesCompanion({
    this.seq = const Value.absent(),
    this.opId = const Value.absent(),
    this.kind = const Value.absent(),
    this.essentialId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.seq = const Value.absent(),
    required String opId,
    required String kind,
    required String essentialId,
    this.payload = const Value.absent(),
    required DateTime createdAt,
  }) : opId = Value(opId),
       kind = Value(kind),
       essentialId = Value(essentialId),
       createdAt = Value(createdAt);
  static Insertable<OutboxEntry> custom({
    Expression<int>? seq,
    Expression<String>? opId,
    Expression<String>? kind,
    Expression<String>? essentialId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (opId != null) 'op_id': opId,
      if (kind != null) 'kind': kind,
      if (essentialId != null) 'essential_id': essentialId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<int>? seq,
    Value<String>? opId,
    Value<String>? kind,
    Value<String>? essentialId,
    Value<String>? payload,
    Value<DateTime>? createdAt,
  }) {
    return OutboxEntriesCompanion(
      seq: seq ?? this.seq,
      opId: opId ?? this.opId,
      kind: kind ?? this.kind,
      essentialId: essentialId ?? this.essentialId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (essentialId.present) {
      map['essential_id'] = Variable<String>(essentialId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('kind: $kind, ')
          ..write('essentialId: $essentialId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedEssentialsTable cachedEssentials = $CachedEssentialsTable(
    this,
  );
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedEssentials,
    outboxEntries,
  ];
}

typedef $$CachedEssentialsTableCreateCompanionBuilder =
    CachedEssentialsCompanion Function({
      required String id,
      required String localDate,
      required int slot,
      required String title,
      required int targetPomodoros,
      Value<int> completedPomodoros,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$CachedEssentialsTableUpdateCompanionBuilder =
    CachedEssentialsCompanion Function({
      Value<String> id,
      Value<String> localDate,
      Value<int> slot,
      Value<String> title,
      Value<int> targetPomodoros,
      Value<int> completedPomodoros,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$CachedEssentialsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEssentialsTable> {
  $$CachedEssentialsTableFilterComposer({
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

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPomodoros => $composableBuilder(
    column: $table.targetPomodoros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedPomodoros => $composableBuilder(
    column: $table.completedPomodoros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedEssentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEssentialsTable> {
  $$CachedEssentialsTableOrderingComposer({
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

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPomodoros => $composableBuilder(
    column: $table.targetPomodoros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedPomodoros => $composableBuilder(
    column: $table.completedPomodoros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedEssentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEssentialsTable> {
  $$CachedEssentialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetPomodoros => $composableBuilder(
    column: $table.targetPomodoros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedPomodoros => $composableBuilder(
    column: $table.completedPomodoros,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$CachedEssentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedEssentialsTable,
          CachedEssential,
          $$CachedEssentialsTableFilterComposer,
          $$CachedEssentialsTableOrderingComposer,
          $$CachedEssentialsTableAnnotationComposer,
          $$CachedEssentialsTableCreateCompanionBuilder,
          $$CachedEssentialsTableUpdateCompanionBuilder,
          (
            CachedEssential,
            BaseReferences<
              _$AppDatabase,
              $CachedEssentialsTable,
              CachedEssential
            >,
          ),
          CachedEssential,
          PrefetchHooks Function()
        > {
  $$CachedEssentialsTableTableManager(
    _$AppDatabase db,
    $CachedEssentialsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEssentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEssentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEssentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<int> slot = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> targetPomodoros = const Value.absent(),
                Value<int> completedPomodoros = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEssentialsCompanion(
                id: id,
                localDate: localDate,
                slot: slot,
                title: title,
                targetPomodoros: targetPomodoros,
                completedPomodoros: completedPomodoros,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localDate,
                required int slot,
                required String title,
                required int targetPomodoros,
                Value<int> completedPomodoros = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEssentialsCompanion.insert(
                id: id,
                localDate: localDate,
                slot: slot,
                title: title,
                targetPomodoros: targetPomodoros,
                completedPomodoros: completedPomodoros,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedEssentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedEssentialsTable,
      CachedEssential,
      $$CachedEssentialsTableFilterComposer,
      $$CachedEssentialsTableOrderingComposer,
      $$CachedEssentialsTableAnnotationComposer,
      $$CachedEssentialsTableCreateCompanionBuilder,
      $$CachedEssentialsTableUpdateCompanionBuilder,
      (
        CachedEssential,
        BaseReferences<_$AppDatabase, $CachedEssentialsTable, CachedEssential>,
      ),
      CachedEssential,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> seq,
      required String opId,
      required String kind,
      required String essentialId,
      Value<String> payload,
      required DateTime createdAt,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> seq,
      Value<String> opId,
      Value<String> kind,
      Value<String> essentialId,
      Value<String> payload,
      Value<DateTime> createdAt,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get essentialId => $composableBuilder(
    column: $table.essentialId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get essentialId => $composableBuilder(
    column: $table.essentialId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get essentialId => $composableBuilder(
    column: $table.essentialId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> opId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> essentialId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxEntriesCompanion(
                seq: seq,
                opId: opId,
                kind: kind,
                essentialId: essentialId,
                payload: payload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String opId,
                required String kind,
                required String essentialId,
                Value<String> payload = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxEntriesCompanion.insert(
                seq: seq,
                opId: opId,
                kind: kind,
                essentialId: essentialId,
                payload: payload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEssentialsTableTableManager get cachedEssentials =>
      $$CachedEssentialsTableTableManager(_db, _db.cachedEssentials);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
