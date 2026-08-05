import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('FirearmRecord')
class Firearms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get type => text()();
  TextColumn get defaultCartridgeId => text().nullable()();
  TextColumn get sightNotes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CartridgeRecord')
class Cartridges extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get projectileDiameterMm => real()();
  TextColumn get notes => text().nullable()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AmmoLotRecord')
class AmmoLots extends Table {
  TextColumn get id => text()();
  TextColumn get cartridgeId => text().references(Cartridges, #id)();
  TextColumn get displayName => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get productName => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  RealColumn get bulletWeightGrains => real().nullable()();
  TextColumn get projectileType => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RangeRecord')
class Ranges extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get locationDescription => text().nullable()();
  BoolColumn get isIndoor => boolean().withDefault(const Constant(true))();
  TextColumn get availableDistancesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SessionRecord')
class TrainingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  DateTimeColumn get startedAtUtc => dateTime()();
  IntColumn get localUtcOffsetMinutes => integer()();
  DateTimeColumn get endedAtUtc => dateTime().nullable()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get photoSafetyAcknowledgedAtUtc => dateTime().nullable()();
  TextColumn get rangeId => text().nullable().references(Ranges, #id)();
  TextColumn get trainingGoal => text().nullable()();
  TextColumn get conditions => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SeriesRecord')
class ShootingSeries extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(TrainingSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequenceNumber => integer()();
  TextColumn get status => text()();
  TextColumn get targetProfileVersionedId => text()();
  TextColumn get targetProfileJson => text()();
  RealColumn get distanceMeters => real()();
  RealColumn get projectileDiameterMm => real()();
  TextColumn get cartridgeId => text().nullable().references(Cartridges, #id)();
  IntColumn get shotCount => integer().withDefault(const Constant(0))();
  IntColumn get maximumPossibleScore =>
      integer().withDefault(const Constant(0))();
  TextColumn get firearmId => text().nullable().references(Firearms, #id)();
  TextColumn get ammoLotId => text().nullable().references(AmmoLots, #id)();
  TextColumn get notes => text().nullable()();
  IntColumn get totalScore => integer().withDefault(const Constant(0))();
  IntColumn get innerTenCount => integer().withDefault(const Constant(0))();
  IntColumn get missCount => integer().withDefault(const Constant(0))();
  IntColumn get scorePenalty => integer().withDefault(const Constant(0))();
  IntColumn get scoredBullCount => integer().nullable()();
  BoolColumn get hasBoundaryWarnings =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get confirmedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ImageAssetRecord')
class ImageAssets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(TrainingSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get seriesId => text().nullable().references(
    ShootingSeries,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get role => text()();
  TextColumn get path => text()();
  TextColumn get sha256 => text()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get sizeBytes => integer()();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ImpactRecord')
class ShotImpacts extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId =>
      text().references(ShootingSeries, #id, onDelete: KeyAction.cascade)();
  RealColumn get xMm => real()();
  RealColumn get yMm => real()();
  TextColumn get sourceImageId => text().nullable().references(
    ImageAssets,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get imageXNormalized => real().nullable()();
  RealColumn get imageYNormalized => real().nullable()();
  IntColumn get multiplicity => integer().withDefault(const Constant(1))();
  BoolColumn get isMiss => boolean().withDefault(const Constant(false))();
  BoolColumn get isPositionUncertain =>
      boolean().withDefault(const Constant(false))();
  TextColumn get targetBullId => text().nullable()();
  IntColumn get scoreValue => integer()();
  IntColumn get rawScoreValue => integer().withDefault(const Constant(0))();
  TextColumn get scoreDisposition =>
      text().withDefault(const Constant('counted'))();
  BoolColumn get isInnerTen => boolean().withDefault(const Constant(false))();
  BoolColumn get isBoundaryUncertain =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PhotoAlignmentRecord')
class PhotoAlignments extends Table {
  TextColumn get imageId =>
      text().references(ImageAssets, #id, onDelete: KeyAction.cascade)();
  TextColumn get cornersJson => text()();
  TextColumn get matrixJson => text()();
  TextColumn get algorithmVersion => text()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {imageId};
}

@DataClassName('GoalRecord')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get targetProfileVersionedId => text()();
  RealColumn get distanceMeters => real()();
  TextColumn get firearmId => text().nullable().references(Firearms, #id)();
  TextColumn get ammoLotId => text().nullable().references(AmmoLots, #id)();
  TextColumn get metric => text()();
  RealColumn get targetValue => real()();
  TextColumn get comparison => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SeriesReflectionRecord')
class SeriesReflections extends Table {
  TextColumn get seriesId =>
      text().references(ShootingSeries, #id, onDelete: KeyAction.cascade)();
  TextColumn get perceivedQuality => text()();
  TextColumn get contextTagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {seriesId};
}

@DataClassName('CoachFeedbackRecord')
class CoachFeedback extends Table {
  TextColumn get insightFingerprint => text()();
  TextColumn get ruleId => text()();
  IntColumn get ruleVersion => integer()();
  TextColumn get response => text()();
  DateTimeColumn get snoozedUntilUtc => dateTime().nullable()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {insightFingerprint};
}

@DataClassName('PreferenceRecord')
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('TargetProfileRecord')
class TargetProfiles extends Table {
  TextColumn get versionedId => text()();
  TextColumn get profileId => text()();
  IntColumn get profileVersion => integer()();
  TextColumn get displayName => text()();
  TextColumn get validationStatus => text()();
  TextColumn get profileJson => text()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {versionedId};
}

@DriftDatabase(
  tables: [
    Firearms,
    Cartridges,
    AmmoLots,
    Ranges,
    TrainingSessions,
    ShootingSeries,
    ImageAssets,
    ShotImpacts,
    PhotoAlignments,
    Goals,
    SeriesReflections,
    CoachFeedback,
    Preferences,
    TargetProfiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'shooting_companion'));

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createInvariantIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      if (from == 1 && to >= 2) {
        await _migrateFromV1(migrator);
      }
      if (from <= 2 && to >= 3) {
        await _migrateToV3(migrator);
      }
      // The v1 rebuild creates the current series and impact tables directly,
      // so their v4 columns already exist after _migrateFromV1.
      if (from >= 2 && from <= 3 && to >= 4) {
        await _migrateToV4(migrator);
      }
      if (from <= 4 && to >= 5) {
        await _migrateToV5(migrator);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _createInvariantIndexes();
      if (details.wasCreated || details.hadUpgrade) {
        final violations = await customSelect('PRAGMA foreign_key_check').get();
        if (violations.isNotEmpty) {
          throw StateError('Database bevat ongeldige foreign keys.');
        }
      }
    },
  );

  Future<void> _createInvariantIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS one_active_session
      ON training_sessions(status)
      WHERE status = 'active'
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS one_draft_series_per_session
      ON shooting_series(session_id)
      WHERE status = 'draft'
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS one_primary_image_per_series
      ON image_assets(series_id)
      WHERE role = 'primaryScoringPhoto'
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS series_by_session_status
      ON shooting_series(session_id, status, sequence_number)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS images_by_session_created
      ON image_assets(session_id, created_at_utc DESC)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS images_by_series
      ON image_assets(series_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS active_firearms_by_name
      ON firearms(archived, name)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS active_cartridges_by_name
      ON cartridges(archived, name)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS active_ammo_by_name
      ON ammo_lots(archived, display_name)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS active_ranges_by_name
      ON ranges(archived, name)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS active_targets_by_name
      ON target_profiles(archived, display_name)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS target_profile_versions
      ON target_profiles(profile_id, profile_version)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS active_goals_by_cohort
      ON goals(active, target_profile_versioned_id, distance_meters)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS reflections_by_updated
      ON series_reflections(updated_at_utc DESC)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS coach_feedback_by_rule
      ON coach_feedback(rule_id, rule_version)
    ''');
  }

  Future<void> _migrateToV3(Migrator migrator) async {
    await migrator.addColumn(cartridges, cartridges.builtIn);
    await migrator.addColumn(cartridges, cartridges.archived);
    await migrator.addColumn(ammoLots, ammoLots.archived);
    await migrator.addColumn(ranges, ranges.archived);
    await migrator.addColumn(targetProfiles, targetProfiles.archived);
    await customStatement('UPDATE cartridges SET built_in = 1');
  }

  Future<void> _migrateToV4(Migrator migrator) async {
    await migrator.addColumn(shootingSeries, shootingSeries.scorePenalty);
    await migrator.addColumn(shootingSeries, shootingSeries.scoredBullCount);
    await migrator.addColumn(shotImpacts, shotImpacts.targetBullId);
    await migrator.addColumn(shotImpacts, shotImpacts.rawScoreValue);
    await migrator.addColumn(shotImpacts, shotImpacts.scoreDisposition);
    await customStatement(
      'UPDATE shot_impacts SET raw_score_value = score_value',
    );
  }

  Future<void> _migrateToV5(Migrator migrator) async {
    await customStatement('ALTER TABLE goals RENAME TO goals_v4');
    await migrator.createTable(goals);
    await customStatement('''
      INSERT INTO goals (
        id,
        target_profile_versioned_id,
        distance_meters,
        firearm_id,
        ammo_lot_id,
        metric,
        target_value,
        comparison,
        active
      )
      SELECT
        id,
        target_profile_versioned_id,
        distance_meters,
        firearm_id,
        ammo_lot_id,
        'scorePercentage',
        target_percentage,
        'atLeast',
        active
      FROM goals_v4
    ''');
    await customStatement('DROP TABLE goals_v4');
    await migrator.createTable(seriesReflections);
    await migrator.createTable(coachFeedback);
  }

  Future<void> _migrateFromV1(Migrator migrator) async {
    await customStatement('PRAGMA defer_foreign_keys = ON');

    await customStatement(
      'ALTER TABLE training_sessions RENAME TO training_sessions_v1',
    );
    await customStatement(
      'ALTER TABLE shooting_series RENAME TO shooting_series_v1',
    );
    await customStatement('ALTER TABLE shot_impacts RENAME TO shot_impacts_v1');
    await customStatement('ALTER TABLE image_assets RENAME TO image_assets_v1');
    await customStatement('ALTER TABLE scans RENAME TO scans_v1');
    await customStatement('ALTER TABLE scan_edits RENAME TO scan_edits_v1');

    await migrator.createTable(trainingSessions);
    await migrator.createTable(shootingSeries);
    await migrator.createTable(imageAssets);
    await migrator.createTable(shotImpacts);
    await migrator.createTable(photoAlignments);

    final oldSessions = await customSelect('''
      SELECT * FROM training_sessions_v1
      ORDER BY started_at_utc DESC, id DESC
    ''').get();
    var keptActiveSession = false;
    for (final row in oldSessions) {
      final data = row.data;
      var status = data['status']! as String;
      var endedAt = _readDateTime(data['ended_at_utc']);
      if (status == 'active') {
        if (keptActiveSession) {
          status = 'completed';
          endedAt ??= _readRequiredDateTime(data['started_at_utc']);
        } else {
          keptActiveSession = true;
        }
      }
      final startedAt = _readRequiredDateTime(data['started_at_utc']);
      await into(trainingSessions).insert(
        TrainingSessionsCompanion.insert(
          id: data['id']! as String,
          status: status,
          startedAtUtc: startedAt,
          localUtcOffsetMinutes: data['local_utc_offset_minutes']! as int,
          endedAtUtc: Value(endedAt),
          updatedAtUtc: endedAt ?? startedAt,
          rangeId: Value(data['range_id'] as String?),
          trainingGoal: Value(data['training_goal'] as String?),
          conditions: Value(data['conditions'] as String?),
          notes: Value(data['notes'] as String?),
        ),
      );
    }

    final impactCounts = <String, int>{};
    final countRows = await customSelect('''
      SELECT series_id, SUM(multiplicity) AS shot_count
      FROM shot_impacts_v1
      GROUP BY series_id
    ''').get();
    for (final row in countRows) {
      impactCounts[row.data['series_id']! as String] =
          row.data['shot_count']! as int;
    }

    final oldSeries = await customSelect('''
      SELECT * FROM shooting_series_v1
      ORDER BY session_id, created_at_utc DESC, id DESC
    ''').get();
    final keptDraftForSession = <String>{};
    final sessionIdBySeriesId = <String, String>{};
    final ammoCartridges = <String, String>{};
    for (final row in await customSelect(
      'SELECT id, cartridge_id FROM ammo_lots',
    ).get()) {
      ammoCartridges[row.data['id']! as String] =
          row.data['cartridge_id']! as String;
    }
    final cartridgeIdsByDiameter = <double, List<String>>{};
    for (final row in await customSelect(
      'SELECT id, projectile_diameter_mm FROM cartridges',
    ).get()) {
      final diameter = (row.data['projectile_diameter_mm']! as num).toDouble();
      cartridgeIdsByDiameter
          .putIfAbsent(diameter, () => <String>[])
          .add(row.data['id']! as String);
    }
    for (final row in oldSeries) {
      final data = row.data;
      final id = data['id']! as String;
      final sessionId = data['session_id']! as String;
      sessionIdBySeriesId[id] = sessionId;
      var status = data['status']! as String;
      var confirmedAt = _readDateTime(data['confirmed_at_utc']);
      final createdAt = _readRequiredDateTime(data['created_at_utc']);
      if (status == 'draft' && !keptDraftForSession.add(sessionId)) {
        status = 'confirmed';
        confirmedAt ??= createdAt;
      }
      final shotCount = impactCounts[id] ?? data['expected_shots']! as int;
      final profileJson = data['target_profile_json']! as String;
      final targetMaximum = _maximumScoreFromTargetJson(profileJson);
      final ammoLotId = data['ammo_lot_id'] as String?;
      final projectileDiameter = (data['projectile_diameter_mm']! as num)
          .toDouble();
      final matchingCartridges = cartridgeIdsByDiameter[projectileDiameter];
      final cartridgeId = ammoLotId == null
          ? (matchingCartridges?.length == 1
                ? matchingCartridges!.single
                : null)
          : ammoCartridges[ammoLotId];
      await into(shootingSeries).insert(
        ShootingSeriesCompanion.insert(
          id: id,
          sessionId: sessionId,
          sequenceNumber: data['sequence_number']! as int,
          status: status,
          targetProfileVersionedId:
              data['target_profile_versioned_id']! as String,
          targetProfileJson: profileJson,
          distanceMeters: (data['distance_meters']! as num).toDouble(),
          projectileDiameterMm: projectileDiameter,
          cartridgeId: Value(cartridgeId),
          shotCount: Value(shotCount),
          maximumPossibleScore: Value(shotCount * targetMaximum),
          firearmId: Value(data['firearm_id'] as String?),
          ammoLotId: Value(ammoLotId),
          totalScore: Value(data['total_score']! as int),
          innerTenCount: Value(data['inner_ten_count']! as int),
          missCount: Value(data['miss_count']! as int),
          hasBoundaryWarnings: Value(
            (data['has_boundary_warnings']! as int) != 0,
          ),
          createdAtUtc: createdAt,
          updatedAtUtc: confirmedAt ?? createdAt,
          confirmedAtUtc: Value(confirmedAt),
        ),
      );
    }

    final oldImages = await customSelect('''
      SELECT * FROM image_assets_v1
      ORDER BY created_at_utc DESC, id DESC
    ''').get();
    final primarySeries = <String>{};
    for (final row in oldImages) {
      final data = row.data;
      final seriesId = data['series_id']! as String;
      final oldKind = data['kind']! as String;
      final isPrimary = oldKind == 'after' && primarySeries.add(seriesId);
      final createdAt = _readRequiredDateTime(data['created_at_utc']);
      await into(imageAssets).insert(
        ImageAssetsCompanion.insert(
          id: data['id']! as String,
          sessionId: sessionIdBySeriesId[seriesId]!,
          seriesId: Value(seriesId),
          role: isPrimary ? 'primaryScoringPhoto' : 'attachment',
          path: data['path']! as String,
          sha256: data['sha256']! as String,
          width: data['width']! as int,
          height: data['height']! as int,
          sizeBytes: data['size_bytes']! as int,
          createdAtUtc: createdAt,
          updatedAtUtc: createdAt,
        ),
      );
    }

    final oldImpacts = await customSelect(
      'SELECT * FROM shot_impacts_v1',
    ).get();
    for (final row in oldImpacts) {
      final data = row.data;
      await into(shotImpacts).insert(
        ShotImpactsCompanion.insert(
          id: data['id']! as String,
          seriesId: data['series_id']! as String,
          xMm: (data['x_mm']! as num).toDouble(),
          yMm: (data['y_mm']! as num).toDouble(),
          multiplicity: Value(data['multiplicity']! as int),
          isMiss: Value((data['is_miss']! as int) != 0),
          isPositionUncertain: Value(
            (data['is_position_uncertain']! as int) != 0,
          ),
          scoreValue: data['score_value']! as int,
          rawScoreValue: Value(data['score_value']! as int),
          isInnerTen: Value((data['is_inner_ten']! as int) != 0),
          isBoundaryUncertain: Value(
            (data['is_boundary_uncertain']! as int) != 0,
          ),
        ),
      );
    }

    await customStatement('DROP TABLE scan_edits_v1');
    await customStatement('DROP TABLE scans_v1');
    await customStatement('DROP TABLE shot_impacts_v1');
    await customStatement('DROP TABLE image_assets_v1');
    await customStatement('DROP TABLE shooting_series_v1');
    await customStatement('DROP TABLE training_sessions_v1');
  }

  static DateTime _readRequiredDateTime(Object? value) => _readDateTime(value)!;

  static DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    return DateTime.parse(value as String).toUtc();
  }

  static int _maximumScoreFromTargetJson(String source) {
    final json = (jsonDecode(source) as Map).cast<String, Object?>();
    final rings = json['rings']! as List<Object?>;
    return rings
        .map((ring) => ((ring! as Map)['value']! as num).toInt())
        .reduce((left, right) => left > right ? left : right);
  }

  Stream<List<SessionRecord>> watchSessions() => (select(
    trainingSessions,
  )..orderBy([(row) => OrderingTerm.desc(row.startedAtUtc)])).watch();

  Stream<SessionRecord?> watchActiveSession() =>
      (select(trainingSessions)
            ..where((row) => row.status.equals('active'))
            ..limit(1))
          .watchSingleOrNull();

  Stream<List<SeriesRecord>> watchSeries(String sessionId) =>
      (select(shootingSeries)
            ..where((row) => row.sessionId.equals(sessionId))
            ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
          .watch();

  Stream<List<SeriesRecord>> watchConfirmedSeries() =>
      (select(shootingSeries)
            ..where((row) => row.status.equals('confirmed'))
            ..orderBy([(row) => OrderingTerm.asc(row.createdAtUtc)]))
          .watch();

  Stream<List<ImpactRecord>> watchImpacts(String seriesId) => (select(
    shotImpacts,
  )..where((row) => row.seriesId.equals(seriesId))).watch();

  Stream<List<ImageAssetRecord>> watchSessionImages(String sessionId) =>
      (select(imageAssets)
            ..where((row) => row.sessionId.equals(sessionId))
            ..orderBy([(row) => OrderingTerm.desc(row.createdAtUtc)]))
          .watch();

  Stream<List<ImageAssetRecord>> watchSeriesImages(String seriesId) =>
      (select(imageAssets)
            ..where((row) => row.seriesId.equals(seriesId))
            ..orderBy([(row) => OrderingTerm.desc(row.createdAtUtc)]))
          .watch();

  Stream<ImageAssetRecord?> watchImage(String imageId) => (select(
    imageAssets,
  )..where((row) => row.id.equals(imageId))).watchSingleOrNull();

  Stream<List<FirearmRecord>> watchFirearms() =>
      (select(firearms)
            ..where((row) => row.archived.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.name)]))
          .watch();

  Stream<List<FirearmRecord>> watchAllFirearms() => (select(
    firearms,
  )..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  Stream<List<CartridgeRecord>> watchCartridges() =>
      (select(cartridges)
            ..where((row) => row.archived.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.name)]))
          .watch();

  Stream<List<CartridgeRecord>> watchAllCartridges() => (select(
    cartridges,
  )..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  Stream<List<AmmoLotRecord>> watchAmmoLots() =>
      (select(ammoLots)
            ..where((row) => row.archived.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.displayName)]))
          .watch();

  Stream<List<AmmoLotRecord>> watchAllAmmoLots() => (select(
    ammoLots,
  )..orderBy([(row) => OrderingTerm.asc(row.displayName)])).watch();

  Stream<List<RangeRecord>> watchRanges() =>
      (select(ranges)
            ..where((row) => row.archived.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.name)]))
          .watch();

  Stream<List<RangeRecord>> watchAllRanges() =>
      (select(ranges)..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  Stream<List<TargetProfileRecord>> watchTargetProfiles() =>
      (select(targetProfiles)
            ..where((row) => row.archived.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.displayName)]))
          .watch();

  Stream<List<TargetProfileRecord>> watchAllTargetProfiles() => (select(
    targetProfiles,
  )..orderBy([(row) => OrderingTerm.asc(row.displayName)])).watch();
}
