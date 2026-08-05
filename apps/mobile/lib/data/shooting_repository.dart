import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'timer_preset_defaults.dart';

class ActiveSessionExistsException implements Exception {
  const ActiveSessionExistsException(this.sessionId);

  final String sessionId;

  @override
  String toString() => 'Er is al een actieve sessie: $sessionId';
}

enum LibraryItemKind { cartridge, firearm, ammoLot, range, targetProfile }

class LibraryUsageSummary {
  const LibraryUsageSummary({
    this.sessionCount = 0,
    this.seriesCount = 0,
    this.goalCount = 0,
    this.dependentAmmoLotCount = 0,
  });

  final int sessionCount;
  final int seriesCount;
  final int goalCount;
  final int dependentAmmoLotCount;

  bool get isInUse =>
      sessionCount > 0 ||
      seriesCount > 0 ||
      goalCount > 0 ||
      dependentAmmoLotCount > 0;
}

enum LibraryRemovalResult {
  deleted,
  archived,
  blockedBuiltIn,
  blockedDependency,
}

enum GoalMetric {
  scorePercentage,
  meanRadiusMm,
  extremeSpreadMm,
  absoluteHorizontalBiasMm,
  absoluteVerticalBiasMm,
  trainingCount,
  completedBr50Bulls,
  consistency,
}

enum GoalComparison { atLeast, atMost }

enum PerceivedQuality { good, neutral, difficult }

enum ReflectionContextTag {
  sightPicture,
  trigger,
  gripOrPosition,
  breathing,
  followThrough,
  tempo,
  lightOrWind,
  equipment,
  perceivedFatigue,
}

enum StoredCoachFeedbackResponse { useful, notUseful, later, dismiss }

enum StoredTrainingActivityKind {
  acousticLiveFire,
  par,
  cadence,
  externalManual,
  drill,
  experiment,
  sightVerification,
  coldSeries,
}

enum StoredTrainingActivityStatus { draft, completed, interrupted }

enum StoredTimerEventSource { acoustic, manual, generatedPar, external }

enum StoredTimerEventDisposition { counted, excluded }

const _timerActivityKinds = {
  'acousticLiveFire',
  'par',
  'cadence',
  'externalManual',
};

class NewShotTimerEvent {
  const NewShotTimerEvent({
    this.id,
    required this.elapsedMicroseconds,
    required this.splitMicroseconds,
    required this.source,
    this.disposition = StoredTimerEventDisposition.counted,
    this.normalizedPeak,
    this.detectionQuality,
    this.exclusionReason,
  });

  final String? id;
  final int elapsedMicroseconds;
  final int splitMicroseconds;
  final StoredTimerEventSource source;
  final StoredTimerEventDisposition disposition;
  final double? normalizedPeak;
  final String? detectionQuality;
  final String? exclusionReason;
}

class TrainingActivityDetail {
  const TrainingActivityDetail({
    required this.activity,
    required this.links,
    required this.events,
  });

  final TrainingActivityRecord activity;
  final List<TrainingActivitySeriesLinkRecord> links;
  final List<ShotTimerEventRecord> events;
}

class TrainingActivityFilters {
  const TrainingActivityFilters({this.kind, this.sessionId, this.status});

  final StoredTrainingActivityKind? kind;
  final String? sessionId;
  final StoredTrainingActivityStatus? status;
}

class AnalysisSeriesData {
  const AnalysisSeriesData({
    required this.session,
    required this.series,
    required this.impacts,
    required this.firearm,
    required this.ammoLot,
    required this.cartridge,
    required this.reflection,
  });

  final SessionRecord session;
  final SeriesRecord series;
  final List<ImpactRecord> impacts;
  final FirearmRecord? firearm;
  final AmmoLotRecord? ammoLot;
  final CartridgeRecord? cartridge;
  final SeriesReflectionRecord? reflection;
}

class QuickSessionResult {
  const QuickSessionResult({
    required this.sessionId,
    required this.draftSeriesId,
  });

  final String sessionId;
  final String draftSeriesId;
}

class SeriesDefaults {
  const SeriesDefaults({
    required this.target,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    this.cartridgeId,
    this.firearmId,
    this.ammoLotId,
  });

  factory SeriesDefaults.standard() => SeriesDefaults(
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
  );

  factory SeriesDefaults.fromRecord(SeriesRecord record) => SeriesDefaults(
    target: domain.TargetProfile.fromJsonString(record.targetProfileJson),
    distanceMeters: record.distanceMeters,
    projectileDiameterMm: record.projectileDiameterMm,
    cartridgeId: record.cartridgeId,
    firearmId: record.firearmId,
    ammoLotId: record.ammoLotId,
  );

  final domain.TargetProfile target;
  final double distanceMeters;
  final double projectileDiameterMm;
  final String? cartridgeId;
  final String? firearmId;
  final String? ammoLotId;
}

class NewImageAsset {
  const NewImageAsset({
    this.id,
    required this.sessionId,
    this.seriesId,
    required this.role,
    required this.path,
    required this.sha256,
    required this.width,
    required this.height,
    required this.sizeBytes,
    this.caption,
  });

  final String? id;
  final String sessionId;
  final String? seriesId;
  final domain.ImageRole role;
  final String path;
  final String sha256;
  final int width;
  final int height;
  final int sizeBytes;
  final String? caption;
}

class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.confirmedSeries,
    required this.draftSeries,
    required this.confirmedSeriesItems,
    required this.draftSeriesItem,
    required this.images,
  });

  final SessionRecord session;
  final List<SeriesRecord> confirmedSeries;
  final SeriesRecord? draftSeries;
  final List<SeriesOverviewItem> confirmedSeriesItems;
  final SeriesOverviewItem? draftSeriesItem;
  final List<ImageAssetRecord> images;

  int get seriesCount => confirmedSeries.length;
  int get shotCount =>
      confirmedSeries.fold(0, (sum, series) => sum + series.shotCount);
  int get totalScore =>
      confirmedSeries.fold(0, (sum, series) => sum + series.totalScore);
  int get maximumPossibleScore => confirmedSeries.fold(
    0,
    (sum, series) => sum + series.maximumPossibleScore,
  );
  int get innerTenCount =>
      confirmedSeries.fold(0, (sum, series) => sum + series.innerTenCount);
  int get photoCount => images.length;
}

class SeriesOverviewItem {
  const SeriesOverviewItem({
    required this.series,
    required this.firearm,
    required this.ammoLot,
    required this.cartridge,
  });

  final SeriesRecord series;
  final FirearmRecord? firearm;
  final AmmoLotRecord? ammoLot;
  final CartridgeRecord? cartridge;
}

class SessionListItem {
  const SessionListItem({
    required this.session,
    required this.confirmedSeriesCount,
    required this.shotCount,
    required this.totalScore,
    required this.maximumPossibleScore,
    required this.innerTenCount,
    required this.photoCount,
    required this.sessionPhotoCount,
    required this.draftSeriesId,
    required this.draftShotCount,
    required this.draftPhotoCount,
    required this.draftHasNotes,
    required this.draftWasEdited,
    required this.thumbnailPath,
  });

  final SessionRecord session;
  final int confirmedSeriesCount;
  final int shotCount;
  final int totalScore;
  final int maximumPossibleScore;
  final int innerTenCount;
  final int photoCount;
  final int sessionPhotoCount;
  final String? draftSeriesId;
  final int draftShotCount;
  final int draftPhotoCount;
  final bool draftHasNotes;
  final bool draftWasEdited;
  final String? thumbnailPath;

  bool get hasDraft => draftSeriesId != null;
  bool get hasMeaningfulDraft =>
      draftShotCount > 0 ||
      draftPhotoCount > 0 ||
      draftHasNotes ||
      draftWasEdited;
}

extension SessionRecordContent on SessionRecord {
  bool get hasUserDetails =>
      rangeId != null ||
      (trainingGoal?.trim().isNotEmpty ?? false) ||
      (conditions?.trim().isNotEmpty ?? false) ||
      (notes?.trim().isNotEmpty ?? false);
}

enum SessionListStatusFilter { all, active, completed }

class SessionListFilters {
  const SessionListFilters({
    this.status = SessionListStatusFilter.all,
    this.startedAtOrAfterUtc,
  });

  final SessionListStatusFilter status;
  final DateTime? startedAtOrAfterUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionListFilters &&
          status == other.status &&
          startedAtOrAfterUtc == other.startedAtOrAfterUtc;

  @override
  int get hashCode => Object.hash(status, startedAtOrAfterUtc);
}

enum DraftCompletionStrategy { requireResolved, discard, confirm }

enum SessionCompletionOutcome {
  completed,
  deletedEmpty,
  alreadyCompleted,
  notFound,
}

class SessionCompletionResult {
  const SessionCompletionResult(this.outcome, {this.confirmedDraftId});

  final SessionCompletionOutcome outcome;
  final String? confirmedDraftId;

  bool get removed =>
      outcome == SessionCompletionOutcome.deletedEmpty ||
      outcome == SessionCompletionOutcome.notFound;
}

class UnresolvedDraftException implements Exception {
  const UnresolvedDraftException({
    required this.seriesId,
    required this.shotCount,
    required this.photoCount,
    required this.hasNotes,
    required this.wasEdited,
  });

  final String seriesId;
  final int shotCount;
  final int photoCount;
  final bool hasNotes;
  final bool wasEdited;

  @override
  String toString() =>
      'Conceptreeks $seriesId bevat $shotCount schoten, $photoCount foto\'s'
      '${hasNotes ? ' en een notitie' : ''}'
      '${wasEdited ? ' en bewaarde wijzigingen' : ''}.';
}

class SeriesDetail {
  const SeriesDetail({
    required this.series,
    required this.impacts,
    required this.images,
    required this.primaryImage,
    required this.photoAlignment,
    required this.firearm,
    required this.ammoLot,
    required this.cartridge,
  });

  final SeriesRecord series;
  final List<ImpactRecord> impacts;
  final List<ImageAssetRecord> images;
  final ImageAssetRecord? primaryImage;
  final PhotoAlignmentRecord? photoAlignment;
  final FirearmRecord? firearm;
  final AmmoLotRecord? ammoLot;
  final CartridgeRecord? cartridge;

  domain.TargetProfile get target =>
      domain.TargetProfile.fromJsonString(series.targetProfileJson);
}

String _sessionListSql(String whereClause) =>
    '''
  WITH filtered_sessions AS (
    SELECT *
    FROM training_sessions AS session
    $whereClause
  ),
  series_aggregate AS (
    SELECT
      session_id,
      SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END)
        AS confirmed_series_count,
      SUM(CASE WHEN status = 'confirmed' THEN shot_count ELSE 0 END)
        AS shot_count,
      SUM(CASE WHEN status = 'confirmed' THEN total_score ELSE 0 END)
        AS total_score,
      SUM(CASE WHEN status = 'confirmed' THEN maximum_possible_score ELSE 0 END)
        AS maximum_possible_score,
      SUM(CASE WHEN status = 'confirmed' THEN inner_ten_count ELSE 0 END)
        AS inner_ten_count,
      MAX(CASE WHEN status = 'draft' THEN id END) AS draft_series_id,
      MAX(CASE WHEN status = 'draft' THEN shot_count ELSE 0 END)
        AS draft_shot_count,
      MAX(CASE
        WHEN status = 'draft' AND TRIM(COALESCE(notes, '')) <> '' THEN 1
        ELSE 0
      END) AS draft_has_notes,
      MAX(CASE
        WHEN status = 'draft' AND updated_at_utc > created_at_utc THEN 1
        ELSE 0
      END) AS draft_was_edited
    FROM shooting_series
    WHERE session_id IN (SELECT id FROM filtered_sessions)
    GROUP BY session_id
  ),
  image_aggregate AS (
    SELECT
      session_id,
      COUNT(*) AS photo_count,
      SUM(CASE WHEN series_id IS NULL THEN 1 ELSE 0 END)
        AS session_photo_count
    FROM image_assets
    WHERE session_id IN (SELECT id FROM filtered_sessions)
    GROUP BY session_id
  )
  SELECT
    session.id,
    session.status,
    session.started_at_utc,
    session.local_utc_offset_minutes,
    session.ended_at_utc,
    session.updated_at_utc,
    session.photo_safety_acknowledged_at_utc,
    session.range_id,
    session.training_goal,
    session.conditions,
    session.notes,
    COALESCE(series.confirmed_series_count, 0) AS confirmed_series_count,
    COALESCE(series.shot_count, 0) AS shot_count,
    COALESCE(series.total_score, 0) AS total_score,
    COALESCE(series.maximum_possible_score, 0) AS maximum_possible_score,
    COALESCE(series.inner_ten_count, 0) AS inner_ten_count,
    COALESCE(images.photo_count, 0) AS photo_count,
    COALESCE(images.session_photo_count, 0) AS session_photo_count,
    series.draft_series_id,
    COALESCE(series.draft_shot_count, 0) AS draft_shot_count,
    COALESCE(series.draft_has_notes, 0) AS draft_has_notes,
    COALESCE(series.draft_was_edited, 0) AS draft_was_edited,
    COALESCE((
      SELECT COUNT(*)
      FROM image_assets AS draft_image
      WHERE draft_image.series_id = series.draft_series_id
    ), 0) AS draft_photo_count,
    (
      SELECT preview.path
      FROM image_assets AS preview
      WHERE preview.session_id = session.id
      ORDER BY
        CASE WHEN preview.role = 'primaryScoringPhoto' THEN 0 ELSE 1 END,
        preview.created_at_utc DESC,
        preview.id DESC
      LIMIT 1
    ) AS thumbnail_path
  FROM filtered_sessions AS session
  LEFT JOIN series_aggregate AS series ON series.session_id = session.id
  LEFT JOIN image_aggregate AS images ON images.session_id = session.id
''';

SessionListItem _sessionListItemFromRow(QueryRow row) {
  final data = row.data;
  return SessionListItem(
    session: SessionRecord(
      id: data['id']! as String,
      status: data['status']! as String,
      startedAtUtc: _dateTimeFromDatabase(data['started_at_utc'])!,
      localUtcOffsetMinutes: data['local_utc_offset_minutes']! as int,
      endedAtUtc: _dateTimeFromDatabase(data['ended_at_utc']),
      updatedAtUtc: _dateTimeFromDatabase(data['updated_at_utc'])!,
      photoSafetyAcknowledgedAtUtc: _dateTimeFromDatabase(
        data['photo_safety_acknowledged_at_utc'],
      ),
      rangeId: data['range_id'] as String?,
      trainingGoal: data['training_goal'] as String?,
      conditions: data['conditions'] as String?,
      notes: data['notes'] as String?,
    ),
    confirmedSeriesCount: data['confirmed_series_count']! as int,
    shotCount: data['shot_count']! as int,
    totalScore: data['total_score']! as int,
    maximumPossibleScore: data['maximum_possible_score']! as int,
    innerTenCount: data['inner_ten_count']! as int,
    photoCount: data['photo_count']! as int,
    sessionPhotoCount: data['session_photo_count']! as int,
    draftSeriesId: data['draft_series_id'] as String?,
    draftShotCount: data['draft_shot_count']! as int,
    draftPhotoCount: data['draft_photo_count']! as int,
    draftHasNotes: (data['draft_has_notes']! as int) != 0,
    draftWasEdited: (data['draft_was_edited']! as int) != 0,
    thumbnailPath: data['thumbnail_path'] as String?,
  );
}

DateTime? _dateTimeFromDatabase(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  return DateTime.parse(value as String).toUtc();
}

class ShootingRepository {
  ShootingRepository(this.database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final Uuid _uuid;

  Stream<List<SessionRecord>> watchSessions() => database.watchSessions();

  Stream<List<SessionListItem>> watchSessionListItems([
    SessionListFilters filters = const SessionListFilters(),
  ]) {
    final predicates = <String>[];
    final variables = <Variable<Object>>[];
    switch (filters.status) {
      case SessionListStatusFilter.all:
        break;
      case SessionListStatusFilter.active:
        predicates.add('session.status = ?');
        variables.add(Variable<String>(domain.SessionStatus.active.name));
      case SessionListStatusFilter.completed:
        predicates.add('session.status = ?');
        variables.add(Variable<String>(domain.SessionStatus.completed.name));
    }
    final startedAtOrAfterUtc = filters.startedAtOrAfterUtc;
    if (startedAtOrAfterUtc != null) {
      predicates.add('session.started_at_utc >= ?');
      variables.add(Variable<DateTime>(startedAtOrAfterUtc.toUtc()));
    }
    final where = predicates.isEmpty ? '' : 'WHERE ${predicates.join(' AND ')}';
    return database
        .customSelect(
          '''
            ${_sessionListSql(where)}
            ORDER BY session.started_at_utc DESC, session.id DESC
          ''',
          variables: variables,
          readsFrom: {
            database.trainingSessions,
            database.shootingSeries,
            database.imageAssets,
          },
        )
        .watch()
        .map(
          (rows) => rows.map(_sessionListItemFromRow).toList(growable: false),
        );
  }

  Stream<SessionRecord?> watchActiveSession() => database.watchActiveSession();

  Stream<List<SeriesRecord>> watchSeries(String sessionId) =>
      database.watchSeries(sessionId);

  Stream<List<SeriesRecord>> watchConfirmedSeries() =>
      database.watchConfirmedSeries();

  Stream<List<AnalysisSeriesData>> watchAnalysisDataset() => database
      .customSelect(
        'SELECT 1',
        readsFrom: {
          database.shootingSeries,
          database.trainingSessions,
          database.shotImpacts,
          database.firearms,
          database.ammoLots,
          database.cartridges,
          database.seriesReflections,
        },
      )
      .watch()
      .asyncMap((_) => _loadAnalysisDataset());

  Stream<List<GoalRecord>> watchGoals({bool activeOnly = false}) {
    final query = database.select(database.goals)
      ..orderBy([(row) => OrderingTerm.asc(row.targetProfileVersionedId)]);
    if (activeOnly) query.where((row) => row.active.equals(true));
    return query.watch();
  }

  Stream<SeriesReflectionRecord?> watchSeriesReflection(String seriesId) =>
      (database.select(
        database.seriesReflections,
      )..where((row) => row.seriesId.equals(seriesId))).watchSingleOrNull();

  Stream<List<SeriesReflectionRecord>> watchSeriesReflections() =>
      (database.select(
        database.seriesReflections,
      )..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)])).watch();

  Stream<List<CoachFeedbackRecord>> watchCoachFeedback() =>
      database.select(database.coachFeedback).watch();

  Stream<List<ImpactRecord>> watchImpacts(String seriesId) =>
      database.watchImpacts(seriesId);

  Stream<List<ImageAssetRecord>> watchSessionImages(String sessionId) =>
      database.watchSessionImages(sessionId);

  Stream<List<ImageAssetRecord>> watchSeriesImages(String seriesId) =>
      database.watchSeriesImages(seriesId);

  Stream<ImageAssetRecord?> watchImage(String imageId) =>
      database.watchImage(imageId);

  Stream<SessionDetail?> watchSessionDetail(String sessionId) => database
      .customSelect(
        'SELECT 1',
        readsFrom: {
          database.trainingSessions,
          database.shootingSeries,
          database.imageAssets,
          database.firearms,
          database.ammoLots,
          database.cartridges,
        },
      )
      .watch()
      .asyncMap((_) => getSessionDetail(sessionId));

  Stream<SeriesDetail?> watchSeriesDetail(String seriesId) => database
      .customSelect(
        'SELECT 1',
        readsFrom: {
          database.shootingSeries,
          database.shotImpacts,
          database.imageAssets,
          database.photoAlignments,
          database.firearms,
          database.ammoLots,
          database.cartridges,
        },
      )
      .watch()
      .asyncMap((_) => getSeriesDetail(seriesId));

  Stream<List<FirearmRecord>> watchFirearms() => database.watchFirearms();

  Stream<List<FirearmRecord>> watchAllFirearms() => database.watchAllFirearms();

  Stream<List<CartridgeRecord>> watchCartridges() => database.watchCartridges();

  Stream<List<CartridgeRecord>> watchAllCartridges() =>
      database.watchAllCartridges();

  Stream<List<AmmoLotRecord>> watchAmmoLots() => database.watchAmmoLots();

  Stream<List<AmmoLotRecord>> watchAllAmmoLots() => database.watchAllAmmoLots();

  Stream<List<RangeRecord>> watchRanges() => database.watchRanges();

  Stream<List<RangeRecord>> watchAllRanges() => database.watchAllRanges();

  Stream<List<TargetProfileRecord>> watchTargetProfiles() =>
      database.watchTargetProfiles();

  Stream<List<TargetProfileRecord>> watchAllTargetProfiles() =>
      database.watchAllTargetProfiles();

  Future<String> saveGoal({
    String? id,
    required String targetProfileVersionedId,
    required double distanceMeters,
    String? firearmId,
    String? ammoLotId,
    required GoalMetric metric,
    required double targetValue,
    required GoalComparison comparison,
    bool active = true,
  }) async {
    if (targetProfileVersionedId.trim().isEmpty ||
        !distanceMeters.isFinite ||
        distanceMeters <= 0 ||
        !targetValue.isFinite ||
        targetValue < 0) {
      throw ArgumentError('Doelkaart, afstand en doelwaarde zijn verplicht.');
    }
    final goalId = id ?? _uuid.v7();
    await database.transaction(() async {
      final targetExists =
          await (database.select(database.targetProfiles)..where(
                (row) => row.versionedId.equals(targetProfileVersionedId),
              ))
              .getSingleOrNull();
      if (targetExists == null) {
        throw ArgumentError('De gekozen doelkaart bestaat niet meer.');
      }
      await database
          .into(database.goals)
          .insertOnConflictUpdate(
            GoalsCompanion.insert(
              id: goalId,
              targetProfileVersionedId: targetProfileVersionedId,
              distanceMeters: distanceMeters,
              firearmId: Value(firearmId),
              ammoLotId: Value(ammoLotId),
              metric: metric.name,
              targetValue: targetValue,
              comparison: comparison.name,
              active: Value(active),
            ),
          );
    });
    return goalId;
  }

  Future<void> deleteGoal(String id) =>
      (database.delete(database.goals)..where((row) => row.id.equals(id))).go();

  Future<void> saveSeriesReflection({
    required String seriesId,
    required PerceivedQuality perceivedQuality,
    Set<ReflectionContextTag> contextTags = const {},
    String? note,
  }) async {
    if (contextTags.length > 3) {
      throw ArgumentError('Kies maximaal drie contexttags.');
    }
    final existing = await (database.select(
      database.seriesReflections,
    )..where((row) => row.seriesId.equals(seriesId))).getSingleOrNull();
    final now = DateTime.now().toUtc();
    await database
        .into(database.seriesReflections)
        .insertOnConflictUpdate(
          SeriesReflectionsCompanion.insert(
            seriesId: seriesId,
            perceivedQuality: perceivedQuality.name,
            contextTagsJson: Value(
              jsonEncode(contextTags.map((tag) => tag.name).toList()..sort()),
            ),
            note: Value(_nullIfBlank(note)),
            createdAtUtc: existing?.createdAtUtc ?? now,
            updatedAtUtc: now,
          ),
        );
  }

  Future<void> deleteSeriesReflection(String seriesId) => (database.delete(
    database.seriesReflections,
  )..where((row) => row.seriesId.equals(seriesId))).go();

  Future<void> saveCoachFeedback({
    required String insightFingerprint,
    required String ruleId,
    required int ruleVersion,
    required StoredCoachFeedbackResponse response,
    DateTime? snoozedUntilUtc,
  }) async {
    if (insightFingerprint.trim().isEmpty ||
        ruleId.trim().isEmpty ||
        ruleVersion < 1) {
      throw ArgumentError('Ongeldige coachfeedback.');
    }
    await database
        .into(database.coachFeedback)
        .insertOnConflictUpdate(
          CoachFeedbackCompanion.insert(
            insightFingerprint: insightFingerprint,
            ruleId: ruleId,
            ruleVersion: ruleVersion,
            response: response.name,
            snoozedUntilUtc: Value(snoozedUntilUtc?.toUtc()),
            updatedAtUtc: DateTime.now().toUtc(),
          ),
        );
  }

  Stream<List<TrainingActivityRecord>> watchTrainingActivities([
    TrainingActivityFilters filters = const TrainingActivityFilters(),
  ]) {
    final query = database.select(database.trainingActivities)
      ..orderBy([(row) => OrderingTerm.desc(row.startedAtUtc)]);
    final kind = filters.kind;
    if (kind != null) query.where((row) => row.kind.equals(kind.name));
    final sessionId = filters.sessionId;
    if (sessionId != null) {
      query.where((row) => row.sessionId.equals(sessionId));
    }
    final status = filters.status;
    if (status != null) query.where((row) => row.status.equals(status.name));
    return query.watch();
  }

  Stream<TrainingActivityDetail?> watchTrainingActivity(String activityId) =>
      database
          .customSelect(
            'SELECT 1',
            readsFrom: {
              database.trainingActivities,
              database.trainingActivitySeriesLinks,
              database.shotTimerEvents,
            },
          )
          .watch()
          .asyncMap((_) => getTrainingActivity(activityId));

  Stream<List<TrainingActivityRecord>> watchSessionTrainingActivities(
    String sessionId,
  ) =>
      (database.select(database.trainingActivities)
            ..where((row) => row.sessionId.equals(sessionId))
            ..orderBy([(row) => OrderingTerm.desc(row.startedAtUtc)]))
          .watch();

  Stream<List<TrainingActivityRecord>> watchSeriesTrainingActivities(
    String seriesId,
  ) {
    final query = database.select(database.trainingActivities).join([
      innerJoin(
        database.trainingActivitySeriesLinks,
        database.trainingActivitySeriesLinks.activityId.equalsExp(
          database.trainingActivities.id,
        ),
      ),
    ])..where(database.trainingActivitySeriesLinks.seriesId.equals(seriesId));
    query.orderBy([
      OrderingTerm.desc(database.trainingActivities.startedAtUtc),
    ]);
    return query.watch().map(
      (rows) => rows
          .map((row) => row.readTable(database.trainingActivities))
          .toList(growable: false),
    );
  }

  Stream<List<TimerPresetRecord>> watchTimerPresets({
    bool includeArchived = false,
  }) {
    final query = database.select(database.timerPresets)
      ..orderBy([
        (row) => OrderingTerm.asc(row.builtIn),
        (row) => OrderingTerm.asc(row.name),
      ]);
    if (!includeArchived) query.where((row) => row.archived.equals(false));
    return query.watch();
  }

  Stream<List<AcousticCalibrationProfileRecord>>
  watchAcousticCalibrationProfiles() => (database.select(
    database.acousticCalibrationProfiles,
  )..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)])).watch();

  Future<TrainingActivityDetail?> getTrainingActivity(String activityId) async {
    final activity = await (database.select(
      database.trainingActivities,
    )..where((row) => row.id.equals(activityId))).getSingleOrNull();
    if (activity == null) return null;
    final links =
        await (database.select(database.trainingActivitySeriesLinks)
              ..where((row) => row.activityId.equals(activityId))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    final events =
        await (database.select(database.shotTimerEvents)
              ..where((row) => row.activityId.equals(activityId))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    return TrainingActivityDetail(
      activity: activity,
      links: List.unmodifiable(links),
      events: List.unmodifiable(events),
    );
  }

  Future<String> createTrainingActivity({
    String? id,
    required StoredTrainingActivityKind kind,
    int activitySchemaVersion = 1,
    StoredTrainingActivityStatus status = StoredTrainingActivityStatus.draft,
    String? sessionId,
    Map<String, Object?> configuration = const {},
    Map<String, Object?> summary = const {},
    String? detectorVersion,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
    DateTime? completedAtUtc,
    String? notes,
  }) async {
    if (activitySchemaVersion < 1 || localUtcOffsetMinutes.abs() > 24 * 60) {
      throw ArgumentError('Ongeldige trainingsactiviteit.');
    }
    if (status == StoredTrainingActivityStatus.completed &&
        completedAtUtc == null) {
      throw ArgumentError('Een voltooide activiteit vereist een eindtijd.');
    }
    final configurationJson = _encodeJsonObject(
      configuration,
      'timerconfiguratie',
    );
    final summaryJson = _encodeJsonObject(summary, 'timersamenvatting');
    final activityId = id ?? _uuid.v7();
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      if (sessionId != null && await _session(sessionId) == null) {
        throw ArgumentError('De gekozen sessie bestaat niet meer.');
      }
      await database
          .into(database.trainingActivities)
          .insert(
            TrainingActivitiesCompanion.insert(
              id: activityId,
              kind: kind.name,
              schemaVersion: Value(activitySchemaVersion),
              status: status.name,
              sessionId: Value(sessionId),
              configurationJson: configurationJson,
              summaryJson: summaryJson,
              detectorVersion: Value(_nullIfBlank(detectorVersion)),
              startedAtUtc: startedAtUtc.toUtc(),
              localUtcOffsetMinutes: localUtcOffsetMinutes,
              completedAtUtc: Value(completedAtUtc?.toUtc()),
              notes: Value(_nullIfBlank(notes)),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      if (sessionId != null) await _touchSession(sessionId, now);
    });
    return activityId;
  }

  /// Persists a reviewed timer result and its optional series link atomically.
  ///
  /// Supplying a stable [id] makes a retried call idempotent after the first
  /// transaction committed. No draft record can remain after a failed write.
  Future<String> saveCompletedTimerActivity({
    String? id,
    required StoredTrainingActivityKind kind,
    int activitySchemaVersion = 1,
    String? sessionId,
    String? seriesId,
    Map<String, Object?> configuration = const {},
    required Map<String, Object?> summary,
    required List<NewShotTimerEvent> events,
    String? detectorVersion,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
    required DateTime completedAtUtc,
    String? notes,
  }) async {
    if (!_timerActivityKinds.contains(kind.name) ||
        activitySchemaVersion < 1 ||
        localUtcOffsetMinutes.abs() > 24 * 60 ||
        completedAtUtc.toUtc().isBefore(startedAtUtc.toUtc())) {
      throw ArgumentError('Ongeldige voltooide timerrun.');
    }
    final configurationJson = _encodeJsonObject(
      configuration,
      'timerconfiguratie',
    );
    final summaryJson = _encodeJsonObject(summary, 'timersamenvatting');
    final activityId = id ?? _uuid.v7();
    await database.transaction(() async {
      final alreadyStored = await _trainingActivity(activityId);
      if (alreadyStored != null) {
        if (alreadyStored.status ==
            StoredTrainingActivityStatus.completed.name) {
          return;
        }
        throw StateError('De activiteit-ID is al in gebruik.');
      }
      SeriesRecord? linkedSeries;
      if (seriesId != null) {
        linkedSeries = await _series(seriesId);
        if (linkedSeries == null) {
          throw ArgumentError('De gekozen reeks bestaat niet meer.');
        }
        if (sessionId != null && sessionId != linkedSeries.sessionId) {
          throw StateError('De reeks hoort bij een andere sessie.');
        }
      }
      final effectiveSessionId = linkedSeries?.sessionId ?? sessionId;
      if (effectiveSessionId != null &&
          await _session(effectiveSessionId) == null) {
        throw ArgumentError('De gekozen sessie bestaat niet meer.');
      }
      final now = DateTime.now().toUtc();
      await database
          .into(database.trainingActivities)
          .insert(
            TrainingActivitiesCompanion.insert(
              id: activityId,
              kind: kind.name,
              schemaVersion: Value(activitySchemaVersion),
              status: StoredTrainingActivityStatus.completed.name,
              sessionId: Value(effectiveSessionId),
              configurationJson: configurationJson,
              summaryJson: summaryJson,
              detectorVersion: Value(_nullIfBlank(detectorVersion)),
              startedAtUtc: startedAtUtc.toUtc(),
              localUtcOffsetMinutes: localUtcOffsetMinutes,
              completedAtUtc: Value(completedAtUtc.toUtc()),
              notes: Value(_nullIfBlank(notes)),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await _replaceTimerEvents(activityId, events);
      final recomputedSummaryJson = await _recomputeTimerSummaryJson(
        activityId,
        baseSummaryJson: summaryJson,
        markUserEdited: false,
      );
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          summaryJson: Value(recomputedSummaryJson),
          updatedAtUtc: Value(now),
        ),
      );
      if (linkedSeries != null) {
        await database
            .into(database.trainingActivitySeriesLinks)
            .insert(
              TrainingActivitySeriesLinksCompanion.insert(
                activityId: activityId,
                seriesId: linkedSeries.id,
                sequenceNumber: 1,
              ),
            );
      }
      if (effectiveSessionId != null) {
        await _touchSession(effectiveSessionId, now);
      }
    });
    return activityId;
  }

  Future<void> completeTrainingActivity({
    required String activityId,
    required Map<String, Object?> summary,
    required List<NewShotTimerEvent> events,
    required DateTime completedAtUtc,
    String? detectorVersion,
    String? notes,
  }) async {
    final summaryJson = _encodeJsonObject(summary, 'timersamenvatting');
    await database.transaction(() async {
      final activity = await _requireTimerActivity(activityId);
      await _replaceTimerEvents(activityId, events);
      final recomputedSummaryJson = await _recomputeTimerSummaryJson(
        activityId,
        baseSummaryJson: summaryJson,
        markUserEdited: false,
      );
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.completed.name),
          summaryJson: Value(recomputedSummaryJson),
          detectorVersion: Value(
            _nullIfBlank(detectorVersion) ?? activity.detectorVersion,
          ),
          completedAtUtc: Value(completedAtUtc.toUtc()),
          notes: Value(_nullIfBlank(notes)),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  Future<void> interruptTrainingActivity({
    required String activityId,
    Map<String, Object?> summary = const {},
    DateTime? interruptedAtUtc,
    String? notes,
  }) async {
    final summaryJson = _encodeJsonObject(summary, 'timersamenvatting');
    await database.transaction(() async {
      final activity = await _trainingActivity(activityId);
      if (activity == null) return;
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.interrupted.name),
          summaryJson: Value(summaryJson),
          completedAtUtc: Value((interruptedAtUtc ?? now).toUtc()),
          notes: Value(_nullIfBlank(notes)),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  Future<void> replaceTimerEvents(
    String activityId,
    List<NewShotTimerEvent> events,
  ) => database.transaction(() async {
    final activity = await _requireTimerActivity(activityId);
    await _replaceTimerEvents(activityId, events);
    final summaryJson = await _recomputeTimerSummaryJson(
      activityId,
      baseSummaryJson: activity.summaryJson,
      markUserEdited: true,
    );
    final now = DateTime.now().toUtc();
    await (database.update(
      database.trainingActivities,
    )..where((row) => row.id.equals(activityId))).write(
      TrainingActivitiesCompanion(
        summaryJson: Value(summaryJson),
        updatedAtUtc: Value(now),
      ),
    );
    if (activity.sessionId != null) {
      await _touchSession(activity.sessionId!, now);
    }
  });

  Future<void> excludeTimerEvent(String eventId, String reason) =>
      _setTimerEventDisposition(
        eventId,
        StoredTimerEventDisposition.excluded,
        reason: reason,
      );

  Future<void> restoreTimerEvent(String eventId) =>
      _setTimerEventDisposition(eventId, StoredTimerEventDisposition.counted);

  Future<void> linkTrainingActivityToSeries(
    String activityId,
    String seriesId, {
    String? role,
    String? variantId,
  }) async {
    await database.transaction(() async {
      final activity = await _trainingActivity(activityId);
      final series = await _series(seriesId);
      if (activity == null || series == null) {
        throw ArgumentError('De trainingsactiviteit of reeks bestaat niet.');
      }
      if (activity.sessionId != null &&
          activity.sessionId != series.sessionId) {
        throw StateError('Activiteit en reeks behoren tot een andere sessie.');
      }
      final existingLinks = await (database.select(
        database.trainingActivitySeriesLinks,
      )..where((row) => row.activityId.equals(activityId))).get();
      final isTimer = _timerActivityKinds.contains(activity.kind);
      if (isTimer && existingLinks.any((link) => link.seriesId != seriesId)) {
        throw StateError('Een timerrun kan aan maximaal één reeks hangen.');
      }
      final existingForSeries = existingLinks
          .where((link) => link.seriesId == seriesId)
          .firstOrNull;
      final sequenceNumber =
          existingForSeries?.sequenceNumber ??
          (existingLinks.isEmpty
              ? 1
              : existingLinks
                        .map((link) => link.sequenceNumber)
                        .reduce((left, right) => left > right ? left : right) +
                    1);
      await database
          .into(database.trainingActivitySeriesLinks)
          .insertOnConflictUpdate(
            TrainingActivitySeriesLinksCompanion.insert(
              activityId: activityId,
              seriesId: seriesId,
              sequenceNumber: sequenceNumber,
              role: Value(_nullIfBlank(role)),
              variantId: Value(_nullIfBlank(variantId)),
            ),
          );
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          sessionId: Value(series.sessionId),
          updatedAtUtc: Value(now),
        ),
      );
      await _touchSession(series.sessionId, now);
    });
  }

  Future<void> unlinkTrainingActivityFromSeries(
    String activityId,
    String seriesId,
  ) =>
      (database.delete(database.trainingActivitySeriesLinks)..where(
            (row) =>
                row.activityId.equals(activityId) &
                row.seriesId.equals(seriesId),
          ))
          .go();

  Future<void> appendTimerSummaryToSeriesNote(
    String seriesId,
    String summaryText,
  ) async {
    final summary = summaryText.trim();
    if (summary.isEmpty) {
      throw ArgumentError('De timersamenvatting is leeg.');
    }
    await database.transaction(() async {
      final series = await _series(seriesId);
      if (series == null) {
        throw ArgumentError('De gekozen reeks bestaat niet meer.');
      }
      final existing = series.notes?.trim();
      final updatedNotes = existing == null || existing.isEmpty
          ? summary
          : '$existing\n\n$summary';
      final now = DateTime.now().toUtc();
      await (database.update(
        database.shootingSeries,
      )..where((row) => row.id.equals(seriesId))).write(
        ShootingSeriesCompanion(
          notes: Value(updatedNotes),
          updatedAtUtc: Value(now),
        ),
      );
      await _touchSession(series.sessionId, now);
    });
  }

  Future<int> countSessionTrainingActivities(String sessionId) async {
    final count = database.trainingActivities.id.count();
    final query = database.selectOnly(database.trainingActivities)
      ..addColumns([count])
      ..where(database.trainingActivities.sessionId.equals(sessionId));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<void> deleteTrainingActivity(String activityId) => (database.delete(
    database.trainingActivities,
  )..where((row) => row.id.equals(activityId))).go();

  Future<String> saveTimerPreset({
    String? id,
    required String name,
    required StoredTrainingActivityKind mode,
    required Map<String, Object?> configuration,
    bool builtIn = false,
  }) async {
    if (!_timerActivityKinds.contains(mode.name) || name.trim().isEmpty) {
      throw ArgumentError('Ongeldige timerpreset.');
    }
    final configurationJson = _encodeJsonObject(
      configuration,
      'timerconfiguratie',
    );
    final presetId = id ?? _uuid.v7();
    final existing = await (database.select(
      database.timerPresets,
    )..where((row) => row.id.equals(presetId))).getSingleOrNull();
    if (existing?.builtIn == true && !builtIn) {
      throw StateError('Ingebouwde timerpresets zijn alleen-lezen.');
    }
    final now = DateTime.now().toUtc();
    await database
        .into(database.timerPresets)
        .insertOnConflictUpdate(
          TimerPresetsCompanion.insert(
            id: presetId,
            name: name.trim(),
            mode: mode.name,
            configurationJson: configurationJson,
            builtIn: Value(builtIn || (existing?.builtIn ?? false)),
            archived: const Value(false),
            createdAtUtc: existing?.createdAtUtc ?? now,
            updatedAtUtc: now,
          ),
        );
    return presetId;
  }

  Future<void> archiveTimerPreset(String id) async {
    final preset = await (database.select(
      database.timerPresets,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (preset == null) return;
    if (preset.builtIn) {
      throw StateError(
        'Ingebouwde timerpresets kunnen niet gearchiveerd worden.',
      );
    }
    await (database.update(
      database.timerPresets,
    )..where((row) => row.id.equals(id))).write(
      TimerPresetsCompanion(
        archived: const Value(true),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<String> saveCalibrationProfile({
    String? id,
    required String name,
    String? firearmId,
    String? cartridgeId,
    required String environment,
    required String audioRoute,
    required int sampleRate,
    required double sensitivity,
    required int echoLockoutMicroseconds,
    required int beepBlankingMicroseconds,
    required String detectorVersion,
  }) async {
    if (name.trim().isEmpty ||
        environment.trim().isEmpty ||
        audioRoute.trim().isEmpty ||
        detectorVersion.trim().isEmpty ||
        sampleRate <= 0 ||
        !sensitivity.isFinite ||
        sensitivity < 0 ||
        echoLockoutMicroseconds < 0 ||
        beepBlankingMicroseconds < 0) {
      throw ArgumentError('Ongeldig akoestisch kalibratieprofiel.');
    }
    final profileId = id ?? _uuid.v7();
    await database.transaction(() async {
      if (firearmId != null && await _firearm(firearmId) == null) {
        throw ArgumentError('Het gekozen wapen bestaat niet meer.');
      }
      if (cartridgeId != null && await _cartridge(cartridgeId) == null) {
        throw ArgumentError('Het gekozen kaliber bestaat niet meer.');
      }
      final existing = await (database.select(
        database.acousticCalibrationProfiles,
      )..where((row) => row.id.equals(profileId))).getSingleOrNull();
      final now = DateTime.now().toUtc();
      await database
          .into(database.acousticCalibrationProfiles)
          .insertOnConflictUpdate(
            AcousticCalibrationProfilesCompanion.insert(
              id: profileId,
              name: name.trim(),
              firearmId: Value(firearmId),
              cartridgeId: Value(cartridgeId),
              environment: environment.trim(),
              audioRoute: audioRoute.trim(),
              sampleRate: sampleRate,
              sensitivity: sensitivity,
              echoLockoutMicroseconds: echoLockoutMicroseconds,
              beepBlankingMicroseconds: beepBlankingMicroseconds,
              detectorVersion: detectorVersion.trim(),
              createdAtUtc: existing?.createdAtUtc ?? now,
              updatedAtUtc: now,
            ),
          );
    });
    return profileId;
  }

  Future<void> deleteCalibrationProfile(String id) => (database.delete(
    database.acousticCalibrationProfiles,
  )..where((row) => row.id.equals(id))).go();

  Future<List<AnalysisSeriesData>> _loadAnalysisDataset() async {
    final series = await getConfirmedSeries();
    if (series.isEmpty) return const [];
    final sessions = await database.select(database.trainingSessions).get();
    final impacts = await database.select(database.shotImpacts).get();
    final firearms = await database.select(database.firearms).get();
    final ammoLots = await database.select(database.ammoLots).get();
    final cartridges = await database.select(database.cartridges).get();
    final reflections = await database.select(database.seriesReflections).get();
    final impactsBySeries = <String, List<ImpactRecord>>{};
    for (final impact in impacts) {
      impactsBySeries.putIfAbsent(impact.seriesId, () => []).add(impact);
    }
    final sessionById = {for (final item in sessions) item.id: item};
    final firearmById = {for (final item in firearms) item.id: item};
    final ammoById = {for (final item in ammoLots) item.id: item};
    final cartridgeById = {for (final item in cartridges) item.id: item};
    final reflectionBySeries = {
      for (final item in reflections) item.seriesId: item,
    };
    return series
        .map((item) {
          final session = sessionById[item.sessionId];
          if (session == null) {
            throw StateError(
              'Bevestigde reeks ${item.id} verwijst naar een ontbrekende sessie.',
            );
          }
          return AnalysisSeriesData(
            session: session,
            series: item,
            impacts: List.unmodifiable(impactsBySeries[item.id] ?? const []),
            firearm: item.firearmId == null
                ? null
                : firearmById[item.firearmId],
            ammoLot: item.ammoLotId == null ? null : ammoById[item.ammoLotId],
            cartridge: item.cartridgeId == null
                ? null
                : cartridgeById[item.cartridgeId],
            reflection: reflectionBySeries[item.id],
          );
        })
        .toList(growable: false);
  }

  Future<void> seedDefaults() async {
    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.cartridges,
        CartridgePresets.all
            .map(
              (cartridge) => CartridgesCompanion.insert(
                id: cartridge.id,
                name: cartridge.name,
                projectileDiameterMm: cartridge.projectileDiameterMm,
                notes: Value(cartridge.notes),
                builtIn: const Value(true),
              ),
            )
            .toList(),
      );
      batch.insertAllOnConflictUpdate(
        database.targetProfiles,
        [...IssfTargetProfiles.all, ...WrabfTargetProfiles.all]
            .map(
              (target) => TargetProfilesCompanion.insert(
                versionedId: target.versionedId,
                profileId: target.profileId,
                profileVersion: target.profileVersion,
                displayName: target.displayName,
                validationStatus: target.validationStatus.name,
                profileJson: target.toJsonString(),
                builtIn: const Value(true),
                createdAtUtc: DateTime.utc(2026, 1, 1),
              ),
            )
            .toList(),
      );
      batch.insertAllOnConflictUpdate(
        database.timerPresets,
        builtInTimerPresetCompanions(),
      );
    });
  }

  Future<void> addCustomTargetProfile(domain.TargetProfile profile) async {
    await database
        .into(database.targetProfiles)
        .insert(
          TargetProfilesCompanion.insert(
            versionedId: profile.versionedId,
            profileId: profile.profileId,
            profileVersion: profile.profileVersion,
            displayName: profile.displayName,
            validationStatus: profile.validationStatus.name,
            profileJson: profile.toJsonString(),
            builtIn: const Value(false),
            createdAtUtc: DateTime.now().toUtc(),
          ),
        );
  }

  Future<String> addCustomCartridge({
    required String name,
    required double projectileDiameterMm,
    String? notes,
  }) async {
    if (name.trim().isEmpty || projectileDiameterMm <= 0) {
      throw ArgumentError('Naam en projectieldiameter zijn verplicht.');
    }
    final id = _uuid.v7();
    await database
        .into(database.cartridges)
        .insert(
          CartridgesCompanion.insert(
            id: id,
            name: name.trim(),
            projectileDiameterMm: projectileDiameterMm,
            notes: Value(_nullIfBlank(notes)),
            builtIn: const Value(false),
          ),
        );
    return id;
  }

  Future<String> addFirearm({
    required String name,
    required domain.FirearmType type,
    String? manufacturer,
    String? model,
    String? defaultCartridgeId,
    String? sightNotes,
  }) async {
    final id = _uuid.v7();
    await database
        .into(database.firearms)
        .insert(
          FirearmsCompanion.insert(
            id: id,
            name: name.trim(),
            type: type.name,
            manufacturer: Value(_nullIfBlank(manufacturer)),
            model: Value(_nullIfBlank(model)),
            defaultCartridgeId: Value(defaultCartridgeId),
            sightNotes: Value(_nullIfBlank(sightNotes)),
          ),
        );
    return id;
  }

  Future<String> addAmmoLot({
    required String cartridgeId,
    required String displayName,
    String? manufacturer,
    String? productName,
    String? lotNumber,
    double? bulletWeightGrains,
    String? projectileType,
    String? notes,
  }) async {
    final id = _uuid.v7();
    await database
        .into(database.ammoLots)
        .insert(
          AmmoLotsCompanion.insert(
            id: id,
            cartridgeId: cartridgeId,
            displayName: displayName.trim(),
            manufacturer: Value(_nullIfBlank(manufacturer)),
            productName: Value(_nullIfBlank(productName)),
            lotNumber: Value(_nullIfBlank(lotNumber)),
            bulletWeightGrains: Value(bulletWeightGrains),
            projectileType: Value(_nullIfBlank(projectileType)),
            notes: Value(_nullIfBlank(notes)),
          ),
        );
    return id;
  }

  Future<String> addRange({
    required String name,
    required bool isIndoor,
    String? locationDescription,
    List<double> availableDistances = const [],
    String? notes,
  }) async {
    final id = _uuid.v7();
    await database
        .into(database.ranges)
        .insert(
          RangesCompanion.insert(
            id: id,
            name: name.trim(),
            isIndoor: Value(isIndoor),
            locationDescription: Value(_nullIfBlank(locationDescription)),
            availableDistancesJson: Value(jsonEncode(availableDistances)),
            notes: Value(_nullIfBlank(notes)),
          ),
        );
    return id;
  }

  Future<LibraryUsageSummary> getLibraryUsage(
    LibraryItemKind kind,
    String id,
  ) async {
    Future<int> count(String sql, String value) async {
      final row = await database
          .customSelect(sql, variables: [Variable<String>(value)])
          .getSingle();
      return (row.data['amount']! as num).toInt();
    }

    switch (kind) {
      case LibraryItemKind.cartridge:
        return LibraryUsageSummary(
          seriesCount: await count(
            'SELECT COUNT(*) AS amount FROM shooting_series WHERE cartridge_id = ?',
            id,
          ),
          dependentAmmoLotCount: await count(
            'SELECT COUNT(*) AS amount FROM ammo_lots WHERE cartridge_id = ?',
            id,
          ),
        );
      case LibraryItemKind.firearm:
        return LibraryUsageSummary(
          seriesCount: await count(
            'SELECT COUNT(*) AS amount FROM shooting_series WHERE firearm_id = ?',
            id,
          ),
          goalCount: await count(
            'SELECT COUNT(*) AS amount FROM goals WHERE firearm_id = ?',
            id,
          ),
        );
      case LibraryItemKind.ammoLot:
        return LibraryUsageSummary(
          seriesCount: await count(
            'SELECT COUNT(*) AS amount FROM shooting_series WHERE ammo_lot_id = ?',
            id,
          ),
          goalCount: await count(
            'SELECT COUNT(*) AS amount FROM goals WHERE ammo_lot_id = ?',
            id,
          ),
        );
      case LibraryItemKind.range:
        return LibraryUsageSummary(
          sessionCount: await count(
            'SELECT COUNT(*) AS amount FROM training_sessions WHERE range_id = ?',
            id,
          ),
        );
      case LibraryItemKind.targetProfile:
        return LibraryUsageSummary(
          seriesCount: await count(
            'SELECT COUNT(*) AS amount FROM shooting_series WHERE target_profile_versioned_id = ?',
            id,
          ),
          goalCount: await count(
            'SELECT COUNT(*) AS amount FROM goals WHERE target_profile_versioned_id = ?',
            id,
          ),
        );
    }
  }

  Future<void> updateFirearm({
    required String id,
    required String name,
    required domain.FirearmType type,
    String? manufacturer,
    String? model,
    String? defaultCartridgeId,
    String? sightNotes,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Een naam is verplicht.');
    }
    final changed =
        await (database.update(
          database.firearms,
        )..where((row) => row.id.equals(id))).write(
          FirearmsCompanion(
            name: Value(name.trim()),
            type: Value(type.name),
            manufacturer: Value(_nullIfBlank(manufacturer)),
            model: Value(_nullIfBlank(model)),
            defaultCartridgeId: Value(defaultCartridgeId),
            sightNotes: Value(_nullIfBlank(sightNotes)),
          ),
        );
    if (changed == 0) {
      throw StateError('Het wapen kon niet worden bijgewerkt.');
    }
  }

  Future<LibraryRemovalResult> removeFirearm(String id) =>
      database.transaction(() async {
        final record = await _firearm(id);
        if (record == null) return LibraryRemovalResult.deleted;
        final usage = await getLibraryUsage(LibraryItemKind.firearm, id);
        if (usage.isInUse) {
          await (database.update(database.firearms)
                ..where((row) => row.id.equals(id)))
              .write(const FirearmsCompanion(archived: Value(true)));
          return LibraryRemovalResult.archived;
        }
        await (database.delete(
          database.firearms,
        )..where((row) => row.id.equals(id))).go();
        return LibraryRemovalResult.deleted;
      });

  Future<void> restoreFirearm(String id) =>
      (database.update(database.firearms)..where((row) => row.id.equals(id)))
          .write(const FirearmsCompanion(archived: Value(false)));

  Future<String> duplicateCartridge(String sourceId) async {
    final source = await _cartridge(sourceId);
    if (source == null) throw StateError('Het kaliber bestaat niet.');
    return addCustomCartridge(
      name: '${source.name} (kopie)',
      projectileDiameterMm: source.projectileDiameterMm,
      notes: source.notes,
    );
  }

  Future<void> updateCustomCartridge({
    required String id,
    required String name,
    required double projectileDiameterMm,
    String? notes,
  }) async {
    final source = await _cartridge(id);
    if (source == null) throw StateError('Het kaliber bestaat niet.');
    if (source.builtIn) {
      throw StateError('Een ingebouwd kaliber is alleen-lezen.');
    }
    if (name.trim().isEmpty || projectileDiameterMm <= 0) {
      throw ArgumentError('Naam en projectieldiameter zijn verplicht.');
    }
    await (database.update(
      database.cartridges,
    )..where((row) => row.id.equals(id))).write(
      CartridgesCompanion(
        name: Value(name.trim()),
        projectileDiameterMm: Value(projectileDiameterMm),
        notes: Value(_nullIfBlank(notes)),
      ),
    );
  }

  Future<LibraryRemovalResult> removeCartridge(
    String id, {
    bool archiveDependents = false,
  }) => database.transaction(() async {
    final record = await _cartridge(id);
    if (record == null) return LibraryRemovalResult.deleted;
    if (record.builtIn) return LibraryRemovalResult.blockedBuiltIn;
    final usage = await getLibraryUsage(LibraryItemKind.cartridge, id);
    if (usage.dependentAmmoLotCount > 0 && !archiveDependents) {
      return LibraryRemovalResult.blockedDependency;
    }
    if (usage.isInUse) {
      await (database.update(database.cartridges)
            ..where((row) => row.id.equals(id)))
          .write(const CartridgesCompanion(archived: Value(true)));
      if (archiveDependents) {
        await (database.update(database.ammoLots)
              ..where((row) => row.cartridgeId.equals(id)))
            .write(const AmmoLotsCompanion(archived: Value(true)));
      }
      await (database.update(database.firearms)
            ..where((row) => row.defaultCartridgeId.equals(id)))
          .write(const FirearmsCompanion(defaultCartridgeId: Value(null)));
      return LibraryRemovalResult.archived;
    }
    await (database.delete(
      database.cartridges,
    )..where((row) => row.id.equals(id))).go();
    return LibraryRemovalResult.deleted;
  });

  Future<void> restoreCartridge(String id) async {
    final record = await _cartridge(id);
    if (record == null) throw StateError('Het kaliber bestaat niet.');
    await (database.update(database.cartridges)
          ..where((row) => row.id.equals(id)))
        .write(const CartridgesCompanion(archived: Value(false)));
  }

  Future<void> updateAmmoLot({
    required String id,
    required String cartridgeId,
    required String displayName,
    String? manufacturer,
    String? productName,
    String? lotNumber,
    double? bulletWeightGrains,
    String? projectileType,
    String? notes,
  }) async {
    if (displayName.trim().isEmpty) {
      throw ArgumentError('Een weergavenaam is verplicht.');
    }
    await (database.update(
      database.ammoLots,
    )..where((row) => row.id.equals(id))).write(
      AmmoLotsCompanion(
        cartridgeId: Value(cartridgeId),
        displayName: Value(displayName.trim()),
        manufacturer: Value(_nullIfBlank(manufacturer)),
        productName: Value(_nullIfBlank(productName)),
        lotNumber: Value(_nullIfBlank(lotNumber)),
        bulletWeightGrains: Value(bulletWeightGrains),
        projectileType: Value(_nullIfBlank(projectileType)),
        notes: Value(_nullIfBlank(notes)),
      ),
    );
  }

  Future<LibraryRemovalResult> removeAmmoLot(String id) =>
      database.transaction(() async {
        final record = await _ammoLot(id);
        if (record == null) return LibraryRemovalResult.deleted;
        final usage = await getLibraryUsage(LibraryItemKind.ammoLot, id);
        if (usage.isInUse) {
          await (database.update(database.ammoLots)
                ..where((row) => row.id.equals(id)))
              .write(const AmmoLotsCompanion(archived: Value(true)));
          return LibraryRemovalResult.archived;
        }
        await (database.delete(
          database.ammoLots,
        )..where((row) => row.id.equals(id))).go();
        return LibraryRemovalResult.deleted;
      });

  Future<void> restoreAmmoLot(String id) => database.transaction(() async {
    final record = await _ammoLot(id);
    if (record == null) throw StateError('Het munitieprofiel bestaat niet.');
    final cartridge = await _cartridge(record.cartridgeId);
    if (cartridge == null || cartridge.archived) {
      throw StateError('Herstel eerst het gekoppelde kaliber.');
    }
    await (database.update(database.ammoLots)
          ..where((row) => row.id.equals(id)))
        .write(const AmmoLotsCompanion(archived: Value(false)));
  });

  Future<void> updateRange({
    required String id,
    required String name,
    required bool isIndoor,
    String? locationDescription,
    List<double> availableDistances = const [],
    String? notes,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Een naam is verplicht.');
    await (database.update(
      database.ranges,
    )..where((row) => row.id.equals(id))).write(
      RangesCompanion(
        name: Value(name.trim()),
        isIndoor: Value(isIndoor),
        locationDescription: Value(_nullIfBlank(locationDescription)),
        availableDistancesJson: Value(jsonEncode(availableDistances)),
        notes: Value(_nullIfBlank(notes)),
      ),
    );
  }

  Future<LibraryRemovalResult> removeRange(String id) =>
      database.transaction(() async {
        final record = await _range(id);
        if (record == null) return LibraryRemovalResult.deleted;
        final usage = await getLibraryUsage(LibraryItemKind.range, id);
        if (usage.isInUse) {
          await (database.update(database.ranges)
                ..where((row) => row.id.equals(id)))
              .write(const RangesCompanion(archived: Value(true)));
          return LibraryRemovalResult.archived;
        }
        await (database.delete(
          database.ranges,
        )..where((row) => row.id.equals(id))).go();
        return LibraryRemovalResult.deleted;
      });

  Future<void> restoreRange(String id) =>
      (database.update(database.ranges)..where((row) => row.id.equals(id)))
          .write(const RangesCompanion(archived: Value(false)));

  Future<String> duplicateTargetProfile(String sourceVersionedId) async {
    final source = await _targetProfile(sourceVersionedId);
    if (source == null) throw StateError('De doelkaart bestaat niet.');
    final profile = domain.TargetProfile.fromJsonString(source.profileJson);
    final duplicate = _copyTargetProfile(
      profile,
      profileId: _uuid.v7(),
      profileVersion: 1,
      displayName: '${profile.displayName} (kopie)',
    );
    await addCustomTargetProfile(duplicate);
    return duplicate.versionedId;
  }

  Future<String> saveCustomTargetEdit(
    String sourceVersionedId,
    domain.TargetProfile edited,
  ) => database.transaction(() async {
    final source = await _targetProfile(sourceVersionedId);
    if (source == null) throw StateError('De doelkaart bestaat niet.');
    if (source.builtIn) {
      throw StateError('Een ingebouwde doelkaart is alleen-lezen.');
    }
    final usage = await getLibraryUsage(
      LibraryItemKind.targetProfile,
      sourceVersionedId,
    );
    if (!usage.isInUse) {
      final preserved = _copyTargetProfile(
        edited,
        profileId: source.profileId,
        profileVersion: source.profileVersion,
      );
      await (database.update(
        database.targetProfiles,
      )..where((row) => row.versionedId.equals(sourceVersionedId))).write(
        TargetProfilesCompanion(
          displayName: Value(preserved.displayName),
          validationStatus: Value(preserved.validationStatus.name),
          profileJson: Value(preserved.toJsonString()),
        ),
      );
      return sourceVersionedId;
    }
    final maxVersion = await database
        .customSelect(
          'SELECT MAX(profile_version) AS version FROM target_profiles WHERE profile_id = ?',
          variables: [Variable<String>(source.profileId)],
        )
        .getSingle();
    final nextVersion =
        ((maxVersion.data['version'] as num?)?.toInt() ?? 0) + 1;
    final versioned = _copyTargetProfile(
      edited,
      profileId: source.profileId,
      profileVersion: nextVersion,
    );
    await (database.update(database.targetProfiles)
          ..where((row) => row.versionedId.equals(sourceVersionedId)))
        .write(const TargetProfilesCompanion(archived: Value(true)));
    await addCustomTargetProfile(versioned);
    return versioned.versionedId;
  });

  Future<LibraryRemovalResult> removeTargetProfile(String versionedId) =>
      database.transaction(() async {
        final record = await _targetProfile(versionedId);
        if (record == null) return LibraryRemovalResult.deleted;
        if (record.builtIn) return LibraryRemovalResult.blockedBuiltIn;
        final usage = await getLibraryUsage(
          LibraryItemKind.targetProfile,
          versionedId,
        );
        if (usage.isInUse) {
          await (database.update(database.targetProfiles)
                ..where((row) => row.versionedId.equals(versionedId)))
              .write(const TargetProfilesCompanion(archived: Value(true)));
          return LibraryRemovalResult.archived;
        }
        await (database.delete(
          database.targetProfiles,
        )..where((row) => row.versionedId.equals(versionedId))).go();
        return LibraryRemovalResult.deleted;
      });

  Future<void> restoreTargetProfile(String versionedId) =>
      (database.update(database.targetProfiles)
            ..where((row) => row.versionedId.equals(versionedId)))
          .write(const TargetProfilesCompanion(archived: Value(false)));

  Future<QuickSessionResult> startQuickSession({SeriesDefaults? defaults}) =>
      database.transaction(() async {
        final active = await _activeSession();
        if (active != null) throw ActiveSessionExistsException(active.id);

        final now = DateTime.now();
        final sessionId = _uuid.v7();
        await database
            .into(database.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: sessionId,
                status: domain.SessionStatus.active.name,
                startedAtUtc: now.toUtc(),
                localUtcOffsetMinutes: now.timeZoneOffset.inMinutes,
                updatedAtUtc: now.toUtc(),
              ),
            );
        final resolved = defaults ?? await _lastUsedDefaults();
        final seriesId = await _insertDraftSeries(
          sessionId: sessionId,
          sequenceNumber: 1,
          defaults: resolved,
        );
        return QuickSessionResult(
          sessionId: sessionId,
          draftSeriesId: seriesId,
        );
      });

  Future<String> createOrResumeDraftSeries(
    String sessionId, {
    SeriesDefaults? defaults,
  }) => database.transaction(() async {
    final session = await _session(sessionId);
    if (session == null) {
      throw StateError('De sessie bestaat niet.');
    }
    if (session.status != domain.SessionStatus.active.name) {
      throw StateError(
        'Alleen een actieve sessie kan een conceptreeks hebben.',
      );
    }
    final existing =
        await (database.select(database.shootingSeries)
              ..where(
                (row) =>
                    row.sessionId.equals(sessionId) &
                    row.status.equals(domain.SeriesStatus.draft.name),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final sessionSeries =
        await (database.select(database.shootingSeries)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.desc(row.sequenceNumber)]))
            .get();
    final resolved =
        defaults ??
        (sessionSeries.isEmpty
            ? await _lastUsedDefaults()
            : SeriesDefaults.fromRecord(sessionSeries.first));
    final nextSequence = sessionSeries.isEmpty
        ? 1
        : sessionSeries.first.sequenceNumber + 1;
    return _insertDraftSeries(
      sessionId: sessionId,
      sequenceNumber: nextSequence,
      defaults: resolved,
    );
  });

  Future<void> saveSeriesDraft({
    required String seriesId,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    String? cartridgeId,
    String? firearmId,
    String? ammoLotId,
    String? notes,
  }) => _replaceSeries(
    seriesId: seriesId,
    expectedStatus: domain.SeriesStatus.draft,
    target: target,
    distanceMeters: distanceMeters,
    projectileDiameterMm: projectileDiameterMm,
    impacts: impacts,
    cartridgeId: cartridgeId,
    firearmId: firearmId,
    ammoLotId: ammoLotId,
    notes: notes,
  );

  Future<void> replaceConfirmedSeries({
    required String seriesId,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    String? cartridgeId,
    String? firearmId,
    String? ammoLotId,
    String? notes,
  }) => _replaceSeries(
    seriesId: seriesId,
    expectedStatus: domain.SeriesStatus.confirmed,
    target: target,
    distanceMeters: distanceMeters,
    projectileDiameterMm: projectileDiameterMm,
    impacts: impacts,
    cartridgeId: cartridgeId,
    firearmId: firearmId,
    ammoLotId: ammoLotId,
    notes: notes,
  );

  Future<SessionCompletionResult> saveConfirmAndCompleteSeries({
    required String seriesId,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    String? cartridgeId,
    String? firearmId,
    String? ammoLotId,
    String? notes,
  }) => database.transaction(() async {
    final series = await _series(seriesId);
    if (series == null) throw StateError('De reeks bestaat niet.');
    if (series.status != domain.SeriesStatus.draft.name) {
      throw StateError('Alleen een conceptreeks kan worden afgerond.');
    }
    if (impacts.isEmpty) {
      throw StateError('Voeg minstens één treffer of misser toe.');
    }
    await _replaceSeries(
      seriesId: seriesId,
      expectedStatus: domain.SeriesStatus.draft,
      target: target,
      distanceMeters: distanceMeters,
      projectileDiameterMm: projectileDiameterMm,
      impacts: impacts,
      cartridgeId: cartridgeId,
      firearmId: firearmId,
      ammoLotId: ammoLotId,
      notes: notes,
    );
    return completeSession(
      series.sessionId,
      draftStrategy: DraftCompletionStrategy.confirm,
    );
  });

  Future<void> confirmSeries(String seriesId) => database.transaction(() async {
    final series = await _series(seriesId);
    if (series == null) throw StateError('De reeks bestaat niet.');
    if (series.status != domain.SeriesStatus.draft.name) {
      throw StateError('Alleen een conceptreeks kan worden bevestigd.');
    }
    if (series.shotCount <= 0) {
      throw StateError('Voeg minstens één treffer of misser toe.');
    }
    final now = DateTime.now().toUtc();
    await (database.update(
      database.shootingSeries,
    )..where((row) => row.id.equals(seriesId))).write(
      ShootingSeriesCompanion(
        status: Value(domain.SeriesStatus.confirmed.name),
        updatedAtUtc: Value(now),
        confirmedAtUtc: Value(now),
      ),
    );
    await _touchSession(series.sessionId, now);
  });

  Future<void> updateSessionDetails({
    required String sessionId,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
    required String? rangeId,
    required String? trainingGoal,
    required String? conditions,
    required String? notes,
  }) async {
    final changed =
        await (database.update(
          database.trainingSessions,
        )..where((row) => row.id.equals(sessionId))).write(
          TrainingSessionsCompanion(
            startedAtUtc: Value(startedAtUtc.toUtc()),
            localUtcOffsetMinutes: Value(localUtcOffsetMinutes),
            updatedAtUtc: Value(DateTime.now().toUtc()),
            rangeId: Value(rangeId),
            trainingGoal: Value(_nullIfBlank(trainingGoal)),
            conditions: Value(_nullIfBlank(conditions)),
            notes: Value(_nullIfBlank(notes)),
          ),
        );
    if (changed != 1) throw StateError('De sessie bestaat niet.');
  }

  Future<void> acknowledgePhotoSafety(String sessionId) async {
    final now = DateTime.now().toUtc();
    final changed =
        await (database.update(
          database.trainingSessions,
        )..where((row) => row.id.equals(sessionId))).write(
          TrainingSessionsCompanion(
            photoSafetyAcknowledgedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
    if (changed != 1) throw StateError('De sessie bestaat niet.');
  }

  Future<SessionCompletionResult> completeSession(
    String sessionId, {
    DraftCompletionStrategy draftStrategy =
        DraftCompletionStrategy.requireResolved,
  }) async {
    final filesToDelete = <String>{};
    final result = await database.transaction(() async {
      final session = await _session(sessionId);
      if (session == null) {
        return const SessionCompletionResult(SessionCompletionOutcome.notFound);
      }
      if (session.status == domain.SessionStatus.completed.name) {
        return const SessionCompletionResult(
          SessionCompletionOutcome.alreadyCompleted,
        );
      }

      final series =
          await (database.select(database.shootingSeries)
                ..where((row) => row.sessionId.equals(sessionId))
                ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
              .get();
      final draft = series
          .where((item) => item.status == domain.SeriesStatus.draft.name)
          .firstOrNull;
      final draftImages = draft == null
          ? const <ImageAssetRecord>[]
          : await (database.select(
              database.imageAssets,
            )..where((row) => row.seriesId.equals(draft.id))).get();
      final hasMeaningfulDraft =
          draft != null &&
          (draft.shotCount > 0 ||
              draftImages.isNotEmpty ||
              (draft.notes?.trim().isNotEmpty ?? false) ||
              draft.updatedAtUtc.isAfter(draft.createdAtUtc));
      if (hasMeaningfulDraft &&
          draftStrategy == DraftCompletionStrategy.requireResolved) {
        throw UnresolvedDraftException(
          seriesId: draft.id,
          shotCount: draft.shotCount,
          photoCount: draftImages.length,
          hasNotes: draft.notes?.trim().isNotEmpty ?? false,
          wasEdited: draft.updatedAtUtc.isAfter(draft.createdAtUtc),
        );
      }

      final now = DateTime.now().toUtc();
      String? confirmedDraftId;
      var confirmedSeriesCount = series
          .where((item) => item.status == domain.SeriesStatus.confirmed.name)
          .length;
      if (draft != null &&
          hasMeaningfulDraft &&
          draftStrategy == DraftCompletionStrategy.confirm) {
        if (draft.shotCount <= 0) {
          throw StateError(
            'Een concept met alleen foto\'s kan niet als reeks worden bevestigd.',
          );
        }
        await (database.update(
          database.shootingSeries,
        )..where((row) => row.id.equals(draft.id))).write(
          ShootingSeriesCompanion(
            status: Value(domain.SeriesStatus.confirmed.name),
            confirmedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
        confirmedDraftId = draft.id;
        confirmedSeriesCount++;
      } else if (draft != null) {
        for (final image in draftImages) {
          filesToDelete.add(image.path);
        }
        await (database.delete(
          database.shootingSeries,
        )..where((row) => row.id.equals(draft.id))).go();
      }

      final sessionOnlyImages =
          await (database.select(database.imageAssets)..where(
                (row) =>
                    row.sessionId.equals(sessionId) & row.seriesId.isNull(),
              ))
              .get();
      if (confirmedSeriesCount == 0 &&
          sessionOnlyImages.isEmpty &&
          !session.hasUserDetails) {
        final remainingImages = await (database.select(
          database.imageAssets,
        )..where((row) => row.sessionId.equals(sessionId))).get();
        for (final image in remainingImages) {
          filesToDelete.add(image.path);
        }
        await (database.delete(
          database.trainingSessions,
        )..where((row) => row.id.equals(sessionId))).go();
        return const SessionCompletionResult(
          SessionCompletionOutcome.deletedEmpty,
        );
      }

      await (database.update(
        database.trainingSessions,
      )..where((row) => row.id.equals(sessionId))).write(
        TrainingSessionsCompanion(
          status: Value(domain.SessionStatus.completed.name),
          endedAtUtc: Value(now),
          updatedAtUtc: Value(now),
        ),
      );
      await _renumberSeries(sessionId);
      return SessionCompletionResult(
        SessionCompletionOutcome.completed,
        confirmedDraftId: confirmedDraftId,
      );
    });

    for (final path in filesToDelete) {
      await _deleteFileIfPresent(path);
    }
    return result;
  }

  Future<SessionCompletionResult> confirmDraftAndCompleteSession(
    String sessionId,
  ) => completeSession(
    sessionId,
    draftStrategy: DraftCompletionStrategy.confirm,
  );

  Future<SessionCompletionResult> discardDraftAndCompleteSession(
    String sessionId,
  ) => completeSession(
    sessionId,
    draftStrategy: DraftCompletionStrategy.discard,
  );

  Future<void> reopenSession(String sessionId) =>
      database.transaction(() async {
        final active = await _activeSession();
        if (active != null && active.id != sessionId) {
          throw ActiveSessionExistsException(active.id);
        }
        final now = DateTime.now().toUtc();
        final changed =
            await (database.update(
              database.trainingSessions,
            )..where((row) => row.id.equals(sessionId))).write(
              TrainingSessionsCompanion(
                status: Value(domain.SessionStatus.active.name),
                endedAtUtc: const Value(null),
                updatedAtUtc: Value(now),
              ),
            );
        if (changed != 1) throw StateError('De sessie bestaat niet.');
      });

  Future<List<String>> attachImagesAtomically(Iterable<NewImageAsset> assets) =>
      database.transaction(() async {
        final ids = <String>[];
        for (final asset in assets) {
          ids.add(await _attachImage(asset));
        }
        return ids;
      });

  Future<String> attachImage(NewImageAsset asset) =>
      database.transaction(() => _attachImage(asset));

  Future<void> setPrimaryScoringImage(String imageId) =>
      database.transaction(() async {
        final image = await _image(imageId);
        if (image == null) throw StateError('De foto bestaat niet.');
        final seriesId = image.seriesId;
        if (seriesId == null) {
          throw StateError('Een sessiefoto kan geen primaire scorefoto zijn.');
        }
        final oldPrimary =
            await (database.select(database.imageAssets)
                  ..where(
                    (row) =>
                        row.seriesId.equals(seriesId) &
                        row.role.equals(
                          domain.ImageRole.primaryScoringPhoto.name,
                        ),
                  )
                  ..limit(1))
                .getSingleOrNull();
        final now = DateTime.now().toUtc();
        if (oldPrimary != null && oldPrimary.id != imageId) {
          await (database.update(
            database.imageAssets,
          )..where((row) => row.id.equals(oldPrimary.id))).write(
            ImageAssetsCompanion(
              role: Value(domain.ImageRole.attachment.name),
              updatedAtUtc: Value(now),
            ),
          );
          await (database.delete(
            database.photoAlignments,
          )..where((row) => row.imageId.equals(oldPrimary.id))).go();
        }
        await (database.update(
          database.imageAssets,
        )..where((row) => row.id.equals(imageId))).write(
          ImageAssetsCompanion(
            role: Value(domain.ImageRole.primaryScoringPhoto.name),
            updatedAtUtc: Value(now),
          ),
        );
        await _touchSession(image.sessionId, now);
      });

  Future<void> updateImageCaption(String imageId, String? caption) =>
      database.transaction(() async {
        final image = await _image(imageId);
        if (image == null) throw StateError('De foto bestaat niet.');
        final now = DateTime.now().toUtc();
        final changed =
            await (database.update(
              database.imageAssets,
            )..where((row) => row.id.equals(imageId))).write(
              ImageAssetsCompanion(
                caption: Value(_nullIfBlank(caption)),
                updatedAtUtc: Value(now),
              ),
            );
        if (changed != 1) throw StateError('De foto bestaat niet.');
        await _touchSession(image.sessionId, now);
      });

  Future<void> savePhotoAlignment(
    domain.StoredPhotoAlignment alignment,
  ) => database.transaction(() async {
    final image = await _image(alignment.imageId);
    if (image == null ||
        image.seriesId == null ||
        image.role != domain.ImageRole.primaryScoringPhoto.name) {
      throw StateError('Alleen een primaire scorefoto kan worden uitgelijnd.');
    }
    await database
        .into(database.photoAlignments)
        .insertOnConflictUpdate(
          PhotoAlignmentsCompanion.insert(
            imageId: alignment.imageId,
            cornersJson: jsonEncode(
              alignment.orderedCorners.map((point) => point.toJson()).toList(),
            ),
            matrixJson: jsonEncode(alignment.homographyMatrix),
            algorithmVersion: alignment.algorithmVersion,
            updatedAtUtc: alignment.updatedAtUtc.toUtc(),
          ),
        );
    await _touchSession(image.sessionId, alignment.updatedAtUtc.toUtc());
  });

  /// Stores a new alignment and the recalculated positions that depend on its
  /// primary image as one indivisible operation.
  ///
  /// [resultingImpacts] is the complete post-alignment impact collection. The
  /// method deliberately rejects additions, removals, or changes to impacts
  /// that do not originate from [alignment.imageId]. This keeps a photo
  /// realignment from accidentally rewriting manually placed impacts.
  Future<void> realignSeriesPhoto({
    required String seriesId,
    required domain.StoredPhotoAlignment alignment,
    required domain.TargetProfile target,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> resultingImpacts,
  }) => database.transaction(() async {
    final series = await _series(seriesId);
    if (series == null) throw StateError('De reeks bestaat niet.');
    if (projectileDiameterMm <= 0) {
      throw ArgumentError.value(
        projectileDiameterMm,
        'projectileDiameterMm',
        'Moet groter zijn dan nul',
      );
    }
    if (series.targetProfileVersionedId != target.versionedId ||
        series.targetProfileJson != target.toJsonString()) {
      throw StateError(
        'De kaart is gewijzigd. Lijn de primaire foto opnieuw uit voor de '
        'opgeslagen kaartversie.',
      );
    }

    final image = await _image(alignment.imageId);
    if (image == null || image.seriesId != seriesId) {
      throw StateError('De uitlijning hoort niet bij een foto van deze reeks.');
    }
    final isPrimary = image.role == domain.ImageRole.primaryScoringPhoto.name;
    final isAttachment = image.role == domain.ImageRole.attachment.name;
    if (!isPrimary && !isAttachment) {
      throw StateError('Deze foto kan niet als primaire scorefoto dienen.');
    }

    final existingRecords = await (database.select(
      database.shotImpacts,
    )..where((row) => row.seriesId.equals(seriesId))).get();
    final existingById = {
      for (final impact in existingRecords) impact.id: impact,
    };
    final resultingById = {
      for (final impact in resultingImpacts) impact.id: impact,
    };
    if (resultingById.length != resultingImpacts.length ||
        resultingById.length != existingById.length ||
        !resultingById.keys.toSet().containsAll(existingById.keys)) {
      throw StateError(
        'Heruitlijning mag geen treffers toevoegen of verwijderen.',
      );
    }

    for (final entry in existingById.entries) {
      final existing = entry.value;
      final resulting = resultingById[entry.key]!;
      final dependsOnPhoto =
          existing.sourceImageId == alignment.imageId &&
          existing.imageXNormalized != null &&
          existing.imageYNormalized != null;
      if (dependsOnPhoto) {
        if (!_sameImpactMetadata(existing, resulting) ||
            resulting.sourceImageId != alignment.imageId ||
            resulting.imageXNormalized == null ||
            resulting.imageYNormalized == null) {
          throw StateError(
            'Heruitlijning mag alleen de fysieke positie van '
            'foto-afhankelijke treffers wijzigen.',
          );
        }
      } else if (!_sameStoredImpact(existing, resulting)) {
        throw StateError(
          'Heruitlijning mag handmatige of andere fototreffers niet wijzigen.',
        );
      }
    }

    final score = ScoreEngine.score(
      target: target,
      impacts: resultingImpacts,
      projectileDiameterMm: projectileDiameterMm,
    );
    final updatedAtUtc = alignment.updatedAtUtc.toUtc();

    if (!isPrimary) {
      final oldPrimaries =
          await (database.select(database.imageAssets)..where(
                (row) =>
                    row.seriesId.equals(seriesId) &
                    row.role.equals(domain.ImageRole.primaryScoringPhoto.name),
              ))
              .get();
      for (final oldPrimary in oldPrimaries) {
        await (database.update(
          database.imageAssets,
        )..where((row) => row.id.equals(oldPrimary.id))).write(
          ImageAssetsCompanion(
            role: Value(domain.ImageRole.attachment.name),
            updatedAtUtc: Value(updatedAtUtc),
          ),
        );
        await (database.delete(
          database.photoAlignments,
        )..where((row) => row.imageId.equals(oldPrimary.id))).go();
      }
      final promoted =
          await (database.update(
            database.imageAssets,
          )..where((row) => row.id.equals(image.id))).write(
            ImageAssetsCompanion(
              role: Value(domain.ImageRole.primaryScoringPhoto.name),
              updatedAtUtc: Value(updatedAtUtc),
            ),
          );
      if (promoted != 1) {
        throw StateError('De scorefoto kon niet primair worden gemaakt.');
      }
    }

    await database
        .into(database.photoAlignments)
        .insertOnConflictUpdate(
          PhotoAlignmentsCompanion.insert(
            imageId: alignment.imageId,
            cornersJson: jsonEncode(
              alignment.orderedCorners.map((point) => point.toJson()).toList(),
            ),
            matrixJson: jsonEncode(alignment.homographyMatrix),
            algorithmVersion: alignment.algorithmVersion,
            updatedAtUtc: updatedAtUtc,
          ),
        );

    for (final shot in score.shots) {
      final existing = existingById[shot.impact.id]!;
      final dependsOnPhoto =
          existing.sourceImageId == alignment.imageId &&
          existing.imageXNormalized != null &&
          existing.imageYNormalized != null;
      final changed =
          await (database.update(database.shotImpacts)..where(
                (row) =>
                    row.id.equals(shot.impact.id) &
                    row.seriesId.equals(seriesId),
              ))
              .write(
                ShotImpactsCompanion(
                  xMm: dependsOnPhoto
                      ? Value(shot.impact.xMm)
                      : const Value.absent(),
                  yMm: dependsOnPhoto
                      ? Value(shot.impact.yMm)
                      : const Value.absent(),
                  scoreValue: Value(shot.value),
                  rawScoreValue: Value(shot.value),
                  targetBullId: Value(shot.targetBullId),
                  scoreDisposition: Value(shot.disposition.name),
                  isInnerTen: Value(shot.isInnerTen),
                  isBoundaryUncertain: Value(shot.isBoundaryUncertain),
                ),
              );
      if (changed != 1) {
        throw StateError('Een treffer is tijdens het uitlijnen gewijzigd.');
      }
    }

    final updated =
        await (database.update(
          database.shootingSeries,
        )..where((row) => row.id.equals(seriesId))).write(
          ShootingSeriesCompanion(
            projectileDiameterMm: Value(projectileDiameterMm),
            shotCount: Value(score.actualShotCount),
            maximumPossibleScore: Value(score.maximumPossible),
            totalScore: Value(score.total),
            innerTenCount: Value(score.innerTenCount),
            missCount: Value(score.missCount),
            scorePenalty: Value(score.penalty),
            scoredBullCount: Value(score.scoredBullCount),
            hasBoundaryWarnings: Value(score.hasBoundaryWarnings),
            updatedAtUtc: Value(updatedAtUtc),
          ),
        );
    if (updated != 1) {
      throw StateError('De reeks is tijdens het uitlijnen gewijzigd.');
    }
    await _touchSession(series.sessionId, updatedAtUtc);
  });

  Future<void> deleteImage(String imageId) async {
    final image = await _image(imageId);
    if (image == null) return;
    await database.transaction(() async {
      await (database.delete(
        database.imageAssets,
      )..where((row) => row.id.equals(imageId))).go();
      await _touchSession(image.sessionId, DateTime.now().toUtc());
    });
    await _deleteFileIfPresent(image.path);
  }

  Future<SessionDetail?> getSessionDetail(String sessionId) async {
    final session = await _session(sessionId);
    if (session == null) return null;
    final series =
        await (database.select(database.shootingSeries)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    final images =
        await (database.select(database.imageAssets)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.desc(row.createdAtUtc)]))
            .get();
    final overviewItems = await Future.wait(series.map(_seriesOverviewItem));
    final confirmedItems = overviewItems
        .where(
          (item) => item.series.status == domain.SeriesStatus.confirmed.name,
        )
        .toList(growable: false);
    final draftItem = overviewItems
        .where((item) => item.series.status == domain.SeriesStatus.draft.name)
        .firstOrNull;
    return SessionDetail(
      session: session,
      confirmedSeries: confirmedItems
          .map((item) => item.series)
          .toList(growable: false),
      draftSeries: draftItem?.series,
      confirmedSeriesItems: confirmedItems,
      draftSeriesItem: draftItem,
      images: images,
    );
  }

  Future<SeriesDetail?> getSeriesDetail(String seriesId) async {
    final series = await _series(seriesId);
    if (series == null) return null;
    final impacts = await (database.select(
      database.shotImpacts,
    )..where((row) => row.seriesId.equals(seriesId))).get();
    final images =
        await (database.select(database.imageAssets)
              ..where((row) => row.seriesId.equals(seriesId))
              ..orderBy([(row) => OrderingTerm.desc(row.createdAtUtc)]))
            .get();
    final primary = images
        .where(
          (image) => image.role == domain.ImageRole.primaryScoringPhoto.name,
        )
        .firstOrNull;
    final alignment = primary == null
        ? null
        : await (database.select(
            database.photoAlignments,
          )..where((row) => row.imageId.equals(primary.id))).getSingleOrNull();
    final overview = await _seriesOverviewItem(series);
    return SeriesDetail(
      series: series,
      impacts: impacts,
      images: images,
      primaryImage: primary,
      photoAlignment: alignment,
      firearm: overview.firearm,
      ammoLot: overview.ammoLot,
      cartridge: overview.cartridge,
    );
  }

  Future<SeriesOverviewItem> _seriesOverviewItem(SeriesRecord series) async {
    final firearmId = series.firearmId;
    final ammoLotId = series.ammoLotId;
    final cartridgeId = series.cartridgeId;
    return SeriesOverviewItem(
      series: series,
      firearm: firearmId == null ? null : await _firearm(firearmId),
      ammoLot: ammoLotId == null ? null : await _ammoLot(ammoLotId),
      cartridge: cartridgeId == null ? null : await _cartridge(cartridgeId),
    );
  }

  Future<List<SeriesRecord>> getConfirmedSeries() =>
      (database.select(database.shootingSeries)
            ..where(
              (row) => row.status.equals(domain.SeriesStatus.confirmed.name),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAtUtc)]))
          .get();

  Future<List<ImpactRecord>> getAllImpacts() =>
      database.select(database.shotImpacts).get();

  String targetNameFor(SeriesRecord series) =>
      domain.TargetProfile.fromJsonString(series.targetProfileJson).displayName;

  Future<void> deleteSeries(String seriesId) async {
    final series = await _series(seriesId);
    if (series == null) return;
    final images = await (database.select(
      database.imageAssets,
    )..where((row) => row.seriesId.equals(seriesId))).get();
    await database.transaction(() async {
      await (database.delete(
        database.shootingSeries,
      )..where((row) => row.id.equals(seriesId))).go();
      await _renumberSeries(series.sessionId);
      await _touchSession(series.sessionId, DateTime.now().toUtc());
    });
    for (final image in images) {
      await _deleteFileIfPresent(image.path);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final images = await (database.select(
      database.imageAssets,
    )..where((row) => row.sessionId.equals(sessionId))).get();
    await (database.delete(
      database.trainingSessions,
    )..where((row) => row.id.equals(sessionId))).go();
    for (final image in images) {
      await _deleteFileIfPresent(image.path);
    }
  }

  Future<String> _insertDraftSeries({
    required String sessionId,
    required int sequenceNumber,
    required SeriesDefaults defaults,
  }) async {
    if (defaults.distanceMeters <= 0 || defaults.projectileDiameterMm <= 0) {
      throw ArgumentError(
        'Afstand en projectieldiameter moeten positief zijn.',
      );
    }
    final id = _uuid.v7();
    final now = DateTime.now().toUtc();
    await database
        .into(database.shootingSeries)
        .insert(
          ShootingSeriesCompanion.insert(
            id: id,
            sessionId: sessionId,
            sequenceNumber: sequenceNumber,
            status: domain.SeriesStatus.draft.name,
            targetProfileVersionedId: defaults.target.versionedId,
            targetProfileJson: defaults.target.toJsonString(),
            distanceMeters: defaults.distanceMeters,
            projectileDiameterMm: defaults.projectileDiameterMm,
            cartridgeId: Value(defaults.cartridgeId),
            firearmId: Value(defaults.firearmId),
            ammoLotId: Value(defaults.ammoLotId),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    return id;
  }

  Future<void> _replaceSeries({
    required String seriesId,
    required domain.SeriesStatus expectedStatus,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    required String? cartridgeId,
    required String? firearmId,
    required String? ammoLotId,
    required String? notes,
  }) => database.transaction(() async {
    final existing = await _series(seriesId);
    if (existing == null) throw StateError('De reeks bestaat niet.');
    if (existing.status != expectedStatus.name) {
      throw StateError('De reeksstatus is intussen gewijzigd.');
    }
    if (distanceMeters <= 0 || projectileDiameterMm <= 0) {
      throw ArgumentError(
        'Afstand en projectieldiameter moeten positief zijn.',
      );
    }
    final targetChanged =
        existing.targetProfileVersionedId != target.versionedId;
    final normalizedImpacts = targetChanged
        ? impacts
              .map(
                (impact) => impact.copyWith(
                  clearSourceImage: true,
                  clearImageCoordinates: true,
                  clearTargetBull: true,
                ),
              )
              .toList(growable: false)
        : impacts;
    final score = ScoreEngine.score(
      target: target,
      impacts: normalizedImpacts,
      projectileDiameterMm: projectileDiameterMm,
    );
    // Drift stores SQLite DateTimes with second precision. Round a persisted
    // edit up so it cannot collapse onto the draft creation time; completion
    // uses that distinction to protect settings-only concepts.
    final now = _nextSqliteSecond(DateTime.now().toUtc());

    await (database.update(
      database.shootingSeries,
    )..where((row) => row.id.equals(seriesId))).write(
      ShootingSeriesCompanion(
        targetProfileVersionedId: Value(target.versionedId),
        targetProfileJson: Value(target.toJsonString()),
        distanceMeters: Value(distanceMeters),
        projectileDiameterMm: Value(projectileDiameterMm),
        cartridgeId: Value(cartridgeId),
        firearmId: Value(firearmId),
        ammoLotId: Value(ammoLotId),
        notes: Value(_nullIfBlank(notes)),
        shotCount: Value(score.actualShotCount),
        maximumPossibleScore: Value(score.maximumPossible),
        totalScore: Value(score.total),
        innerTenCount: Value(score.innerTenCount),
        missCount: Value(score.missCount),
        scorePenalty: Value(score.penalty),
        scoredBullCount: Value(score.scoredBullCount),
        hasBoundaryWarnings: Value(score.hasBoundaryWarnings),
        updatedAtUtc: Value(now),
      ),
    );
    await (database.delete(
      database.shotImpacts,
    )..where((row) => row.seriesId.equals(seriesId))).go();
    for (final shot in score.shots) {
      await database
          .into(database.shotImpacts)
          .insert(
            ShotImpactsCompanion.insert(
              id: shot.impact.id,
              seriesId: seriesId,
              xMm: shot.impact.xMm,
              yMm: shot.impact.yMm,
              sourceImageId: Value(shot.impact.sourceImageId),
              imageXNormalized: Value(shot.impact.imageXNormalized),
              imageYNormalized: Value(shot.impact.imageYNormalized),
              multiplicity: Value(shot.impact.multiplicity),
              isMiss: Value(shot.impact.isMiss),
              isPositionUncertain: Value(shot.impact.isPositionUncertain),
              targetBullId: Value(shot.targetBullId),
              scoreValue: shot.value,
              rawScoreValue: Value(shot.value),
              scoreDisposition: Value(shot.disposition.name),
              isInnerTen: Value(shot.isInnerTen),
              isBoundaryUncertain: Value(shot.isBoundaryUncertain),
            ),
          );
    }
    if (targetChanged) {
      final images = await (database.select(
        database.imageAssets,
      )..where((row) => row.seriesId.equals(seriesId))).get();
      for (final image in images) {
        await (database.delete(
          database.photoAlignments,
        )..where((row) => row.imageId.equals(image.id))).go();
      }
    }
    await _touchSession(existing.sessionId, now);
  });

  Future<String> _attachImage(NewImageAsset asset) async {
    final session = await _session(asset.sessionId);
    if (session == null) throw StateError('De sessie bestaat niet.');
    if (asset.width <= 0 || asset.height <= 0 || asset.sizeBytes <= 0) {
      throw ArgumentError('Ongeldige foto-eigenschappen.');
    }
    final seriesId = asset.seriesId;
    if (seriesId != null) {
      final series = await _series(seriesId);
      if (series == null || series.sessionId != asset.sessionId) {
        throw StateError('De reeks hoort niet bij deze sessie.');
      }
    } else if (asset.role == domain.ImageRole.primaryScoringPhoto) {
      throw StateError('Een sessiefoto kan geen primaire scorefoto zijn.');
    }

    final now = DateTime.now().toUtc();
    if (asset.role == domain.ImageRole.primaryScoringPhoto) {
      final existing =
          await (database.select(database.imageAssets)
                ..where(
                  (row) =>
                      row.seriesId.equals(seriesId!) &
                      row.role.equals(
                        domain.ImageRole.primaryScoringPhoto.name,
                      ),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) {
        await (database.update(
          database.imageAssets,
        )..where((row) => row.id.equals(existing.id))).write(
          ImageAssetsCompanion(
            role: Value(domain.ImageRole.attachment.name),
            updatedAtUtc: Value(now),
          ),
        );
        await (database.delete(
          database.photoAlignments,
        )..where((row) => row.imageId.equals(existing.id))).go();
      }
    }

    final id = asset.id ?? _uuid.v7();
    await database
        .into(database.imageAssets)
        .insert(
          ImageAssetsCompanion.insert(
            id: id,
            sessionId: asset.sessionId,
            seriesId: Value(seriesId),
            role: asset.role.name,
            path: asset.path,
            sha256: asset.sha256,
            width: asset.width,
            height: asset.height,
            sizeBytes: asset.sizeBytes,
            caption: Value(_nullIfBlank(asset.caption)),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    await _touchSession(asset.sessionId, now);
    return id;
  }

  Future<TrainingActivityRecord?> _trainingActivity(String id) =>
      (database.select(database.trainingActivities)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<void> _replaceTimerEvents(
    String activityId,
    List<NewShotTimerEvent> events,
  ) async {
    await _requireTimerActivity(activityId);
    var previousElapsed = 0;
    var previousCountedElapsed = 0;
    final eventIds = <String>{};
    final companions = <ShotTimerEventsCompanion>[];
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      final peak = event.normalizedPeak;
      if (event.elapsedMicroseconds < 0 ||
          (index > 0 && event.elapsedMicroseconds <= previousElapsed) ||
          event.splitMicroseconds < 0 ||
          event.splitMicroseconds > event.elapsedMicroseconds ||
          peak != null && (!peak.isFinite || peak < 0 || peak > 1)) {
        throw ArgumentError('Schottijden moeten geldig en oplopend zijn.');
      }
      if (event.disposition == StoredTimerEventDisposition.counted) {
        final expectedSplit =
            event.elapsedMicroseconds - previousCountedElapsed;
        if (event.splitMicroseconds != expectedSplit) {
          throw ArgumentError(
            'Splits moeten ten opzichte van het vorige getelde event zijn.',
          );
        }
        previousCountedElapsed = event.elapsedMicroseconds;
      }
      final eventId = event.id ?? _uuid.v7();
      if (!eventIds.add(eventId)) {
        throw ArgumentError('Een timerevent-ID komt meer dan één keer voor.');
      }
      final exclusionReason = _nullIfBlank(event.exclusionReason);
      if (event.disposition == StoredTimerEventDisposition.excluded &&
          exclusionReason == null) {
        throw ArgumentError('Een uitgesloten detectie vereist een reden.');
      }
      companions.add(
        ShotTimerEventsCompanion.insert(
          id: eventId,
          activityId: activityId,
          sequenceNumber: index + 1,
          elapsedMicroseconds: event.elapsedMicroseconds,
          splitMicroseconds: event.splitMicroseconds,
          source: event.source.name,
          disposition: event.disposition.name,
          normalizedPeak: Value(peak),
          detectionQuality: Value(_nullIfBlank(event.detectionQuality)),
          exclusionReason: Value(
            event.disposition == StoredTimerEventDisposition.excluded
                ? exclusionReason
                : null,
          ),
        ),
      );
      previousElapsed = event.elapsedMicroseconds;
    }
    await (database.delete(
      database.shotTimerEvents,
    )..where((row) => row.activityId.equals(activityId))).go();
    if (companions.isNotEmpty) {
      await database.batch(
        (batch) => batch.insertAll(database.shotTimerEvents, companions),
      );
    }
  }

  Future<void> _setTimerEventDisposition(
    String eventId,
    StoredTimerEventDisposition disposition, {
    String? reason,
  }) async {
    final normalizedReason = _nullIfBlank(reason);
    if (disposition == StoredTimerEventDisposition.excluded &&
        normalizedReason == null) {
      throw ArgumentError('Een uitgesloten detectie vereist een reden.');
    }
    await database.transaction(() async {
      final event = await (database.select(
        database.shotTimerEvents,
      )..where((row) => row.id.equals(eventId))).getSingleOrNull();
      if (event == null) return;
      final activity = await _requireTimerActivity(event.activityId);
      await (database.update(
        database.shotTimerEvents,
      )..where((row) => row.id.equals(eventId))).write(
        ShotTimerEventsCompanion(
          disposition: Value(disposition.name),
          exclusionReason: Value(
            disposition == StoredTimerEventDisposition.excluded
                ? normalizedReason
                : null,
          ),
        ),
      );
      await _normalizeStoredCountedSplits(event.activityId);
      final now = DateTime.now().toUtc();
      final summaryJson = await _recomputeTimerSummaryJson(
        event.activityId,
        baseSummaryJson: activity.summaryJson,
        markUserEdited: true,
      );
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(event.activityId))).write(
        TrainingActivitiesCompanion(
          summaryJson: Value(summaryJson),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  Future<void> _normalizeStoredCountedSplits(String activityId) async {
    final events =
        await (database.select(database.shotTimerEvents)
              ..where((row) => row.activityId.equals(activityId))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    var previousElapsed = 0;
    var previousCountedElapsed = 0;
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      if (event.sequenceNumber != index + 1 ||
          event.elapsedMicroseconds < 0 ||
          index > 0 && event.elapsedMicroseconds <= previousElapsed) {
        throw StateError(
          'Timerevents zijn niet geldig chronologisch opgeslagen.',
        );
      }
      final disposition = StoredTimerEventDisposition.values
          .where((value) => value.name == event.disposition)
          .firstOrNull;
      if (disposition == null ||
          event.splitMicroseconds < 0 ||
          event.splitMicroseconds > event.elapsedMicroseconds ||
          disposition == StoredTimerEventDisposition.excluded &&
              _nullIfBlank(event.exclusionReason) == null) {
        throw StateError('Timerevent bevat ongeldige opgeslagen gegevens.');
      }
      if (disposition == StoredTimerEventDisposition.counted) {
        final normalizedSplit =
            event.elapsedMicroseconds - previousCountedElapsed;
        if (event.splitMicroseconds != normalizedSplit) {
          await (database.update(
            database.shotTimerEvents,
          )..where((row) => row.id.equals(event.id))).write(
            ShotTimerEventsCompanion(splitMicroseconds: Value(normalizedSplit)),
          );
        }
        previousCountedElapsed = event.elapsedMicroseconds;
      }
      previousElapsed = event.elapsedMicroseconds;
    }
  }

  Future<TrainingActivityRecord> _requireTimerActivity(
    String activityId,
  ) async {
    final activity = await _trainingActivity(activityId);
    if (activity == null) {
      throw ArgumentError('De trainingsactiviteit bestaat niet meer.');
    }
    if (!_timerActivityKinds.contains(activity.kind)) {
      throw StateError('Alleen timeractiviteiten mogen timerevents bevatten.');
    }
    return activity;
  }

  Future<String> _recomputeTimerSummaryJson(
    String activityId, {
    required String baseSummaryJson,
    required bool markUserEdited,
  }) async {
    final activity = await _requireTimerActivity(activityId);
    final decoded = jsonDecode(baseSummaryJson);
    if (decoded is! Map) {
      throw StateError('De timersamenvatting is ongeldig.');
    }
    final summary = decoded.cast<String, Object?>();
    final allEvents =
        await (database.select(database.shotTimerEvents)
              ..where((row) => row.activityId.equals(activityId))
              ..orderBy([
                (row) => OrderingTerm.asc(row.elapsedMicroseconds),
                (row) => OrderingTerm.asc(row.sequenceNumber),
              ]))
            .get();
    final counted = allEvents
        .where(
          (event) =>
              event.disposition == StoredTimerEventDisposition.counted.name,
        )
        .toList(growable: false);

    final splits = <int>[];
    for (var index = 1; index < counted.length; index++) {
      splits.add(
        counted[index].elapsedMicroseconds -
            counted[index - 1].elapsedMicroseconds,
      );
    }
    final averageSplit = splits.isEmpty
        ? null
        : splits.fold<int>(0, (sum, value) => sum + value) ~/ splits.length;
    int? splitStandardDeviation;
    if (splits.length >= 2) {
      final mean =
          splits.fold<double>(0, (sum, value) => sum + value) / splits.length;
      final variance =
          splits.fold<double>(0, (sum, value) {
            final delta = value - mean;
            return sum + delta * delta;
          }) /
          (splits.length - 1);
      splitStandardDeviation = math.sqrt(variance).round();
    }

    final preservesSignalDuration =
        allEvents.isEmpty &&
        (activity.kind == StoredTrainingActivityKind.par.name ||
            activity.kind == StoredTrainingActivityKind.cadence.name);
    final preservesExternalManualSummary =
        allEvents.isEmpty &&
        activity.kind == StoredTrainingActivityKind.externalManual.name &&
        summary['externalTimingCompleteness'] == 'summaryOnly';
    final previousTotalTime = summary['totalTimeMicros'];

    if (!preservesExternalManualSummary) {
      summary
        ..['countedShotCount'] = counted.length
        ..['firstShotTimeMicros'] = counted.isEmpty
            ? null
            : counted.first.elapsedMicroseconds
        ..['lastShotTimeMicros'] = counted.isEmpty
            ? null
            : counted.last.elapsedMicroseconds
        ..['totalTimeMicros'] = preservesSignalDuration
            ? previousTotalTime
            : counted.isEmpty
            ? 0
            : counted.last.elapsedMicroseconds
        ..['fastestSplitMicros'] = splits.isEmpty
            ? null
            : splits.reduce(math.min)
        ..['slowestSplitMicros'] = splits.isEmpty
            ? null
            : splits.reduce(math.max)
        ..['averageSplitMicros'] = averageSplit
        ..['splitStandardDeviationMicros'] = splitStandardDeviation;
    }
    if (markUserEdited) summary['userEdited'] = true;
    return _encodeJsonObject(summary, 'timersamenvatting');
  }

  String _encodeJsonObject(Map<String, Object?> value, String label) {
    try {
      final encoded = jsonEncode(value);
      if (jsonDecode(encoded) is! Map) throw const FormatException();
      return encoded;
    } on Object {
      throw ArgumentError('$label bevat niet-serialiseerbare gegevens.');
    }
  }

  Future<SeriesDefaults> _lastUsedDefaults() async {
    final last =
        await (database.select(database.shootingSeries)
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)])
              ..limit(1))
            .getSingleOrNull();
    return last == null
        ? SeriesDefaults.standard()
        : SeriesDefaults.fromRecord(last);
  }

  Future<SessionRecord?> _activeSession() =>
      (database.select(database.trainingSessions)
            ..where(
              (row) => row.status.equals(domain.SessionStatus.active.name),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<SessionRecord?> _session(String id) =>
      (database.select(database.trainingSessions)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<FirearmRecord?> _firearm(String id) =>
      (database.select(database.firearms)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<CartridgeRecord?> _cartridge(String id) =>
      (database.select(database.cartridges)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<AmmoLotRecord?> _ammoLot(String id) =>
      (database.select(database.ammoLots)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<RangeRecord?> _range(String id) =>
      (database.select(database.ranges)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<TargetProfileRecord?> _targetProfile(String versionedId) =>
      (database.select(database.targetProfiles)
            ..where((row) => row.versionedId.equals(versionedId))
            ..limit(1))
          .getSingleOrNull();

  Future<SeriesRecord?> _series(String id) =>
      (database.select(database.shootingSeries)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<ImageAssetRecord?> _image(String id) =>
      (database.select(database.imageAssets)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<void> _touchSession(String id, DateTime atUtc) async {
    await (database.update(database.trainingSessions)
          ..where((row) => row.id.equals(id)))
        .write(TrainingSessionsCompanion(updatedAtUtc: Value(atUtc.toUtc())));
  }

  Future<void> _renumberSeries(String sessionId) async {
    final series =
        await (database.select(database.shootingSeries)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([
                (row) => OrderingTerm.asc(row.sequenceNumber),
                (row) => OrderingTerm.asc(row.createdAtUtc),
              ]))
            .get();
    for (var index = 0; index < series.length; index++) {
      final expected = index + 1;
      if (series[index].sequenceNumber != expected) {
        await (database.update(database.shootingSeries)
              ..where((row) => row.id.equals(series[index].id)))
            .write(ShootingSeriesCompanion(sequenceNumber: Value(expected)));
      }
    }
  }

  Future<void> _deleteFileIfPresent(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error, stackTrace) {
      developer.log(
        'Lokaal mediabestand kon niet worden opgeruimd: $path',
        name: 'shooting_companion.media_cleanup',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _sameImpactMetadata(
    ImpactRecord existing,
    domain.ShotImpact resulting,
  ) =>
      existing.id == resulting.id &&
      existing.sourceImageId == resulting.sourceImageId &&
      existing.imageXNormalized == resulting.imageXNormalized &&
      existing.imageYNormalized == resulting.imageYNormalized &&
      existing.multiplicity == resulting.multiplicity &&
      existing.isMiss == resulting.isMiss &&
      existing.isPositionUncertain == resulting.isPositionUncertain;

  bool _sameStoredImpact(ImpactRecord existing, domain.ShotImpact resulting) =>
      _sameImpactMetadata(existing, resulting) &&
      existing.targetBullId == resulting.targetBullId &&
      existing.xMm == resulting.xMm &&
      existing.yMm == resulting.yMm;

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

domain.TargetProfile _copyTargetProfile(
  domain.TargetProfile source, {
  required String profileId,
  required int profileVersion,
  String? displayName,
}) => domain.TargetProfile(
  schemaVersion: source.schemaVersion,
  profileId: profileId,
  profileVersion: profileVersion,
  displayName: displayName ?? source.displayName,
  authority: source.authority,
  rulesEdition: source.rulesEdition,
  physicalCardWidthMm: source.physicalCardWidthMm,
  physicalCardHeightMm: source.physicalCardHeightMm,
  rings: source.rings,
  innerTenDiameterMm: source.innerTenDiameterMm,
  blackOuterDiameterMm: source.blackOuterDiameterMm,
  lineThicknessMm: source.lineThicknessMm,
  lineBreakingRule: source.lineBreakingRule,
  validationStatus: source.validationStatus,
  targetKind: source.targetKind,
  defaultDistanceMeters: source.defaultDistanceMeters,
  supportedDistancesMeters: source.supportedDistancesMeters,
  bulls: source.bulls,
  multiBullScoringPolicy: source.multiBullScoringPolicy,
  rendererKind: source.rendererKind,
);

DateTime _nextSqliteSecond(DateTime value) {
  final seconds = value.toUtc().millisecondsSinceEpoch ~/ 1000;
  return DateTime.fromMillisecondsSinceEpoch((seconds + 1) * 1000, isUtc: true);
}
