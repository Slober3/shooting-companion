// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FirearmsTable extends Firearms
    with TableInfo<$FirearmsTable, FirearmRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FirearmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultCartridgeIdMeta =
      const VerificationMeta('defaultCartridgeId');
  @override
  late final GeneratedColumn<String> defaultCartridgeId =
      GeneratedColumn<String>(
        'default_cartridge_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sightNotesMeta = const VerificationMeta(
    'sightNotes',
  );
  @override
  late final GeneratedColumn<String> sightNotes = GeneratedColumn<String>(
    'sight_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    manufacturer,
    model,
    type,
    defaultCartridgeId,
    sightNotes,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firearms';
  @override
  VerificationContext validateIntegrity(
    Insertable<FirearmRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('default_cartridge_id')) {
      context.handle(
        _defaultCartridgeIdMeta,
        defaultCartridgeId.isAcceptableOrUnknown(
          data['default_cartridge_id']!,
          _defaultCartridgeIdMeta,
        ),
      );
    }
    if (data.containsKey('sight_notes')) {
      context.handle(
        _sightNotesMeta,
        sightNotes.isAcceptableOrUnknown(data['sight_notes']!, _sightNotesMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FirearmRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FirearmRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      defaultCartridgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_cartridge_id'],
      ),
      sightNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sight_notes'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $FirearmsTable createAlias(String alias) {
    return $FirearmsTable(attachedDatabase, alias);
  }
}

class FirearmRecord extends DataClass implements Insertable<FirearmRecord> {
  final String id;
  final String name;
  final String? manufacturer;
  final String? model;
  final String type;
  final String? defaultCartridgeId;
  final String? sightNotes;
  final bool archived;
  const FirearmRecord({
    required this.id,
    required this.name,
    this.manufacturer,
    this.model,
    required this.type,
    this.defaultCartridgeId,
    this.sightNotes,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || defaultCartridgeId != null) {
      map['default_cartridge_id'] = Variable<String>(defaultCartridgeId);
    }
    if (!nullToAbsent || sightNotes != null) {
      map['sight_notes'] = Variable<String>(sightNotes);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  FirearmsCompanion toCompanion(bool nullToAbsent) {
    return FirearmsCompanion(
      id: Value(id),
      name: Value(name),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      type: Value(type),
      defaultCartridgeId: defaultCartridgeId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultCartridgeId),
      sightNotes: sightNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(sightNotes),
      archived: Value(archived),
    );
  }

  factory FirearmRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FirearmRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      model: serializer.fromJson<String?>(json['model']),
      type: serializer.fromJson<String>(json['type']),
      defaultCartridgeId: serializer.fromJson<String?>(
        json['defaultCartridgeId'],
      ),
      sightNotes: serializer.fromJson<String?>(json['sightNotes']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'model': serializer.toJson<String?>(model),
      'type': serializer.toJson<String>(type),
      'defaultCartridgeId': serializer.toJson<String?>(defaultCartridgeId),
      'sightNotes': serializer.toJson<String?>(sightNotes),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  FirearmRecord copyWith({
    String? id,
    String? name,
    Value<String?> manufacturer = const Value.absent(),
    Value<String?> model = const Value.absent(),
    String? type,
    Value<String?> defaultCartridgeId = const Value.absent(),
    Value<String?> sightNotes = const Value.absent(),
    bool? archived,
  }) => FirearmRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    model: model.present ? model.value : this.model,
    type: type ?? this.type,
    defaultCartridgeId: defaultCartridgeId.present
        ? defaultCartridgeId.value
        : this.defaultCartridgeId,
    sightNotes: sightNotes.present ? sightNotes.value : this.sightNotes,
    archived: archived ?? this.archived,
  );
  FirearmRecord copyWithCompanion(FirearmsCompanion data) {
    return FirearmRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      type: data.type.present ? data.type.value : this.type,
      defaultCartridgeId: data.defaultCartridgeId.present
          ? data.defaultCartridgeId.value
          : this.defaultCartridgeId,
      sightNotes: data.sightNotes.present
          ? data.sightNotes.value
          : this.sightNotes,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FirearmRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('type: $type, ')
          ..write('defaultCartridgeId: $defaultCartridgeId, ')
          ..write('sightNotes: $sightNotes, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    manufacturer,
    model,
    type,
    defaultCartridgeId,
    sightNotes,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirearmRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.type == this.type &&
          other.defaultCartridgeId == this.defaultCartridgeId &&
          other.sightNotes == this.sightNotes &&
          other.archived == this.archived);
}

class FirearmsCompanion extends UpdateCompanion<FirearmRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> manufacturer;
  final Value<String?> model;
  final Value<String> type;
  final Value<String?> defaultCartridgeId;
  final Value<String?> sightNotes;
  final Value<bool> archived;
  final Value<int> rowid;
  const FirearmsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.type = const Value.absent(),
    this.defaultCartridgeId = const Value.absent(),
    this.sightNotes = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FirearmsCompanion.insert({
    required String id,
    required String name,
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    required String type,
    this.defaultCartridgeId = const Value.absent(),
    this.sightNotes = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type);
  static Insertable<FirearmRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<String>? type,
    Expression<String>? defaultCartridgeId,
    Expression<String>? sightNotes,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (type != null) 'type': type,
      if (defaultCartridgeId != null)
        'default_cartridge_id': defaultCartridgeId,
      if (sightNotes != null) 'sight_notes': sightNotes,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FirearmsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? manufacturer,
    Value<String?>? model,
    Value<String>? type,
    Value<String?>? defaultCartridgeId,
    Value<String?>? sightNotes,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return FirearmsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      type: type ?? this.type,
      defaultCartridgeId: defaultCartridgeId ?? this.defaultCartridgeId,
      sightNotes: sightNotes ?? this.sightNotes,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (defaultCartridgeId.present) {
      map['default_cartridge_id'] = Variable<String>(defaultCartridgeId.value);
    }
    if (sightNotes.present) {
      map['sight_notes'] = Variable<String>(sightNotes.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FirearmsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('type: $type, ')
          ..write('defaultCartridgeId: $defaultCartridgeId, ')
          ..write('sightNotes: $sightNotes, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CartridgesTable extends Cartridges
    with TableInfo<$CartridgesTable, CartridgeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartridgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _projectileDiameterMmMeta =
      const VerificationMeta('projectileDiameterMm');
  @override
  late final GeneratedColumn<double> projectileDiameterMm =
      GeneratedColumn<double>(
        'projectile_diameter_mm',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    projectileDiameterMm,
    notes,
    builtIn,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cartridges';
  @override
  VerificationContext validateIntegrity(
    Insertable<CartridgeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('projectile_diameter_mm')) {
      context.handle(
        _projectileDiameterMmMeta,
        projectileDiameterMm.isAcceptableOrUnknown(
          data['projectile_diameter_mm']!,
          _projectileDiameterMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectileDiameterMmMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartridgeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartridgeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      projectileDiameterMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}projectile_diameter_mm'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $CartridgesTable createAlias(String alias) {
    return $CartridgesTable(attachedDatabase, alias);
  }
}

class CartridgeRecord extends DataClass implements Insertable<CartridgeRecord> {
  final String id;
  final String name;
  final double projectileDiameterMm;
  final String? notes;
  final bool builtIn;
  final bool archived;
  const CartridgeRecord({
    required this.id,
    required this.name,
    required this.projectileDiameterMm,
    this.notes,
    required this.builtIn,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['projectile_diameter_mm'] = Variable<double>(projectileDiameterMm);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['built_in'] = Variable<bool>(builtIn);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  CartridgesCompanion toCompanion(bool nullToAbsent) {
    return CartridgesCompanion(
      id: Value(id),
      name: Value(name),
      projectileDiameterMm: Value(projectileDiameterMm),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      builtIn: Value(builtIn),
      archived: Value(archived),
    );
  }

  factory CartridgeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartridgeRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      projectileDiameterMm: serializer.fromJson<double>(
        json['projectileDiameterMm'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'projectileDiameterMm': serializer.toJson<double>(projectileDiameterMm),
      'notes': serializer.toJson<String?>(notes),
      'builtIn': serializer.toJson<bool>(builtIn),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  CartridgeRecord copyWith({
    String? id,
    String? name,
    double? projectileDiameterMm,
    Value<String?> notes = const Value.absent(),
    bool? builtIn,
    bool? archived,
  }) => CartridgeRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    projectileDiameterMm: projectileDiameterMm ?? this.projectileDiameterMm,
    notes: notes.present ? notes.value : this.notes,
    builtIn: builtIn ?? this.builtIn,
    archived: archived ?? this.archived,
  );
  CartridgeRecord copyWithCompanion(CartridgesCompanion data) {
    return CartridgeRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      projectileDiameterMm: data.projectileDiameterMm.present
          ? data.projectileDiameterMm.value
          : this.projectileDiameterMm,
      notes: data.notes.present ? data.notes.value : this.notes,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartridgeRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('projectileDiameterMm: $projectileDiameterMm, ')
          ..write('notes: $notes, ')
          ..write('builtIn: $builtIn, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, projectileDiameterMm, notes, builtIn, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartridgeRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.projectileDiameterMm == this.projectileDiameterMm &&
          other.notes == this.notes &&
          other.builtIn == this.builtIn &&
          other.archived == this.archived);
}

class CartridgesCompanion extends UpdateCompanion<CartridgeRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> projectileDiameterMm;
  final Value<String?> notes;
  final Value<bool> builtIn;
  final Value<bool> archived;
  final Value<int> rowid;
  const CartridgesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.projectileDiameterMm = const Value.absent(),
    this.notes = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CartridgesCompanion.insert({
    required String id,
    required String name,
    required double projectileDiameterMm,
    this.notes = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       projectileDiameterMm = Value(projectileDiameterMm);
  static Insertable<CartridgeRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? projectileDiameterMm,
    Expression<String>? notes,
    Expression<bool>? builtIn,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (projectileDiameterMm != null)
        'projectile_diameter_mm': projectileDiameterMm,
      if (notes != null) 'notes': notes,
      if (builtIn != null) 'built_in': builtIn,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CartridgesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? projectileDiameterMm,
    Value<String?>? notes,
    Value<bool>? builtIn,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return CartridgesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      projectileDiameterMm: projectileDiameterMm ?? this.projectileDiameterMm,
      notes: notes ?? this.notes,
      builtIn: builtIn ?? this.builtIn,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (projectileDiameterMm.present) {
      map['projectile_diameter_mm'] = Variable<double>(
        projectileDiameterMm.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartridgesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('projectileDiameterMm: $projectileDiameterMm, ')
          ..write('notes: $notes, ')
          ..write('builtIn: $builtIn, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AmmoLotsTable extends AmmoLots
    with TableInfo<$AmmoLotsTable, AmmoLotRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmmoLotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cartridgeIdMeta = const VerificationMeta(
    'cartridgeId',
  );
  @override
  late final GeneratedColumn<String> cartridgeId = GeneratedColumn<String>(
    'cartridge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cartridges (id)',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lotNumberMeta = const VerificationMeta(
    'lotNumber',
  );
  @override
  late final GeneratedColumn<String> lotNumber = GeneratedColumn<String>(
    'lot_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bulletWeightGrainsMeta =
      const VerificationMeta('bulletWeightGrains');
  @override
  late final GeneratedColumn<double> bulletWeightGrains =
      GeneratedColumn<double>(
        'bullet_weight_grains',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _projectileTypeMeta = const VerificationMeta(
    'projectileType',
  );
  @override
  late final GeneratedColumn<String> projectileType = GeneratedColumn<String>(
    'projectile_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cartridgeId,
    displayName,
    manufacturer,
    productName,
    lotNumber,
    bulletWeightGrains,
    projectileType,
    notes,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ammo_lots';
  @override
  VerificationContext validateIntegrity(
    Insertable<AmmoLotRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cartridge_id')) {
      context.handle(
        _cartridgeIdMeta,
        cartridgeId.isAcceptableOrUnknown(
          data['cartridge_id']!,
          _cartridgeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cartridgeIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('lot_number')) {
      context.handle(
        _lotNumberMeta,
        lotNumber.isAcceptableOrUnknown(data['lot_number']!, _lotNumberMeta),
      );
    }
    if (data.containsKey('bullet_weight_grains')) {
      context.handle(
        _bulletWeightGrainsMeta,
        bulletWeightGrains.isAcceptableOrUnknown(
          data['bullet_weight_grains']!,
          _bulletWeightGrainsMeta,
        ),
      );
    }
    if (data.containsKey('projectile_type')) {
      context.handle(
        _projectileTypeMeta,
        projectileType.isAcceptableOrUnknown(
          data['projectile_type']!,
          _projectileTypeMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AmmoLotRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AmmoLotRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cartridgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cartridge_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      ),
      lotNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_number'],
      ),
      bulletWeightGrains: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bullet_weight_grains'],
      ),
      projectileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}projectile_type'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $AmmoLotsTable createAlias(String alias) {
    return $AmmoLotsTable(attachedDatabase, alias);
  }
}

class AmmoLotRecord extends DataClass implements Insertable<AmmoLotRecord> {
  final String id;
  final String cartridgeId;
  final String displayName;
  final String? manufacturer;
  final String? productName;
  final String? lotNumber;
  final double? bulletWeightGrains;
  final String? projectileType;
  final String? notes;
  final bool archived;
  const AmmoLotRecord({
    required this.id,
    required this.cartridgeId,
    required this.displayName,
    this.manufacturer,
    this.productName,
    this.lotNumber,
    this.bulletWeightGrains,
    this.projectileType,
    this.notes,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cartridge_id'] = Variable<String>(cartridgeId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || productName != null) {
      map['product_name'] = Variable<String>(productName);
    }
    if (!nullToAbsent || lotNumber != null) {
      map['lot_number'] = Variable<String>(lotNumber);
    }
    if (!nullToAbsent || bulletWeightGrains != null) {
      map['bullet_weight_grains'] = Variable<double>(bulletWeightGrains);
    }
    if (!nullToAbsent || projectileType != null) {
      map['projectile_type'] = Variable<String>(projectileType);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  AmmoLotsCompanion toCompanion(bool nullToAbsent) {
    return AmmoLotsCompanion(
      id: Value(id),
      cartridgeId: Value(cartridgeId),
      displayName: Value(displayName),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      productName: productName == null && nullToAbsent
          ? const Value.absent()
          : Value(productName),
      lotNumber: lotNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(lotNumber),
      bulletWeightGrains: bulletWeightGrains == null && nullToAbsent
          ? const Value.absent()
          : Value(bulletWeightGrains),
      projectileType: projectileType == null && nullToAbsent
          ? const Value.absent()
          : Value(projectileType),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      archived: Value(archived),
    );
  }

  factory AmmoLotRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AmmoLotRecord(
      id: serializer.fromJson<String>(json['id']),
      cartridgeId: serializer.fromJson<String>(json['cartridgeId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      productName: serializer.fromJson<String?>(json['productName']),
      lotNumber: serializer.fromJson<String?>(json['lotNumber']),
      bulletWeightGrains: serializer.fromJson<double?>(
        json['bulletWeightGrains'],
      ),
      projectileType: serializer.fromJson<String?>(json['projectileType']),
      notes: serializer.fromJson<String?>(json['notes']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cartridgeId': serializer.toJson<String>(cartridgeId),
      'displayName': serializer.toJson<String>(displayName),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'productName': serializer.toJson<String?>(productName),
      'lotNumber': serializer.toJson<String?>(lotNumber),
      'bulletWeightGrains': serializer.toJson<double?>(bulletWeightGrains),
      'projectileType': serializer.toJson<String?>(projectileType),
      'notes': serializer.toJson<String?>(notes),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  AmmoLotRecord copyWith({
    String? id,
    String? cartridgeId,
    String? displayName,
    Value<String?> manufacturer = const Value.absent(),
    Value<String?> productName = const Value.absent(),
    Value<String?> lotNumber = const Value.absent(),
    Value<double?> bulletWeightGrains = const Value.absent(),
    Value<String?> projectileType = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? archived,
  }) => AmmoLotRecord(
    id: id ?? this.id,
    cartridgeId: cartridgeId ?? this.cartridgeId,
    displayName: displayName ?? this.displayName,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    productName: productName.present ? productName.value : this.productName,
    lotNumber: lotNumber.present ? lotNumber.value : this.lotNumber,
    bulletWeightGrains: bulletWeightGrains.present
        ? bulletWeightGrains.value
        : this.bulletWeightGrains,
    projectileType: projectileType.present
        ? projectileType.value
        : this.projectileType,
    notes: notes.present ? notes.value : this.notes,
    archived: archived ?? this.archived,
  );
  AmmoLotRecord copyWithCompanion(AmmoLotsCompanion data) {
    return AmmoLotRecord(
      id: data.id.present ? data.id.value : this.id,
      cartridgeId: data.cartridgeId.present
          ? data.cartridgeId.value
          : this.cartridgeId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      lotNumber: data.lotNumber.present ? data.lotNumber.value : this.lotNumber,
      bulletWeightGrains: data.bulletWeightGrains.present
          ? data.bulletWeightGrains.value
          : this.bulletWeightGrains,
      projectileType: data.projectileType.present
          ? data.projectileType.value
          : this.projectileType,
      notes: data.notes.present ? data.notes.value : this.notes,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AmmoLotRecord(')
          ..write('id: $id, ')
          ..write('cartridgeId: $cartridgeId, ')
          ..write('displayName: $displayName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('productName: $productName, ')
          ..write('lotNumber: $lotNumber, ')
          ..write('bulletWeightGrains: $bulletWeightGrains, ')
          ..write('projectileType: $projectileType, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cartridgeId,
    displayName,
    manufacturer,
    productName,
    lotNumber,
    bulletWeightGrains,
    projectileType,
    notes,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmmoLotRecord &&
          other.id == this.id &&
          other.cartridgeId == this.cartridgeId &&
          other.displayName == this.displayName &&
          other.manufacturer == this.manufacturer &&
          other.productName == this.productName &&
          other.lotNumber == this.lotNumber &&
          other.bulletWeightGrains == this.bulletWeightGrains &&
          other.projectileType == this.projectileType &&
          other.notes == this.notes &&
          other.archived == this.archived);
}

class AmmoLotsCompanion extends UpdateCompanion<AmmoLotRecord> {
  final Value<String> id;
  final Value<String> cartridgeId;
  final Value<String> displayName;
  final Value<String?> manufacturer;
  final Value<String?> productName;
  final Value<String?> lotNumber;
  final Value<double?> bulletWeightGrains;
  final Value<String?> projectileType;
  final Value<String?> notes;
  final Value<bool> archived;
  final Value<int> rowid;
  const AmmoLotsCompanion({
    this.id = const Value.absent(),
    this.cartridgeId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.productName = const Value.absent(),
    this.lotNumber = const Value.absent(),
    this.bulletWeightGrains = const Value.absent(),
    this.projectileType = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AmmoLotsCompanion.insert({
    required String id,
    required String cartridgeId,
    required String displayName,
    this.manufacturer = const Value.absent(),
    this.productName = const Value.absent(),
    this.lotNumber = const Value.absent(),
    this.bulletWeightGrains = const Value.absent(),
    this.projectileType = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cartridgeId = Value(cartridgeId),
       displayName = Value(displayName);
  static Insertable<AmmoLotRecord> custom({
    Expression<String>? id,
    Expression<String>? cartridgeId,
    Expression<String>? displayName,
    Expression<String>? manufacturer,
    Expression<String>? productName,
    Expression<String>? lotNumber,
    Expression<double>? bulletWeightGrains,
    Expression<String>? projectileType,
    Expression<String>? notes,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cartridgeId != null) 'cartridge_id': cartridgeId,
      if (displayName != null) 'display_name': displayName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (productName != null) 'product_name': productName,
      if (lotNumber != null) 'lot_number': lotNumber,
      if (bulletWeightGrains != null)
        'bullet_weight_grains': bulletWeightGrains,
      if (projectileType != null) 'projectile_type': projectileType,
      if (notes != null) 'notes': notes,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AmmoLotsCompanion copyWith({
    Value<String>? id,
    Value<String>? cartridgeId,
    Value<String>? displayName,
    Value<String?>? manufacturer,
    Value<String?>? productName,
    Value<String?>? lotNumber,
    Value<double?>? bulletWeightGrains,
    Value<String?>? projectileType,
    Value<String?>? notes,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return AmmoLotsCompanion(
      id: id ?? this.id,
      cartridgeId: cartridgeId ?? this.cartridgeId,
      displayName: displayName ?? this.displayName,
      manufacturer: manufacturer ?? this.manufacturer,
      productName: productName ?? this.productName,
      lotNumber: lotNumber ?? this.lotNumber,
      bulletWeightGrains: bulletWeightGrains ?? this.bulletWeightGrains,
      projectileType: projectileType ?? this.projectileType,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cartridgeId.present) {
      map['cartridge_id'] = Variable<String>(cartridgeId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (lotNumber.present) {
      map['lot_number'] = Variable<String>(lotNumber.value);
    }
    if (bulletWeightGrains.present) {
      map['bullet_weight_grains'] = Variable<double>(bulletWeightGrains.value);
    }
    if (projectileType.present) {
      map['projectile_type'] = Variable<String>(projectileType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmmoLotsCompanion(')
          ..write('id: $id, ')
          ..write('cartridgeId: $cartridgeId, ')
          ..write('displayName: $displayName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('productName: $productName, ')
          ..write('lotNumber: $lotNumber, ')
          ..write('bulletWeightGrains: $bulletWeightGrains, ')
          ..write('projectileType: $projectileType, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RangesTable extends Ranges with TableInfo<$RangesTable, RangeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _locationDescriptionMeta =
      const VerificationMeta('locationDescription');
  @override
  late final GeneratedColumn<String> locationDescription =
      GeneratedColumn<String>(
        'location_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isIndoorMeta = const VerificationMeta(
    'isIndoor',
  );
  @override
  late final GeneratedColumn<bool> isIndoor = GeneratedColumn<bool>(
    'is_indoor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_indoor" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _availableDistancesJsonMeta =
      const VerificationMeta('availableDistancesJson');
  @override
  late final GeneratedColumn<String> availableDistancesJson =
      GeneratedColumn<String>(
        'available_distances_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    locationDescription,
    isIndoor,
    availableDistancesJson,
    notes,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ranges';
  @override
  VerificationContext validateIntegrity(
    Insertable<RangeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location_description')) {
      context.handle(
        _locationDescriptionMeta,
        locationDescription.isAcceptableOrUnknown(
          data['location_description']!,
          _locationDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_indoor')) {
      context.handle(
        _isIndoorMeta,
        isIndoor.isAcceptableOrUnknown(data['is_indoor']!, _isIndoorMeta),
      );
    }
    if (data.containsKey('available_distances_json')) {
      context.handle(
        _availableDistancesJsonMeta,
        availableDistancesJson.isAcceptableOrUnknown(
          data['available_distances_json']!,
          _availableDistancesJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RangeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RangeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      locationDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_description'],
      ),
      isIndoor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_indoor'],
      )!,
      availableDistancesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}available_distances_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $RangesTable createAlias(String alias) {
    return $RangesTable(attachedDatabase, alias);
  }
}

class RangeRecord extends DataClass implements Insertable<RangeRecord> {
  final String id;
  final String name;
  final String? locationDescription;
  final bool isIndoor;
  final String availableDistancesJson;
  final String? notes;
  final bool archived;
  const RangeRecord({
    required this.id,
    required this.name,
    this.locationDescription,
    required this.isIndoor,
    required this.availableDistancesJson,
    this.notes,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || locationDescription != null) {
      map['location_description'] = Variable<String>(locationDescription);
    }
    map['is_indoor'] = Variable<bool>(isIndoor);
    map['available_distances_json'] = Variable<String>(availableDistancesJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  RangesCompanion toCompanion(bool nullToAbsent) {
    return RangesCompanion(
      id: Value(id),
      name: Value(name),
      locationDescription: locationDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(locationDescription),
      isIndoor: Value(isIndoor),
      availableDistancesJson: Value(availableDistancesJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      archived: Value(archived),
    );
  }

  factory RangeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RangeRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      locationDescription: serializer.fromJson<String?>(
        json['locationDescription'],
      ),
      isIndoor: serializer.fromJson<bool>(json['isIndoor']),
      availableDistancesJson: serializer.fromJson<String>(
        json['availableDistancesJson'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'locationDescription': serializer.toJson<String?>(locationDescription),
      'isIndoor': serializer.toJson<bool>(isIndoor),
      'availableDistancesJson': serializer.toJson<String>(
        availableDistancesJson,
      ),
      'notes': serializer.toJson<String?>(notes),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  RangeRecord copyWith({
    String? id,
    String? name,
    Value<String?> locationDescription = const Value.absent(),
    bool? isIndoor,
    String? availableDistancesJson,
    Value<String?> notes = const Value.absent(),
    bool? archived,
  }) => RangeRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    locationDescription: locationDescription.present
        ? locationDescription.value
        : this.locationDescription,
    isIndoor: isIndoor ?? this.isIndoor,
    availableDistancesJson:
        availableDistancesJson ?? this.availableDistancesJson,
    notes: notes.present ? notes.value : this.notes,
    archived: archived ?? this.archived,
  );
  RangeRecord copyWithCompanion(RangesCompanion data) {
    return RangeRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      locationDescription: data.locationDescription.present
          ? data.locationDescription.value
          : this.locationDescription,
      isIndoor: data.isIndoor.present ? data.isIndoor.value : this.isIndoor,
      availableDistancesJson: data.availableDistancesJson.present
          ? data.availableDistancesJson.value
          : this.availableDistancesJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RangeRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('availableDistancesJson: $availableDistancesJson, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    locationDescription,
    isIndoor,
    availableDistancesJson,
    notes,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RangeRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.locationDescription == this.locationDescription &&
          other.isIndoor == this.isIndoor &&
          other.availableDistancesJson == this.availableDistancesJson &&
          other.notes == this.notes &&
          other.archived == this.archived);
}

class RangesCompanion extends UpdateCompanion<RangeRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> locationDescription;
  final Value<bool> isIndoor;
  final Value<String> availableDistancesJson;
  final Value<String?> notes;
  final Value<bool> archived;
  final Value<int> rowid;
  const RangesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.isIndoor = const Value.absent(),
    this.availableDistancesJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RangesCompanion.insert({
    required String id,
    required String name,
    this.locationDescription = const Value.absent(),
    this.isIndoor = const Value.absent(),
    this.availableDistancesJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<RangeRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? locationDescription,
    Expression<bool>? isIndoor,
    Expression<String>? availableDistancesJson,
    Expression<String>? notes,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (locationDescription != null)
        'location_description': locationDescription,
      if (isIndoor != null) 'is_indoor': isIndoor,
      if (availableDistancesJson != null)
        'available_distances_json': availableDistancesJson,
      if (notes != null) 'notes': notes,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RangesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? locationDescription,
    Value<bool>? isIndoor,
    Value<String>? availableDistancesJson,
    Value<String?>? notes,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return RangesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      locationDescription: locationDescription ?? this.locationDescription,
      isIndoor: isIndoor ?? this.isIndoor,
      availableDistancesJson:
          availableDistancesJson ?? this.availableDistancesJson,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (locationDescription.present) {
      map['location_description'] = Variable<String>(locationDescription.value);
    }
    if (isIndoor.present) {
      map['is_indoor'] = Variable<bool>(isIndoor.value);
    }
    if (availableDistancesJson.present) {
      map['available_distances_json'] = Variable<String>(
        availableDistancesJson.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RangesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('availableDistancesJson: $availableDistancesJson, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainingSessionsTable extends TrainingSessions
    with TableInfo<$TrainingSessionsTable, SessionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _startedAtUtcMeta = const VerificationMeta(
    'startedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startedAtUtc = GeneratedColumn<DateTime>(
    'started_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUtcOffsetMinutesMeta =
      const VerificationMeta('localUtcOffsetMinutes');
  @override
  late final GeneratedColumn<int> localUtcOffsetMinutes = GeneratedColumn<int>(
    'local_utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtUtcMeta = const VerificationMeta(
    'endedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endedAtUtc = GeneratedColumn<DateTime>(
    'ended_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoSafetyAcknowledgedAtUtcMeta =
      const VerificationMeta('photoSafetyAcknowledgedAtUtc');
  @override
  late final GeneratedColumn<DateTime> photoSafetyAcknowledgedAtUtc =
      GeneratedColumn<DateTime>(
        'photo_safety_acknowledged_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rangeIdMeta = const VerificationMeta(
    'rangeId',
  );
  @override
  late final GeneratedColumn<String> rangeId = GeneratedColumn<String>(
    'range_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ranges (id)',
    ),
  );
  static const VerificationMeta _trainingGoalMeta = const VerificationMeta(
    'trainingGoal',
  );
  @override
  late final GeneratedColumn<String> trainingGoal = GeneratedColumn<String>(
    'training_goal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionsMeta = const VerificationMeta(
    'conditions',
  );
  @override
  late final GeneratedColumn<String> conditions = GeneratedColumn<String>(
    'conditions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    startedAtUtc,
    localUtcOffsetMinutes,
    endedAtUtc,
    updatedAtUtc,
    photoSafetyAcknowledgedAtUtc,
    rangeId,
    trainingGoal,
    conditions,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at_utc')) {
      context.handle(
        _startedAtUtcMeta,
        startedAtUtc.isAcceptableOrUnknown(
          data['started_at_utc']!,
          _startedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtUtcMeta);
    }
    if (data.containsKey('local_utc_offset_minutes')) {
      context.handle(
        _localUtcOffsetMinutesMeta,
        localUtcOffsetMinutes.isAcceptableOrUnknown(
          data['local_utc_offset_minutes']!,
          _localUtcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUtcOffsetMinutesMeta);
    }
    if (data.containsKey('ended_at_utc')) {
      context.handle(
        _endedAtUtcMeta,
        endedAtUtc.isAcceptableOrUnknown(
          data['ended_at_utc']!,
          _endedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('photo_safety_acknowledged_at_utc')) {
      context.handle(
        _photoSafetyAcknowledgedAtUtcMeta,
        photoSafetyAcknowledgedAtUtc.isAcceptableOrUnknown(
          data['photo_safety_acknowledged_at_utc']!,
          _photoSafetyAcknowledgedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('range_id')) {
      context.handle(
        _rangeIdMeta,
        rangeId.isAcceptableOrUnknown(data['range_id']!, _rangeIdMeta),
      );
    }
    if (data.containsKey('training_goal')) {
      context.handle(
        _trainingGoalMeta,
        trainingGoal.isAcceptableOrUnknown(
          data['training_goal']!,
          _trainingGoalMeta,
        ),
      );
    }
    if (data.containsKey('conditions')) {
      context.handle(
        _conditionsMeta,
        conditions.isAcceptableOrUnknown(data['conditions']!, _conditionsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at_utc'],
      )!,
      localUtcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_utc_offset_minutes'],
      )!,
      endedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at_utc'],
      ),
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      photoSafetyAcknowledgedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}photo_safety_acknowledged_at_utc'],
      ),
      rangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_id'],
      ),
      trainingGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}training_goal'],
      ),
      conditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conditions'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $TrainingSessionsTable createAlias(String alias) {
    return $TrainingSessionsTable(attachedDatabase, alias);
  }
}

class SessionRecord extends DataClass implements Insertable<SessionRecord> {
  final String id;
  final String status;
  final DateTime startedAtUtc;
  final int localUtcOffsetMinutes;
  final DateTime? endedAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? photoSafetyAcknowledgedAtUtc;
  final String? rangeId;
  final String? trainingGoal;
  final String? conditions;
  final String? notes;
  const SessionRecord({
    required this.id,
    required this.status,
    required this.startedAtUtc,
    required this.localUtcOffsetMinutes,
    this.endedAtUtc,
    required this.updatedAtUtc,
    this.photoSafetyAcknowledgedAtUtc,
    this.rangeId,
    this.trainingGoal,
    this.conditions,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['started_at_utc'] = Variable<DateTime>(startedAtUtc);
    map['local_utc_offset_minutes'] = Variable<int>(localUtcOffsetMinutes);
    if (!nullToAbsent || endedAtUtc != null) {
      map['ended_at_utc'] = Variable<DateTime>(endedAtUtc);
    }
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || photoSafetyAcknowledgedAtUtc != null) {
      map['photo_safety_acknowledged_at_utc'] = Variable<DateTime>(
        photoSafetyAcknowledgedAtUtc,
      );
    }
    if (!nullToAbsent || rangeId != null) {
      map['range_id'] = Variable<String>(rangeId);
    }
    if (!nullToAbsent || trainingGoal != null) {
      map['training_goal'] = Variable<String>(trainingGoal);
    }
    if (!nullToAbsent || conditions != null) {
      map['conditions'] = Variable<String>(conditions);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  TrainingSessionsCompanion toCompanion(bool nullToAbsent) {
    return TrainingSessionsCompanion(
      id: Value(id),
      status: Value(status),
      startedAtUtc: Value(startedAtUtc),
      localUtcOffsetMinutes: Value(localUtcOffsetMinutes),
      endedAtUtc: endedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      photoSafetyAcknowledgedAtUtc:
          photoSafetyAcknowledgedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(photoSafetyAcknowledgedAtUtc),
      rangeId: rangeId == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeId),
      trainingGoal: trainingGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(trainingGoal),
      conditions: conditions == null && nullToAbsent
          ? const Value.absent()
          : Value(conditions),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SessionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRecord(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      startedAtUtc: serializer.fromJson<DateTime>(json['startedAtUtc']),
      localUtcOffsetMinutes: serializer.fromJson<int>(
        json['localUtcOffsetMinutes'],
      ),
      endedAtUtc: serializer.fromJson<DateTime?>(json['endedAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      photoSafetyAcknowledgedAtUtc: serializer.fromJson<DateTime?>(
        json['photoSafetyAcknowledgedAtUtc'],
      ),
      rangeId: serializer.fromJson<String?>(json['rangeId']),
      trainingGoal: serializer.fromJson<String?>(json['trainingGoal']),
      conditions: serializer.fromJson<String?>(json['conditions']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'startedAtUtc': serializer.toJson<DateTime>(startedAtUtc),
      'localUtcOffsetMinutes': serializer.toJson<int>(localUtcOffsetMinutes),
      'endedAtUtc': serializer.toJson<DateTime?>(endedAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'photoSafetyAcknowledgedAtUtc': serializer.toJson<DateTime?>(
        photoSafetyAcknowledgedAtUtc,
      ),
      'rangeId': serializer.toJson<String?>(rangeId),
      'trainingGoal': serializer.toJson<String?>(trainingGoal),
      'conditions': serializer.toJson<String?>(conditions),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SessionRecord copyWith({
    String? id,
    String? status,
    DateTime? startedAtUtc,
    int? localUtcOffsetMinutes,
    Value<DateTime?> endedAtUtc = const Value.absent(),
    DateTime? updatedAtUtc,
    Value<DateTime?> photoSafetyAcknowledgedAtUtc = const Value.absent(),
    Value<String?> rangeId = const Value.absent(),
    Value<String?> trainingGoal = const Value.absent(),
    Value<String?> conditions = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => SessionRecord(
    id: id ?? this.id,
    status: status ?? this.status,
    startedAtUtc: startedAtUtc ?? this.startedAtUtc,
    localUtcOffsetMinutes: localUtcOffsetMinutes ?? this.localUtcOffsetMinutes,
    endedAtUtc: endedAtUtc.present ? endedAtUtc.value : this.endedAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    photoSafetyAcknowledgedAtUtc: photoSafetyAcknowledgedAtUtc.present
        ? photoSafetyAcknowledgedAtUtc.value
        : this.photoSafetyAcknowledgedAtUtc,
    rangeId: rangeId.present ? rangeId.value : this.rangeId,
    trainingGoal: trainingGoal.present ? trainingGoal.value : this.trainingGoal,
    conditions: conditions.present ? conditions.value : this.conditions,
    notes: notes.present ? notes.value : this.notes,
  );
  SessionRecord copyWithCompanion(TrainingSessionsCompanion data) {
    return SessionRecord(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      startedAtUtc: data.startedAtUtc.present
          ? data.startedAtUtc.value
          : this.startedAtUtc,
      localUtcOffsetMinutes: data.localUtcOffsetMinutes.present
          ? data.localUtcOffsetMinutes.value
          : this.localUtcOffsetMinutes,
      endedAtUtc: data.endedAtUtc.present
          ? data.endedAtUtc.value
          : this.endedAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      photoSafetyAcknowledgedAtUtc: data.photoSafetyAcknowledgedAtUtc.present
          ? data.photoSafetyAcknowledgedAtUtc.value
          : this.photoSafetyAcknowledgedAtUtc,
      rangeId: data.rangeId.present ? data.rangeId.value : this.rangeId,
      trainingGoal: data.trainingGoal.present
          ? data.trainingGoal.value
          : this.trainingGoal,
      conditions: data.conditions.present
          ? data.conditions.value
          : this.conditions,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecord(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('localUtcOffsetMinutes: $localUtcOffsetMinutes, ')
          ..write('endedAtUtc: $endedAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write(
            'photoSafetyAcknowledgedAtUtc: $photoSafetyAcknowledgedAtUtc, ',
          )
          ..write('rangeId: $rangeId, ')
          ..write('trainingGoal: $trainingGoal, ')
          ..write('conditions: $conditions, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    startedAtUtc,
    localUtcOffsetMinutes,
    endedAtUtc,
    updatedAtUtc,
    photoSafetyAcknowledgedAtUtc,
    rangeId,
    trainingGoal,
    conditions,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRecord &&
          other.id == this.id &&
          other.status == this.status &&
          other.startedAtUtc == this.startedAtUtc &&
          other.localUtcOffsetMinutes == this.localUtcOffsetMinutes &&
          other.endedAtUtc == this.endedAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.photoSafetyAcknowledgedAtUtc ==
              this.photoSafetyAcknowledgedAtUtc &&
          other.rangeId == this.rangeId &&
          other.trainingGoal == this.trainingGoal &&
          other.conditions == this.conditions &&
          other.notes == this.notes);
}

class TrainingSessionsCompanion extends UpdateCompanion<SessionRecord> {
  final Value<String> id;
  final Value<String> status;
  final Value<DateTime> startedAtUtc;
  final Value<int> localUtcOffsetMinutes;
  final Value<DateTime?> endedAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> photoSafetyAcknowledgedAtUtc;
  final Value<String?> rangeId;
  final Value<String?> trainingGoal;
  final Value<String?> conditions;
  final Value<String?> notes;
  final Value<int> rowid;
  const TrainingSessionsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAtUtc = const Value.absent(),
    this.localUtcOffsetMinutes = const Value.absent(),
    this.endedAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.photoSafetyAcknowledgedAtUtc = const Value.absent(),
    this.rangeId = const Value.absent(),
    this.trainingGoal = const Value.absent(),
    this.conditions = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainingSessionsCompanion.insert({
    required String id,
    required String status,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
    this.endedAtUtc = const Value.absent(),
    required DateTime updatedAtUtc,
    this.photoSafetyAcknowledgedAtUtc = const Value.absent(),
    this.rangeId = const Value.absent(),
    this.trainingGoal = const Value.absent(),
    this.conditions = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       startedAtUtc = Value(startedAtUtc),
       localUtcOffsetMinutes = Value(localUtcOffsetMinutes),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<SessionRecord> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<DateTime>? startedAtUtc,
    Expression<int>? localUtcOffsetMinutes,
    Expression<DateTime>? endedAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? photoSafetyAcknowledgedAtUtc,
    Expression<String>? rangeId,
    Expression<String>? trainingGoal,
    Expression<String>? conditions,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (startedAtUtc != null) 'started_at_utc': startedAtUtc,
      if (localUtcOffsetMinutes != null)
        'local_utc_offset_minutes': localUtcOffsetMinutes,
      if (endedAtUtc != null) 'ended_at_utc': endedAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (photoSafetyAcknowledgedAtUtc != null)
        'photo_safety_acknowledged_at_utc': photoSafetyAcknowledgedAtUtc,
      if (rangeId != null) 'range_id': rangeId,
      if (trainingGoal != null) 'training_goal': trainingGoal,
      if (conditions != null) 'conditions': conditions,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<DateTime>? startedAtUtc,
    Value<int>? localUtcOffsetMinutes,
    Value<DateTime?>? endedAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? photoSafetyAcknowledgedAtUtc,
    Value<String?>? rangeId,
    Value<String?>? trainingGoal,
    Value<String?>? conditions,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return TrainingSessionsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      localUtcOffsetMinutes:
          localUtcOffsetMinutes ?? this.localUtcOffsetMinutes,
      endedAtUtc: endedAtUtc ?? this.endedAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      photoSafetyAcknowledgedAtUtc:
          photoSafetyAcknowledgedAtUtc ?? this.photoSafetyAcknowledgedAtUtc,
      rangeId: rangeId ?? this.rangeId,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAtUtc.present) {
      map['started_at_utc'] = Variable<DateTime>(startedAtUtc.value);
    }
    if (localUtcOffsetMinutes.present) {
      map['local_utc_offset_minutes'] = Variable<int>(
        localUtcOffsetMinutes.value,
      );
    }
    if (endedAtUtc.present) {
      map['ended_at_utc'] = Variable<DateTime>(endedAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (photoSafetyAcknowledgedAtUtc.present) {
      map['photo_safety_acknowledged_at_utc'] = Variable<DateTime>(
        photoSafetyAcknowledgedAtUtc.value,
      );
    }
    if (rangeId.present) {
      map['range_id'] = Variable<String>(rangeId.value);
    }
    if (trainingGoal.present) {
      map['training_goal'] = Variable<String>(trainingGoal.value);
    }
    if (conditions.present) {
      map['conditions'] = Variable<String>(conditions.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('localUtcOffsetMinutes: $localUtcOffsetMinutes, ')
          ..write('endedAtUtc: $endedAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write(
            'photoSafetyAcknowledgedAtUtc: $photoSafetyAcknowledgedAtUtc, ',
          )
          ..write('rangeId: $rangeId, ')
          ..write('trainingGoal: $trainingGoal, ')
          ..write('conditions: $conditions, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShootingSeriesTable extends ShootingSeries
    with TableInfo<$ShootingSeriesTable, SeriesRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShootingSeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES training_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetProfileVersionedIdMeta =
      const VerificationMeta('targetProfileVersionedId');
  @override
  late final GeneratedColumn<String> targetProfileVersionedId =
      GeneratedColumn<String>(
        'target_profile_versioned_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _targetProfileJsonMeta = const VerificationMeta(
    'targetProfileJson',
  );
  @override
  late final GeneratedColumn<String> targetProfileJson =
      GeneratedColumn<String>(
        'target_profile_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectileDiameterMmMeta =
      const VerificationMeta('projectileDiameterMm');
  @override
  late final GeneratedColumn<double> projectileDiameterMm =
      GeneratedColumn<double>(
        'projectile_diameter_mm',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cartridgeIdMeta = const VerificationMeta(
    'cartridgeId',
  );
  @override
  late final GeneratedColumn<String> cartridgeId = GeneratedColumn<String>(
    'cartridge_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cartridges (id)',
    ),
  );
  static const VerificationMeta _shotCountMeta = const VerificationMeta(
    'shotCount',
  );
  @override
  late final GeneratedColumn<int> shotCount = GeneratedColumn<int>(
    'shot_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maximumPossibleScoreMeta =
      const VerificationMeta('maximumPossibleScore');
  @override
  late final GeneratedColumn<int> maximumPossibleScore = GeneratedColumn<int>(
    'maximum_possible_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firearmIdMeta = const VerificationMeta(
    'firearmId',
  );
  @override
  late final GeneratedColumn<String> firearmId = GeneratedColumn<String>(
    'firearm_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES firearms (id)',
    ),
  );
  static const VerificationMeta _ammoLotIdMeta = const VerificationMeta(
    'ammoLotId',
  );
  @override
  late final GeneratedColumn<String> ammoLotId = GeneratedColumn<String>(
    'ammo_lot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ammo_lots (id)',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<int> totalScore = GeneratedColumn<int>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _innerTenCountMeta = const VerificationMeta(
    'innerTenCount',
  );
  @override
  late final GeneratedColumn<int> innerTenCount = GeneratedColumn<int>(
    'inner_ten_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missCountMeta = const VerificationMeta(
    'missCount',
  );
  @override
  late final GeneratedColumn<int> missCount = GeneratedColumn<int>(
    'miss_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scorePenaltyMeta = const VerificationMeta(
    'scorePenalty',
  );
  @override
  late final GeneratedColumn<int> scorePenalty = GeneratedColumn<int>(
    'score_penalty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoredBullCountMeta = const VerificationMeta(
    'scoredBullCount',
  );
  @override
  late final GeneratedColumn<int> scoredBullCount = GeneratedColumn<int>(
    'scored_bull_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasBoundaryWarningsMeta =
      const VerificationMeta('hasBoundaryWarnings');
  @override
  late final GeneratedColumn<bool> hasBoundaryWarnings = GeneratedColumn<bool>(
    'has_boundary_warnings',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_boundary_warnings" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtUtcMeta = const VerificationMeta(
    'confirmedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAtUtc =
      GeneratedColumn<DateTime>(
        'confirmed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    sequenceNumber,
    status,
    targetProfileVersionedId,
    targetProfileJson,
    distanceMeters,
    projectileDiameterMm,
    cartridgeId,
    shotCount,
    maximumPossibleScore,
    firearmId,
    ammoLotId,
    notes,
    totalScore,
    innerTenCount,
    missCount,
    scorePenalty,
    scoredBullCount,
    hasBoundaryWarnings,
    createdAtUtc,
    updatedAtUtc,
    confirmedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shooting_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('target_profile_versioned_id')) {
      context.handle(
        _targetProfileVersionedIdMeta,
        targetProfileVersionedId.isAcceptableOrUnknown(
          data['target_profile_versioned_id']!,
          _targetProfileVersionedIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetProfileVersionedIdMeta);
    }
    if (data.containsKey('target_profile_json')) {
      context.handle(
        _targetProfileJsonMeta,
        targetProfileJson.isAcceptableOrUnknown(
          data['target_profile_json']!,
          _targetProfileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetProfileJsonMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('projectile_diameter_mm')) {
      context.handle(
        _projectileDiameterMmMeta,
        projectileDiameterMm.isAcceptableOrUnknown(
          data['projectile_diameter_mm']!,
          _projectileDiameterMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectileDiameterMmMeta);
    }
    if (data.containsKey('cartridge_id')) {
      context.handle(
        _cartridgeIdMeta,
        cartridgeId.isAcceptableOrUnknown(
          data['cartridge_id']!,
          _cartridgeIdMeta,
        ),
      );
    }
    if (data.containsKey('shot_count')) {
      context.handle(
        _shotCountMeta,
        shotCount.isAcceptableOrUnknown(data['shot_count']!, _shotCountMeta),
      );
    }
    if (data.containsKey('maximum_possible_score')) {
      context.handle(
        _maximumPossibleScoreMeta,
        maximumPossibleScore.isAcceptableOrUnknown(
          data['maximum_possible_score']!,
          _maximumPossibleScoreMeta,
        ),
      );
    }
    if (data.containsKey('firearm_id')) {
      context.handle(
        _firearmIdMeta,
        firearmId.isAcceptableOrUnknown(data['firearm_id']!, _firearmIdMeta),
      );
    }
    if (data.containsKey('ammo_lot_id')) {
      context.handle(
        _ammoLotIdMeta,
        ammoLotId.isAcceptableOrUnknown(data['ammo_lot_id']!, _ammoLotIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    }
    if (data.containsKey('inner_ten_count')) {
      context.handle(
        _innerTenCountMeta,
        innerTenCount.isAcceptableOrUnknown(
          data['inner_ten_count']!,
          _innerTenCountMeta,
        ),
      );
    }
    if (data.containsKey('miss_count')) {
      context.handle(
        _missCountMeta,
        missCount.isAcceptableOrUnknown(data['miss_count']!, _missCountMeta),
      );
    }
    if (data.containsKey('score_penalty')) {
      context.handle(
        _scorePenaltyMeta,
        scorePenalty.isAcceptableOrUnknown(
          data['score_penalty']!,
          _scorePenaltyMeta,
        ),
      );
    }
    if (data.containsKey('scored_bull_count')) {
      context.handle(
        _scoredBullCountMeta,
        scoredBullCount.isAcceptableOrUnknown(
          data['scored_bull_count']!,
          _scoredBullCountMeta,
        ),
      );
    }
    if (data.containsKey('has_boundary_warnings')) {
      context.handle(
        _hasBoundaryWarningsMeta,
        hasBoundaryWarnings.isAcceptableOrUnknown(
          data['has_boundary_warnings']!,
          _hasBoundaryWarningsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('confirmed_at_utc')) {
      context.handle(
        _confirmedAtUtcMeta,
        confirmedAtUtc.isAcceptableOrUnknown(
          data['confirmed_at_utc']!,
          _confirmedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      targetProfileVersionedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_profile_versioned_id'],
      )!,
      targetProfileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_profile_json'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      projectileDiameterMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}projectile_diameter_mm'],
      )!,
      cartridgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cartridge_id'],
      ),
      shotCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_count'],
      )!,
      maximumPossibleScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maximum_possible_score'],
      )!,
      firearmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firearm_id'],
      ),
      ammoLotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ammo_lot_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_score'],
      )!,
      innerTenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}inner_ten_count'],
      )!,
      missCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}miss_count'],
      )!,
      scorePenalty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_penalty'],
      )!,
      scoredBullCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scored_bull_count'],
      ),
      hasBoundaryWarnings: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_boundary_warnings'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      confirmedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at_utc'],
      ),
    );
  }

  @override
  $ShootingSeriesTable createAlias(String alias) {
    return $ShootingSeriesTable(attachedDatabase, alias);
  }
}

class SeriesRecord extends DataClass implements Insertable<SeriesRecord> {
  final String id;
  final String sessionId;
  final int sequenceNumber;
  final String status;
  final String targetProfileVersionedId;
  final String targetProfileJson;
  final double distanceMeters;
  final double projectileDiameterMm;
  final String? cartridgeId;
  final int shotCount;
  final int maximumPossibleScore;
  final String? firearmId;
  final String? ammoLotId;
  final String? notes;
  final int totalScore;
  final int innerTenCount;
  final int missCount;
  final int scorePenalty;
  final int? scoredBullCount;
  final bool hasBoundaryWarnings;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? confirmedAtUtc;
  const SeriesRecord({
    required this.id,
    required this.sessionId,
    required this.sequenceNumber,
    required this.status,
    required this.targetProfileVersionedId,
    required this.targetProfileJson,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    this.cartridgeId,
    required this.shotCount,
    required this.maximumPossibleScore,
    this.firearmId,
    this.ammoLotId,
    this.notes,
    required this.totalScore,
    required this.innerTenCount,
    required this.missCount,
    required this.scorePenalty,
    this.scoredBullCount,
    required this.hasBoundaryWarnings,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.confirmedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['status'] = Variable<String>(status);
    map['target_profile_versioned_id'] = Variable<String>(
      targetProfileVersionedId,
    );
    map['target_profile_json'] = Variable<String>(targetProfileJson);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['projectile_diameter_mm'] = Variable<double>(projectileDiameterMm);
    if (!nullToAbsent || cartridgeId != null) {
      map['cartridge_id'] = Variable<String>(cartridgeId);
    }
    map['shot_count'] = Variable<int>(shotCount);
    map['maximum_possible_score'] = Variable<int>(maximumPossibleScore);
    if (!nullToAbsent || firearmId != null) {
      map['firearm_id'] = Variable<String>(firearmId);
    }
    if (!nullToAbsent || ammoLotId != null) {
      map['ammo_lot_id'] = Variable<String>(ammoLotId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['total_score'] = Variable<int>(totalScore);
    map['inner_ten_count'] = Variable<int>(innerTenCount);
    map['miss_count'] = Variable<int>(missCount);
    map['score_penalty'] = Variable<int>(scorePenalty);
    if (!nullToAbsent || scoredBullCount != null) {
      map['scored_bull_count'] = Variable<int>(scoredBullCount);
    }
    map['has_boundary_warnings'] = Variable<bool>(hasBoundaryWarnings);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || confirmedAtUtc != null) {
      map['confirmed_at_utc'] = Variable<DateTime>(confirmedAtUtc);
    }
    return map;
  }

  ShootingSeriesCompanion toCompanion(bool nullToAbsent) {
    return ShootingSeriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      sequenceNumber: Value(sequenceNumber),
      status: Value(status),
      targetProfileVersionedId: Value(targetProfileVersionedId),
      targetProfileJson: Value(targetProfileJson),
      distanceMeters: Value(distanceMeters),
      projectileDiameterMm: Value(projectileDiameterMm),
      cartridgeId: cartridgeId == null && nullToAbsent
          ? const Value.absent()
          : Value(cartridgeId),
      shotCount: Value(shotCount),
      maximumPossibleScore: Value(maximumPossibleScore),
      firearmId: firearmId == null && nullToAbsent
          ? const Value.absent()
          : Value(firearmId),
      ammoLotId: ammoLotId == null && nullToAbsent
          ? const Value.absent()
          : Value(ammoLotId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      totalScore: Value(totalScore),
      innerTenCount: Value(innerTenCount),
      missCount: Value(missCount),
      scorePenalty: Value(scorePenalty),
      scoredBullCount: scoredBullCount == null && nullToAbsent
          ? const Value.absent()
          : Value(scoredBullCount),
      hasBoundaryWarnings: Value(hasBoundaryWarnings),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      confirmedAtUtc: confirmedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAtUtc),
    );
  }

  factory SeriesRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRecord(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      status: serializer.fromJson<String>(json['status']),
      targetProfileVersionedId: serializer.fromJson<String>(
        json['targetProfileVersionedId'],
      ),
      targetProfileJson: serializer.fromJson<String>(json['targetProfileJson']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      projectileDiameterMm: serializer.fromJson<double>(
        json['projectileDiameterMm'],
      ),
      cartridgeId: serializer.fromJson<String?>(json['cartridgeId']),
      shotCount: serializer.fromJson<int>(json['shotCount']),
      maximumPossibleScore: serializer.fromJson<int>(
        json['maximumPossibleScore'],
      ),
      firearmId: serializer.fromJson<String?>(json['firearmId']),
      ammoLotId: serializer.fromJson<String?>(json['ammoLotId']),
      notes: serializer.fromJson<String?>(json['notes']),
      totalScore: serializer.fromJson<int>(json['totalScore']),
      innerTenCount: serializer.fromJson<int>(json['innerTenCount']),
      missCount: serializer.fromJson<int>(json['missCount']),
      scorePenalty: serializer.fromJson<int>(json['scorePenalty']),
      scoredBullCount: serializer.fromJson<int?>(json['scoredBullCount']),
      hasBoundaryWarnings: serializer.fromJson<bool>(
        json['hasBoundaryWarnings'],
      ),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      confirmedAtUtc: serializer.fromJson<DateTime?>(json['confirmedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'status': serializer.toJson<String>(status),
      'targetProfileVersionedId': serializer.toJson<String>(
        targetProfileVersionedId,
      ),
      'targetProfileJson': serializer.toJson<String>(targetProfileJson),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'projectileDiameterMm': serializer.toJson<double>(projectileDiameterMm),
      'cartridgeId': serializer.toJson<String?>(cartridgeId),
      'shotCount': serializer.toJson<int>(shotCount),
      'maximumPossibleScore': serializer.toJson<int>(maximumPossibleScore),
      'firearmId': serializer.toJson<String?>(firearmId),
      'ammoLotId': serializer.toJson<String?>(ammoLotId),
      'notes': serializer.toJson<String?>(notes),
      'totalScore': serializer.toJson<int>(totalScore),
      'innerTenCount': serializer.toJson<int>(innerTenCount),
      'missCount': serializer.toJson<int>(missCount),
      'scorePenalty': serializer.toJson<int>(scorePenalty),
      'scoredBullCount': serializer.toJson<int?>(scoredBullCount),
      'hasBoundaryWarnings': serializer.toJson<bool>(hasBoundaryWarnings),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'confirmedAtUtc': serializer.toJson<DateTime?>(confirmedAtUtc),
    };
  }

  SeriesRecord copyWith({
    String? id,
    String? sessionId,
    int? sequenceNumber,
    String? status,
    String? targetProfileVersionedId,
    String? targetProfileJson,
    double? distanceMeters,
    double? projectileDiameterMm,
    Value<String?> cartridgeId = const Value.absent(),
    int? shotCount,
    int? maximumPossibleScore,
    Value<String?> firearmId = const Value.absent(),
    Value<String?> ammoLotId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? totalScore,
    int? innerTenCount,
    int? missCount,
    int? scorePenalty,
    Value<int?> scoredBullCount = const Value.absent(),
    bool? hasBoundaryWarnings,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> confirmedAtUtc = const Value.absent(),
  }) => SeriesRecord(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    status: status ?? this.status,
    targetProfileVersionedId:
        targetProfileVersionedId ?? this.targetProfileVersionedId,
    targetProfileJson: targetProfileJson ?? this.targetProfileJson,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    projectileDiameterMm: projectileDiameterMm ?? this.projectileDiameterMm,
    cartridgeId: cartridgeId.present ? cartridgeId.value : this.cartridgeId,
    shotCount: shotCount ?? this.shotCount,
    maximumPossibleScore: maximumPossibleScore ?? this.maximumPossibleScore,
    firearmId: firearmId.present ? firearmId.value : this.firearmId,
    ammoLotId: ammoLotId.present ? ammoLotId.value : this.ammoLotId,
    notes: notes.present ? notes.value : this.notes,
    totalScore: totalScore ?? this.totalScore,
    innerTenCount: innerTenCount ?? this.innerTenCount,
    missCount: missCount ?? this.missCount,
    scorePenalty: scorePenalty ?? this.scorePenalty,
    scoredBullCount: scoredBullCount.present
        ? scoredBullCount.value
        : this.scoredBullCount,
    hasBoundaryWarnings: hasBoundaryWarnings ?? this.hasBoundaryWarnings,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    confirmedAtUtc: confirmedAtUtc.present
        ? confirmedAtUtc.value
        : this.confirmedAtUtc,
  );
  SeriesRecord copyWithCompanion(ShootingSeriesCompanion data) {
    return SeriesRecord(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      status: data.status.present ? data.status.value : this.status,
      targetProfileVersionedId: data.targetProfileVersionedId.present
          ? data.targetProfileVersionedId.value
          : this.targetProfileVersionedId,
      targetProfileJson: data.targetProfileJson.present
          ? data.targetProfileJson.value
          : this.targetProfileJson,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      projectileDiameterMm: data.projectileDiameterMm.present
          ? data.projectileDiameterMm.value
          : this.projectileDiameterMm,
      cartridgeId: data.cartridgeId.present
          ? data.cartridgeId.value
          : this.cartridgeId,
      shotCount: data.shotCount.present ? data.shotCount.value : this.shotCount,
      maximumPossibleScore: data.maximumPossibleScore.present
          ? data.maximumPossibleScore.value
          : this.maximumPossibleScore,
      firearmId: data.firearmId.present ? data.firearmId.value : this.firearmId,
      ammoLotId: data.ammoLotId.present ? data.ammoLotId.value : this.ammoLotId,
      notes: data.notes.present ? data.notes.value : this.notes,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      innerTenCount: data.innerTenCount.present
          ? data.innerTenCount.value
          : this.innerTenCount,
      missCount: data.missCount.present ? data.missCount.value : this.missCount,
      scorePenalty: data.scorePenalty.present
          ? data.scorePenalty.value
          : this.scorePenalty,
      scoredBullCount: data.scoredBullCount.present
          ? data.scoredBullCount.value
          : this.scoredBullCount,
      hasBoundaryWarnings: data.hasBoundaryWarnings.present
          ? data.hasBoundaryWarnings.value
          : this.hasBoundaryWarnings,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      confirmedAtUtc: data.confirmedAtUtc.present
          ? data.confirmedAtUtc.value
          : this.confirmedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRecord(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('status: $status, ')
          ..write('targetProfileVersionedId: $targetProfileVersionedId, ')
          ..write('targetProfileJson: $targetProfileJson, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('projectileDiameterMm: $projectileDiameterMm, ')
          ..write('cartridgeId: $cartridgeId, ')
          ..write('shotCount: $shotCount, ')
          ..write('maximumPossibleScore: $maximumPossibleScore, ')
          ..write('firearmId: $firearmId, ')
          ..write('ammoLotId: $ammoLotId, ')
          ..write('notes: $notes, ')
          ..write('totalScore: $totalScore, ')
          ..write('innerTenCount: $innerTenCount, ')
          ..write('missCount: $missCount, ')
          ..write('scorePenalty: $scorePenalty, ')
          ..write('scoredBullCount: $scoredBullCount, ')
          ..write('hasBoundaryWarnings: $hasBoundaryWarnings, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('confirmedAtUtc: $confirmedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sessionId,
    sequenceNumber,
    status,
    targetProfileVersionedId,
    targetProfileJson,
    distanceMeters,
    projectileDiameterMm,
    cartridgeId,
    shotCount,
    maximumPossibleScore,
    firearmId,
    ammoLotId,
    notes,
    totalScore,
    innerTenCount,
    missCount,
    scorePenalty,
    scoredBullCount,
    hasBoundaryWarnings,
    createdAtUtc,
    updatedAtUtc,
    confirmedAtUtc,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRecord &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.sequenceNumber == this.sequenceNumber &&
          other.status == this.status &&
          other.targetProfileVersionedId == this.targetProfileVersionedId &&
          other.targetProfileJson == this.targetProfileJson &&
          other.distanceMeters == this.distanceMeters &&
          other.projectileDiameterMm == this.projectileDiameterMm &&
          other.cartridgeId == this.cartridgeId &&
          other.shotCount == this.shotCount &&
          other.maximumPossibleScore == this.maximumPossibleScore &&
          other.firearmId == this.firearmId &&
          other.ammoLotId == this.ammoLotId &&
          other.notes == this.notes &&
          other.totalScore == this.totalScore &&
          other.innerTenCount == this.innerTenCount &&
          other.missCount == this.missCount &&
          other.scorePenalty == this.scorePenalty &&
          other.scoredBullCount == this.scoredBullCount &&
          other.hasBoundaryWarnings == this.hasBoundaryWarnings &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.confirmedAtUtc == this.confirmedAtUtc);
}

class ShootingSeriesCompanion extends UpdateCompanion<SeriesRecord> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> sequenceNumber;
  final Value<String> status;
  final Value<String> targetProfileVersionedId;
  final Value<String> targetProfileJson;
  final Value<double> distanceMeters;
  final Value<double> projectileDiameterMm;
  final Value<String?> cartridgeId;
  final Value<int> shotCount;
  final Value<int> maximumPossibleScore;
  final Value<String?> firearmId;
  final Value<String?> ammoLotId;
  final Value<String?> notes;
  final Value<int> totalScore;
  final Value<int> innerTenCount;
  final Value<int> missCount;
  final Value<int> scorePenalty;
  final Value<int?> scoredBullCount;
  final Value<bool> hasBoundaryWarnings;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> confirmedAtUtc;
  final Value<int> rowid;
  const ShootingSeriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.targetProfileVersionedId = const Value.absent(),
    this.targetProfileJson = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.projectileDiameterMm = const Value.absent(),
    this.cartridgeId = const Value.absent(),
    this.shotCount = const Value.absent(),
    this.maximumPossibleScore = const Value.absent(),
    this.firearmId = const Value.absent(),
    this.ammoLotId = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.innerTenCount = const Value.absent(),
    this.missCount = const Value.absent(),
    this.scorePenalty = const Value.absent(),
    this.scoredBullCount = const Value.absent(),
    this.hasBoundaryWarnings = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.confirmedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShootingSeriesCompanion.insert({
    required String id,
    required String sessionId,
    required int sequenceNumber,
    required String status,
    required String targetProfileVersionedId,
    required String targetProfileJson,
    required double distanceMeters,
    required double projectileDiameterMm,
    this.cartridgeId = const Value.absent(),
    this.shotCount = const Value.absent(),
    this.maximumPossibleScore = const Value.absent(),
    this.firearmId = const Value.absent(),
    this.ammoLotId = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.innerTenCount = const Value.absent(),
    this.missCount = const Value.absent(),
    this.scorePenalty = const Value.absent(),
    this.scoredBullCount = const Value.absent(),
    this.hasBoundaryWarnings = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.confirmedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       sequenceNumber = Value(sequenceNumber),
       status = Value(status),
       targetProfileVersionedId = Value(targetProfileVersionedId),
       targetProfileJson = Value(targetProfileJson),
       distanceMeters = Value(distanceMeters),
       projectileDiameterMm = Value(projectileDiameterMm),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<SeriesRecord> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? sequenceNumber,
    Expression<String>? status,
    Expression<String>? targetProfileVersionedId,
    Expression<String>? targetProfileJson,
    Expression<double>? distanceMeters,
    Expression<double>? projectileDiameterMm,
    Expression<String>? cartridgeId,
    Expression<int>? shotCount,
    Expression<int>? maximumPossibleScore,
    Expression<String>? firearmId,
    Expression<String>? ammoLotId,
    Expression<String>? notes,
    Expression<int>? totalScore,
    Expression<int>? innerTenCount,
    Expression<int>? missCount,
    Expression<int>? scorePenalty,
    Expression<int>? scoredBullCount,
    Expression<bool>? hasBoundaryWarnings,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? confirmedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (status != null) 'status': status,
      if (targetProfileVersionedId != null)
        'target_profile_versioned_id': targetProfileVersionedId,
      if (targetProfileJson != null) 'target_profile_json': targetProfileJson,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (projectileDiameterMm != null)
        'projectile_diameter_mm': projectileDiameterMm,
      if (cartridgeId != null) 'cartridge_id': cartridgeId,
      if (shotCount != null) 'shot_count': shotCount,
      if (maximumPossibleScore != null)
        'maximum_possible_score': maximumPossibleScore,
      if (firearmId != null) 'firearm_id': firearmId,
      if (ammoLotId != null) 'ammo_lot_id': ammoLotId,
      if (notes != null) 'notes': notes,
      if (totalScore != null) 'total_score': totalScore,
      if (innerTenCount != null) 'inner_ten_count': innerTenCount,
      if (missCount != null) 'miss_count': missCount,
      if (scorePenalty != null) 'score_penalty': scorePenalty,
      if (scoredBullCount != null) 'scored_bull_count': scoredBullCount,
      if (hasBoundaryWarnings != null)
        'has_boundary_warnings': hasBoundaryWarnings,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (confirmedAtUtc != null) 'confirmed_at_utc': confirmedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShootingSeriesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? sequenceNumber,
    Value<String>? status,
    Value<String>? targetProfileVersionedId,
    Value<String>? targetProfileJson,
    Value<double>? distanceMeters,
    Value<double>? projectileDiameterMm,
    Value<String?>? cartridgeId,
    Value<int>? shotCount,
    Value<int>? maximumPossibleScore,
    Value<String?>? firearmId,
    Value<String?>? ammoLotId,
    Value<String?>? notes,
    Value<int>? totalScore,
    Value<int>? innerTenCount,
    Value<int>? missCount,
    Value<int>? scorePenalty,
    Value<int?>? scoredBullCount,
    Value<bool>? hasBoundaryWarnings,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? confirmedAtUtc,
    Value<int>? rowid,
  }) {
    return ShootingSeriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      status: status ?? this.status,
      targetProfileVersionedId:
          targetProfileVersionedId ?? this.targetProfileVersionedId,
      targetProfileJson: targetProfileJson ?? this.targetProfileJson,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      projectileDiameterMm: projectileDiameterMm ?? this.projectileDiameterMm,
      cartridgeId: cartridgeId ?? this.cartridgeId,
      shotCount: shotCount ?? this.shotCount,
      maximumPossibleScore: maximumPossibleScore ?? this.maximumPossibleScore,
      firearmId: firearmId ?? this.firearmId,
      ammoLotId: ammoLotId ?? this.ammoLotId,
      notes: notes ?? this.notes,
      totalScore: totalScore ?? this.totalScore,
      innerTenCount: innerTenCount ?? this.innerTenCount,
      missCount: missCount ?? this.missCount,
      scorePenalty: scorePenalty ?? this.scorePenalty,
      scoredBullCount: scoredBullCount ?? this.scoredBullCount,
      hasBoundaryWarnings: hasBoundaryWarnings ?? this.hasBoundaryWarnings,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      confirmedAtUtc: confirmedAtUtc ?? this.confirmedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (targetProfileVersionedId.present) {
      map['target_profile_versioned_id'] = Variable<String>(
        targetProfileVersionedId.value,
      );
    }
    if (targetProfileJson.present) {
      map['target_profile_json'] = Variable<String>(targetProfileJson.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (projectileDiameterMm.present) {
      map['projectile_diameter_mm'] = Variable<double>(
        projectileDiameterMm.value,
      );
    }
    if (cartridgeId.present) {
      map['cartridge_id'] = Variable<String>(cartridgeId.value);
    }
    if (shotCount.present) {
      map['shot_count'] = Variable<int>(shotCount.value);
    }
    if (maximumPossibleScore.present) {
      map['maximum_possible_score'] = Variable<int>(maximumPossibleScore.value);
    }
    if (firearmId.present) {
      map['firearm_id'] = Variable<String>(firearmId.value);
    }
    if (ammoLotId.present) {
      map['ammo_lot_id'] = Variable<String>(ammoLotId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<int>(totalScore.value);
    }
    if (innerTenCount.present) {
      map['inner_ten_count'] = Variable<int>(innerTenCount.value);
    }
    if (missCount.present) {
      map['miss_count'] = Variable<int>(missCount.value);
    }
    if (scorePenalty.present) {
      map['score_penalty'] = Variable<int>(scorePenalty.value);
    }
    if (scoredBullCount.present) {
      map['scored_bull_count'] = Variable<int>(scoredBullCount.value);
    }
    if (hasBoundaryWarnings.present) {
      map['has_boundary_warnings'] = Variable<bool>(hasBoundaryWarnings.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (confirmedAtUtc.present) {
      map['confirmed_at_utc'] = Variable<DateTime>(confirmedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShootingSeriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('status: $status, ')
          ..write('targetProfileVersionedId: $targetProfileVersionedId, ')
          ..write('targetProfileJson: $targetProfileJson, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('projectileDiameterMm: $projectileDiameterMm, ')
          ..write('cartridgeId: $cartridgeId, ')
          ..write('shotCount: $shotCount, ')
          ..write('maximumPossibleScore: $maximumPossibleScore, ')
          ..write('firearmId: $firearmId, ')
          ..write('ammoLotId: $ammoLotId, ')
          ..write('notes: $notes, ')
          ..write('totalScore: $totalScore, ')
          ..write('innerTenCount: $innerTenCount, ')
          ..write('missCount: $missCount, ')
          ..write('scorePenalty: $scorePenalty, ')
          ..write('scoredBullCount: $scoredBullCount, ')
          ..write('hasBoundaryWarnings: $hasBoundaryWarnings, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('confirmedAtUtc: $confirmedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageAssetsTable extends ImageAssets
    with TableInfo<$ImageAssetsTable, ImageAssetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES training_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shooting_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seriesId,
    role,
    path,
    sha256,
    width,
    height,
    sizeBytes,
    caption,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageAssetRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImageAssetRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageAssetRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $ImageAssetsTable createAlias(String alias) {
    return $ImageAssetsTable(attachedDatabase, alias);
  }
}

class ImageAssetRecord extends DataClass
    implements Insertable<ImageAssetRecord> {
  final String id;
  final String sessionId;
  final String? seriesId;
  final String role;
  final String path;
  final String sha256;
  final int width;
  final int height;
  final int sizeBytes;
  final String? caption;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const ImageAssetRecord({
    required this.id,
    required this.sessionId,
    this.seriesId,
    required this.role,
    required this.path,
    required this.sha256,
    required this.width,
    required this.height,
    required this.sizeBytes,
    this.caption,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    map['role'] = Variable<String>(role);
    map['path'] = Variable<String>(path);
    map['sha256'] = Variable<String>(sha256);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  ImageAssetsCompanion toCompanion(bool nullToAbsent) {
    return ImageAssetsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      role: Value(role),
      path: Value(path),
      sha256: Value(sha256),
      width: Value(width),
      height: Value(height),
      sizeBytes: Value(sizeBytes),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory ImageAssetRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageAssetRecord(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      role: serializer.fromJson<String>(json['role']),
      path: serializer.fromJson<String>(json['path']),
      sha256: serializer.fromJson<String>(json['sha256']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      caption: serializer.fromJson<String?>(json['caption']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seriesId': serializer.toJson<String?>(seriesId),
      'role': serializer.toJson<String>(role),
      'path': serializer.toJson<String>(path),
      'sha256': serializer.toJson<String>(sha256),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'caption': serializer.toJson<String?>(caption),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  ImageAssetRecord copyWith({
    String? id,
    String? sessionId,
    Value<String?> seriesId = const Value.absent(),
    String? role,
    String? path,
    String? sha256,
    int? width,
    int? height,
    int? sizeBytes,
    Value<String?> caption = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => ImageAssetRecord(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    role: role ?? this.role,
    path: path ?? this.path,
    sha256: sha256 ?? this.sha256,
    width: width ?? this.width,
    height: height ?? this.height,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    caption: caption.present ? caption.value : this.caption,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  ImageAssetRecord copyWithCompanion(ImageAssetsCompanion data) {
    return ImageAssetRecord(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      role: data.role.present ? data.role.value : this.role,
      path: data.path.present ? data.path.value : this.path,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageAssetRecord(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seriesId: $seriesId, ')
          ..write('role: $role, ')
          ..write('path: $path, ')
          ..write('sha256: $sha256, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('caption: $caption, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seriesId,
    role,
    path,
    sha256,
    width,
    height,
    sizeBytes,
    caption,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageAssetRecord &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seriesId == this.seriesId &&
          other.role == this.role &&
          other.path == this.path &&
          other.sha256 == this.sha256 &&
          other.width == this.width &&
          other.height == this.height &&
          other.sizeBytes == this.sizeBytes &&
          other.caption == this.caption &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class ImageAssetsCompanion extends UpdateCompanion<ImageAssetRecord> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String?> seriesId;
  final Value<String> role;
  final Value<String> path;
  final Value<String> sha256;
  final Value<int> width;
  final Value<int> height;
  final Value<int> sizeBytes;
  final Value<String?> caption;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const ImageAssetsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.role = const Value.absent(),
    this.path = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageAssetsCompanion.insert({
    required String id,
    required String sessionId,
    this.seriesId = const Value.absent(),
    required String role,
    required String path,
    required String sha256,
    required int width,
    required int height,
    required int sizeBytes,
    this.caption = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       role = Value(role),
       path = Value(path),
       sha256 = Value(sha256),
       width = Value(width),
       height = Value(height),
       sizeBytes = Value(sizeBytes),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<ImageAssetRecord> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? seriesId,
    Expression<String>? role,
    Expression<String>? path,
    Expression<String>? sha256,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? sizeBytes,
    Expression<String>? caption,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seriesId != null) 'series_id': seriesId,
      if (role != null) 'role': role,
      if (path != null) 'path': path,
      if (sha256 != null) 'sha256': sha256,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (caption != null) 'caption': caption,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String?>? seriesId,
    Value<String>? role,
    Value<String>? path,
    Value<String>? sha256,
    Value<int>? width,
    Value<int>? height,
    Value<int>? sizeBytes,
    Value<String?>? caption,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return ImageAssetsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seriesId: seriesId ?? this.seriesId,
      role: role ?? this.role,
      path: path ?? this.path,
      sha256: sha256 ?? this.sha256,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      caption: caption ?? this.caption,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageAssetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seriesId: $seriesId, ')
          ..write('role: $role, ')
          ..write('path: $path, ')
          ..write('sha256: $sha256, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('caption: $caption, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisionScanDraftsTable extends VisionScanDrafts
    with TableInfo<$VisionScanDraftsTable, VisionScanDraftRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisionScanDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _originalImagePathMeta = const VerificationMeta(
    'originalImagePath',
  );
  @override
  late final GeneratedColumn<String> originalImagePath =
      GeneratedColumn<String>(
        'original_image_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetProfileJsonMeta = const VerificationMeta(
    'targetProfileJson',
  );
  @override
  late final GeneratedColumn<String> targetProfileJson =
      GeneratedColumn<String>(
        'target_profile_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _projectileDiameterMmMeta =
      const VerificationMeta('projectileDiameterMm');
  @override
  late final GeneratedColumn<double> projectileDiameterMm =
      GeneratedColumn<double>(
        'projectile_diameter_mm',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _qualityJsonMeta = const VerificationMeta(
    'qualityJson',
  );
  @override
  late final GeneratedColumn<String> qualityJson = GeneratedColumn<String>(
    'quality_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registrationJsonMeta = const VerificationMeta(
    'registrationJson',
  );
  @override
  late final GeneratedColumn<String> registrationJson = GeneratedColumn<String>(
    'registration_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _candidatesJsonMeta = const VerificationMeta(
    'candidatesJson',
  );
  @override
  late final GeneratedColumn<String> candidatesJson = GeneratedColumn<String>(
    'candidates_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewJsonMeta = const VerificationMeta(
    'reviewJson',
  );
  @override
  late final GeneratedColumn<String> reviewJson = GeneratedColumn<String>(
    'review_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _engineVersionMeta = const VerificationMeta(
    'engineVersion',
  );
  @override
  late final GeneratedColumn<String> engineVersion = GeneratedColumn<String>(
    'engine_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rotationQuarterTurnsMeta =
      const VerificationMeta('rotationQuarterTurns');
  @override
  late final GeneratedColumn<int> rotationQuarterTurns = GeneratedColumn<int>(
    'rotation_quarter_turns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alignmentModeMeta = const VerificationMeta(
    'alignmentMode',
  );
  @override
  late final GeneratedColumn<String> alignmentMode = GeneratedColumn<String>(
    'alignment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fullCard'),
  );
  static const VerificationMeta _anchorsJsonMeta = const VerificationMeta(
    'anchorsJson',
  );
  @override
  late final GeneratedColumn<String> anchorsJson = GeneratedColumn<String>(
    'anchors_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reprojectionRmsMmMeta = const VerificationMeta(
    'reprojectionRmsMm',
  );
  @override
  late final GeneratedColumn<double> reprojectionRmsMm =
      GeneratedColumn<double>(
        'reprojection_rms_mm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reprojectionMaxMmMeta = const VerificationMeta(
    'reprojectionMaxMm',
  );
  @override
  late final GeneratedColumn<double> reprojectionMaxMm =
      GeneratedColumn<double>(
        'reprojection_max_mm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _planarityStatusMeta = const VerificationMeta(
    'planarityStatus',
  );
  @override
  late final GeneratedColumn<String> planarityStatus = GeneratedColumn<String>(
    'planarity_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _alignmentAlgorithmVersionMeta =
      const VerificationMeta('alignmentAlgorithmVersion');
  @override
  late final GeneratedColumn<String> alignmentAlgorithmVersion =
      GeneratedColumn<String>(
        'alignment_algorithm_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _alignmentConfirmedAtUtcMeta =
      const VerificationMeta('alignmentConfirmedAtUtc');
  @override
  late final GeneratedColumn<DateTime> alignmentConfirmedAtUtc =
      GeneratedColumn<DateTime>(
        'alignment_confirmed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    originalImagePath,
    sha256,
    width,
    height,
    sizeBytes,
    targetProfileJson,
    projectileDiameterMm,
    qualityJson,
    registrationJson,
    candidatesJson,
    reviewJson,
    engineVersion,
    failureCode,
    rotationQuarterTurns,
    alignmentMode,
    anchorsJson,
    reprojectionRmsMm,
    reprojectionMaxMm,
    planarityStatus,
    alignmentAlgorithmVersion,
    alignmentConfirmedAtUtc,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vision_scan_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisionScanDraftRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('original_image_path')) {
      context.handle(
        _originalImagePathMeta,
        originalImagePath.isAcceptableOrUnknown(
          data['original_image_path']!,
          _originalImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalImagePathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('target_profile_json')) {
      context.handle(
        _targetProfileJsonMeta,
        targetProfileJson.isAcceptableOrUnknown(
          data['target_profile_json']!,
          _targetProfileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetProfileJsonMeta);
    }
    if (data.containsKey('projectile_diameter_mm')) {
      context.handle(
        _projectileDiameterMmMeta,
        projectileDiameterMm.isAcceptableOrUnknown(
          data['projectile_diameter_mm']!,
          _projectileDiameterMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectileDiameterMmMeta);
    }
    if (data.containsKey('quality_json')) {
      context.handle(
        _qualityJsonMeta,
        qualityJson.isAcceptableOrUnknown(
          data['quality_json']!,
          _qualityJsonMeta,
        ),
      );
    }
    if (data.containsKey('registration_json')) {
      context.handle(
        _registrationJsonMeta,
        registrationJson.isAcceptableOrUnknown(
          data['registration_json']!,
          _registrationJsonMeta,
        ),
      );
    }
    if (data.containsKey('candidates_json')) {
      context.handle(
        _candidatesJsonMeta,
        candidatesJson.isAcceptableOrUnknown(
          data['candidates_json']!,
          _candidatesJsonMeta,
        ),
      );
    }
    if (data.containsKey('review_json')) {
      context.handle(
        _reviewJsonMeta,
        reviewJson.isAcceptableOrUnknown(data['review_json']!, _reviewJsonMeta),
      );
    }
    if (data.containsKey('engine_version')) {
      context.handle(
        _engineVersionMeta,
        engineVersion.isAcceptableOrUnknown(
          data['engine_version']!,
          _engineVersionMeta,
        ),
      );
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('rotation_quarter_turns')) {
      context.handle(
        _rotationQuarterTurnsMeta,
        rotationQuarterTurns.isAcceptableOrUnknown(
          data['rotation_quarter_turns']!,
          _rotationQuarterTurnsMeta,
        ),
      );
    }
    if (data.containsKey('alignment_mode')) {
      context.handle(
        _alignmentModeMeta,
        alignmentMode.isAcceptableOrUnknown(
          data['alignment_mode']!,
          _alignmentModeMeta,
        ),
      );
    }
    if (data.containsKey('anchors_json')) {
      context.handle(
        _anchorsJsonMeta,
        anchorsJson.isAcceptableOrUnknown(
          data['anchors_json']!,
          _anchorsJsonMeta,
        ),
      );
    }
    if (data.containsKey('reprojection_rms_mm')) {
      context.handle(
        _reprojectionRmsMmMeta,
        reprojectionRmsMm.isAcceptableOrUnknown(
          data['reprojection_rms_mm']!,
          _reprojectionRmsMmMeta,
        ),
      );
    }
    if (data.containsKey('reprojection_max_mm')) {
      context.handle(
        _reprojectionMaxMmMeta,
        reprojectionMaxMm.isAcceptableOrUnknown(
          data['reprojection_max_mm']!,
          _reprojectionMaxMmMeta,
        ),
      );
    }
    if (data.containsKey('planarity_status')) {
      context.handle(
        _planarityStatusMeta,
        planarityStatus.isAcceptableOrUnknown(
          data['planarity_status']!,
          _planarityStatusMeta,
        ),
      );
    }
    if (data.containsKey('alignment_algorithm_version')) {
      context.handle(
        _alignmentAlgorithmVersionMeta,
        alignmentAlgorithmVersion.isAcceptableOrUnknown(
          data['alignment_algorithm_version']!,
          _alignmentAlgorithmVersionMeta,
        ),
      );
    }
    if (data.containsKey('alignment_confirmed_at_utc')) {
      context.handle(
        _alignmentConfirmedAtUtcMeta,
        alignmentConfirmedAtUtc.isAcceptableOrUnknown(
          data['alignment_confirmed_at_utc']!,
          _alignmentConfirmedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisionScanDraftRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisionScanDraftRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      originalImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_image_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      targetProfileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_profile_json'],
      )!,
      projectileDiameterMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}projectile_diameter_mm'],
      )!,
      qualityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_json'],
      ),
      registrationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_json'],
      ),
      candidatesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidates_json'],
      ),
      reviewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_json'],
      ),
      engineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_version'],
      ),
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      rotationQuarterTurns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation_quarter_turns'],
      )!,
      alignmentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alignment_mode'],
      )!,
      anchorsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchors_json'],
      ),
      reprojectionRmsMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reprojection_rms_mm'],
      ),
      reprojectionMaxMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reprojection_max_mm'],
      ),
      planarityStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planarity_status'],
      )!,
      alignmentAlgorithmVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alignment_algorithm_version'],
      ),
      alignmentConfirmedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}alignment_confirmed_at_utc'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $VisionScanDraftsTable createAlias(String alias) {
    return $VisionScanDraftsTable(attachedDatabase, alias);
  }
}

class VisionScanDraftRecord extends DataClass
    implements Insertable<VisionScanDraftRecord> {
  final String id;
  final String status;
  final String originalImagePath;
  final String sha256;
  final int width;
  final int height;
  final int sizeBytes;
  final String targetProfileJson;
  final double projectileDiameterMm;
  final String? qualityJson;
  final String? registrationJson;
  final String? candidatesJson;
  final String? reviewJson;
  final String? engineVersion;
  final String? failureCode;
  final int rotationQuarterTurns;
  final String alignmentMode;
  final String? anchorsJson;
  final double? reprojectionRmsMm;
  final double? reprojectionMaxMm;
  final String planarityStatus;
  final String? alignmentAlgorithmVersion;
  final DateTime? alignmentConfirmedAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const VisionScanDraftRecord({
    required this.id,
    required this.status,
    required this.originalImagePath,
    required this.sha256,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.targetProfileJson,
    required this.projectileDiameterMm,
    this.qualityJson,
    this.registrationJson,
    this.candidatesJson,
    this.reviewJson,
    this.engineVersion,
    this.failureCode,
    required this.rotationQuarterTurns,
    required this.alignmentMode,
    this.anchorsJson,
    this.reprojectionRmsMm,
    this.reprojectionMaxMm,
    required this.planarityStatus,
    this.alignmentAlgorithmVersion,
    this.alignmentConfirmedAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['original_image_path'] = Variable<String>(originalImagePath);
    map['sha256'] = Variable<String>(sha256);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['target_profile_json'] = Variable<String>(targetProfileJson);
    map['projectile_diameter_mm'] = Variable<double>(projectileDiameterMm);
    if (!nullToAbsent || qualityJson != null) {
      map['quality_json'] = Variable<String>(qualityJson);
    }
    if (!nullToAbsent || registrationJson != null) {
      map['registration_json'] = Variable<String>(registrationJson);
    }
    if (!nullToAbsent || candidatesJson != null) {
      map['candidates_json'] = Variable<String>(candidatesJson);
    }
    if (!nullToAbsent || reviewJson != null) {
      map['review_json'] = Variable<String>(reviewJson);
    }
    if (!nullToAbsent || engineVersion != null) {
      map['engine_version'] = Variable<String>(engineVersion);
    }
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    map['rotation_quarter_turns'] = Variable<int>(rotationQuarterTurns);
    map['alignment_mode'] = Variable<String>(alignmentMode);
    if (!nullToAbsent || anchorsJson != null) {
      map['anchors_json'] = Variable<String>(anchorsJson);
    }
    if (!nullToAbsent || reprojectionRmsMm != null) {
      map['reprojection_rms_mm'] = Variable<double>(reprojectionRmsMm);
    }
    if (!nullToAbsent || reprojectionMaxMm != null) {
      map['reprojection_max_mm'] = Variable<double>(reprojectionMaxMm);
    }
    map['planarity_status'] = Variable<String>(planarityStatus);
    if (!nullToAbsent || alignmentAlgorithmVersion != null) {
      map['alignment_algorithm_version'] = Variable<String>(
        alignmentAlgorithmVersion,
      );
    }
    if (!nullToAbsent || alignmentConfirmedAtUtc != null) {
      map['alignment_confirmed_at_utc'] = Variable<DateTime>(
        alignmentConfirmedAtUtc,
      );
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  VisionScanDraftsCompanion toCompanion(bool nullToAbsent) {
    return VisionScanDraftsCompanion(
      id: Value(id),
      status: Value(status),
      originalImagePath: Value(originalImagePath),
      sha256: Value(sha256),
      width: Value(width),
      height: Value(height),
      sizeBytes: Value(sizeBytes),
      targetProfileJson: Value(targetProfileJson),
      projectileDiameterMm: Value(projectileDiameterMm),
      qualityJson: qualityJson == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityJson),
      registrationJson: registrationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationJson),
      candidatesJson: candidatesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(candidatesJson),
      reviewJson: reviewJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewJson),
      engineVersion: engineVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(engineVersion),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      rotationQuarterTurns: Value(rotationQuarterTurns),
      alignmentMode: Value(alignmentMode),
      anchorsJson: anchorsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorsJson),
      reprojectionRmsMm: reprojectionRmsMm == null && nullToAbsent
          ? const Value.absent()
          : Value(reprojectionRmsMm),
      reprojectionMaxMm: reprojectionMaxMm == null && nullToAbsent
          ? const Value.absent()
          : Value(reprojectionMaxMm),
      planarityStatus: Value(planarityStatus),
      alignmentAlgorithmVersion:
          alignmentAlgorithmVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(alignmentAlgorithmVersion),
      alignmentConfirmedAtUtc: alignmentConfirmedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(alignmentConfirmedAtUtc),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory VisionScanDraftRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisionScanDraftRecord(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      originalImagePath: serializer.fromJson<String>(json['originalImagePath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      targetProfileJson: serializer.fromJson<String>(json['targetProfileJson']),
      projectileDiameterMm: serializer.fromJson<double>(
        json['projectileDiameterMm'],
      ),
      qualityJson: serializer.fromJson<String?>(json['qualityJson']),
      registrationJson: serializer.fromJson<String?>(json['registrationJson']),
      candidatesJson: serializer.fromJson<String?>(json['candidatesJson']),
      reviewJson: serializer.fromJson<String?>(json['reviewJson']),
      engineVersion: serializer.fromJson<String?>(json['engineVersion']),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      rotationQuarterTurns: serializer.fromJson<int>(
        json['rotationQuarterTurns'],
      ),
      alignmentMode: serializer.fromJson<String>(json['alignmentMode']),
      anchorsJson: serializer.fromJson<String?>(json['anchorsJson']),
      reprojectionRmsMm: serializer.fromJson<double?>(
        json['reprojectionRmsMm'],
      ),
      reprojectionMaxMm: serializer.fromJson<double?>(
        json['reprojectionMaxMm'],
      ),
      planarityStatus: serializer.fromJson<String>(json['planarityStatus']),
      alignmentAlgorithmVersion: serializer.fromJson<String?>(
        json['alignmentAlgorithmVersion'],
      ),
      alignmentConfirmedAtUtc: serializer.fromJson<DateTime?>(
        json['alignmentConfirmedAtUtc'],
      ),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'originalImagePath': serializer.toJson<String>(originalImagePath),
      'sha256': serializer.toJson<String>(sha256),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'targetProfileJson': serializer.toJson<String>(targetProfileJson),
      'projectileDiameterMm': serializer.toJson<double>(projectileDiameterMm),
      'qualityJson': serializer.toJson<String?>(qualityJson),
      'registrationJson': serializer.toJson<String?>(registrationJson),
      'candidatesJson': serializer.toJson<String?>(candidatesJson),
      'reviewJson': serializer.toJson<String?>(reviewJson),
      'engineVersion': serializer.toJson<String?>(engineVersion),
      'failureCode': serializer.toJson<String?>(failureCode),
      'rotationQuarterTurns': serializer.toJson<int>(rotationQuarterTurns),
      'alignmentMode': serializer.toJson<String>(alignmentMode),
      'anchorsJson': serializer.toJson<String?>(anchorsJson),
      'reprojectionRmsMm': serializer.toJson<double?>(reprojectionRmsMm),
      'reprojectionMaxMm': serializer.toJson<double?>(reprojectionMaxMm),
      'planarityStatus': serializer.toJson<String>(planarityStatus),
      'alignmentAlgorithmVersion': serializer.toJson<String?>(
        alignmentAlgorithmVersion,
      ),
      'alignmentConfirmedAtUtc': serializer.toJson<DateTime?>(
        alignmentConfirmedAtUtc,
      ),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  VisionScanDraftRecord copyWith({
    String? id,
    String? status,
    String? originalImagePath,
    String? sha256,
    int? width,
    int? height,
    int? sizeBytes,
    String? targetProfileJson,
    double? projectileDiameterMm,
    Value<String?> qualityJson = const Value.absent(),
    Value<String?> registrationJson = const Value.absent(),
    Value<String?> candidatesJson = const Value.absent(),
    Value<String?> reviewJson = const Value.absent(),
    Value<String?> engineVersion = const Value.absent(),
    Value<String?> failureCode = const Value.absent(),
    int? rotationQuarterTurns,
    String? alignmentMode,
    Value<String?> anchorsJson = const Value.absent(),
    Value<double?> reprojectionRmsMm = const Value.absent(),
    Value<double?> reprojectionMaxMm = const Value.absent(),
    String? planarityStatus,
    Value<String?> alignmentAlgorithmVersion = const Value.absent(),
    Value<DateTime?> alignmentConfirmedAtUtc = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => VisionScanDraftRecord(
    id: id ?? this.id,
    status: status ?? this.status,
    originalImagePath: originalImagePath ?? this.originalImagePath,
    sha256: sha256 ?? this.sha256,
    width: width ?? this.width,
    height: height ?? this.height,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    targetProfileJson: targetProfileJson ?? this.targetProfileJson,
    projectileDiameterMm: projectileDiameterMm ?? this.projectileDiameterMm,
    qualityJson: qualityJson.present ? qualityJson.value : this.qualityJson,
    registrationJson: registrationJson.present
        ? registrationJson.value
        : this.registrationJson,
    candidatesJson: candidatesJson.present
        ? candidatesJson.value
        : this.candidatesJson,
    reviewJson: reviewJson.present ? reviewJson.value : this.reviewJson,
    engineVersion: engineVersion.present
        ? engineVersion.value
        : this.engineVersion,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
    alignmentMode: alignmentMode ?? this.alignmentMode,
    anchorsJson: anchorsJson.present ? anchorsJson.value : this.anchorsJson,
    reprojectionRmsMm: reprojectionRmsMm.present
        ? reprojectionRmsMm.value
        : this.reprojectionRmsMm,
    reprojectionMaxMm: reprojectionMaxMm.present
        ? reprojectionMaxMm.value
        : this.reprojectionMaxMm,
    planarityStatus: planarityStatus ?? this.planarityStatus,
    alignmentAlgorithmVersion: alignmentAlgorithmVersion.present
        ? alignmentAlgorithmVersion.value
        : this.alignmentAlgorithmVersion,
    alignmentConfirmedAtUtc: alignmentConfirmedAtUtc.present
        ? alignmentConfirmedAtUtc.value
        : this.alignmentConfirmedAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  VisionScanDraftRecord copyWithCompanion(VisionScanDraftsCompanion data) {
    return VisionScanDraftRecord(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      originalImagePath: data.originalImagePath.present
          ? data.originalImagePath.value
          : this.originalImagePath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      targetProfileJson: data.targetProfileJson.present
          ? data.targetProfileJson.value
          : this.targetProfileJson,
      projectileDiameterMm: data.projectileDiameterMm.present
          ? data.projectileDiameterMm.value
          : this.projectileDiameterMm,
      qualityJson: data.qualityJson.present
          ? data.qualityJson.value
          : this.qualityJson,
      registrationJson: data.registrationJson.present
          ? data.registrationJson.value
          : this.registrationJson,
      candidatesJson: data.candidatesJson.present
          ? data.candidatesJson.value
          : this.candidatesJson,
      reviewJson: data.reviewJson.present
          ? data.reviewJson.value
          : this.reviewJson,
      engineVersion: data.engineVersion.present
          ? data.engineVersion.value
          : this.engineVersion,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      rotationQuarterTurns: data.rotationQuarterTurns.present
          ? data.rotationQuarterTurns.value
          : this.rotationQuarterTurns,
      alignmentMode: data.alignmentMode.present
          ? data.alignmentMode.value
          : this.alignmentMode,
      anchorsJson: data.anchorsJson.present
          ? data.anchorsJson.value
          : this.anchorsJson,
      reprojectionRmsMm: data.reprojectionRmsMm.present
          ? data.reprojectionRmsMm.value
          : this.reprojectionRmsMm,
      reprojectionMaxMm: data.reprojectionMaxMm.present
          ? data.reprojectionMaxMm.value
          : this.reprojectionMaxMm,
      planarityStatus: data.planarityStatus.present
          ? data.planarityStatus.value
          : this.planarityStatus,
      alignmentAlgorithmVersion: data.alignmentAlgorithmVersion.present
          ? data.alignmentAlgorithmVersion.value
          : this.alignmentAlgorithmVersion,
      alignmentConfirmedAtUtc: data.alignmentConfirmedAtUtc.present
          ? data.alignmentConfirmedAtUtc.value
          : this.alignmentConfirmedAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisionScanDraftRecord(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('sha256: $sha256, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('targetProfileJson: $targetProfileJson, ')
          ..write('projectileDiameterMm: $projectileDiameterMm, ')
          ..write('qualityJson: $qualityJson, ')
          ..write('registrationJson: $registrationJson, ')
          ..write('candidatesJson: $candidatesJson, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('failureCode: $failureCode, ')
          ..write('rotationQuarterTurns: $rotationQuarterTurns, ')
          ..write('alignmentMode: $alignmentMode, ')
          ..write('anchorsJson: $anchorsJson, ')
          ..write('reprojectionRmsMm: $reprojectionRmsMm, ')
          ..write('reprojectionMaxMm: $reprojectionMaxMm, ')
          ..write('planarityStatus: $planarityStatus, ')
          ..write('alignmentAlgorithmVersion: $alignmentAlgorithmVersion, ')
          ..write('alignmentConfirmedAtUtc: $alignmentConfirmedAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    status,
    originalImagePath,
    sha256,
    width,
    height,
    sizeBytes,
    targetProfileJson,
    projectileDiameterMm,
    qualityJson,
    registrationJson,
    candidatesJson,
    reviewJson,
    engineVersion,
    failureCode,
    rotationQuarterTurns,
    alignmentMode,
    anchorsJson,
    reprojectionRmsMm,
    reprojectionMaxMm,
    planarityStatus,
    alignmentAlgorithmVersion,
    alignmentConfirmedAtUtc,
    createdAtUtc,
    updatedAtUtc,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisionScanDraftRecord &&
          other.id == this.id &&
          other.status == this.status &&
          other.originalImagePath == this.originalImagePath &&
          other.sha256 == this.sha256 &&
          other.width == this.width &&
          other.height == this.height &&
          other.sizeBytes == this.sizeBytes &&
          other.targetProfileJson == this.targetProfileJson &&
          other.projectileDiameterMm == this.projectileDiameterMm &&
          other.qualityJson == this.qualityJson &&
          other.registrationJson == this.registrationJson &&
          other.candidatesJson == this.candidatesJson &&
          other.reviewJson == this.reviewJson &&
          other.engineVersion == this.engineVersion &&
          other.failureCode == this.failureCode &&
          other.rotationQuarterTurns == this.rotationQuarterTurns &&
          other.alignmentMode == this.alignmentMode &&
          other.anchorsJson == this.anchorsJson &&
          other.reprojectionRmsMm == this.reprojectionRmsMm &&
          other.reprojectionMaxMm == this.reprojectionMaxMm &&
          other.planarityStatus == this.planarityStatus &&
          other.alignmentAlgorithmVersion == this.alignmentAlgorithmVersion &&
          other.alignmentConfirmedAtUtc == this.alignmentConfirmedAtUtc &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class VisionScanDraftsCompanion extends UpdateCompanion<VisionScanDraftRecord> {
  final Value<String> id;
  final Value<String> status;
  final Value<String> originalImagePath;
  final Value<String> sha256;
  final Value<int> width;
  final Value<int> height;
  final Value<int> sizeBytes;
  final Value<String> targetProfileJson;
  final Value<double> projectileDiameterMm;
  final Value<String?> qualityJson;
  final Value<String?> registrationJson;
  final Value<String?> candidatesJson;
  final Value<String?> reviewJson;
  final Value<String?> engineVersion;
  final Value<String?> failureCode;
  final Value<int> rotationQuarterTurns;
  final Value<String> alignmentMode;
  final Value<String?> anchorsJson;
  final Value<double?> reprojectionRmsMm;
  final Value<double?> reprojectionMaxMm;
  final Value<String> planarityStatus;
  final Value<String?> alignmentAlgorithmVersion;
  final Value<DateTime?> alignmentConfirmedAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const VisionScanDraftsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.originalImagePath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.targetProfileJson = const Value.absent(),
    this.projectileDiameterMm = const Value.absent(),
    this.qualityJson = const Value.absent(),
    this.registrationJson = const Value.absent(),
    this.candidatesJson = const Value.absent(),
    this.reviewJson = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.rotationQuarterTurns = const Value.absent(),
    this.alignmentMode = const Value.absent(),
    this.anchorsJson = const Value.absent(),
    this.reprojectionRmsMm = const Value.absent(),
    this.reprojectionMaxMm = const Value.absent(),
    this.planarityStatus = const Value.absent(),
    this.alignmentAlgorithmVersion = const Value.absent(),
    this.alignmentConfirmedAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisionScanDraftsCompanion.insert({
    required String id,
    required String status,
    required String originalImagePath,
    required String sha256,
    required int width,
    required int height,
    required int sizeBytes,
    required String targetProfileJson,
    required double projectileDiameterMm,
    this.qualityJson = const Value.absent(),
    this.registrationJson = const Value.absent(),
    this.candidatesJson = const Value.absent(),
    this.reviewJson = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.rotationQuarterTurns = const Value.absent(),
    this.alignmentMode = const Value.absent(),
    this.anchorsJson = const Value.absent(),
    this.reprojectionRmsMm = const Value.absent(),
    this.reprojectionMaxMm = const Value.absent(),
    this.planarityStatus = const Value.absent(),
    this.alignmentAlgorithmVersion = const Value.absent(),
    this.alignmentConfirmedAtUtc = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       originalImagePath = Value(originalImagePath),
       sha256 = Value(sha256),
       width = Value(width),
       height = Value(height),
       sizeBytes = Value(sizeBytes),
       targetProfileJson = Value(targetProfileJson),
       projectileDiameterMm = Value(projectileDiameterMm),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<VisionScanDraftRecord> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? originalImagePath,
    Expression<String>? sha256,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? sizeBytes,
    Expression<String>? targetProfileJson,
    Expression<double>? projectileDiameterMm,
    Expression<String>? qualityJson,
    Expression<String>? registrationJson,
    Expression<String>? candidatesJson,
    Expression<String>? reviewJson,
    Expression<String>? engineVersion,
    Expression<String>? failureCode,
    Expression<int>? rotationQuarterTurns,
    Expression<String>? alignmentMode,
    Expression<String>? anchorsJson,
    Expression<double>? reprojectionRmsMm,
    Expression<double>? reprojectionMaxMm,
    Expression<String>? planarityStatus,
    Expression<String>? alignmentAlgorithmVersion,
    Expression<DateTime>? alignmentConfirmedAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (originalImagePath != null) 'original_image_path': originalImagePath,
      if (sha256 != null) 'sha256': sha256,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (targetProfileJson != null) 'target_profile_json': targetProfileJson,
      if (projectileDiameterMm != null)
        'projectile_diameter_mm': projectileDiameterMm,
      if (qualityJson != null) 'quality_json': qualityJson,
      if (registrationJson != null) 'registration_json': registrationJson,
      if (candidatesJson != null) 'candidates_json': candidatesJson,
      if (reviewJson != null) 'review_json': reviewJson,
      if (engineVersion != null) 'engine_version': engineVersion,
      if (failureCode != null) 'failure_code': failureCode,
      if (rotationQuarterTurns != null)
        'rotation_quarter_turns': rotationQuarterTurns,
      if (alignmentMode != null) 'alignment_mode': alignmentMode,
      if (anchorsJson != null) 'anchors_json': anchorsJson,
      if (reprojectionRmsMm != null) 'reprojection_rms_mm': reprojectionRmsMm,
      if (reprojectionMaxMm != null) 'reprojection_max_mm': reprojectionMaxMm,
      if (planarityStatus != null) 'planarity_status': planarityStatus,
      if (alignmentAlgorithmVersion != null)
        'alignment_algorithm_version': alignmentAlgorithmVersion,
      if (alignmentConfirmedAtUtc != null)
        'alignment_confirmed_at_utc': alignmentConfirmedAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisionScanDraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String>? originalImagePath,
    Value<String>? sha256,
    Value<int>? width,
    Value<int>? height,
    Value<int>? sizeBytes,
    Value<String>? targetProfileJson,
    Value<double>? projectileDiameterMm,
    Value<String?>? qualityJson,
    Value<String?>? registrationJson,
    Value<String?>? candidatesJson,
    Value<String?>? reviewJson,
    Value<String?>? engineVersion,
    Value<String?>? failureCode,
    Value<int>? rotationQuarterTurns,
    Value<String>? alignmentMode,
    Value<String?>? anchorsJson,
    Value<double?>? reprojectionRmsMm,
    Value<double?>? reprojectionMaxMm,
    Value<String>? planarityStatus,
    Value<String?>? alignmentAlgorithmVersion,
    Value<DateTime?>? alignmentConfirmedAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return VisionScanDraftsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      sha256: sha256 ?? this.sha256,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      targetProfileJson: targetProfileJson ?? this.targetProfileJson,
      projectileDiameterMm: projectileDiameterMm ?? this.projectileDiameterMm,
      qualityJson: qualityJson ?? this.qualityJson,
      registrationJson: registrationJson ?? this.registrationJson,
      candidatesJson: candidatesJson ?? this.candidatesJson,
      reviewJson: reviewJson ?? this.reviewJson,
      engineVersion: engineVersion ?? this.engineVersion,
      failureCode: failureCode ?? this.failureCode,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      alignmentMode: alignmentMode ?? this.alignmentMode,
      anchorsJson: anchorsJson ?? this.anchorsJson,
      reprojectionRmsMm: reprojectionRmsMm ?? this.reprojectionRmsMm,
      reprojectionMaxMm: reprojectionMaxMm ?? this.reprojectionMaxMm,
      planarityStatus: planarityStatus ?? this.planarityStatus,
      alignmentAlgorithmVersion:
          alignmentAlgorithmVersion ?? this.alignmentAlgorithmVersion,
      alignmentConfirmedAtUtc:
          alignmentConfirmedAtUtc ?? this.alignmentConfirmedAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (originalImagePath.present) {
      map['original_image_path'] = Variable<String>(originalImagePath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (targetProfileJson.present) {
      map['target_profile_json'] = Variable<String>(targetProfileJson.value);
    }
    if (projectileDiameterMm.present) {
      map['projectile_diameter_mm'] = Variable<double>(
        projectileDiameterMm.value,
      );
    }
    if (qualityJson.present) {
      map['quality_json'] = Variable<String>(qualityJson.value);
    }
    if (registrationJson.present) {
      map['registration_json'] = Variable<String>(registrationJson.value);
    }
    if (candidatesJson.present) {
      map['candidates_json'] = Variable<String>(candidatesJson.value);
    }
    if (reviewJson.present) {
      map['review_json'] = Variable<String>(reviewJson.value);
    }
    if (engineVersion.present) {
      map['engine_version'] = Variable<String>(engineVersion.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (rotationQuarterTurns.present) {
      map['rotation_quarter_turns'] = Variable<int>(rotationQuarterTurns.value);
    }
    if (alignmentMode.present) {
      map['alignment_mode'] = Variable<String>(alignmentMode.value);
    }
    if (anchorsJson.present) {
      map['anchors_json'] = Variable<String>(anchorsJson.value);
    }
    if (reprojectionRmsMm.present) {
      map['reprojection_rms_mm'] = Variable<double>(reprojectionRmsMm.value);
    }
    if (reprojectionMaxMm.present) {
      map['reprojection_max_mm'] = Variable<double>(reprojectionMaxMm.value);
    }
    if (planarityStatus.present) {
      map['planarity_status'] = Variable<String>(planarityStatus.value);
    }
    if (alignmentAlgorithmVersion.present) {
      map['alignment_algorithm_version'] = Variable<String>(
        alignmentAlgorithmVersion.value,
      );
    }
    if (alignmentConfirmedAtUtc.present) {
      map['alignment_confirmed_at_utc'] = Variable<DateTime>(
        alignmentConfirmedAtUtc.value,
      );
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisionScanDraftsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('sha256: $sha256, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('targetProfileJson: $targetProfileJson, ')
          ..write('projectileDiameterMm: $projectileDiameterMm, ')
          ..write('qualityJson: $qualityJson, ')
          ..write('registrationJson: $registrationJson, ')
          ..write('candidatesJson: $candidatesJson, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('failureCode: $failureCode, ')
          ..write('rotationQuarterTurns: $rotationQuarterTurns, ')
          ..write('alignmentMode: $alignmentMode, ')
          ..write('anchorsJson: $anchorsJson, ')
          ..write('reprojectionRmsMm: $reprojectionRmsMm, ')
          ..write('reprojectionMaxMm: $reprojectionMaxMm, ')
          ..write('planarityStatus: $planarityStatus, ')
          ..write('alignmentAlgorithmVersion: $alignmentAlgorithmVersion, ')
          ..write('alignmentConfirmedAtUtc: $alignmentConfirmedAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisionAnalysesTable extends VisionAnalyses
    with TableInfo<$VisionAnalysesTable, VisionAnalysisRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisionAnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shooting_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES image_assets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _engineVersionMeta = const VerificationMeta(
    'engineVersion',
  );
  @override
  late final GeneratedColumn<String> engineVersion = GeneratedColumn<String>(
    'engine_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backendVersionMeta = const VerificationMeta(
    'backendVersion',
  );
  @override
  late final GeneratedColumn<String> backendVersion = GeneratedColumn<String>(
    'backend_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityJsonMeta = const VerificationMeta(
    'qualityJson',
  );
  @override
  late final GeneratedColumn<String> qualityJson = GeneratedColumn<String>(
    'quality_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registrationJsonMeta = const VerificationMeta(
    'registrationJson',
  );
  @override
  late final GeneratedColumn<String> registrationJson = GeneratedColumn<String>(
    'registration_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _candidatesJsonMeta = const VerificationMeta(
    'candidatesJson',
  );
  @override
  late final GeneratedColumn<String> candidatesJson = GeneratedColumn<String>(
    'candidates_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewJsonMeta = const VerificationMeta(
    'reviewJson',
  );
  @override
  late final GeneratedColumn<String> reviewJson = GeneratedColumn<String>(
    'review_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    imageId,
    engineVersion,
    backendVersion,
    modelVersion,
    qualityJson,
    registrationJson,
    candidatesJson,
    reviewJson,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vision_analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisionAnalysisRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_imageIdMeta);
    }
    if (data.containsKey('engine_version')) {
      context.handle(
        _engineVersionMeta,
        engineVersion.isAcceptableOrUnknown(
          data['engine_version']!,
          _engineVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_engineVersionMeta);
    }
    if (data.containsKey('backend_version')) {
      context.handle(
        _backendVersionMeta,
        backendVersion.isAcceptableOrUnknown(
          data['backend_version']!,
          _backendVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_backendVersionMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    }
    if (data.containsKey('quality_json')) {
      context.handle(
        _qualityJsonMeta,
        qualityJson.isAcceptableOrUnknown(
          data['quality_json']!,
          _qualityJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualityJsonMeta);
    }
    if (data.containsKey('registration_json')) {
      context.handle(
        _registrationJsonMeta,
        registrationJson.isAcceptableOrUnknown(
          data['registration_json']!,
          _registrationJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registrationJsonMeta);
    }
    if (data.containsKey('candidates_json')) {
      context.handle(
        _candidatesJsonMeta,
        candidatesJson.isAcceptableOrUnknown(
          data['candidates_json']!,
          _candidatesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_candidatesJsonMeta);
    }
    if (data.containsKey('review_json')) {
      context.handle(
        _reviewJsonMeta,
        reviewJson.isAcceptableOrUnknown(data['review_json']!, _reviewJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewJsonMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisionAnalysisRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisionAnalysisRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      )!,
      engineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_version'],
      )!,
      backendVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_version'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      ),
      qualityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_json'],
      )!,
      registrationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_json'],
      )!,
      candidatesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidates_json'],
      )!,
      reviewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_json'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $VisionAnalysesTable createAlias(String alias) {
    return $VisionAnalysesTable(attachedDatabase, alias);
  }
}

class VisionAnalysisRecord extends DataClass
    implements Insertable<VisionAnalysisRecord> {
  final String id;
  final String seriesId;
  final String imageId;
  final String engineVersion;
  final String backendVersion;
  final String? modelVersion;
  final String qualityJson;
  final String registrationJson;
  final String candidatesJson;
  final String reviewJson;
  final DateTime createdAtUtc;
  const VisionAnalysisRecord({
    required this.id,
    required this.seriesId,
    required this.imageId,
    required this.engineVersion,
    required this.backendVersion,
    this.modelVersion,
    required this.qualityJson,
    required this.registrationJson,
    required this.candidatesJson,
    required this.reviewJson,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['image_id'] = Variable<String>(imageId);
    map['engine_version'] = Variable<String>(engineVersion);
    map['backend_version'] = Variable<String>(backendVersion);
    if (!nullToAbsent || modelVersion != null) {
      map['model_version'] = Variable<String>(modelVersion);
    }
    map['quality_json'] = Variable<String>(qualityJson);
    map['registration_json'] = Variable<String>(registrationJson);
    map['candidates_json'] = Variable<String>(candidatesJson);
    map['review_json'] = Variable<String>(reviewJson);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  VisionAnalysesCompanion toCompanion(bool nullToAbsent) {
    return VisionAnalysesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      imageId: Value(imageId),
      engineVersion: Value(engineVersion),
      backendVersion: Value(backendVersion),
      modelVersion: modelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(modelVersion),
      qualityJson: Value(qualityJson),
      registrationJson: Value(registrationJson),
      candidatesJson: Value(candidatesJson),
      reviewJson: Value(reviewJson),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory VisionAnalysisRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisionAnalysisRecord(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      imageId: serializer.fromJson<String>(json['imageId']),
      engineVersion: serializer.fromJson<String>(json['engineVersion']),
      backendVersion: serializer.fromJson<String>(json['backendVersion']),
      modelVersion: serializer.fromJson<String?>(json['modelVersion']),
      qualityJson: serializer.fromJson<String>(json['qualityJson']),
      registrationJson: serializer.fromJson<String>(json['registrationJson']),
      candidatesJson: serializer.fromJson<String>(json['candidatesJson']),
      reviewJson: serializer.fromJson<String>(json['reviewJson']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'imageId': serializer.toJson<String>(imageId),
      'engineVersion': serializer.toJson<String>(engineVersion),
      'backendVersion': serializer.toJson<String>(backendVersion),
      'modelVersion': serializer.toJson<String?>(modelVersion),
      'qualityJson': serializer.toJson<String>(qualityJson),
      'registrationJson': serializer.toJson<String>(registrationJson),
      'candidatesJson': serializer.toJson<String>(candidatesJson),
      'reviewJson': serializer.toJson<String>(reviewJson),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  VisionAnalysisRecord copyWith({
    String? id,
    String? seriesId,
    String? imageId,
    String? engineVersion,
    String? backendVersion,
    Value<String?> modelVersion = const Value.absent(),
    String? qualityJson,
    String? registrationJson,
    String? candidatesJson,
    String? reviewJson,
    DateTime? createdAtUtc,
  }) => VisionAnalysisRecord(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    imageId: imageId ?? this.imageId,
    engineVersion: engineVersion ?? this.engineVersion,
    backendVersion: backendVersion ?? this.backendVersion,
    modelVersion: modelVersion.present ? modelVersion.value : this.modelVersion,
    qualityJson: qualityJson ?? this.qualityJson,
    registrationJson: registrationJson ?? this.registrationJson,
    candidatesJson: candidatesJson ?? this.candidatesJson,
    reviewJson: reviewJson ?? this.reviewJson,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  VisionAnalysisRecord copyWithCompanion(VisionAnalysesCompanion data) {
    return VisionAnalysisRecord(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
      engineVersion: data.engineVersion.present
          ? data.engineVersion.value
          : this.engineVersion,
      backendVersion: data.backendVersion.present
          ? data.backendVersion.value
          : this.backendVersion,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      qualityJson: data.qualityJson.present
          ? data.qualityJson.value
          : this.qualityJson,
      registrationJson: data.registrationJson.present
          ? data.registrationJson.value
          : this.registrationJson,
      candidatesJson: data.candidatesJson.present
          ? data.candidatesJson.value
          : this.candidatesJson,
      reviewJson: data.reviewJson.present
          ? data.reviewJson.value
          : this.reviewJson,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisionAnalysisRecord(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('imageId: $imageId, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('backendVersion: $backendVersion, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('qualityJson: $qualityJson, ')
          ..write('registrationJson: $registrationJson, ')
          ..write('candidatesJson: $candidatesJson, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    imageId,
    engineVersion,
    backendVersion,
    modelVersion,
    qualityJson,
    registrationJson,
    candidatesJson,
    reviewJson,
    createdAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisionAnalysisRecord &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.imageId == this.imageId &&
          other.engineVersion == this.engineVersion &&
          other.backendVersion == this.backendVersion &&
          other.modelVersion == this.modelVersion &&
          other.qualityJson == this.qualityJson &&
          other.registrationJson == this.registrationJson &&
          other.candidatesJson == this.candidatesJson &&
          other.reviewJson == this.reviewJson &&
          other.createdAtUtc == this.createdAtUtc);
}

class VisionAnalysesCompanion extends UpdateCompanion<VisionAnalysisRecord> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<String> imageId;
  final Value<String> engineVersion;
  final Value<String> backendVersion;
  final Value<String?> modelVersion;
  final Value<String> qualityJson;
  final Value<String> registrationJson;
  final Value<String> candidatesJson;
  final Value<String> reviewJson;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const VisionAnalysesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.imageId = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.backendVersion = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.qualityJson = const Value.absent(),
    this.registrationJson = const Value.absent(),
    this.candidatesJson = const Value.absent(),
    this.reviewJson = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisionAnalysesCompanion.insert({
    required String id,
    required String seriesId,
    required String imageId,
    required String engineVersion,
    required String backendVersion,
    this.modelVersion = const Value.absent(),
    required String qualityJson,
    required String registrationJson,
    required String candidatesJson,
    required String reviewJson,
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       imageId = Value(imageId),
       engineVersion = Value(engineVersion),
       backendVersion = Value(backendVersion),
       qualityJson = Value(qualityJson),
       registrationJson = Value(registrationJson),
       candidatesJson = Value(candidatesJson),
       reviewJson = Value(reviewJson),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<VisionAnalysisRecord> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<String>? imageId,
    Expression<String>? engineVersion,
    Expression<String>? backendVersion,
    Expression<String>? modelVersion,
    Expression<String>? qualityJson,
    Expression<String>? registrationJson,
    Expression<String>? candidatesJson,
    Expression<String>? reviewJson,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (imageId != null) 'image_id': imageId,
      if (engineVersion != null) 'engine_version': engineVersion,
      if (backendVersion != null) 'backend_version': backendVersion,
      if (modelVersion != null) 'model_version': modelVersion,
      if (qualityJson != null) 'quality_json': qualityJson,
      if (registrationJson != null) 'registration_json': registrationJson,
      if (candidatesJson != null) 'candidates_json': candidatesJson,
      if (reviewJson != null) 'review_json': reviewJson,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisionAnalysesCompanion copyWith({
    Value<String>? id,
    Value<String>? seriesId,
    Value<String>? imageId,
    Value<String>? engineVersion,
    Value<String>? backendVersion,
    Value<String?>? modelVersion,
    Value<String>? qualityJson,
    Value<String>? registrationJson,
    Value<String>? candidatesJson,
    Value<String>? reviewJson,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return VisionAnalysesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      imageId: imageId ?? this.imageId,
      engineVersion: engineVersion ?? this.engineVersion,
      backendVersion: backendVersion ?? this.backendVersion,
      modelVersion: modelVersion ?? this.modelVersion,
      qualityJson: qualityJson ?? this.qualityJson,
      registrationJson: registrationJson ?? this.registrationJson,
      candidatesJson: candidatesJson ?? this.candidatesJson,
      reviewJson: reviewJson ?? this.reviewJson,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (engineVersion.present) {
      map['engine_version'] = Variable<String>(engineVersion.value);
    }
    if (backendVersion.present) {
      map['backend_version'] = Variable<String>(backendVersion.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (qualityJson.present) {
      map['quality_json'] = Variable<String>(qualityJson.value);
    }
    if (registrationJson.present) {
      map['registration_json'] = Variable<String>(registrationJson.value);
    }
    if (candidatesJson.present) {
      map['candidates_json'] = Variable<String>(candidatesJson.value);
    }
    if (reviewJson.present) {
      map['review_json'] = Variable<String>(reviewJson.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisionAnalysesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('imageId: $imageId, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('backendVersion: $backendVersion, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('qualityJson: $qualityJson, ')
          ..write('registrationJson: $registrationJson, ')
          ..write('candidatesJson: $candidatesJson, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShotImpactsTable extends ShotImpacts
    with TableInfo<$ShotImpactsTable, ImpactRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotImpactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shooting_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _xMmMeta = const VerificationMeta('xMm');
  @override
  late final GeneratedColumn<double> xMm = GeneratedColumn<double>(
    'x_mm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMmMeta = const VerificationMeta('yMm');
  @override
  late final GeneratedColumn<double> yMm = GeneratedColumn<double>(
    'y_mm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceImageIdMeta = const VerificationMeta(
    'sourceImageId',
  );
  @override
  late final GeneratedColumn<String> sourceImageId = GeneratedColumn<String>(
    'source_image_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES image_assets (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _imageXNormalizedMeta = const VerificationMeta(
    'imageXNormalized',
  );
  @override
  late final GeneratedColumn<double> imageXNormalized = GeneratedColumn<double>(
    'image_x_normalized',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageYNormalizedMeta = const VerificationMeta(
    'imageYNormalized',
  );
  @override
  late final GeneratedColumn<double> imageYNormalized = GeneratedColumn<double>(
    'image_y_normalized',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _multiplicityMeta = const VerificationMeta(
    'multiplicity',
  );
  @override
  late final GeneratedColumn<int> multiplicity = GeneratedColumn<int>(
    'multiplicity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isMissMeta = const VerificationMeta('isMiss');
  @override
  late final GeneratedColumn<bool> isMiss = GeneratedColumn<bool>(
    'is_miss',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_miss" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPositionUncertainMeta =
      const VerificationMeta('isPositionUncertain');
  @override
  late final GeneratedColumn<bool> isPositionUncertain = GeneratedColumn<bool>(
    'is_position_uncertain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_position_uncertain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetBullIdMeta = const VerificationMeta(
    'targetBullId',
  );
  @override
  late final GeneratedColumn<String> targetBullId = GeneratedColumn<String>(
    'target_bull_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreValueMeta = const VerificationMeta(
    'scoreValue',
  );
  @override
  late final GeneratedColumn<int> scoreValue = GeneratedColumn<int>(
    'score_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawScoreValueMeta = const VerificationMeta(
    'rawScoreValue',
  );
  @override
  late final GeneratedColumn<int> rawScoreValue = GeneratedColumn<int>(
    'raw_score_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreDispositionMeta = const VerificationMeta(
    'scoreDisposition',
  );
  @override
  late final GeneratedColumn<String> scoreDisposition = GeneratedColumn<String>(
    'score_disposition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('counted'),
  );
  static const VerificationMeta _isInnerTenMeta = const VerificationMeta(
    'isInnerTen',
  );
  @override
  late final GeneratedColumn<bool> isInnerTen = GeneratedColumn<bool>(
    'is_inner_ten',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_inner_ten" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBoundaryUncertainMeta =
      const VerificationMeta('isBoundaryUncertain');
  @override
  late final GeneratedColumn<bool> isBoundaryUncertain = GeneratedColumn<bool>(
    'is_boundary_uncertain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_boundary_uncertain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _placementMethodMeta = const VerificationMeta(
    'placementMethod',
  );
  @override
  late final GeneratedColumn<String> placementMethod = GeneratedColumn<String>(
    'placement_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _visionAnalysisIdMeta = const VerificationMeta(
    'visionAnalysisId',
  );
  @override
  late final GeneratedColumn<String> visionAnalysisId = GeneratedColumn<String>(
    'vision_analysis_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vision_analyses (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _positionalUncertaintyMmMeta =
      const VerificationMeta('positionalUncertaintyMm');
  @override
  late final GeneratedColumn<double> positionalUncertaintyMm =
      GeneratedColumn<double>(
        'positional_uncertainty_mm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    xMm,
    yMm,
    sourceImageId,
    imageXNormalized,
    imageYNormalized,
    multiplicity,
    isMiss,
    isPositionUncertain,
    targetBullId,
    scoreValue,
    rawScoreValue,
    scoreDisposition,
    isInnerTen,
    isBoundaryUncertain,
    placementMethod,
    visionAnalysisId,
    positionalUncertaintyMm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shot_impacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImpactRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('x_mm')) {
      context.handle(
        _xMmMeta,
        xMm.isAcceptableOrUnknown(data['x_mm']!, _xMmMeta),
      );
    } else if (isInserting) {
      context.missing(_xMmMeta);
    }
    if (data.containsKey('y_mm')) {
      context.handle(
        _yMmMeta,
        yMm.isAcceptableOrUnknown(data['y_mm']!, _yMmMeta),
      );
    } else if (isInserting) {
      context.missing(_yMmMeta);
    }
    if (data.containsKey('source_image_id')) {
      context.handle(
        _sourceImageIdMeta,
        sourceImageId.isAcceptableOrUnknown(
          data['source_image_id']!,
          _sourceImageIdMeta,
        ),
      );
    }
    if (data.containsKey('image_x_normalized')) {
      context.handle(
        _imageXNormalizedMeta,
        imageXNormalized.isAcceptableOrUnknown(
          data['image_x_normalized']!,
          _imageXNormalizedMeta,
        ),
      );
    }
    if (data.containsKey('image_y_normalized')) {
      context.handle(
        _imageYNormalizedMeta,
        imageYNormalized.isAcceptableOrUnknown(
          data['image_y_normalized']!,
          _imageYNormalizedMeta,
        ),
      );
    }
    if (data.containsKey('multiplicity')) {
      context.handle(
        _multiplicityMeta,
        multiplicity.isAcceptableOrUnknown(
          data['multiplicity']!,
          _multiplicityMeta,
        ),
      );
    }
    if (data.containsKey('is_miss')) {
      context.handle(
        _isMissMeta,
        isMiss.isAcceptableOrUnknown(data['is_miss']!, _isMissMeta),
      );
    }
    if (data.containsKey('is_position_uncertain')) {
      context.handle(
        _isPositionUncertainMeta,
        isPositionUncertain.isAcceptableOrUnknown(
          data['is_position_uncertain']!,
          _isPositionUncertainMeta,
        ),
      );
    }
    if (data.containsKey('target_bull_id')) {
      context.handle(
        _targetBullIdMeta,
        targetBullId.isAcceptableOrUnknown(
          data['target_bull_id']!,
          _targetBullIdMeta,
        ),
      );
    }
    if (data.containsKey('score_value')) {
      context.handle(
        _scoreValueMeta,
        scoreValue.isAcceptableOrUnknown(data['score_value']!, _scoreValueMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreValueMeta);
    }
    if (data.containsKey('raw_score_value')) {
      context.handle(
        _rawScoreValueMeta,
        rawScoreValue.isAcceptableOrUnknown(
          data['raw_score_value']!,
          _rawScoreValueMeta,
        ),
      );
    }
    if (data.containsKey('score_disposition')) {
      context.handle(
        _scoreDispositionMeta,
        scoreDisposition.isAcceptableOrUnknown(
          data['score_disposition']!,
          _scoreDispositionMeta,
        ),
      );
    }
    if (data.containsKey('is_inner_ten')) {
      context.handle(
        _isInnerTenMeta,
        isInnerTen.isAcceptableOrUnknown(
          data['is_inner_ten']!,
          _isInnerTenMeta,
        ),
      );
    }
    if (data.containsKey('is_boundary_uncertain')) {
      context.handle(
        _isBoundaryUncertainMeta,
        isBoundaryUncertain.isAcceptableOrUnknown(
          data['is_boundary_uncertain']!,
          _isBoundaryUncertainMeta,
        ),
      );
    }
    if (data.containsKey('placement_method')) {
      context.handle(
        _placementMethodMeta,
        placementMethod.isAcceptableOrUnknown(
          data['placement_method']!,
          _placementMethodMeta,
        ),
      );
    }
    if (data.containsKey('vision_analysis_id')) {
      context.handle(
        _visionAnalysisIdMeta,
        visionAnalysisId.isAcceptableOrUnknown(
          data['vision_analysis_id']!,
          _visionAnalysisIdMeta,
        ),
      );
    }
    if (data.containsKey('positional_uncertainty_mm')) {
      context.handle(
        _positionalUncertaintyMmMeta,
        positionalUncertaintyMm.isAcceptableOrUnknown(
          data['positional_uncertainty_mm']!,
          _positionalUncertaintyMmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImpactRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImpactRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      xMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_mm'],
      )!,
      yMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_mm'],
      )!,
      sourceImageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_image_id'],
      ),
      imageXNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}image_x_normalized'],
      ),
      imageYNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}image_y_normalized'],
      ),
      multiplicity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}multiplicity'],
      )!,
      isMiss: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_miss'],
      )!,
      isPositionUncertain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_position_uncertain'],
      )!,
      targetBullId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_bull_id'],
      ),
      scoreValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_value'],
      )!,
      rawScoreValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_score_value'],
      )!,
      scoreDisposition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_disposition'],
      )!,
      isInnerTen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_inner_ten'],
      )!,
      isBoundaryUncertain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_boundary_uncertain'],
      )!,
      placementMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}placement_method'],
      )!,
      visionAnalysisId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_analysis_id'],
      ),
      positionalUncertaintyMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}positional_uncertainty_mm'],
      ),
    );
  }

  @override
  $ShotImpactsTable createAlias(String alias) {
    return $ShotImpactsTable(attachedDatabase, alias);
  }
}

class ImpactRecord extends DataClass implements Insertable<ImpactRecord> {
  final String id;
  final String seriesId;
  final double xMm;
  final double yMm;
  final String? sourceImageId;
  final double? imageXNormalized;
  final double? imageYNormalized;
  final int multiplicity;
  final bool isMiss;
  final bool isPositionUncertain;
  final String? targetBullId;
  final int scoreValue;
  final int rawScoreValue;
  final String scoreDisposition;
  final bool isInnerTen;
  final bool isBoundaryUncertain;
  final String placementMethod;
  final String? visionAnalysisId;
  final double? positionalUncertaintyMm;
  const ImpactRecord({
    required this.id,
    required this.seriesId,
    required this.xMm,
    required this.yMm,
    this.sourceImageId,
    this.imageXNormalized,
    this.imageYNormalized,
    required this.multiplicity,
    required this.isMiss,
    required this.isPositionUncertain,
    this.targetBullId,
    required this.scoreValue,
    required this.rawScoreValue,
    required this.scoreDisposition,
    required this.isInnerTen,
    required this.isBoundaryUncertain,
    required this.placementMethod,
    this.visionAnalysisId,
    this.positionalUncertaintyMm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['x_mm'] = Variable<double>(xMm);
    map['y_mm'] = Variable<double>(yMm);
    if (!nullToAbsent || sourceImageId != null) {
      map['source_image_id'] = Variable<String>(sourceImageId);
    }
    if (!nullToAbsent || imageXNormalized != null) {
      map['image_x_normalized'] = Variable<double>(imageXNormalized);
    }
    if (!nullToAbsent || imageYNormalized != null) {
      map['image_y_normalized'] = Variable<double>(imageYNormalized);
    }
    map['multiplicity'] = Variable<int>(multiplicity);
    map['is_miss'] = Variable<bool>(isMiss);
    map['is_position_uncertain'] = Variable<bool>(isPositionUncertain);
    if (!nullToAbsent || targetBullId != null) {
      map['target_bull_id'] = Variable<String>(targetBullId);
    }
    map['score_value'] = Variable<int>(scoreValue);
    map['raw_score_value'] = Variable<int>(rawScoreValue);
    map['score_disposition'] = Variable<String>(scoreDisposition);
    map['is_inner_ten'] = Variable<bool>(isInnerTen);
    map['is_boundary_uncertain'] = Variable<bool>(isBoundaryUncertain);
    map['placement_method'] = Variable<String>(placementMethod);
    if (!nullToAbsent || visionAnalysisId != null) {
      map['vision_analysis_id'] = Variable<String>(visionAnalysisId);
    }
    if (!nullToAbsent || positionalUncertaintyMm != null) {
      map['positional_uncertainty_mm'] = Variable<double>(
        positionalUncertaintyMm,
      );
    }
    return map;
  }

  ShotImpactsCompanion toCompanion(bool nullToAbsent) {
    return ShotImpactsCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      xMm: Value(xMm),
      yMm: Value(yMm),
      sourceImageId: sourceImageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceImageId),
      imageXNormalized: imageXNormalized == null && nullToAbsent
          ? const Value.absent()
          : Value(imageXNormalized),
      imageYNormalized: imageYNormalized == null && nullToAbsent
          ? const Value.absent()
          : Value(imageYNormalized),
      multiplicity: Value(multiplicity),
      isMiss: Value(isMiss),
      isPositionUncertain: Value(isPositionUncertain),
      targetBullId: targetBullId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetBullId),
      scoreValue: Value(scoreValue),
      rawScoreValue: Value(rawScoreValue),
      scoreDisposition: Value(scoreDisposition),
      isInnerTen: Value(isInnerTen),
      isBoundaryUncertain: Value(isBoundaryUncertain),
      placementMethod: Value(placementMethod),
      visionAnalysisId: visionAnalysisId == null && nullToAbsent
          ? const Value.absent()
          : Value(visionAnalysisId),
      positionalUncertaintyMm: positionalUncertaintyMm == null && nullToAbsent
          ? const Value.absent()
          : Value(positionalUncertaintyMm),
    );
  }

  factory ImpactRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImpactRecord(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      xMm: serializer.fromJson<double>(json['xMm']),
      yMm: serializer.fromJson<double>(json['yMm']),
      sourceImageId: serializer.fromJson<String?>(json['sourceImageId']),
      imageXNormalized: serializer.fromJson<double?>(json['imageXNormalized']),
      imageYNormalized: serializer.fromJson<double?>(json['imageYNormalized']),
      multiplicity: serializer.fromJson<int>(json['multiplicity']),
      isMiss: serializer.fromJson<bool>(json['isMiss']),
      isPositionUncertain: serializer.fromJson<bool>(
        json['isPositionUncertain'],
      ),
      targetBullId: serializer.fromJson<String?>(json['targetBullId']),
      scoreValue: serializer.fromJson<int>(json['scoreValue']),
      rawScoreValue: serializer.fromJson<int>(json['rawScoreValue']),
      scoreDisposition: serializer.fromJson<String>(json['scoreDisposition']),
      isInnerTen: serializer.fromJson<bool>(json['isInnerTen']),
      isBoundaryUncertain: serializer.fromJson<bool>(
        json['isBoundaryUncertain'],
      ),
      placementMethod: serializer.fromJson<String>(json['placementMethod']),
      visionAnalysisId: serializer.fromJson<String?>(json['visionAnalysisId']),
      positionalUncertaintyMm: serializer.fromJson<double?>(
        json['positionalUncertaintyMm'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'xMm': serializer.toJson<double>(xMm),
      'yMm': serializer.toJson<double>(yMm),
      'sourceImageId': serializer.toJson<String?>(sourceImageId),
      'imageXNormalized': serializer.toJson<double?>(imageXNormalized),
      'imageYNormalized': serializer.toJson<double?>(imageYNormalized),
      'multiplicity': serializer.toJson<int>(multiplicity),
      'isMiss': serializer.toJson<bool>(isMiss),
      'isPositionUncertain': serializer.toJson<bool>(isPositionUncertain),
      'targetBullId': serializer.toJson<String?>(targetBullId),
      'scoreValue': serializer.toJson<int>(scoreValue),
      'rawScoreValue': serializer.toJson<int>(rawScoreValue),
      'scoreDisposition': serializer.toJson<String>(scoreDisposition),
      'isInnerTen': serializer.toJson<bool>(isInnerTen),
      'isBoundaryUncertain': serializer.toJson<bool>(isBoundaryUncertain),
      'placementMethod': serializer.toJson<String>(placementMethod),
      'visionAnalysisId': serializer.toJson<String?>(visionAnalysisId),
      'positionalUncertaintyMm': serializer.toJson<double?>(
        positionalUncertaintyMm,
      ),
    };
  }

  ImpactRecord copyWith({
    String? id,
    String? seriesId,
    double? xMm,
    double? yMm,
    Value<String?> sourceImageId = const Value.absent(),
    Value<double?> imageXNormalized = const Value.absent(),
    Value<double?> imageYNormalized = const Value.absent(),
    int? multiplicity,
    bool? isMiss,
    bool? isPositionUncertain,
    Value<String?> targetBullId = const Value.absent(),
    int? scoreValue,
    int? rawScoreValue,
    String? scoreDisposition,
    bool? isInnerTen,
    bool? isBoundaryUncertain,
    String? placementMethod,
    Value<String?> visionAnalysisId = const Value.absent(),
    Value<double?> positionalUncertaintyMm = const Value.absent(),
  }) => ImpactRecord(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    xMm: xMm ?? this.xMm,
    yMm: yMm ?? this.yMm,
    sourceImageId: sourceImageId.present
        ? sourceImageId.value
        : this.sourceImageId,
    imageXNormalized: imageXNormalized.present
        ? imageXNormalized.value
        : this.imageXNormalized,
    imageYNormalized: imageYNormalized.present
        ? imageYNormalized.value
        : this.imageYNormalized,
    multiplicity: multiplicity ?? this.multiplicity,
    isMiss: isMiss ?? this.isMiss,
    isPositionUncertain: isPositionUncertain ?? this.isPositionUncertain,
    targetBullId: targetBullId.present ? targetBullId.value : this.targetBullId,
    scoreValue: scoreValue ?? this.scoreValue,
    rawScoreValue: rawScoreValue ?? this.rawScoreValue,
    scoreDisposition: scoreDisposition ?? this.scoreDisposition,
    isInnerTen: isInnerTen ?? this.isInnerTen,
    isBoundaryUncertain: isBoundaryUncertain ?? this.isBoundaryUncertain,
    placementMethod: placementMethod ?? this.placementMethod,
    visionAnalysisId: visionAnalysisId.present
        ? visionAnalysisId.value
        : this.visionAnalysisId,
    positionalUncertaintyMm: positionalUncertaintyMm.present
        ? positionalUncertaintyMm.value
        : this.positionalUncertaintyMm,
  );
  ImpactRecord copyWithCompanion(ShotImpactsCompanion data) {
    return ImpactRecord(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      xMm: data.xMm.present ? data.xMm.value : this.xMm,
      yMm: data.yMm.present ? data.yMm.value : this.yMm,
      sourceImageId: data.sourceImageId.present
          ? data.sourceImageId.value
          : this.sourceImageId,
      imageXNormalized: data.imageXNormalized.present
          ? data.imageXNormalized.value
          : this.imageXNormalized,
      imageYNormalized: data.imageYNormalized.present
          ? data.imageYNormalized.value
          : this.imageYNormalized,
      multiplicity: data.multiplicity.present
          ? data.multiplicity.value
          : this.multiplicity,
      isMiss: data.isMiss.present ? data.isMiss.value : this.isMiss,
      isPositionUncertain: data.isPositionUncertain.present
          ? data.isPositionUncertain.value
          : this.isPositionUncertain,
      targetBullId: data.targetBullId.present
          ? data.targetBullId.value
          : this.targetBullId,
      scoreValue: data.scoreValue.present
          ? data.scoreValue.value
          : this.scoreValue,
      rawScoreValue: data.rawScoreValue.present
          ? data.rawScoreValue.value
          : this.rawScoreValue,
      scoreDisposition: data.scoreDisposition.present
          ? data.scoreDisposition.value
          : this.scoreDisposition,
      isInnerTen: data.isInnerTen.present
          ? data.isInnerTen.value
          : this.isInnerTen,
      isBoundaryUncertain: data.isBoundaryUncertain.present
          ? data.isBoundaryUncertain.value
          : this.isBoundaryUncertain,
      placementMethod: data.placementMethod.present
          ? data.placementMethod.value
          : this.placementMethod,
      visionAnalysisId: data.visionAnalysisId.present
          ? data.visionAnalysisId.value
          : this.visionAnalysisId,
      positionalUncertaintyMm: data.positionalUncertaintyMm.present
          ? data.positionalUncertaintyMm.value
          : this.positionalUncertaintyMm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImpactRecord(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('xMm: $xMm, ')
          ..write('yMm: $yMm, ')
          ..write('sourceImageId: $sourceImageId, ')
          ..write('imageXNormalized: $imageXNormalized, ')
          ..write('imageYNormalized: $imageYNormalized, ')
          ..write('multiplicity: $multiplicity, ')
          ..write('isMiss: $isMiss, ')
          ..write('isPositionUncertain: $isPositionUncertain, ')
          ..write('targetBullId: $targetBullId, ')
          ..write('scoreValue: $scoreValue, ')
          ..write('rawScoreValue: $rawScoreValue, ')
          ..write('scoreDisposition: $scoreDisposition, ')
          ..write('isInnerTen: $isInnerTen, ')
          ..write('isBoundaryUncertain: $isBoundaryUncertain, ')
          ..write('placementMethod: $placementMethod, ')
          ..write('visionAnalysisId: $visionAnalysisId, ')
          ..write('positionalUncertaintyMm: $positionalUncertaintyMm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    xMm,
    yMm,
    sourceImageId,
    imageXNormalized,
    imageYNormalized,
    multiplicity,
    isMiss,
    isPositionUncertain,
    targetBullId,
    scoreValue,
    rawScoreValue,
    scoreDisposition,
    isInnerTen,
    isBoundaryUncertain,
    placementMethod,
    visionAnalysisId,
    positionalUncertaintyMm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImpactRecord &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.xMm == this.xMm &&
          other.yMm == this.yMm &&
          other.sourceImageId == this.sourceImageId &&
          other.imageXNormalized == this.imageXNormalized &&
          other.imageYNormalized == this.imageYNormalized &&
          other.multiplicity == this.multiplicity &&
          other.isMiss == this.isMiss &&
          other.isPositionUncertain == this.isPositionUncertain &&
          other.targetBullId == this.targetBullId &&
          other.scoreValue == this.scoreValue &&
          other.rawScoreValue == this.rawScoreValue &&
          other.scoreDisposition == this.scoreDisposition &&
          other.isInnerTen == this.isInnerTen &&
          other.isBoundaryUncertain == this.isBoundaryUncertain &&
          other.placementMethod == this.placementMethod &&
          other.visionAnalysisId == this.visionAnalysisId &&
          other.positionalUncertaintyMm == this.positionalUncertaintyMm);
}

class ShotImpactsCompanion extends UpdateCompanion<ImpactRecord> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<double> xMm;
  final Value<double> yMm;
  final Value<String?> sourceImageId;
  final Value<double?> imageXNormalized;
  final Value<double?> imageYNormalized;
  final Value<int> multiplicity;
  final Value<bool> isMiss;
  final Value<bool> isPositionUncertain;
  final Value<String?> targetBullId;
  final Value<int> scoreValue;
  final Value<int> rawScoreValue;
  final Value<String> scoreDisposition;
  final Value<bool> isInnerTen;
  final Value<bool> isBoundaryUncertain;
  final Value<String> placementMethod;
  final Value<String?> visionAnalysisId;
  final Value<double?> positionalUncertaintyMm;
  final Value<int> rowid;
  const ShotImpactsCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.xMm = const Value.absent(),
    this.yMm = const Value.absent(),
    this.sourceImageId = const Value.absent(),
    this.imageXNormalized = const Value.absent(),
    this.imageYNormalized = const Value.absent(),
    this.multiplicity = const Value.absent(),
    this.isMiss = const Value.absent(),
    this.isPositionUncertain = const Value.absent(),
    this.targetBullId = const Value.absent(),
    this.scoreValue = const Value.absent(),
    this.rawScoreValue = const Value.absent(),
    this.scoreDisposition = const Value.absent(),
    this.isInnerTen = const Value.absent(),
    this.isBoundaryUncertain = const Value.absent(),
    this.placementMethod = const Value.absent(),
    this.visionAnalysisId = const Value.absent(),
    this.positionalUncertaintyMm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShotImpactsCompanion.insert({
    required String id,
    required String seriesId,
    required double xMm,
    required double yMm,
    this.sourceImageId = const Value.absent(),
    this.imageXNormalized = const Value.absent(),
    this.imageYNormalized = const Value.absent(),
    this.multiplicity = const Value.absent(),
    this.isMiss = const Value.absent(),
    this.isPositionUncertain = const Value.absent(),
    this.targetBullId = const Value.absent(),
    required int scoreValue,
    this.rawScoreValue = const Value.absent(),
    this.scoreDisposition = const Value.absent(),
    this.isInnerTen = const Value.absent(),
    this.isBoundaryUncertain = const Value.absent(),
    this.placementMethod = const Value.absent(),
    this.visionAnalysisId = const Value.absent(),
    this.positionalUncertaintyMm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       xMm = Value(xMm),
       yMm = Value(yMm),
       scoreValue = Value(scoreValue);
  static Insertable<ImpactRecord> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<double>? xMm,
    Expression<double>? yMm,
    Expression<String>? sourceImageId,
    Expression<double>? imageXNormalized,
    Expression<double>? imageYNormalized,
    Expression<int>? multiplicity,
    Expression<bool>? isMiss,
    Expression<bool>? isPositionUncertain,
    Expression<String>? targetBullId,
    Expression<int>? scoreValue,
    Expression<int>? rawScoreValue,
    Expression<String>? scoreDisposition,
    Expression<bool>? isInnerTen,
    Expression<bool>? isBoundaryUncertain,
    Expression<String>? placementMethod,
    Expression<String>? visionAnalysisId,
    Expression<double>? positionalUncertaintyMm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (xMm != null) 'x_mm': xMm,
      if (yMm != null) 'y_mm': yMm,
      if (sourceImageId != null) 'source_image_id': sourceImageId,
      if (imageXNormalized != null) 'image_x_normalized': imageXNormalized,
      if (imageYNormalized != null) 'image_y_normalized': imageYNormalized,
      if (multiplicity != null) 'multiplicity': multiplicity,
      if (isMiss != null) 'is_miss': isMiss,
      if (isPositionUncertain != null)
        'is_position_uncertain': isPositionUncertain,
      if (targetBullId != null) 'target_bull_id': targetBullId,
      if (scoreValue != null) 'score_value': scoreValue,
      if (rawScoreValue != null) 'raw_score_value': rawScoreValue,
      if (scoreDisposition != null) 'score_disposition': scoreDisposition,
      if (isInnerTen != null) 'is_inner_ten': isInnerTen,
      if (isBoundaryUncertain != null)
        'is_boundary_uncertain': isBoundaryUncertain,
      if (placementMethod != null) 'placement_method': placementMethod,
      if (visionAnalysisId != null) 'vision_analysis_id': visionAnalysisId,
      if (positionalUncertaintyMm != null)
        'positional_uncertainty_mm': positionalUncertaintyMm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShotImpactsCompanion copyWith({
    Value<String>? id,
    Value<String>? seriesId,
    Value<double>? xMm,
    Value<double>? yMm,
    Value<String?>? sourceImageId,
    Value<double?>? imageXNormalized,
    Value<double?>? imageYNormalized,
    Value<int>? multiplicity,
    Value<bool>? isMiss,
    Value<bool>? isPositionUncertain,
    Value<String?>? targetBullId,
    Value<int>? scoreValue,
    Value<int>? rawScoreValue,
    Value<String>? scoreDisposition,
    Value<bool>? isInnerTen,
    Value<bool>? isBoundaryUncertain,
    Value<String>? placementMethod,
    Value<String?>? visionAnalysisId,
    Value<double?>? positionalUncertaintyMm,
    Value<int>? rowid,
  }) {
    return ShotImpactsCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      imageXNormalized: imageXNormalized ?? this.imageXNormalized,
      imageYNormalized: imageYNormalized ?? this.imageYNormalized,
      multiplicity: multiplicity ?? this.multiplicity,
      isMiss: isMiss ?? this.isMiss,
      isPositionUncertain: isPositionUncertain ?? this.isPositionUncertain,
      targetBullId: targetBullId ?? this.targetBullId,
      scoreValue: scoreValue ?? this.scoreValue,
      rawScoreValue: rawScoreValue ?? this.rawScoreValue,
      scoreDisposition: scoreDisposition ?? this.scoreDisposition,
      isInnerTen: isInnerTen ?? this.isInnerTen,
      isBoundaryUncertain: isBoundaryUncertain ?? this.isBoundaryUncertain,
      placementMethod: placementMethod ?? this.placementMethod,
      visionAnalysisId: visionAnalysisId ?? this.visionAnalysisId,
      positionalUncertaintyMm:
          positionalUncertaintyMm ?? this.positionalUncertaintyMm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (xMm.present) {
      map['x_mm'] = Variable<double>(xMm.value);
    }
    if (yMm.present) {
      map['y_mm'] = Variable<double>(yMm.value);
    }
    if (sourceImageId.present) {
      map['source_image_id'] = Variable<String>(sourceImageId.value);
    }
    if (imageXNormalized.present) {
      map['image_x_normalized'] = Variable<double>(imageXNormalized.value);
    }
    if (imageYNormalized.present) {
      map['image_y_normalized'] = Variable<double>(imageYNormalized.value);
    }
    if (multiplicity.present) {
      map['multiplicity'] = Variable<int>(multiplicity.value);
    }
    if (isMiss.present) {
      map['is_miss'] = Variable<bool>(isMiss.value);
    }
    if (isPositionUncertain.present) {
      map['is_position_uncertain'] = Variable<bool>(isPositionUncertain.value);
    }
    if (targetBullId.present) {
      map['target_bull_id'] = Variable<String>(targetBullId.value);
    }
    if (scoreValue.present) {
      map['score_value'] = Variable<int>(scoreValue.value);
    }
    if (rawScoreValue.present) {
      map['raw_score_value'] = Variable<int>(rawScoreValue.value);
    }
    if (scoreDisposition.present) {
      map['score_disposition'] = Variable<String>(scoreDisposition.value);
    }
    if (isInnerTen.present) {
      map['is_inner_ten'] = Variable<bool>(isInnerTen.value);
    }
    if (isBoundaryUncertain.present) {
      map['is_boundary_uncertain'] = Variable<bool>(isBoundaryUncertain.value);
    }
    if (placementMethod.present) {
      map['placement_method'] = Variable<String>(placementMethod.value);
    }
    if (visionAnalysisId.present) {
      map['vision_analysis_id'] = Variable<String>(visionAnalysisId.value);
    }
    if (positionalUncertaintyMm.present) {
      map['positional_uncertainty_mm'] = Variable<double>(
        positionalUncertaintyMm.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotImpactsCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('xMm: $xMm, ')
          ..write('yMm: $yMm, ')
          ..write('sourceImageId: $sourceImageId, ')
          ..write('imageXNormalized: $imageXNormalized, ')
          ..write('imageYNormalized: $imageYNormalized, ')
          ..write('multiplicity: $multiplicity, ')
          ..write('isMiss: $isMiss, ')
          ..write('isPositionUncertain: $isPositionUncertain, ')
          ..write('targetBullId: $targetBullId, ')
          ..write('scoreValue: $scoreValue, ')
          ..write('rawScoreValue: $rawScoreValue, ')
          ..write('scoreDisposition: $scoreDisposition, ')
          ..write('isInnerTen: $isInnerTen, ')
          ..write('isBoundaryUncertain: $isBoundaryUncertain, ')
          ..write('placementMethod: $placementMethod, ')
          ..write('visionAnalysisId: $visionAnalysisId, ')
          ..write('positionalUncertaintyMm: $positionalUncertaintyMm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoAlignmentsTable extends PhotoAlignments
    with TableInfo<$PhotoAlignmentsTable, PhotoAlignmentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoAlignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES image_assets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cornersJsonMeta = const VerificationMeta(
    'cornersJson',
  );
  @override
  late final GeneratedColumn<String> cornersJson = GeneratedColumn<String>(
    'corners_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matrixJsonMeta = const VerificationMeta(
    'matrixJson',
  );
  @override
  late final GeneratedColumn<String> matrixJson = GeneratedColumn<String>(
    'matrix_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _algorithmVersionMeta = const VerificationMeta(
    'algorithmVersion',
  );
  @override
  late final GeneratedColumn<String> algorithmVersion = GeneratedColumn<String>(
    'algorithm_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rotationQuarterTurnsMeta =
      const VerificationMeta('rotationQuarterTurns');
  @override
  late final GeneratedColumn<int> rotationQuarterTurns = GeneratedColumn<int>(
    'rotation_quarter_turns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alignmentModeMeta = const VerificationMeta(
    'alignmentMode',
  );
  @override
  late final GeneratedColumn<String> alignmentMode = GeneratedColumn<String>(
    'alignment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fullCard'),
  );
  static const VerificationMeta _anchorsJsonMeta = const VerificationMeta(
    'anchorsJson',
  );
  @override
  late final GeneratedColumn<String> anchorsJson = GeneratedColumn<String>(
    'anchors_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reprojectionRmsMmMeta = const VerificationMeta(
    'reprojectionRmsMm',
  );
  @override
  late final GeneratedColumn<double> reprojectionRmsMm =
      GeneratedColumn<double>(
        'reprojection_rms_mm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reprojectionMaxMmMeta = const VerificationMeta(
    'reprojectionMaxMm',
  );
  @override
  late final GeneratedColumn<double> reprojectionMaxMm =
      GeneratedColumn<double>(
        'reprojection_max_mm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _planarityStatusMeta = const VerificationMeta(
    'planarityStatus',
  );
  @override
  late final GeneratedColumn<String> planarityStatus = GeneratedColumn<String>(
    'planarity_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _confirmedAtUtcMeta = const VerificationMeta(
    'confirmedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAtUtc =
      GeneratedColumn<DateTime>(
        'confirmed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    imageId,
    cornersJson,
    matrixJson,
    algorithmVersion,
    rotationQuarterTurns,
    alignmentMode,
    anchorsJson,
    reprojectionRmsMm,
    reprojectionMaxMm,
    planarityStatus,
    confirmedAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_alignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoAlignmentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_imageIdMeta);
    }
    if (data.containsKey('corners_json')) {
      context.handle(
        _cornersJsonMeta,
        cornersJson.isAcceptableOrUnknown(
          data['corners_json']!,
          _cornersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cornersJsonMeta);
    }
    if (data.containsKey('matrix_json')) {
      context.handle(
        _matrixJsonMeta,
        matrixJson.isAcceptableOrUnknown(data['matrix_json']!, _matrixJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_matrixJsonMeta);
    }
    if (data.containsKey('algorithm_version')) {
      context.handle(
        _algorithmVersionMeta,
        algorithmVersion.isAcceptableOrUnknown(
          data['algorithm_version']!,
          _algorithmVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_algorithmVersionMeta);
    }
    if (data.containsKey('rotation_quarter_turns')) {
      context.handle(
        _rotationQuarterTurnsMeta,
        rotationQuarterTurns.isAcceptableOrUnknown(
          data['rotation_quarter_turns']!,
          _rotationQuarterTurnsMeta,
        ),
      );
    }
    if (data.containsKey('alignment_mode')) {
      context.handle(
        _alignmentModeMeta,
        alignmentMode.isAcceptableOrUnknown(
          data['alignment_mode']!,
          _alignmentModeMeta,
        ),
      );
    }
    if (data.containsKey('anchors_json')) {
      context.handle(
        _anchorsJsonMeta,
        anchorsJson.isAcceptableOrUnknown(
          data['anchors_json']!,
          _anchorsJsonMeta,
        ),
      );
    }
    if (data.containsKey('reprojection_rms_mm')) {
      context.handle(
        _reprojectionRmsMmMeta,
        reprojectionRmsMm.isAcceptableOrUnknown(
          data['reprojection_rms_mm']!,
          _reprojectionRmsMmMeta,
        ),
      );
    }
    if (data.containsKey('reprojection_max_mm')) {
      context.handle(
        _reprojectionMaxMmMeta,
        reprojectionMaxMm.isAcceptableOrUnknown(
          data['reprojection_max_mm']!,
          _reprojectionMaxMmMeta,
        ),
      );
    }
    if (data.containsKey('planarity_status')) {
      context.handle(
        _planarityStatusMeta,
        planarityStatus.isAcceptableOrUnknown(
          data['planarity_status']!,
          _planarityStatusMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_at_utc')) {
      context.handle(
        _confirmedAtUtcMeta,
        confirmedAtUtc.isAcceptableOrUnknown(
          data['confirmed_at_utc']!,
          _confirmedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {imageId};
  @override
  PhotoAlignmentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoAlignmentRecord(
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      )!,
      cornersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corners_json'],
      )!,
      matrixJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matrix_json'],
      )!,
      algorithmVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}algorithm_version'],
      )!,
      rotationQuarterTurns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation_quarter_turns'],
      )!,
      alignmentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alignment_mode'],
      )!,
      anchorsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchors_json'],
      ),
      reprojectionRmsMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reprojection_rms_mm'],
      ),
      reprojectionMaxMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reprojection_max_mm'],
      ),
      planarityStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planarity_status'],
      )!,
      confirmedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at_utc'],
      ),
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $PhotoAlignmentsTable createAlias(String alias) {
    return $PhotoAlignmentsTable(attachedDatabase, alias);
  }
}

class PhotoAlignmentRecord extends DataClass
    implements Insertable<PhotoAlignmentRecord> {
  final String imageId;
  final String cornersJson;
  final String matrixJson;
  final String algorithmVersion;
  final int rotationQuarterTurns;
  final String alignmentMode;
  final String? anchorsJson;
  final double? reprojectionRmsMm;
  final double? reprojectionMaxMm;
  final String planarityStatus;
  final DateTime? confirmedAtUtc;
  final DateTime updatedAtUtc;
  const PhotoAlignmentRecord({
    required this.imageId,
    required this.cornersJson,
    required this.matrixJson,
    required this.algorithmVersion,
    required this.rotationQuarterTurns,
    required this.alignmentMode,
    this.anchorsJson,
    this.reprojectionRmsMm,
    this.reprojectionMaxMm,
    required this.planarityStatus,
    this.confirmedAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['image_id'] = Variable<String>(imageId);
    map['corners_json'] = Variable<String>(cornersJson);
    map['matrix_json'] = Variable<String>(matrixJson);
    map['algorithm_version'] = Variable<String>(algorithmVersion);
    map['rotation_quarter_turns'] = Variable<int>(rotationQuarterTurns);
    map['alignment_mode'] = Variable<String>(alignmentMode);
    if (!nullToAbsent || anchorsJson != null) {
      map['anchors_json'] = Variable<String>(anchorsJson);
    }
    if (!nullToAbsent || reprojectionRmsMm != null) {
      map['reprojection_rms_mm'] = Variable<double>(reprojectionRmsMm);
    }
    if (!nullToAbsent || reprojectionMaxMm != null) {
      map['reprojection_max_mm'] = Variable<double>(reprojectionMaxMm);
    }
    map['planarity_status'] = Variable<String>(planarityStatus);
    if (!nullToAbsent || confirmedAtUtc != null) {
      map['confirmed_at_utc'] = Variable<DateTime>(confirmedAtUtc);
    }
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  PhotoAlignmentsCompanion toCompanion(bool nullToAbsent) {
    return PhotoAlignmentsCompanion(
      imageId: Value(imageId),
      cornersJson: Value(cornersJson),
      matrixJson: Value(matrixJson),
      algorithmVersion: Value(algorithmVersion),
      rotationQuarterTurns: Value(rotationQuarterTurns),
      alignmentMode: Value(alignmentMode),
      anchorsJson: anchorsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorsJson),
      reprojectionRmsMm: reprojectionRmsMm == null && nullToAbsent
          ? const Value.absent()
          : Value(reprojectionRmsMm),
      reprojectionMaxMm: reprojectionMaxMm == null && nullToAbsent
          ? const Value.absent()
          : Value(reprojectionMaxMm),
      planarityStatus: Value(planarityStatus),
      confirmedAtUtc: confirmedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory PhotoAlignmentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoAlignmentRecord(
      imageId: serializer.fromJson<String>(json['imageId']),
      cornersJson: serializer.fromJson<String>(json['cornersJson']),
      matrixJson: serializer.fromJson<String>(json['matrixJson']),
      algorithmVersion: serializer.fromJson<String>(json['algorithmVersion']),
      rotationQuarterTurns: serializer.fromJson<int>(
        json['rotationQuarterTurns'],
      ),
      alignmentMode: serializer.fromJson<String>(json['alignmentMode']),
      anchorsJson: serializer.fromJson<String?>(json['anchorsJson']),
      reprojectionRmsMm: serializer.fromJson<double?>(
        json['reprojectionRmsMm'],
      ),
      reprojectionMaxMm: serializer.fromJson<double?>(
        json['reprojectionMaxMm'],
      ),
      planarityStatus: serializer.fromJson<String>(json['planarityStatus']),
      confirmedAtUtc: serializer.fromJson<DateTime?>(json['confirmedAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'imageId': serializer.toJson<String>(imageId),
      'cornersJson': serializer.toJson<String>(cornersJson),
      'matrixJson': serializer.toJson<String>(matrixJson),
      'algorithmVersion': serializer.toJson<String>(algorithmVersion),
      'rotationQuarterTurns': serializer.toJson<int>(rotationQuarterTurns),
      'alignmentMode': serializer.toJson<String>(alignmentMode),
      'anchorsJson': serializer.toJson<String?>(anchorsJson),
      'reprojectionRmsMm': serializer.toJson<double?>(reprojectionRmsMm),
      'reprojectionMaxMm': serializer.toJson<double?>(reprojectionMaxMm),
      'planarityStatus': serializer.toJson<String>(planarityStatus),
      'confirmedAtUtc': serializer.toJson<DateTime?>(confirmedAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  PhotoAlignmentRecord copyWith({
    String? imageId,
    String? cornersJson,
    String? matrixJson,
    String? algorithmVersion,
    int? rotationQuarterTurns,
    String? alignmentMode,
    Value<String?> anchorsJson = const Value.absent(),
    Value<double?> reprojectionRmsMm = const Value.absent(),
    Value<double?> reprojectionMaxMm = const Value.absent(),
    String? planarityStatus,
    Value<DateTime?> confirmedAtUtc = const Value.absent(),
    DateTime? updatedAtUtc,
  }) => PhotoAlignmentRecord(
    imageId: imageId ?? this.imageId,
    cornersJson: cornersJson ?? this.cornersJson,
    matrixJson: matrixJson ?? this.matrixJson,
    algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
    alignmentMode: alignmentMode ?? this.alignmentMode,
    anchorsJson: anchorsJson.present ? anchorsJson.value : this.anchorsJson,
    reprojectionRmsMm: reprojectionRmsMm.present
        ? reprojectionRmsMm.value
        : this.reprojectionRmsMm,
    reprojectionMaxMm: reprojectionMaxMm.present
        ? reprojectionMaxMm.value
        : this.reprojectionMaxMm,
    planarityStatus: planarityStatus ?? this.planarityStatus,
    confirmedAtUtc: confirmedAtUtc.present
        ? confirmedAtUtc.value
        : this.confirmedAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  PhotoAlignmentRecord copyWithCompanion(PhotoAlignmentsCompanion data) {
    return PhotoAlignmentRecord(
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
      cornersJson: data.cornersJson.present
          ? data.cornersJson.value
          : this.cornersJson,
      matrixJson: data.matrixJson.present
          ? data.matrixJson.value
          : this.matrixJson,
      algorithmVersion: data.algorithmVersion.present
          ? data.algorithmVersion.value
          : this.algorithmVersion,
      rotationQuarterTurns: data.rotationQuarterTurns.present
          ? data.rotationQuarterTurns.value
          : this.rotationQuarterTurns,
      alignmentMode: data.alignmentMode.present
          ? data.alignmentMode.value
          : this.alignmentMode,
      anchorsJson: data.anchorsJson.present
          ? data.anchorsJson.value
          : this.anchorsJson,
      reprojectionRmsMm: data.reprojectionRmsMm.present
          ? data.reprojectionRmsMm.value
          : this.reprojectionRmsMm,
      reprojectionMaxMm: data.reprojectionMaxMm.present
          ? data.reprojectionMaxMm.value
          : this.reprojectionMaxMm,
      planarityStatus: data.planarityStatus.present
          ? data.planarityStatus.value
          : this.planarityStatus,
      confirmedAtUtc: data.confirmedAtUtc.present
          ? data.confirmedAtUtc.value
          : this.confirmedAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoAlignmentRecord(')
          ..write('imageId: $imageId, ')
          ..write('cornersJson: $cornersJson, ')
          ..write('matrixJson: $matrixJson, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('rotationQuarterTurns: $rotationQuarterTurns, ')
          ..write('alignmentMode: $alignmentMode, ')
          ..write('anchorsJson: $anchorsJson, ')
          ..write('reprojectionRmsMm: $reprojectionRmsMm, ')
          ..write('reprojectionMaxMm: $reprojectionMaxMm, ')
          ..write('planarityStatus: $planarityStatus, ')
          ..write('confirmedAtUtc: $confirmedAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    imageId,
    cornersJson,
    matrixJson,
    algorithmVersion,
    rotationQuarterTurns,
    alignmentMode,
    anchorsJson,
    reprojectionRmsMm,
    reprojectionMaxMm,
    planarityStatus,
    confirmedAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoAlignmentRecord &&
          other.imageId == this.imageId &&
          other.cornersJson == this.cornersJson &&
          other.matrixJson == this.matrixJson &&
          other.algorithmVersion == this.algorithmVersion &&
          other.rotationQuarterTurns == this.rotationQuarterTurns &&
          other.alignmentMode == this.alignmentMode &&
          other.anchorsJson == this.anchorsJson &&
          other.reprojectionRmsMm == this.reprojectionRmsMm &&
          other.reprojectionMaxMm == this.reprojectionMaxMm &&
          other.planarityStatus == this.planarityStatus &&
          other.confirmedAtUtc == this.confirmedAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class PhotoAlignmentsCompanion extends UpdateCompanion<PhotoAlignmentRecord> {
  final Value<String> imageId;
  final Value<String> cornersJson;
  final Value<String> matrixJson;
  final Value<String> algorithmVersion;
  final Value<int> rotationQuarterTurns;
  final Value<String> alignmentMode;
  final Value<String?> anchorsJson;
  final Value<double?> reprojectionRmsMm;
  final Value<double?> reprojectionMaxMm;
  final Value<String> planarityStatus;
  final Value<DateTime?> confirmedAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const PhotoAlignmentsCompanion({
    this.imageId = const Value.absent(),
    this.cornersJson = const Value.absent(),
    this.matrixJson = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    this.rotationQuarterTurns = const Value.absent(),
    this.alignmentMode = const Value.absent(),
    this.anchorsJson = const Value.absent(),
    this.reprojectionRmsMm = const Value.absent(),
    this.reprojectionMaxMm = const Value.absent(),
    this.planarityStatus = const Value.absent(),
    this.confirmedAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoAlignmentsCompanion.insert({
    required String imageId,
    required String cornersJson,
    required String matrixJson,
    required String algorithmVersion,
    this.rotationQuarterTurns = const Value.absent(),
    this.alignmentMode = const Value.absent(),
    this.anchorsJson = const Value.absent(),
    this.reprojectionRmsMm = const Value.absent(),
    this.reprojectionMaxMm = const Value.absent(),
    this.planarityStatus = const Value.absent(),
    this.confirmedAtUtc = const Value.absent(),
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : imageId = Value(imageId),
       cornersJson = Value(cornersJson),
       matrixJson = Value(matrixJson),
       algorithmVersion = Value(algorithmVersion),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<PhotoAlignmentRecord> custom({
    Expression<String>? imageId,
    Expression<String>? cornersJson,
    Expression<String>? matrixJson,
    Expression<String>? algorithmVersion,
    Expression<int>? rotationQuarterTurns,
    Expression<String>? alignmentMode,
    Expression<String>? anchorsJson,
    Expression<double>? reprojectionRmsMm,
    Expression<double>? reprojectionMaxMm,
    Expression<String>? planarityStatus,
    Expression<DateTime>? confirmedAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (imageId != null) 'image_id': imageId,
      if (cornersJson != null) 'corners_json': cornersJson,
      if (matrixJson != null) 'matrix_json': matrixJson,
      if (algorithmVersion != null) 'algorithm_version': algorithmVersion,
      if (rotationQuarterTurns != null)
        'rotation_quarter_turns': rotationQuarterTurns,
      if (alignmentMode != null) 'alignment_mode': alignmentMode,
      if (anchorsJson != null) 'anchors_json': anchorsJson,
      if (reprojectionRmsMm != null) 'reprojection_rms_mm': reprojectionRmsMm,
      if (reprojectionMaxMm != null) 'reprojection_max_mm': reprojectionMaxMm,
      if (planarityStatus != null) 'planarity_status': planarityStatus,
      if (confirmedAtUtc != null) 'confirmed_at_utc': confirmedAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoAlignmentsCompanion copyWith({
    Value<String>? imageId,
    Value<String>? cornersJson,
    Value<String>? matrixJson,
    Value<String>? algorithmVersion,
    Value<int>? rotationQuarterTurns,
    Value<String>? alignmentMode,
    Value<String?>? anchorsJson,
    Value<double?>? reprojectionRmsMm,
    Value<double?>? reprojectionMaxMm,
    Value<String>? planarityStatus,
    Value<DateTime?>? confirmedAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return PhotoAlignmentsCompanion(
      imageId: imageId ?? this.imageId,
      cornersJson: cornersJson ?? this.cornersJson,
      matrixJson: matrixJson ?? this.matrixJson,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      alignmentMode: alignmentMode ?? this.alignmentMode,
      anchorsJson: anchorsJson ?? this.anchorsJson,
      reprojectionRmsMm: reprojectionRmsMm ?? this.reprojectionRmsMm,
      reprojectionMaxMm: reprojectionMaxMm ?? this.reprojectionMaxMm,
      planarityStatus: planarityStatus ?? this.planarityStatus,
      confirmedAtUtc: confirmedAtUtc ?? this.confirmedAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (cornersJson.present) {
      map['corners_json'] = Variable<String>(cornersJson.value);
    }
    if (matrixJson.present) {
      map['matrix_json'] = Variable<String>(matrixJson.value);
    }
    if (algorithmVersion.present) {
      map['algorithm_version'] = Variable<String>(algorithmVersion.value);
    }
    if (rotationQuarterTurns.present) {
      map['rotation_quarter_turns'] = Variable<int>(rotationQuarterTurns.value);
    }
    if (alignmentMode.present) {
      map['alignment_mode'] = Variable<String>(alignmentMode.value);
    }
    if (anchorsJson.present) {
      map['anchors_json'] = Variable<String>(anchorsJson.value);
    }
    if (reprojectionRmsMm.present) {
      map['reprojection_rms_mm'] = Variable<double>(reprojectionRmsMm.value);
    }
    if (reprojectionMaxMm.present) {
      map['reprojection_max_mm'] = Variable<double>(reprojectionMaxMm.value);
    }
    if (planarityStatus.present) {
      map['planarity_status'] = Variable<String>(planarityStatus.value);
    }
    if (confirmedAtUtc.present) {
      map['confirmed_at_utc'] = Variable<DateTime>(confirmedAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoAlignmentsCompanion(')
          ..write('imageId: $imageId, ')
          ..write('cornersJson: $cornersJson, ')
          ..write('matrixJson: $matrixJson, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('rotationQuarterTurns: $rotationQuarterTurns, ')
          ..write('alignmentMode: $alignmentMode, ')
          ..write('anchorsJson: $anchorsJson, ')
          ..write('reprojectionRmsMm: $reprojectionRmsMm, ')
          ..write('reprojectionMaxMm: $reprojectionMaxMm, ')
          ..write('planarityStatus: $planarityStatus, ')
          ..write('confirmedAtUtc: $confirmedAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetProfileVersionedIdMeta =
      const VerificationMeta('targetProfileVersionedId');
  @override
  late final GeneratedColumn<String> targetProfileVersionedId =
      GeneratedColumn<String>(
        'target_profile_versioned_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firearmIdMeta = const VerificationMeta(
    'firearmId',
  );
  @override
  late final GeneratedColumn<String> firearmId = GeneratedColumn<String>(
    'firearm_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES firearms (id)',
    ),
  );
  static const VerificationMeta _ammoLotIdMeta = const VerificationMeta(
    'ammoLotId',
  );
  @override
  late final GeneratedColumn<String> ammoLotId = GeneratedColumn<String>(
    'ammo_lot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ammo_lots (id)',
    ),
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetValueMeta = const VerificationMeta(
    'targetValue',
  );
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
    'target_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comparisonMeta = const VerificationMeta(
    'comparison',
  );
  @override
  late final GeneratedColumn<String> comparison = GeneratedColumn<String>(
    'comparison',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetProfileVersionedId,
    distanceMeters,
    firearmId,
    ammoLotId,
    metric,
    targetValue,
    comparison,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_profile_versioned_id')) {
      context.handle(
        _targetProfileVersionedIdMeta,
        targetProfileVersionedId.isAcceptableOrUnknown(
          data['target_profile_versioned_id']!,
          _targetProfileVersionedIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetProfileVersionedIdMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('firearm_id')) {
      context.handle(
        _firearmIdMeta,
        firearmId.isAcceptableOrUnknown(data['firearm_id']!, _firearmIdMeta),
      );
    }
    if (data.containsKey('ammo_lot_id')) {
      context.handle(
        _ammoLotIdMeta,
        ammoLotId.isAcceptableOrUnknown(data['ammo_lot_id']!, _ammoLotIdMeta),
      );
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('target_value')) {
      context.handle(
        _targetValueMeta,
        targetValue.isAcceptableOrUnknown(
          data['target_value']!,
          _targetValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetValueMeta);
    }
    if (data.containsKey('comparison')) {
      context.handle(
        _comparisonMeta,
        comparison.isAcceptableOrUnknown(data['comparison']!, _comparisonMeta),
      );
    } else if (isInserting) {
      context.missing(_comparisonMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetProfileVersionedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_profile_versioned_id'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      firearmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firearm_id'],
      ),
      ammoLotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ammo_lot_id'],
      ),
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      targetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_value'],
      )!,
      comparison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comparison'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalRecord extends DataClass implements Insertable<GoalRecord> {
  final String id;
  final String targetProfileVersionedId;
  final double distanceMeters;
  final String? firearmId;
  final String? ammoLotId;
  final String metric;
  final double targetValue;
  final String comparison;
  final bool active;
  const GoalRecord({
    required this.id,
    required this.targetProfileVersionedId,
    required this.distanceMeters,
    this.firearmId,
    this.ammoLotId,
    required this.metric,
    required this.targetValue,
    required this.comparison,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_profile_versioned_id'] = Variable<String>(
      targetProfileVersionedId,
    );
    map['distance_meters'] = Variable<double>(distanceMeters);
    if (!nullToAbsent || firearmId != null) {
      map['firearm_id'] = Variable<String>(firearmId);
    }
    if (!nullToAbsent || ammoLotId != null) {
      map['ammo_lot_id'] = Variable<String>(ammoLotId);
    }
    map['metric'] = Variable<String>(metric);
    map['target_value'] = Variable<double>(targetValue);
    map['comparison'] = Variable<String>(comparison);
    map['active'] = Variable<bool>(active);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      targetProfileVersionedId: Value(targetProfileVersionedId),
      distanceMeters: Value(distanceMeters),
      firearmId: firearmId == null && nullToAbsent
          ? const Value.absent()
          : Value(firearmId),
      ammoLotId: ammoLotId == null && nullToAbsent
          ? const Value.absent()
          : Value(ammoLotId),
      metric: Value(metric),
      targetValue: Value(targetValue),
      comparison: Value(comparison),
      active: Value(active),
    );
  }

  factory GoalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRecord(
      id: serializer.fromJson<String>(json['id']),
      targetProfileVersionedId: serializer.fromJson<String>(
        json['targetProfileVersionedId'],
      ),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      firearmId: serializer.fromJson<String?>(json['firearmId']),
      ammoLotId: serializer.fromJson<String?>(json['ammoLotId']),
      metric: serializer.fromJson<String>(json['metric']),
      targetValue: serializer.fromJson<double>(json['targetValue']),
      comparison: serializer.fromJson<String>(json['comparison']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetProfileVersionedId': serializer.toJson<String>(
        targetProfileVersionedId,
      ),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'firearmId': serializer.toJson<String?>(firearmId),
      'ammoLotId': serializer.toJson<String?>(ammoLotId),
      'metric': serializer.toJson<String>(metric),
      'targetValue': serializer.toJson<double>(targetValue),
      'comparison': serializer.toJson<String>(comparison),
      'active': serializer.toJson<bool>(active),
    };
  }

  GoalRecord copyWith({
    String? id,
    String? targetProfileVersionedId,
    double? distanceMeters,
    Value<String?> firearmId = const Value.absent(),
    Value<String?> ammoLotId = const Value.absent(),
    String? metric,
    double? targetValue,
    String? comparison,
    bool? active,
  }) => GoalRecord(
    id: id ?? this.id,
    targetProfileVersionedId:
        targetProfileVersionedId ?? this.targetProfileVersionedId,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    firearmId: firearmId.present ? firearmId.value : this.firearmId,
    ammoLotId: ammoLotId.present ? ammoLotId.value : this.ammoLotId,
    metric: metric ?? this.metric,
    targetValue: targetValue ?? this.targetValue,
    comparison: comparison ?? this.comparison,
    active: active ?? this.active,
  );
  GoalRecord copyWithCompanion(GoalsCompanion data) {
    return GoalRecord(
      id: data.id.present ? data.id.value : this.id,
      targetProfileVersionedId: data.targetProfileVersionedId.present
          ? data.targetProfileVersionedId.value
          : this.targetProfileVersionedId,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      firearmId: data.firearmId.present ? data.firearmId.value : this.firearmId,
      ammoLotId: data.ammoLotId.present ? data.ammoLotId.value : this.ammoLotId,
      metric: data.metric.present ? data.metric.value : this.metric,
      targetValue: data.targetValue.present
          ? data.targetValue.value
          : this.targetValue,
      comparison: data.comparison.present
          ? data.comparison.value
          : this.comparison,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRecord(')
          ..write('id: $id, ')
          ..write('targetProfileVersionedId: $targetProfileVersionedId, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('firearmId: $firearmId, ')
          ..write('ammoLotId: $ammoLotId, ')
          ..write('metric: $metric, ')
          ..write('targetValue: $targetValue, ')
          ..write('comparison: $comparison, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetProfileVersionedId,
    distanceMeters,
    firearmId,
    ammoLotId,
    metric,
    targetValue,
    comparison,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRecord &&
          other.id == this.id &&
          other.targetProfileVersionedId == this.targetProfileVersionedId &&
          other.distanceMeters == this.distanceMeters &&
          other.firearmId == this.firearmId &&
          other.ammoLotId == this.ammoLotId &&
          other.metric == this.metric &&
          other.targetValue == this.targetValue &&
          other.comparison == this.comparison &&
          other.active == this.active);
}

class GoalsCompanion extends UpdateCompanion<GoalRecord> {
  final Value<String> id;
  final Value<String> targetProfileVersionedId;
  final Value<double> distanceMeters;
  final Value<String?> firearmId;
  final Value<String?> ammoLotId;
  final Value<String> metric;
  final Value<double> targetValue;
  final Value<String> comparison;
  final Value<bool> active;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.targetProfileVersionedId = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.firearmId = const Value.absent(),
    this.ammoLotId = const Value.absent(),
    this.metric = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.comparison = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String targetProfileVersionedId,
    required double distanceMeters,
    this.firearmId = const Value.absent(),
    this.ammoLotId = const Value.absent(),
    required String metric,
    required double targetValue,
    required String comparison,
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetProfileVersionedId = Value(targetProfileVersionedId),
       distanceMeters = Value(distanceMeters),
       metric = Value(metric),
       targetValue = Value(targetValue),
       comparison = Value(comparison);
  static Insertable<GoalRecord> custom({
    Expression<String>? id,
    Expression<String>? targetProfileVersionedId,
    Expression<double>? distanceMeters,
    Expression<String>? firearmId,
    Expression<String>? ammoLotId,
    Expression<String>? metric,
    Expression<double>? targetValue,
    Expression<String>? comparison,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetProfileVersionedId != null)
        'target_profile_versioned_id': targetProfileVersionedId,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (firearmId != null) 'firearm_id': firearmId,
      if (ammoLotId != null) 'ammo_lot_id': ammoLotId,
      if (metric != null) 'metric': metric,
      if (targetValue != null) 'target_value': targetValue,
      if (comparison != null) 'comparison': comparison,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? targetProfileVersionedId,
    Value<double>? distanceMeters,
    Value<String?>? firearmId,
    Value<String?>? ammoLotId,
    Value<String>? metric,
    Value<double>? targetValue,
    Value<String>? comparison,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      targetProfileVersionedId:
          targetProfileVersionedId ?? this.targetProfileVersionedId,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      firearmId: firearmId ?? this.firearmId,
      ammoLotId: ammoLotId ?? this.ammoLotId,
      metric: metric ?? this.metric,
      targetValue: targetValue ?? this.targetValue,
      comparison: comparison ?? this.comparison,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetProfileVersionedId.present) {
      map['target_profile_versioned_id'] = Variable<String>(
        targetProfileVersionedId.value,
      );
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (firearmId.present) {
      map['firearm_id'] = Variable<String>(firearmId.value);
    }
    if (ammoLotId.present) {
      map['ammo_lot_id'] = Variable<String>(ammoLotId.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (comparison.present) {
      map['comparison'] = Variable<String>(comparison.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('targetProfileVersionedId: $targetProfileVersionedId, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('firearmId: $firearmId, ')
          ..write('ammoLotId: $ammoLotId, ')
          ..write('metric: $metric, ')
          ..write('targetValue: $targetValue, ')
          ..write('comparison: $comparison, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesReflectionsTable extends SeriesReflections
    with TableInfo<$SeriesReflectionsTable, SeriesReflectionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shooting_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _perceivedQualityMeta = const VerificationMeta(
    'perceivedQuality',
  );
  @override
  late final GeneratedColumn<String> perceivedQuality = GeneratedColumn<String>(
    'perceived_quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextTagsJsonMeta = const VerificationMeta(
    'contextTagsJson',
  );
  @override
  late final GeneratedColumn<String> contextTagsJson = GeneratedColumn<String>(
    'context_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seriesId,
    perceivedQuality,
    contextTagsJson,
    note,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesReflectionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('perceived_quality')) {
      context.handle(
        _perceivedQualityMeta,
        perceivedQuality.isAcceptableOrUnknown(
          data['perceived_quality']!,
          _perceivedQualityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perceivedQualityMeta);
    }
    if (data.containsKey('context_tags_json')) {
      context.handle(
        _contextTagsJsonMeta,
        contextTagsJson.isAcceptableOrUnknown(
          data['context_tags_json']!,
          _contextTagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seriesId};
  @override
  SeriesReflectionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesReflectionRecord(
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      perceivedQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perceived_quality'],
      )!,
      contextTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_tags_json'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $SeriesReflectionsTable createAlias(String alias) {
    return $SeriesReflectionsTable(attachedDatabase, alias);
  }
}

class SeriesReflectionRecord extends DataClass
    implements Insertable<SeriesReflectionRecord> {
  final String seriesId;
  final String perceivedQuality;
  final String contextTagsJson;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const SeriesReflectionRecord({
    required this.seriesId,
    required this.perceivedQuality,
    required this.contextTagsJson,
    this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['series_id'] = Variable<String>(seriesId);
    map['perceived_quality'] = Variable<String>(perceivedQuality);
    map['context_tags_json'] = Variable<String>(contextTagsJson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  SeriesReflectionsCompanion toCompanion(bool nullToAbsent) {
    return SeriesReflectionsCompanion(
      seriesId: Value(seriesId),
      perceivedQuality: Value(perceivedQuality),
      contextTagsJson: Value(contextTagsJson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory SeriesReflectionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesReflectionRecord(
      seriesId: serializer.fromJson<String>(json['seriesId']),
      perceivedQuality: serializer.fromJson<String>(json['perceivedQuality']),
      contextTagsJson: serializer.fromJson<String>(json['contextTagsJson']),
      note: serializer.fromJson<String?>(json['note']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seriesId': serializer.toJson<String>(seriesId),
      'perceivedQuality': serializer.toJson<String>(perceivedQuality),
      'contextTagsJson': serializer.toJson<String>(contextTagsJson),
      'note': serializer.toJson<String?>(note),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  SeriesReflectionRecord copyWith({
    String? seriesId,
    String? perceivedQuality,
    String? contextTagsJson,
    Value<String?> note = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => SeriesReflectionRecord(
    seriesId: seriesId ?? this.seriesId,
    perceivedQuality: perceivedQuality ?? this.perceivedQuality,
    contextTagsJson: contextTagsJson ?? this.contextTagsJson,
    note: note.present ? note.value : this.note,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  SeriesReflectionRecord copyWithCompanion(SeriesReflectionsCompanion data) {
    return SeriesReflectionRecord(
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      perceivedQuality: data.perceivedQuality.present
          ? data.perceivedQuality.value
          : this.perceivedQuality,
      contextTagsJson: data.contextTagsJson.present
          ? data.contextTagsJson.value
          : this.contextTagsJson,
      note: data.note.present ? data.note.value : this.note,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesReflectionRecord(')
          ..write('seriesId: $seriesId, ')
          ..write('perceivedQuality: $perceivedQuality, ')
          ..write('contextTagsJson: $contextTagsJson, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seriesId,
    perceivedQuality,
    contextTagsJson,
    note,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesReflectionRecord &&
          other.seriesId == this.seriesId &&
          other.perceivedQuality == this.perceivedQuality &&
          other.contextTagsJson == this.contextTagsJson &&
          other.note == this.note &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class SeriesReflectionsCompanion
    extends UpdateCompanion<SeriesReflectionRecord> {
  final Value<String> seriesId;
  final Value<String> perceivedQuality;
  final Value<String> contextTagsJson;
  final Value<String?> note;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const SeriesReflectionsCompanion({
    this.seriesId = const Value.absent(),
    this.perceivedQuality = const Value.absent(),
    this.contextTagsJson = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesReflectionsCompanion.insert({
    required String seriesId,
    required String perceivedQuality,
    this.contextTagsJson = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : seriesId = Value(seriesId),
       perceivedQuality = Value(perceivedQuality),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<SeriesReflectionRecord> custom({
    Expression<String>? seriesId,
    Expression<String>? perceivedQuality,
    Expression<String>? contextTagsJson,
    Expression<String>? note,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seriesId != null) 'series_id': seriesId,
      if (perceivedQuality != null) 'perceived_quality': perceivedQuality,
      if (contextTagsJson != null) 'context_tags_json': contextTagsJson,
      if (note != null) 'note': note,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesReflectionsCompanion copyWith({
    Value<String>? seriesId,
    Value<String>? perceivedQuality,
    Value<String>? contextTagsJson,
    Value<String?>? note,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return SeriesReflectionsCompanion(
      seriesId: seriesId ?? this.seriesId,
      perceivedQuality: perceivedQuality ?? this.perceivedQuality,
      contextTagsJson: contextTagsJson ?? this.contextTagsJson,
      note: note ?? this.note,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (perceivedQuality.present) {
      map['perceived_quality'] = Variable<String>(perceivedQuality.value);
    }
    if (contextTagsJson.present) {
      map['context_tags_json'] = Variable<String>(contextTagsJson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesReflectionsCompanion(')
          ..write('seriesId: $seriesId, ')
          ..write('perceivedQuality: $perceivedQuality, ')
          ..write('contextTagsJson: $contextTagsJson, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoachFeedbackTable extends CoachFeedback
    with TableInfo<$CoachFeedbackTable, CoachFeedbackRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _insightFingerprintMeta =
      const VerificationMeta('insightFingerprint');
  @override
  late final GeneratedColumn<String> insightFingerprint =
      GeneratedColumn<String>(
        'insight_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  @override
  late final GeneratedColumn<int> ruleVersion = GeneratedColumn<int>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta(
    'response',
  );
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozedUntilUtcMeta = const VerificationMeta(
    'snoozedUntilUtc',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntilUtc =
      GeneratedColumn<DateTime>(
        'snoozed_until_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    insightFingerprint,
    ruleId,
    ruleVersion,
    response,
    snoozedUntilUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachFeedbackRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('insight_fingerprint')) {
      context.handle(
        _insightFingerprintMeta,
        insightFingerprint.isAcceptableOrUnknown(
          data['insight_fingerprint']!,
          _insightFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_insightFingerprintMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('snoozed_until_utc')) {
      context.handle(
        _snoozedUntilUtcMeta,
        snoozedUntilUtc.isAcceptableOrUnknown(
          data['snoozed_until_utc']!,
          _snoozedUntilUtcMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {insightFingerprint};
  @override
  CoachFeedbackRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachFeedbackRecord(
      insightFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight_fingerprint'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_version'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      )!,
      snoozedUntilUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until_utc'],
      ),
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $CoachFeedbackTable createAlias(String alias) {
    return $CoachFeedbackTable(attachedDatabase, alias);
  }
}

class CoachFeedbackRecord extends DataClass
    implements Insertable<CoachFeedbackRecord> {
  final String insightFingerprint;
  final String ruleId;
  final int ruleVersion;
  final String response;
  final DateTime? snoozedUntilUtc;
  final DateTime updatedAtUtc;
  const CoachFeedbackRecord({
    required this.insightFingerprint,
    required this.ruleId,
    required this.ruleVersion,
    required this.response,
    this.snoozedUntilUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['insight_fingerprint'] = Variable<String>(insightFingerprint);
    map['rule_id'] = Variable<String>(ruleId);
    map['rule_version'] = Variable<int>(ruleVersion);
    map['response'] = Variable<String>(response);
    if (!nullToAbsent || snoozedUntilUtc != null) {
      map['snoozed_until_utc'] = Variable<DateTime>(snoozedUntilUtc);
    }
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  CoachFeedbackCompanion toCompanion(bool nullToAbsent) {
    return CoachFeedbackCompanion(
      insightFingerprint: Value(insightFingerprint),
      ruleId: Value(ruleId),
      ruleVersion: Value(ruleVersion),
      response: Value(response),
      snoozedUntilUtc: snoozedUntilUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntilUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory CoachFeedbackRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachFeedbackRecord(
      insightFingerprint: serializer.fromJson<String>(
        json['insightFingerprint'],
      ),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      ruleVersion: serializer.fromJson<int>(json['ruleVersion']),
      response: serializer.fromJson<String>(json['response']),
      snoozedUntilUtc: serializer.fromJson<DateTime?>(json['snoozedUntilUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'insightFingerprint': serializer.toJson<String>(insightFingerprint),
      'ruleId': serializer.toJson<String>(ruleId),
      'ruleVersion': serializer.toJson<int>(ruleVersion),
      'response': serializer.toJson<String>(response),
      'snoozedUntilUtc': serializer.toJson<DateTime?>(snoozedUntilUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  CoachFeedbackRecord copyWith({
    String? insightFingerprint,
    String? ruleId,
    int? ruleVersion,
    String? response,
    Value<DateTime?> snoozedUntilUtc = const Value.absent(),
    DateTime? updatedAtUtc,
  }) => CoachFeedbackRecord(
    insightFingerprint: insightFingerprint ?? this.insightFingerprint,
    ruleId: ruleId ?? this.ruleId,
    ruleVersion: ruleVersion ?? this.ruleVersion,
    response: response ?? this.response,
    snoozedUntilUtc: snoozedUntilUtc.present
        ? snoozedUntilUtc.value
        : this.snoozedUntilUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  CoachFeedbackRecord copyWithCompanion(CoachFeedbackCompanion data) {
    return CoachFeedbackRecord(
      insightFingerprint: data.insightFingerprint.present
          ? data.insightFingerprint.value
          : this.insightFingerprint,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
      response: data.response.present ? data.response.value : this.response,
      snoozedUntilUtc: data.snoozedUntilUtc.present
          ? data.snoozedUntilUtc.value
          : this.snoozedUntilUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachFeedbackRecord(')
          ..write('insightFingerprint: $insightFingerprint, ')
          ..write('ruleId: $ruleId, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('response: $response, ')
          ..write('snoozedUntilUtc: $snoozedUntilUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    insightFingerprint,
    ruleId,
    ruleVersion,
    response,
    snoozedUntilUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachFeedbackRecord &&
          other.insightFingerprint == this.insightFingerprint &&
          other.ruleId == this.ruleId &&
          other.ruleVersion == this.ruleVersion &&
          other.response == this.response &&
          other.snoozedUntilUtc == this.snoozedUntilUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class CoachFeedbackCompanion extends UpdateCompanion<CoachFeedbackRecord> {
  final Value<String> insightFingerprint;
  final Value<String> ruleId;
  final Value<int> ruleVersion;
  final Value<String> response;
  final Value<DateTime?> snoozedUntilUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const CoachFeedbackCompanion({
    this.insightFingerprint = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.response = const Value.absent(),
    this.snoozedUntilUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoachFeedbackCompanion.insert({
    required String insightFingerprint,
    required String ruleId,
    required int ruleVersion,
    required String response,
    this.snoozedUntilUtc = const Value.absent(),
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : insightFingerprint = Value(insightFingerprint),
       ruleId = Value(ruleId),
       ruleVersion = Value(ruleVersion),
       response = Value(response),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<CoachFeedbackRecord> custom({
    Expression<String>? insightFingerprint,
    Expression<String>? ruleId,
    Expression<int>? ruleVersion,
    Expression<String>? response,
    Expression<DateTime>? snoozedUntilUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (insightFingerprint != null) 'insight_fingerprint': insightFingerprint,
      if (ruleId != null) 'rule_id': ruleId,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (response != null) 'response': response,
      if (snoozedUntilUtc != null) 'snoozed_until_utc': snoozedUntilUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoachFeedbackCompanion copyWith({
    Value<String>? insightFingerprint,
    Value<String>? ruleId,
    Value<int>? ruleVersion,
    Value<String>? response,
    Value<DateTime?>? snoozedUntilUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return CoachFeedbackCompanion(
      insightFingerprint: insightFingerprint ?? this.insightFingerprint,
      ruleId: ruleId ?? this.ruleId,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      response: response ?? this.response,
      snoozedUntilUtc: snoozedUntilUtc ?? this.snoozedUntilUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (insightFingerprint.present) {
      map['insight_fingerprint'] = Variable<String>(insightFingerprint.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<int>(ruleVersion.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (snoozedUntilUtc.present) {
      map['snoozed_until_utc'] = Variable<DateTime>(snoozedUntilUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachFeedbackCompanion(')
          ..write('insightFingerprint: $insightFingerprint, ')
          ..write('ruleId: $ruleId, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('response: $response, ')
          ..write('snoozedUntilUtc: $snoozedUntilUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, PreferenceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceRecord> instance, {
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
  PreferenceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceRecord(
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
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class PreferenceRecord extends DataClass
    implements Insertable<PreferenceRecord> {
  final String key;
  final String value;
  const PreferenceRecord({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory PreferenceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceRecord(
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

  PreferenceRecord copyWith({String? key, String? value}) =>
      PreferenceRecord(key: key ?? this.key, value: value ?? this.value);
  PreferenceRecord copyWithCompanion(PreferencesCompanion data) {
    return PreferenceRecord(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceRecord(')
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
      (other is PreferenceRecord &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<PreferenceRecord> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PreferenceRecord> custom({
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

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
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
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TargetProfilesTable extends TargetProfiles
    with TableInfo<$TargetProfilesTable, TargetProfileRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TargetProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionedIdMeta = const VerificationMeta(
    'versionedId',
  );
  @override
  late final GeneratedColumn<String> versionedId = GeneratedColumn<String>(
    'versioned_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileVersionMeta = const VerificationMeta(
    'profileVersion',
  );
  @override
  late final GeneratedColumn<int> profileVersion = GeneratedColumn<int>(
    'profile_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validationStatusMeta = const VerificationMeta(
    'validationStatus',
  );
  @override
  late final GeneratedColumn<String> validationStatus = GeneratedColumn<String>(
    'validation_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    versionedId,
    profileId,
    profileVersion,
    displayName,
    validationStatus,
    profileJson,
    builtIn,
    archived,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'target_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<TargetProfileRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('versioned_id')) {
      context.handle(
        _versionedIdMeta,
        versionedId.isAcceptableOrUnknown(
          data['versioned_id']!,
          _versionedIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionedIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('profile_version')) {
      context.handle(
        _profileVersionMeta,
        profileVersion.isAcceptableOrUnknown(
          data['profile_version']!,
          _profileVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileVersionMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('validation_status')) {
      context.handle(
        _validationStatusMeta,
        validationStatus.isAcceptableOrUnknown(
          data['validation_status']!,
          _validationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validationStatusMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {versionedId};
  @override
  TargetProfileRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TargetProfileRecord(
      versionedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versioned_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      profileVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_version'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      validationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation_status'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $TargetProfilesTable createAlias(String alias) {
    return $TargetProfilesTable(attachedDatabase, alias);
  }
}

class TargetProfileRecord extends DataClass
    implements Insertable<TargetProfileRecord> {
  final String versionedId;
  final String profileId;
  final int profileVersion;
  final String displayName;
  final String validationStatus;
  final String profileJson;
  final bool builtIn;
  final bool archived;
  final DateTime createdAtUtc;
  const TargetProfileRecord({
    required this.versionedId,
    required this.profileId,
    required this.profileVersion,
    required this.displayName,
    required this.validationStatus,
    required this.profileJson,
    required this.builtIn,
    required this.archived,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['versioned_id'] = Variable<String>(versionedId);
    map['profile_id'] = Variable<String>(profileId);
    map['profile_version'] = Variable<int>(profileVersion);
    map['display_name'] = Variable<String>(displayName);
    map['validation_status'] = Variable<String>(validationStatus);
    map['profile_json'] = Variable<String>(profileJson);
    map['built_in'] = Variable<bool>(builtIn);
    map['archived'] = Variable<bool>(archived);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  TargetProfilesCompanion toCompanion(bool nullToAbsent) {
    return TargetProfilesCompanion(
      versionedId: Value(versionedId),
      profileId: Value(profileId),
      profileVersion: Value(profileVersion),
      displayName: Value(displayName),
      validationStatus: Value(validationStatus),
      profileJson: Value(profileJson),
      builtIn: Value(builtIn),
      archived: Value(archived),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory TargetProfileRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TargetProfileRecord(
      versionedId: serializer.fromJson<String>(json['versionedId']),
      profileId: serializer.fromJson<String>(json['profileId']),
      profileVersion: serializer.fromJson<int>(json['profileVersion']),
      displayName: serializer.fromJson<String>(json['displayName']),
      validationStatus: serializer.fromJson<String>(json['validationStatus']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'versionedId': serializer.toJson<String>(versionedId),
      'profileId': serializer.toJson<String>(profileId),
      'profileVersion': serializer.toJson<int>(profileVersion),
      'displayName': serializer.toJson<String>(displayName),
      'validationStatus': serializer.toJson<String>(validationStatus),
      'profileJson': serializer.toJson<String>(profileJson),
      'builtIn': serializer.toJson<bool>(builtIn),
      'archived': serializer.toJson<bool>(archived),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  TargetProfileRecord copyWith({
    String? versionedId,
    String? profileId,
    int? profileVersion,
    String? displayName,
    String? validationStatus,
    String? profileJson,
    bool? builtIn,
    bool? archived,
    DateTime? createdAtUtc,
  }) => TargetProfileRecord(
    versionedId: versionedId ?? this.versionedId,
    profileId: profileId ?? this.profileId,
    profileVersion: profileVersion ?? this.profileVersion,
    displayName: displayName ?? this.displayName,
    validationStatus: validationStatus ?? this.validationStatus,
    profileJson: profileJson ?? this.profileJson,
    builtIn: builtIn ?? this.builtIn,
    archived: archived ?? this.archived,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  TargetProfileRecord copyWithCompanion(TargetProfilesCompanion data) {
    return TargetProfileRecord(
      versionedId: data.versionedId.present
          ? data.versionedId.value
          : this.versionedId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      profileVersion: data.profileVersion.present
          ? data.profileVersion.value
          : this.profileVersion,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      validationStatus: data.validationStatus.present
          ? data.validationStatus.value
          : this.validationStatus,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TargetProfileRecord(')
          ..write('versionedId: $versionedId, ')
          ..write('profileId: $profileId, ')
          ..write('profileVersion: $profileVersion, ')
          ..write('displayName: $displayName, ')
          ..write('validationStatus: $validationStatus, ')
          ..write('profileJson: $profileJson, ')
          ..write('builtIn: $builtIn, ')
          ..write('archived: $archived, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    versionedId,
    profileId,
    profileVersion,
    displayName,
    validationStatus,
    profileJson,
    builtIn,
    archived,
    createdAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TargetProfileRecord &&
          other.versionedId == this.versionedId &&
          other.profileId == this.profileId &&
          other.profileVersion == this.profileVersion &&
          other.displayName == this.displayName &&
          other.validationStatus == this.validationStatus &&
          other.profileJson == this.profileJson &&
          other.builtIn == this.builtIn &&
          other.archived == this.archived &&
          other.createdAtUtc == this.createdAtUtc);
}

class TargetProfilesCompanion extends UpdateCompanion<TargetProfileRecord> {
  final Value<String> versionedId;
  final Value<String> profileId;
  final Value<int> profileVersion;
  final Value<String> displayName;
  final Value<String> validationStatus;
  final Value<String> profileJson;
  final Value<bool> builtIn;
  final Value<bool> archived;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const TargetProfilesCompanion({
    this.versionedId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.profileVersion = const Value.absent(),
    this.displayName = const Value.absent(),
    this.validationStatus = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TargetProfilesCompanion.insert({
    required String versionedId,
    required String profileId,
    required int profileVersion,
    required String displayName,
    required String validationStatus,
    required String profileJson,
    this.builtIn = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : versionedId = Value(versionedId),
       profileId = Value(profileId),
       profileVersion = Value(profileVersion),
       displayName = Value(displayName),
       validationStatus = Value(validationStatus),
       profileJson = Value(profileJson),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<TargetProfileRecord> custom({
    Expression<String>? versionedId,
    Expression<String>? profileId,
    Expression<int>? profileVersion,
    Expression<String>? displayName,
    Expression<String>? validationStatus,
    Expression<String>? profileJson,
    Expression<bool>? builtIn,
    Expression<bool>? archived,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (versionedId != null) 'versioned_id': versionedId,
      if (profileId != null) 'profile_id': profileId,
      if (profileVersion != null) 'profile_version': profileVersion,
      if (displayName != null) 'display_name': displayName,
      if (validationStatus != null) 'validation_status': validationStatus,
      if (profileJson != null) 'profile_json': profileJson,
      if (builtIn != null) 'built_in': builtIn,
      if (archived != null) 'archived': archived,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TargetProfilesCompanion copyWith({
    Value<String>? versionedId,
    Value<String>? profileId,
    Value<int>? profileVersion,
    Value<String>? displayName,
    Value<String>? validationStatus,
    Value<String>? profileJson,
    Value<bool>? builtIn,
    Value<bool>? archived,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return TargetProfilesCompanion(
      versionedId: versionedId ?? this.versionedId,
      profileId: profileId ?? this.profileId,
      profileVersion: profileVersion ?? this.profileVersion,
      displayName: displayName ?? this.displayName,
      validationStatus: validationStatus ?? this.validationStatus,
      profileJson: profileJson ?? this.profileJson,
      builtIn: builtIn ?? this.builtIn,
      archived: archived ?? this.archived,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (versionedId.present) {
      map['versioned_id'] = Variable<String>(versionedId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (profileVersion.present) {
      map['profile_version'] = Variable<int>(profileVersion.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (validationStatus.present) {
      map['validation_status'] = Variable<String>(validationStatus.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TargetProfilesCompanion(')
          ..write('versionedId: $versionedId, ')
          ..write('profileId: $profileId, ')
          ..write('profileVersion: $profileVersion, ')
          ..write('displayName: $displayName, ')
          ..write('validationStatus: $validationStatus, ')
          ..write('profileJson: $profileJson, ')
          ..write('builtIn: $builtIn, ')
          ..write('archived: $archived, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainingActivitiesTable extends TrainingActivities
    with TableInfo<$TrainingActivitiesTable, TrainingActivityRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingActivitiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES training_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _configurationJsonMeta = const VerificationMeta(
    'configurationJson',
  );
  @override
  late final GeneratedColumn<String> configurationJson =
      GeneratedColumn<String>(
        'configuration_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectorVersionMeta = const VerificationMeta(
    'detectorVersion',
  );
  @override
  late final GeneratedColumn<String> detectorVersion = GeneratedColumn<String>(
    'detector_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtUtcMeta = const VerificationMeta(
    'startedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startedAtUtc = GeneratedColumn<DateTime>(
    'started_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUtcOffsetMinutesMeta =
      const VerificationMeta('localUtcOffsetMinutes');
  @override
  late final GeneratedColumn<int> localUtcOffsetMinutes = GeneratedColumn<int>(
    'local_utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtUtcMeta = const VerificationMeta(
    'completedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> completedAtUtc =
      GeneratedColumn<DateTime>(
        'completed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    schemaVersion,
    status,
    sessionId,
    configurationJson,
    summaryJson,
    detectorVersion,
    startedAtUtc,
    localUtcOffsetMinutes,
    completedAtUtc,
    notes,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainingActivityRecord> instance, {
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
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
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
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('configuration_json')) {
      context.handle(
        _configurationJsonMeta,
        configurationJson.isAcceptableOrUnknown(
          data['configuration_json']!,
          _configurationJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationJsonMeta);
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summaryJsonMeta);
    }
    if (data.containsKey('detector_version')) {
      context.handle(
        _detectorVersionMeta,
        detectorVersion.isAcceptableOrUnknown(
          data['detector_version']!,
          _detectorVersionMeta,
        ),
      );
    }
    if (data.containsKey('started_at_utc')) {
      context.handle(
        _startedAtUtcMeta,
        startedAtUtc.isAcceptableOrUnknown(
          data['started_at_utc']!,
          _startedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtUtcMeta);
    }
    if (data.containsKey('local_utc_offset_minutes')) {
      context.handle(
        _localUtcOffsetMinutesMeta,
        localUtcOffsetMinutes.isAcceptableOrUnknown(
          data['local_utc_offset_minutes']!,
          _localUtcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUtcOffsetMinutesMeta);
    }
    if (data.containsKey('completed_at_utc')) {
      context.handle(
        _completedAtUtcMeta,
        completedAtUtc.isAcceptableOrUnknown(
          data['completed_at_utc']!,
          _completedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingActivityRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingActivityRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      configurationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration_json'],
      )!,
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      )!,
      detectorVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detector_version'],
      ),
      startedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at_utc'],
      )!,
      localUtcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_utc_offset_minutes'],
      )!,
      completedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at_utc'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TrainingActivitiesTable createAlias(String alias) {
    return $TrainingActivitiesTable(attachedDatabase, alias);
  }
}

class TrainingActivityRecord extends DataClass
    implements Insertable<TrainingActivityRecord> {
  final String id;
  final String kind;
  final int schemaVersion;
  final String status;
  final String? sessionId;
  final String configurationJson;
  final String summaryJson;
  final String? detectorVersion;
  final DateTime startedAtUtc;
  final int localUtcOffsetMinutes;
  final DateTime? completedAtUtc;
  final String? notes;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TrainingActivityRecord({
    required this.id,
    required this.kind,
    required this.schemaVersion,
    required this.status,
    this.sessionId,
    required this.configurationJson,
    required this.summaryJson,
    this.detectorVersion,
    required this.startedAtUtc,
    required this.localUtcOffsetMinutes,
    this.completedAtUtc,
    this.notes,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['configuration_json'] = Variable<String>(configurationJson);
    map['summary_json'] = Variable<String>(summaryJson);
    if (!nullToAbsent || detectorVersion != null) {
      map['detector_version'] = Variable<String>(detectorVersion);
    }
    map['started_at_utc'] = Variable<DateTime>(startedAtUtc);
    map['local_utc_offset_minutes'] = Variable<int>(localUtcOffsetMinutes);
    if (!nullToAbsent || completedAtUtc != null) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TrainingActivitiesCompanion toCompanion(bool nullToAbsent) {
    return TrainingActivitiesCompanion(
      id: Value(id),
      kind: Value(kind),
      schemaVersion: Value(schemaVersion),
      status: Value(status),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      configurationJson: Value(configurationJson),
      summaryJson: Value(summaryJson),
      detectorVersion: detectorVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(detectorVersion),
      startedAtUtc: Value(startedAtUtc),
      localUtcOffsetMinutes: Value(localUtcOffsetMinutes),
      completedAtUtc: completedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtc),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TrainingActivityRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingActivityRecord(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      status: serializer.fromJson<String>(json['status']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      configurationJson: serializer.fromJson<String>(json['configurationJson']),
      summaryJson: serializer.fromJson<String>(json['summaryJson']),
      detectorVersion: serializer.fromJson<String?>(json['detectorVersion']),
      startedAtUtc: serializer.fromJson<DateTime>(json['startedAtUtc']),
      localUtcOffsetMinutes: serializer.fromJson<int>(
        json['localUtcOffsetMinutes'],
      ),
      completedAtUtc: serializer.fromJson<DateTime?>(json['completedAtUtc']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'status': serializer.toJson<String>(status),
      'sessionId': serializer.toJson<String?>(sessionId),
      'configurationJson': serializer.toJson<String>(configurationJson),
      'summaryJson': serializer.toJson<String>(summaryJson),
      'detectorVersion': serializer.toJson<String?>(detectorVersion),
      'startedAtUtc': serializer.toJson<DateTime>(startedAtUtc),
      'localUtcOffsetMinutes': serializer.toJson<int>(localUtcOffsetMinutes),
      'completedAtUtc': serializer.toJson<DateTime?>(completedAtUtc),
      'notes': serializer.toJson<String?>(notes),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TrainingActivityRecord copyWith({
    String? id,
    String? kind,
    int? schemaVersion,
    String? status,
    Value<String?> sessionId = const Value.absent(),
    String? configurationJson,
    String? summaryJson,
    Value<String?> detectorVersion = const Value.absent(),
    DateTime? startedAtUtc,
    int? localUtcOffsetMinutes,
    Value<DateTime?> completedAtUtc = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TrainingActivityRecord(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    status: status ?? this.status,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    configurationJson: configurationJson ?? this.configurationJson,
    summaryJson: summaryJson ?? this.summaryJson,
    detectorVersion: detectorVersion.present
        ? detectorVersion.value
        : this.detectorVersion,
    startedAtUtc: startedAtUtc ?? this.startedAtUtc,
    localUtcOffsetMinutes: localUtcOffsetMinutes ?? this.localUtcOffsetMinutes,
    completedAtUtc: completedAtUtc.present
        ? completedAtUtc.value
        : this.completedAtUtc,
    notes: notes.present ? notes.value : this.notes,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TrainingActivityRecord copyWithCompanion(TrainingActivitiesCompanion data) {
    return TrainingActivityRecord(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      status: data.status.present ? data.status.value : this.status,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      configurationJson: data.configurationJson.present
          ? data.configurationJson.value
          : this.configurationJson,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      detectorVersion: data.detectorVersion.present
          ? data.detectorVersion.value
          : this.detectorVersion,
      startedAtUtc: data.startedAtUtc.present
          ? data.startedAtUtc.value
          : this.startedAtUtc,
      localUtcOffsetMinutes: data.localUtcOffsetMinutes.present
          ? data.localUtcOffsetMinutes.value
          : this.localUtcOffsetMinutes,
      completedAtUtc: data.completedAtUtc.present
          ? data.completedAtUtc.value
          : this.completedAtUtc,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingActivityRecord(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('status: $status, ')
          ..write('sessionId: $sessionId, ')
          ..write('configurationJson: $configurationJson, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('detectorVersion: $detectorVersion, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('localUtcOffsetMinutes: $localUtcOffsetMinutes, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('notes: $notes, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    schemaVersion,
    status,
    sessionId,
    configurationJson,
    summaryJson,
    detectorVersion,
    startedAtUtc,
    localUtcOffsetMinutes,
    completedAtUtc,
    notes,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingActivityRecord &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.schemaVersion == this.schemaVersion &&
          other.status == this.status &&
          other.sessionId == this.sessionId &&
          other.configurationJson == this.configurationJson &&
          other.summaryJson == this.summaryJson &&
          other.detectorVersion == this.detectorVersion &&
          other.startedAtUtc == this.startedAtUtc &&
          other.localUtcOffsetMinutes == this.localUtcOffsetMinutes &&
          other.completedAtUtc == this.completedAtUtc &&
          other.notes == this.notes &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TrainingActivitiesCompanion
    extends UpdateCompanion<TrainingActivityRecord> {
  final Value<String> id;
  final Value<String> kind;
  final Value<int> schemaVersion;
  final Value<String> status;
  final Value<String?> sessionId;
  final Value<String> configurationJson;
  final Value<String> summaryJson;
  final Value<String?> detectorVersion;
  final Value<DateTime> startedAtUtc;
  final Value<int> localUtcOffsetMinutes;
  final Value<DateTime?> completedAtUtc;
  final Value<String?> notes;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TrainingActivitiesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.configurationJson = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.detectorVersion = const Value.absent(),
    this.startedAtUtc = const Value.absent(),
    this.localUtcOffsetMinutes = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainingActivitiesCompanion.insert({
    required String id,
    required String kind,
    this.schemaVersion = const Value.absent(),
    required String status,
    this.sessionId = const Value.absent(),
    required String configurationJson,
    required String summaryJson,
    this.detectorVersion = const Value.absent(),
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
    this.completedAtUtc = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       status = Value(status),
       configurationJson = Value(configurationJson),
       summaryJson = Value(summaryJson),
       startedAtUtc = Value(startedAtUtc),
       localUtcOffsetMinutes = Value(localUtcOffsetMinutes),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TrainingActivityRecord> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? schemaVersion,
    Expression<String>? status,
    Expression<String>? sessionId,
    Expression<String>? configurationJson,
    Expression<String>? summaryJson,
    Expression<String>? detectorVersion,
    Expression<DateTime>? startedAtUtc,
    Expression<int>? localUtcOffsetMinutes,
    Expression<DateTime>? completedAtUtc,
    Expression<String>? notes,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (status != null) 'status': status,
      if (sessionId != null) 'session_id': sessionId,
      if (configurationJson != null) 'configuration_json': configurationJson,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (detectorVersion != null) 'detector_version': detectorVersion,
      if (startedAtUtc != null) 'started_at_utc': startedAtUtc,
      if (localUtcOffsetMinutes != null)
        'local_utc_offset_minutes': localUtcOffsetMinutes,
      if (completedAtUtc != null) 'completed_at_utc': completedAtUtc,
      if (notes != null) 'notes': notes,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainingActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<int>? schemaVersion,
    Value<String>? status,
    Value<String?>? sessionId,
    Value<String>? configurationJson,
    Value<String>? summaryJson,
    Value<String?>? detectorVersion,
    Value<DateTime>? startedAtUtc,
    Value<int>? localUtcOffsetMinutes,
    Value<DateTime?>? completedAtUtc,
    Value<String?>? notes,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TrainingActivitiesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      configurationJson: configurationJson ?? this.configurationJson,
      summaryJson: summaryJson ?? this.summaryJson,
      detectorVersion: detectorVersion ?? this.detectorVersion,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      localUtcOffsetMinutes:
          localUtcOffsetMinutes ?? this.localUtcOffsetMinutes,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      notes: notes ?? this.notes,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
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
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (configurationJson.present) {
      map['configuration_json'] = Variable<String>(configurationJson.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (detectorVersion.present) {
      map['detector_version'] = Variable<String>(detectorVersion.value);
    }
    if (startedAtUtc.present) {
      map['started_at_utc'] = Variable<DateTime>(startedAtUtc.value);
    }
    if (localUtcOffsetMinutes.present) {
      map['local_utc_offset_minutes'] = Variable<int>(
        localUtcOffsetMinutes.value,
      );
    }
    if (completedAtUtc.present) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('status: $status, ')
          ..write('sessionId: $sessionId, ')
          ..write('configurationJson: $configurationJson, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('detectorVersion: $detectorVersion, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('localUtcOffsetMinutes: $localUtcOffsetMinutes, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('notes: $notes, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainingActivitySeriesLinksTable extends TrainingActivitySeriesLinks
    with
        TableInfo<
          $TrainingActivitySeriesLinksTable,
          TrainingActivitySeriesLinkRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingActivitySeriesLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES training_activities (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shooting_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    activityId,
    seriesId,
    sequenceNumber,
    role,
    variantId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_activity_series_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainingActivitySeriesLinkRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {activityId, seriesId};
  @override
  TrainingActivitySeriesLinkRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingActivitySeriesLinkRecord(
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      ),
    );
  }

  @override
  $TrainingActivitySeriesLinksTable createAlias(String alias) {
    return $TrainingActivitySeriesLinksTable(attachedDatabase, alias);
  }
}

class TrainingActivitySeriesLinkRecord extends DataClass
    implements Insertable<TrainingActivitySeriesLinkRecord> {
  final String activityId;
  final String seriesId;
  final int sequenceNumber;
  final String? role;
  final String? variantId;
  const TrainingActivitySeriesLinkRecord({
    required this.activityId,
    required this.seriesId,
    required this.sequenceNumber,
    this.role,
    this.variantId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['activity_id'] = Variable<String>(activityId);
    map['series_id'] = Variable<String>(seriesId);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    return map;
  }

  TrainingActivitySeriesLinksCompanion toCompanion(bool nullToAbsent) {
    return TrainingActivitySeriesLinksCompanion(
      activityId: Value(activityId),
      seriesId: Value(seriesId),
      sequenceNumber: Value(sequenceNumber),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
    );
  }

  factory TrainingActivitySeriesLinkRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingActivitySeriesLinkRecord(
      activityId: serializer.fromJson<String>(json['activityId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      role: serializer.fromJson<String?>(json['role']),
      variantId: serializer.fromJson<String?>(json['variantId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'activityId': serializer.toJson<String>(activityId),
      'seriesId': serializer.toJson<String>(seriesId),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'role': serializer.toJson<String?>(role),
      'variantId': serializer.toJson<String?>(variantId),
    };
  }

  TrainingActivitySeriesLinkRecord copyWith({
    String? activityId,
    String? seriesId,
    int? sequenceNumber,
    Value<String?> role = const Value.absent(),
    Value<String?> variantId = const Value.absent(),
  }) => TrainingActivitySeriesLinkRecord(
    activityId: activityId ?? this.activityId,
    seriesId: seriesId ?? this.seriesId,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    role: role.present ? role.value : this.role,
    variantId: variantId.present ? variantId.value : this.variantId,
  );
  TrainingActivitySeriesLinkRecord copyWithCompanion(
    TrainingActivitySeriesLinksCompanion data,
  ) {
    return TrainingActivitySeriesLinkRecord(
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      role: data.role.present ? data.role.value : this.role,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingActivitySeriesLinkRecord(')
          ..write('activityId: $activityId, ')
          ..write('seriesId: $seriesId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('role: $role, ')
          ..write('variantId: $variantId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(activityId, seriesId, sequenceNumber, role, variantId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingActivitySeriesLinkRecord &&
          other.activityId == this.activityId &&
          other.seriesId == this.seriesId &&
          other.sequenceNumber == this.sequenceNumber &&
          other.role == this.role &&
          other.variantId == this.variantId);
}

class TrainingActivitySeriesLinksCompanion
    extends UpdateCompanion<TrainingActivitySeriesLinkRecord> {
  final Value<String> activityId;
  final Value<String> seriesId;
  final Value<int> sequenceNumber;
  final Value<String?> role;
  final Value<String?> variantId;
  final Value<int> rowid;
  const TrainingActivitySeriesLinksCompanion({
    this.activityId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.role = const Value.absent(),
    this.variantId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainingActivitySeriesLinksCompanion.insert({
    required String activityId,
    required String seriesId,
    required int sequenceNumber,
    this.role = const Value.absent(),
    this.variantId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : activityId = Value(activityId),
       seriesId = Value(seriesId),
       sequenceNumber = Value(sequenceNumber);
  static Insertable<TrainingActivitySeriesLinkRecord> custom({
    Expression<String>? activityId,
    Expression<String>? seriesId,
    Expression<int>? sequenceNumber,
    Expression<String>? role,
    Expression<String>? variantId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (activityId != null) 'activity_id': activityId,
      if (seriesId != null) 'series_id': seriesId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (role != null) 'role': role,
      if (variantId != null) 'variant_id': variantId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainingActivitySeriesLinksCompanion copyWith({
    Value<String>? activityId,
    Value<String>? seriesId,
    Value<int>? sequenceNumber,
    Value<String?>? role,
    Value<String?>? variantId,
    Value<int>? rowid,
  }) {
    return TrainingActivitySeriesLinksCompanion(
      activityId: activityId ?? this.activityId,
      seriesId: seriesId ?? this.seriesId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      role: role ?? this.role,
      variantId: variantId ?? this.variantId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingActivitySeriesLinksCompanion(')
          ..write('activityId: $activityId, ')
          ..write('seriesId: $seriesId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('role: $role, ')
          ..write('variantId: $variantId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShotTimerEventsTable extends ShotTimerEvents
    with TableInfo<$ShotTimerEventsTable, ShotTimerEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotTimerEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES training_activities (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMicrosecondsMeta =
      const VerificationMeta('elapsedMicroseconds');
  @override
  late final GeneratedColumn<int> elapsedMicroseconds = GeneratedColumn<int>(
    'elapsed_microseconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitMicrosecondsMeta = const VerificationMeta(
    'splitMicroseconds',
  );
  @override
  late final GeneratedColumn<int> splitMicroseconds = GeneratedColumn<int>(
    'split_microseconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dispositionMeta = const VerificationMeta(
    'disposition',
  );
  @override
  late final GeneratedColumn<String> disposition = GeneratedColumn<String>(
    'disposition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedPeakMeta = const VerificationMeta(
    'normalizedPeak',
  );
  @override
  late final GeneratedColumn<double> normalizedPeak = GeneratedColumn<double>(
    'normalized_peak',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detectionQualityMeta = const VerificationMeta(
    'detectionQuality',
  );
  @override
  late final GeneratedColumn<String> detectionQuality = GeneratedColumn<String>(
    'detection_quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exclusionReasonMeta = const VerificationMeta(
    'exclusionReason',
  );
  @override
  late final GeneratedColumn<String> exclusionReason = GeneratedColumn<String>(
    'exclusion_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    sequenceNumber,
    elapsedMicroseconds,
    splitMicroseconds,
    source,
    disposition,
    normalizedPeak,
    detectionQuality,
    exclusionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shot_timer_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShotTimerEventRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('elapsed_microseconds')) {
      context.handle(
        _elapsedMicrosecondsMeta,
        elapsedMicroseconds.isAcceptableOrUnknown(
          data['elapsed_microseconds']!,
          _elapsedMicrosecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elapsedMicrosecondsMeta);
    }
    if (data.containsKey('split_microseconds')) {
      context.handle(
        _splitMicrosecondsMeta,
        splitMicroseconds.isAcceptableOrUnknown(
          data['split_microseconds']!,
          _splitMicrosecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitMicrosecondsMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('disposition')) {
      context.handle(
        _dispositionMeta,
        disposition.isAcceptableOrUnknown(
          data['disposition']!,
          _dispositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dispositionMeta);
    }
    if (data.containsKey('normalized_peak')) {
      context.handle(
        _normalizedPeakMeta,
        normalizedPeak.isAcceptableOrUnknown(
          data['normalized_peak']!,
          _normalizedPeakMeta,
        ),
      );
    }
    if (data.containsKey('detection_quality')) {
      context.handle(
        _detectionQualityMeta,
        detectionQuality.isAcceptableOrUnknown(
          data['detection_quality']!,
          _detectionQualityMeta,
        ),
      );
    }
    if (data.containsKey('exclusion_reason')) {
      context.handle(
        _exclusionReasonMeta,
        exclusionReason.isAcceptableOrUnknown(
          data['exclusion_reason']!,
          _exclusionReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShotTimerEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShotTimerEventRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      elapsedMicroseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_microseconds'],
      )!,
      splitMicroseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_microseconds'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      disposition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disposition'],
      )!,
      normalizedPeak: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}normalized_peak'],
      ),
      detectionQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detection_quality'],
      ),
      exclusionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exclusion_reason'],
      ),
    );
  }

  @override
  $ShotTimerEventsTable createAlias(String alias) {
    return $ShotTimerEventsTable(attachedDatabase, alias);
  }
}

class ShotTimerEventRecord extends DataClass
    implements Insertable<ShotTimerEventRecord> {
  final String id;
  final String activityId;
  final int sequenceNumber;
  final int elapsedMicroseconds;
  final int splitMicroseconds;
  final String source;
  final String disposition;
  final double? normalizedPeak;
  final String? detectionQuality;
  final String? exclusionReason;
  const ShotTimerEventRecord({
    required this.id,
    required this.activityId,
    required this.sequenceNumber,
    required this.elapsedMicroseconds,
    required this.splitMicroseconds,
    required this.source,
    required this.disposition,
    this.normalizedPeak,
    this.detectionQuality,
    this.exclusionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_id'] = Variable<String>(activityId);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['elapsed_microseconds'] = Variable<int>(elapsedMicroseconds);
    map['split_microseconds'] = Variable<int>(splitMicroseconds);
    map['source'] = Variable<String>(source);
    map['disposition'] = Variable<String>(disposition);
    if (!nullToAbsent || normalizedPeak != null) {
      map['normalized_peak'] = Variable<double>(normalizedPeak);
    }
    if (!nullToAbsent || detectionQuality != null) {
      map['detection_quality'] = Variable<String>(detectionQuality);
    }
    if (!nullToAbsent || exclusionReason != null) {
      map['exclusion_reason'] = Variable<String>(exclusionReason);
    }
    return map;
  }

  ShotTimerEventsCompanion toCompanion(bool nullToAbsent) {
    return ShotTimerEventsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      sequenceNumber: Value(sequenceNumber),
      elapsedMicroseconds: Value(elapsedMicroseconds),
      splitMicroseconds: Value(splitMicroseconds),
      source: Value(source),
      disposition: Value(disposition),
      normalizedPeak: normalizedPeak == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedPeak),
      detectionQuality: detectionQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(detectionQuality),
      exclusionReason: exclusionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(exclusionReason),
    );
  }

  factory ShotTimerEventRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShotTimerEventRecord(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String>(json['activityId']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      elapsedMicroseconds: serializer.fromJson<int>(
        json['elapsedMicroseconds'],
      ),
      splitMicroseconds: serializer.fromJson<int>(json['splitMicroseconds']),
      source: serializer.fromJson<String>(json['source']),
      disposition: serializer.fromJson<String>(json['disposition']),
      normalizedPeak: serializer.fromJson<double?>(json['normalizedPeak']),
      detectionQuality: serializer.fromJson<String?>(json['detectionQuality']),
      exclusionReason: serializer.fromJson<String?>(json['exclusionReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String>(activityId),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'elapsedMicroseconds': serializer.toJson<int>(elapsedMicroseconds),
      'splitMicroseconds': serializer.toJson<int>(splitMicroseconds),
      'source': serializer.toJson<String>(source),
      'disposition': serializer.toJson<String>(disposition),
      'normalizedPeak': serializer.toJson<double?>(normalizedPeak),
      'detectionQuality': serializer.toJson<String?>(detectionQuality),
      'exclusionReason': serializer.toJson<String?>(exclusionReason),
    };
  }

  ShotTimerEventRecord copyWith({
    String? id,
    String? activityId,
    int? sequenceNumber,
    int? elapsedMicroseconds,
    int? splitMicroseconds,
    String? source,
    String? disposition,
    Value<double?> normalizedPeak = const Value.absent(),
    Value<String?> detectionQuality = const Value.absent(),
    Value<String?> exclusionReason = const Value.absent(),
  }) => ShotTimerEventRecord(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    elapsedMicroseconds: elapsedMicroseconds ?? this.elapsedMicroseconds,
    splitMicroseconds: splitMicroseconds ?? this.splitMicroseconds,
    source: source ?? this.source,
    disposition: disposition ?? this.disposition,
    normalizedPeak: normalizedPeak.present
        ? normalizedPeak.value
        : this.normalizedPeak,
    detectionQuality: detectionQuality.present
        ? detectionQuality.value
        : this.detectionQuality,
    exclusionReason: exclusionReason.present
        ? exclusionReason.value
        : this.exclusionReason,
  );
  ShotTimerEventRecord copyWithCompanion(ShotTimerEventsCompanion data) {
    return ShotTimerEventRecord(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      elapsedMicroseconds: data.elapsedMicroseconds.present
          ? data.elapsedMicroseconds.value
          : this.elapsedMicroseconds,
      splitMicroseconds: data.splitMicroseconds.present
          ? data.splitMicroseconds.value
          : this.splitMicroseconds,
      source: data.source.present ? data.source.value : this.source,
      disposition: data.disposition.present
          ? data.disposition.value
          : this.disposition,
      normalizedPeak: data.normalizedPeak.present
          ? data.normalizedPeak.value
          : this.normalizedPeak,
      detectionQuality: data.detectionQuality.present
          ? data.detectionQuality.value
          : this.detectionQuality,
      exclusionReason: data.exclusionReason.present
          ? data.exclusionReason.value
          : this.exclusionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShotTimerEventRecord(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('elapsedMicroseconds: $elapsedMicroseconds, ')
          ..write('splitMicroseconds: $splitMicroseconds, ')
          ..write('source: $source, ')
          ..write('disposition: $disposition, ')
          ..write('normalizedPeak: $normalizedPeak, ')
          ..write('detectionQuality: $detectionQuality, ')
          ..write('exclusionReason: $exclusionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    sequenceNumber,
    elapsedMicroseconds,
    splitMicroseconds,
    source,
    disposition,
    normalizedPeak,
    detectionQuality,
    exclusionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShotTimerEventRecord &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.sequenceNumber == this.sequenceNumber &&
          other.elapsedMicroseconds == this.elapsedMicroseconds &&
          other.splitMicroseconds == this.splitMicroseconds &&
          other.source == this.source &&
          other.disposition == this.disposition &&
          other.normalizedPeak == this.normalizedPeak &&
          other.detectionQuality == this.detectionQuality &&
          other.exclusionReason == this.exclusionReason);
}

class ShotTimerEventsCompanion extends UpdateCompanion<ShotTimerEventRecord> {
  final Value<String> id;
  final Value<String> activityId;
  final Value<int> sequenceNumber;
  final Value<int> elapsedMicroseconds;
  final Value<int> splitMicroseconds;
  final Value<String> source;
  final Value<String> disposition;
  final Value<double?> normalizedPeak;
  final Value<String?> detectionQuality;
  final Value<String?> exclusionReason;
  final Value<int> rowid;
  const ShotTimerEventsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.elapsedMicroseconds = const Value.absent(),
    this.splitMicroseconds = const Value.absent(),
    this.source = const Value.absent(),
    this.disposition = const Value.absent(),
    this.normalizedPeak = const Value.absent(),
    this.detectionQuality = const Value.absent(),
    this.exclusionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShotTimerEventsCompanion.insert({
    required String id,
    required String activityId,
    required int sequenceNumber,
    required int elapsedMicroseconds,
    required int splitMicroseconds,
    required String source,
    required String disposition,
    this.normalizedPeak = const Value.absent(),
    this.detectionQuality = const Value.absent(),
    this.exclusionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activityId = Value(activityId),
       sequenceNumber = Value(sequenceNumber),
       elapsedMicroseconds = Value(elapsedMicroseconds),
       splitMicroseconds = Value(splitMicroseconds),
       source = Value(source),
       disposition = Value(disposition);
  static Insertable<ShotTimerEventRecord> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<int>? sequenceNumber,
    Expression<int>? elapsedMicroseconds,
    Expression<int>? splitMicroseconds,
    Expression<String>? source,
    Expression<String>? disposition,
    Expression<double>? normalizedPeak,
    Expression<String>? detectionQuality,
    Expression<String>? exclusionReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (elapsedMicroseconds != null)
        'elapsed_microseconds': elapsedMicroseconds,
      if (splitMicroseconds != null) 'split_microseconds': splitMicroseconds,
      if (source != null) 'source': source,
      if (disposition != null) 'disposition': disposition,
      if (normalizedPeak != null) 'normalized_peak': normalizedPeak,
      if (detectionQuality != null) 'detection_quality': detectionQuality,
      if (exclusionReason != null) 'exclusion_reason': exclusionReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShotTimerEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? activityId,
    Value<int>? sequenceNumber,
    Value<int>? elapsedMicroseconds,
    Value<int>? splitMicroseconds,
    Value<String>? source,
    Value<String>? disposition,
    Value<double?>? normalizedPeak,
    Value<String?>? detectionQuality,
    Value<String?>? exclusionReason,
    Value<int>? rowid,
  }) {
    return ShotTimerEventsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      elapsedMicroseconds: elapsedMicroseconds ?? this.elapsedMicroseconds,
      splitMicroseconds: splitMicroseconds ?? this.splitMicroseconds,
      source: source ?? this.source,
      disposition: disposition ?? this.disposition,
      normalizedPeak: normalizedPeak ?? this.normalizedPeak,
      detectionQuality: detectionQuality ?? this.detectionQuality,
      exclusionReason: exclusionReason ?? this.exclusionReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (elapsedMicroseconds.present) {
      map['elapsed_microseconds'] = Variable<int>(elapsedMicroseconds.value);
    }
    if (splitMicroseconds.present) {
      map['split_microseconds'] = Variable<int>(splitMicroseconds.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (disposition.present) {
      map['disposition'] = Variable<String>(disposition.value);
    }
    if (normalizedPeak.present) {
      map['normalized_peak'] = Variable<double>(normalizedPeak.value);
    }
    if (detectionQuality.present) {
      map['detection_quality'] = Variable<String>(detectionQuality.value);
    }
    if (exclusionReason.present) {
      map['exclusion_reason'] = Variable<String>(exclusionReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotTimerEventsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('elapsedMicroseconds: $elapsedMicroseconds, ')
          ..write('splitMicroseconds: $splitMicroseconds, ')
          ..write('source: $source, ')
          ..write('disposition: $disposition, ')
          ..write('normalizedPeak: $normalizedPeak, ')
          ..write('detectionQuality: $detectionQuality, ')
          ..write('exclusionReason: $exclusionReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerPresetsTable extends TimerPresets
    with TableInfo<$TimerPresetsTable, TimerPresetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configurationJsonMeta = const VerificationMeta(
    'configurationJson',
  );
  @override
  late final GeneratedColumn<String> configurationJson =
      GeneratedColumn<String>(
        'configuration_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    mode,
    configurationJson,
    builtIn,
    archived,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimerPresetRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('configuration_json')) {
      context.handle(
        _configurationJsonMeta,
        configurationJson.isAcceptableOrUnknown(
          data['configuration_json']!,
          _configurationJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationJsonMeta);
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerPresetRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerPresetRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      configurationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration_json'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TimerPresetsTable createAlias(String alias) {
    return $TimerPresetsTable(attachedDatabase, alias);
  }
}

class TimerPresetRecord extends DataClass
    implements Insertable<TimerPresetRecord> {
  final String id;
  final String name;
  final String mode;
  final String configurationJson;
  final bool builtIn;
  final bool archived;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TimerPresetRecord({
    required this.id,
    required this.name,
    required this.mode,
    required this.configurationJson,
    required this.builtIn,
    required this.archived,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['mode'] = Variable<String>(mode);
    map['configuration_json'] = Variable<String>(configurationJson);
    map['built_in'] = Variable<bool>(builtIn);
    map['archived'] = Variable<bool>(archived);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TimerPresetsCompanion toCompanion(bool nullToAbsent) {
    return TimerPresetsCompanion(
      id: Value(id),
      name: Value(name),
      mode: Value(mode),
      configurationJson: Value(configurationJson),
      builtIn: Value(builtIn),
      archived: Value(archived),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TimerPresetRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerPresetRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mode: serializer.fromJson<String>(json['mode']),
      configurationJson: serializer.fromJson<String>(json['configurationJson']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'mode': serializer.toJson<String>(mode),
      'configurationJson': serializer.toJson<String>(configurationJson),
      'builtIn': serializer.toJson<bool>(builtIn),
      'archived': serializer.toJson<bool>(archived),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TimerPresetRecord copyWith({
    String? id,
    String? name,
    String? mode,
    String? configurationJson,
    bool? builtIn,
    bool? archived,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TimerPresetRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    mode: mode ?? this.mode,
    configurationJson: configurationJson ?? this.configurationJson,
    builtIn: builtIn ?? this.builtIn,
    archived: archived ?? this.archived,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TimerPresetRecord copyWithCompanion(TimerPresetsCompanion data) {
    return TimerPresetRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mode: data.mode.present ? data.mode.value : this.mode,
      configurationJson: data.configurationJson.present
          ? data.configurationJson.value
          : this.configurationJson,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerPresetRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mode: $mode, ')
          ..write('configurationJson: $configurationJson, ')
          ..write('builtIn: $builtIn, ')
          ..write('archived: $archived, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mode,
    configurationJson,
    builtIn,
    archived,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerPresetRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.mode == this.mode &&
          other.configurationJson == this.configurationJson &&
          other.builtIn == this.builtIn &&
          other.archived == this.archived &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TimerPresetsCompanion extends UpdateCompanion<TimerPresetRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> mode;
  final Value<String> configurationJson;
  final Value<bool> builtIn;
  final Value<bool> archived;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TimerPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mode = const Value.absent(),
    this.configurationJson = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimerPresetsCompanion.insert({
    required String id,
    required String name,
    required String mode,
    required String configurationJson,
    this.builtIn = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       mode = Value(mode),
       configurationJson = Value(configurationJson),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TimerPresetRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? mode,
    Expression<String>? configurationJson,
    Expression<bool>? builtIn,
    Expression<bool>? archived,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mode != null) 'mode': mode,
      if (configurationJson != null) 'configuration_json': configurationJson,
      if (builtIn != null) 'built_in': builtIn,
      if (archived != null) 'archived': archived,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimerPresetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? mode,
    Value<String>? configurationJson,
    Value<bool>? builtIn,
    Value<bool>? archived,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TimerPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      configurationJson: configurationJson ?? this.configurationJson,
      builtIn: builtIn ?? this.builtIn,
      archived: archived ?? this.archived,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (configurationJson.present) {
      map['configuration_json'] = Variable<String>(configurationJson.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mode: $mode, ')
          ..write('configurationJson: $configurationJson, ')
          ..write('builtIn: $builtIn, ')
          ..write('archived: $archived, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AcousticCalibrationProfilesTable extends AcousticCalibrationProfiles
    with
        TableInfo<
          $AcousticCalibrationProfilesTable,
          AcousticCalibrationProfileRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcousticCalibrationProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _firearmIdMeta = const VerificationMeta(
    'firearmId',
  );
  @override
  late final GeneratedColumn<String> firearmId = GeneratedColumn<String>(
    'firearm_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES firearms (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _cartridgeIdMeta = const VerificationMeta(
    'cartridgeId',
  );
  @override
  late final GeneratedColumn<String> cartridgeId = GeneratedColumn<String>(
    'cartridge_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cartridges (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _environmentMeta = const VerificationMeta(
    'environment',
  );
  @override
  late final GeneratedColumn<String> environment = GeneratedColumn<String>(
    'environment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioRouteMeta = const VerificationMeta(
    'audioRoute',
  );
  @override
  late final GeneratedColumn<String> audioRoute = GeneratedColumn<String>(
    'audio_route',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleRateMeta = const VerificationMeta(
    'sampleRate',
  );
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sensitivityMeta = const VerificationMeta(
    'sensitivity',
  );
  @override
  late final GeneratedColumn<double> sensitivity = GeneratedColumn<double>(
    'sensitivity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _echoLockoutMicrosecondsMeta =
      const VerificationMeta('echoLockoutMicroseconds');
  @override
  late final GeneratedColumn<int> echoLockoutMicroseconds =
      GeneratedColumn<int>(
        'echo_lockout_microseconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _beepBlankingMicrosecondsMeta =
      const VerificationMeta('beepBlankingMicroseconds');
  @override
  late final GeneratedColumn<int> beepBlankingMicroseconds =
      GeneratedColumn<int>(
        'beep_blanking_microseconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _detectorVersionMeta = const VerificationMeta(
    'detectorVersion',
  );
  @override
  late final GeneratedColumn<String> detectorVersion = GeneratedColumn<String>(
    'detector_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    firearmId,
    cartridgeId,
    environment,
    audioRoute,
    sampleRate,
    sensitivity,
    echoLockoutMicroseconds,
    beepBlankingMicroseconds,
    detectorVersion,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'acoustic_calibration_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcousticCalibrationProfileRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('firearm_id')) {
      context.handle(
        _firearmIdMeta,
        firearmId.isAcceptableOrUnknown(data['firearm_id']!, _firearmIdMeta),
      );
    }
    if (data.containsKey('cartridge_id')) {
      context.handle(
        _cartridgeIdMeta,
        cartridgeId.isAcceptableOrUnknown(
          data['cartridge_id']!,
          _cartridgeIdMeta,
        ),
      );
    }
    if (data.containsKey('environment')) {
      context.handle(
        _environmentMeta,
        environment.isAcceptableOrUnknown(
          data['environment']!,
          _environmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentMeta);
    }
    if (data.containsKey('audio_route')) {
      context.handle(
        _audioRouteMeta,
        audioRoute.isAcceptableOrUnknown(data['audio_route']!, _audioRouteMeta),
      );
    } else if (isInserting) {
      context.missing(_audioRouteMeta);
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    } else if (isInserting) {
      context.missing(_sampleRateMeta);
    }
    if (data.containsKey('sensitivity')) {
      context.handle(
        _sensitivityMeta,
        sensitivity.isAcceptableOrUnknown(
          data['sensitivity']!,
          _sensitivityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensitivityMeta);
    }
    if (data.containsKey('echo_lockout_microseconds')) {
      context.handle(
        _echoLockoutMicrosecondsMeta,
        echoLockoutMicroseconds.isAcceptableOrUnknown(
          data['echo_lockout_microseconds']!,
          _echoLockoutMicrosecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_echoLockoutMicrosecondsMeta);
    }
    if (data.containsKey('beep_blanking_microseconds')) {
      context.handle(
        _beepBlankingMicrosecondsMeta,
        beepBlankingMicroseconds.isAcceptableOrUnknown(
          data['beep_blanking_microseconds']!,
          _beepBlankingMicrosecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beepBlankingMicrosecondsMeta);
    }
    if (data.containsKey('detector_version')) {
      context.handle(
        _detectorVersionMeta,
        detectorVersion.isAcceptableOrUnknown(
          data['detector_version']!,
          _detectorVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_detectorVersionMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AcousticCalibrationProfileRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcousticCalibrationProfileRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      firearmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firearm_id'],
      ),
      cartridgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cartridge_id'],
      ),
      environment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment'],
      )!,
      audioRoute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_route'],
      )!,
      sampleRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      )!,
      sensitivity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sensitivity'],
      )!,
      echoLockoutMicroseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}echo_lockout_microseconds'],
      )!,
      beepBlankingMicroseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}beep_blanking_microseconds'],
      )!,
      detectorVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detector_version'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $AcousticCalibrationProfilesTable createAlias(String alias) {
    return $AcousticCalibrationProfilesTable(attachedDatabase, alias);
  }
}

class AcousticCalibrationProfileRecord extends DataClass
    implements Insertable<AcousticCalibrationProfileRecord> {
  final String id;
  final String name;
  final String? firearmId;
  final String? cartridgeId;
  final String environment;
  final String audioRoute;
  final int sampleRate;
  final double sensitivity;
  final int echoLockoutMicroseconds;
  final int beepBlankingMicroseconds;
  final String detectorVersion;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const AcousticCalibrationProfileRecord({
    required this.id,
    required this.name,
    this.firearmId,
    this.cartridgeId,
    required this.environment,
    required this.audioRoute,
    required this.sampleRate,
    required this.sensitivity,
    required this.echoLockoutMicroseconds,
    required this.beepBlankingMicroseconds,
    required this.detectorVersion,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || firearmId != null) {
      map['firearm_id'] = Variable<String>(firearmId);
    }
    if (!nullToAbsent || cartridgeId != null) {
      map['cartridge_id'] = Variable<String>(cartridgeId);
    }
    map['environment'] = Variable<String>(environment);
    map['audio_route'] = Variable<String>(audioRoute);
    map['sample_rate'] = Variable<int>(sampleRate);
    map['sensitivity'] = Variable<double>(sensitivity);
    map['echo_lockout_microseconds'] = Variable<int>(echoLockoutMicroseconds);
    map['beep_blanking_microseconds'] = Variable<int>(beepBlankingMicroseconds);
    map['detector_version'] = Variable<String>(detectorVersion);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  AcousticCalibrationProfilesCompanion toCompanion(bool nullToAbsent) {
    return AcousticCalibrationProfilesCompanion(
      id: Value(id),
      name: Value(name),
      firearmId: firearmId == null && nullToAbsent
          ? const Value.absent()
          : Value(firearmId),
      cartridgeId: cartridgeId == null && nullToAbsent
          ? const Value.absent()
          : Value(cartridgeId),
      environment: Value(environment),
      audioRoute: Value(audioRoute),
      sampleRate: Value(sampleRate),
      sensitivity: Value(sensitivity),
      echoLockoutMicroseconds: Value(echoLockoutMicroseconds),
      beepBlankingMicroseconds: Value(beepBlankingMicroseconds),
      detectorVersion: Value(detectorVersion),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory AcousticCalibrationProfileRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcousticCalibrationProfileRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      firearmId: serializer.fromJson<String?>(json['firearmId']),
      cartridgeId: serializer.fromJson<String?>(json['cartridgeId']),
      environment: serializer.fromJson<String>(json['environment']),
      audioRoute: serializer.fromJson<String>(json['audioRoute']),
      sampleRate: serializer.fromJson<int>(json['sampleRate']),
      sensitivity: serializer.fromJson<double>(json['sensitivity']),
      echoLockoutMicroseconds: serializer.fromJson<int>(
        json['echoLockoutMicroseconds'],
      ),
      beepBlankingMicroseconds: serializer.fromJson<int>(
        json['beepBlankingMicroseconds'],
      ),
      detectorVersion: serializer.fromJson<String>(json['detectorVersion']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'firearmId': serializer.toJson<String?>(firearmId),
      'cartridgeId': serializer.toJson<String?>(cartridgeId),
      'environment': serializer.toJson<String>(environment),
      'audioRoute': serializer.toJson<String>(audioRoute),
      'sampleRate': serializer.toJson<int>(sampleRate),
      'sensitivity': serializer.toJson<double>(sensitivity),
      'echoLockoutMicroseconds': serializer.toJson<int>(
        echoLockoutMicroseconds,
      ),
      'beepBlankingMicroseconds': serializer.toJson<int>(
        beepBlankingMicroseconds,
      ),
      'detectorVersion': serializer.toJson<String>(detectorVersion),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  AcousticCalibrationProfileRecord copyWith({
    String? id,
    String? name,
    Value<String?> firearmId = const Value.absent(),
    Value<String?> cartridgeId = const Value.absent(),
    String? environment,
    String? audioRoute,
    int? sampleRate,
    double? sensitivity,
    int? echoLockoutMicroseconds,
    int? beepBlankingMicroseconds,
    String? detectorVersion,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => AcousticCalibrationProfileRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    firearmId: firearmId.present ? firearmId.value : this.firearmId,
    cartridgeId: cartridgeId.present ? cartridgeId.value : this.cartridgeId,
    environment: environment ?? this.environment,
    audioRoute: audioRoute ?? this.audioRoute,
    sampleRate: sampleRate ?? this.sampleRate,
    sensitivity: sensitivity ?? this.sensitivity,
    echoLockoutMicroseconds:
        echoLockoutMicroseconds ?? this.echoLockoutMicroseconds,
    beepBlankingMicroseconds:
        beepBlankingMicroseconds ?? this.beepBlankingMicroseconds,
    detectorVersion: detectorVersion ?? this.detectorVersion,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  AcousticCalibrationProfileRecord copyWithCompanion(
    AcousticCalibrationProfilesCompanion data,
  ) {
    return AcousticCalibrationProfileRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      firearmId: data.firearmId.present ? data.firearmId.value : this.firearmId,
      cartridgeId: data.cartridgeId.present
          ? data.cartridgeId.value
          : this.cartridgeId,
      environment: data.environment.present
          ? data.environment.value
          : this.environment,
      audioRoute: data.audioRoute.present
          ? data.audioRoute.value
          : this.audioRoute,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      sensitivity: data.sensitivity.present
          ? data.sensitivity.value
          : this.sensitivity,
      echoLockoutMicroseconds: data.echoLockoutMicroseconds.present
          ? data.echoLockoutMicroseconds.value
          : this.echoLockoutMicroseconds,
      beepBlankingMicroseconds: data.beepBlankingMicroseconds.present
          ? data.beepBlankingMicroseconds.value
          : this.beepBlankingMicroseconds,
      detectorVersion: data.detectorVersion.present
          ? data.detectorVersion.value
          : this.detectorVersion,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcousticCalibrationProfileRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firearmId: $firearmId, ')
          ..write('cartridgeId: $cartridgeId, ')
          ..write('environment: $environment, ')
          ..write('audioRoute: $audioRoute, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('sensitivity: $sensitivity, ')
          ..write('echoLockoutMicroseconds: $echoLockoutMicroseconds, ')
          ..write('beepBlankingMicroseconds: $beepBlankingMicroseconds, ')
          ..write('detectorVersion: $detectorVersion, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    firearmId,
    cartridgeId,
    environment,
    audioRoute,
    sampleRate,
    sensitivity,
    echoLockoutMicroseconds,
    beepBlankingMicroseconds,
    detectorVersion,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcousticCalibrationProfileRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.firearmId == this.firearmId &&
          other.cartridgeId == this.cartridgeId &&
          other.environment == this.environment &&
          other.audioRoute == this.audioRoute &&
          other.sampleRate == this.sampleRate &&
          other.sensitivity == this.sensitivity &&
          other.echoLockoutMicroseconds == this.echoLockoutMicroseconds &&
          other.beepBlankingMicroseconds == this.beepBlankingMicroseconds &&
          other.detectorVersion == this.detectorVersion &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class AcousticCalibrationProfilesCompanion
    extends UpdateCompanion<AcousticCalibrationProfileRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> firearmId;
  final Value<String?> cartridgeId;
  final Value<String> environment;
  final Value<String> audioRoute;
  final Value<int> sampleRate;
  final Value<double> sensitivity;
  final Value<int> echoLockoutMicroseconds;
  final Value<int> beepBlankingMicroseconds;
  final Value<String> detectorVersion;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const AcousticCalibrationProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.firearmId = const Value.absent(),
    this.cartridgeId = const Value.absent(),
    this.environment = const Value.absent(),
    this.audioRoute = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.sensitivity = const Value.absent(),
    this.echoLockoutMicroseconds = const Value.absent(),
    this.beepBlankingMicroseconds = const Value.absent(),
    this.detectorVersion = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AcousticCalibrationProfilesCompanion.insert({
    required String id,
    required String name,
    this.firearmId = const Value.absent(),
    this.cartridgeId = const Value.absent(),
    required String environment,
    required String audioRoute,
    required int sampleRate,
    required double sensitivity,
    required int echoLockoutMicroseconds,
    required int beepBlankingMicroseconds,
    required String detectorVersion,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       environment = Value(environment),
       audioRoute = Value(audioRoute),
       sampleRate = Value(sampleRate),
       sensitivity = Value(sensitivity),
       echoLockoutMicroseconds = Value(echoLockoutMicroseconds),
       beepBlankingMicroseconds = Value(beepBlankingMicroseconds),
       detectorVersion = Value(detectorVersion),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<AcousticCalibrationProfileRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? firearmId,
    Expression<String>? cartridgeId,
    Expression<String>? environment,
    Expression<String>? audioRoute,
    Expression<int>? sampleRate,
    Expression<double>? sensitivity,
    Expression<int>? echoLockoutMicroseconds,
    Expression<int>? beepBlankingMicroseconds,
    Expression<String>? detectorVersion,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (firearmId != null) 'firearm_id': firearmId,
      if (cartridgeId != null) 'cartridge_id': cartridgeId,
      if (environment != null) 'environment': environment,
      if (audioRoute != null) 'audio_route': audioRoute,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (sensitivity != null) 'sensitivity': sensitivity,
      if (echoLockoutMicroseconds != null)
        'echo_lockout_microseconds': echoLockoutMicroseconds,
      if (beepBlankingMicroseconds != null)
        'beep_blanking_microseconds': beepBlankingMicroseconds,
      if (detectorVersion != null) 'detector_version': detectorVersion,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AcousticCalibrationProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? firearmId,
    Value<String?>? cartridgeId,
    Value<String>? environment,
    Value<String>? audioRoute,
    Value<int>? sampleRate,
    Value<double>? sensitivity,
    Value<int>? echoLockoutMicroseconds,
    Value<int>? beepBlankingMicroseconds,
    Value<String>? detectorVersion,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return AcousticCalibrationProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      firearmId: firearmId ?? this.firearmId,
      cartridgeId: cartridgeId ?? this.cartridgeId,
      environment: environment ?? this.environment,
      audioRoute: audioRoute ?? this.audioRoute,
      sampleRate: sampleRate ?? this.sampleRate,
      sensitivity: sensitivity ?? this.sensitivity,
      echoLockoutMicroseconds:
          echoLockoutMicroseconds ?? this.echoLockoutMicroseconds,
      beepBlankingMicroseconds:
          beepBlankingMicroseconds ?? this.beepBlankingMicroseconds,
      detectorVersion: detectorVersion ?? this.detectorVersion,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firearmId.present) {
      map['firearm_id'] = Variable<String>(firearmId.value);
    }
    if (cartridgeId.present) {
      map['cartridge_id'] = Variable<String>(cartridgeId.value);
    }
    if (environment.present) {
      map['environment'] = Variable<String>(environment.value);
    }
    if (audioRoute.present) {
      map['audio_route'] = Variable<String>(audioRoute.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (sensitivity.present) {
      map['sensitivity'] = Variable<double>(sensitivity.value);
    }
    if (echoLockoutMicroseconds.present) {
      map['echo_lockout_microseconds'] = Variable<int>(
        echoLockoutMicroseconds.value,
      );
    }
    if (beepBlankingMicroseconds.present) {
      map['beep_blanking_microseconds'] = Variable<int>(
        beepBlankingMicroseconds.value,
      );
    }
    if (detectorVersion.present) {
      map['detector_version'] = Variable<String>(detectorVersion.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcousticCalibrationProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firearmId: $firearmId, ')
          ..write('cartridgeId: $cartridgeId, ')
          ..write('environment: $environment, ')
          ..write('audioRoute: $audioRoute, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('sensitivity: $sensitivity, ')
          ..write('echoLockoutMicroseconds: $echoLockoutMicroseconds, ')
          ..write('beepBlankingMicroseconds: $beepBlankingMicroseconds, ')
          ..write('detectorVersion: $detectorVersion, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FirearmsTable firearms = $FirearmsTable(this);
  late final $CartridgesTable cartridges = $CartridgesTable(this);
  late final $AmmoLotsTable ammoLots = $AmmoLotsTable(this);
  late final $RangesTable ranges = $RangesTable(this);
  late final $TrainingSessionsTable trainingSessions = $TrainingSessionsTable(
    this,
  );
  late final $ShootingSeriesTable shootingSeries = $ShootingSeriesTable(this);
  late final $ImageAssetsTable imageAssets = $ImageAssetsTable(this);
  late final $VisionScanDraftsTable visionScanDrafts = $VisionScanDraftsTable(
    this,
  );
  late final $VisionAnalysesTable visionAnalyses = $VisionAnalysesTable(this);
  late final $ShotImpactsTable shotImpacts = $ShotImpactsTable(this);
  late final $PhotoAlignmentsTable photoAlignments = $PhotoAlignmentsTable(
    this,
  );
  late final $GoalsTable goals = $GoalsTable(this);
  late final $SeriesReflectionsTable seriesReflections =
      $SeriesReflectionsTable(this);
  late final $CoachFeedbackTable coachFeedback = $CoachFeedbackTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $TargetProfilesTable targetProfiles = $TargetProfilesTable(this);
  late final $TrainingActivitiesTable trainingActivities =
      $TrainingActivitiesTable(this);
  late final $TrainingActivitySeriesLinksTable trainingActivitySeriesLinks =
      $TrainingActivitySeriesLinksTable(this);
  late final $ShotTimerEventsTable shotTimerEvents = $ShotTimerEventsTable(
    this,
  );
  late final $TimerPresetsTable timerPresets = $TimerPresetsTable(this);
  late final $AcousticCalibrationProfilesTable acousticCalibrationProfiles =
      $AcousticCalibrationProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    firearms,
    cartridges,
    ammoLots,
    ranges,
    trainingSessions,
    shootingSeries,
    imageAssets,
    visionScanDrafts,
    visionAnalyses,
    shotImpacts,
    photoAlignments,
    goals,
    seriesReflections,
    coachFeedback,
    preferences,
    targetProfiles,
    trainingActivities,
    trainingActivitySeriesLinks,
    shotTimerEvents,
    timerPresets,
    acousticCalibrationProfiles,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'training_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shooting_series', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'training_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('image_assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shooting_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('image_assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shooting_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vision_analyses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'image_assets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vision_analyses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shooting_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shot_impacts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'image_assets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shot_impacts', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vision_analyses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shot_impacts', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'image_assets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('photo_alignments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shooting_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('series_reflections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'training_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('training_activities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'training_activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('training_activity_series_links', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shooting_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('training_activity_series_links', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'training_activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shot_timer_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'firearms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('acoustic_calibration_profiles', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cartridges',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('acoustic_calibration_profiles', kind: UpdateKind.update),
      ],
    ),
  ]);
}

typedef $$FirearmsTableCreateCompanionBuilder =
    FirearmsCompanion Function({
      required String id,
      required String name,
      Value<String?> manufacturer,
      Value<String?> model,
      required String type,
      Value<String?> defaultCartridgeId,
      Value<String?> sightNotes,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$FirearmsTableUpdateCompanionBuilder =
    FirearmsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> manufacturer,
      Value<String?> model,
      Value<String> type,
      Value<String?> defaultCartridgeId,
      Value<String?> sightNotes,
      Value<bool> archived,
      Value<int> rowid,
    });

final class $$FirearmsTableReferences
    extends BaseReferences<_$AppDatabase, $FirearmsTable, FirearmRecord> {
  $$FirearmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShootingSeriesTable, List<SeriesRecord>>
  _shootingSeriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shootingSeries,
    aliasName: 'firearms__id__shooting_series__firearm_id',
  );

  $$ShootingSeriesTableProcessedTableManager get shootingSeriesRefs {
    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.firearmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shootingSeriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalsTable, List<GoalRecord>> _goalsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.goals,
    aliasName: 'firearms__id__goals__firearm_id',
  );

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.firearmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AcousticCalibrationProfilesTable,
    List<AcousticCalibrationProfileRecord>
  >
  _acousticCalibrationProfilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.acousticCalibrationProfiles,
        aliasName: 'firearms__id__acoustic_calibration_profiles__firearm_id',
      );

  $$AcousticCalibrationProfilesTableProcessedTableManager
  get acousticCalibrationProfilesRefs {
    final manager = $$AcousticCalibrationProfilesTableTableManager(
      $_db,
      $_db.acousticCalibrationProfiles,
    ).filter((f) => f.firearmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _acousticCalibrationProfilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FirearmsTableFilterComposer
    extends Composer<_$AppDatabase, $FirearmsTable> {
  $$FirearmsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCartridgeId => $composableBuilder(
    column: $table.defaultCartridgeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sightNotes => $composableBuilder(
    column: $table.sightNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shootingSeriesRefs(
    Expression<bool> Function($$ShootingSeriesTableFilterComposer f) f,
  ) {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.firearmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalsRefs(
    Expression<bool> Function($$GoalsTableFilterComposer f) f,
  ) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.firearmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> acousticCalibrationProfilesRefs(
    Expression<bool> Function(
      $$AcousticCalibrationProfilesTableFilterComposer f,
    )
    f,
  ) {
    final $$AcousticCalibrationProfilesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.acousticCalibrationProfiles,
          getReferencedColumn: (t) => t.firearmId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcousticCalibrationProfilesTableFilterComposer(
                $db: $db,
                $table: $db.acousticCalibrationProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FirearmsTableOrderingComposer
    extends Composer<_$AppDatabase, $FirearmsTable> {
  $$FirearmsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCartridgeId => $composableBuilder(
    column: $table.defaultCartridgeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sightNotes => $composableBuilder(
    column: $table.sightNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FirearmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FirearmsTable> {
  $$FirearmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get defaultCartridgeId => $composableBuilder(
    column: $table.defaultCartridgeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sightNotes => $composableBuilder(
    column: $table.sightNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> shootingSeriesRefs<T extends Object>(
    Expression<T> Function($$ShootingSeriesTableAnnotationComposer a) f,
  ) {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.firearmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
    Expression<T> Function($$GoalsTableAnnotationComposer a) f,
  ) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.firearmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> acousticCalibrationProfilesRefs<T extends Object>(
    Expression<T> Function(
      $$AcousticCalibrationProfilesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AcousticCalibrationProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.acousticCalibrationProfiles,
          getReferencedColumn: (t) => t.firearmId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcousticCalibrationProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.acousticCalibrationProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FirearmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FirearmsTable,
          FirearmRecord,
          $$FirearmsTableFilterComposer,
          $$FirearmsTableOrderingComposer,
          $$FirearmsTableAnnotationComposer,
          $$FirearmsTableCreateCompanionBuilder,
          $$FirearmsTableUpdateCompanionBuilder,
          (FirearmRecord, $$FirearmsTableReferences),
          FirearmRecord,
          PrefetchHooks Function({
            bool shootingSeriesRefs,
            bool goalsRefs,
            bool acousticCalibrationProfilesRefs,
          })
        > {
  $$FirearmsTableTableManager(_$AppDatabase db, $FirearmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FirearmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FirearmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FirearmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> defaultCartridgeId = const Value.absent(),
                Value<String?> sightNotes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FirearmsCompanion(
                id: id,
                name: name,
                manufacturer: manufacturer,
                model: model,
                type: type,
                defaultCartridgeId: defaultCartridgeId,
                sightNotes: sightNotes,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> model = const Value.absent(),
                required String type,
                Value<String?> defaultCartridgeId = const Value.absent(),
                Value<String?> sightNotes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FirearmsCompanion.insert(
                id: id,
                name: name,
                manufacturer: manufacturer,
                model: model,
                type: type,
                defaultCartridgeId: defaultCartridgeId,
                sightNotes: sightNotes,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FirearmsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                shootingSeriesRefs = false,
                goalsRefs = false,
                acousticCalibrationProfilesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shootingSeriesRefs) db.shootingSeries,
                    if (goalsRefs) db.goals,
                    if (acousticCalibrationProfilesRefs)
                      db.acousticCalibrationProfiles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shootingSeriesRefs)
                        await $_getPrefetchedData<
                          FirearmRecord,
                          $FirearmsTable,
                          SeriesRecord
                        >(
                          currentTable: table,
                          referencedTable: $$FirearmsTableReferences
                              ._shootingSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FirearmsTableReferences(
                                db,
                                table,
                                p0,
                              ).shootingSeriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firearmId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalsRefs)
                        await $_getPrefetchedData<
                          FirearmRecord,
                          $FirearmsTable,
                          GoalRecord
                        >(
                          currentTable: table,
                          referencedTable: $$FirearmsTableReferences
                              ._goalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FirearmsTableReferences(
                                db,
                                table,
                                p0,
                              ).goalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firearmId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (acousticCalibrationProfilesRefs)
                        await $_getPrefetchedData<
                          FirearmRecord,
                          $FirearmsTable,
                          AcousticCalibrationProfileRecord
                        >(
                          currentTable: table,
                          referencedTable: $$FirearmsTableReferences
                              ._acousticCalibrationProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FirearmsTableReferences(
                                db,
                                table,
                                p0,
                              ).acousticCalibrationProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firearmId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FirearmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FirearmsTable,
      FirearmRecord,
      $$FirearmsTableFilterComposer,
      $$FirearmsTableOrderingComposer,
      $$FirearmsTableAnnotationComposer,
      $$FirearmsTableCreateCompanionBuilder,
      $$FirearmsTableUpdateCompanionBuilder,
      (FirearmRecord, $$FirearmsTableReferences),
      FirearmRecord,
      PrefetchHooks Function({
        bool shootingSeriesRefs,
        bool goalsRefs,
        bool acousticCalibrationProfilesRefs,
      })
    >;
typedef $$CartridgesTableCreateCompanionBuilder =
    CartridgesCompanion Function({
      required String id,
      required String name,
      required double projectileDiameterMm,
      Value<String?> notes,
      Value<bool> builtIn,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$CartridgesTableUpdateCompanionBuilder =
    CartridgesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> projectileDiameterMm,
      Value<String?> notes,
      Value<bool> builtIn,
      Value<bool> archived,
      Value<int> rowid,
    });

final class $$CartridgesTableReferences
    extends BaseReferences<_$AppDatabase, $CartridgesTable, CartridgeRecord> {
  $$CartridgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AmmoLotsTable, List<AmmoLotRecord>>
  _ammoLotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ammoLots,
    aliasName: 'cartridges__id__ammo_lots__cartridge_id',
  );

  $$AmmoLotsTableProcessedTableManager get ammoLotsRefs {
    final manager = $$AmmoLotsTableTableManager(
      $_db,
      $_db.ammoLots,
    ).filter((f) => f.cartridgeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ammoLotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShootingSeriesTable, List<SeriesRecord>>
  _shootingSeriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shootingSeries,
    aliasName: 'cartridges__id__shooting_series__cartridge_id',
  );

  $$ShootingSeriesTableProcessedTableManager get shootingSeriesRefs {
    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.cartridgeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shootingSeriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AcousticCalibrationProfilesTable,
    List<AcousticCalibrationProfileRecord>
  >
  _acousticCalibrationProfilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.acousticCalibrationProfiles,
        aliasName:
            'cartridges__id__acoustic_calibration_profiles__cartridge_id',
      );

  $$AcousticCalibrationProfilesTableProcessedTableManager
  get acousticCalibrationProfilesRefs {
    final manager = $$AcousticCalibrationProfilesTableTableManager(
      $_db,
      $_db.acousticCalibrationProfiles,
    ).filter((f) => f.cartridgeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _acousticCalibrationProfilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CartridgesTableFilterComposer
    extends Composer<_$AppDatabase, $CartridgesTable> {
  $$CartridgesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ammoLotsRefs(
    Expression<bool> Function($$AmmoLotsTableFilterComposer f) f,
  ) {
    final $$AmmoLotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.cartridgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableFilterComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shootingSeriesRefs(
    Expression<bool> Function($$ShootingSeriesTableFilterComposer f) f,
  ) {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.cartridgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> acousticCalibrationProfilesRefs(
    Expression<bool> Function(
      $$AcousticCalibrationProfilesTableFilterComposer f,
    )
    f,
  ) {
    final $$AcousticCalibrationProfilesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.acousticCalibrationProfiles,
          getReferencedColumn: (t) => t.cartridgeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcousticCalibrationProfilesTableFilterComposer(
                $db: $db,
                $table: $db.acousticCalibrationProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CartridgesTableOrderingComposer
    extends Composer<_$AppDatabase, $CartridgesTable> {
  $$CartridgesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CartridgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CartridgesTable> {
  $$CartridgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> ammoLotsRefs<T extends Object>(
    Expression<T> Function($$AmmoLotsTableAnnotationComposer a) f,
  ) {
    final $$AmmoLotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.cartridgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableAnnotationComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shootingSeriesRefs<T extends Object>(
    Expression<T> Function($$ShootingSeriesTableAnnotationComposer a) f,
  ) {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.cartridgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> acousticCalibrationProfilesRefs<T extends Object>(
    Expression<T> Function(
      $$AcousticCalibrationProfilesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AcousticCalibrationProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.acousticCalibrationProfiles,
          getReferencedColumn: (t) => t.cartridgeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcousticCalibrationProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.acousticCalibrationProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CartridgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CartridgesTable,
          CartridgeRecord,
          $$CartridgesTableFilterComposer,
          $$CartridgesTableOrderingComposer,
          $$CartridgesTableAnnotationComposer,
          $$CartridgesTableCreateCompanionBuilder,
          $$CartridgesTableUpdateCompanionBuilder,
          (CartridgeRecord, $$CartridgesTableReferences),
          CartridgeRecord,
          PrefetchHooks Function({
            bool ammoLotsRefs,
            bool shootingSeriesRefs,
            bool acousticCalibrationProfilesRefs,
          })
        > {
  $$CartridgesTableTableManager(_$AppDatabase db, $CartridgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartridgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartridgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartridgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> projectileDiameterMm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CartridgesCompanion(
                id: id,
                name: name,
                projectileDiameterMm: projectileDiameterMm,
                notes: notes,
                builtIn: builtIn,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double projectileDiameterMm,
                Value<String?> notes = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CartridgesCompanion.insert(
                id: id,
                name: name,
                projectileDiameterMm: projectileDiameterMm,
                notes: notes,
                builtIn: builtIn,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CartridgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ammoLotsRefs = false,
                shootingSeriesRefs = false,
                acousticCalibrationProfilesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ammoLotsRefs) db.ammoLots,
                    if (shootingSeriesRefs) db.shootingSeries,
                    if (acousticCalibrationProfilesRefs)
                      db.acousticCalibrationProfiles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ammoLotsRefs)
                        await $_getPrefetchedData<
                          CartridgeRecord,
                          $CartridgesTable,
                          AmmoLotRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CartridgesTableReferences
                              ._ammoLotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CartridgesTableReferences(
                                db,
                                table,
                                p0,
                              ).ammoLotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cartridgeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shootingSeriesRefs)
                        await $_getPrefetchedData<
                          CartridgeRecord,
                          $CartridgesTable,
                          SeriesRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CartridgesTableReferences
                              ._shootingSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CartridgesTableReferences(
                                db,
                                table,
                                p0,
                              ).shootingSeriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cartridgeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (acousticCalibrationProfilesRefs)
                        await $_getPrefetchedData<
                          CartridgeRecord,
                          $CartridgesTable,
                          AcousticCalibrationProfileRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CartridgesTableReferences
                              ._acousticCalibrationProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CartridgesTableReferences(
                                db,
                                table,
                                p0,
                              ).acousticCalibrationProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cartridgeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CartridgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CartridgesTable,
      CartridgeRecord,
      $$CartridgesTableFilterComposer,
      $$CartridgesTableOrderingComposer,
      $$CartridgesTableAnnotationComposer,
      $$CartridgesTableCreateCompanionBuilder,
      $$CartridgesTableUpdateCompanionBuilder,
      (CartridgeRecord, $$CartridgesTableReferences),
      CartridgeRecord,
      PrefetchHooks Function({
        bool ammoLotsRefs,
        bool shootingSeriesRefs,
        bool acousticCalibrationProfilesRefs,
      })
    >;
typedef $$AmmoLotsTableCreateCompanionBuilder =
    AmmoLotsCompanion Function({
      required String id,
      required String cartridgeId,
      required String displayName,
      Value<String?> manufacturer,
      Value<String?> productName,
      Value<String?> lotNumber,
      Value<double?> bulletWeightGrains,
      Value<String?> projectileType,
      Value<String?> notes,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$AmmoLotsTableUpdateCompanionBuilder =
    AmmoLotsCompanion Function({
      Value<String> id,
      Value<String> cartridgeId,
      Value<String> displayName,
      Value<String?> manufacturer,
      Value<String?> productName,
      Value<String?> lotNumber,
      Value<double?> bulletWeightGrains,
      Value<String?> projectileType,
      Value<String?> notes,
      Value<bool> archived,
      Value<int> rowid,
    });

final class $$AmmoLotsTableReferences
    extends BaseReferences<_$AppDatabase, $AmmoLotsTable, AmmoLotRecord> {
  $$AmmoLotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CartridgesTable _cartridgeIdTable(_$AppDatabase db) =>
      db.cartridges.createAlias('ammo_lots__cartridge_id__cartridges__id');

  $$CartridgesTableProcessedTableManager get cartridgeId {
    final $_column = $_itemColumn<String>('cartridge_id')!;

    final manager = $$CartridgesTableTableManager(
      $_db,
      $_db.cartridges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cartridgeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShootingSeriesTable, List<SeriesRecord>>
  _shootingSeriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shootingSeries,
    aliasName: 'ammo_lots__id__shooting_series__ammo_lot_id',
  );

  $$ShootingSeriesTableProcessedTableManager get shootingSeriesRefs {
    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.ammoLotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shootingSeriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalsTable, List<GoalRecord>> _goalsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.goals,
    aliasName: 'ammo_lots__id__goals__ammo_lot_id',
  );

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.ammoLotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AmmoLotsTableFilterComposer
    extends Composer<_$AppDatabase, $AmmoLotsTable> {
  $$AmmoLotsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lotNumber => $composableBuilder(
    column: $table.lotNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bulletWeightGrains => $composableBuilder(
    column: $table.bulletWeightGrains,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectileType => $composableBuilder(
    column: $table.projectileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  $$CartridgesTableFilterComposer get cartridgeId {
    final $$CartridgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableFilterComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shootingSeriesRefs(
    Expression<bool> Function($$ShootingSeriesTableFilterComposer f) f,
  ) {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.ammoLotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalsRefs(
    Expression<bool> Function($$GoalsTableFilterComposer f) f,
  ) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.ammoLotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AmmoLotsTableOrderingComposer
    extends Composer<_$AppDatabase, $AmmoLotsTable> {
  $$AmmoLotsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lotNumber => $composableBuilder(
    column: $table.lotNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bulletWeightGrains => $composableBuilder(
    column: $table.bulletWeightGrains,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectileType => $composableBuilder(
    column: $table.projectileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  $$CartridgesTableOrderingComposer get cartridgeId {
    final $$CartridgesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableOrderingComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmmoLotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmmoLotsTable> {
  $$AmmoLotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lotNumber =>
      $composableBuilder(column: $table.lotNumber, builder: (column) => column);

  GeneratedColumn<double> get bulletWeightGrains => $composableBuilder(
    column: $table.bulletWeightGrains,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectileType => $composableBuilder(
    column: $table.projectileType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  $$CartridgesTableAnnotationComposer get cartridgeId {
    final $$CartridgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableAnnotationComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shootingSeriesRefs<T extends Object>(
    Expression<T> Function($$ShootingSeriesTableAnnotationComposer a) f,
  ) {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.ammoLotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
    Expression<T> Function($$GoalsTableAnnotationComposer a) f,
  ) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.ammoLotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AmmoLotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmmoLotsTable,
          AmmoLotRecord,
          $$AmmoLotsTableFilterComposer,
          $$AmmoLotsTableOrderingComposer,
          $$AmmoLotsTableAnnotationComposer,
          $$AmmoLotsTableCreateCompanionBuilder,
          $$AmmoLotsTableUpdateCompanionBuilder,
          (AmmoLotRecord, $$AmmoLotsTableReferences),
          AmmoLotRecord,
          PrefetchHooks Function({
            bool cartridgeId,
            bool shootingSeriesRefs,
            bool goalsRefs,
          })
        > {
  $$AmmoLotsTableTableManager(_$AppDatabase db, $AmmoLotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmmoLotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmmoLotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmmoLotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cartridgeId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<String?> lotNumber = const Value.absent(),
                Value<double?> bulletWeightGrains = const Value.absent(),
                Value<String?> projectileType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmmoLotsCompanion(
                id: id,
                cartridgeId: cartridgeId,
                displayName: displayName,
                manufacturer: manufacturer,
                productName: productName,
                lotNumber: lotNumber,
                bulletWeightGrains: bulletWeightGrains,
                projectileType: projectileType,
                notes: notes,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cartridgeId,
                required String displayName,
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<String?> lotNumber = const Value.absent(),
                Value<double?> bulletWeightGrains = const Value.absent(),
                Value<String?> projectileType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmmoLotsCompanion.insert(
                id: id,
                cartridgeId: cartridgeId,
                displayName: displayName,
                manufacturer: manufacturer,
                productName: productName,
                lotNumber: lotNumber,
                bulletWeightGrains: bulletWeightGrains,
                projectileType: projectileType,
                notes: notes,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmmoLotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cartridgeId = false,
                shootingSeriesRefs = false,
                goalsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shootingSeriesRefs) db.shootingSeries,
                    if (goalsRefs) db.goals,
                  ],
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
                        if (cartridgeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cartridgeId,
                                    referencedTable: $$AmmoLotsTableReferences
                                        ._cartridgeIdTable(db),
                                    referencedColumn: $$AmmoLotsTableReferences
                                        ._cartridgeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shootingSeriesRefs)
                        await $_getPrefetchedData<
                          AmmoLotRecord,
                          $AmmoLotsTable,
                          SeriesRecord
                        >(
                          currentTable: table,
                          referencedTable: $$AmmoLotsTableReferences
                              ._shootingSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AmmoLotsTableReferences(
                                db,
                                table,
                                p0,
                              ).shootingSeriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ammoLotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalsRefs)
                        await $_getPrefetchedData<
                          AmmoLotRecord,
                          $AmmoLotsTable,
                          GoalRecord
                        >(
                          currentTable: table,
                          referencedTable: $$AmmoLotsTableReferences
                              ._goalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AmmoLotsTableReferences(
                                db,
                                table,
                                p0,
                              ).goalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ammoLotId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AmmoLotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmmoLotsTable,
      AmmoLotRecord,
      $$AmmoLotsTableFilterComposer,
      $$AmmoLotsTableOrderingComposer,
      $$AmmoLotsTableAnnotationComposer,
      $$AmmoLotsTableCreateCompanionBuilder,
      $$AmmoLotsTableUpdateCompanionBuilder,
      (AmmoLotRecord, $$AmmoLotsTableReferences),
      AmmoLotRecord,
      PrefetchHooks Function({
        bool cartridgeId,
        bool shootingSeriesRefs,
        bool goalsRefs,
      })
    >;
typedef $$RangesTableCreateCompanionBuilder =
    RangesCompanion Function({
      required String id,
      required String name,
      Value<String?> locationDescription,
      Value<bool> isIndoor,
      Value<String> availableDistancesJson,
      Value<String?> notes,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$RangesTableUpdateCompanionBuilder =
    RangesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> locationDescription,
      Value<bool> isIndoor,
      Value<String> availableDistancesJson,
      Value<String?> notes,
      Value<bool> archived,
      Value<int> rowid,
    });

final class $$RangesTableReferences
    extends BaseReferences<_$AppDatabase, $RangesTable, RangeRecord> {
  $$RangesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrainingSessionsTable, List<SessionRecord>>
  _trainingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trainingSessions,
    aliasName: 'ranges__id__training_sessions__range_id',
  );

  $$TrainingSessionsTableProcessedTableManager get trainingSessionsRefs {
    final manager = $$TrainingSessionsTableTableManager(
      $_db,
      $_db.trainingSessions,
    ).filter((f) => f.rangeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trainingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RangesTableFilterComposer
    extends Composer<_$AppDatabase, $RangesTable> {
  $$RangesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availableDistancesJson => $composableBuilder(
    column: $table.availableDistancesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trainingSessionsRefs(
    Expression<bool> Function($$TrainingSessionsTableFilterComposer f) f,
  ) {
    final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.rangeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RangesTableOrderingComposer
    extends Composer<_$AppDatabase, $RangesTable> {
  $$RangesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availableDistancesJson => $composableBuilder(
    column: $table.availableDistancesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RangesTable> {
  $$RangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isIndoor =>
      $composableBuilder(column: $table.isIndoor, builder: (column) => column);

  GeneratedColumn<String> get availableDistancesJson => $composableBuilder(
    column: $table.availableDistancesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> trainingSessionsRefs<T extends Object>(
    Expression<T> Function($$TrainingSessionsTableAnnotationComposer a) f,
  ) {
    final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.rangeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RangesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RangesTable,
          RangeRecord,
          $$RangesTableFilterComposer,
          $$RangesTableOrderingComposer,
          $$RangesTableAnnotationComposer,
          $$RangesTableCreateCompanionBuilder,
          $$RangesTableUpdateCompanionBuilder,
          (RangeRecord, $$RangesTableReferences),
          RangeRecord,
          PrefetchHooks Function({bool trainingSessionsRefs})
        > {
  $$RangesTableTableManager(_$AppDatabase db, $RangesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                Value<bool> isIndoor = const Value.absent(),
                Value<String> availableDistancesJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RangesCompanion(
                id: id,
                name: name,
                locationDescription: locationDescription,
                isIndoor: isIndoor,
                availableDistancesJson: availableDistancesJson,
                notes: notes,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> locationDescription = const Value.absent(),
                Value<bool> isIndoor = const Value.absent(),
                Value<String> availableDistancesJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RangesCompanion.insert(
                id: id,
                name: name,
                locationDescription: locationDescription,
                isIndoor: isIndoor,
                availableDistancesJson: availableDistancesJson,
                notes: notes,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RangesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({trainingSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (trainingSessionsRefs) db.trainingSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trainingSessionsRefs)
                    await $_getPrefetchedData<
                      RangeRecord,
                      $RangesTable,
                      SessionRecord
                    >(
                      currentTable: table,
                      referencedTable: $$RangesTableReferences
                          ._trainingSessionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RangesTableReferences(
                        db,
                        table,
                        p0,
                      ).trainingSessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.rangeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RangesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RangesTable,
      RangeRecord,
      $$RangesTableFilterComposer,
      $$RangesTableOrderingComposer,
      $$RangesTableAnnotationComposer,
      $$RangesTableCreateCompanionBuilder,
      $$RangesTableUpdateCompanionBuilder,
      (RangeRecord, $$RangesTableReferences),
      RangeRecord,
      PrefetchHooks Function({bool trainingSessionsRefs})
    >;
typedef $$TrainingSessionsTableCreateCompanionBuilder =
    TrainingSessionsCompanion Function({
      required String id,
      required String status,
      required DateTime startedAtUtc,
      required int localUtcOffsetMinutes,
      Value<DateTime?> endedAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> photoSafetyAcknowledgedAtUtc,
      Value<String?> rangeId,
      Value<String?> trainingGoal,
      Value<String?> conditions,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$TrainingSessionsTableUpdateCompanionBuilder =
    TrainingSessionsCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<DateTime> startedAtUtc,
      Value<int> localUtcOffsetMinutes,
      Value<DateTime?> endedAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> photoSafetyAcknowledgedAtUtc,
      Value<String?> rangeId,
      Value<String?> trainingGoal,
      Value<String?> conditions,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$TrainingSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TrainingSessionsTable, SessionRecord> {
  $$TrainingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RangesTable _rangeIdTable(_$AppDatabase db) =>
      db.ranges.createAlias('training_sessions__range_id__ranges__id');

  $$RangesTableProcessedTableManager? get rangeId {
    final $_column = $_itemColumn<String>('range_id');
    if ($_column == null) return null;
    final manager = $$RangesTableTableManager(
      $_db,
      $_db.ranges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rangeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShootingSeriesTable, List<SeriesRecord>>
  _shootingSeriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shootingSeries,
    aliasName: 'training_sessions__id__shooting_series__session_id',
  );

  $$ShootingSeriesTableProcessedTableManager get shootingSeriesRefs {
    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shootingSeriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImageAssetsTable, List<ImageAssetRecord>>
  _imageAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.imageAssets,
    aliasName: 'training_sessions__id__image_assets__session_id',
  );

  $$ImageAssetsTableProcessedTableManager get imageAssetsRefs {
    final manager = $$ImageAssetsTableTableManager(
      $_db,
      $_db.imageAssets,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imageAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TrainingActivitiesTable,
    List<TrainingActivityRecord>
  >
  _trainingActivitiesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.trainingActivities,
        aliasName: 'training_sessions__id__training_activities__session_id',
      );

  $$TrainingActivitiesTableProcessedTableManager get trainingActivitiesRefs {
    final manager = $$TrainingActivitiesTableTableManager(
      $_db,
      $_db.trainingActivities,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trainingActivitiesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TrainingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingSessionsTable> {
  $$TrainingSessionsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localUtcOffsetMinutes => $composableBuilder(
    column: $table.localUtcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAtUtc => $composableBuilder(
    column: $table.endedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get photoSafetyAcknowledgedAtUtc =>
      $composableBuilder(
        column: $table.photoSafetyAcknowledgedAtUtc,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<String> get trainingGoal => $composableBuilder(
    column: $table.trainingGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditions => $composableBuilder(
    column: $table.conditions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$RangesTableFilterComposer get rangeId {
    final $$RangesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeId,
      referencedTable: $db.ranges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RangesTableFilterComposer(
            $db: $db,
            $table: $db.ranges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shootingSeriesRefs(
    Expression<bool> Function($$ShootingSeriesTableFilterComposer f) f,
  ) {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> imageAssetsRefs(
    Expression<bool> Function($$ImageAssetsTableFilterComposer f) f,
  ) {
    final $$ImageAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableFilterComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trainingActivitiesRefs(
    Expression<bool> Function($$TrainingActivitiesTableFilterComposer f) f,
  ) {
    final $$TrainingActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingActivities,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.trainingActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrainingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingSessionsTable> {
  $$TrainingSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localUtcOffsetMinutes => $composableBuilder(
    column: $table.localUtcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAtUtc => $composableBuilder(
    column: $table.endedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get photoSafetyAcknowledgedAtUtc =>
      $composableBuilder(
        column: $table.photoSafetyAcknowledgedAtUtc,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get trainingGoal => $composableBuilder(
    column: $table.trainingGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditions => $composableBuilder(
    column: $table.conditions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$RangesTableOrderingComposer get rangeId {
    final $$RangesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeId,
      referencedTable: $db.ranges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RangesTableOrderingComposer(
            $db: $db,
            $table: $db.ranges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrainingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingSessionsTable> {
  $$TrainingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localUtcOffsetMinutes => $composableBuilder(
    column: $table.localUtcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endedAtUtc => $composableBuilder(
    column: $table.endedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get photoSafetyAcknowledgedAtUtc =>
      $composableBuilder(
        column: $table.photoSafetyAcknowledgedAtUtc,
        builder: (column) => column,
      );

  GeneratedColumn<String> get trainingGoal => $composableBuilder(
    column: $table.trainingGoal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conditions => $composableBuilder(
    column: $table.conditions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$RangesTableAnnotationComposer get rangeId {
    final $$RangesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeId,
      referencedTable: $db.ranges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RangesTableAnnotationComposer(
            $db: $db,
            $table: $db.ranges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shootingSeriesRefs<T extends Object>(
    Expression<T> Function($$ShootingSeriesTableAnnotationComposer a) f,
  ) {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> imageAssetsRefs<T extends Object>(
    Expression<T> Function($$ImageAssetsTableAnnotationComposer a) f,
  ) {
    final $$ImageAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trainingActivitiesRefs<T extends Object>(
    Expression<T> Function($$TrainingActivitiesTableAnnotationComposer a) f,
  ) {
    final $$TrainingActivitiesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trainingActivities,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitiesTableAnnotationComposer(
                $db: $db,
                $table: $db.trainingActivities,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TrainingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainingSessionsTable,
          SessionRecord,
          $$TrainingSessionsTableFilterComposer,
          $$TrainingSessionsTableOrderingComposer,
          $$TrainingSessionsTableAnnotationComposer,
          $$TrainingSessionsTableCreateCompanionBuilder,
          $$TrainingSessionsTableUpdateCompanionBuilder,
          (SessionRecord, $$TrainingSessionsTableReferences),
          SessionRecord,
          PrefetchHooks Function({
            bool rangeId,
            bool shootingSeriesRefs,
            bool imageAssetsRefs,
            bool trainingActivitiesRefs,
          })
        > {
  $$TrainingSessionsTableTableManager(
    _$AppDatabase db,
    $TrainingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAtUtc = const Value.absent(),
                Value<int> localUtcOffsetMinutes = const Value.absent(),
                Value<DateTime?> endedAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> photoSafetyAcknowledgedAtUtc =
                    const Value.absent(),
                Value<String?> rangeId = const Value.absent(),
                Value<String?> trainingGoal = const Value.absent(),
                Value<String?> conditions = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingSessionsCompanion(
                id: id,
                status: status,
                startedAtUtc: startedAtUtc,
                localUtcOffsetMinutes: localUtcOffsetMinutes,
                endedAtUtc: endedAtUtc,
                updatedAtUtc: updatedAtUtc,
                photoSafetyAcknowledgedAtUtc: photoSafetyAcknowledgedAtUtc,
                rangeId: rangeId,
                trainingGoal: trainingGoal,
                conditions: conditions,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required DateTime startedAtUtc,
                required int localUtcOffsetMinutes,
                Value<DateTime?> endedAtUtc = const Value.absent(),
                required DateTime updatedAtUtc,
                Value<DateTime?> photoSafetyAcknowledgedAtUtc =
                    const Value.absent(),
                Value<String?> rangeId = const Value.absent(),
                Value<String?> trainingGoal = const Value.absent(),
                Value<String?> conditions = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingSessionsCompanion.insert(
                id: id,
                status: status,
                startedAtUtc: startedAtUtc,
                localUtcOffsetMinutes: localUtcOffsetMinutes,
                endedAtUtc: endedAtUtc,
                updatedAtUtc: updatedAtUtc,
                photoSafetyAcknowledgedAtUtc: photoSafetyAcknowledgedAtUtc,
                rangeId: rangeId,
                trainingGoal: trainingGoal,
                conditions: conditions,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrainingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                rangeId = false,
                shootingSeriesRefs = false,
                imageAssetsRefs = false,
                trainingActivitiesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shootingSeriesRefs) db.shootingSeries,
                    if (imageAssetsRefs) db.imageAssets,
                    if (trainingActivitiesRefs) db.trainingActivities,
                  ],
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
                        if (rangeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rangeId,
                                    referencedTable:
                                        $$TrainingSessionsTableReferences
                                            ._rangeIdTable(db),
                                    referencedColumn:
                                        $$TrainingSessionsTableReferences
                                            ._rangeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shootingSeriesRefs)
                        await $_getPrefetchedData<
                          SessionRecord,
                          $TrainingSessionsTable,
                          SeriesRecord
                        >(
                          currentTable: table,
                          referencedTable: $$TrainingSessionsTableReferences
                              ._shootingSeriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrainingSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).shootingSeriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (imageAssetsRefs)
                        await $_getPrefetchedData<
                          SessionRecord,
                          $TrainingSessionsTable,
                          ImageAssetRecord
                        >(
                          currentTable: table,
                          referencedTable: $$TrainingSessionsTableReferences
                              ._imageAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrainingSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).imageAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trainingActivitiesRefs)
                        await $_getPrefetchedData<
                          SessionRecord,
                          $TrainingSessionsTable,
                          TrainingActivityRecord
                        >(
                          currentTable: table,
                          referencedTable: $$TrainingSessionsTableReferences
                              ._trainingActivitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrainingSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).trainingActivitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TrainingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainingSessionsTable,
      SessionRecord,
      $$TrainingSessionsTableFilterComposer,
      $$TrainingSessionsTableOrderingComposer,
      $$TrainingSessionsTableAnnotationComposer,
      $$TrainingSessionsTableCreateCompanionBuilder,
      $$TrainingSessionsTableUpdateCompanionBuilder,
      (SessionRecord, $$TrainingSessionsTableReferences),
      SessionRecord,
      PrefetchHooks Function({
        bool rangeId,
        bool shootingSeriesRefs,
        bool imageAssetsRefs,
        bool trainingActivitiesRefs,
      })
    >;
typedef $$ShootingSeriesTableCreateCompanionBuilder =
    ShootingSeriesCompanion Function({
      required String id,
      required String sessionId,
      required int sequenceNumber,
      required String status,
      required String targetProfileVersionedId,
      required String targetProfileJson,
      required double distanceMeters,
      required double projectileDiameterMm,
      Value<String?> cartridgeId,
      Value<int> shotCount,
      Value<int> maximumPossibleScore,
      Value<String?> firearmId,
      Value<String?> ammoLotId,
      Value<String?> notes,
      Value<int> totalScore,
      Value<int> innerTenCount,
      Value<int> missCount,
      Value<int> scorePenalty,
      Value<int?> scoredBullCount,
      Value<bool> hasBoundaryWarnings,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> confirmedAtUtc,
      Value<int> rowid,
    });
typedef $$ShootingSeriesTableUpdateCompanionBuilder =
    ShootingSeriesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> sequenceNumber,
      Value<String> status,
      Value<String> targetProfileVersionedId,
      Value<String> targetProfileJson,
      Value<double> distanceMeters,
      Value<double> projectileDiameterMm,
      Value<String?> cartridgeId,
      Value<int> shotCount,
      Value<int> maximumPossibleScore,
      Value<String?> firearmId,
      Value<String?> ammoLotId,
      Value<String?> notes,
      Value<int> totalScore,
      Value<int> innerTenCount,
      Value<int> missCount,
      Value<int> scorePenalty,
      Value<int?> scoredBullCount,
      Value<bool> hasBoundaryWarnings,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> confirmedAtUtc,
      Value<int> rowid,
    });

final class $$ShootingSeriesTableReferences
    extends BaseReferences<_$AppDatabase, $ShootingSeriesTable, SeriesRecord> {
  $$ShootingSeriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrainingSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .trainingSessions
      .createAlias('shooting_series__session_id__training_sessions__id');

  $$TrainingSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$TrainingSessionsTableTableManager(
      $_db,
      $_db.trainingSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CartridgesTable _cartridgeIdTable(_$AppDatabase db) => db.cartridges
      .createAlias('shooting_series__cartridge_id__cartridges__id');

  $$CartridgesTableProcessedTableManager? get cartridgeId {
    final $_column = $_itemColumn<String>('cartridge_id');
    if ($_column == null) return null;
    final manager = $$CartridgesTableTableManager(
      $_db,
      $_db.cartridges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cartridgeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FirearmsTable _firearmIdTable(_$AppDatabase db) =>
      db.firearms.createAlias('shooting_series__firearm_id__firearms__id');

  $$FirearmsTableProcessedTableManager? get firearmId {
    final $_column = $_itemColumn<String>('firearm_id');
    if ($_column == null) return null;
    final manager = $$FirearmsTableTableManager(
      $_db,
      $_db.firearms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firearmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AmmoLotsTable _ammoLotIdTable(_$AppDatabase db) =>
      db.ammoLots.createAlias('shooting_series__ammo_lot_id__ammo_lots__id');

  $$AmmoLotsTableProcessedTableManager? get ammoLotId {
    final $_column = $_itemColumn<String>('ammo_lot_id');
    if ($_column == null) return null;
    final manager = $$AmmoLotsTableTableManager(
      $_db,
      $_db.ammoLots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ammoLotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ImageAssetsTable, List<ImageAssetRecord>>
  _imageAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.imageAssets,
    aliasName: 'shooting_series__id__image_assets__series_id',
  );

  $$ImageAssetsTableProcessedTableManager get imageAssetsRefs {
    final manager = $$ImageAssetsTableTableManager(
      $_db,
      $_db.imageAssets,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imageAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisionAnalysesTable, List<VisionAnalysisRecord>>
  _visionAnalysesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visionAnalyses,
    aliasName: 'shooting_series__id__vision_analyses__series_id',
  );

  $$VisionAnalysesTableProcessedTableManager get visionAnalysesRefs {
    final manager = $$VisionAnalysesTableTableManager(
      $_db,
      $_db.visionAnalyses,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visionAnalysesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShotImpactsTable, List<ImpactRecord>>
  _shotImpactsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotImpacts,
    aliasName: 'shooting_series__id__shot_impacts__series_id',
  );

  $$ShotImpactsTableProcessedTableManager get shotImpactsRefs {
    final manager = $$ShotImpactsTableTableManager(
      $_db,
      $_db.shotImpacts,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotImpactsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SeriesReflectionsTable,
    List<SeriesReflectionRecord>
  >
  _seriesReflectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.seriesReflections,
        aliasName: 'shooting_series__id__series_reflections__series_id',
      );

  $$SeriesReflectionsTableProcessedTableManager get seriesReflectionsRefs {
    final manager = $$SeriesReflectionsTableTableManager(
      $_db,
      $_db.seriesReflections,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _seriesReflectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TrainingActivitySeriesLinksTable,
    List<TrainingActivitySeriesLinkRecord>
  >
  _trainingActivitySeriesLinksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.trainingActivitySeriesLinks,
        aliasName:
            'shooting_series__id__training_activity_series_links__series_id',
      );

  $$TrainingActivitySeriesLinksTableProcessedTableManager
  get trainingActivitySeriesLinksRefs {
    final manager = $$TrainingActivitySeriesLinksTableTableManager(
      $_db,
      $_db.trainingActivitySeriesLinks,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trainingActivitySeriesLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShootingSeriesTableFilterComposer
    extends Composer<_$AppDatabase, $ShootingSeriesTable> {
  $$ShootingSeriesTableFilterComposer({
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

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetProfileVersionedId => $composableBuilder(
    column: $table.targetProfileVersionedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetProfileJson => $composableBuilder(
    column: $table.targetProfileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shotCount => $composableBuilder(
    column: $table.shotCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maximumPossibleScore => $composableBuilder(
    column: $table.maximumPossibleScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get innerTenCount => $composableBuilder(
    column: $table.innerTenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missCount => $composableBuilder(
    column: $table.missCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scorePenalty => $composableBuilder(
    column: $table.scorePenalty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoredBullCount => $composableBuilder(
    column: $table.scoredBullCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasBoundaryWarnings => $composableBuilder(
    column: $table.hasBoundaryWarnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAtUtc => $composableBuilder(
    column: $table.confirmedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TrainingSessionsTableFilterComposer get sessionId {
    final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CartridgesTableFilterComposer get cartridgeId {
    final $$CartridgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableFilterComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FirearmsTableFilterComposer get firearmId {
    final $$FirearmsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableFilterComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmmoLotsTableFilterComposer get ammoLotId {
    final $$AmmoLotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ammoLotId,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableFilterComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> imageAssetsRefs(
    Expression<bool> Function($$ImageAssetsTableFilterComposer f) f,
  ) {
    final $$ImageAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableFilterComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visionAnalysesRefs(
    Expression<bool> Function($$VisionAnalysesTableFilterComposer f) f,
  ) {
    final $$VisionAnalysesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableFilterComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shotImpactsRefs(
    Expression<bool> Function($$ShotImpactsTableFilterComposer f) f,
  ) {
    final $$ShotImpactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotImpacts,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotImpactsTableFilterComposer(
            $db: $db,
            $table: $db.shotImpacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seriesReflectionsRefs(
    Expression<bool> Function($$SeriesReflectionsTableFilterComposer f) f,
  ) {
    final $$SeriesReflectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seriesReflections,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesReflectionsTableFilterComposer(
            $db: $db,
            $table: $db.seriesReflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trainingActivitySeriesLinksRefs(
    Expression<bool> Function(
      $$TrainingActivitySeriesLinksTableFilterComposer f,
    )
    f,
  ) {
    final $$TrainingActivitySeriesLinksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trainingActivitySeriesLinks,
          getReferencedColumn: (t) => t.seriesId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitySeriesLinksTableFilterComposer(
                $db: $db,
                $table: $db.trainingActivitySeriesLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ShootingSeriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShootingSeriesTable> {
  $$ShootingSeriesTableOrderingComposer({
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

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetProfileVersionedId => $composableBuilder(
    column: $table.targetProfileVersionedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetProfileJson => $composableBuilder(
    column: $table.targetProfileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shotCount => $composableBuilder(
    column: $table.shotCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maximumPossibleScore => $composableBuilder(
    column: $table.maximumPossibleScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get innerTenCount => $composableBuilder(
    column: $table.innerTenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missCount => $composableBuilder(
    column: $table.missCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scorePenalty => $composableBuilder(
    column: $table.scorePenalty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoredBullCount => $composableBuilder(
    column: $table.scoredBullCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasBoundaryWarnings => $composableBuilder(
    column: $table.hasBoundaryWarnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAtUtc => $composableBuilder(
    column: $table.confirmedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrainingSessionsTableOrderingComposer get sessionId {
    final $$TrainingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CartridgesTableOrderingComposer get cartridgeId {
    final $$CartridgesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableOrderingComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FirearmsTableOrderingComposer get firearmId {
    final $$FirearmsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableOrderingComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmmoLotsTableOrderingComposer get ammoLotId {
    final $$AmmoLotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ammoLotId,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableOrderingComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShootingSeriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShootingSeriesTable> {
  $$ShootingSeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get targetProfileVersionedId => $composableBuilder(
    column: $table.targetProfileVersionedId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetProfileJson => $composableBuilder(
    column: $table.targetProfileJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shotCount =>
      $composableBuilder(column: $table.shotCount, builder: (column) => column);

  GeneratedColumn<int> get maximumPossibleScore => $composableBuilder(
    column: $table.maximumPossibleScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get innerTenCount => $composableBuilder(
    column: $table.innerTenCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get missCount =>
      $composableBuilder(column: $table.missCount, builder: (column) => column);

  GeneratedColumn<int> get scorePenalty => $composableBuilder(
    column: $table.scorePenalty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoredBullCount => $composableBuilder(
    column: $table.scoredBullCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasBoundaryWarnings => $composableBuilder(
    column: $table.hasBoundaryWarnings,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAtUtc => $composableBuilder(
    column: $table.confirmedAtUtc,
    builder: (column) => column,
  );

  $$TrainingSessionsTableAnnotationComposer get sessionId {
    final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CartridgesTableAnnotationComposer get cartridgeId {
    final $$CartridgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableAnnotationComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FirearmsTableAnnotationComposer get firearmId {
    final $$FirearmsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableAnnotationComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmmoLotsTableAnnotationComposer get ammoLotId {
    final $$AmmoLotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ammoLotId,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableAnnotationComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> imageAssetsRefs<T extends Object>(
    Expression<T> Function($$ImageAssetsTableAnnotationComposer a) f,
  ) {
    final $$ImageAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visionAnalysesRefs<T extends Object>(
    Expression<T> Function($$VisionAnalysesTableAnnotationComposer a) f,
  ) {
    final $$VisionAnalysesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableAnnotationComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shotImpactsRefs<T extends Object>(
    Expression<T> Function($$ShotImpactsTableAnnotationComposer a) f,
  ) {
    final $$ShotImpactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotImpacts,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotImpactsTableAnnotationComposer(
            $db: $db,
            $table: $db.shotImpacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seriesReflectionsRefs<T extends Object>(
    Expression<T> Function($$SeriesReflectionsTableAnnotationComposer a) f,
  ) {
    final $$SeriesReflectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.seriesReflections,
          getReferencedColumn: (t) => t.seriesId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeriesReflectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.seriesReflections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> trainingActivitySeriesLinksRefs<T extends Object>(
    Expression<T> Function(
      $$TrainingActivitySeriesLinksTableAnnotationComposer a,
    )
    f,
  ) {
    final $$TrainingActivitySeriesLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trainingActivitySeriesLinks,
          getReferencedColumn: (t) => t.seriesId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitySeriesLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.trainingActivitySeriesLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ShootingSeriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShootingSeriesTable,
          SeriesRecord,
          $$ShootingSeriesTableFilterComposer,
          $$ShootingSeriesTableOrderingComposer,
          $$ShootingSeriesTableAnnotationComposer,
          $$ShootingSeriesTableCreateCompanionBuilder,
          $$ShootingSeriesTableUpdateCompanionBuilder,
          (SeriesRecord, $$ShootingSeriesTableReferences),
          SeriesRecord,
          PrefetchHooks Function({
            bool sessionId,
            bool cartridgeId,
            bool firearmId,
            bool ammoLotId,
            bool imageAssetsRefs,
            bool visionAnalysesRefs,
            bool shotImpactsRefs,
            bool seriesReflectionsRefs,
            bool trainingActivitySeriesLinksRefs,
          })
        > {
  $$ShootingSeriesTableTableManager(
    _$AppDatabase db,
    $ShootingSeriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShootingSeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShootingSeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShootingSeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> targetProfileVersionedId = const Value.absent(),
                Value<String> targetProfileJson = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double> projectileDiameterMm = const Value.absent(),
                Value<String?> cartridgeId = const Value.absent(),
                Value<int> shotCount = const Value.absent(),
                Value<int> maximumPossibleScore = const Value.absent(),
                Value<String?> firearmId = const Value.absent(),
                Value<String?> ammoLotId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> innerTenCount = const Value.absent(),
                Value<int> missCount = const Value.absent(),
                Value<int> scorePenalty = const Value.absent(),
                Value<int?> scoredBullCount = const Value.absent(),
                Value<bool> hasBoundaryWarnings = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> confirmedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShootingSeriesCompanion(
                id: id,
                sessionId: sessionId,
                sequenceNumber: sequenceNumber,
                status: status,
                targetProfileVersionedId: targetProfileVersionedId,
                targetProfileJson: targetProfileJson,
                distanceMeters: distanceMeters,
                projectileDiameterMm: projectileDiameterMm,
                cartridgeId: cartridgeId,
                shotCount: shotCount,
                maximumPossibleScore: maximumPossibleScore,
                firearmId: firearmId,
                ammoLotId: ammoLotId,
                notes: notes,
                totalScore: totalScore,
                innerTenCount: innerTenCount,
                missCount: missCount,
                scorePenalty: scorePenalty,
                scoredBullCount: scoredBullCount,
                hasBoundaryWarnings: hasBoundaryWarnings,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                confirmedAtUtc: confirmedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int sequenceNumber,
                required String status,
                required String targetProfileVersionedId,
                required String targetProfileJson,
                required double distanceMeters,
                required double projectileDiameterMm,
                Value<String?> cartridgeId = const Value.absent(),
                Value<int> shotCount = const Value.absent(),
                Value<int> maximumPossibleScore = const Value.absent(),
                Value<String?> firearmId = const Value.absent(),
                Value<String?> ammoLotId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> innerTenCount = const Value.absent(),
                Value<int> missCount = const Value.absent(),
                Value<int> scorePenalty = const Value.absent(),
                Value<int?> scoredBullCount = const Value.absent(),
                Value<bool> hasBoundaryWarnings = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> confirmedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShootingSeriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                sequenceNumber: sequenceNumber,
                status: status,
                targetProfileVersionedId: targetProfileVersionedId,
                targetProfileJson: targetProfileJson,
                distanceMeters: distanceMeters,
                projectileDiameterMm: projectileDiameterMm,
                cartridgeId: cartridgeId,
                shotCount: shotCount,
                maximumPossibleScore: maximumPossibleScore,
                firearmId: firearmId,
                ammoLotId: ammoLotId,
                notes: notes,
                totalScore: totalScore,
                innerTenCount: innerTenCount,
                missCount: missCount,
                scorePenalty: scorePenalty,
                scoredBullCount: scoredBullCount,
                hasBoundaryWarnings: hasBoundaryWarnings,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                confirmedAtUtc: confirmedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShootingSeriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionId = false,
                cartridgeId = false,
                firearmId = false,
                ammoLotId = false,
                imageAssetsRefs = false,
                visionAnalysesRefs = false,
                shotImpactsRefs = false,
                seriesReflectionsRefs = false,
                trainingActivitySeriesLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (imageAssetsRefs) db.imageAssets,
                    if (visionAnalysesRefs) db.visionAnalyses,
                    if (shotImpactsRefs) db.shotImpacts,
                    if (seriesReflectionsRefs) db.seriesReflections,
                    if (trainingActivitySeriesLinksRefs)
                      db.trainingActivitySeriesLinks,
                  ],
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
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$ShootingSeriesTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$ShootingSeriesTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cartridgeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cartridgeId,
                                    referencedTable:
                                        $$ShootingSeriesTableReferences
                                            ._cartridgeIdTable(db),
                                    referencedColumn:
                                        $$ShootingSeriesTableReferences
                                            ._cartridgeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (firearmId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.firearmId,
                                    referencedTable:
                                        $$ShootingSeriesTableReferences
                                            ._firearmIdTable(db),
                                    referencedColumn:
                                        $$ShootingSeriesTableReferences
                                            ._firearmIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (ammoLotId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ammoLotId,
                                    referencedTable:
                                        $$ShootingSeriesTableReferences
                                            ._ammoLotIdTable(db),
                                    referencedColumn:
                                        $$ShootingSeriesTableReferences
                                            ._ammoLotIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (imageAssetsRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $ShootingSeriesTable,
                          ImageAssetRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ShootingSeriesTableReferences
                              ._imageAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShootingSeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).imageAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visionAnalysesRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $ShootingSeriesTable,
                          VisionAnalysisRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ShootingSeriesTableReferences
                              ._visionAnalysesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShootingSeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).visionAnalysesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shotImpactsRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $ShootingSeriesTable,
                          ImpactRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ShootingSeriesTableReferences
                              ._shotImpactsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShootingSeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).shotImpactsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesReflectionsRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $ShootingSeriesTable,
                          SeriesReflectionRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ShootingSeriesTableReferences
                              ._seriesReflectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShootingSeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).seriesReflectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trainingActivitySeriesLinksRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $ShootingSeriesTable,
                          TrainingActivitySeriesLinkRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ShootingSeriesTableReferences
                              ._trainingActivitySeriesLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShootingSeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).trainingActivitySeriesLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShootingSeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShootingSeriesTable,
      SeriesRecord,
      $$ShootingSeriesTableFilterComposer,
      $$ShootingSeriesTableOrderingComposer,
      $$ShootingSeriesTableAnnotationComposer,
      $$ShootingSeriesTableCreateCompanionBuilder,
      $$ShootingSeriesTableUpdateCompanionBuilder,
      (SeriesRecord, $$ShootingSeriesTableReferences),
      SeriesRecord,
      PrefetchHooks Function({
        bool sessionId,
        bool cartridgeId,
        bool firearmId,
        bool ammoLotId,
        bool imageAssetsRefs,
        bool visionAnalysesRefs,
        bool shotImpactsRefs,
        bool seriesReflectionsRefs,
        bool trainingActivitySeriesLinksRefs,
      })
    >;
typedef $$ImageAssetsTableCreateCompanionBuilder =
    ImageAssetsCompanion Function({
      required String id,
      required String sessionId,
      Value<String?> seriesId,
      required String role,
      required String path,
      required String sha256,
      required int width,
      required int height,
      required int sizeBytes,
      Value<String?> caption,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$ImageAssetsTableUpdateCompanionBuilder =
    ImageAssetsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String?> seriesId,
      Value<String> role,
      Value<String> path,
      Value<String> sha256,
      Value<int> width,
      Value<int> height,
      Value<int> sizeBytes,
      Value<String?> caption,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$ImageAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $ImageAssetsTable, ImageAssetRecord> {
  $$ImageAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrainingSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .trainingSessions
      .createAlias('image_assets__session_id__training_sessions__id');

  $$TrainingSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$TrainingSessionsTableTableManager(
      $_db,
      $_db.trainingSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ShootingSeriesTable _seriesIdTable(_$AppDatabase db) => db
      .shootingSeries
      .createAlias('image_assets__series_id__shooting_series__id');

  $$ShootingSeriesTableProcessedTableManager? get seriesId {
    final $_column = $_itemColumn<String>('series_id');
    if ($_column == null) return null;
    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VisionAnalysesTable, List<VisionAnalysisRecord>>
  _visionAnalysesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visionAnalyses,
    aliasName: 'image_assets__id__vision_analyses__image_id',
  );

  $$VisionAnalysesTableProcessedTableManager get visionAnalysesRefs {
    final manager = $$VisionAnalysesTableTableManager(
      $_db,
      $_db.visionAnalyses,
    ).filter((f) => f.imageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visionAnalysesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShotImpactsTable, List<ImpactRecord>>
  _shotImpactsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotImpacts,
    aliasName: 'image_assets__id__shot_impacts__source_image_id',
  );

  $$ShotImpactsTableProcessedTableManager get shotImpactsRefs {
    final manager = $$ShotImpactsTableTableManager(
      $_db,
      $_db.shotImpacts,
    ).filter((f) => f.sourceImageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotImpactsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PhotoAlignmentsTable, List<PhotoAlignmentRecord>>
  _photoAlignmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.photoAlignments,
    aliasName: 'image_assets__id__photo_alignments__image_id',
  );

  $$PhotoAlignmentsTableProcessedTableManager get photoAlignmentsRefs {
    final manager = $$PhotoAlignmentsTableTableManager(
      $_db,
      $_db.photoAlignments,
    ).filter((f) => f.imageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _photoAlignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ImageAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $ImageAssetsTable> {
  $$ImageAssetsTableFilterComposer({
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

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TrainingSessionsTableFilterComposer get sessionId {
    final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShootingSeriesTableFilterComposer get seriesId {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> visionAnalysesRefs(
    Expression<bool> Function($$VisionAnalysesTableFilterComposer f) f,
  ) {
    final $$VisionAnalysesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableFilterComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shotImpactsRefs(
    Expression<bool> Function($$ShotImpactsTableFilterComposer f) f,
  ) {
    final $$ShotImpactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotImpacts,
      getReferencedColumn: (t) => t.sourceImageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotImpactsTableFilterComposer(
            $db: $db,
            $table: $db.shotImpacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> photoAlignmentsRefs(
    Expression<bool> Function($$PhotoAlignmentsTableFilterComposer f) f,
  ) {
    final $$PhotoAlignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photoAlignments,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotoAlignmentsTableFilterComposer(
            $db: $db,
            $table: $db.photoAlignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImageAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageAssetsTable> {
  $$ImageAssetsTableOrderingComposer({
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

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrainingSessionsTableOrderingComposer get sessionId {
    final $$TrainingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShootingSeriesTableOrderingComposer get seriesId {
    final $$ShootingSeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableOrderingComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageAssetsTable> {
  $$ImageAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TrainingSessionsTableAnnotationComposer get sessionId {
    final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShootingSeriesTableAnnotationComposer get seriesId {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> visionAnalysesRefs<T extends Object>(
    Expression<T> Function($$VisionAnalysesTableAnnotationComposer a) f,
  ) {
    final $$VisionAnalysesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableAnnotationComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shotImpactsRefs<T extends Object>(
    Expression<T> Function($$ShotImpactsTableAnnotationComposer a) f,
  ) {
    final $$ShotImpactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotImpacts,
      getReferencedColumn: (t) => t.sourceImageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotImpactsTableAnnotationComposer(
            $db: $db,
            $table: $db.shotImpacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> photoAlignmentsRefs<T extends Object>(
    Expression<T> Function($$PhotoAlignmentsTableAnnotationComposer a) f,
  ) {
    final $$PhotoAlignmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photoAlignments,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotoAlignmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.photoAlignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImageAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageAssetsTable,
          ImageAssetRecord,
          $$ImageAssetsTableFilterComposer,
          $$ImageAssetsTableOrderingComposer,
          $$ImageAssetsTableAnnotationComposer,
          $$ImageAssetsTableCreateCompanionBuilder,
          $$ImageAssetsTableUpdateCompanionBuilder,
          (ImageAssetRecord, $$ImageAssetsTableReferences),
          ImageAssetRecord,
          PrefetchHooks Function({
            bool sessionId,
            bool seriesId,
            bool visionAnalysesRefs,
            bool shotImpactsRefs,
            bool photoAlignmentsRefs,
          })
        > {
  $$ImageAssetsTableTableManager(_$AppDatabase db, $ImageAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageAssetsCompanion(
                id: id,
                sessionId: sessionId,
                seriesId: seriesId,
                role: role,
                path: path,
                sha256: sha256,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                caption: caption,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                Value<String?> seriesId = const Value.absent(),
                required String role,
                required String path,
                required String sha256,
                required int width,
                required int height,
                required int sizeBytes,
                Value<String?> caption = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => ImageAssetsCompanion.insert(
                id: id,
                sessionId: sessionId,
                seriesId: seriesId,
                role: role,
                path: path,
                sha256: sha256,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                caption: caption,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImageAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionId = false,
                seriesId = false,
                visionAnalysesRefs = false,
                shotImpactsRefs = false,
                photoAlignmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (visionAnalysesRefs) db.visionAnalyses,
                    if (shotImpactsRefs) db.shotImpacts,
                    if (photoAlignmentsRefs) db.photoAlignments,
                  ],
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
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$ImageAssetsTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$ImageAssetsTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (seriesId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.seriesId,
                                    referencedTable:
                                        $$ImageAssetsTableReferences
                                            ._seriesIdTable(db),
                                    referencedColumn:
                                        $$ImageAssetsTableReferences
                                            ._seriesIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (visionAnalysesRefs)
                        await $_getPrefetchedData<
                          ImageAssetRecord,
                          $ImageAssetsTable,
                          VisionAnalysisRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ImageAssetsTableReferences
                              ._visionAnalysesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImageAssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).visionAnalysesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.imageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shotImpactsRefs)
                        await $_getPrefetchedData<
                          ImageAssetRecord,
                          $ImageAssetsTable,
                          ImpactRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ImageAssetsTableReferences
                              ._shotImpactsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImageAssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).shotImpactsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceImageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (photoAlignmentsRefs)
                        await $_getPrefetchedData<
                          ImageAssetRecord,
                          $ImageAssetsTable,
                          PhotoAlignmentRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ImageAssetsTableReferences
                              ._photoAlignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImageAssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).photoAlignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.imageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ImageAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageAssetsTable,
      ImageAssetRecord,
      $$ImageAssetsTableFilterComposer,
      $$ImageAssetsTableOrderingComposer,
      $$ImageAssetsTableAnnotationComposer,
      $$ImageAssetsTableCreateCompanionBuilder,
      $$ImageAssetsTableUpdateCompanionBuilder,
      (ImageAssetRecord, $$ImageAssetsTableReferences),
      ImageAssetRecord,
      PrefetchHooks Function({
        bool sessionId,
        bool seriesId,
        bool visionAnalysesRefs,
        bool shotImpactsRefs,
        bool photoAlignmentsRefs,
      })
    >;
typedef $$VisionScanDraftsTableCreateCompanionBuilder =
    VisionScanDraftsCompanion Function({
      required String id,
      required String status,
      required String originalImagePath,
      required String sha256,
      required int width,
      required int height,
      required int sizeBytes,
      required String targetProfileJson,
      required double projectileDiameterMm,
      Value<String?> qualityJson,
      Value<String?> registrationJson,
      Value<String?> candidatesJson,
      Value<String?> reviewJson,
      Value<String?> engineVersion,
      Value<String?> failureCode,
      Value<int> rotationQuarterTurns,
      Value<String> alignmentMode,
      Value<String?> anchorsJson,
      Value<double?> reprojectionRmsMm,
      Value<double?> reprojectionMaxMm,
      Value<String> planarityStatus,
      Value<String?> alignmentAlgorithmVersion,
      Value<DateTime?> alignmentConfirmedAtUtc,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$VisionScanDraftsTableUpdateCompanionBuilder =
    VisionScanDraftsCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String> originalImagePath,
      Value<String> sha256,
      Value<int> width,
      Value<int> height,
      Value<int> sizeBytes,
      Value<String> targetProfileJson,
      Value<double> projectileDiameterMm,
      Value<String?> qualityJson,
      Value<String?> registrationJson,
      Value<String?> candidatesJson,
      Value<String?> reviewJson,
      Value<String?> engineVersion,
      Value<String?> failureCode,
      Value<int> rotationQuarterTurns,
      Value<String> alignmentMode,
      Value<String?> anchorsJson,
      Value<double?> reprojectionRmsMm,
      Value<double?> reprojectionMaxMm,
      Value<String> planarityStatus,
      Value<String?> alignmentAlgorithmVersion,
      Value<DateTime?> alignmentConfirmedAtUtc,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$VisionScanDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $VisionScanDraftsTable> {
  $$VisionScanDraftsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetProfileJson => $composableBuilder(
    column: $table.targetProfileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationJson => $composableBuilder(
    column: $table.registrationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidatesJson => $composableBuilder(
    column: $table.candidatesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotationQuarterTurns => $composableBuilder(
    column: $table.rotationQuarterTurns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alignmentMode => $composableBuilder(
    column: $table.alignmentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorsJson => $composableBuilder(
    column: $table.anchorsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reprojectionRmsMm => $composableBuilder(
    column: $table.reprojectionRmsMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reprojectionMaxMm => $composableBuilder(
    column: $table.reprojectionMaxMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planarityStatus => $composableBuilder(
    column: $table.planarityStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alignmentAlgorithmVersion => $composableBuilder(
    column: $table.alignmentAlgorithmVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get alignmentConfirmedAtUtc => $composableBuilder(
    column: $table.alignmentConfirmedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisionScanDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisionScanDraftsTable> {
  $$VisionScanDraftsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetProfileJson => $composableBuilder(
    column: $table.targetProfileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationJson => $composableBuilder(
    column: $table.registrationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidatesJson => $composableBuilder(
    column: $table.candidatesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotationQuarterTurns => $composableBuilder(
    column: $table.rotationQuarterTurns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alignmentMode => $composableBuilder(
    column: $table.alignmentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorsJson => $composableBuilder(
    column: $table.anchorsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reprojectionRmsMm => $composableBuilder(
    column: $table.reprojectionRmsMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reprojectionMaxMm => $composableBuilder(
    column: $table.reprojectionMaxMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planarityStatus => $composableBuilder(
    column: $table.planarityStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alignmentAlgorithmVersion => $composableBuilder(
    column: $table.alignmentAlgorithmVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get alignmentConfirmedAtUtc => $composableBuilder(
    column: $table.alignmentConfirmedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisionScanDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisionScanDraftsTable> {
  $$VisionScanDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get targetProfileJson => $composableBuilder(
    column: $table.targetProfileJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get projectileDiameterMm => $composableBuilder(
    column: $table.projectileDiameterMm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get registrationJson => $composableBuilder(
    column: $table.registrationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get candidatesJson => $composableBuilder(
    column: $table.candidatesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rotationQuarterTurns => $composableBuilder(
    column: $table.rotationQuarterTurns,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alignmentMode => $composableBuilder(
    column: $table.alignmentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchorsJson => $composableBuilder(
    column: $table.anchorsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reprojectionRmsMm => $composableBuilder(
    column: $table.reprojectionRmsMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reprojectionMaxMm => $composableBuilder(
    column: $table.reprojectionMaxMm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planarityStatus => $composableBuilder(
    column: $table.planarityStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alignmentAlgorithmVersion => $composableBuilder(
    column: $table.alignmentAlgorithmVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get alignmentConfirmedAtUtc => $composableBuilder(
    column: $table.alignmentConfirmedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$VisionScanDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisionScanDraftsTable,
          VisionScanDraftRecord,
          $$VisionScanDraftsTableFilterComposer,
          $$VisionScanDraftsTableOrderingComposer,
          $$VisionScanDraftsTableAnnotationComposer,
          $$VisionScanDraftsTableCreateCompanionBuilder,
          $$VisionScanDraftsTableUpdateCompanionBuilder,
          (
            VisionScanDraftRecord,
            BaseReferences<
              _$AppDatabase,
              $VisionScanDraftsTable,
              VisionScanDraftRecord
            >,
          ),
          VisionScanDraftRecord,
          PrefetchHooks Function()
        > {
  $$VisionScanDraftsTableTableManager(
    _$AppDatabase db,
    $VisionScanDraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisionScanDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisionScanDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisionScanDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> originalImagePath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> targetProfileJson = const Value.absent(),
                Value<double> projectileDiameterMm = const Value.absent(),
                Value<String?> qualityJson = const Value.absent(),
                Value<String?> registrationJson = const Value.absent(),
                Value<String?> candidatesJson = const Value.absent(),
                Value<String?> reviewJson = const Value.absent(),
                Value<String?> engineVersion = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> rotationQuarterTurns = const Value.absent(),
                Value<String> alignmentMode = const Value.absent(),
                Value<String?> anchorsJson = const Value.absent(),
                Value<double?> reprojectionRmsMm = const Value.absent(),
                Value<double?> reprojectionMaxMm = const Value.absent(),
                Value<String> planarityStatus = const Value.absent(),
                Value<String?> alignmentAlgorithmVersion = const Value.absent(),
                Value<DateTime?> alignmentConfirmedAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisionScanDraftsCompanion(
                id: id,
                status: status,
                originalImagePath: originalImagePath,
                sha256: sha256,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                targetProfileJson: targetProfileJson,
                projectileDiameterMm: projectileDiameterMm,
                qualityJson: qualityJson,
                registrationJson: registrationJson,
                candidatesJson: candidatesJson,
                reviewJson: reviewJson,
                engineVersion: engineVersion,
                failureCode: failureCode,
                rotationQuarterTurns: rotationQuarterTurns,
                alignmentMode: alignmentMode,
                anchorsJson: anchorsJson,
                reprojectionRmsMm: reprojectionRmsMm,
                reprojectionMaxMm: reprojectionMaxMm,
                planarityStatus: planarityStatus,
                alignmentAlgorithmVersion: alignmentAlgorithmVersion,
                alignmentConfirmedAtUtc: alignmentConfirmedAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required String originalImagePath,
                required String sha256,
                required int width,
                required int height,
                required int sizeBytes,
                required String targetProfileJson,
                required double projectileDiameterMm,
                Value<String?> qualityJson = const Value.absent(),
                Value<String?> registrationJson = const Value.absent(),
                Value<String?> candidatesJson = const Value.absent(),
                Value<String?> reviewJson = const Value.absent(),
                Value<String?> engineVersion = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> rotationQuarterTurns = const Value.absent(),
                Value<String> alignmentMode = const Value.absent(),
                Value<String?> anchorsJson = const Value.absent(),
                Value<double?> reprojectionRmsMm = const Value.absent(),
                Value<double?> reprojectionMaxMm = const Value.absent(),
                Value<String> planarityStatus = const Value.absent(),
                Value<String?> alignmentAlgorithmVersion = const Value.absent(),
                Value<DateTime?> alignmentConfirmedAtUtc = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => VisionScanDraftsCompanion.insert(
                id: id,
                status: status,
                originalImagePath: originalImagePath,
                sha256: sha256,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                targetProfileJson: targetProfileJson,
                projectileDiameterMm: projectileDiameterMm,
                qualityJson: qualityJson,
                registrationJson: registrationJson,
                candidatesJson: candidatesJson,
                reviewJson: reviewJson,
                engineVersion: engineVersion,
                failureCode: failureCode,
                rotationQuarterTurns: rotationQuarterTurns,
                alignmentMode: alignmentMode,
                anchorsJson: anchorsJson,
                reprojectionRmsMm: reprojectionRmsMm,
                reprojectionMaxMm: reprojectionMaxMm,
                planarityStatus: planarityStatus,
                alignmentAlgorithmVersion: alignmentAlgorithmVersion,
                alignmentConfirmedAtUtc: alignmentConfirmedAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisionScanDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisionScanDraftsTable,
      VisionScanDraftRecord,
      $$VisionScanDraftsTableFilterComposer,
      $$VisionScanDraftsTableOrderingComposer,
      $$VisionScanDraftsTableAnnotationComposer,
      $$VisionScanDraftsTableCreateCompanionBuilder,
      $$VisionScanDraftsTableUpdateCompanionBuilder,
      (
        VisionScanDraftRecord,
        BaseReferences<
          _$AppDatabase,
          $VisionScanDraftsTable,
          VisionScanDraftRecord
        >,
      ),
      VisionScanDraftRecord,
      PrefetchHooks Function()
    >;
typedef $$VisionAnalysesTableCreateCompanionBuilder =
    VisionAnalysesCompanion Function({
      required String id,
      required String seriesId,
      required String imageId,
      required String engineVersion,
      required String backendVersion,
      Value<String?> modelVersion,
      required String qualityJson,
      required String registrationJson,
      required String candidatesJson,
      required String reviewJson,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$VisionAnalysesTableUpdateCompanionBuilder =
    VisionAnalysesCompanion Function({
      Value<String> id,
      Value<String> seriesId,
      Value<String> imageId,
      Value<String> engineVersion,
      Value<String> backendVersion,
      Value<String?> modelVersion,
      Value<String> qualityJson,
      Value<String> registrationJson,
      Value<String> candidatesJson,
      Value<String> reviewJson,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

final class $$VisionAnalysesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VisionAnalysesTable,
          VisionAnalysisRecord
        > {
  $$VisionAnalysesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShootingSeriesTable _seriesIdTable(_$AppDatabase db) => db
      .shootingSeries
      .createAlias('vision_analyses__series_id__shooting_series__id');

  $$ShootingSeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ImageAssetsTable _imageIdTable(_$AppDatabase db) =>
      db.imageAssets.createAlias('vision_analyses__image_id__image_assets__id');

  $$ImageAssetsTableProcessedTableManager get imageId {
    final $_column = $_itemColumn<String>('image_id')!;

    final manager = $$ImageAssetsTableTableManager(
      $_db,
      $_db.imageAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_imageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShotImpactsTable, List<ImpactRecord>>
  _shotImpactsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotImpacts,
    aliasName: 'vision_analyses__id__shot_impacts__vision_analysis_id',
  );

  $$ShotImpactsTableProcessedTableManager get shotImpactsRefs {
    final manager = $$ShotImpactsTableTableManager($_db, $_db.shotImpacts)
        .filter(
          (f) => f.visionAnalysisId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_shotImpactsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VisionAnalysesTableFilterComposer
    extends Composer<_$AppDatabase, $VisionAnalysesTable> {
  $$VisionAnalysesTableFilterComposer({
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

  ColumnFilters<String> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendVersion => $composableBuilder(
    column: $table.backendVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationJson => $composableBuilder(
    column: $table.registrationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidatesJson => $composableBuilder(
    column: $table.candidatesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$ShootingSeriesTableFilterComposer get seriesId {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImageAssetsTableFilterComposer get imageId {
    final $$ImageAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableFilterComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shotImpactsRefs(
    Expression<bool> Function($$ShotImpactsTableFilterComposer f) f,
  ) {
    final $$ShotImpactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotImpacts,
      getReferencedColumn: (t) => t.visionAnalysisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotImpactsTableFilterComposer(
            $db: $db,
            $table: $db.shotImpacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisionAnalysesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisionAnalysesTable> {
  $$VisionAnalysesTableOrderingComposer({
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

  ColumnOrderings<String> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendVersion => $composableBuilder(
    column: $table.backendVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationJson => $composableBuilder(
    column: $table.registrationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidatesJson => $composableBuilder(
    column: $table.candidatesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShootingSeriesTableOrderingComposer get seriesId {
    final $$ShootingSeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableOrderingComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImageAssetsTableOrderingComposer get imageId {
    final $$ImageAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisionAnalysesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisionAnalysesTable> {
  $$VisionAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backendVersion => $composableBuilder(
    column: $table.backendVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get registrationJson => $composableBuilder(
    column: $table.registrationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get candidatesJson => $composableBuilder(
    column: $table.candidatesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$ShootingSeriesTableAnnotationComposer get seriesId {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImageAssetsTableAnnotationComposer get imageId {
    final $$ImageAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shotImpactsRefs<T extends Object>(
    Expression<T> Function($$ShotImpactsTableAnnotationComposer a) f,
  ) {
    final $$ShotImpactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotImpacts,
      getReferencedColumn: (t) => t.visionAnalysisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotImpactsTableAnnotationComposer(
            $db: $db,
            $table: $db.shotImpacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisionAnalysesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisionAnalysesTable,
          VisionAnalysisRecord,
          $$VisionAnalysesTableFilterComposer,
          $$VisionAnalysesTableOrderingComposer,
          $$VisionAnalysesTableAnnotationComposer,
          $$VisionAnalysesTableCreateCompanionBuilder,
          $$VisionAnalysesTableUpdateCompanionBuilder,
          (VisionAnalysisRecord, $$VisionAnalysesTableReferences),
          VisionAnalysisRecord,
          PrefetchHooks Function({
            bool seriesId,
            bool imageId,
            bool shotImpactsRefs,
          })
        > {
  $$VisionAnalysesTableTableManager(
    _$AppDatabase db,
    $VisionAnalysesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisionAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisionAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisionAnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> imageId = const Value.absent(),
                Value<String> engineVersion = const Value.absent(),
                Value<String> backendVersion = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<String> qualityJson = const Value.absent(),
                Value<String> registrationJson = const Value.absent(),
                Value<String> candidatesJson = const Value.absent(),
                Value<String> reviewJson = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisionAnalysesCompanion(
                id: id,
                seriesId: seriesId,
                imageId: imageId,
                engineVersion: engineVersion,
                backendVersion: backendVersion,
                modelVersion: modelVersion,
                qualityJson: qualityJson,
                registrationJson: registrationJson,
                candidatesJson: candidatesJson,
                reviewJson: reviewJson,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seriesId,
                required String imageId,
                required String engineVersion,
                required String backendVersion,
                Value<String?> modelVersion = const Value.absent(),
                required String qualityJson,
                required String registrationJson,
                required String candidatesJson,
                required String reviewJson,
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => VisionAnalysesCompanion.insert(
                id: id,
                seriesId: seriesId,
                imageId: imageId,
                engineVersion: engineVersion,
                backendVersion: backendVersion,
                modelVersion: modelVersion,
                qualityJson: qualityJson,
                registrationJson: registrationJson,
                candidatesJson: candidatesJson,
                reviewJson: reviewJson,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisionAnalysesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({seriesId = false, imageId = false, shotImpactsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shotImpactsRefs) db.shotImpacts,
                  ],
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
                        if (seriesId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.seriesId,
                                    referencedTable:
                                        $$VisionAnalysesTableReferences
                                            ._seriesIdTable(db),
                                    referencedColumn:
                                        $$VisionAnalysesTableReferences
                                            ._seriesIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (imageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.imageId,
                                    referencedTable:
                                        $$VisionAnalysesTableReferences
                                            ._imageIdTable(db),
                                    referencedColumn:
                                        $$VisionAnalysesTableReferences
                                            ._imageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shotImpactsRefs)
                        await $_getPrefetchedData<
                          VisionAnalysisRecord,
                          $VisionAnalysesTable,
                          ImpactRecord
                        >(
                          currentTable: table,
                          referencedTable: $$VisionAnalysesTableReferences
                              ._shotImpactsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisionAnalysesTableReferences(
                                db,
                                table,
                                p0,
                              ).shotImpactsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visionAnalysisId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VisionAnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisionAnalysesTable,
      VisionAnalysisRecord,
      $$VisionAnalysesTableFilterComposer,
      $$VisionAnalysesTableOrderingComposer,
      $$VisionAnalysesTableAnnotationComposer,
      $$VisionAnalysesTableCreateCompanionBuilder,
      $$VisionAnalysesTableUpdateCompanionBuilder,
      (VisionAnalysisRecord, $$VisionAnalysesTableReferences),
      VisionAnalysisRecord,
      PrefetchHooks Function({
        bool seriesId,
        bool imageId,
        bool shotImpactsRefs,
      })
    >;
typedef $$ShotImpactsTableCreateCompanionBuilder =
    ShotImpactsCompanion Function({
      required String id,
      required String seriesId,
      required double xMm,
      required double yMm,
      Value<String?> sourceImageId,
      Value<double?> imageXNormalized,
      Value<double?> imageYNormalized,
      Value<int> multiplicity,
      Value<bool> isMiss,
      Value<bool> isPositionUncertain,
      Value<String?> targetBullId,
      required int scoreValue,
      Value<int> rawScoreValue,
      Value<String> scoreDisposition,
      Value<bool> isInnerTen,
      Value<bool> isBoundaryUncertain,
      Value<String> placementMethod,
      Value<String?> visionAnalysisId,
      Value<double?> positionalUncertaintyMm,
      Value<int> rowid,
    });
typedef $$ShotImpactsTableUpdateCompanionBuilder =
    ShotImpactsCompanion Function({
      Value<String> id,
      Value<String> seriesId,
      Value<double> xMm,
      Value<double> yMm,
      Value<String?> sourceImageId,
      Value<double?> imageXNormalized,
      Value<double?> imageYNormalized,
      Value<int> multiplicity,
      Value<bool> isMiss,
      Value<bool> isPositionUncertain,
      Value<String?> targetBullId,
      Value<int> scoreValue,
      Value<int> rawScoreValue,
      Value<String> scoreDisposition,
      Value<bool> isInnerTen,
      Value<bool> isBoundaryUncertain,
      Value<String> placementMethod,
      Value<String?> visionAnalysisId,
      Value<double?> positionalUncertaintyMm,
      Value<int> rowid,
    });

final class $$ShotImpactsTableReferences
    extends BaseReferences<_$AppDatabase, $ShotImpactsTable, ImpactRecord> {
  $$ShotImpactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShootingSeriesTable _seriesIdTable(_$AppDatabase db) => db
      .shootingSeries
      .createAlias('shot_impacts__series_id__shooting_series__id');

  $$ShootingSeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ImageAssetsTable _sourceImageIdTable(_$AppDatabase db) => db
      .imageAssets
      .createAlias('shot_impacts__source_image_id__image_assets__id');

  $$ImageAssetsTableProcessedTableManager? get sourceImageId {
    final $_column = $_itemColumn<String>('source_image_id');
    if ($_column == null) return null;
    final manager = $$ImageAssetsTableTableManager(
      $_db,
      $_db.imageAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceImageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VisionAnalysesTable _visionAnalysisIdTable(_$AppDatabase db) => db
      .visionAnalyses
      .createAlias('shot_impacts__vision_analysis_id__vision_analyses__id');

  $$VisionAnalysesTableProcessedTableManager? get visionAnalysisId {
    final $_column = $_itemColumn<String>('vision_analysis_id');
    if ($_column == null) return null;
    final manager = $$VisionAnalysesTableTableManager(
      $_db,
      $_db.visionAnalyses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visionAnalysisIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShotImpactsTableFilterComposer
    extends Composer<_$AppDatabase, $ShotImpactsTable> {
  $$ShotImpactsTableFilterComposer({
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

  ColumnFilters<double> get xMm => $composableBuilder(
    column: $table.xMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yMm => $composableBuilder(
    column: $table.yMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get imageXNormalized => $composableBuilder(
    column: $table.imageXNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get imageYNormalized => $composableBuilder(
    column: $table.imageYNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get multiplicity => $composableBuilder(
    column: $table.multiplicity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMiss => $composableBuilder(
    column: $table.isMiss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPositionUncertain => $composableBuilder(
    column: $table.isPositionUncertain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetBullId => $composableBuilder(
    column: $table.targetBullId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreValue => $composableBuilder(
    column: $table.scoreValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawScoreValue => $composableBuilder(
    column: $table.rawScoreValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoreDisposition => $composableBuilder(
    column: $table.scoreDisposition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInnerTen => $composableBuilder(
    column: $table.isInnerTen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBoundaryUncertain => $composableBuilder(
    column: $table.isBoundaryUncertain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placementMethod => $composableBuilder(
    column: $table.placementMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get positionalUncertaintyMm => $composableBuilder(
    column: $table.positionalUncertaintyMm,
    builder: (column) => ColumnFilters(column),
  );

  $$ShootingSeriesTableFilterComposer get seriesId {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImageAssetsTableFilterComposer get sourceImageId {
    final $$ImageAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceImageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableFilterComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisionAnalysesTableFilterComposer get visionAnalysisId {
    final $$VisionAnalysesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visionAnalysisId,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableFilterComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotImpactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShotImpactsTable> {
  $$ShotImpactsTableOrderingComposer({
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

  ColumnOrderings<double> get xMm => $composableBuilder(
    column: $table.xMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yMm => $composableBuilder(
    column: $table.yMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get imageXNormalized => $composableBuilder(
    column: $table.imageXNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get imageYNormalized => $composableBuilder(
    column: $table.imageYNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get multiplicity => $composableBuilder(
    column: $table.multiplicity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMiss => $composableBuilder(
    column: $table.isMiss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPositionUncertain => $composableBuilder(
    column: $table.isPositionUncertain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetBullId => $composableBuilder(
    column: $table.targetBullId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreValue => $composableBuilder(
    column: $table.scoreValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawScoreValue => $composableBuilder(
    column: $table.rawScoreValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoreDisposition => $composableBuilder(
    column: $table.scoreDisposition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInnerTen => $composableBuilder(
    column: $table.isInnerTen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBoundaryUncertain => $composableBuilder(
    column: $table.isBoundaryUncertain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placementMethod => $composableBuilder(
    column: $table.placementMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get positionalUncertaintyMm => $composableBuilder(
    column: $table.positionalUncertaintyMm,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShootingSeriesTableOrderingComposer get seriesId {
    final $$ShootingSeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableOrderingComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImageAssetsTableOrderingComposer get sourceImageId {
    final $$ImageAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceImageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisionAnalysesTableOrderingComposer get visionAnalysisId {
    final $$VisionAnalysesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visionAnalysisId,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableOrderingComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotImpactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShotImpactsTable> {
  $$ShotImpactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get xMm =>
      $composableBuilder(column: $table.xMm, builder: (column) => column);

  GeneratedColumn<double> get yMm =>
      $composableBuilder(column: $table.yMm, builder: (column) => column);

  GeneratedColumn<double> get imageXNormalized => $composableBuilder(
    column: $table.imageXNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<double> get imageYNormalized => $composableBuilder(
    column: $table.imageYNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<int> get multiplicity => $composableBuilder(
    column: $table.multiplicity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMiss =>
      $composableBuilder(column: $table.isMiss, builder: (column) => column);

  GeneratedColumn<bool> get isPositionUncertain => $composableBuilder(
    column: $table.isPositionUncertain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetBullId => $composableBuilder(
    column: $table.targetBullId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreValue => $composableBuilder(
    column: $table.scoreValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rawScoreValue => $composableBuilder(
    column: $table.rawScoreValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scoreDisposition => $composableBuilder(
    column: $table.scoreDisposition,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isInnerTen => $composableBuilder(
    column: $table.isInnerTen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBoundaryUncertain => $composableBuilder(
    column: $table.isBoundaryUncertain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get placementMethod => $composableBuilder(
    column: $table.placementMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get positionalUncertaintyMm => $composableBuilder(
    column: $table.positionalUncertaintyMm,
    builder: (column) => column,
  );

  $$ShootingSeriesTableAnnotationComposer get seriesId {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImageAssetsTableAnnotationComposer get sourceImageId {
    final $$ImageAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceImageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisionAnalysesTableAnnotationComposer get visionAnalysisId {
    final $$VisionAnalysesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visionAnalysisId,
      referencedTable: $db.visionAnalyses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisionAnalysesTableAnnotationComposer(
            $db: $db,
            $table: $db.visionAnalyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotImpactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotImpactsTable,
          ImpactRecord,
          $$ShotImpactsTableFilterComposer,
          $$ShotImpactsTableOrderingComposer,
          $$ShotImpactsTableAnnotationComposer,
          $$ShotImpactsTableCreateCompanionBuilder,
          $$ShotImpactsTableUpdateCompanionBuilder,
          (ImpactRecord, $$ShotImpactsTableReferences),
          ImpactRecord,
          PrefetchHooks Function({
            bool seriesId,
            bool sourceImageId,
            bool visionAnalysisId,
          })
        > {
  $$ShotImpactsTableTableManager(_$AppDatabase db, $ShotImpactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShotImpactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShotImpactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShotImpactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<double> xMm = const Value.absent(),
                Value<double> yMm = const Value.absent(),
                Value<String?> sourceImageId = const Value.absent(),
                Value<double?> imageXNormalized = const Value.absent(),
                Value<double?> imageYNormalized = const Value.absent(),
                Value<int> multiplicity = const Value.absent(),
                Value<bool> isMiss = const Value.absent(),
                Value<bool> isPositionUncertain = const Value.absent(),
                Value<String?> targetBullId = const Value.absent(),
                Value<int> scoreValue = const Value.absent(),
                Value<int> rawScoreValue = const Value.absent(),
                Value<String> scoreDisposition = const Value.absent(),
                Value<bool> isInnerTen = const Value.absent(),
                Value<bool> isBoundaryUncertain = const Value.absent(),
                Value<String> placementMethod = const Value.absent(),
                Value<String?> visionAnalysisId = const Value.absent(),
                Value<double?> positionalUncertaintyMm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotImpactsCompanion(
                id: id,
                seriesId: seriesId,
                xMm: xMm,
                yMm: yMm,
                sourceImageId: sourceImageId,
                imageXNormalized: imageXNormalized,
                imageYNormalized: imageYNormalized,
                multiplicity: multiplicity,
                isMiss: isMiss,
                isPositionUncertain: isPositionUncertain,
                targetBullId: targetBullId,
                scoreValue: scoreValue,
                rawScoreValue: rawScoreValue,
                scoreDisposition: scoreDisposition,
                isInnerTen: isInnerTen,
                isBoundaryUncertain: isBoundaryUncertain,
                placementMethod: placementMethod,
                visionAnalysisId: visionAnalysisId,
                positionalUncertaintyMm: positionalUncertaintyMm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seriesId,
                required double xMm,
                required double yMm,
                Value<String?> sourceImageId = const Value.absent(),
                Value<double?> imageXNormalized = const Value.absent(),
                Value<double?> imageYNormalized = const Value.absent(),
                Value<int> multiplicity = const Value.absent(),
                Value<bool> isMiss = const Value.absent(),
                Value<bool> isPositionUncertain = const Value.absent(),
                Value<String?> targetBullId = const Value.absent(),
                required int scoreValue,
                Value<int> rawScoreValue = const Value.absent(),
                Value<String> scoreDisposition = const Value.absent(),
                Value<bool> isInnerTen = const Value.absent(),
                Value<bool> isBoundaryUncertain = const Value.absent(),
                Value<String> placementMethod = const Value.absent(),
                Value<String?> visionAnalysisId = const Value.absent(),
                Value<double?> positionalUncertaintyMm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotImpactsCompanion.insert(
                id: id,
                seriesId: seriesId,
                xMm: xMm,
                yMm: yMm,
                sourceImageId: sourceImageId,
                imageXNormalized: imageXNormalized,
                imageYNormalized: imageYNormalized,
                multiplicity: multiplicity,
                isMiss: isMiss,
                isPositionUncertain: isPositionUncertain,
                targetBullId: targetBullId,
                scoreValue: scoreValue,
                rawScoreValue: rawScoreValue,
                scoreDisposition: scoreDisposition,
                isInnerTen: isInnerTen,
                isBoundaryUncertain: isBoundaryUncertain,
                placementMethod: placementMethod,
                visionAnalysisId: visionAnalysisId,
                positionalUncertaintyMm: positionalUncertaintyMm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShotImpactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                seriesId = false,
                sourceImageId = false,
                visionAnalysisId = false,
              }) {
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
                        if (seriesId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.seriesId,
                                    referencedTable:
                                        $$ShotImpactsTableReferences
                                            ._seriesIdTable(db),
                                    referencedColumn:
                                        $$ShotImpactsTableReferences
                                            ._seriesIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceImageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceImageId,
                                    referencedTable:
                                        $$ShotImpactsTableReferences
                                            ._sourceImageIdTable(db),
                                    referencedColumn:
                                        $$ShotImpactsTableReferences
                                            ._sourceImageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (visionAnalysisId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.visionAnalysisId,
                                    referencedTable:
                                        $$ShotImpactsTableReferences
                                            ._visionAnalysisIdTable(db),
                                    referencedColumn:
                                        $$ShotImpactsTableReferences
                                            ._visionAnalysisIdTable(db)
                                            .id,
                                  )
                                  as T;
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

typedef $$ShotImpactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotImpactsTable,
      ImpactRecord,
      $$ShotImpactsTableFilterComposer,
      $$ShotImpactsTableOrderingComposer,
      $$ShotImpactsTableAnnotationComposer,
      $$ShotImpactsTableCreateCompanionBuilder,
      $$ShotImpactsTableUpdateCompanionBuilder,
      (ImpactRecord, $$ShotImpactsTableReferences),
      ImpactRecord,
      PrefetchHooks Function({
        bool seriesId,
        bool sourceImageId,
        bool visionAnalysisId,
      })
    >;
typedef $$PhotoAlignmentsTableCreateCompanionBuilder =
    PhotoAlignmentsCompanion Function({
      required String imageId,
      required String cornersJson,
      required String matrixJson,
      required String algorithmVersion,
      Value<int> rotationQuarterTurns,
      Value<String> alignmentMode,
      Value<String?> anchorsJson,
      Value<double?> reprojectionRmsMm,
      Value<double?> reprojectionMaxMm,
      Value<String> planarityStatus,
      Value<DateTime?> confirmedAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$PhotoAlignmentsTableUpdateCompanionBuilder =
    PhotoAlignmentsCompanion Function({
      Value<String> imageId,
      Value<String> cornersJson,
      Value<String> matrixJson,
      Value<String> algorithmVersion,
      Value<int> rotationQuarterTurns,
      Value<String> alignmentMode,
      Value<String?> anchorsJson,
      Value<double?> reprojectionRmsMm,
      Value<double?> reprojectionMaxMm,
      Value<String> planarityStatus,
      Value<DateTime?> confirmedAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$PhotoAlignmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PhotoAlignmentsTable,
          PhotoAlignmentRecord
        > {
  $$PhotoAlignmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ImageAssetsTable _imageIdTable(_$AppDatabase db) => db.imageAssets
      .createAlias('photo_alignments__image_id__image_assets__id');

  $$ImageAssetsTableProcessedTableManager get imageId {
    final $_column = $_itemColumn<String>('image_id')!;

    final manager = $$ImageAssetsTableTableManager(
      $_db,
      $_db.imageAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_imageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhotoAlignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoAlignmentsTable> {
  $$PhotoAlignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixJson => $composableBuilder(
    column: $table.matrixJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotationQuarterTurns => $composableBuilder(
    column: $table.rotationQuarterTurns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alignmentMode => $composableBuilder(
    column: $table.alignmentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorsJson => $composableBuilder(
    column: $table.anchorsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reprojectionRmsMm => $composableBuilder(
    column: $table.reprojectionRmsMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reprojectionMaxMm => $composableBuilder(
    column: $table.reprojectionMaxMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planarityStatus => $composableBuilder(
    column: $table.planarityStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAtUtc => $composableBuilder(
    column: $table.confirmedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$ImageAssetsTableFilterComposer get imageId {
    final $$ImageAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableFilterComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotoAlignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoAlignmentsTable> {
  $$PhotoAlignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixJson => $composableBuilder(
    column: $table.matrixJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotationQuarterTurns => $composableBuilder(
    column: $table.rotationQuarterTurns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alignmentMode => $composableBuilder(
    column: $table.alignmentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorsJson => $composableBuilder(
    column: $table.anchorsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reprojectionRmsMm => $composableBuilder(
    column: $table.reprojectionRmsMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reprojectionMaxMm => $composableBuilder(
    column: $table.reprojectionMaxMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planarityStatus => $composableBuilder(
    column: $table.planarityStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAtUtc => $composableBuilder(
    column: $table.confirmedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImageAssetsTableOrderingComposer get imageId {
    final $$ImageAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotoAlignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoAlignmentsTable> {
  $$PhotoAlignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matrixJson => $composableBuilder(
    column: $table.matrixJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rotationQuarterTurns => $composableBuilder(
    column: $table.rotationQuarterTurns,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alignmentMode => $composableBuilder(
    column: $table.alignmentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchorsJson => $composableBuilder(
    column: $table.anchorsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reprojectionRmsMm => $composableBuilder(
    column: $table.reprojectionRmsMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reprojectionMaxMm => $composableBuilder(
    column: $table.reprojectionMaxMm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planarityStatus => $composableBuilder(
    column: $table.planarityStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAtUtc => $composableBuilder(
    column: $table.confirmedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$ImageAssetsTableAnnotationComposer get imageId {
    final $$ImageAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.imageAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotoAlignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotoAlignmentsTable,
          PhotoAlignmentRecord,
          $$PhotoAlignmentsTableFilterComposer,
          $$PhotoAlignmentsTableOrderingComposer,
          $$PhotoAlignmentsTableAnnotationComposer,
          $$PhotoAlignmentsTableCreateCompanionBuilder,
          $$PhotoAlignmentsTableUpdateCompanionBuilder,
          (PhotoAlignmentRecord, $$PhotoAlignmentsTableReferences),
          PhotoAlignmentRecord,
          PrefetchHooks Function({bool imageId})
        > {
  $$PhotoAlignmentsTableTableManager(
    _$AppDatabase db,
    $PhotoAlignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoAlignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoAlignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoAlignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> imageId = const Value.absent(),
                Value<String> cornersJson = const Value.absent(),
                Value<String> matrixJson = const Value.absent(),
                Value<String> algorithmVersion = const Value.absent(),
                Value<int> rotationQuarterTurns = const Value.absent(),
                Value<String> alignmentMode = const Value.absent(),
                Value<String?> anchorsJson = const Value.absent(),
                Value<double?> reprojectionRmsMm = const Value.absent(),
                Value<double?> reprojectionMaxMm = const Value.absent(),
                Value<String> planarityStatus = const Value.absent(),
                Value<DateTime?> confirmedAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoAlignmentsCompanion(
                imageId: imageId,
                cornersJson: cornersJson,
                matrixJson: matrixJson,
                algorithmVersion: algorithmVersion,
                rotationQuarterTurns: rotationQuarterTurns,
                alignmentMode: alignmentMode,
                anchorsJson: anchorsJson,
                reprojectionRmsMm: reprojectionRmsMm,
                reprojectionMaxMm: reprojectionMaxMm,
                planarityStatus: planarityStatus,
                confirmedAtUtc: confirmedAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String imageId,
                required String cornersJson,
                required String matrixJson,
                required String algorithmVersion,
                Value<int> rotationQuarterTurns = const Value.absent(),
                Value<String> alignmentMode = const Value.absent(),
                Value<String?> anchorsJson = const Value.absent(),
                Value<double?> reprojectionRmsMm = const Value.absent(),
                Value<double?> reprojectionMaxMm = const Value.absent(),
                Value<String> planarityStatus = const Value.absent(),
                Value<DateTime?> confirmedAtUtc = const Value.absent(),
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => PhotoAlignmentsCompanion.insert(
                imageId: imageId,
                cornersJson: cornersJson,
                matrixJson: matrixJson,
                algorithmVersion: algorithmVersion,
                rotationQuarterTurns: rotationQuarterTurns,
                alignmentMode: alignmentMode,
                anchorsJson: anchorsJson,
                reprojectionRmsMm: reprojectionRmsMm,
                reprojectionMaxMm: reprojectionMaxMm,
                planarityStatus: planarityStatus,
                confirmedAtUtc: confirmedAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PhotoAlignmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({imageId = false}) {
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
                    if (imageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.imageId,
                                referencedTable:
                                    $$PhotoAlignmentsTableReferences
                                        ._imageIdTable(db),
                                referencedColumn:
                                    $$PhotoAlignmentsTableReferences
                                        ._imageIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$PhotoAlignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotoAlignmentsTable,
      PhotoAlignmentRecord,
      $$PhotoAlignmentsTableFilterComposer,
      $$PhotoAlignmentsTableOrderingComposer,
      $$PhotoAlignmentsTableAnnotationComposer,
      $$PhotoAlignmentsTableCreateCompanionBuilder,
      $$PhotoAlignmentsTableUpdateCompanionBuilder,
      (PhotoAlignmentRecord, $$PhotoAlignmentsTableReferences),
      PhotoAlignmentRecord,
      PrefetchHooks Function({bool imageId})
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String targetProfileVersionedId,
      required double distanceMeters,
      Value<String?> firearmId,
      Value<String?> ammoLotId,
      required String metric,
      required double targetValue,
      required String comparison,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> targetProfileVersionedId,
      Value<double> distanceMeters,
      Value<String?> firearmId,
      Value<String?> ammoLotId,
      Value<String> metric,
      Value<double> targetValue,
      Value<String> comparison,
      Value<bool> active,
      Value<int> rowid,
    });

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, GoalRecord> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FirearmsTable _firearmIdTable(_$AppDatabase db) =>
      db.firearms.createAlias('goals__firearm_id__firearms__id');

  $$FirearmsTableProcessedTableManager? get firearmId {
    final $_column = $_itemColumn<String>('firearm_id');
    if ($_column == null) return null;
    final manager = $$FirearmsTableTableManager(
      $_db,
      $_db.firearms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firearmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AmmoLotsTable _ammoLotIdTable(_$AppDatabase db) =>
      db.ammoLots.createAlias('goals__ammo_lot_id__ammo_lots__id');

  $$AmmoLotsTableProcessedTableManager? get ammoLotId {
    final $_column = $_itemColumn<String>('ammo_lot_id');
    if ($_column == null) return null;
    final manager = $$AmmoLotsTableTableManager(
      $_db,
      $_db.ammoLots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ammoLotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get targetProfileVersionedId => $composableBuilder(
    column: $table.targetProfileVersionedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comparison => $composableBuilder(
    column: $table.comparison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  $$FirearmsTableFilterComposer get firearmId {
    final $$FirearmsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableFilterComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmmoLotsTableFilterComposer get ammoLotId {
    final $$AmmoLotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ammoLotId,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableFilterComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get targetProfileVersionedId => $composableBuilder(
    column: $table.targetProfileVersionedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comparison => $composableBuilder(
    column: $table.comparison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  $$FirearmsTableOrderingComposer get firearmId {
    final $$FirearmsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableOrderingComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmmoLotsTableOrderingComposer get ammoLotId {
    final $$AmmoLotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ammoLotId,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableOrderingComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetProfileVersionedId => $composableBuilder(
    column: $table.targetProfileVersionedId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comparison => $composableBuilder(
    column: $table.comparison,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  $$FirearmsTableAnnotationComposer get firearmId {
    final $$FirearmsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableAnnotationComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmmoLotsTableAnnotationComposer get ammoLotId {
    final $$AmmoLotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ammoLotId,
      referencedTable: $db.ammoLots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmmoLotsTableAnnotationComposer(
            $db: $db,
            $table: $db.ammoLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRecord,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRecord, $$GoalsTableReferences),
          GoalRecord,
          PrefetchHooks Function({bool firearmId, bool ammoLotId})
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetProfileVersionedId = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<String?> firearmId = const Value.absent(),
                Value<String?> ammoLotId = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<double> targetValue = const Value.absent(),
                Value<String> comparison = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                targetProfileVersionedId: targetProfileVersionedId,
                distanceMeters: distanceMeters,
                firearmId: firearmId,
                ammoLotId: ammoLotId,
                metric: metric,
                targetValue: targetValue,
                comparison: comparison,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetProfileVersionedId,
                required double distanceMeters,
                Value<String?> firearmId = const Value.absent(),
                Value<String?> ammoLotId = const Value.absent(),
                required String metric,
                required double targetValue,
                required String comparison,
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                targetProfileVersionedId: targetProfileVersionedId,
                distanceMeters: distanceMeters,
                firearmId: firearmId,
                ammoLotId: ammoLotId,
                metric: metric,
                targetValue: targetValue,
                comparison: comparison,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GoalsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({firearmId = false, ammoLotId = false}) {
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
                    if (firearmId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.firearmId,
                                referencedTable: $$GoalsTableReferences
                                    ._firearmIdTable(db),
                                referencedColumn: $$GoalsTableReferences
                                    ._firearmIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (ammoLotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ammoLotId,
                                referencedTable: $$GoalsTableReferences
                                    ._ammoLotIdTable(db),
                                referencedColumn: $$GoalsTableReferences
                                    ._ammoLotIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRecord,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRecord, $$GoalsTableReferences),
      GoalRecord,
      PrefetchHooks Function({bool firearmId, bool ammoLotId})
    >;
typedef $$SeriesReflectionsTableCreateCompanionBuilder =
    SeriesReflectionsCompanion Function({
      required String seriesId,
      required String perceivedQuality,
      Value<String> contextTagsJson,
      Value<String?> note,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$SeriesReflectionsTableUpdateCompanionBuilder =
    SeriesReflectionsCompanion Function({
      Value<String> seriesId,
      Value<String> perceivedQuality,
      Value<String> contextTagsJson,
      Value<String?> note,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$SeriesReflectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SeriesReflectionsTable,
          SeriesReflectionRecord
        > {
  $$SeriesReflectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShootingSeriesTable _seriesIdTable(_$AppDatabase db) => db
      .shootingSeries
      .createAlias('series_reflections__series_id__shooting_series__id');

  $$ShootingSeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeriesReflectionsTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesReflectionsTable> {
  $$SeriesReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get perceivedQuality => $composableBuilder(
    column: $table.perceivedQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextTagsJson => $composableBuilder(
    column: $table.contextTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$ShootingSeriesTableFilterComposer get seriesId {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesReflectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesReflectionsTable> {
  $$SeriesReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get perceivedQuality => $composableBuilder(
    column: $table.perceivedQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextTagsJson => $composableBuilder(
    column: $table.contextTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShootingSeriesTableOrderingComposer get seriesId {
    final $$ShootingSeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableOrderingComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesReflectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesReflectionsTable> {
  $$SeriesReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get perceivedQuality => $composableBuilder(
    column: $table.perceivedQuality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextTagsJson => $composableBuilder(
    column: $table.contextTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$ShootingSeriesTableAnnotationComposer get seriesId {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesReflectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesReflectionsTable,
          SeriesReflectionRecord,
          $$SeriesReflectionsTableFilterComposer,
          $$SeriesReflectionsTableOrderingComposer,
          $$SeriesReflectionsTableAnnotationComposer,
          $$SeriesReflectionsTableCreateCompanionBuilder,
          $$SeriesReflectionsTableUpdateCompanionBuilder,
          (SeriesReflectionRecord, $$SeriesReflectionsTableReferences),
          SeriesReflectionRecord,
          PrefetchHooks Function({bool seriesId})
        > {
  $$SeriesReflectionsTableTableManager(
    _$AppDatabase db,
    $SeriesReflectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesReflectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> seriesId = const Value.absent(),
                Value<String> perceivedQuality = const Value.absent(),
                Value<String> contextTagsJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesReflectionsCompanion(
                seriesId: seriesId,
                perceivedQuality: perceivedQuality,
                contextTagsJson: contextTagsJson,
                note: note,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String seriesId,
                required String perceivedQuality,
                Value<String> contextTagsJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => SeriesReflectionsCompanion.insert(
                seriesId: seriesId,
                perceivedQuality: perceivedQuality,
                contextTagsJson: contextTagsJson,
                note: note,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeriesReflectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
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
                    if (seriesId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seriesId,
                                referencedTable:
                                    $$SeriesReflectionsTableReferences
                                        ._seriesIdTable(db),
                                referencedColumn:
                                    $$SeriesReflectionsTableReferences
                                        ._seriesIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$SeriesReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesReflectionsTable,
      SeriesReflectionRecord,
      $$SeriesReflectionsTableFilterComposer,
      $$SeriesReflectionsTableOrderingComposer,
      $$SeriesReflectionsTableAnnotationComposer,
      $$SeriesReflectionsTableCreateCompanionBuilder,
      $$SeriesReflectionsTableUpdateCompanionBuilder,
      (SeriesReflectionRecord, $$SeriesReflectionsTableReferences),
      SeriesReflectionRecord,
      PrefetchHooks Function({bool seriesId})
    >;
typedef $$CoachFeedbackTableCreateCompanionBuilder =
    CoachFeedbackCompanion Function({
      required String insightFingerprint,
      required String ruleId,
      required int ruleVersion,
      required String response,
      Value<DateTime?> snoozedUntilUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$CoachFeedbackTableUpdateCompanionBuilder =
    CoachFeedbackCompanion Function({
      Value<String> insightFingerprint,
      Value<String> ruleId,
      Value<int> ruleVersion,
      Value<String> response,
      Value<DateTime?> snoozedUntilUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$CoachFeedbackTableFilterComposer
    extends Composer<_$AppDatabase, $CoachFeedbackTable> {
  $$CoachFeedbackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get insightFingerprint => $composableBuilder(
    column: $table.insightFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntilUtc => $composableBuilder(
    column: $table.snoozedUntilUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoachFeedbackTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachFeedbackTable> {
  $$CoachFeedbackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get insightFingerprint => $composableBuilder(
    column: $table.insightFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntilUtc => $composableBuilder(
    column: $table.snoozedUntilUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoachFeedbackTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachFeedbackTable> {
  $$CoachFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get insightFingerprint => $composableBuilder(
    column: $table.insightFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntilUtc => $composableBuilder(
    column: $table.snoozedUntilUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$CoachFeedbackTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachFeedbackTable,
          CoachFeedbackRecord,
          $$CoachFeedbackTableFilterComposer,
          $$CoachFeedbackTableOrderingComposer,
          $$CoachFeedbackTableAnnotationComposer,
          $$CoachFeedbackTableCreateCompanionBuilder,
          $$CoachFeedbackTableUpdateCompanionBuilder,
          (
            CoachFeedbackRecord,
            BaseReferences<
              _$AppDatabase,
              $CoachFeedbackTable,
              CoachFeedbackRecord
            >,
          ),
          CoachFeedbackRecord,
          PrefetchHooks Function()
        > {
  $$CoachFeedbackTableTableManager(_$AppDatabase db, $CoachFeedbackTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachFeedbackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachFeedbackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> insightFingerprint = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<int> ruleVersion = const Value.absent(),
                Value<String> response = const Value.absent(),
                Value<DateTime?> snoozedUntilUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoachFeedbackCompanion(
                insightFingerprint: insightFingerprint,
                ruleId: ruleId,
                ruleVersion: ruleVersion,
                response: response,
                snoozedUntilUtc: snoozedUntilUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String insightFingerprint,
                required String ruleId,
                required int ruleVersion,
                required String response,
                Value<DateTime?> snoozedUntilUtc = const Value.absent(),
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => CoachFeedbackCompanion.insert(
                insightFingerprint: insightFingerprint,
                ruleId: ruleId,
                ruleVersion: ruleVersion,
                response: response,
                snoozedUntilUtc: snoozedUntilUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoachFeedbackTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachFeedbackTable,
      CoachFeedbackRecord,
      $$CoachFeedbackTableFilterComposer,
      $$CoachFeedbackTableOrderingComposer,
      $$CoachFeedbackTableAnnotationComposer,
      $$CoachFeedbackTableCreateCompanionBuilder,
      $$CoachFeedbackTableUpdateCompanionBuilder,
      (
        CoachFeedbackRecord,
        BaseReferences<_$AppDatabase, $CoachFeedbackTable, CoachFeedbackRecord>,
      ),
      CoachFeedbackRecord,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
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

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
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

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
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

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          PreferenceRecord,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            PreferenceRecord,
            BaseReferences<_$AppDatabase, $PreferencesTable, PreferenceRecord>,
          ),
          PreferenceRecord,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
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

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      PreferenceRecord,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        PreferenceRecord,
        BaseReferences<_$AppDatabase, $PreferencesTable, PreferenceRecord>,
      ),
      PreferenceRecord,
      PrefetchHooks Function()
    >;
typedef $$TargetProfilesTableCreateCompanionBuilder =
    TargetProfilesCompanion Function({
      required String versionedId,
      required String profileId,
      required int profileVersion,
      required String displayName,
      required String validationStatus,
      required String profileJson,
      Value<bool> builtIn,
      Value<bool> archived,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$TargetProfilesTableUpdateCompanionBuilder =
    TargetProfilesCompanion Function({
      Value<String> versionedId,
      Value<String> profileId,
      Value<int> profileVersion,
      Value<String> displayName,
      Value<String> validationStatus,
      Value<String> profileJson,
      Value<bool> builtIn,
      Value<bool> archived,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

class $$TargetProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $TargetProfilesTable> {
  $$TargetProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get versionedId => $composableBuilder(
    column: $table.versionedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validationStatus => $composableBuilder(
    column: $table.validationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TargetProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TargetProfilesTable> {
  $$TargetProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get versionedId => $composableBuilder(
    column: $table.versionedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validationStatus => $composableBuilder(
    column: $table.validationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TargetProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TargetProfilesTable> {
  $$TargetProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get versionedId => $composableBuilder(
    column: $table.versionedId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validationStatus => $composableBuilder(
    column: $table.validationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$TargetProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TargetProfilesTable,
          TargetProfileRecord,
          $$TargetProfilesTableFilterComposer,
          $$TargetProfilesTableOrderingComposer,
          $$TargetProfilesTableAnnotationComposer,
          $$TargetProfilesTableCreateCompanionBuilder,
          $$TargetProfilesTableUpdateCompanionBuilder,
          (
            TargetProfileRecord,
            BaseReferences<
              _$AppDatabase,
              $TargetProfilesTable,
              TargetProfileRecord
            >,
          ),
          TargetProfileRecord,
          PrefetchHooks Function()
        > {
  $$TargetProfilesTableTableManager(
    _$AppDatabase db,
    $TargetProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TargetProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TargetProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TargetProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> versionedId = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<int> profileVersion = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> validationStatus = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TargetProfilesCompanion(
                versionedId: versionedId,
                profileId: profileId,
                profileVersion: profileVersion,
                displayName: displayName,
                validationStatus: validationStatus,
                profileJson: profileJson,
                builtIn: builtIn,
                archived: archived,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String versionedId,
                required String profileId,
                required int profileVersion,
                required String displayName,
                required String validationStatus,
                required String profileJson,
                Value<bool> builtIn = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TargetProfilesCompanion.insert(
                versionedId: versionedId,
                profileId: profileId,
                profileVersion: profileVersion,
                displayName: displayName,
                validationStatus: validationStatus,
                profileJson: profileJson,
                builtIn: builtIn,
                archived: archived,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TargetProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TargetProfilesTable,
      TargetProfileRecord,
      $$TargetProfilesTableFilterComposer,
      $$TargetProfilesTableOrderingComposer,
      $$TargetProfilesTableAnnotationComposer,
      $$TargetProfilesTableCreateCompanionBuilder,
      $$TargetProfilesTableUpdateCompanionBuilder,
      (
        TargetProfileRecord,
        BaseReferences<
          _$AppDatabase,
          $TargetProfilesTable,
          TargetProfileRecord
        >,
      ),
      TargetProfileRecord,
      PrefetchHooks Function()
    >;
typedef $$TrainingActivitiesTableCreateCompanionBuilder =
    TrainingActivitiesCompanion Function({
      required String id,
      required String kind,
      Value<int> schemaVersion,
      required String status,
      Value<String?> sessionId,
      required String configurationJson,
      required String summaryJson,
      Value<String?> detectorVersion,
      required DateTime startedAtUtc,
      required int localUtcOffsetMinutes,
      Value<DateTime?> completedAtUtc,
      Value<String?> notes,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TrainingActivitiesTableUpdateCompanionBuilder =
    TrainingActivitiesCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<int> schemaVersion,
      Value<String> status,
      Value<String?> sessionId,
      Value<String> configurationJson,
      Value<String> summaryJson,
      Value<String?> detectorVersion,
      Value<DateTime> startedAtUtc,
      Value<int> localUtcOffsetMinutes,
      Value<DateTime?> completedAtUtc,
      Value<String?> notes,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$TrainingActivitiesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TrainingActivitiesTable,
          TrainingActivityRecord
        > {
  $$TrainingActivitiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrainingSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .trainingSessions
      .createAlias('training_activities__session_id__training_sessions__id');

  $$TrainingSessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<String>('session_id');
    if ($_column == null) return null;
    final manager = $$TrainingSessionsTableTableManager(
      $_db,
      $_db.trainingSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TrainingActivitySeriesLinksTable,
    List<TrainingActivitySeriesLinkRecord>
  >
  _trainingActivitySeriesLinksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trainingActivitySeriesLinks,
    aliasName:
        'training_activities__id__training_activity_series_links__activity_id',
  );

  $$TrainingActivitySeriesLinksTableProcessedTableManager
  get trainingActivitySeriesLinksRefs {
    final manager = $$TrainingActivitySeriesLinksTableTableManager(
      $_db,
      $_db.trainingActivitySeriesLinks,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trainingActivitySeriesLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShotTimerEventsTable, List<ShotTimerEventRecord>>
  _shotTimerEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotTimerEvents,
    aliasName: 'training_activities__id__shot_timer_events__activity_id',
  );

  $$ShotTimerEventsTableProcessedTableManager get shotTimerEventsRefs {
    final manager = $$ShotTimerEventsTableTableManager(
      $_db,
      $_db.shotTimerEvents,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _shotTimerEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TrainingActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingActivitiesTable> {
  $$TrainingActivitiesTableFilterComposer({
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

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectorVersion => $composableBuilder(
    column: $table.detectorVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localUtcOffsetMinutes => $composableBuilder(
    column: $table.localUtcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TrainingSessionsTableFilterComposer get sessionId {
    final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> trainingActivitySeriesLinksRefs(
    Expression<bool> Function(
      $$TrainingActivitySeriesLinksTableFilterComposer f,
    )
    f,
  ) {
    final $$TrainingActivitySeriesLinksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trainingActivitySeriesLinks,
          getReferencedColumn: (t) => t.activityId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitySeriesLinksTableFilterComposer(
                $db: $db,
                $table: $db.trainingActivitySeriesLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> shotTimerEventsRefs(
    Expression<bool> Function($$ShotTimerEventsTableFilterComposer f) f,
  ) {
    final $$ShotTimerEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotTimerEvents,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotTimerEventsTableFilterComposer(
            $db: $db,
            $table: $db.shotTimerEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrainingActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingActivitiesTable> {
  $$TrainingActivitiesTableOrderingComposer({
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

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectorVersion => $composableBuilder(
    column: $table.detectorVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localUtcOffsetMinutes => $composableBuilder(
    column: $table.localUtcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrainingSessionsTableOrderingComposer get sessionId {
    final $$TrainingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrainingActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingActivitiesTable> {
  $$TrainingActivitiesTableAnnotationComposer({
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

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detectorVersion => $composableBuilder(
    column: $table.detectorVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localUtcOffsetMinutes => $composableBuilder(
    column: $table.localUtcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TrainingSessionsTableAnnotationComposer get sessionId {
    final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.trainingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> trainingActivitySeriesLinksRefs<T extends Object>(
    Expression<T> Function(
      $$TrainingActivitySeriesLinksTableAnnotationComposer a,
    )
    f,
  ) {
    final $$TrainingActivitySeriesLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trainingActivitySeriesLinks,
          getReferencedColumn: (t) => t.activityId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitySeriesLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.trainingActivitySeriesLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> shotTimerEventsRefs<T extends Object>(
    Expression<T> Function($$ShotTimerEventsTableAnnotationComposer a) f,
  ) {
    final $$ShotTimerEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotTimerEvents,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotTimerEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.shotTimerEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrainingActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainingActivitiesTable,
          TrainingActivityRecord,
          $$TrainingActivitiesTableFilterComposer,
          $$TrainingActivitiesTableOrderingComposer,
          $$TrainingActivitiesTableAnnotationComposer,
          $$TrainingActivitiesTableCreateCompanionBuilder,
          $$TrainingActivitiesTableUpdateCompanionBuilder,
          (TrainingActivityRecord, $$TrainingActivitiesTableReferences),
          TrainingActivityRecord,
          PrefetchHooks Function({
            bool sessionId,
            bool trainingActivitySeriesLinksRefs,
            bool shotTimerEventsRefs,
          })
        > {
  $$TrainingActivitiesTableTableManager(
    _$AppDatabase db,
    $TrainingActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingActivitiesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> configurationJson = const Value.absent(),
                Value<String> summaryJson = const Value.absent(),
                Value<String?> detectorVersion = const Value.absent(),
                Value<DateTime> startedAtUtc = const Value.absent(),
                Value<int> localUtcOffsetMinutes = const Value.absent(),
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingActivitiesCompanion(
                id: id,
                kind: kind,
                schemaVersion: schemaVersion,
                status: status,
                sessionId: sessionId,
                configurationJson: configurationJson,
                summaryJson: summaryJson,
                detectorVersion: detectorVersion,
                startedAtUtc: startedAtUtc,
                localUtcOffsetMinutes: localUtcOffsetMinutes,
                completedAtUtc: completedAtUtc,
                notes: notes,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<int> schemaVersion = const Value.absent(),
                required String status,
                Value<String?> sessionId = const Value.absent(),
                required String configurationJson,
                required String summaryJson,
                Value<String?> detectorVersion = const Value.absent(),
                required DateTime startedAtUtc,
                required int localUtcOffsetMinutes,
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TrainingActivitiesCompanion.insert(
                id: id,
                kind: kind,
                schemaVersion: schemaVersion,
                status: status,
                sessionId: sessionId,
                configurationJson: configurationJson,
                summaryJson: summaryJson,
                detectorVersion: detectorVersion,
                startedAtUtc: startedAtUtc,
                localUtcOffsetMinutes: localUtcOffsetMinutes,
                completedAtUtc: completedAtUtc,
                notes: notes,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrainingActivitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionId = false,
                trainingActivitySeriesLinksRefs = false,
                shotTimerEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trainingActivitySeriesLinksRefs)
                      db.trainingActivitySeriesLinks,
                    if (shotTimerEventsRefs) db.shotTimerEvents,
                  ],
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
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$TrainingActivitiesTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$TrainingActivitiesTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trainingActivitySeriesLinksRefs)
                        await $_getPrefetchedData<
                          TrainingActivityRecord,
                          $TrainingActivitiesTable,
                          TrainingActivitySeriesLinkRecord
                        >(
                          currentTable: table,
                          referencedTable: $$TrainingActivitiesTableReferences
                              ._trainingActivitySeriesLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrainingActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).trainingActivitySeriesLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.activityId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shotTimerEventsRefs)
                        await $_getPrefetchedData<
                          TrainingActivityRecord,
                          $TrainingActivitiesTable,
                          ShotTimerEventRecord
                        >(
                          currentTable: table,
                          referencedTable: $$TrainingActivitiesTableReferences
                              ._shotTimerEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrainingActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).shotTimerEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.activityId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TrainingActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainingActivitiesTable,
      TrainingActivityRecord,
      $$TrainingActivitiesTableFilterComposer,
      $$TrainingActivitiesTableOrderingComposer,
      $$TrainingActivitiesTableAnnotationComposer,
      $$TrainingActivitiesTableCreateCompanionBuilder,
      $$TrainingActivitiesTableUpdateCompanionBuilder,
      (TrainingActivityRecord, $$TrainingActivitiesTableReferences),
      TrainingActivityRecord,
      PrefetchHooks Function({
        bool sessionId,
        bool trainingActivitySeriesLinksRefs,
        bool shotTimerEventsRefs,
      })
    >;
typedef $$TrainingActivitySeriesLinksTableCreateCompanionBuilder =
    TrainingActivitySeriesLinksCompanion Function({
      required String activityId,
      required String seriesId,
      required int sequenceNumber,
      Value<String?> role,
      Value<String?> variantId,
      Value<int> rowid,
    });
typedef $$TrainingActivitySeriesLinksTableUpdateCompanionBuilder =
    TrainingActivitySeriesLinksCompanion Function({
      Value<String> activityId,
      Value<String> seriesId,
      Value<int> sequenceNumber,
      Value<String?> role,
      Value<String?> variantId,
      Value<int> rowid,
    });

final class $$TrainingActivitySeriesLinksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TrainingActivitySeriesLinksTable,
          TrainingActivitySeriesLinkRecord
        > {
  $$TrainingActivitySeriesLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrainingActivitiesTable _activityIdTable(_$AppDatabase db) =>
      db.trainingActivities.createAlias(
        'training_activity_series_links__activity_id__training_activities__id',
      );

  $$TrainingActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<String>('activity_id')!;

    final manager = $$TrainingActivitiesTableTableManager(
      $_db,
      $_db.trainingActivities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ShootingSeriesTable _seriesIdTable(_$AppDatabase db) =>
      db.shootingSeries.createAlias(
        'training_activity_series_links__series_id__shooting_series__id',
      );

  $$ShootingSeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ShootingSeriesTableTableManager(
      $_db,
      $_db.shootingSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrainingActivitySeriesLinksTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingActivitySeriesLinksTable> {
  $$TrainingActivitySeriesLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  $$TrainingActivitiesTableFilterComposer get activityId {
    final $$TrainingActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.trainingActivities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.trainingActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShootingSeriesTableFilterComposer get seriesId {
    final $$ShootingSeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableFilterComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrainingActivitySeriesLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingActivitySeriesLinksTable> {
  $$TrainingActivitySeriesLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrainingActivitiesTableOrderingComposer get activityId {
    final $$TrainingActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.trainingActivities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.trainingActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShootingSeriesTableOrderingComposer get seriesId {
    final $$ShootingSeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableOrderingComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrainingActivitySeriesLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingActivitySeriesLinksTable> {
  $$TrainingActivitySeriesLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  $$TrainingActivitiesTableAnnotationComposer get activityId {
    final $$TrainingActivitiesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.activityId,
          referencedTable: $db.trainingActivities,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitiesTableAnnotationComposer(
                $db: $db,
                $table: $db.trainingActivities,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ShootingSeriesTableAnnotationComposer get seriesId {
    final $$ShootingSeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.shootingSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShootingSeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.shootingSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrainingActivitySeriesLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainingActivitySeriesLinksTable,
          TrainingActivitySeriesLinkRecord,
          $$TrainingActivitySeriesLinksTableFilterComposer,
          $$TrainingActivitySeriesLinksTableOrderingComposer,
          $$TrainingActivitySeriesLinksTableAnnotationComposer,
          $$TrainingActivitySeriesLinksTableCreateCompanionBuilder,
          $$TrainingActivitySeriesLinksTableUpdateCompanionBuilder,
          (
            TrainingActivitySeriesLinkRecord,
            $$TrainingActivitySeriesLinksTableReferences,
          ),
          TrainingActivitySeriesLinkRecord,
          PrefetchHooks Function({bool activityId, bool seriesId})
        > {
  $$TrainingActivitySeriesLinksTableTableManager(
    _$AppDatabase db,
    $TrainingActivitySeriesLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingActivitySeriesLinksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TrainingActivitySeriesLinksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrainingActivitySeriesLinksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> activityId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingActivitySeriesLinksCompanion(
                activityId: activityId,
                seriesId: seriesId,
                sequenceNumber: sequenceNumber,
                role: role,
                variantId: variantId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String activityId,
                required String seriesId,
                required int sequenceNumber,
                Value<String?> role = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingActivitySeriesLinksCompanion.insert(
                activityId: activityId,
                seriesId: seriesId,
                sequenceNumber: sequenceNumber,
                role: role,
                variantId: variantId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrainingActivitySeriesLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false, seriesId = false}) {
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
                    if (activityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.activityId,
                                referencedTable:
                                    $$TrainingActivitySeriesLinksTableReferences
                                        ._activityIdTable(db),
                                referencedColumn:
                                    $$TrainingActivitySeriesLinksTableReferences
                                        ._activityIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (seriesId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seriesId,
                                referencedTable:
                                    $$TrainingActivitySeriesLinksTableReferences
                                        ._seriesIdTable(db),
                                referencedColumn:
                                    $$TrainingActivitySeriesLinksTableReferences
                                        ._seriesIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TrainingActivitySeriesLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainingActivitySeriesLinksTable,
      TrainingActivitySeriesLinkRecord,
      $$TrainingActivitySeriesLinksTableFilterComposer,
      $$TrainingActivitySeriesLinksTableOrderingComposer,
      $$TrainingActivitySeriesLinksTableAnnotationComposer,
      $$TrainingActivitySeriesLinksTableCreateCompanionBuilder,
      $$TrainingActivitySeriesLinksTableUpdateCompanionBuilder,
      (
        TrainingActivitySeriesLinkRecord,
        $$TrainingActivitySeriesLinksTableReferences,
      ),
      TrainingActivitySeriesLinkRecord,
      PrefetchHooks Function({bool activityId, bool seriesId})
    >;
typedef $$ShotTimerEventsTableCreateCompanionBuilder =
    ShotTimerEventsCompanion Function({
      required String id,
      required String activityId,
      required int sequenceNumber,
      required int elapsedMicroseconds,
      required int splitMicroseconds,
      required String source,
      required String disposition,
      Value<double?> normalizedPeak,
      Value<String?> detectionQuality,
      Value<String?> exclusionReason,
      Value<int> rowid,
    });
typedef $$ShotTimerEventsTableUpdateCompanionBuilder =
    ShotTimerEventsCompanion Function({
      Value<String> id,
      Value<String> activityId,
      Value<int> sequenceNumber,
      Value<int> elapsedMicroseconds,
      Value<int> splitMicroseconds,
      Value<String> source,
      Value<String> disposition,
      Value<double?> normalizedPeak,
      Value<String?> detectionQuality,
      Value<String?> exclusionReason,
      Value<int> rowid,
    });

final class $$ShotTimerEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ShotTimerEventsTable,
          ShotTimerEventRecord
        > {
  $$ShotTimerEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrainingActivitiesTable _activityIdTable(_$AppDatabase db) => db
      .trainingActivities
      .createAlias('shot_timer_events__activity_id__training_activities__id');

  $$TrainingActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<String>('activity_id')!;

    final manager = $$TrainingActivitiesTableTableManager(
      $_db,
      $_db.trainingActivities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShotTimerEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ShotTimerEventsTable> {
  $$ShotTimerEventsTableFilterComposer({
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

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMicroseconds => $composableBuilder(
    column: $table.elapsedMicroseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get splitMicroseconds => $composableBuilder(
    column: $table.splitMicroseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disposition => $composableBuilder(
    column: $table.disposition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get normalizedPeak => $composableBuilder(
    column: $table.normalizedPeak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectionQuality => $composableBuilder(
    column: $table.detectionQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exclusionReason => $composableBuilder(
    column: $table.exclusionReason,
    builder: (column) => ColumnFilters(column),
  );

  $$TrainingActivitiesTableFilterComposer get activityId {
    final $$TrainingActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.trainingActivities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.trainingActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotTimerEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShotTimerEventsTable> {
  $$ShotTimerEventsTableOrderingComposer({
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

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMicroseconds => $composableBuilder(
    column: $table.elapsedMicroseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get splitMicroseconds => $composableBuilder(
    column: $table.splitMicroseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disposition => $composableBuilder(
    column: $table.disposition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get normalizedPeak => $composableBuilder(
    column: $table.normalizedPeak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectionQuality => $composableBuilder(
    column: $table.detectionQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exclusionReason => $composableBuilder(
    column: $table.exclusionReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrainingActivitiesTableOrderingComposer get activityId {
    final $$TrainingActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.trainingActivities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.trainingActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotTimerEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShotTimerEventsTable> {
  $$ShotTimerEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMicroseconds => $composableBuilder(
    column: $table.elapsedMicroseconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get splitMicroseconds => $composableBuilder(
    column: $table.splitMicroseconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get disposition => $composableBuilder(
    column: $table.disposition,
    builder: (column) => column,
  );

  GeneratedColumn<double> get normalizedPeak => $composableBuilder(
    column: $table.normalizedPeak,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detectionQuality => $composableBuilder(
    column: $table.detectionQuality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exclusionReason => $composableBuilder(
    column: $table.exclusionReason,
    builder: (column) => column,
  );

  $$TrainingActivitiesTableAnnotationComposer get activityId {
    final $$TrainingActivitiesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.activityId,
          referencedTable: $db.trainingActivities,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrainingActivitiesTableAnnotationComposer(
                $db: $db,
                $table: $db.trainingActivities,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ShotTimerEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotTimerEventsTable,
          ShotTimerEventRecord,
          $$ShotTimerEventsTableFilterComposer,
          $$ShotTimerEventsTableOrderingComposer,
          $$ShotTimerEventsTableAnnotationComposer,
          $$ShotTimerEventsTableCreateCompanionBuilder,
          $$ShotTimerEventsTableUpdateCompanionBuilder,
          (ShotTimerEventRecord, $$ShotTimerEventsTableReferences),
          ShotTimerEventRecord,
          PrefetchHooks Function({bool activityId})
        > {
  $$ShotTimerEventsTableTableManager(
    _$AppDatabase db,
    $ShotTimerEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShotTimerEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShotTimerEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShotTimerEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<int> elapsedMicroseconds = const Value.absent(),
                Value<int> splitMicroseconds = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> disposition = const Value.absent(),
                Value<double?> normalizedPeak = const Value.absent(),
                Value<String?> detectionQuality = const Value.absent(),
                Value<String?> exclusionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotTimerEventsCompanion(
                id: id,
                activityId: activityId,
                sequenceNumber: sequenceNumber,
                elapsedMicroseconds: elapsedMicroseconds,
                splitMicroseconds: splitMicroseconds,
                source: source,
                disposition: disposition,
                normalizedPeak: normalizedPeak,
                detectionQuality: detectionQuality,
                exclusionReason: exclusionReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String activityId,
                required int sequenceNumber,
                required int elapsedMicroseconds,
                required int splitMicroseconds,
                required String source,
                required String disposition,
                Value<double?> normalizedPeak = const Value.absent(),
                Value<String?> detectionQuality = const Value.absent(),
                Value<String?> exclusionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotTimerEventsCompanion.insert(
                id: id,
                activityId: activityId,
                sequenceNumber: sequenceNumber,
                elapsedMicroseconds: elapsedMicroseconds,
                splitMicroseconds: splitMicroseconds,
                source: source,
                disposition: disposition,
                normalizedPeak: normalizedPeak,
                detectionQuality: detectionQuality,
                exclusionReason: exclusionReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShotTimerEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
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
                    if (activityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.activityId,
                                referencedTable:
                                    $$ShotTimerEventsTableReferences
                                        ._activityIdTable(db),
                                referencedColumn:
                                    $$ShotTimerEventsTableReferences
                                        ._activityIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ShotTimerEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotTimerEventsTable,
      ShotTimerEventRecord,
      $$ShotTimerEventsTableFilterComposer,
      $$ShotTimerEventsTableOrderingComposer,
      $$ShotTimerEventsTableAnnotationComposer,
      $$ShotTimerEventsTableCreateCompanionBuilder,
      $$ShotTimerEventsTableUpdateCompanionBuilder,
      (ShotTimerEventRecord, $$ShotTimerEventsTableReferences),
      ShotTimerEventRecord,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$TimerPresetsTableCreateCompanionBuilder =
    TimerPresetsCompanion Function({
      required String id,
      required String name,
      required String mode,
      required String configurationJson,
      Value<bool> builtIn,
      Value<bool> archived,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TimerPresetsTableUpdateCompanionBuilder =
    TimerPresetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> mode,
      Value<String> configurationJson,
      Value<bool> builtIn,
      Value<bool> archived,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$TimerPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $TimerPresetsTable> {
  $$TimerPresetsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimerPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerPresetsTable> {
  $$TimerPresetsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimerPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerPresetsTable> {
  $$TimerPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get configurationJson => $composableBuilder(
    column: $table.configurationJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$TimerPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimerPresetsTable,
          TimerPresetRecord,
          $$TimerPresetsTableFilterComposer,
          $$TimerPresetsTableOrderingComposer,
          $$TimerPresetsTableAnnotationComposer,
          $$TimerPresetsTableCreateCompanionBuilder,
          $$TimerPresetsTableUpdateCompanionBuilder,
          (
            TimerPresetRecord,
            BaseReferences<
              _$AppDatabase,
              $TimerPresetsTable,
              TimerPresetRecord
            >,
          ),
          TimerPresetRecord,
          PrefetchHooks Function()
        > {
  $$TimerPresetsTableTableManager(_$AppDatabase db, $TimerPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> configurationJson = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimerPresetsCompanion(
                id: id,
                name: name,
                mode: mode,
                configurationJson: configurationJson,
                builtIn: builtIn,
                archived: archived,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String mode,
                required String configurationJson,
                Value<bool> builtIn = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TimerPresetsCompanion.insert(
                id: id,
                name: name,
                mode: mode,
                configurationJson: configurationJson,
                builtIn: builtIn,
                archived: archived,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimerPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimerPresetsTable,
      TimerPresetRecord,
      $$TimerPresetsTableFilterComposer,
      $$TimerPresetsTableOrderingComposer,
      $$TimerPresetsTableAnnotationComposer,
      $$TimerPresetsTableCreateCompanionBuilder,
      $$TimerPresetsTableUpdateCompanionBuilder,
      (
        TimerPresetRecord,
        BaseReferences<_$AppDatabase, $TimerPresetsTable, TimerPresetRecord>,
      ),
      TimerPresetRecord,
      PrefetchHooks Function()
    >;
typedef $$AcousticCalibrationProfilesTableCreateCompanionBuilder =
    AcousticCalibrationProfilesCompanion Function({
      required String id,
      required String name,
      Value<String?> firearmId,
      Value<String?> cartridgeId,
      required String environment,
      required String audioRoute,
      required int sampleRate,
      required double sensitivity,
      required int echoLockoutMicroseconds,
      required int beepBlankingMicroseconds,
      required String detectorVersion,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$AcousticCalibrationProfilesTableUpdateCompanionBuilder =
    AcousticCalibrationProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> firearmId,
      Value<String?> cartridgeId,
      Value<String> environment,
      Value<String> audioRoute,
      Value<int> sampleRate,
      Value<double> sensitivity,
      Value<int> echoLockoutMicroseconds,
      Value<int> beepBlankingMicroseconds,
      Value<String> detectorVersion,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$AcousticCalibrationProfilesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AcousticCalibrationProfilesTable,
          AcousticCalibrationProfileRecord
        > {
  $$AcousticCalibrationProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FirearmsTable _firearmIdTable(_$AppDatabase db) => db.firearms
      .createAlias('acoustic_calibration_profiles__firearm_id__firearms__id');

  $$FirearmsTableProcessedTableManager? get firearmId {
    final $_column = $_itemColumn<String>('firearm_id');
    if ($_column == null) return null;
    final manager = $$FirearmsTableTableManager(
      $_db,
      $_db.firearms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firearmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CartridgesTable _cartridgeIdTable(_$AppDatabase db) =>
      db.cartridges.createAlias(
        'acoustic_calibration_profiles__cartridge_id__cartridges__id',
      );

  $$CartridgesTableProcessedTableManager? get cartridgeId {
    final $_column = $_itemColumn<String>('cartridge_id');
    if ($_column == null) return null;
    final manager = $$CartridgesTableTableManager(
      $_db,
      $_db.cartridges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cartridgeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AcousticCalibrationProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $AcousticCalibrationProfilesTable> {
  $$AcousticCalibrationProfilesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioRoute => $composableBuilder(
    column: $table.audioRoute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sensitivity => $composableBuilder(
    column: $table.sensitivity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get echoLockoutMicroseconds => $composableBuilder(
    column: $table.echoLockoutMicroseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get beepBlankingMicroseconds => $composableBuilder(
    column: $table.beepBlankingMicroseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectorVersion => $composableBuilder(
    column: $table.detectorVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$FirearmsTableFilterComposer get firearmId {
    final $$FirearmsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableFilterComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CartridgesTableFilterComposer get cartridgeId {
    final $$CartridgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableFilterComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AcousticCalibrationProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $AcousticCalibrationProfilesTable> {
  $$AcousticCalibrationProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioRoute => $composableBuilder(
    column: $table.audioRoute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sensitivity => $composableBuilder(
    column: $table.sensitivity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get echoLockoutMicroseconds => $composableBuilder(
    column: $table.echoLockoutMicroseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get beepBlankingMicroseconds => $composableBuilder(
    column: $table.beepBlankingMicroseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectorVersion => $composableBuilder(
    column: $table.detectorVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$FirearmsTableOrderingComposer get firearmId {
    final $$FirearmsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableOrderingComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CartridgesTableOrderingComposer get cartridgeId {
    final $$CartridgesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableOrderingComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AcousticCalibrationProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcousticCalibrationProfilesTable> {
  $$AcousticCalibrationProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioRoute => $composableBuilder(
    column: $table.audioRoute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sensitivity => $composableBuilder(
    column: $table.sensitivity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get echoLockoutMicroseconds => $composableBuilder(
    column: $table.echoLockoutMicroseconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get beepBlankingMicroseconds => $composableBuilder(
    column: $table.beepBlankingMicroseconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detectorVersion => $composableBuilder(
    column: $table.detectorVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$FirearmsTableAnnotationComposer get firearmId {
    final $$FirearmsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firearmId,
      referencedTable: $db.firearms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FirearmsTableAnnotationComposer(
            $db: $db,
            $table: $db.firearms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CartridgesTableAnnotationComposer get cartridgeId {
    final $$CartridgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cartridgeId,
      referencedTable: $db.cartridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartridgesTableAnnotationComposer(
            $db: $db,
            $table: $db.cartridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AcousticCalibrationProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AcousticCalibrationProfilesTable,
          AcousticCalibrationProfileRecord,
          $$AcousticCalibrationProfilesTableFilterComposer,
          $$AcousticCalibrationProfilesTableOrderingComposer,
          $$AcousticCalibrationProfilesTableAnnotationComposer,
          $$AcousticCalibrationProfilesTableCreateCompanionBuilder,
          $$AcousticCalibrationProfilesTableUpdateCompanionBuilder,
          (
            AcousticCalibrationProfileRecord,
            $$AcousticCalibrationProfilesTableReferences,
          ),
          AcousticCalibrationProfileRecord,
          PrefetchHooks Function({bool firearmId, bool cartridgeId})
        > {
  $$AcousticCalibrationProfilesTableTableManager(
    _$AppDatabase db,
    $AcousticCalibrationProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcousticCalibrationProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AcousticCalibrationProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AcousticCalibrationProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> firearmId = const Value.absent(),
                Value<String?> cartridgeId = const Value.absent(),
                Value<String> environment = const Value.absent(),
                Value<String> audioRoute = const Value.absent(),
                Value<int> sampleRate = const Value.absent(),
                Value<double> sensitivity = const Value.absent(),
                Value<int> echoLockoutMicroseconds = const Value.absent(),
                Value<int> beepBlankingMicroseconds = const Value.absent(),
                Value<String> detectorVersion = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AcousticCalibrationProfilesCompanion(
                id: id,
                name: name,
                firearmId: firearmId,
                cartridgeId: cartridgeId,
                environment: environment,
                audioRoute: audioRoute,
                sampleRate: sampleRate,
                sensitivity: sensitivity,
                echoLockoutMicroseconds: echoLockoutMicroseconds,
                beepBlankingMicroseconds: beepBlankingMicroseconds,
                detectorVersion: detectorVersion,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> firearmId = const Value.absent(),
                Value<String?> cartridgeId = const Value.absent(),
                required String environment,
                required String audioRoute,
                required int sampleRate,
                required double sensitivity,
                required int echoLockoutMicroseconds,
                required int beepBlankingMicroseconds,
                required String detectorVersion,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => AcousticCalibrationProfilesCompanion.insert(
                id: id,
                name: name,
                firearmId: firearmId,
                cartridgeId: cartridgeId,
                environment: environment,
                audioRoute: audioRoute,
                sampleRate: sampleRate,
                sensitivity: sensitivity,
                echoLockoutMicroseconds: echoLockoutMicroseconds,
                beepBlankingMicroseconds: beepBlankingMicroseconds,
                detectorVersion: detectorVersion,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AcousticCalibrationProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({firearmId = false, cartridgeId = false}) {
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
                    if (firearmId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.firearmId,
                                referencedTable:
                                    $$AcousticCalibrationProfilesTableReferences
                                        ._firearmIdTable(db),
                                referencedColumn:
                                    $$AcousticCalibrationProfilesTableReferences
                                        ._firearmIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (cartridgeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cartridgeId,
                                referencedTable:
                                    $$AcousticCalibrationProfilesTableReferences
                                        ._cartridgeIdTable(db),
                                referencedColumn:
                                    $$AcousticCalibrationProfilesTableReferences
                                        ._cartridgeIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$AcousticCalibrationProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AcousticCalibrationProfilesTable,
      AcousticCalibrationProfileRecord,
      $$AcousticCalibrationProfilesTableFilterComposer,
      $$AcousticCalibrationProfilesTableOrderingComposer,
      $$AcousticCalibrationProfilesTableAnnotationComposer,
      $$AcousticCalibrationProfilesTableCreateCompanionBuilder,
      $$AcousticCalibrationProfilesTableUpdateCompanionBuilder,
      (
        AcousticCalibrationProfileRecord,
        $$AcousticCalibrationProfilesTableReferences,
      ),
      AcousticCalibrationProfileRecord,
      PrefetchHooks Function({bool firearmId, bool cartridgeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FirearmsTableTableManager get firearms =>
      $$FirearmsTableTableManager(_db, _db.firearms);
  $$CartridgesTableTableManager get cartridges =>
      $$CartridgesTableTableManager(_db, _db.cartridges);
  $$AmmoLotsTableTableManager get ammoLots =>
      $$AmmoLotsTableTableManager(_db, _db.ammoLots);
  $$RangesTableTableManager get ranges =>
      $$RangesTableTableManager(_db, _db.ranges);
  $$TrainingSessionsTableTableManager get trainingSessions =>
      $$TrainingSessionsTableTableManager(_db, _db.trainingSessions);
  $$ShootingSeriesTableTableManager get shootingSeries =>
      $$ShootingSeriesTableTableManager(_db, _db.shootingSeries);
  $$ImageAssetsTableTableManager get imageAssets =>
      $$ImageAssetsTableTableManager(_db, _db.imageAssets);
  $$VisionScanDraftsTableTableManager get visionScanDrafts =>
      $$VisionScanDraftsTableTableManager(_db, _db.visionScanDrafts);
  $$VisionAnalysesTableTableManager get visionAnalyses =>
      $$VisionAnalysesTableTableManager(_db, _db.visionAnalyses);
  $$ShotImpactsTableTableManager get shotImpacts =>
      $$ShotImpactsTableTableManager(_db, _db.shotImpacts);
  $$PhotoAlignmentsTableTableManager get photoAlignments =>
      $$PhotoAlignmentsTableTableManager(_db, _db.photoAlignments);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$SeriesReflectionsTableTableManager get seriesReflections =>
      $$SeriesReflectionsTableTableManager(_db, _db.seriesReflections);
  $$CoachFeedbackTableTableManager get coachFeedback =>
      $$CoachFeedbackTableTableManager(_db, _db.coachFeedback);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$TargetProfilesTableTableManager get targetProfiles =>
      $$TargetProfilesTableTableManager(_db, _db.targetProfiles);
  $$TrainingActivitiesTableTableManager get trainingActivities =>
      $$TrainingActivitiesTableTableManager(_db, _db.trainingActivities);
  $$TrainingActivitySeriesLinksTableTableManager
  get trainingActivitySeriesLinks =>
      $$TrainingActivitySeriesLinksTableTableManager(
        _db,
        _db.trainingActivitySeriesLinks,
      );
  $$ShotTimerEventsTableTableManager get shotTimerEvents =>
      $$ShotTimerEventsTableTableManager(_db, _db.shotTimerEvents);
  $$TimerPresetsTableTableManager get timerPresets =>
      $$TimerPresetsTableTableManager(_db, _db.timerPresets);
  $$AcousticCalibrationProfilesTableTableManager
  get acousticCalibrationProfiles =>
      $$AcousticCalibrationProfilesTableTableManager(
        _db,
        _db.acousticCalibrationProfiles,
      );
}
