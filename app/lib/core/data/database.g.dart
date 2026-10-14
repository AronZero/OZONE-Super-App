// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
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
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
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
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
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

  AppMetaRow copyWith({String? key, String? value}) =>
      AppMetaRow(key: key ?? this.key, value: value ?? this.value);
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
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
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaRow> custom({
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

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
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
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  final int updatedAt;
  const SettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SettingRow copyWith({String? key, String? value, int? updatedAt}) =>
      SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletionsTable extends Deletions
    with TableInfo<$DeletionsTable, DeletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, recordId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, recordId};
  @override
  DeletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletionRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletionsTable createAlias(String alias) {
    return $DeletionsTable(attachedDatabase, alias);
  }
}

class DeletionRow extends DataClass implements Insertable<DeletionRow> {
  final String entity;
  final String recordId;
  final int deletedAt;
  const DeletionRow({
    required this.entity,
    required this.recordId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['record_id'] = Variable<String>(recordId);
    map['deleted_at'] = Variable<int>(deletedAt);
    return map;
  }

  DeletionsCompanion toCompanion(bool nullToAbsent) {
    return DeletionsCompanion(
      entity: Value(entity),
      recordId: Value(recordId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletionRow(
      entity: serializer.fromJson<String>(json['entity']),
      recordId: serializer.fromJson<String>(json['recordId']),
      deletedAt: serializer.fromJson<int>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'recordId': serializer.toJson<String>(recordId),
      'deletedAt': serializer.toJson<int>(deletedAt),
    };
  }

  DeletionRow copyWith({String? entity, String? recordId, int? deletedAt}) =>
      DeletionRow(
        entity: entity ?? this.entity,
        recordId: recordId ?? this.recordId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  DeletionRow copyWithCompanion(DeletionsCompanion data) {
    return DeletionRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletionRow(')
          ..write('entity: $entity, ')
          ..write('recordId: $recordId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, recordId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletionRow &&
          other.entity == this.entity &&
          other.recordId == this.recordId &&
          other.deletedAt == this.deletedAt);
}

class DeletionsCompanion extends UpdateCompanion<DeletionRow> {
  final Value<String> entity;
  final Value<String> recordId;
  final Value<int> deletedAt;
  final Value<int> rowid;
  const DeletionsCompanion({
    this.entity = const Value.absent(),
    this.recordId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletionsCompanion.insert({
    required String entity,
    required String recordId,
    required int deletedAt,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       recordId = Value(recordId),
       deletedAt = Value(deletedAt);
  static Insertable<DeletionRow> custom({
    Expression<String>? entity,
    Expression<String>? recordId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (recordId != null) 'record_id': recordId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletionsCompanion copyWith({
    Value<String>? entity,
    Value<String>? recordId,
    Value<int>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletionsCompanion(
      entity: entity ?? this.entity,
      recordId: recordId ?? this.recordId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletionsCompanion(')
          ..write('entity: $entity, ')
          ..write('recordId: $recordId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportsLogTable extends ExportsLog
    with TableInfo<$ExportsLogTable, ExportLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportsLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowCountsMeta = const VerificationMeta(
    'rowCounts',
  );
  @override
  late final GeneratedColumn<String> rowCounts = GeneratedColumn<String>(
    'row_counts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    fileName,
    createdAt,
    rowCounts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exports_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('row_counts')) {
      context.handle(
        _rowCountsMeta,
        rowCounts.isAcceptableOrUnknown(data['row_counts']!, _rowCountsMeta),
      );
    } else if (isInserting) {
      context.missing(_rowCountsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      rowCounts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_counts'],
      )!,
    );
  }

  @override
  $ExportsLogTable createAlias(String alias) {
    return $ExportsLogTable(attachedDatabase, alias);
  }
}

class ExportLogRow extends DataClass implements Insertable<ExportLogRow> {
  final String id;
  final String kind;
  final String fileName;
  final int createdAt;
  final String rowCounts;
  const ExportLogRow({
    required this.id,
    required this.kind,
    required this.fileName,
    required this.createdAt,
    required this.rowCounts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['file_name'] = Variable<String>(fileName);
    map['created_at'] = Variable<int>(createdAt);
    map['row_counts'] = Variable<String>(rowCounts);
    return map;
  }

  ExportsLogCompanion toCompanion(bool nullToAbsent) {
    return ExportsLogCompanion(
      id: Value(id),
      kind: Value(kind),
      fileName: Value(fileName),
      createdAt: Value(createdAt),
      rowCounts: Value(rowCounts),
    );
  }

  factory ExportLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportLogRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      fileName: serializer.fromJson<String>(json['fileName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      rowCounts: serializer.fromJson<String>(json['rowCounts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'fileName': serializer.toJson<String>(fileName),
      'createdAt': serializer.toJson<int>(createdAt),
      'rowCounts': serializer.toJson<String>(rowCounts),
    };
  }

  ExportLogRow copyWith({
    String? id,
    String? kind,
    String? fileName,
    int? createdAt,
    String? rowCounts,
  }) => ExportLogRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    fileName: fileName ?? this.fileName,
    createdAt: createdAt ?? this.createdAt,
    rowCounts: rowCounts ?? this.rowCounts,
  );
  ExportLogRow copyWithCompanion(ExportsLogCompanion data) {
    return ExportLogRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rowCounts: data.rowCounts.present ? data.rowCounts.value : this.rowCounts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportLogRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowCounts: $rowCounts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, fileName, createdAt, rowCounts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportLogRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.fileName == this.fileName &&
          other.createdAt == this.createdAt &&
          other.rowCounts == this.rowCounts);
}

class ExportsLogCompanion extends UpdateCompanion<ExportLogRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> fileName;
  final Value<int> createdAt;
  final Value<String> rowCounts;
  final Value<int> rowid;
  const ExportsLogCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.fileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowCounts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportsLogCompanion.insert({
    required String id,
    required String kind,
    required String fileName,
    required int createdAt,
    required String rowCounts,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       fileName = Value(fileName),
       createdAt = Value(createdAt),
       rowCounts = Value(rowCounts);
  static Insertable<ExportLogRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? fileName,
    Expression<int>? createdAt,
    Expression<String>? rowCounts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (fileName != null) 'file_name': fileName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowCounts != null) 'row_counts': rowCounts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportsLogCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? fileName,
    Value<int>? createdAt,
    Value<String>? rowCounts,
    Value<int>? rowid,
  }) {
    return ExportsLogCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      rowCounts: rowCounts ?? this.rowCounts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowCounts.present) {
      map['row_counts'] = Variable<String>(rowCounts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportsLogCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowCounts: $rowCounts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsAccountsTable extends SavingsAccounts
    with TableInfo<$SavingsAccountsTable, SavingsAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<String> archivedAt = GeneratedColumn<String>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    platform,
    type,
    remarks,
    sortOrder,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $SavingsAccountsTable createAlias(String alias) {
    return $SavingsAccountsTable(attachedDatabase, alias);
  }
}

class SavingsAccountRow extends DataClass
    implements Insertable<SavingsAccountRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String name;
  final String? platform;
  final String? type;
  final String? remarks;
  final int sortOrder;
  final String? archivedAt;
  const SavingsAccountRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.platform,
    this.type,
    this.remarks,
    required this.sortOrder,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || platform != null) {
      map['platform'] = Variable<String>(platform);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<String>(archivedAt);
    }
    return map;
  }

  SavingsAccountsCompanion toCompanion(bool nullToAbsent) {
    return SavingsAccountsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      platform: platform == null && nullToAbsent
          ? const Value.absent()
          : Value(platform),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      sortOrder: Value(sortOrder),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory SavingsAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsAccountRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      platform: serializer.fromJson<String?>(json['platform']),
      type: serializer.fromJson<String?>(json['type']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archivedAt: serializer.fromJson<String?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'name': serializer.toJson<String>(name),
      'platform': serializer.toJson<String?>(platform),
      'type': serializer.toJson<String?>(type),
      'remarks': serializer.toJson<String?>(remarks),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archivedAt': serializer.toJson<String?>(archivedAt),
    };
  }

  SavingsAccountRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? name,
    Value<String?> platform = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    int? sortOrder,
    Value<String?> archivedAt = const Value.absent(),
  }) => SavingsAccountRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    platform: platform.present ? platform.value : this.platform,
    type: type.present ? type.value : this.type,
    remarks: remarks.present ? remarks.value : this.remarks,
    sortOrder: sortOrder ?? this.sortOrder,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  SavingsAccountRow copyWithCompanion(SavingsAccountsCompanion data) {
    return SavingsAccountRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      platform: data.platform.present ? data.platform.value : this.platform,
      type: data.type.present ? data.type.value : this.type,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsAccountRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('type: $type, ')
          ..write('remarks: $remarks, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    platform,
    type,
    remarks,
    sortOrder,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsAccountRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.platform == this.platform &&
          other.type == this.type &&
          other.remarks == this.remarks &&
          other.sortOrder == this.sortOrder &&
          other.archivedAt == this.archivedAt);
}

class SavingsAccountsCompanion extends UpdateCompanion<SavingsAccountRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> name;
  final Value<String?> platform;
  final Value<String?> type;
  final Value<String?> remarks;
  final Value<int> sortOrder;
  final Value<String?> archivedAt;
  final Value<int> rowid;
  const SavingsAccountsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.platform = const Value.absent(),
    this.type = const Value.absent(),
    this.remarks = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsAccountsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String name,
    this.platform = const Value.absent(),
    this.type = const Value.absent(),
    this.remarks = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<SavingsAccountRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? name,
    Expression<String>? platform,
    Expression<String>? type,
    Expression<String>? remarks,
    Expression<int>? sortOrder,
    Expression<String>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (platform != null) 'platform': platform,
      if (type != null) 'type': type,
      if (remarks != null) 'remarks': remarks,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsAccountsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? name,
    Value<String?>? platform,
    Value<String?>? type,
    Value<String?>? remarks,
    Value<int>? sortOrder,
    Value<String?>? archivedAt,
    Value<int>? rowid,
  }) {
    return SavingsAccountsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      type: type ?? this.type,
      remarks: remarks ?? this.remarks,
      sortOrder: sortOrder ?? this.sortOrder,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<String>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsAccountsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('type: $type, ')
          ..write('remarks: $remarks, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalanceUpdatesTable extends BalanceUpdates
    with TableInfo<$BalanceUpdatesTable, BalanceUpdateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceUpdatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES savings_accounts (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUnchangedMeta = const VerificationMeta(
    'isUnchanged',
  );
  @override
  late final GeneratedColumn<bool> isUnchanged = GeneratedColumn<bool>(
    'is_unchanged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unchanged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    accountId,
    date,
    balance,
    isUnchanged,
    remarks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_updates';
  @override
  VerificationContext validateIntegrity(
    Insertable<BalanceUpdateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('is_unchanged')) {
      context.handle(
        _isUnchangedMeta,
        isUnchanged.isAcceptableOrUnknown(
          data['is_unchanged']!,
          _isUnchangedMeta,
        ),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountId, date},
  ];
  @override
  BalanceUpdateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceUpdateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      isUnchanged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unchanged'],
      )!,
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
    );
  }

  @override
  $BalanceUpdatesTable createAlias(String alias) {
    return $BalanceUpdatesTable(attachedDatabase, alias);
  }
}

class BalanceUpdateRow extends DataClass
    implements Insertable<BalanceUpdateRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String accountId;
  final String date;
  final int balance;
  final bool isUnchanged;
  final String? remarks;
  const BalanceUpdateRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.accountId,
    required this.date,
    required this.balance,
    required this.isUnchanged,
    this.remarks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['account_id'] = Variable<String>(accountId);
    map['date'] = Variable<String>(date);
    map['balance'] = Variable<int>(balance);
    map['is_unchanged'] = Variable<bool>(isUnchanged);
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    return map;
  }

  BalanceUpdatesCompanion toCompanion(bool nullToAbsent) {
    return BalanceUpdatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      accountId: Value(accountId),
      date: Value(date),
      balance: Value(balance),
      isUnchanged: Value(isUnchanged),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
    );
  }

  factory BalanceUpdateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceUpdateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      accountId: serializer.fromJson<String>(json['accountId']),
      date: serializer.fromJson<String>(json['date']),
      balance: serializer.fromJson<int>(json['balance']),
      isUnchanged: serializer.fromJson<bool>(json['isUnchanged']),
      remarks: serializer.fromJson<String?>(json['remarks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'accountId': serializer.toJson<String>(accountId),
      'date': serializer.toJson<String>(date),
      'balance': serializer.toJson<int>(balance),
      'isUnchanged': serializer.toJson<bool>(isUnchanged),
      'remarks': serializer.toJson<String?>(remarks),
    };
  }

  BalanceUpdateRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? accountId,
    String? date,
    int? balance,
    bool? isUnchanged,
    Value<String?> remarks = const Value.absent(),
  }) => BalanceUpdateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    balance: balance ?? this.balance,
    isUnchanged: isUnchanged ?? this.isUnchanged,
    remarks: remarks.present ? remarks.value : this.remarks,
  );
  BalanceUpdateRow copyWithCompanion(BalanceUpdatesCompanion data) {
    return BalanceUpdateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      date: data.date.present ? data.date.value : this.date,
      balance: data.balance.present ? data.balance.value : this.balance,
      isUnchanged: data.isUnchanged.present
          ? data.isUnchanged.value
          : this.isUnchanged,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceUpdateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('balance: $balance, ')
          ..write('isUnchanged: $isUnchanged, ')
          ..write('remarks: $remarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    accountId,
    date,
    balance,
    isUnchanged,
    remarks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceUpdateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.accountId == this.accountId &&
          other.date == this.date &&
          other.balance == this.balance &&
          other.isUnchanged == this.isUnchanged &&
          other.remarks == this.remarks);
}

class BalanceUpdatesCompanion extends UpdateCompanion<BalanceUpdateRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> accountId;
  final Value<String> date;
  final Value<int> balance;
  final Value<bool> isUnchanged;
  final Value<String?> remarks;
  final Value<int> rowid;
  const BalanceUpdatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.date = const Value.absent(),
    this.balance = const Value.absent(),
    this.isUnchanged = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceUpdatesCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String accountId,
    required String date,
    required int balance,
    this.isUnchanged = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       accountId = Value(accountId),
       date = Value(date),
       balance = Value(balance);
  static Insertable<BalanceUpdateRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? accountId,
    Expression<String>? date,
    Expression<int>? balance,
    Expression<bool>? isUnchanged,
    Expression<String>? remarks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (accountId != null) 'account_id': accountId,
      if (date != null) 'date': date,
      if (balance != null) 'balance': balance,
      if (isUnchanged != null) 'is_unchanged': isUnchanged,
      if (remarks != null) 'remarks': remarks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceUpdatesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? accountId,
    Value<String>? date,
    Value<int>? balance,
    Value<bool>? isUnchanged,
    Value<String?>? remarks,
    Value<int>? rowid,
  }) {
    return BalanceUpdatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      balance: balance ?? this.balance,
      isUnchanged: isUnchanged ?? this.isUnchanged,
      remarks: remarks ?? this.remarks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (isUnchanged.present) {
      map['is_unchanged'] = Variable<bool>(isUnchanged.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceUpdatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('balance: $balance, ')
          ..write('isUnchanged: $isUnchanged, ')
          ..write('remarks: $remarks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoldItemsTable extends GoldItems
    with TableInfo<$GoldItemsTable, GoldItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoldItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMgMeta = const VerificationMeta(
    'weightMg',
  );
  @override
  late final GeneratedColumn<int> weightMg = GeneratedColumn<int>(
    'weight_mg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _karatMeta = const VerificationMeta('karat');
  @override
  late final GeneratedColumn<int> karat = GeneratedColumn<int>(
    'karat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<int> cost = GeneratedColumn<int>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('held'),
  );
  static const VerificationMeta _disposedDateMeta = const VerificationMeta(
    'disposedDate',
  );
  @override
  late final GeneratedColumn<String> disposedDate = GeneratedColumn<String>(
    'disposed_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    weightMg,
    karat,
    vendor,
    purchaseDate,
    cost,
    status,
    disposedDate,
    remarks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gold_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoldItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('weight_mg')) {
      context.handle(
        _weightMgMeta,
        weightMg.isAcceptableOrUnknown(data['weight_mg']!, _weightMgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMgMeta);
    }
    if (data.containsKey('karat')) {
      context.handle(
        _karatMeta,
        karat.isAcceptableOrUnknown(data['karat']!, _karatMeta),
      );
    } else if (isInserting) {
      context.missing(_karatMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('disposed_date')) {
      context.handle(
        _disposedDateMeta,
        disposedDate.isAcceptableOrUnknown(
          data['disposed_date']!,
          _disposedDateMeta,
        ),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoldItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoldItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      weightMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight_mg'],
      )!,
      karat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}karat'],
      )!,
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      disposedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disposed_date'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
    );
  }

  @override
  $GoldItemsTable createAlias(String alias) {
    return $GoldItemsTable(attachedDatabase, alias);
  }
}

class GoldItemRow extends DataClass implements Insertable<GoldItemRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String name;
  final int weightMg;
  final int karat;
  final String? vendor;
  final String purchaseDate;
  final int cost;
  final String status;
  final String? disposedDate;
  final String? remarks;
  const GoldItemRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.weightMg,
    required this.karat,
    this.vendor,
    required this.purchaseDate,
    required this.cost,
    required this.status,
    this.disposedDate,
    this.remarks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['name'] = Variable<String>(name);
    map['weight_mg'] = Variable<int>(weightMg);
    map['karat'] = Variable<int>(karat);
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    map['purchase_date'] = Variable<String>(purchaseDate);
    map['cost'] = Variable<int>(cost);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || disposedDate != null) {
      map['disposed_date'] = Variable<String>(disposedDate);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    return map;
  }

  GoldItemsCompanion toCompanion(bool nullToAbsent) {
    return GoldItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      weightMg: Value(weightMg),
      karat: Value(karat),
      vendor: vendor == null && nullToAbsent
          ? const Value.absent()
          : Value(vendor),
      purchaseDate: Value(purchaseDate),
      cost: Value(cost),
      status: Value(status),
      disposedDate: disposedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(disposedDate),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
    );
  }

  factory GoldItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoldItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      weightMg: serializer.fromJson<int>(json['weightMg']),
      karat: serializer.fromJson<int>(json['karat']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      purchaseDate: serializer.fromJson<String>(json['purchaseDate']),
      cost: serializer.fromJson<int>(json['cost']),
      status: serializer.fromJson<String>(json['status']),
      disposedDate: serializer.fromJson<String?>(json['disposedDate']),
      remarks: serializer.fromJson<String?>(json['remarks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'name': serializer.toJson<String>(name),
      'weightMg': serializer.toJson<int>(weightMg),
      'karat': serializer.toJson<int>(karat),
      'vendor': serializer.toJson<String?>(vendor),
      'purchaseDate': serializer.toJson<String>(purchaseDate),
      'cost': serializer.toJson<int>(cost),
      'status': serializer.toJson<String>(status),
      'disposedDate': serializer.toJson<String?>(disposedDate),
      'remarks': serializer.toJson<String?>(remarks),
    };
  }

  GoldItemRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? name,
    int? weightMg,
    int? karat,
    Value<String?> vendor = const Value.absent(),
    String? purchaseDate,
    int? cost,
    String? status,
    Value<String?> disposedDate = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
  }) => GoldItemRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    weightMg: weightMg ?? this.weightMg,
    karat: karat ?? this.karat,
    vendor: vendor.present ? vendor.value : this.vendor,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    cost: cost ?? this.cost,
    status: status ?? this.status,
    disposedDate: disposedDate.present ? disposedDate.value : this.disposedDate,
    remarks: remarks.present ? remarks.value : this.remarks,
  );
  GoldItemRow copyWithCompanion(GoldItemsCompanion data) {
    return GoldItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      weightMg: data.weightMg.present ? data.weightMg.value : this.weightMg,
      karat: data.karat.present ? data.karat.value : this.karat,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      cost: data.cost.present ? data.cost.value : this.cost,
      status: data.status.present ? data.status.value : this.status,
      disposedDate: data.disposedDate.present
          ? data.disposedDate.value
          : this.disposedDate,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoldItemRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('weightMg: $weightMg, ')
          ..write('karat: $karat, ')
          ..write('vendor: $vendor, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('cost: $cost, ')
          ..write('status: $status, ')
          ..write('disposedDate: $disposedDate, ')
          ..write('remarks: $remarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    weightMg,
    karat,
    vendor,
    purchaseDate,
    cost,
    status,
    disposedDate,
    remarks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoldItemRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.weightMg == this.weightMg &&
          other.karat == this.karat &&
          other.vendor == this.vendor &&
          other.purchaseDate == this.purchaseDate &&
          other.cost == this.cost &&
          other.status == this.status &&
          other.disposedDate == this.disposedDate &&
          other.remarks == this.remarks);
}

class GoldItemsCompanion extends UpdateCompanion<GoldItemRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> name;
  final Value<int> weightMg;
  final Value<int> karat;
  final Value<String?> vendor;
  final Value<String> purchaseDate;
  final Value<int> cost;
  final Value<String> status;
  final Value<String?> disposedDate;
  final Value<String?> remarks;
  final Value<int> rowid;
  const GoldItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.weightMg = const Value.absent(),
    this.karat = const Value.absent(),
    this.vendor = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.cost = const Value.absent(),
    this.status = const Value.absent(),
    this.disposedDate = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoldItemsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String name,
    required int weightMg,
    required int karat,
    this.vendor = const Value.absent(),
    required String purchaseDate,
    required int cost,
    this.status = const Value.absent(),
    this.disposedDate = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       weightMg = Value(weightMg),
       karat = Value(karat),
       purchaseDate = Value(purchaseDate),
       cost = Value(cost);
  static Insertable<GoldItemRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? name,
    Expression<int>? weightMg,
    Expression<int>? karat,
    Expression<String>? vendor,
    Expression<String>? purchaseDate,
    Expression<int>? cost,
    Expression<String>? status,
    Expression<String>? disposedDate,
    Expression<String>? remarks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (weightMg != null) 'weight_mg': weightMg,
      if (karat != null) 'karat': karat,
      if (vendor != null) 'vendor': vendor,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (cost != null) 'cost': cost,
      if (status != null) 'status': status,
      if (disposedDate != null) 'disposed_date': disposedDate,
      if (remarks != null) 'remarks': remarks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoldItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? name,
    Value<int>? weightMg,
    Value<int>? karat,
    Value<String?>? vendor,
    Value<String>? purchaseDate,
    Value<int>? cost,
    Value<String>? status,
    Value<String?>? disposedDate,
    Value<String?>? remarks,
    Value<int>? rowid,
  }) {
    return GoldItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      weightMg: weightMg ?? this.weightMg,
      karat: karat ?? this.karat,
      vendor: vendor ?? this.vendor,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      disposedDate: disposedDate ?? this.disposedDate,
      remarks: remarks ?? this.remarks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (weightMg.present) {
      map['weight_mg'] = Variable<int>(weightMg.value);
    }
    if (karat.present) {
      map['karat'] = Variable<int>(karat.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (cost.present) {
      map['cost'] = Variable<int>(cost.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (disposedDate.present) {
      map['disposed_date'] = Variable<String>(disposedDate.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoldItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('weightMg: $weightMg, ')
          ..write('karat: $karat, ')
          ..write('vendor: $vendor, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('cost: $cost, ')
          ..write('status: $status, ')
          ..write('disposedDate: $disposedDate, ')
          ..write('remarks: $remarks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KaratPricesTable extends KaratPrices
    with TableInfo<$KaratPricesTable, KaratPriceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KaratPricesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _karatMeta = const VerificationMeta('karat');
  @override
  late final GeneratedColumn<int> karat = GeneratedColumn<int>(
    'karat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerGramMeta = const VerificationMeta(
    'pricePerGram',
  );
  @override
  late final GeneratedColumn<int> pricePerGram = GeneratedColumn<int>(
    'price_per_gram',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    karat,
    pricePerGram,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'karat_prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<KaratPriceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('karat')) {
      context.handle(
        _karatMeta,
        karat.isAcceptableOrUnknown(data['karat']!, _karatMeta),
      );
    } else if (isInserting) {
      context.missing(_karatMeta);
    }
    if (data.containsKey('price_per_gram')) {
      context.handle(
        _pricePerGramMeta,
        pricePerGram.isAcceptableOrUnknown(
          data['price_per_gram']!,
          _pricePerGramMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerGramMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {karat, date},
  ];
  @override
  KaratPriceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KaratPriceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      karat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}karat'],
      )!,
      pricePerGram: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_gram'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $KaratPricesTable createAlias(String alias) {
    return $KaratPricesTable(attachedDatabase, alias);
  }
}

class KaratPriceRow extends DataClass implements Insertable<KaratPriceRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int karat;
  final int pricePerGram;
  final String date;
  const KaratPriceRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.karat,
    required this.pricePerGram,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['karat'] = Variable<int>(karat);
    map['price_per_gram'] = Variable<int>(pricePerGram);
    map['date'] = Variable<String>(date);
    return map;
  }

  KaratPricesCompanion toCompanion(bool nullToAbsent) {
    return KaratPricesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      karat: Value(karat),
      pricePerGram: Value(pricePerGram),
      date: Value(date),
    );
  }

  factory KaratPriceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KaratPriceRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      karat: serializer.fromJson<int>(json['karat']),
      pricePerGram: serializer.fromJson<int>(json['pricePerGram']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'karat': serializer.toJson<int>(karat),
      'pricePerGram': serializer.toJson<int>(pricePerGram),
      'date': serializer.toJson<String>(date),
    };
  }

  KaratPriceRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    int? karat,
    int? pricePerGram,
    String? date,
  }) => KaratPriceRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    karat: karat ?? this.karat,
    pricePerGram: pricePerGram ?? this.pricePerGram,
    date: date ?? this.date,
  );
  KaratPriceRow copyWithCompanion(KaratPricesCompanion data) {
    return KaratPriceRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      karat: data.karat.present ? data.karat.value : this.karat,
      pricePerGram: data.pricePerGram.present
          ? data.pricePerGram.value
          : this.pricePerGram,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KaratPriceRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('karat: $karat, ')
          ..write('pricePerGram: $pricePerGram, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, karat, pricePerGram, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KaratPriceRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.karat == this.karat &&
          other.pricePerGram == this.pricePerGram &&
          other.date == this.date);
}

class KaratPricesCompanion extends UpdateCompanion<KaratPriceRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> karat;
  final Value<int> pricePerGram;
  final Value<String> date;
  final Value<int> rowid;
  const KaratPricesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.karat = const Value.absent(),
    this.pricePerGram = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KaratPricesCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required int karat,
    required int pricePerGram,
    required String date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       karat = Value(karat),
       pricePerGram = Value(pricePerGram),
       date = Value(date);
  static Insertable<KaratPriceRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? karat,
    Expression<int>? pricePerGram,
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (karat != null) 'karat': karat,
      if (pricePerGram != null) 'price_per_gram': pricePerGram,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KaratPricesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? karat,
    Value<int>? pricePerGram,
    Value<String>? date,
    Value<int>? rowid,
  }) {
    return KaratPricesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      karat: karat ?? this.karat,
      pricePerGram: pricePerGram ?? this.pricePerGram,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (karat.present) {
      map['karat'] = Variable<int>(karat.value);
    }
    if (pricePerGram.present) {
      map['price_per_gram'] = Variable<int>(pricePerGram.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KaratPricesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('karat: $karat, ')
          ..write('pricePerGram: $pricePerGram, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRefundedMeta = const VerificationMeta(
    'isRefunded',
  );
  @override
  late final GeneratedColumn<bool> isRefunded = GeneratedColumn<bool>(
    'is_refunded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_refunded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _refundedAtMeta = const VerificationMeta(
    'refundedAt',
  );
  @override
  late final GeneratedColumn<int> refundedAt = GeneratedColumn<int>(
    'refunded_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    item,
    vendor,
    amount,
    date,
    isRefunded,
    refundedAt,
    remarks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_refunded')) {
      context.handle(
        _isRefundedMeta,
        isRefunded.isAcceptableOrUnknown(data['is_refunded']!, _isRefundedMeta),
      );
    }
    if (data.containsKey('refunded_at')) {
      context.handle(
        _refundedAtMeta,
        refundedAt.isAcceptableOrUnknown(data['refunded_at']!, _refundedAtMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      item: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item'],
      )!,
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      isRefunded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_refunded'],
      )!,
      refundedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refunded_at'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String item;
  final String vendor;
  final int amount;
  final String date;
  final bool isRefunded;
  final int? refundedAt;
  final String? remarks;
  const ExpenseRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.item,
    required this.vendor,
    required this.amount,
    required this.date,
    required this.isRefunded,
    this.refundedAt,
    this.remarks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['item'] = Variable<String>(item);
    map['vendor'] = Variable<String>(vendor);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<String>(date);
    map['is_refunded'] = Variable<bool>(isRefunded);
    if (!nullToAbsent || refundedAt != null) {
      map['refunded_at'] = Variable<int>(refundedAt);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      item: Value(item),
      vendor: Value(vendor),
      amount: Value(amount),
      date: Value(date),
      isRefunded: Value(isRefunded),
      refundedAt: refundedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(refundedAt),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      item: serializer.fromJson<String>(json['item']),
      vendor: serializer.fromJson<String>(json['vendor']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      isRefunded: serializer.fromJson<bool>(json['isRefunded']),
      refundedAt: serializer.fromJson<int?>(json['refundedAt']),
      remarks: serializer.fromJson<String?>(json['remarks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'item': serializer.toJson<String>(item),
      'vendor': serializer.toJson<String>(vendor),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<String>(date),
      'isRefunded': serializer.toJson<bool>(isRefunded),
      'refundedAt': serializer.toJson<int?>(refundedAt),
      'remarks': serializer.toJson<String?>(remarks),
    };
  }

  ExpenseRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? item,
    String? vendor,
    int? amount,
    String? date,
    bool? isRefunded,
    Value<int?> refundedAt = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
  }) => ExpenseRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    item: item ?? this.item,
    vendor: vendor ?? this.vendor,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    isRefunded: isRefunded ?? this.isRefunded,
    refundedAt: refundedAt.present ? refundedAt.value : this.refundedAt,
    remarks: remarks.present ? remarks.value : this.remarks,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      item: data.item.present ? data.item.value : this.item,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      isRefunded: data.isRefunded.present
          ? data.isRefunded.value
          : this.isRefunded,
      refundedAt: data.refundedAt.present
          ? data.refundedAt.value
          : this.refundedAt,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('item: $item, ')
          ..write('vendor: $vendor, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('isRefunded: $isRefunded, ')
          ..write('refundedAt: $refundedAt, ')
          ..write('remarks: $remarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    item,
    vendor,
    amount,
    date,
    isRefunded,
    refundedAt,
    remarks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.item == this.item &&
          other.vendor == this.vendor &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.isRefunded == this.isRefunded &&
          other.refundedAt == this.refundedAt &&
          other.remarks == this.remarks);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> item;
  final Value<String> vendor;
  final Value<int> amount;
  final Value<String> date;
  final Value<bool> isRefunded;
  final Value<int?> refundedAt;
  final Value<String?> remarks;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.item = const Value.absent(),
    this.vendor = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.isRefunded = const Value.absent(),
    this.refundedAt = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String item,
    required String vendor,
    required int amount,
    required String date,
    this.isRefunded = const Value.absent(),
    this.refundedAt = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       item = Value(item),
       vendor = Value(vendor),
       amount = Value(amount),
       date = Value(date);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? item,
    Expression<String>? vendor,
    Expression<int>? amount,
    Expression<String>? date,
    Expression<bool>? isRefunded,
    Expression<int>? refundedAt,
    Expression<String>? remarks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (item != null) 'item': item,
      if (vendor != null) 'vendor': vendor,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (isRefunded != null) 'is_refunded': isRefunded,
      if (refundedAt != null) 'refunded_at': refundedAt,
      if (remarks != null) 'remarks': remarks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? item,
    Value<String>? vendor,
    Value<int>? amount,
    Value<String>? date,
    Value<bool>? isRefunded,
    Value<int?>? refundedAt,
    Value<String?>? remarks,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      item: item ?? this.item,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isRefunded: isRefunded ?? this.isRefunded,
      refundedAt: refundedAt ?? this.refundedAt,
      remarks: remarks ?? this.remarks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (isRefunded.present) {
      map['is_refunded'] = Variable<bool>(isRefunded.value);
    }
    if (refundedAt.present) {
      map['refunded_at'] = Variable<int>(refundedAt.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('item: $item, ')
          ..write('vendor: $vendor, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('isRefunded: $isRefunded, ')
          ..write('refundedAt: $refundedAt, ')
          ..write('remarks: $remarks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
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
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeKbMeta = const VerificationMeta('sizeKb');
  @override
  late final GeneratedColumn<int> sizeKb = GeneratedColumn<int>(
    'size_kb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onKindleMeta = const VerificationMeta(
    'onKindle',
  );
  @override
  late final GeneratedColumn<bool> onKindle = GeneratedColumn<bool>(
    'on_kindle',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_kindle" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _acquisitionMeta = const VerificationMeta(
    'acquisition',
  );
  @override
  late final GeneratedColumn<String> acquisition = GeneratedColumn<String>(
    'acquisition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acquiredDateMeta = const VerificationMeta(
    'acquiredDate',
  );
  @override
  late final GeneratedColumn<String> acquiredDate = GeneratedColumn<String>(
    'acquired_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingHalfMeta = const VerificationMeta(
    'ratingHalf',
  );
  @override
  late final GeneratedColumn<int> ratingHalf = GeneratedColumn<int>(
    'rating_half',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    title,
    author,
    sizeKb,
    onKindle,
    status,
    acquisition,
    acquiredDate,
    amount,
    ratingHalf,
    remarks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('size_kb')) {
      context.handle(
        _sizeKbMeta,
        sizeKb.isAcceptableOrUnknown(data['size_kb']!, _sizeKbMeta),
      );
    }
    if (data.containsKey('on_kindle')) {
      context.handle(
        _onKindleMeta,
        onKindle.isAcceptableOrUnknown(data['on_kindle']!, _onKindleMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('acquisition')) {
      context.handle(
        _acquisitionMeta,
        acquisition.isAcceptableOrUnknown(
          data['acquisition']!,
          _acquisitionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_acquisitionMeta);
    }
    if (data.containsKey('acquired_date')) {
      context.handle(
        _acquiredDateMeta,
        acquiredDate.isAcceptableOrUnknown(
          data['acquired_date']!,
          _acquiredDateMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('rating_half')) {
      context.handle(
        _ratingHalfMeta,
        ratingHalf.isAcceptableOrUnknown(data['rating_half']!, _ratingHalfMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      sizeKb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_kb'],
      ),
      onKindle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_kindle'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      acquisition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acquisition'],
      )!,
      acquiredDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acquired_date'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      ),
      ratingHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_half'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String title;
  final String? author;
  final int? sizeKb;
  final bool onKindle;
  final String status;
  final String acquisition;
  final String? acquiredDate;
  final int? amount;
  final int? ratingHalf;
  final String? remarks;
  const BookRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.author,
    this.sizeKb,
    required this.onKindle,
    required this.status,
    required this.acquisition,
    this.acquiredDate,
    this.amount,
    this.ratingHalf,
    this.remarks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || sizeKb != null) {
      map['size_kb'] = Variable<int>(sizeKb);
    }
    map['on_kindle'] = Variable<bool>(onKindle);
    map['status'] = Variable<String>(status);
    map['acquisition'] = Variable<String>(acquisition);
    if (!nullToAbsent || acquiredDate != null) {
      map['acquired_date'] = Variable<String>(acquiredDate);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<int>(amount);
    }
    if (!nullToAbsent || ratingHalf != null) {
      map['rating_half'] = Variable<int>(ratingHalf);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      sizeKb: sizeKb == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeKb),
      onKindle: Value(onKindle),
      status: Value(status),
      acquisition: Value(acquisition),
      acquiredDate: acquiredDate == null && nullToAbsent
          ? const Value.absent()
          : Value(acquiredDate),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      ratingHalf: ratingHalf == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingHalf),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      sizeKb: serializer.fromJson<int?>(json['sizeKb']),
      onKindle: serializer.fromJson<bool>(json['onKindle']),
      status: serializer.fromJson<String>(json['status']),
      acquisition: serializer.fromJson<String>(json['acquisition']),
      acquiredDate: serializer.fromJson<String?>(json['acquiredDate']),
      amount: serializer.fromJson<int?>(json['amount']),
      ratingHalf: serializer.fromJson<int?>(json['ratingHalf']),
      remarks: serializer.fromJson<String?>(json['remarks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'sizeKb': serializer.toJson<int?>(sizeKb),
      'onKindle': serializer.toJson<bool>(onKindle),
      'status': serializer.toJson<String>(status),
      'acquisition': serializer.toJson<String>(acquisition),
      'acquiredDate': serializer.toJson<String?>(acquiredDate),
      'amount': serializer.toJson<int?>(amount),
      'ratingHalf': serializer.toJson<int?>(ratingHalf),
      'remarks': serializer.toJson<String?>(remarks),
    };
  }

  BookRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<int?> sizeKb = const Value.absent(),
    bool? onKindle,
    String? status,
    String? acquisition,
    Value<String?> acquiredDate = const Value.absent(),
    Value<int?> amount = const Value.absent(),
    Value<int?> ratingHalf = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
  }) => BookRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    sizeKb: sizeKb.present ? sizeKb.value : this.sizeKb,
    onKindle: onKindle ?? this.onKindle,
    status: status ?? this.status,
    acquisition: acquisition ?? this.acquisition,
    acquiredDate: acquiredDate.present ? acquiredDate.value : this.acquiredDate,
    amount: amount.present ? amount.value : this.amount,
    ratingHalf: ratingHalf.present ? ratingHalf.value : this.ratingHalf,
    remarks: remarks.present ? remarks.value : this.remarks,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      sizeKb: data.sizeKb.present ? data.sizeKb.value : this.sizeKb,
      onKindle: data.onKindle.present ? data.onKindle.value : this.onKindle,
      status: data.status.present ? data.status.value : this.status,
      acquisition: data.acquisition.present
          ? data.acquisition.value
          : this.acquisition,
      acquiredDate: data.acquiredDate.present
          ? data.acquiredDate.value
          : this.acquiredDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      ratingHalf: data.ratingHalf.present
          ? data.ratingHalf.value
          : this.ratingHalf,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('sizeKb: $sizeKb, ')
          ..write('onKindle: $onKindle, ')
          ..write('status: $status, ')
          ..write('acquisition: $acquisition, ')
          ..write('acquiredDate: $acquiredDate, ')
          ..write('amount: $amount, ')
          ..write('ratingHalf: $ratingHalf, ')
          ..write('remarks: $remarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    title,
    author,
    sizeKb,
    onKindle,
    status,
    acquisition,
    acquiredDate,
    amount,
    ratingHalf,
    remarks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.title == this.title &&
          other.author == this.author &&
          other.sizeKb == this.sizeKb &&
          other.onKindle == this.onKindle &&
          other.status == this.status &&
          other.acquisition == this.acquisition &&
          other.acquiredDate == this.acquiredDate &&
          other.amount == this.amount &&
          other.ratingHalf == this.ratingHalf &&
          other.remarks == this.remarks);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> title;
  final Value<String?> author;
  final Value<int?> sizeKb;
  final Value<bool> onKindle;
  final Value<String> status;
  final Value<String> acquisition;
  final Value<String?> acquiredDate;
  final Value<int?> amount;
  final Value<int?> ratingHalf;
  final Value<String?> remarks;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.sizeKb = const Value.absent(),
    this.onKindle = const Value.absent(),
    this.status = const Value.absent(),
    this.acquisition = const Value.absent(),
    this.acquiredDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.ratingHalf = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String title,
    this.author = const Value.absent(),
    this.sizeKb = const Value.absent(),
    this.onKindle = const Value.absent(),
    required String status,
    required String acquisition,
    this.acquiredDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.ratingHalf = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       title = Value(title),
       status = Value(status),
       acquisition = Value(acquisition);
  static Insertable<BookRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? title,
    Expression<String>? author,
    Expression<int>? sizeKb,
    Expression<bool>? onKindle,
    Expression<String>? status,
    Expression<String>? acquisition,
    Expression<String>? acquiredDate,
    Expression<int>? amount,
    Expression<int>? ratingHalf,
    Expression<String>? remarks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (sizeKb != null) 'size_kb': sizeKb,
      if (onKindle != null) 'on_kindle': onKindle,
      if (status != null) 'status': status,
      if (acquisition != null) 'acquisition': acquisition,
      if (acquiredDate != null) 'acquired_date': acquiredDate,
      if (amount != null) 'amount': amount,
      if (ratingHalf != null) 'rating_half': ratingHalf,
      if (remarks != null) 'remarks': remarks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? title,
    Value<String?>? author,
    Value<int?>? sizeKb,
    Value<bool>? onKindle,
    Value<String>? status,
    Value<String>? acquisition,
    Value<String?>? acquiredDate,
    Value<int?>? amount,
    Value<int?>? ratingHalf,
    Value<String?>? remarks,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      author: author ?? this.author,
      sizeKb: sizeKb ?? this.sizeKb,
      onKindle: onKindle ?? this.onKindle,
      status: status ?? this.status,
      acquisition: acquisition ?? this.acquisition,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      amount: amount ?? this.amount,
      ratingHalf: ratingHalf ?? this.ratingHalf,
      remarks: remarks ?? this.remarks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (sizeKb.present) {
      map['size_kb'] = Variable<int>(sizeKb.value);
    }
    if (onKindle.present) {
      map['on_kindle'] = Variable<bool>(onKindle.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (acquisition.present) {
      map['acquisition'] = Variable<String>(acquisition.value);
    }
    if (acquiredDate.present) {
      map['acquired_date'] = Variable<String>(acquiredDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (ratingHalf.present) {
      map['rating_half'] = Variable<int>(ratingHalf.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('sizeKb: $sizeKb, ')
          ..write('onKindle: $onKindle, ')
          ..write('status: $status, ')
          ..write('acquisition: $acquisition, ')
          ..write('acquiredDate: $acquiredDate, ')
          ..write('amount: $amount, ')
          ..write('ratingHalf: $ratingHalf, ')
          ..write('remarks: $remarks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, FolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class FolderRow extends DataClass implements Insertable<FolderRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String name;
  final int sortOrder;
  const FolderRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory FolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FolderRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? name,
    int? sortOrder,
  }) => FolderRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  FolderRow copyWithCompanion(FoldersCompanion data) {
    return FolderRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class FoldersCompanion extends UpdateCompanion<FolderRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<FolderRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String name;
  const TagRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'name': serializer.toJson<String>(name),
    };
  }

  TagRow copyWith({String? id, int? createdAt, int? updatedAt, String? name}) =>
      TagRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        name: name ?? this.name,
      );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> name;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plainTextMeta = const VerificationMeta(
    'plainText',
  );
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
    'plain_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta(
    'pinnedAt',
  );
  @override
  late final GeneratedColumn<int> pinnedAt = GeneratedColumn<int>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cipherMeta = const VerificationMeta('cipher');
  @override
  late final GeneratedColumn<String> cipher = GeneratedColumn<String>(
    'cipher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trashedAtMeta = const VerificationMeta(
    'trashedAt',
  );
  @override
  late final GeneratedColumn<int> trashedAt = GeneratedColumn<int>(
    'trashed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    folderId,
    title,
    content,
    plainText,
    isPinned,
    pinnedAt,
    isLocked,
    cipher,
    editedAt,
    trashedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('plain_text')) {
      context.handle(
        _plainTextMeta,
        plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('cipher')) {
      context.handle(
        _cipherMeta,
        cipher.isAcceptableOrUnknown(data['cipher']!, _cipherMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('trashed_at')) {
      context.handle(
        _trashedAtMeta,
        trashedAt.isAcceptableOrUnknown(data['trashed_at']!, _trashedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      plainText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plain_text'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      pinnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pinned_at'],
      ),
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      cipher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cipher'],
      ),
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
      trashedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trashed_at'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String? folderId;
  final String? title;
  final String? content;
  final String? plainText;
  final bool isPinned;
  final int? pinnedAt;
  final bool isLocked;
  final String? cipher;
  final int editedAt;
  final int? trashedAt;
  const NoteRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.title,
    this.content,
    this.plainText,
    required this.isPinned,
    this.pinnedAt,
    required this.isLocked,
    this.cipher,
    required this.editedAt,
    this.trashedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || plainText != null) {
      map['plain_text'] = Variable<String>(plainText);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<int>(pinnedAt);
    }
    map['is_locked'] = Variable<bool>(isLocked);
    if (!nullToAbsent || cipher != null) {
      map['cipher'] = Variable<String>(cipher);
    }
    map['edited_at'] = Variable<int>(editedAt);
    if (!nullToAbsent || trashedAt != null) {
      map['trashed_at'] = Variable<int>(trashedAt);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      plainText: plainText == null && nullToAbsent
          ? const Value.absent()
          : Value(plainText),
      isPinned: Value(isPinned),
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
      isLocked: Value(isLocked),
      cipher: cipher == null && nullToAbsent
          ? const Value.absent()
          : Value(cipher),
      editedAt: Value(editedAt),
      trashedAt: trashedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trashedAt),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      plainText: serializer.fromJson<String?>(json['plainText']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      pinnedAt: serializer.fromJson<int?>(json['pinnedAt']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      cipher: serializer.fromJson<String?>(json['cipher']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
      trashedAt: serializer.fromJson<int?>(json['trashedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'folderId': serializer.toJson<String?>(folderId),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String?>(content),
      'plainText': serializer.toJson<String?>(plainText),
      'isPinned': serializer.toJson<bool>(isPinned),
      'pinnedAt': serializer.toJson<int?>(pinnedAt),
      'isLocked': serializer.toJson<bool>(isLocked),
      'cipher': serializer.toJson<String?>(cipher),
      'editedAt': serializer.toJson<int>(editedAt),
      'trashedAt': serializer.toJson<int?>(trashedAt),
    };
  }

  NoteRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<String?> folderId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> plainText = const Value.absent(),
    bool? isPinned,
    Value<int?> pinnedAt = const Value.absent(),
    bool? isLocked,
    Value<String?> cipher = const Value.absent(),
    int? editedAt,
    Value<int?> trashedAt = const Value.absent(),
  }) => NoteRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    folderId: folderId.present ? folderId.value : this.folderId,
    title: title.present ? title.value : this.title,
    content: content.present ? content.value : this.content,
    plainText: plainText.present ? plainText.value : this.plainText,
    isPinned: isPinned ?? this.isPinned,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    isLocked: isLocked ?? this.isLocked,
    cipher: cipher.present ? cipher.value : this.cipher,
    editedAt: editedAt ?? this.editedAt,
    trashedAt: trashedAt.present ? trashedAt.value : this.trashedAt,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      cipher: data.cipher.present ? data.cipher.value : this.cipher,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      trashedAt: data.trashedAt.present ? data.trashedAt.value : this.trashedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('folderId: $folderId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('plainText: $plainText, ')
          ..write('isPinned: $isPinned, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('isLocked: $isLocked, ')
          ..write('cipher: $cipher, ')
          ..write('editedAt: $editedAt, ')
          ..write('trashedAt: $trashedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    folderId,
    title,
    content,
    plainText,
    isPinned,
    pinnedAt,
    isLocked,
    cipher,
    editedAt,
    trashedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.folderId == this.folderId &&
          other.title == this.title &&
          other.content == this.content &&
          other.plainText == this.plainText &&
          other.isPinned == this.isPinned &&
          other.pinnedAt == this.pinnedAt &&
          other.isLocked == this.isLocked &&
          other.cipher == this.cipher &&
          other.editedAt == this.editedAt &&
          other.trashedAt == this.trashedAt);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String?> folderId;
  final Value<String?> title;
  final Value<String?> content;
  final Value<String?> plainText;
  final Value<bool> isPinned;
  final Value<int?> pinnedAt;
  final Value<bool> isLocked;
  final Value<String?> cipher;
  final Value<int> editedAt;
  final Value<int?> trashedAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.folderId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.plainText = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.cipher = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required int createdAt,
    required int updatedAt,
    this.folderId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.plainText = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.cipher = const Value.absent(),
    required int editedAt,
    this.trashedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       editedAt = Value(editedAt);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? folderId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? plainText,
    Expression<bool>? isPinned,
    Expression<int>? pinnedAt,
    Expression<bool>? isLocked,
    Expression<String>? cipher,
    Expression<int>? editedAt,
    Expression<int>? trashedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (folderId != null) 'folder_id': folderId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (plainText != null) 'plain_text': plainText,
      if (isPinned != null) 'is_pinned': isPinned,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (isLocked != null) 'is_locked': isLocked,
      if (cipher != null) 'cipher': cipher,
      if (editedAt != null) 'edited_at': editedAt,
      if (trashedAt != null) 'trashed_at': trashedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String?>? folderId,
    Value<String?>? title,
    Value<String?>? content,
    Value<String?>? plainText,
    Value<bool>? isPinned,
    Value<int?>? pinnedAt,
    Value<bool>? isLocked,
    Value<String?>? cipher,
    Value<int>? editedAt,
    Value<int?>? trashedAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isLocked: isLocked ?? this.isLocked,
      cipher: cipher ?? this.cipher,
      editedAt: editedAt ?? this.editedAt,
      trashedAt: trashedAt ?? this.trashedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<int>(pinnedAt.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (cipher.present) {
      map['cipher'] = Variable<String>(cipher.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (trashedAt.present) {
      map['trashed_at'] = Variable<int>(trashedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('folderId: $folderId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('plainText: $plainText, ')
          ..write('isPinned: $isPinned, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('isLocked: $isLocked, ')
          ..write('cipher: $cipher, ')
          ..write('editedAt: $editedAt, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteTagsTable extends NoteTags
    with TableInfo<$NoteTagsTable, NoteTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, tagId};
  @override
  NoteTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTagRow(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $NoteTagsTable createAlias(String alias) {
    return $NoteTagsTable(attachedDatabase, alias);
  }
}

class NoteTagRow extends DataClass implements Insertable<NoteTagRow> {
  final String noteId;
  final String tagId;
  const NoteTagRow({required this.noteId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  NoteTagsCompanion toCompanion(bool nullToAbsent) {
    return NoteTagsCompanion(noteId: Value(noteId), tagId: Value(tagId));
  }

  factory NoteTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTagRow(
      noteId: serializer.fromJson<String>(json['noteId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  NoteTagRow copyWith({String? noteId, String? tagId}) =>
      NoteTagRow(noteId: noteId ?? this.noteId, tagId: tagId ?? this.tagId);
  NoteTagRow copyWithCompanion(NoteTagsCompanion data) {
    return NoteTagRow(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagRow(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTagRow &&
          other.noteId == this.noteId &&
          other.tagId == this.tagId);
}

class NoteTagsCompanion extends UpdateCompanion<NoteTagRow> {
  final Value<String> noteId;
  final Value<String> tagId;
  final Value<int> rowid;
  const NoteTagsCompanion({
    this.noteId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteTagsCompanion.insert({
    required String noteId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       tagId = Value(tagId);
  static Insertable<NoteTagRow> custom({
    Expression<String>? noteId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteTagsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return NoteTagsCompanion(
      noteId: noteId ?? this.noteId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteDraftsTable extends NoteDrafts
    with TableInfo<$NoteDraftsTable, NoteDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<int> savedAt = GeneratedColumn<int>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, content, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId};
  @override
  NoteDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteDraftRow(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $NoteDraftsTable createAlias(String alias) {
    return $NoteDraftsTable(attachedDatabase, alias);
  }
}

class NoteDraftRow extends DataClass implements Insertable<NoteDraftRow> {
  final String noteId;
  final String content;
  final int savedAt;
  const NoteDraftRow({
    required this.noteId,
    required this.content,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['content'] = Variable<String>(content);
    map['saved_at'] = Variable<int>(savedAt);
    return map;
  }

  NoteDraftsCompanion toCompanion(bool nullToAbsent) {
    return NoteDraftsCompanion(
      noteId: Value(noteId),
      content: Value(content),
      savedAt: Value(savedAt),
    );
  }

  factory NoteDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteDraftRow(
      noteId: serializer.fromJson<String>(json['noteId']),
      content: serializer.fromJson<String>(json['content']),
      savedAt: serializer.fromJson<int>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'content': serializer.toJson<String>(content),
      'savedAt': serializer.toJson<int>(savedAt),
    };
  }

  NoteDraftRow copyWith({String? noteId, String? content, int? savedAt}) =>
      NoteDraftRow(
        noteId: noteId ?? this.noteId,
        content: content ?? this.content,
        savedAt: savedAt ?? this.savedAt,
      );
  NoteDraftRow copyWithCompanion(NoteDraftsCompanion data) {
    return NoteDraftRow(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      content: data.content.present ? data.content.value : this.content,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteDraftRow(')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, content, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteDraftRow &&
          other.noteId == this.noteId &&
          other.content == this.content &&
          other.savedAt == this.savedAt);
}

class NoteDraftsCompanion extends UpdateCompanion<NoteDraftRow> {
  final Value<String> noteId;
  final Value<String> content;
  final Value<int> savedAt;
  final Value<int> rowid;
  const NoteDraftsCompanion({
    this.noteId = const Value.absent(),
    this.content = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteDraftsCompanion.insert({
    required String noteId,
    required String content,
    required int savedAt,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       content = Value(content),
       savedAt = Value(savedAt);
  static Insertable<NoteDraftRow> custom({
    Expression<String>? noteId,
    Expression<String>? content,
    Expression<int>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (content != null) 'content': content,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteDraftsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? content,
    Value<int>? savedAt,
    Value<int>? rowid,
  }) {
    return NoteDraftsCompanion(
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<int>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteDraftsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultTable extends Vault with TableInfo<$VaultTable, VaultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kdfParamsMeta = const VerificationMeta(
    'kdfParams',
  );
  @override
  late final GeneratedColumn<String> kdfParams = GeneratedColumn<String>(
    'kdf_params',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<Uint8List> salt = GeneratedColumn<Uint8List>(
    'salt',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltRecoveryMeta = const VerificationMeta(
    'saltRecovery',
  );
  @override
  late final GeneratedColumn<Uint8List> saltRecovery =
      GeneratedColumn<Uint8List>(
        'salt_recovery',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wrappedKeyPasswordMeta =
      const VerificationMeta('wrappedKeyPassword');
  @override
  late final GeneratedColumn<Uint8List> wrappedKeyPassword =
      GeneratedColumn<Uint8List>(
        'wrapped_key_password',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wrappedKeyRecoveryMeta =
      const VerificationMeta('wrappedKeyRecovery');
  @override
  late final GeneratedColumn<Uint8List> wrappedKeyRecovery =
      GeneratedColumn<Uint8List>(
        'wrapped_key_recovery',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _keyCheckMeta = const VerificationMeta(
    'keyCheck',
  );
  @override
  late final GeneratedColumn<Uint8List> keyCheck = GeneratedColumn<Uint8List>(
    'key_check',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kdfParams,
    salt,
    saltRecovery,
    wrappedKeyPassword,
    wrappedKeyRecovery,
    keyCheck,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kdf_params')) {
      context.handle(
        _kdfParamsMeta,
        kdfParams.isAcceptableOrUnknown(data['kdf_params']!, _kdfParamsMeta),
      );
    } else if (isInserting) {
      context.missing(_kdfParamsMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
        _saltMeta,
        salt.isAcceptableOrUnknown(data['salt']!, _saltMeta),
      );
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('salt_recovery')) {
      context.handle(
        _saltRecoveryMeta,
        saltRecovery.isAcceptableOrUnknown(
          data['salt_recovery']!,
          _saltRecoveryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saltRecoveryMeta);
    }
    if (data.containsKey('wrapped_key_password')) {
      context.handle(
        _wrappedKeyPasswordMeta,
        wrappedKeyPassword.isAcceptableOrUnknown(
          data['wrapped_key_password']!,
          _wrappedKeyPasswordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wrappedKeyPasswordMeta);
    }
    if (data.containsKey('wrapped_key_recovery')) {
      context.handle(
        _wrappedKeyRecoveryMeta,
        wrappedKeyRecovery.isAcceptableOrUnknown(
          data['wrapped_key_recovery']!,
          _wrappedKeyRecoveryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wrappedKeyRecoveryMeta);
    }
    if (data.containsKey('key_check')) {
      context.handle(
        _keyCheckMeta,
        keyCheck.isAcceptableOrUnknown(data['key_check']!, _keyCheckMeta),
      );
    } else if (isInserting) {
      context.missing(_keyCheckMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kdfParams: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kdf_params'],
      )!,
      salt: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}salt'],
      )!,
      saltRecovery: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}salt_recovery'],
      )!,
      wrappedKeyPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}wrapped_key_password'],
      )!,
      wrappedKeyRecovery: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}wrapped_key_recovery'],
      )!,
      keyCheck: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}key_check'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultTable createAlias(String alias) {
    return $VaultTable(attachedDatabase, alias);
  }
}

class VaultRow extends DataClass implements Insertable<VaultRow> {
  final int id;
  final String kdfParams;
  final Uint8List salt;
  final Uint8List saltRecovery;
  final Uint8List wrappedKeyPassword;
  final Uint8List wrappedKeyRecovery;
  final Uint8List keyCheck;
  final int createdAt;
  final int updatedAt;
  const VaultRow({
    required this.id,
    required this.kdfParams,
    required this.salt,
    required this.saltRecovery,
    required this.wrappedKeyPassword,
    required this.wrappedKeyRecovery,
    required this.keyCheck,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kdf_params'] = Variable<String>(kdfParams);
    map['salt'] = Variable<Uint8List>(salt);
    map['salt_recovery'] = Variable<Uint8List>(saltRecovery);
    map['wrapped_key_password'] = Variable<Uint8List>(wrappedKeyPassword);
    map['wrapped_key_recovery'] = Variable<Uint8List>(wrappedKeyRecovery);
    map['key_check'] = Variable<Uint8List>(keyCheck);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultCompanion toCompanion(bool nullToAbsent) {
    return VaultCompanion(
      id: Value(id),
      kdfParams: Value(kdfParams),
      salt: Value(salt),
      saltRecovery: Value(saltRecovery),
      wrappedKeyPassword: Value(wrappedKeyPassword),
      wrappedKeyRecovery: Value(wrappedKeyRecovery),
      keyCheck: Value(keyCheck),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultRow(
      id: serializer.fromJson<int>(json['id']),
      kdfParams: serializer.fromJson<String>(json['kdfParams']),
      salt: serializer.fromJson<Uint8List>(json['salt']),
      saltRecovery: serializer.fromJson<Uint8List>(json['saltRecovery']),
      wrappedKeyPassword: serializer.fromJson<Uint8List>(
        json['wrappedKeyPassword'],
      ),
      wrappedKeyRecovery: serializer.fromJson<Uint8List>(
        json['wrappedKeyRecovery'],
      ),
      keyCheck: serializer.fromJson<Uint8List>(json['keyCheck']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kdfParams': serializer.toJson<String>(kdfParams),
      'salt': serializer.toJson<Uint8List>(salt),
      'saltRecovery': serializer.toJson<Uint8List>(saltRecovery),
      'wrappedKeyPassword': serializer.toJson<Uint8List>(wrappedKeyPassword),
      'wrappedKeyRecovery': serializer.toJson<Uint8List>(wrappedKeyRecovery),
      'keyCheck': serializer.toJson<Uint8List>(keyCheck),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultRow copyWith({
    int? id,
    String? kdfParams,
    Uint8List? salt,
    Uint8List? saltRecovery,
    Uint8List? wrappedKeyPassword,
    Uint8List? wrappedKeyRecovery,
    Uint8List? keyCheck,
    int? createdAt,
    int? updatedAt,
  }) => VaultRow(
    id: id ?? this.id,
    kdfParams: kdfParams ?? this.kdfParams,
    salt: salt ?? this.salt,
    saltRecovery: saltRecovery ?? this.saltRecovery,
    wrappedKeyPassword: wrappedKeyPassword ?? this.wrappedKeyPassword,
    wrappedKeyRecovery: wrappedKeyRecovery ?? this.wrappedKeyRecovery,
    keyCheck: keyCheck ?? this.keyCheck,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultRow copyWithCompanion(VaultCompanion data) {
    return VaultRow(
      id: data.id.present ? data.id.value : this.id,
      kdfParams: data.kdfParams.present ? data.kdfParams.value : this.kdfParams,
      salt: data.salt.present ? data.salt.value : this.salt,
      saltRecovery: data.saltRecovery.present
          ? data.saltRecovery.value
          : this.saltRecovery,
      wrappedKeyPassword: data.wrappedKeyPassword.present
          ? data.wrappedKeyPassword.value
          : this.wrappedKeyPassword,
      wrappedKeyRecovery: data.wrappedKeyRecovery.present
          ? data.wrappedKeyRecovery.value
          : this.wrappedKeyRecovery,
      keyCheck: data.keyCheck.present ? data.keyCheck.value : this.keyCheck,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultRow(')
          ..write('id: $id, ')
          ..write('kdfParams: $kdfParams, ')
          ..write('salt: $salt, ')
          ..write('saltRecovery: $saltRecovery, ')
          ..write('wrappedKeyPassword: $wrappedKeyPassword, ')
          ..write('wrappedKeyRecovery: $wrappedKeyRecovery, ')
          ..write('keyCheck: $keyCheck, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kdfParams,
    $driftBlobEquality.hash(salt),
    $driftBlobEquality.hash(saltRecovery),
    $driftBlobEquality.hash(wrappedKeyPassword),
    $driftBlobEquality.hash(wrappedKeyRecovery),
    $driftBlobEquality.hash(keyCheck),
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultRow &&
          other.id == this.id &&
          other.kdfParams == this.kdfParams &&
          $driftBlobEquality.equals(other.salt, this.salt) &&
          $driftBlobEquality.equals(other.saltRecovery, this.saltRecovery) &&
          $driftBlobEquality.equals(
            other.wrappedKeyPassword,
            this.wrappedKeyPassword,
          ) &&
          $driftBlobEquality.equals(
            other.wrappedKeyRecovery,
            this.wrappedKeyRecovery,
          ) &&
          $driftBlobEquality.equals(other.keyCheck, this.keyCheck) &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VaultCompanion extends UpdateCompanion<VaultRow> {
  final Value<int> id;
  final Value<String> kdfParams;
  final Value<Uint8List> salt;
  final Value<Uint8List> saltRecovery;
  final Value<Uint8List> wrappedKeyPassword;
  final Value<Uint8List> wrappedKeyRecovery;
  final Value<Uint8List> keyCheck;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const VaultCompanion({
    this.id = const Value.absent(),
    this.kdfParams = const Value.absent(),
    this.salt = const Value.absent(),
    this.saltRecovery = const Value.absent(),
    this.wrappedKeyPassword = const Value.absent(),
    this.wrappedKeyRecovery = const Value.absent(),
    this.keyCheck = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VaultCompanion.insert({
    this.id = const Value.absent(),
    required String kdfParams,
    required Uint8List salt,
    required Uint8List saltRecovery,
    required Uint8List wrappedKeyPassword,
    required Uint8List wrappedKeyRecovery,
    required Uint8List keyCheck,
    required int createdAt,
    required int updatedAt,
  }) : kdfParams = Value(kdfParams),
       salt = Value(salt),
       saltRecovery = Value(saltRecovery),
       wrappedKeyPassword = Value(wrappedKeyPassword),
       wrappedKeyRecovery = Value(wrappedKeyRecovery),
       keyCheck = Value(keyCheck),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VaultRow> custom({
    Expression<int>? id,
    Expression<String>? kdfParams,
    Expression<Uint8List>? salt,
    Expression<Uint8List>? saltRecovery,
    Expression<Uint8List>? wrappedKeyPassword,
    Expression<Uint8List>? wrappedKeyRecovery,
    Expression<Uint8List>? keyCheck,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kdfParams != null) 'kdf_params': kdfParams,
      if (salt != null) 'salt': salt,
      if (saltRecovery != null) 'salt_recovery': saltRecovery,
      if (wrappedKeyPassword != null)
        'wrapped_key_password': wrappedKeyPassword,
      if (wrappedKeyRecovery != null)
        'wrapped_key_recovery': wrappedKeyRecovery,
      if (keyCheck != null) 'key_check': keyCheck,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VaultCompanion copyWith({
    Value<int>? id,
    Value<String>? kdfParams,
    Value<Uint8List>? salt,
    Value<Uint8List>? saltRecovery,
    Value<Uint8List>? wrappedKeyPassword,
    Value<Uint8List>? wrappedKeyRecovery,
    Value<Uint8List>? keyCheck,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return VaultCompanion(
      id: id ?? this.id,
      kdfParams: kdfParams ?? this.kdfParams,
      salt: salt ?? this.salt,
      saltRecovery: saltRecovery ?? this.saltRecovery,
      wrappedKeyPassword: wrappedKeyPassword ?? this.wrappedKeyPassword,
      wrappedKeyRecovery: wrappedKeyRecovery ?? this.wrappedKeyRecovery,
      keyCheck: keyCheck ?? this.keyCheck,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kdfParams.present) {
      map['kdf_params'] = Variable<String>(kdfParams.value);
    }
    if (salt.present) {
      map['salt'] = Variable<Uint8List>(salt.value);
    }
    if (saltRecovery.present) {
      map['salt_recovery'] = Variable<Uint8List>(saltRecovery.value);
    }
    if (wrappedKeyPassword.present) {
      map['wrapped_key_password'] = Variable<Uint8List>(
        wrappedKeyPassword.value,
      );
    }
    if (wrappedKeyRecovery.present) {
      map['wrapped_key_recovery'] = Variable<Uint8List>(
        wrappedKeyRecovery.value,
      );
    }
    if (keyCheck.present) {
      map['key_check'] = Variable<Uint8List>(keyCheck.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultCompanion(')
          ..write('id: $id, ')
          ..write('kdfParams: $kdfParams, ')
          ..write('salt: $salt, ')
          ..write('saltRecovery: $saltRecovery, ')
          ..write('wrappedKeyPassword: $wrappedKeyPassword, ')
          ..write('wrappedKeyRecovery: $wrappedKeyRecovery, ')
          ..write('keyCheck: $keyCheck, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $DeletionsTable deletions = $DeletionsTable(this);
  late final $ExportsLogTable exportsLog = $ExportsLogTable(this);
  late final $SavingsAccountsTable savingsAccounts = $SavingsAccountsTable(
    this,
  );
  late final $BalanceUpdatesTable balanceUpdates = $BalanceUpdatesTable(this);
  late final $GoldItemsTable goldItems = $GoldItemsTable(this);
  late final $KaratPricesTable karatPrices = $KaratPricesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $NoteTagsTable noteTags = $NoteTagsTable(this);
  late final $NoteDraftsTable noteDrafts = $NoteDraftsTable(this);
  late final $VaultTable vault = $VaultTable(this);
  late final Index idxBalanceUpdatesAccountDate = Index(
    'idx_balance_updates_account_date',
    'CREATE INDEX idx_balance_updates_account_date ON balance_updates (account_id, date)',
  );
  late final Index idxGoldItemsStatus = Index(
    'idx_gold_items_status',
    'CREATE INDEX idx_gold_items_status ON gold_items (status)',
  );
  late final Index idxKaratPricesKaratDate = Index(
    'idx_karat_prices_karat_date',
    'CREATE INDEX idx_karat_prices_karat_date ON karat_prices (karat, date)',
  );
  late final Index idxExpensesDate = Index(
    'idx_expenses_date',
    'CREATE INDEX idx_expenses_date ON expenses (date)',
  );
  late final Index idxExpensesVendor = Index(
    'idx_expenses_vendor',
    'CREATE INDEX idx_expenses_vendor ON expenses (vendor)',
  );
  late final Index idxBooksStatus = Index(
    'idx_books_status',
    'CREATE INDEX idx_books_status ON books (status)',
  );
  late final Index idxBooksAcquiredDate = Index(
    'idx_books_acquired_date',
    'CREATE INDEX idx_books_acquired_date ON books (acquired_date)',
  );
  late final Index idxNotesList = Index(
    'idx_notes_list',
    'CREATE INDEX idx_notes_list ON notes (trashed_at, is_pinned, edited_at)',
  );
  late final Index idxNotesFolder = Index(
    'idx_notes_folder',
    'CREATE INDEX idx_notes_folder ON notes (folder_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMeta,
    settings,
    deletions,
    exportsLog,
    savingsAccounts,
    balanceUpdates,
    goldItems,
    karatPrices,
    expenses,
    books,
    folders,
    tags,
    notes,
    noteTags,
    noteDrafts,
    vault,
    idxBalanceUpdatesAccountDate,
    idxGoldItemsStatus,
    idxKaratPricesKaratDate,
    idxExpensesDate,
    idxExpensesVendor,
    idxBooksStatus,
    idxBooksAcquiredDate,
    idxNotesList,
    idxNotesFolder,
  ];
}

typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
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

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
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

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
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

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, AppMetaRow>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$DeletionsTableCreateCompanionBuilder = DeletionsCompanion Function({
  required String entity,
  required String recordId,
  required int deletedAt,
  Value<int> rowid,
});
typedef $$DeletionsTableUpdateCompanionBuilder = DeletionsCompanion Function({
  Value<String> entity,
  Value<String> recordId,
  Value<int> deletedAt,
  Value<int> rowid,
});

class $$DeletionsTableFilterComposer
    extends Composer<_$AppDatabase, $DeletionsTable> {
  $$DeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeletionsTable> {
  $$DeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeletionsTable> {
  $$DeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeletionsTable,
          DeletionRow,
          $$DeletionsTableFilterComposer,
          $$DeletionsTableOrderingComposer,
          $$DeletionsTableAnnotationComposer,
          $$DeletionsTableCreateCompanionBuilder,
          $$DeletionsTableUpdateCompanionBuilder,
          (
            DeletionRow,
            BaseReferences<_$AppDatabase, $DeletionsTable, DeletionRow>,
          ),
          DeletionRow,
          PrefetchHooks Function()
        > {
  $$DeletionsTableTableManager(_$AppDatabase db, $DeletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletionsCompanion(
                entity: entity,
                recordId: recordId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String recordId,
                required int deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeletionsCompanion.insert(
                entity: entity,
                recordId: recordId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeletionsTable, DeletionRow>(table),
                  BaseReferences<_$AppDatabase, $DeletionsTable, DeletionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeletionsTable,
      DeletionRow,
      $$DeletionsTableFilterComposer,
      $$DeletionsTableOrderingComposer,
      $$DeletionsTableAnnotationComposer,
      $$DeletionsTableCreateCompanionBuilder,
      $$DeletionsTableUpdateCompanionBuilder,
      (
        DeletionRow,
        BaseReferences<_$AppDatabase, $DeletionsTable, DeletionRow>,
      ),
      DeletionRow,
      PrefetchHooks Function()
    >;
typedef $$ExportsLogTableCreateCompanionBuilder = ExportsLogCompanion Function({
  required String id,
  required String kind,
  required String fileName,
  required int createdAt,
  required String rowCounts,
  Value<int> rowid,
});
typedef $$ExportsLogTableUpdateCompanionBuilder = ExportsLogCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> fileName,
  Value<int> createdAt,
  Value<String> rowCounts,
  Value<int> rowid,
});

class $$ExportsLogTableFilterComposer
    extends Composer<_$AppDatabase, $ExportsLogTable> {
  $$ExportsLogTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowCounts => $composableBuilder(
    column: $table.rowCounts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExportsLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportsLogTable> {
  $$ExportsLogTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowCounts => $composableBuilder(
    column: $table.rowCounts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExportsLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportsLogTable> {
  $$ExportsLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get rowCounts =>
      $composableBuilder(column: $table.rowCounts, builder: (column) => column);
}

class $$ExportsLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExportsLogTable,
          ExportLogRow,
          $$ExportsLogTableFilterComposer,
          $$ExportsLogTableOrderingComposer,
          $$ExportsLogTableAnnotationComposer,
          $$ExportsLogTableCreateCompanionBuilder,
          $$ExportsLogTableUpdateCompanionBuilder,
          (
            ExportLogRow,
            BaseReferences<_$AppDatabase, $ExportsLogTable, ExportLogRow>,
          ),
          ExportLogRow,
          PrefetchHooks Function()
        > {
  $$ExportsLogTableTableManager(_$AppDatabase db, $ExportsLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportsLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportsLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportsLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> rowCounts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportsLogCompanion(
                id: id,
                kind: kind,
                fileName: fileName,
                createdAt: createdAt,
                rowCounts: rowCounts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String fileName,
                required int createdAt,
                required String rowCounts,
                Value<int> rowid = const Value.absent(),
              }) => ExportsLogCompanion.insert(
                id: id,
                kind: kind,
                fileName: fileName,
                createdAt: createdAt,
                rowCounts: rowCounts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExportsLogTable, ExportLogRow>(table),
                  BaseReferences<_$AppDatabase, $ExportsLogTable, ExportLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExportsLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExportsLogTable,
      ExportLogRow,
      $$ExportsLogTableFilterComposer,
      $$ExportsLogTableOrderingComposer,
      $$ExportsLogTableAnnotationComposer,
      $$ExportsLogTableCreateCompanionBuilder,
      $$ExportsLogTableUpdateCompanionBuilder,
      (
        ExportLogRow,
        BaseReferences<_$AppDatabase, $ExportsLogTable, ExportLogRow>,
      ),
      ExportLogRow,
      PrefetchHooks Function()
    >;
typedef $$SavingsAccountsTableCreateCompanionBuilder =
    SavingsAccountsCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      required String name,
      Value<String?> platform,
      Value<String?> type,
      Value<String?> remarks,
      Value<int> sortOrder,
      Value<String?> archivedAt,
      Value<int> rowid,
    });
typedef $$SavingsAccountsTableUpdateCompanionBuilder =
    SavingsAccountsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> name,
      Value<String?> platform,
      Value<String?> type,
      Value<String?> remarks,
      Value<int> sortOrder,
      Value<String?> archivedAt,
      Value<int> rowid,
    });

final class $$SavingsAccountsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SavingsAccountsTable,
          SavingsAccountRow
        > {
  $$SavingsAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BalanceUpdatesTable, List<BalanceUpdateRow>>
  _balanceUpdatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.balanceUpdates,
    aliasName: 'savings_accounts__id__balance_updates__account_id',
  );

  $$BalanceUpdatesTableProcessedTableManager get balanceUpdatesRefs {
    final manager = $$BalanceUpdatesTableTableManager(
      $_db,
      $_db.balanceUpdates,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_balanceUpdatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavingsAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsAccountsTable> {
  $$SavingsAccountsTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> balanceUpdatesRefs(
    Expression<bool> Function($$BalanceUpdatesTableFilterComposer f) f,
  ) {
    final $$BalanceUpdatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceUpdates,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceUpdatesTableFilterComposer(
            $db: $db,
            $table: $db.balanceUpdates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavingsAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsAccountsTable> {
  $$SavingsAccountsTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsAccountsTable> {
  $$SavingsAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  Expression<T> balanceUpdatesRefs<T extends Object>(
    Expression<T> Function($$BalanceUpdatesTableAnnotationComposer a) f,
  ) {
    final $$BalanceUpdatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceUpdates,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceUpdatesTableAnnotationComposer(
            $db: $db,
            $table: $db.balanceUpdates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavingsAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsAccountsTable,
          SavingsAccountRow,
          $$SavingsAccountsTableFilterComposer,
          $$SavingsAccountsTableOrderingComposer,
          $$SavingsAccountsTableAnnotationComposer,
          $$SavingsAccountsTableCreateCompanionBuilder,
          $$SavingsAccountsTableUpdateCompanionBuilder,
          (SavingsAccountRow, $$SavingsAccountsTableReferences),
          SavingsAccountRow,
          PrefetchHooks Function({bool balanceUpdatesRefs})
        > {
  $$SavingsAccountsTableTableManager(
    _$AppDatabase db,
    $SavingsAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> platform = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsAccountsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                platform: platform,
                type: type,
                remarks: remarks,
                sortOrder: sortOrder,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String name,
                Value<String?> platform = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsAccountsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                platform: platform,
                type: type,
                remarks: remarks,
                sortOrder: sortOrder,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsAccountsTable, SavingsAccountRow>(table),
                  $$SavingsAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({balanceUpdatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (balanceUpdatesRefs) db.balanceUpdates,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (balanceUpdatesRefs)
                    await $_getPrefetchedData<
                      SavingsAccountRow,
                      $SavingsAccountsTable,
                      BalanceUpdateRow
                    >(
                      currentTable: table,
                      referencedTable: $$SavingsAccountsTableReferences
                          ._balanceUpdatesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SavingsAccountsTableReferences(
                            db,
                            table,
                            p0,
                          ).balanceUpdatesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SavingsAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsAccountsTable,
      SavingsAccountRow,
      $$SavingsAccountsTableFilterComposer,
      $$SavingsAccountsTableOrderingComposer,
      $$SavingsAccountsTableAnnotationComposer,
      $$SavingsAccountsTableCreateCompanionBuilder,
      $$SavingsAccountsTableUpdateCompanionBuilder,
      (SavingsAccountRow, $$SavingsAccountsTableReferences),
      SavingsAccountRow,
      PrefetchHooks Function({bool balanceUpdatesRefs})
    >;
typedef $$BalanceUpdatesTableCreateCompanionBuilder =
    BalanceUpdatesCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      required String accountId,
      required String date,
      required int balance,
      Value<bool> isUnchanged,
      Value<String?> remarks,
      Value<int> rowid,
    });
typedef $$BalanceUpdatesTableUpdateCompanionBuilder =
    BalanceUpdatesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> accountId,
      Value<String> date,
      Value<int> balance,
      Value<bool> isUnchanged,
      Value<String?> remarks,
      Value<int> rowid,
    });

final class $$BalanceUpdatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $BalanceUpdatesTable, BalanceUpdateRow> {
  $$BalanceUpdatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SavingsAccountsTable _accountIdTable(_$AppDatabase db) => db
      .savingsAccounts
      .createAlias('balance_updates__account_id__savings_accounts__id');

  $$SavingsAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$SavingsAccountsTableTableManager(
      $_db,
      $_db.savingsAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BalanceUpdatesTableFilterComposer
    extends Composer<_$AppDatabase, $BalanceUpdatesTable> {
  $$BalanceUpdatesTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnchanged => $composableBuilder(
    column: $table.isUnchanged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  $$SavingsAccountsTableFilterComposer get accountId {
    final $$SavingsAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.savingsAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsAccountsTableFilterComposer(
            $db: $db,
            $table: $db.savingsAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceUpdatesTableOrderingComposer
    extends Composer<_$AppDatabase, $BalanceUpdatesTable> {
  $$BalanceUpdatesTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnchanged => $composableBuilder(
    column: $table.isUnchanged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  $$SavingsAccountsTableOrderingComposer get accountId {
    final $$SavingsAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.savingsAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.savingsAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceUpdatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalanceUpdatesTable> {
  $$BalanceUpdatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get isUnchanged => $composableBuilder(
    column: $table.isUnchanged,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  $$SavingsAccountsTableAnnotationComposer get accountId {
    final $$SavingsAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.savingsAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceUpdatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceUpdatesTable,
          BalanceUpdateRow,
          $$BalanceUpdatesTableFilterComposer,
          $$BalanceUpdatesTableOrderingComposer,
          $$BalanceUpdatesTableAnnotationComposer,
          $$BalanceUpdatesTableCreateCompanionBuilder,
          $$BalanceUpdatesTableUpdateCompanionBuilder,
          (BalanceUpdateRow, $$BalanceUpdatesTableReferences),
          BalanceUpdateRow,
          PrefetchHooks Function({bool accountId})
        > {
  $$BalanceUpdatesTableTableManager(
    _$AppDatabase db,
    $BalanceUpdatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalanceUpdatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalanceUpdatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalanceUpdatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<bool> isUnchanged = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceUpdatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                accountId: accountId,
                date: date,
                balance: balance,
                isUnchanged: isUnchanged,
                remarks: remarks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String accountId,
                required String date,
                required int balance,
                Value<bool> isUnchanged = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceUpdatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                accountId: accountId,
                date: date,
                balance: balance,
                isUnchanged: isUnchanged,
                remarks: remarks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BalanceUpdatesTable, BalanceUpdateRow>(table),
                  $$BalanceUpdatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$BalanceUpdatesTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$BalanceUpdatesTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BalanceUpdatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceUpdatesTable,
      BalanceUpdateRow,
      $$BalanceUpdatesTableFilterComposer,
      $$BalanceUpdatesTableOrderingComposer,
      $$BalanceUpdatesTableAnnotationComposer,
      $$BalanceUpdatesTableCreateCompanionBuilder,
      $$BalanceUpdatesTableUpdateCompanionBuilder,
      (BalanceUpdateRow, $$BalanceUpdatesTableReferences),
      BalanceUpdateRow,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$GoldItemsTableCreateCompanionBuilder = GoldItemsCompanion Function({
  required String id,
  required int createdAt,
  required int updatedAt,
  required String name,
  required int weightMg,
  required int karat,
  Value<String?> vendor,
  required String purchaseDate,
  required int cost,
  Value<String> status,
  Value<String?> disposedDate,
  Value<String?> remarks,
  Value<int> rowid,
});
typedef $$GoldItemsTableUpdateCompanionBuilder = GoldItemsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> name,
  Value<int> weightMg,
  Value<int> karat,
  Value<String?> vendor,
  Value<String> purchaseDate,
  Value<int> cost,
  Value<String> status,
  Value<String?> disposedDate,
  Value<String?> remarks,
  Value<int> rowid,
});

class $$GoldItemsTableFilterComposer
    extends Composer<_$AppDatabase, $GoldItemsTable> {
  $$GoldItemsTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weightMg => $composableBuilder(
    column: $table.weightMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get karat => $composableBuilder(
    column: $table.karat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disposedDate => $composableBuilder(
    column: $table.disposedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoldItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoldItemsTable> {
  $$GoldItemsTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weightMg => $composableBuilder(
    column: $table.weightMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get karat => $composableBuilder(
    column: $table.karat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disposedDate => $composableBuilder(
    column: $table.disposedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoldItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoldItemsTable> {
  $$GoldItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get weightMg =>
      $composableBuilder(column: $table.weightMg, builder: (column) => column);

  GeneratedColumn<int> get karat =>
      $composableBuilder(column: $table.karat, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get disposedDate => $composableBuilder(
    column: $table.disposedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);
}

class $$GoldItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoldItemsTable,
          GoldItemRow,
          $$GoldItemsTableFilterComposer,
          $$GoldItemsTableOrderingComposer,
          $$GoldItemsTableAnnotationComposer,
          $$GoldItemsTableCreateCompanionBuilder,
          $$GoldItemsTableUpdateCompanionBuilder,
          (
            GoldItemRow,
            BaseReferences<_$AppDatabase, $GoldItemsTable, GoldItemRow>,
          ),
          GoldItemRow,
          PrefetchHooks Function()
        > {
  $$GoldItemsTableTableManager(_$AppDatabase db, $GoldItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoldItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoldItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoldItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> weightMg = const Value.absent(),
                Value<int> karat = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<int> cost = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> disposedDate = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoldItemsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                weightMg: weightMg,
                karat: karat,
                vendor: vendor,
                purchaseDate: purchaseDate,
                cost: cost,
                status: status,
                disposedDate: disposedDate,
                remarks: remarks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String name,
                required int weightMg,
                required int karat,
                Value<String?> vendor = const Value.absent(),
                required String purchaseDate,
                required int cost,
                Value<String> status = const Value.absent(),
                Value<String?> disposedDate = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoldItemsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                weightMg: weightMg,
                karat: karat,
                vendor: vendor,
                purchaseDate: purchaseDate,
                cost: cost,
                status: status,
                disposedDate: disposedDate,
                remarks: remarks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoldItemsTable, GoldItemRow>(table),
                  BaseReferences<_$AppDatabase, $GoldItemsTable, GoldItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoldItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoldItemsTable,
      GoldItemRow,
      $$GoldItemsTableFilterComposer,
      $$GoldItemsTableOrderingComposer,
      $$GoldItemsTableAnnotationComposer,
      $$GoldItemsTableCreateCompanionBuilder,
      $$GoldItemsTableUpdateCompanionBuilder,
      (
        GoldItemRow,
        BaseReferences<_$AppDatabase, $GoldItemsTable, GoldItemRow>,
      ),
      GoldItemRow,
      PrefetchHooks Function()
    >;
typedef $$KaratPricesTableCreateCompanionBuilder =
    KaratPricesCompanion Function({
      required String id,
      required int createdAt,
      required int updatedAt,
      required int karat,
      required int pricePerGram,
      required String date,
      Value<int> rowid,
    });
typedef $$KaratPricesTableUpdateCompanionBuilder =
    KaratPricesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> karat,
      Value<int> pricePerGram,
      Value<String> date,
      Value<int> rowid,
    });

class $$KaratPricesTableFilterComposer
    extends Composer<_$AppDatabase, $KaratPricesTable> {
  $$KaratPricesTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get karat => $composableBuilder(
    column: $table.karat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerGram => $composableBuilder(
    column: $table.pricePerGram,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KaratPricesTableOrderingComposer
    extends Composer<_$AppDatabase, $KaratPricesTable> {
  $$KaratPricesTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get karat => $composableBuilder(
    column: $table.karat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerGram => $composableBuilder(
    column: $table.pricePerGram,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KaratPricesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KaratPricesTable> {
  $$KaratPricesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get karat =>
      $composableBuilder(column: $table.karat, builder: (column) => column);

  GeneratedColumn<int> get pricePerGram => $composableBuilder(
    column: $table.pricePerGram,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$KaratPricesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KaratPricesTable,
          KaratPriceRow,
          $$KaratPricesTableFilterComposer,
          $$KaratPricesTableOrderingComposer,
          $$KaratPricesTableAnnotationComposer,
          $$KaratPricesTableCreateCompanionBuilder,
          $$KaratPricesTableUpdateCompanionBuilder,
          (
            KaratPriceRow,
            BaseReferences<_$AppDatabase, $KaratPricesTable, KaratPriceRow>,
          ),
          KaratPriceRow,
          PrefetchHooks Function()
        > {
  $$KaratPricesTableTableManager(_$AppDatabase db, $KaratPricesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KaratPricesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KaratPricesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KaratPricesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> karat = const Value.absent(),
                Value<int> pricePerGram = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KaratPricesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                karat: karat,
                pricePerGram: pricePerGram,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required int karat,
                required int pricePerGram,
                required String date,
                Value<int> rowid = const Value.absent(),
              }) => KaratPricesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                karat: karat,
                pricePerGram: pricePerGram,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KaratPricesTable, KaratPriceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $KaratPricesTable,
                    KaratPriceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KaratPricesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KaratPricesTable,
      KaratPriceRow,
      $$KaratPricesTableFilterComposer,
      $$KaratPricesTableOrderingComposer,
      $$KaratPricesTableAnnotationComposer,
      $$KaratPricesTableCreateCompanionBuilder,
      $$KaratPricesTableUpdateCompanionBuilder,
      (
        KaratPriceRow,
        BaseReferences<_$AppDatabase, $KaratPricesTable, KaratPriceRow>,
      ),
      KaratPriceRow,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required int createdAt,
  required int updatedAt,
  required String item,
  required String vendor,
  required int amount,
  required String date,
  Value<bool> isRefunded,
  Value<int?> refundedAt,
  Value<String?> remarks,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> item,
  Value<String> vendor,
  Value<int> amount,
  Value<String> date,
  Value<bool> isRefunded,
  Value<int?> refundedAt,
  Value<String?> remarks,
  Value<int> rowid,
});

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRefunded => $composableBuilder(
    column: $table.isRefunded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refundedAt => $composableBuilder(
    column: $table.refundedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRefunded => $composableBuilder(
    column: $table.isRefunded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refundedAt => $composableBuilder(
    column: $table.refundedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isRefunded => $composableBuilder(
    column: $table.isRefunded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get refundedAt => $composableBuilder(
    column: $table.refundedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<String> vendor = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> isRefunded = const Value.absent(),
                Value<int?> refundedAt = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                item: item,
                vendor: vendor,
                amount: amount,
                date: date,
                isRefunded: isRefunded,
                refundedAt: refundedAt,
                remarks: remarks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String item,
                required String vendor,
                required int amount,
                required String date,
                Value<bool> isRefunded = const Value.absent(),
                Value<int?> refundedAt = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                item: item,
                vendor: vendor,
                amount: amount,
                date: date,
                isRefunded: isRefunded,
                refundedAt: refundedAt,
                remarks: remarks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, ExpenseRow>(table),
                  BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required int createdAt,
  required int updatedAt,
  required String title,
  Value<String?> author,
  Value<int?> sizeKb,
  Value<bool> onKindle,
  required String status,
  required String acquisition,
  Value<String?> acquiredDate,
  Value<int?> amount,
  Value<int?> ratingHalf,
  Value<String?> remarks,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> title,
  Value<String?> author,
  Value<int?> sizeKb,
  Value<bool> onKindle,
  Value<String> status,
  Value<String> acquisition,
  Value<String?> acquiredDate,
  Value<int?> amount,
  Value<int?> ratingHalf,
  Value<String?> remarks,
  Value<int> rowid,
});

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeKb => $composableBuilder(
    column: $table.sizeKb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onKindle => $composableBuilder(
    column: $table.onKindle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acquisition => $composableBuilder(
    column: $table.acquisition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acquiredDate => $composableBuilder(
    column: $table.acquiredDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingHalf => $composableBuilder(
    column: $table.ratingHalf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeKb => $composableBuilder(
    column: $table.sizeKb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onKindle => $composableBuilder(
    column: $table.onKindle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acquisition => $composableBuilder(
    column: $table.acquisition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acquiredDate => $composableBuilder(
    column: $table.acquiredDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingHalf => $composableBuilder(
    column: $table.ratingHalf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<int> get sizeKb =>
      $composableBuilder(column: $table.sizeKb, builder: (column) => column);

  GeneratedColumn<bool> get onKindle =>
      $composableBuilder(column: $table.onKindle, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get acquisition => $composableBuilder(
    column: $table.acquisition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acquiredDate => $composableBuilder(
    column: $table.acquiredDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get ratingHalf => $composableBuilder(
    column: $table.ratingHalf,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
          BookRow,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<int?> sizeKb = const Value.absent(),
                Value<bool> onKindle = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> acquisition = const Value.absent(),
                Value<String?> acquiredDate = const Value.absent(),
                Value<int?> amount = const Value.absent(),
                Value<int?> ratingHalf = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                author: author,
                sizeKb: sizeKb,
                onKindle: onKindle,
                status: status,
                acquisition: acquisition,
                acquiredDate: acquiredDate,
                amount: amount,
                ratingHalf: ratingHalf,
                remarks: remarks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<int?> sizeKb = const Value.absent(),
                Value<bool> onKindle = const Value.absent(),
                required String status,
                required String acquisition,
                Value<String?> acquiredDate = const Value.absent(),
                Value<int?> amount = const Value.absent(),
                Value<int?> ratingHalf = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                author: author,
                sizeKb: sizeKb,
                onKindle: onKindle,
                status: status,
                acquisition: acquisition,
                acquiredDate: acquiredDate,
                amount: amount,
                ratingHalf: ratingHalf,
                remarks: remarks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, BookRow>(table),
                  BaseReferences<_$AppDatabase, $BooksTable, BookRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
      BookRow,
      PrefetchHooks Function()
    >;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  required int createdAt,
  required int updatedAt,
  required String name,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, FolderRow> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotesTable, List<NoteRow>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: 'folders__id__notes__folder_id',
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          FolderRow,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (FolderRow, $$FoldersTableReferences),
          FolderRow,
          PrefetchHooks Function({bool notesRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTable, FolderRow>(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (notesRefs) db.notes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notesRefs)
                    await $_getPrefetchedData<
                      FolderRow,
                      $FoldersTable,
                      NoteRow
                    >(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences._notesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$FoldersTableReferences(db, table, p0).notesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      FolderRow,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (FolderRow, $$FoldersTableReferences),
      FolderRow,
      PrefetchHooks Function({bool notesRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required int createdAt,
  required int updatedAt,
  required String name,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> name,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NoteTagsTable, List<NoteTagRow>>
  _noteTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.noteTags,
    aliasName: 'tags__id__note_tags__tag_id',
  );

  $$NoteTagsTableProcessedTableManager get noteTagsRefs {
    final manager = $$NoteTagsTableTableManager(
      $_db,
      $_db.noteTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> noteTagsRefs(
    Expression<bool> Function($$NoteTagsTableFilterComposer f) f,
  ) {
    final $$NoteTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableFilterComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> noteTagsRefs<T extends Object>(
    Expression<T> Function($$NoteTagsTableAnnotationComposer a) f,
  ) {
    final $$NoteTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool noteTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, TagRow>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (noteTagsRefs) db.noteTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (noteTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, NoteTagRow>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._noteTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).noteTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool noteTagsRefs})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  required int createdAt,
  required int updatedAt,
  Value<String?> folderId,
  Value<String?> title,
  Value<String?> content,
  Value<String?> plainText,
  Value<bool> isPinned,
  Value<int?> pinnedAt,
  Value<bool> isLocked,
  Value<String?> cipher,
  required int editedAt,
  Value<int?> trashedAt,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String?> folderId,
  Value<String?> title,
  Value<String?> content,
  Value<String?> plainText,
  Value<bool> isPinned,
  Value<int?> pinnedAt,
  Value<bool> isLocked,
  Value<String?> cipher,
  Value<int> editedAt,
  Value<int?> trashedAt,
  Value<int> rowid,
});

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, NoteRow> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) =>
      db.folders.createAlias('notes__folder_id__folders__id');

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NoteTagsTable, List<NoteTagRow>>
  _noteTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.noteTags,
    aliasName: 'notes__id__note_tags__note_id',
  );

  $$NoteTagsTableProcessedTableManager get noteTagsRefs {
    final manager = $$NoteTagsTableTableManager(
      $_db,
      $_db.noteTags,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cipher => $composableBuilder(
    column: $table.cipher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> noteTagsRefs(
    Expression<bool> Function($$NoteTagsTableFilterComposer f) f,
  ) {
    final $$NoteTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableFilterComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cipher => $composableBuilder(
    column: $table.cipher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<String> get cipher =>
      $composableBuilder(column: $table.cipher, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<int> get trashedAt =>
      $composableBuilder(column: $table.trashedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> noteTagsRefs<T extends Object>(
    Expression<T> Function($$NoteTagsTableAnnotationComposer a) f,
  ) {
    final $$NoteTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, $$NotesTableReferences),
          NoteRow,
          PrefetchHooks Function({bool folderId, bool noteTagsRefs})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> plainText = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int?> pinnedAt = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String?> cipher = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<int?> trashedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                folderId: folderId,
                title: title,
                content: content,
                plainText: plainText,
                isPinned: isPinned,
                pinnedAt: pinnedAt,
                isLocked: isLocked,
                cipher: cipher,
                editedAt: editedAt,
                trashedAt: trashedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int updatedAt,
                Value<String?> folderId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> plainText = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int?> pinnedAt = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String?> cipher = const Value.absent(),
                required int editedAt,
                Value<int?> trashedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                folderId: folderId,
                title: title,
                content: content,
                plainText: plainText,
                isPinned: isPinned,
                pinnedAt: pinnedAt,
                isLocked: isLocked,
                cipher: cipher,
                editedAt: editedAt,
                trashedAt: trashedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  $$NotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({folderId = false, noteTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (noteTagsRefs) db.noteTags],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (folderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.folderId,
                        referencedTable: $$NotesTableReferences._folderIdTable(
                          db,
                        ),
                        referencedColumn: $$NotesTableReferences
                            ._folderIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (noteTagsRefs)
                    await $_getPrefetchedData<NoteRow, $NotesTable, NoteTagRow>(
                      currentTable: table,
                      referencedTable: $$NotesTableReferences
                          ._noteTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$NotesTableReferences(db, table, p0).noteTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.noteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, $$NotesTableReferences),
      NoteRow,
      PrefetchHooks Function({bool folderId, bool noteTagsRefs})
    >;
typedef $$NoteTagsTableCreateCompanionBuilder = NoteTagsCompanion Function({
  required String noteId,
  required String tagId,
  Value<int> rowid,
});
typedef $$NoteTagsTableUpdateCompanionBuilder = NoteTagsCompanion Function({
  Value<String> noteId,
  Value<String> tagId,
  Value<int> rowid,
});

final class $$NoteTagsTableReferences
    extends BaseReferences<_$AppDatabase, $NoteTagsTable, NoteTagRow> {
  $$NoteTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotesTable _noteIdTable(_$AppDatabase db) =>
      db.notes.createAlias('note_tags__note_id__notes__id');

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('note_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NoteTagsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteTagsTable,
          NoteTagRow,
          $$NoteTagsTableFilterComposer,
          $$NoteTagsTableOrderingComposer,
          $$NoteTagsTableAnnotationComposer,
          $$NoteTagsTableCreateCompanionBuilder,
          $$NoteTagsTableUpdateCompanionBuilder,
          (NoteTagRow, $$NoteTagsTableReferences),
          NoteTagRow,
          PrefetchHooks Function({bool noteId, bool tagId})
        > {
  $$NoteTagsTableTableManager(_$AppDatabase db, $NoteTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> noteId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => NoteTagsCompanion(noteId: noteId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required String noteId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => NoteTagsCompanion.insert(
                noteId: noteId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteTagsTable, NoteTagRow>(table),
                  $$NoteTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (noteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.noteId,
                        referencedTable: $$NoteTagsTableReferences._noteIdTable(
                          db,
                        ),
                        referencedColumn: $$NoteTagsTableReferences
                            ._noteIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$NoteTagsTableReferences._tagIdTable(
                          db,
                        ),
                        referencedColumn: $$NoteTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteTagsTable,
      NoteTagRow,
      $$NoteTagsTableFilterComposer,
      $$NoteTagsTableOrderingComposer,
      $$NoteTagsTableAnnotationComposer,
      $$NoteTagsTableCreateCompanionBuilder,
      $$NoteTagsTableUpdateCompanionBuilder,
      (NoteTagRow, $$NoteTagsTableReferences),
      NoteTagRow,
      PrefetchHooks Function({bool noteId, bool tagId})
    >;
typedef $$NoteDraftsTableCreateCompanionBuilder = NoteDraftsCompanion Function({
  required String noteId,
  required String content,
  required int savedAt,
  Value<int> rowid,
});
typedef $$NoteDraftsTableUpdateCompanionBuilder = NoteDraftsCompanion Function({
  Value<String> noteId,
  Value<String> content,
  Value<int> savedAt,
  Value<int> rowid,
});

class $$NoteDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteDraftsTable> {
  $$NoteDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteDraftsTable> {
  $$NoteDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteDraftsTable> {
  $$NoteDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$NoteDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteDraftsTable,
          NoteDraftRow,
          $$NoteDraftsTableFilterComposer,
          $$NoteDraftsTableOrderingComposer,
          $$NoteDraftsTableAnnotationComposer,
          $$NoteDraftsTableCreateCompanionBuilder,
          $$NoteDraftsTableUpdateCompanionBuilder,
          (
            NoteDraftRow,
            BaseReferences<_$AppDatabase, $NoteDraftsTable, NoteDraftRow>,
          ),
          NoteDraftRow,
          PrefetchHooks Function()
        > {
  $$NoteDraftsTableTableManager(_$AppDatabase db, $NoteDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> noteId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteDraftsCompanion(
                noteId: noteId,
                content: content,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String noteId,
                required String content,
                required int savedAt,
                Value<int> rowid = const Value.absent(),
              }) => NoteDraftsCompanion.insert(
                noteId: noteId,
                content: content,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteDraftsTable, NoteDraftRow>(table),
                  BaseReferences<_$AppDatabase, $NoteDraftsTable, NoteDraftRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteDraftsTable,
      NoteDraftRow,
      $$NoteDraftsTableFilterComposer,
      $$NoteDraftsTableOrderingComposer,
      $$NoteDraftsTableAnnotationComposer,
      $$NoteDraftsTableCreateCompanionBuilder,
      $$NoteDraftsTableUpdateCompanionBuilder,
      (
        NoteDraftRow,
        BaseReferences<_$AppDatabase, $NoteDraftsTable, NoteDraftRow>,
      ),
      NoteDraftRow,
      PrefetchHooks Function()
    >;
typedef $$VaultTableCreateCompanionBuilder = VaultCompanion Function({
  Value<int> id,
  required String kdfParams,
  required Uint8List salt,
  required Uint8List saltRecovery,
  required Uint8List wrappedKeyPassword,
  required Uint8List wrappedKeyRecovery,
  required Uint8List keyCheck,
  required int createdAt,
  required int updatedAt,
});
typedef $$VaultTableUpdateCompanionBuilder = VaultCompanion Function({
  Value<int> id,
  Value<String> kdfParams,
  Value<Uint8List> salt,
  Value<Uint8List> saltRecovery,
  Value<Uint8List> wrappedKeyPassword,
  Value<Uint8List> wrappedKeyRecovery,
  Value<Uint8List> keyCheck,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$VaultTableFilterComposer extends Composer<_$AppDatabase, $VaultTable> {
  $$VaultTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kdfParams => $composableBuilder(
    column: $table.kdfParams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get saltRecovery => $composableBuilder(
    column: $table.saltRecovery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get wrappedKeyPassword => $composableBuilder(
    column: $table.wrappedKeyPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get wrappedKeyRecovery => $composableBuilder(
    column: $table.wrappedKeyRecovery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get keyCheck => $composableBuilder(
    column: $table.keyCheck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultTable> {
  $$VaultTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kdfParams => $composableBuilder(
    column: $table.kdfParams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get saltRecovery => $composableBuilder(
    column: $table.saltRecovery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get wrappedKeyPassword => $composableBuilder(
    column: $table.wrappedKeyPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get wrappedKeyRecovery => $composableBuilder(
    column: $table.wrappedKeyRecovery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get keyCheck => $composableBuilder(
    column: $table.keyCheck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultTable> {
  $$VaultTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kdfParams =>
      $composableBuilder(column: $table.kdfParams, builder: (column) => column);

  GeneratedColumn<Uint8List> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);

  GeneratedColumn<Uint8List> get saltRecovery => $composableBuilder(
    column: $table.saltRecovery,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get wrappedKeyPassword => $composableBuilder(
    column: $table.wrappedKeyPassword,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get wrappedKeyRecovery => $composableBuilder(
    column: $table.wrappedKeyRecovery,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get keyCheck =>
      $composableBuilder(column: $table.keyCheck, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VaultTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultTable,
          VaultRow,
          $$VaultTableFilterComposer,
          $$VaultTableOrderingComposer,
          $$VaultTableAnnotationComposer,
          $$VaultTableCreateCompanionBuilder,
          $$VaultTableUpdateCompanionBuilder,
          (VaultRow, BaseReferences<_$AppDatabase, $VaultTable, VaultRow>),
          VaultRow,
          PrefetchHooks Function()
        > {
  $$VaultTableTableManager(_$AppDatabase db, $VaultTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kdfParams = const Value.absent(),
                Value<Uint8List> salt = const Value.absent(),
                Value<Uint8List> saltRecovery = const Value.absent(),
                Value<Uint8List> wrappedKeyPassword = const Value.absent(),
                Value<Uint8List> wrappedKeyRecovery = const Value.absent(),
                Value<Uint8List> keyCheck = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => VaultCompanion(
                id: id,
                kdfParams: kdfParams,
                salt: salt,
                saltRecovery: saltRecovery,
                wrappedKeyPassword: wrappedKeyPassword,
                wrappedKeyRecovery: wrappedKeyRecovery,
                keyCheck: keyCheck,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kdfParams,
                required Uint8List salt,
                required Uint8List saltRecovery,
                required Uint8List wrappedKeyPassword,
                required Uint8List wrappedKeyRecovery,
                required Uint8List keyCheck,
                required int createdAt,
                required int updatedAt,
              }) => VaultCompanion.insert(
                id: id,
                kdfParams: kdfParams,
                salt: salt,
                saltRecovery: saltRecovery,
                wrappedKeyPassword: wrappedKeyPassword,
                wrappedKeyRecovery: wrappedKeyRecovery,
                keyCheck: keyCheck,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VaultTable, VaultRow>(table),
                  BaseReferences<_$AppDatabase, $VaultTable, VaultRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultTable,
      VaultRow,
      $$VaultTableFilterComposer,
      $$VaultTableOrderingComposer,
      $$VaultTableAnnotationComposer,
      $$VaultTableCreateCompanionBuilder,
      $$VaultTableUpdateCompanionBuilder,
      (VaultRow, BaseReferences<_$AppDatabase, $VaultTable, VaultRow>),
      VaultRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$DeletionsTableTableManager get deletions =>
      $$DeletionsTableTableManager(_db, _db.deletions);
  $$ExportsLogTableTableManager get exportsLog =>
      $$ExportsLogTableTableManager(_db, _db.exportsLog);
  $$SavingsAccountsTableTableManager get savingsAccounts =>
      $$SavingsAccountsTableTableManager(_db, _db.savingsAccounts);
  $$BalanceUpdatesTableTableManager get balanceUpdates =>
      $$BalanceUpdatesTableTableManager(_db, _db.balanceUpdates);
  $$GoldItemsTableTableManager get goldItems =>
      $$GoldItemsTableTableManager(_db, _db.goldItems);
  $$KaratPricesTableTableManager get karatPrices =>
      $$KaratPricesTableTableManager(_db, _db.karatPrices);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$NoteTagsTableTableManager get noteTags =>
      $$NoteTagsTableTableManager(_db, _db.noteTags);
  $$NoteDraftsTableTableManager get noteDrafts =>
      $$NoteDraftsTableTableManager(_db, _db.noteDrafts);
  $$VaultTableTableManager get vault =>
      $$VaultTableTableManager(_db, _db.vault);
}
