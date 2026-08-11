import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:shooting_companion_training/training.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'timer_preset_defaults.dart';
import 'training_activity_snapshot_validator.dart';

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
  guidedDrillV2,
  learningPathV2,
  trainingPlan,
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

/// Read model used by the training UI so it never needs to reinterpret stored
/// activity JSON or accidentally resume a legacy v1 drill.
class GuidedTrainingActivityOverview {
  const GuidedTrainingActivityOverview({
    required this.activity,
    required this.configuration,
    required this.summary,
    required this.title,
    required this.versionedContentId,
    required this.canResume,
    required this.isLegacyReadOnly,
    required this.isTrainingPlan,
  });

  final TrainingActivityRecord activity;
  final Map<String, Object?> configuration;
  final Map<String, Object?> summary;
  final String title;
  final String? versionedContentId;
  final bool canResume;
  final bool isLegacyReadOnly;
  final bool isTrainingPlan;
}

/// Version-bound read model for an active or historical learning path.
///
/// The UI reconstructs the path from [configuration], never from the mutable
/// built-in catalog. This keeps a started path reproducible after content
/// updates and makes completed history strictly read-only.
class LearningPathActivityOverview {
  const LearningPathActivityOverview({
    required this.activity,
    required this.configuration,
    required this.summary,
    required this.title,
    required this.versionedContentId,
    required this.completedEntryIds,
    required this.currentEntryIndex,
    required this.totalEntryCount,
    required this.lessonSnapshotsByEntryId,
    required this.drillSnapshotsByEntryId,
    required this.canResume,
  });

  final TrainingActivityRecord activity;
  final Map<String, Object?> configuration;
  final Map<String, Object?> summary;
  final String title;
  final String? versionedContentId;
  final Set<String> completedEntryIds;
  final int currentEntryIndex;
  final int totalEntryCount;
  final Map<String, TechniqueLessonV2> lessonSnapshotsByEntryId;
  final Map<String, DrillDefinitionV2> drillSnapshotsByEntryId;
  final bool canResume;

  bool get hasCompleteEntrySnapshots =>
      lessonSnapshotsByEntryId.length + drillSnapshotsByEntryId.length ==
      totalEntryCount;

  bool get isReadOnly =>
      activity.status == StoredTrainingActivityStatus.completed.name ||
      !canResume;
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

  /// Watches unfinished drill runs that can be resumed from the drill library.
  ///
  /// A drill is deliberately persisted before its first series is opened. Both
  /// [draft] and [interrupted] records therefore belong in this list.
  Stream<List<TrainingActivityRecord>> watchResumableDrillActivities() {
    final query = database.select(database.trainingActivities)
      ..where(
        (row) =>
            row.kind.equals(StoredTrainingActivityKind.guidedDrillV2.name) &
            row.status.isIn([
              StoredTrainingActivityStatus.draft.name,
              StoredTrainingActivityStatus.interrupted.name,
            ]),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)]);
    return query.watch().map(
      (activities) => activities
          .where(_hasResumableTrainingSnapshot)
          .toList(growable: false),
    );
  }

  /// Watches unfinished deterministic training plans.
  Stream<List<TrainingActivityRecord>> watchResumableTrainingPlans() {
    final query = database.select(database.trainingActivities)
      ..where(
        (row) =>
            row.kind.equals(StoredTrainingActivityKind.trainingPlan.name) &
            row.status.isIn([
              StoredTrainingActivityStatus.draft.name,
              StoredTrainingActivityStatus.interrupted.name,
            ]),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)]);
    return query.watch().map(
      (activities) => activities
          .where(_hasResumableTrainingSnapshot)
          .toList(growable: false),
    );
  }

  /// Watches the one authoritative active training plan.
  ///
  /// Creation prevents multiple active plans. If imported or externally
  /// corrupted data nevertheless contains more than one resumable plan, this
  /// stream fails closed instead of choosing an arbitrary plan.
  Stream<TrainingActivityRecord?>
  watchActiveTrainingPlan() => watchResumableTrainingPlans().map((plans) {
    if (plans.isEmpty) return null;
    if (plans.length == 1) return plans.single;
    throw StateError(
      'Meerdere actieve trainingsplannen gevonden; hervatten is geblokkeerd.',
    );
  });

  /// Watches every persisted V2 learning path, including immutable history.
  /// Malformed or future snapshots stay visible but are never resumable.
  Stream<List<LearningPathActivityOverview>>
  watchLearningPathActivityOverviews() {
    final query = database.select(database.trainingActivities)
      ..where(
        (row) =>
            row.kind.equals(StoredTrainingActivityKind.learningPathV2.name),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)]);
    return query.watch().map(
      (activities) =>
          activities.map(_learningPathActivityOverview).toList(growable: false),
    );
  }

  /// Watches the single unfinished learning path used by the Start resume card.
  ///
  /// A corrupt import containing multiple unfinished paths fails closed rather
  /// than picking one arbitrarily.
  Stream<LearningPathActivityOverview?> watchActiveLearningPath() =>
      watchLearningPathActivityOverviews().map((overviews) {
        final active = overviews
            .where(
              (overview) =>
                  overview.activity.status ==
                      StoredTrainingActivityStatus.draft.name ||
                  overview.activity.status ==
                      StoredTrainingActivityStatus.interrupted.name,
            )
            .toList(growable: false);
        if (active.isEmpty) return null;
        if (active.length == 1) return active.single;
        throw StateError(
          'Meerdere actieve leerpaden gevonden; hervatten is geblokkeerd.',
        );
      });

  /// Provides current runs and history with legacy drill records explicitly
  /// marked read-only. Only `guidedDrillV2` and `trainingPlan` can resume.
  Stream<List<GuidedTrainingActivityOverview>>
  watchGuidedTrainingActivityOverviews() {
    final query = database.select(database.trainingActivities)
      ..where(
        (row) => row.kind.isIn([
          StoredTrainingActivityKind.drill.name,
          StoredTrainingActivityKind.guidedDrillV2.name,
          StoredTrainingActivityKind.trainingPlan.name,
        ]),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)]);
    return query.watch().map(
      (activities) => activities
          .map(_guidedTrainingActivityOverview)
          .toList(growable: false),
    );
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

  /// Starts exactly one version-bound learning path.
  ///
  /// Repeating the same request while that path is unfinished returns the
  /// existing activity id. A different active path must first be completed,
  /// interrupted and removed, or explicitly resumed by the user.
  Future<String> startLearningPathActivity({
    required String learningPathVersionedId,
    required Map<String, Object?> learningPathSnapshot,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
  }) async {
    if (localUtcOffsetMinutes.abs() > 24 * 60) {
      throw ArgumentError('Ongeldige lokale tijdzone.');
    }
    final pathOnly = _validateLearningPathSnapshot(
      learningPathVersionedId: learningPathVersionedId,
      learningPathSnapshot: learningPathSnapshot,
    );
    final entrySnapshots = _createLearningPathEntrySnapshots(pathOnly.path);
    final validated = _validateLearningPathSnapshot(
      learningPathVersionedId: learningPathVersionedId,
      learningPathSnapshot: learningPathSnapshot,
      rawEntrySnapshots: entrySnapshots,
      requireEntrySnapshots: true,
    );
    final configuration = <String, Object?>{
      'learningPathVersionedId': validated.path.versionedId,
      'learningPath': validated.path.toJson(),
      'entrySnapshots': entrySnapshots,
    };
    final summary = <String, Object?>{
      'completedEntryIds': <String>[],
      'currentEntryIndex': 0,
    };
    final configurationJson = _encodeJsonObject(
      configuration,
      'leerpadconfiguratie',
    );
    final summaryJson = _encodeJsonObject(summary, 'leerpadvoortgang');
    final id = _uuid.v7();
    final now = DateTime.now().toUtc();
    return database.transaction(() async {
      final existing =
          await (database.select(database.trainingActivities)..where(
                (row) =>
                    row.kind.equals(
                      StoredTrainingActivityKind.learningPathV2.name,
                    ) &
                    row.status.isIn([
                      StoredTrainingActivityStatus.draft.name,
                      StoredTrainingActivityStatus.interrupted.name,
                    ]),
              ))
              .get();
      if (existing.length > 1) {
        throw StateError(
          'Meerdere actieve leerpaden gevonden; starten is geblokkeerd.',
        );
      }
      if (existing case [final current]) {
        final currentSnapshot = _learningPathSnapshot(current);
        if (currentSnapshot.path.versionedId == validated.path.versionedId) {
          return current.id;
        }
        throw StateError(
          'Er is al een ander leerpad actief. Rond het af of onderbreek het.',
        );
      }
      await database
          .into(database.trainingActivities)
          .insert(
            TrainingActivitiesCompanion.insert(
              id: id,
              kind: StoredTrainingActivityKind.learningPathV2.name,
              schemaVersion: const Value(2),
              status: StoredTrainingActivityStatus.draft.name,
              configurationJson: configurationJson,
              summaryJson: summaryJson,
              startedAtUtc: startedAtUtc.toUtc(),
              localUtcOffsetMinutes: localUtcOffsetMinutes,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      return id;
    });
  }

  /// Replaces learning-path progress after validating it against the immutable
  /// path snapshot. Repeating the same write is a no-op.
  Future<void> updateLearningPathProgress({
    required String activityId,
    required Iterable<String> completedEntryIds,
  }) async {
    await database.transaction(() async {
      final activity = await _requireLearningPathActivity(activityId);
      if (activity.status != StoredTrainingActivityStatus.draft.name) {
        throw StateError(
          activity.status == StoredTrainingActivityStatus.completed.name
              ? 'Een afgerond leerpad is alleen-lezen.'
              : 'Hervat het leerpad voordat je voortgang aanpast.',
        );
      }
      final snapshot = _learningPathSnapshot(activity);
      final completed = completedEntryIds.toList(growable: false);
      if (completed.length != completed.toSet().length ||
          completed.any((id) => !snapshot.entryIds.contains(id))) {
        throw ArgumentError('De leerpadvoortgang bevat onbekende onderdelen.');
      }
      final completedSet = completed.toSet();
      await _requireCompletedLearningPathDrillEvidence(
        activity: activity,
        snapshot: snapshot,
        completedEntryIds: completedSet,
      );
      final orderedCompleted = snapshot.entryIds
          .where(completedSet.contains)
          .toList(growable: false);
      final currentEntryIndex = snapshot.entryIds.indexWhere(
        (id) => !completedSet.contains(id),
      );
      final summary = <String, Object?>{
        'completedEntryIds': orderedCompleted,
        'currentEntryIndex': currentEntryIndex < 0
            ? snapshot.entryIds.length
            : currentEntryIndex,
      };
      final summaryJson = _encodeJsonObject(summary, 'leerpadvoortgang');
      if (summaryJson == activity.summaryJson) return;
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          summaryJson: Value(summaryJson),
          updatedAtUtc: Value(DateTime.now().toUtc()),
        ),
      );
    });
  }

  Future<void> resumeLearningPath(String activityId) =>
      _resumeStructuredActivity(
        activityId,
        requireActivity: _requireLearningPathActivity,
      );

  Future<void> interruptLearningPath({
    required String activityId,
    DateTime? interruptedAtUtc,
  }) async {
    await database.transaction(() async {
      final activity = await _requireLearningPathActivity(activityId);
      if (activity.status == StoredTrainingActivityStatus.completed.name ||
          activity.status == StoredTrainingActivityStatus.interrupted.name) {
        return;
      }
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.interrupted.name),
          completedAtUtc: Value((interruptedAtUtc ?? now).toUtc()),
          updatedAtUtc: Value(now),
        ),
      );
    });
  }

  Future<void> completeLearningPath({
    required String activityId,
    required DateTime completedAtUtc,
  }) async {
    await database.transaction(() async {
      final activity = await _requireLearningPathActivity(activityId);
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        return;
      }
      final snapshot = _learningPathSnapshot(activity);
      final progress = _learningPathProgress(activity, snapshot);
      if (progress.completedEntryIds.length != snapshot.entryIds.length) {
        throw StateError('Rond eerst alle onderdelen van het leerpad af.');
      }
      await _requireCompletedLearningPathDrillEvidence(
        activity: activity,
        snapshot: snapshot,
        completedEntryIds: progress.completedEntryIds.toSet(),
      );
      final completedAt = completedAtUtc.toUtc();
      if (completedAt.isBefore(activity.startedAtUtc.toUtc())) {
        throw ArgumentError('De eindtijd ligt vóór de start van het leerpad.');
      }
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.completed.name),
          completedAtUtc: Value(completedAt),
          updatedAtUtc: Value(DateTime.now().toUtc()),
        ),
      );
    });
  }

  /// Creates the sole resumable training plan. A second draft must be resumed
  /// or explicitly interrupted/deleted instead of being silently duplicated.
  Future<String> createTrainingPlanActivity({
    required Map<String, Object?> configuration,
    required Map<String, Object?> summary,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
  }) async {
    if (localUtcOffsetMinutes.abs() > 24 * 60) {
      throw ArgumentError('Ongeldige lokale tijdzone.');
    }
    final configurationJson = _encodeJsonObject(
      configuration,
      'trainingsplanconfiguratie',
    );
    final summaryJson = _encodeJsonObject(summary, 'trainingsplansamenvatting');
    final id = _uuid.v7();
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      final existing =
          await (database.select(database.trainingActivities)
                ..where(
                  (row) =>
                      row.kind.equals(
                        StoredTrainingActivityKind.trainingPlan.name,
                      ) &
                      row.status.isIn([
                        StoredTrainingActivityStatus.draft.name,
                        StoredTrainingActivityStatus.interrupted.name,
                      ]),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) {
        throw StateError(
          'Er bestaat al een trainingsplan. Hervat of verwijder dat plan.',
        );
      }
      await database
          .into(database.trainingActivities)
          .insert(
            TrainingActivitiesCompanion.insert(
              id: id,
              kind: StoredTrainingActivityKind.trainingPlan.name,
              schemaVersion: const Value(1),
              status: StoredTrainingActivityStatus.draft.name,
              configurationJson: configurationJson,
              summaryJson: summaryJson,
              startedAtUtc: startedAtUtc.toUtc(),
              localUtcOffsetMinutes: localUtcOffsetMinutes,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      final stored = await _requireTrainingPlanActivity(id);
      _planSnapshot(stored);
    });
    return id;
  }

  /// Finds or creates exactly one V2 guided activity for a persisted plan slot.
  /// The slot mapping and activity insert share one transaction, preventing
  /// orphaned drafts after process interruption or repeated taps.
  Future<String> findOrCreateGuidedDrillSlot({
    required String planActivityId,
    required int slotIndex,
    required String drillVersionedId,
    required Map<String, Object?> drillSnapshot,
    required Map<String, Object?> trainingPlanContext,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
  }) async {
    if (localUtcOffsetMinutes.abs() > 24 * 60) {
      throw ArgumentError('Ongeldige lokale tijdzone.');
    }
    return database.transaction(() async {
      final plan = await _requireTrainingPlanActivity(planActivityId);
      if (plan.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError('Het trainingsplan is al afgerond.');
      }
      final planSnapshot = _planSnapshot(plan);
      final slots = planSnapshot['slots'];
      if (slots is! List) {
        throw StateError('Het trainingsplan bevat geen geldige slots.');
      }
      final matching = slots.whereType<Map>().where(
        (slot) => slot['index'] == slotIndex,
      );
      if (matching.length != 1) {
        throw StateError('De gekozen trainingsplanslot bestaat niet.');
      }
      final expectedDrill = matching.single['drill'];
      if (expectedDrill is! Map ||
          _versionedContentId(expectedDrill.cast<Object?, Object?>()) !=
              drillVersionedId ||
          _versionedContentId(drillSnapshot.cast<Object?, Object?>()) !=
              drillVersionedId ||
          trainingPlanContext['planActivityId'] != planActivityId ||
          trainingPlanContext['planId'] != planSnapshot['id'] ||
          trainingPlanContext['slotIndex'] != slotIndex ||
          trainingPlanContext['slotCount'] != slots.length) {
        throw StateError('De drill komt niet overeen met de opgeslagen slot.');
      }
      final planSummary = _decodeJsonObject(
        plan.summaryJson,
        'trainingsplansamenvatting',
      );
      final mapped = _readStringMap(
        planSummary['guidedDrillActivityIds'],
      )['$slotIndex'];
      if (mapped != null) {
        final existing = await _requireDrillActivity(mapped);
        _validateTrainingPlanBinding(drill: existing, plan: plan);
        return existing.id;
      }

      final candidates =
          await (database.select(database.trainingActivities)..where(
                (row) => row.kind.equals(
                  StoredTrainingActivityKind.guidedDrillV2.name,
                ),
              ))
              .get();
      final matchingDrafts = <TrainingActivityRecord>[];
      for (final candidate in candidates) {
        try {
          final configuration = _decodeJsonObject(
            candidate.configurationJson,
            'drillconfiguratie',
          );
          final context = configuration['trainingPlan'];
          if (context is Map &&
              context['planActivityId'] == planActivityId &&
              context['slotIndex'] == slotIndex) {
            matchingDrafts.add(candidate);
          }
        } on Object {
          continue;
        }
      }
      if (matchingDrafts.length > 1) {
        throw StateError('Deze planslot bevat meerdere drillconcepten.');
      }
      final id = matchingDrafts.singleOrNull?.id ?? _uuid.v7();
      if (matchingDrafts.isEmpty) {
        final configuration = {
          'drillVersionedId': drillVersionedId,
          'drill': drillSnapshot,
          'trainingPlan': trainingPlanContext,
        };
        final now = DateTime.now().toUtc();
        await database
            .into(database.trainingActivities)
            .insert(
              TrainingActivitiesCompanion.insert(
                id: id,
                kind: StoredTrainingActivityKind.guidedDrillV2.name,
                schemaVersion: const Value(2),
                status: StoredTrainingActivityStatus.draft.name,
                configurationJson: _encodeJsonObject(
                  configuration,
                  'drillconfiguratie',
                ),
                summaryJson: '{}',
                startedAtUtc: startedAtUtc.toUtc(),
                localUtcOffsetMinutes: localUtcOffsetMinutes,
                createdAtUtc: now,
                updatedAtUtc: now,
              ),
            );
      }
      final drill = await _requireDrillActivity(id);
      _validateTrainingPlanBinding(drill: drill, plan: plan);
      planSummary['guidedDrillActivityIds'] = {
        ..._readStringMap(planSummary['guidedDrillActivityIds']),
        '$slotIndex': id,
      };
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(plan.id))).write(
        TrainingActivitiesCompanion(
          summaryJson: Value(
            _encodeJsonObject(planSummary, 'trainingsplansamenvatting'),
          ),
          updatedAtUtc: Value(DateTime.now().toUtc()),
        ),
      );
      return id;
    });
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
      if (activity.kind == StoredTrainingActivityKind.guidedDrillV2.name ||
          activity.kind == StoredTrainingActivityKind.trainingPlan.name) {
        _requireValidStructuredSnapshot(
          activity,
          summaryJson: summaryJson,
          status: StoredTrainingActivityStatus.interrupted.name,
        );
        if (activity.kind == StoredTrainingActivityKind.guidedDrillV2.name) {
          await _validateGuidedDrillRelations(
            activity,
            summary,
            requireCompletion: false,
          );
        } else {
          await _validateTrainingPlanRelations(
            activity,
            summary,
            requireCompletion: false,
          );
        }
      }
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

  /// Stores drill-runner state without manufacturing completed series.
  Future<void> updateDrillActivityProgress({
    required String activityId,
    required Map<String, Object?> summary,
    String? notes,
  }) async {
    final summaryJson = _encodeJsonObject(summary, 'drillvoortgang');
    await database.transaction(() async {
      final activity = await _requireDrillActivity(activityId);
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError('Een afgeronde drill kan niet worden aangepast.');
      }
      _requireValidStructuredSnapshot(
        activity,
        summaryJson: summaryJson,
        status: activity.status,
      );
      await _validateGuidedDrillRelations(
        activity,
        summary,
        requireCompletion: false,
      );
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          summaryJson: Value(summaryJson),
          notes: Value(_nullIfBlank(notes) ?? activity.notes),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  /// Resumes an interrupted drill while keeping its snapshot and links intact.
  Future<void> resumeDrillActivity(String activityId) async {
    await database.transaction(() async {
      final activity = await _requireDrillActivity(activityId);
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        return;
      }
      if (activity.status == StoredTrainingActivityStatus.draft.name &&
          activity.completedAtUtc == null) {
        return;
      }
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.draft.name),
          completedAtUtc: const Value(null),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  /// Stores deterministic planner progress without changing linked series.
  Future<void> updateTrainingPlanProgress({
    required String activityId,
    required Map<String, Object?> summary,
    String? notes,
  }) async {
    final summaryJson = _encodeJsonObject(summary, 'trainingsplanvoortgang');
    await database.transaction(() async {
      final activity = await _requireTrainingPlanActivity(activityId);
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError(
          'Een afgerond trainingsplan kan niet worden aangepast.',
        );
      }
      _requireValidStructuredSnapshot(
        activity,
        summaryJson: summaryJson,
        status: activity.status,
      );
      await _validateTrainingPlanRelations(
        activity,
        summary,
        requireCompletion: false,
      );
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          summaryJson: Value(summaryJson),
          notes: Value(_nullIfBlank(notes) ?? activity.notes),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  Future<void> resumeTrainingPlan(String activityId) =>
      _resumeStructuredActivity(
        activityId,
        requireActivity: _requireTrainingPlanActivity,
      );

  Future<void> completeTrainingPlan({
    required String activityId,
    required Map<String, Object?> summary,
    required DateTime completedAtUtc,
  }) async {
    final summaryJson = _encodeJsonObject(summary, 'trainingsplansamenvatting');
    await database.transaction(() async {
      final activity = await _requireTrainingPlanActivity(activityId);
      _requireValidStructuredSnapshot(
        activity,
        summaryJson: summaryJson,
        status: StoredTrainingActivityStatus.completed.name,
      );
      await _validateTrainingPlanRelations(
        activity,
        summary,
        requireCompletion: true,
      );
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        return;
      }
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.completed.name),
          summaryJson: Value(summaryJson),
          completedAtUtc: Value(completedAtUtc.toUtc()),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  /// Records a finished guided-drill slot in its plan. Retried completions are
  /// idempotent. The plan remains unfinished until every explicit setup,
  /// technique, drill, review and reflection step has been completed.
  Future<void> recordCompletedDrillInTrainingPlan({
    required String activityId,
    required int slotIndex,
    required int slotCount,
    required String guidedDrillActivityId,
    required DateTime completedAtUtc,
  }) async {
    if (slotIndex < 0 || slotCount < 1 || slotIndex >= slotCount) {
      throw ArgumentError('Ongeldige trainingsplanslot.');
    }
    await database.transaction(() async {
      final plan = await _requireTrainingPlanActivity(activityId);
      final drill = await _requireDrillActivity(guidedDrillActivityId);
      final binding = _validateTrainingPlanBinding(drill: drill, plan: plan);
      if (binding.slotIndex != slotIndex || binding.slotCount != slotCount) {
        throw StateError(
          'De drill hoort niet bij deze opgeslagen trainingsplanslot.',
        );
      }
      if (drill.status != StoredTrainingActivityStatus.completed.name) {
        throw StateError('De gekoppelde drill is nog niet afgerond.');
      }
      await _recordCompletedDrillSlot(
        plan: plan,
        drill: drill,
        binding: binding,
        completedAtUtc: completedAtUtc,
      );
    });
  }

  /// Completes a V2 drill and its containing plan slot in one transaction.
  ///
  /// The plan relationship is read from the immutable activity snapshots. A
  /// caller cannot complete another slot by supplying a different index,
  /// count, plan or drill id.
  Future<void> completeGuidedDrillActivity({
    required String activityId,
    required Map<String, Object?> summary,
    required DateTime completedAtUtc,
    required int minimumLinkedSeries,
    String? notes,
  }) async {
    if (minimumLinkedSeries < 0) {
      throw ArgumentError(
        'Het vereiste aantal reeksen kan niet negatief zijn.',
      );
    }
    final summaryJson = _encodeJsonObject(summary, 'drillsamenvatting');
    await database.transaction(() async {
      final drill = await _requireDrillActivity(activityId);
      if (drill.status == StoredTrainingActivityStatus.completed.name) {
        final planId = _trainingPlanActivityId(drill);
        if (planId != null) {
          final plan = await _requireTrainingPlanActivity(planId);
          final binding = _validateTrainingPlanBinding(
            drill: drill,
            plan: plan,
          );
          await _recordCompletedDrillSlot(
            plan: plan,
            drill: drill,
            binding: binding,
            completedAtUtc: completedAtUtc,
          );
        }
        return;
      }
      _requireValidStructuredSnapshot(
        drill,
        summaryJson: summaryJson,
        status: StoredTrainingActivityStatus.completed.name,
      );
      await _validateGuidedDrillRelations(
        drill,
        summary,
        requireCompletion: true,
      );
      await _validateAndCompleteDrill(
        drill: drill,
        summaryJson: summaryJson,
        completedAtUtc: completedAtUtc,
        minimumLinkedSeries: minimumLinkedSeries,
        notes: notes,
      );
      final planId = _trainingPlanActivityId(drill);
      if (planId != null) {
        final plan = await _requireTrainingPlanActivity(planId);
        final binding = _validateTrainingPlanBinding(drill: drill, plan: plan);
        await _recordCompletedDrillSlot(
          plan: plan,
          drill: drill,
          binding: binding,
          completedAtUtc: completedAtUtc,
        );
      }
    });
  }

  Future<void> _resumeStructuredActivity(
    String activityId, {
    required Future<TrainingActivityRecord> Function(String activityId)
    requireActivity,
  }) async {
    await database.transaction(() async {
      final activity = await requireActivity(activityId);
      _requireValidStructuredSnapshot(activity);
      if (activity.status == StoredTrainingActivityStatus.completed.name ||
          activity.status == StoredTrainingActivityStatus.draft.name &&
              activity.completedAtUtc == null) {
        return;
      }
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals(activityId))).write(
        TrainingActivitiesCompanion(
          status: Value(StoredTrainingActivityStatus.draft.name),
          completedAtUtc: const Value(null),
          updatedAtUtc: Value(now),
        ),
      );
      if (activity.sessionId != null) {
        await _touchSession(activity.sessionId!, now);
      }
    });
  }

  /// Completes a drill only after enough real, confirmed series are linked.
  Future<void> completeDrillActivity({
    required String activityId,
    required Map<String, Object?> summary,
    required DateTime completedAtUtc,
    required int minimumLinkedSeries,
    String? notes,
  }) async {
    if (minimumLinkedSeries < 0) {
      throw ArgumentError(
        'Het vereiste aantal reeksen kan niet negatief zijn.',
      );
    }
    final summaryJson = _encodeJsonObject(summary, 'drillsamenvatting');
    await database.transaction(() async {
      final activity = await _requireDrillActivity(activityId);
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        return;
      }
      if (_trainingPlanActivityId(activity) != null) {
        throw StateError(
          'Een geplande drill moet samen met zijn trainingsplan worden '
          'afgerond.',
        );
      }
      _requireValidStructuredSnapshot(
        activity,
        summaryJson: summaryJson,
        status: StoredTrainingActivityStatus.completed.name,
      );
      await _validateGuidedDrillRelations(
        activity,
        summary,
        requireCompletion: true,
      );
      await _validateAndCompleteDrill(
        drill: activity,
        summaryJson: summaryJson,
        completedAtUtc: completedAtUtc,
        minimumLinkedSeries: minimumLinkedSeries,
        notes: notes,
      );
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
      await _linkTrainingActivityRecords(
        activity,
        series,
        role: role,
        variantId: variantId,
      );
    });
  }

  /// Links a runner result while enforcing that it is an actual confirmed
  /// shooting series. Duplicate taps remain idempotent.
  Future<void> linkConfirmedSeriesToDrillActivity(
    String activityId,
    String seriesId, {
    String? role,
    String? variantId,
  }) async {
    await database.transaction(() async {
      final activity = await _requireDrillActivity(activityId);
      final series = await _series(seriesId);
      if (series == null) {
        throw ArgumentError('De gekozen reeks bestaat niet meer.');
      }
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError('Een afgeronde drill kan niet worden aangepast.');
      }
      if (series.status != domain.SeriesStatus.confirmed.name) {
        throw StateError('Alleen een bevestigde reeks kan worden gekoppeld.');
      }
      await _linkTrainingActivityRecords(
        activity,
        series,
        role: role,
        variantId: variantId,
      );
    });
  }

  /// Links the same confirmed evidence to its containing training plan.
  Future<void> linkConfirmedSeriesToTrainingPlan(
    String activityId,
    String seriesId, {
    String? role,
    String? variantId,
  }) async {
    await database.transaction(() async {
      final activity = await _requireTrainingPlanActivity(activityId);
      final series = await _series(seriesId);
      if (series == null) {
        throw ArgumentError('De gekozen reeks bestaat niet meer.');
      }
      if (activity.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError(
          'Een afgerond trainingsplan kan niet worden aangepast.',
        );
      }
      if (series.status != domain.SeriesStatus.confirmed.name) {
        throw StateError('Alleen een bevestigde reeks kan worden gekoppeld.');
      }
      await _linkTrainingActivityRecords(
        activity,
        series,
        role: role,
        variantId: variantId,
      );
    });
  }

  /// Atomically attaches one confirmed series to its V2 drill and, when the
  /// drill runs inside a plan, to that plan as the same evidence. Retrying the
  /// callback is safe through the activity/series unique key.
  Future<void> linkConfirmedSeriesToGuidedDrill({
    required String drillActivityId,
    required String seriesId,
    String? drillRole,
    String? planActivityId,
    String? planRole,
    String? variantId,
  }) async {
    await database.transaction(() async {
      final drill = await _requireDrillActivity(drillActivityId);
      final plan = planActivityId == null
          ? null
          : await _requireTrainingPlanActivity(planActivityId);
      final binding = plan == null
          ? null
          : _validateTrainingPlanBinding(drill: drill, plan: plan);
      final storedPlanId = _trainingPlanActivityId(drill);
      if (storedPlanId != planActivityId) {
        throw StateError(
          'De opgeslagen drill hoort niet bij dit trainingsplan.',
        );
      }
      if (binding != null) {
        final expectedRole = 'slot:${binding.slotIndex}:$drillRole';
        if (planRole != expectedRole) {
          throw StateError('De reeks hoort niet bij deze planslot.');
        }
      }
      final series = await _series(seriesId);
      if (series == null) {
        throw ArgumentError('De gekozen reeks bestaat niet meer.');
      }
      if (drill.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError('Een afgeronde drill kan niet worden aangepast.');
      }
      if (plan?.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError(
          'Een afgerond trainingsplan kan niet worden aangepast.',
        );
      }
      if (series.status != domain.SeriesStatus.confirmed.name) {
        throw StateError('Alleen een bevestigde reeks kan worden gekoppeld.');
      }
      await _linkTrainingActivityRecords(
        drill,
        series,
        role: drillRole,
        variantId: variantId,
      );
      if (plan != null) {
        await _linkTrainingActivityRecords(
          plan,
          series,
          role: planRole,
          variantId: variantId,
        );
      }
    });
  }

  /// Atomically removes one confirmed-series link from a guided drill and its
  /// containing plan. This prevents stale plan evidence after runner edits.
  Future<void> unlinkConfirmedSeriesFromGuidedDrill({
    required String drillActivityId,
    required String seriesId,
  }) async {
    await database.transaction(() async {
      final drill = await _requireDrillActivity(drillActivityId);
      if (drill.status == StoredTrainingActivityStatus.completed.name) {
        throw StateError('Een afgeronde drill kan niet worden aangepast.');
      }
      final planId = _trainingPlanActivityId(drill);
      TrainingActivityRecord? plan;
      if (planId != null) {
        plan = await _requireTrainingPlanActivity(planId);
        _validateTrainingPlanBinding(drill: drill, plan: plan);
        if (plan.status == StoredTrainingActivityStatus.completed.name) {
          throw StateError(
            'Een afgerond trainingsplan kan niet worden aangepast.',
          );
        }
      }
      await _deleteTrainingActivitySeriesLink(drill.id, seriesId);
      if (plan != null) {
        await _deleteTrainingActivitySeriesLink(plan.id, seriesId);
      }
      final now = DateTime.now().toUtc();
      if (drill.sessionId != null) await _touchSession(drill.sessionId!, now);
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

  Future<void> deleteTrainingActivity(String activityId) =>
      database.transaction(() async {
        final target = await _trainingActivity(activityId);
        if (target == null) return;
        final structured =
            await (database.select(database.trainingActivities)..where(
                  (row) => row.kind.isIn([
                    StoredTrainingActivityKind.guidedDrillV2.name,
                    StoredTrainingActivityKind.trainingPlan.name,
                  ]),
                ))
                .get();
        for (final activity in structured) {
          if (activity.id == activityId) continue;
          if (_timerActivityKinds.contains(target.kind) &&
              activity.kind == StoredTrainingActivityKind.guidedDrillV2.name) {
            final summary = _decodeJsonObject(
              activity.summaryJson,
              'drillvoortgang',
            );
            if (_readStringMap(
              summary['timerActivityIds'],
            ).containsValue(activityId)) {
              throw StateError(
                'Deze timerrun is als bewijs aan een drillfase gekoppeld.',
              );
            }
          }
          if (target.kind == StoredTrainingActivityKind.guidedDrillV2.name &&
              activity.kind == StoredTrainingActivityKind.trainingPlan.name) {
            final summary = _decodeJsonObject(
              activity.summaryJson,
              'trainingsplanvoortgang',
            );
            if (_readStringMap(
              summary['guidedDrillActivityIds'],
            ).containsValue(activityId)) {
              throw StateError(
                'Deze drill is nog aan een trainingsplan gekoppeld.',
              );
            }
          }
          if (target.kind == StoredTrainingActivityKind.trainingPlan.name &&
              activity.kind == StoredTrainingActivityKind.guidedDrillV2.name) {
            final configuration = _decodeJsonObject(
              activity.configurationJson,
              'drillconfiguratie',
            );
            final context = configuration['trainingPlan'];
            if (context is Map && context['planActivityId'] == activityId) {
              throw StateError(
                'Dit trainingsplan bevat nog gekoppelde drillactiviteiten.',
              );
            }
          }
        }
        await (database.delete(
          database.trainingActivities,
        )..where((row) => row.id.equals(activityId))).go();
      });

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

  Future<void> savePhotoAlignment(domain.StoredPhotoAlignment alignment) =>
      database.transaction(() async {
        final image = await _image(alignment.imageId);
        if (image == null ||
            image.seriesId == null ||
            image.role != domain.ImageRole.primaryScoringPhoto.name) {
          throw StateError(
            'Alleen een primaire scorefoto kan worden uitgelijnd.',
          );
        }
        final series = await _series(image.seriesId!);
        if (series == null) throw StateError('De reeks bestaat niet meer.');
        final target = domain.TargetProfile.fromJsonString(
          series.targetProfileJson,
        );
        target.validateRuntime().requireValid(argumentName: 'target');
        final checked = _validateAlignment(alignment, target: target);
        await database
            .into(database.photoAlignments)
            .insertOnConflictUpdate(
              PhotoAlignmentsCompanion.insert(
                imageId: alignment.imageId,
                cornersJson: jsonEncode(
                  checked.geometry.corners.points
                      .map((point) => point.toJson())
                      .toList(),
                ),
                matrixJson: jsonEncode(checked.geometry.homographyMatrix),
                algorithmVersion: checked.geometry.algorithmVersion,
                rotationQuarterTurns: Value(alignment.rotationQuarterTurns),
                alignmentMode: Value(checked.persistedMode),
                anchorsJson: Value(checked.anchorsJson),
                reprojectionRmsMm: Value(checked.geometry.residuals.rmsMm),
                reprojectionMaxMm: Value(checked.geometry.residuals.maximumMm),
                planarityStatus: Value(checked.planarityStatus),
                confirmedAtUtc: Value(checked.confirmedAtUtc),
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
    if (!projectileDiameterMm.isFinite || projectileDiameterMm <= 0) {
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

    target.validateRuntime().requireValid(argumentName: 'target');
    final checkedAlignment = _validateAlignment(alignment, target: target);

    // Image coordinates are canonical: they always refer to the immutable,
    // EXIF-normalized original.  A rotation is a view/alignment concern only.
    // The old alignment is loaded deliberately so legacy view-relative data
    // can be detected before it is silently reinterpreted.
    final previousAlignmentRecord = await (database.select(
      database.photoAlignments,
    )..where((row) => row.imageId.equals(alignment.imageId))).getSingleOrNull();
    final previousAlignment = previousAlignmentRecord == null
        ? null
        : _tryDecodePersistedAlignment(previousAlignmentRecord, target: target);

    final existingRecords = await (database.select(
      database.shotImpacts,
    )..where((row) => row.seriesId.equals(seriesId))).get();
    final existingById = {
      for (final impact in existingRecords) impact.id: impact,
    };
    final resultingById = <String, domain.ShotImpact>{};
    for (var index = 0; index < resultingImpacts.length; index++) {
      final impact = resultingImpacts[index];
      impact.validateRuntime().requireValid(
        argumentName: 'resultingImpacts[$index]',
      );
      resultingById[impact.id] = impact;
    }
    if (resultingById.length != resultingImpacts.length ||
        resultingById.length != existingById.length ||
        !resultingById.keys.toSet().containsAll(existingById.keys)) {
      throw StateError(
        'Heruitlijning mag geen treffers toevoegen of verwijderen.',
      );
    }

    final authoritativeImpacts = <domain.ShotImpact>[];
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

        final storedSourcePoint = geo.NormalizedPoint(
          existing.imageXNormalized!,
          existing.imageYNormalized!,
        );
        if (!storedSourcePoint.isInsideImage) {
          throw StateError(
            'Een foto-afhankelijke treffer heeft ongeldige broncoordinaten.',
          );
        }
        final originalPoint = _canonicalOriginalSourcePoint(
          existing: existing,
          storedSourcePoint: storedSourcePoint,
          previousAlignment: previousAlignment,
        );
        final rotatedPoint = geo.rotateNormalizedPoint(
          originalPoint,
          alignment.rotationQuarterTurns,
        );
        final physical = checkedAlignment.geometry.normalizedToPhysical(
          rotatedPoint,
        );
        final authoritative = _domainImpact(existing).copyWith(
          xMm: physical.x,
          yMm: physical.y,
          imageXNormalized: originalPoint.x,
          imageYNormalized: originalPoint.y,
          targetBullId:
              target.targetKind == domain.TargetKind.multiBullConcentric
              ? target.bullAt(physical.x, physical.y, recordOnly: true)?.id
              : existing.targetBullId,
          clearTargetBull:
              target.targetKind == domain.TargetKind.multiBullConcentric &&
              target.bullAt(physical.x, physical.y, recordOnly: true) == null,
        );
        if ((resulting.xMm - authoritative.xMm).abs() >
                _alignmentPreviewToleranceMm ||
            (resulting.yMm - authoritative.yMm).abs() >
                _alignmentPreviewToleranceMm) {
          throw StateError(
            'De getoonde uitlijningspreview wijkt af van de autoritatieve '
            'herberekening.',
          );
        }
        authoritative.validateRuntime().requireValid(
          argumentName: 'authoritativeImpacts[${entry.key}]',
        );
        authoritativeImpacts.add(authoritative);
      } else if (!_sameStoredImpact(existing, resulting)) {
        throw StateError(
          'Heruitlijning mag handmatige of andere fototreffers niet wijzigen.',
        );
      } else {
        final authoritative = _domainImpact(existing);
        authoritative.validateRuntime().requireValid(
          argumentName: 'authoritativeImpacts[${entry.key}]',
        );
        authoritativeImpacts.add(authoritative);
      }
    }

    final score = ScoreEngine.score(
      target: target,
      impacts: authoritativeImpacts,
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
              checkedAlignment.geometry.corners.points
                  .map((point) => point.toJson())
                  .toList(),
            ),
            matrixJson: jsonEncode(checkedAlignment.geometry.homographyMatrix),
            algorithmVersion: checkedAlignment.geometry.algorithmVersion,
            rotationQuarterTurns: Value(alignment.rotationQuarterTurns),
            alignmentMode: Value(checkedAlignment.persistedMode),
            anchorsJson: Value(checkedAlignment.anchorsJson),
            reprojectionRmsMm: Value(checkedAlignment.geometry.residuals.rmsMm),
            reprojectionMaxMm: Value(
              checkedAlignment.geometry.residuals.maximumMm,
            ),
            planarityStatus: Value(checkedAlignment.planarityStatus),
            confirmedAtUtc: Value(checkedAlignment.confirmedAtUtc),
            updatedAtUtc: updatedAtUtc,
          ),
        );

    for (final shot in score.shots) {
      final existing = existingById[shot.impact.id]!;
      final dependsOnPhoto =
          existing.sourceImageId == alignment.imageId &&
          existing.imageXNormalized != null &&
          existing.imageYNormalized != null;
      if (!dependsOnPhoto) {
        // The score aggregate is recalculated from all impacts, but a photo
        // realignment must leave every stored non-photo impact byte-identical.
        continue;
      }
      final changed =
          await (database.update(database.shotImpacts)..where(
                (row) =>
                    row.id.equals(shot.impact.id) &
                    row.seriesId.equals(seriesId),
              ))
              .write(
                ShotImpactsCompanion(
                  xMm: Value(shot.impact.xMm),
                  yMm: Value(shot.impact.yMm),
                  imageXNormalized: Value(shot.impact.imageXNormalized),
                  imageYNormalized: Value(shot.impact.imageYNormalized),
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
              placementMethod: Value(shot.impact.placementMethod.name),
              visionAnalysisId: Value(shot.impact.visionAnalysisId),
              positionalUncertaintyMm: Value(
                shot.impact.positionalUncertaintyMm,
              ),
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

  Future<void> _linkTrainingActivityRecords(
    TrainingActivityRecord activity,
    SeriesRecord series, {
    String? role,
    String? variantId,
  }) async {
    if (activity.sessionId != null && activity.sessionId != series.sessionId) {
      throw StateError('Activiteit en reeks behoren tot een andere sessie.');
    }
    final existingLinks = await (database.select(
      database.trainingActivitySeriesLinks,
    )..where((row) => row.activityId.equals(activity.id))).get();
    final isTimer = _timerActivityKinds.contains(activity.kind);
    if (isTimer && existingLinks.any((link) => link.seriesId != series.id)) {
      throw StateError('Een timerrun kan aan maximaal één reeks hangen.');
    }
    final existingForSeries = existingLinks
        .where((link) => link.seriesId == series.id)
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
            activityId: activity.id,
            seriesId: series.id,
            sequenceNumber: sequenceNumber,
            role: Value(_nullIfBlank(role)),
            variantId: Value(_nullIfBlank(variantId)),
          ),
        );
    final now = DateTime.now().toUtc();
    await (database.update(
      database.trainingActivities,
    )..where((row) => row.id.equals(activity.id))).write(
      TrainingActivitiesCompanion(
        sessionId: Value(series.sessionId),
        updatedAtUtc: Value(now),
      ),
    );
    await _touchSession(series.sessionId, now);
  }

  Future<void> _deleteTrainingActivitySeriesLink(
    String activityId,
    String seriesId,
  ) =>
      (database.delete(database.trainingActivitySeriesLinks)..where(
            (row) =>
                row.activityId.equals(activityId) &
                row.seriesId.equals(seriesId),
          ))
          .go();

  String? _trainingPlanActivityId(TrainingActivityRecord drill) {
    final configuration = _decodeJsonObject(
      drill.configurationJson,
      'drillconfiguratie',
    );
    final raw = configuration['trainingPlan'];
    if (raw == null) return null;
    if (raw is! Map || raw['planActivityId'] is! String) {
      throw StateError('De opgeslagen trainingsplancontext is ongeldig.');
    }
    return raw['planActivityId']! as String;
  }

  _ValidatedTrainingPlanBinding _validateTrainingPlanBinding({
    required TrainingActivityRecord drill,
    required TrainingActivityRecord plan,
  }) {
    final drillConfiguration = _decodeJsonObject(
      drill.configurationJson,
      'drillconfiguratie',
    );
    final rawContext = drillConfiguration['trainingPlan'];
    final rawPlan = _planSnapshot(plan);
    if (rawContext is! Map) {
      throw StateError('De opgeslagen trainingsplankoppeling is onvolledig.');
    }
    final context = rawContext.cast<Object?, Object?>();
    final planSnapshot = rawPlan.cast<Object?, Object?>();
    final planId = planSnapshot['id'];
    final slotIndex = context['slotIndex'];
    final slotCount = context['slotCount'];
    final slots = planSnapshot['slots'];
    final drillVersionedId = drillConfiguration['drillVersionedId'];
    if (context['planActivityId'] != plan.id ||
        planId is! String ||
        context['planId'] != planId ||
        slotIndex is! int ||
        slotCount is! int ||
        slots is! List ||
        drillVersionedId is! String ||
        slotCount != slots.length) {
      throw StateError('De opgeslagen trainingsplankoppeling is ongeldig.');
    }
    final slotMaps = slots
        .whereType<Map>()
        .map((value) => value.cast<Object?, Object?>())
        .toList(growable: false);
    if (slotMaps.length != slots.length ||
        slotMaps.map((slot) => slot['index']).toSet().length != slots.length) {
      throw StateError('Het opgeslagen trainingsplan bevat ongeldige slots.');
    }
    final matching = slotMaps
        .where((slot) => slot['index'] == slotIndex)
        .toList(growable: false);
    if (matching.length != 1) {
      throw StateError('De opgeslagen planslot bestaat niet.');
    }
    final slotDrill = matching.single['drill'];
    if (slotDrill is! Map ||
        _versionedContentId(slotDrill.cast<Object?, Object?>()) !=
            drillVersionedId) {
      throw StateError('De drillversie komt niet overeen met de planslot.');
    }
    return _ValidatedTrainingPlanBinding(
      planId: planId,
      slotIndex: slotIndex,
      slotCount: slotCount,
      drillVersionedId: drillVersionedId,
      validSlotIndexes: slotMaps
          .map((slot) => slot['index'])
          .whereType<int>()
          .toSet(),
    );
  }

  String? _versionedContentId(Map<Object?, Object?> snapshot) {
    final id = snapshot['id'];
    final version = snapshot['version'];
    return id is String && version is int ? '$id@$version' : null;
  }

  Map<String, Object?> _planSnapshot(TrainingActivityRecord plan) {
    final configuration = _decodeJsonObject(
      plan.configurationJson,
      'trainingsplanconfiguratie',
    );
    final raw = configuration['plan'];
    if (raw is! Map) {
      throw StateError('De opgeslagen trainingsplansnapshot ontbreekt.');
    }
    final snapshot = raw.cast<String, Object?>();
    if (configuration['planId'] != snapshot['id']) {
      throw StateError('De opgeslagen trainingsplanidentiteit is ongeldig.');
    }
    return snapshot;
  }

  void _requireValidStructuredSnapshot(
    TrainingActivityRecord activity, {
    String? summaryJson,
    String? status,
  }) {
    final validation = TrainingActivitySnapshotValidator.validateEncoded(
      kind: activity.kind,
      activitySchemaVersion: activity.schemaVersion,
      configurationJson: activity.configurationJson,
      summaryJson: summaryJson ?? activity.summaryJson,
      status: status ?? activity.status,
    );
    if (!validation.canResume) {
      throw StateError(
        validation.message ??
            'Deze trainingssnapshot kan niet veilig worden hervat.',
      );
    }
  }

  Future<void> _validateGuidedDrillRelations(
    TrainingActivityRecord drill,
    Map<String, Object?> summary, {
    required bool requireCompletion,
  }) async {
    final configuration = _decodeJsonObject(
      drill.configurationJson,
      'drillconfiguratie',
    );
    final rawDrill = configuration['drill'];
    if (rawDrill is! Map) {
      throw StateError('De opgeslagen drillsnapshot ontbreekt.');
    }
    final definition = DrillDefinitionV2.fromJson(
      rawDrill.cast<String, Object?>(),
    );
    final timerIds = _readStringMap(summary['timerActivityIds']);
    for (final entry in timerIds.entries) {
      final timer = await _trainingActivity(entry.value);
      if (timer == null ||
          !_timerActivityKinds.contains(timer.kind) ||
          timer.status != StoredTrainingActivityStatus.completed.name ||
          timer.completedAtUtc == null ||
          drill.sessionId != null &&
              timer.sessionId != null &&
              drill.sessionId != timer.sessionId) {
        throw StateError(
          'Timerfase ${entry.key} verwijst niet naar een geldige '
          'voltooide timerrun.',
        );
      }
    }
    if (!requireCompletion) return;

    final links = await (database.select(
      database.trainingActivitySeriesLinks,
    )..where((row) => row.activityId.equals(drill.id))).get();
    if (summary['linkedSeriesCount'] != links.length) {
      throw StateError(
        'Het opgeslagen reeksaantal komt niet overeen met de echte koppelingen.',
      );
    }
    for (final link in links) {
      final series = await _series(link.seriesId);
      if (series == null ||
          series.status != domain.SeriesStatus.confirmed.name) {
        throw StateError('Een gekoppelde drillreeks is niet bevestigd.');
      }
    }
    final seriesPhases = definition.phases
        .where(
          (phase) =>
              phase.completionKind == DrillPhaseCompletionKind.confirmedSeries,
        )
        .toList(growable: false);
    for (final phase in seriesPhases) {
      final explicit = links.where((link) => link.role == phase.id).length;
      final effective = explicit > 0
          ? explicit
          : seriesPhases.length == 1 && links.every((link) => link.role == null)
          ? links.length
          : 0;
      if (effective < (phase.seriesCount ?? 1)) {
        throw StateError(
          'Reeksfase ${phase.id} mist bevestigde, correct gekoppelde reeksen.',
        );
      }
    }
  }

  Future<void> _validateTrainingPlanRelations(
    TrainingActivityRecord plan,
    Map<String, Object?> summary, {
    required bool requireCompletion,
  }) async {
    final snapshot = _planSnapshot(plan);
    final rawSlots = snapshot['slots'];
    if (rawSlots is! List) {
      throw StateError('Het trainingsplan bevat geen geldige slots.');
    }
    final validSlotIndexes = rawSlots
        .whereType<Map>()
        .map((slot) => slot['index'])
        .whereType<int>()
        .toSet();
    final completedSlots = _readIntList(
      summary['completedSlotIndexes'],
    ).toSet();
    final mappedActivities = _readStringMap(summary['guidedDrillActivityIds']);
    final planLinks = await (database.select(
      database.trainingActivitySeriesLinks,
    )..where((row) => row.activityId.equals(plan.id))).get();
    final planSeriesIds = planLinks.map((link) => link.seriesId).toSet();

    for (final entry in mappedActivities.entries) {
      final slotIndex = int.tryParse(entry.key);
      if (slotIndex == null || !validSlotIndexes.contains(slotIndex)) {
        throw StateError('Het trainingsplan verwijst naar een ongeldige slot.');
      }
      final drill = await _trainingActivity(entry.value);
      if (drill == null ||
          drill.kind != StoredTrainingActivityKind.guidedDrillV2.name) {
        throw StateError(
          'Planslot $slotIndex verwijst niet naar een bestaande V2-drill.',
        );
      }
      final binding = _validateTrainingPlanBinding(drill: drill, plan: plan);
      if (binding.slotIndex != slotIndex) {
        throw StateError('De gekoppelde drill hoort bij een andere planslot.');
      }
      final slotCompleted = completedSlots.contains(slotIndex);
      if ((slotCompleted || requireCompletion) &&
          drill.status != StoredTrainingActivityStatus.completed.name) {
        throw StateError('Planslot $slotIndex bevat geen afgeronde drill.');
      }
      if (slotCompleted || requireCompletion) {
        _requireValidStructuredSnapshot(drill);
        final drillSummary = _decodeJsonObject(
          drill.summaryJson,
          'drillsamenvatting',
        );
        await _validateGuidedDrillRelations(
          drill,
          drillSummary,
          requireCompletion: true,
        );
        final drillLinks = await (database.select(
          database.trainingActivitySeriesLinks,
        )..where((row) => row.activityId.equals(drill.id))).get();
        if (!planSeriesIds.containsAll(
          drillLinks.map((link) => link.seriesId),
        )) {
          throw StateError(
            'Het trainingsplan mist gekoppelde reeksdata van planslot '
            '$slotIndex.',
          );
        }
      }
    }
    if (requireCompletion &&
        (completedSlots.length != validSlotIndexes.length ||
            !completedSlots.containsAll(validSlotIndexes) ||
            mappedActivities.length != validSlotIndexes.length)) {
      throw StateError(
        'Rond eerst iedere planslot met een bevestigde drill af.',
      );
    }
  }

  Future<void> _validateAndCompleteDrill({
    required TrainingActivityRecord drill,
    required String summaryJson,
    required DateTime completedAtUtc,
    required int minimumLinkedSeries,
    String? notes,
  }) async {
    final links = await (database.select(
      database.trainingActivitySeriesLinks,
    )..where((row) => row.activityId.equals(drill.id))).get();
    if (links.length < minimumLinkedSeries) {
      throw StateError(
        'Koppel eerst $minimumLinkedSeries bevestigde '
        '${minimumLinkedSeries == 1 ? 'reeks' : 'reeksen'}.',
      );
    }
    for (final link in links) {
      final series = await _series(link.seriesId);
      if (series == null ||
          series.status != domain.SeriesStatus.confirmed.name) {
        throw StateError('Een gekoppelde reeks is niet bevestigd.');
      }
    }
    final now = DateTime.now().toUtc();
    await (database.update(
      database.trainingActivities,
    )..where((row) => row.id.equals(drill.id))).write(
      TrainingActivitiesCompanion(
        status: Value(StoredTrainingActivityStatus.completed.name),
        summaryJson: Value(summaryJson),
        completedAtUtc: Value(completedAtUtc.toUtc()),
        notes: Value(_nullIfBlank(notes) ?? drill.notes),
        updatedAtUtc: Value(now),
      ),
    );
    if (drill.sessionId != null) await _touchSession(drill.sessionId!, now);
  }

  Future<void> _recordCompletedDrillSlot({
    required TrainingActivityRecord plan,
    required TrainingActivityRecord drill,
    required _ValidatedTrainingPlanBinding binding,
    required DateTime completedAtUtc,
  }) async {
    final summary = _decodeJsonObject(
      plan.summaryJson,
      'trainingsplansamenvatting',
    );
    final completedSlots = _readIntList(
      summary['completedSlotIndexes'],
    ).toSet();
    if (!binding.validSlotIndexes.containsAll(completedSlots)) {
      throw StateError('Het trainingsplan bevat ongeldige voortgang.');
    }
    final drillActivities = <String, String>{
      ..._readStringMap(summary['guidedDrillActivityIds']),
    };
    final existing = drillActivities['${binding.slotIndex}'];
    if (existing != null && existing != drill.id) {
      throw StateError('Deze planslot is al door een andere drill ingevuld.');
    }
    completedSlots.add(binding.slotIndex);
    drillActivities['${binding.slotIndex}'] = drill.id;
    summary
      ..['completedSlotIndexes'] = (completedSlots.toList()..sort())
      ..['guidedDrillActivityIds'] = drillActivities
      ..['slotCount'] = binding.slotCount;
    final allDrillsCompleted =
        completedSlots.containsAll(binding.validSlotIndexes) &&
        completedSlots.length == binding.validSlotIndexes.length;
    if (plan.status == StoredTrainingActivityStatus.completed.name) {
      final completedStepIds = _readStringList(
        summary['completedStepIds'],
      ).toSet();
      final snapshot = _planSnapshot(plan);
      final rawSteps = snapshot['steps'];
      final expectedStepIds = rawSteps is List
          ? rawSteps
                .whereType<Map>()
                .map((step) => step['id'])
                .whereType<String>()
                .toSet()
          : const <String>{};
      if (!allDrillsCompleted ||
          expectedStepIds.isEmpty ||
          !completedStepIds.containsAll(expectedStepIds)) {
        throw StateError('Het afgeronde trainingsplan is inconsistent.');
      }
      return;
    }
    final now = DateTime.now().toUtc();
    await (database.update(
      database.trainingActivities,
    )..where((row) => row.id.equals(plan.id))).write(
      TrainingActivitiesCompanion(
        status: Value(StoredTrainingActivityStatus.draft.name),
        summaryJson: Value(
          _encodeJsonObject(summary, 'trainingsplansamenvatting'),
        ),
        completedAtUtc: const Value(null),
        updatedAtUtc: Value(now),
      ),
    );
    if (plan.sessionId != null) await _touchSession(plan.sessionId!, now);
  }

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

  Future<TrainingActivityRecord> _requireDrillActivity(
    String activityId,
  ) async {
    final activity = await _trainingActivity(activityId);
    if (activity == null) {
      throw ArgumentError('De drillactiviteit bestaat niet meer.');
    }
    if (activity.kind != StoredTrainingActivityKind.guidedDrillV2.name) {
      throw StateError('Deze activiteit is geen drill.');
    }
    return activity;
  }

  Future<TrainingActivityRecord> _requireTrainingPlanActivity(
    String activityId,
  ) async {
    final activity = await _trainingActivity(activityId);
    if (activity == null) {
      throw ArgumentError('Het trainingsplan bestaat niet meer.');
    }
    if (activity.kind != StoredTrainingActivityKind.trainingPlan.name) {
      throw StateError('Deze activiteit is geen trainingsplan.');
    }
    return activity;
  }

  Future<TrainingActivityRecord> _requireLearningPathActivity(
    String activityId,
  ) async {
    final activity = await _trainingActivity(activityId);
    if (activity == null) {
      throw ArgumentError('Het leerpad bestaat niet meer.');
    }
    if (activity.kind != StoredTrainingActivityKind.learningPathV2.name) {
      throw StateError('Deze activiteit is geen V2-leerpad.');
    }
    if (activity.schemaVersion != 2) {
      throw StateError('Deze leerpadversie is alleen-lezen in deze appversie.');
    }
    final snapshot = _learningPathSnapshot(activity);
    _learningPathProgress(activity, snapshot);
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

  Map<String, Object?> _decodeJsonObject(String value, String label) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) throw const FormatException();
      return decoded.cast<String, Object?>();
    } on Object {
      throw StateError('$label bevat geen geldig JSON-object.');
    }
  }

  GuidedTrainingActivityOverview _guidedTrainingActivityOverview(
    TrainingActivityRecord activity,
  ) {
    Map<String, Object?> configuration;
    Map<String, Object?> summary;
    try {
      configuration = _decodeJsonObject(
        activity.configurationJson,
        'trainingsconfiguratie',
      );
    } on Object {
      configuration = const {};
    }
    try {
      summary = _decodeJsonObject(
        activity.summaryJson,
        'trainingssamenvatting',
      );
    } on Object {
      summary = const {};
    }
    final isLegacy = activity.kind == StoredTrainingActivityKind.drill.name;
    final isPlan =
        activity.kind == StoredTrainingActivityKind.trainingPlan.name;
    final drill = configuration['drill'];
    final plan = configuration['plan'];
    final title = switch ((drill, plan)) {
      (final Map<Object?, Object?> value, _) =>
        value['title'] as String? ?? 'Historische drill',
      (_, final Map<Object?, Object?> value) =>
        value['title'] as String? ?? 'Trainingsplan',
      _ => isPlan ? 'Trainingsplan' : 'Historische drill',
    };
    final versionedId = isPlan
        ? configuration['planId'] as String?
        : configuration['drillVersionedId'] as String?;
    final unfinished =
        activity.status == StoredTrainingActivityStatus.draft.name ||
        activity.status == StoredTrainingActivityStatus.interrupted.name;
    final hasResumableSnapshot = _hasResumableTrainingSnapshot(activity);
    return GuidedTrainingActivityOverview(
      activity: activity,
      configuration: Map.unmodifiable(configuration),
      summary: Map.unmodifiable(summary),
      title: title,
      versionedContentId: versionedId,
      canResume: !isLegacy && unfinished && hasResumableSnapshot,
      isLegacyReadOnly: isLegacy,
      isTrainingPlan: isPlan,
    );
  }

  LearningPathActivityOverview _learningPathActivityOverview(
    TrainingActivityRecord activity,
  ) {
    Map<String, Object?> configuration = const {};
    Map<String, Object?> summary = const {};
    try {
      configuration = _decodeJsonObject(
        activity.configurationJson,
        'leerpadconfiguratie',
      );
    } on Object {
      // Malformed history remains visible and read-only.
    }
    try {
      summary = _decodeJsonObject(activity.summaryJson, 'leerpadvoortgang');
    } on Object {
      // Malformed history remains visible and read-only.
    }

    var title = 'Historisch leerpad';
    String? versionedId = configuration['learningPathVersionedId'] as String?;
    var completedEntryIds = const <String>{};
    var currentEntryIndex = 0;
    var totalEntryCount = 0;
    var lessonSnapshotsByEntryId = const <String, TechniqueLessonV2>{};
    var drillSnapshotsByEntryId = const <String, DrillDefinitionV2>{};
    var valid = false;
    try {
      if (activity.schemaVersion != 2) throw const FormatException();
      final snapshot = _learningPathSnapshot(activity);
      final progress = _learningPathProgress(activity, snapshot);
      title = snapshot.path.title;
      versionedId = snapshot.path.versionedId;
      completedEntryIds = Set.unmodifiable(progress.completedEntryIds);
      currentEntryIndex = progress.currentEntryIndex;
      totalEntryCount = snapshot.entryIds.length;
      lessonSnapshotsByEntryId = snapshot.lessonSnapshotsByEntryId;
      drillSnapshotsByEntryId = snapshot.drillSnapshotsByEntryId;
      valid = true;
    } on Object {
      final rawPath = configuration['learningPath'];
      if (rawPath is Map) {
        final rawTitle = rawPath['title'];
        if (rawTitle is String && rawTitle.trim().isNotEmpty) {
          title = rawTitle.trim();
        }
      }
    }
    final unfinished =
        activity.status == StoredTrainingActivityStatus.draft.name ||
        activity.status == StoredTrainingActivityStatus.interrupted.name;
    return LearningPathActivityOverview(
      activity: activity,
      configuration: Map.unmodifiable(configuration),
      summary: Map.unmodifiable(summary),
      title: title,
      versionedContentId: versionedId,
      completedEntryIds: completedEntryIds,
      currentEntryIndex: currentEntryIndex,
      totalEntryCount: totalEntryCount,
      lessonSnapshotsByEntryId: lessonSnapshotsByEntryId,
      drillSnapshotsByEntryId: drillSnapshotsByEntryId,
      canResume: valid && unfinished,
    );
  }

  _ValidatedLearningPathSnapshot _learningPathSnapshot(
    TrainingActivityRecord activity,
  ) {
    if (activity.kind != StoredTrainingActivityKind.learningPathV2.name) {
      throw StateError('Deze activiteit is geen V2-leerpad.');
    }
    final configuration = _decodeJsonObject(
      activity.configurationJson,
      'leerpadconfiguratie',
    );
    final versionedId = configuration['learningPathVersionedId'];
    final rawPath = configuration['learningPath'];
    if (versionedId is! String || rawPath is! Map) {
      throw StateError('Het leerpad bevat geen volledige inhoudssnapshot.');
    }
    try {
      final pathOnly = _validateLearningPathSnapshot(
        learningPathVersionedId: versionedId,
        learningPathSnapshot: rawPath.cast<String, Object?>(),
      );
      final hasPersistedEntrySnapshots = configuration.containsKey(
        'entrySnapshots',
      );
      final rawEntrySnapshots = hasPersistedEntrySnapshots
          ? configuration['entrySnapshots']
          : _createLearningPathEntrySnapshots(pathOnly.path);
      return _validateLearningPathSnapshot(
        learningPathVersionedId: versionedId,
        learningPathSnapshot: rawPath.cast<String, Object?>(),
        rawEntrySnapshots: rawEntrySnapshots,
        requireEntrySnapshots: true,
      );
    } on ArgumentError catch (error) {
      throw StateError('De opgeslagen leerpadsnapshot is ongeldig: $error');
    } on Object {
      throw StateError('De opgeslagen leerpadsnapshot is ongeldig.');
    }
  }

  _ValidatedLearningPathSnapshot _validateLearningPathSnapshot({
    required String learningPathVersionedId,
    required Map<String, Object?> learningPathSnapshot,
    Object? rawEntrySnapshots,
    bool requireEntrySnapshots = false,
  }) {
    final path = LearningPathV2.fromJson(learningPathSnapshot);
    if (learningPathVersionedId != path.versionedId) {
      throw ArgumentError(
        'De leerpad-ID komt niet overeen met de inhoudssnapshot.',
      );
    }
    final entryIds = path.entries.map((entry) => entry.id).toList();
    if (entryIds.length != entryIds.toSet().length) {
      throw ArgumentError('Een leerpad bevat dubbele onderdeel-ID’s.');
    }
    final known = <String>{};
    for (final entry in path.entries) {
      if (entry.prerequisiteEntryIds.any((id) => !known.contains(id))) {
        throw ArgumentError(
          'Een leerpadvoorwaarde verwijst niet naar een eerder onderdeel.',
        );
      }
      known.add(entry.id);
    }
    final lessonSnapshots = <String, TechniqueLessonV2>{};
    final drillSnapshots = <String, DrillDefinitionV2>{};
    if (rawEntrySnapshots == null) {
      if (requireEntrySnapshots) {
        throw ArgumentError('Het leerpad mist volledige onderdeelsnapshots.');
      }
    } else {
      if (rawEntrySnapshots is! List ||
          rawEntrySnapshots.length != path.entries.length) {
        throw ArgumentError(
          'Het leerpad bevat geen volledige lijst onderdeelsnapshots.',
        );
      }
      for (var index = 0; index < path.entries.length; index++) {
        final entry = path.entries[index];
        final rawSnapshot = rawEntrySnapshots[index];
        if (rawSnapshot is! Map) {
          throw ArgumentError('Een leerpadonderdeelsnapshot is ongeldig.');
        }
        final snapshot = rawSnapshot.cast<String, Object?>();
        if (snapshot['entryId'] != entry.id ||
            snapshot['kind'] != entry.kind.name ||
            snapshot['versionedContentId'] != entry.versionedContentId ||
            snapshot['content'] is! Map) {
          throw ArgumentError(
            'Een leerpadonderdeelsnapshot hoort niet bij de opgeslagen stap.',
          );
        }
        final content = (snapshot['content']! as Map).cast<String, Object?>();
        switch (entry.kind) {
          case LearningPathEntryKind.lesson:
            final lesson = TechniqueLessonV2.fromJson(content);
            if (lesson.versionedId != entry.versionedContentId) {
              throw ArgumentError(
                'De lessnapshot heeft een andere inhoudsversie.',
              );
            }
            lessonSnapshots[entry.id] = lesson;
          case LearningPathEntryKind.drill:
            final drill = DrillDefinitionV2.fromJson(content);
            if (drill.versionedId != entry.versionedContentId) {
              throw ArgumentError(
                'De drillsnapshot heeft een andere inhoudsversie.',
              );
            }
            drillSnapshots[entry.id] = drill;
        }
      }
    }
    return _ValidatedLearningPathSnapshot(
      path: path,
      entryIds: List.unmodifiable(entryIds),
      lessonSnapshotsByEntryId: Map.unmodifiable(lessonSnapshots),
      drillSnapshotsByEntryId: Map.unmodifiable(drillSnapshots),
    );
  }

  List<Map<String, Object?>> _createLearningPathEntrySnapshots(
    LearningPathV2 path,
  ) {
    final catalog = BuiltInTrainingContent.catalog;
    return List.unmodifiable(
      path.entries.map((entry) {
        final content = switch (entry.kind) {
          LearningPathEntryKind.lesson =>
            catalog.lessonByVersionedId(entry.versionedContentId)?.toJson(),
          LearningPathEntryKind.drill =>
            catalog.drillByVersionedId(entry.versionedContentId)?.toJson(),
        };
        if (content == null) {
          throw ArgumentError(
            'Inhoud ${entry.versionedContentId} kan niet volledig worden opgeslagen.',
          );
        }
        return <String, Object?>{
          'entryId': entry.id,
          'kind': entry.kind.name,
          'versionedContentId': entry.versionedContentId,
          'content': content,
        };
      }),
    );
  }

  _LearningPathProgress _learningPathProgress(
    TrainingActivityRecord activity,
    _ValidatedLearningPathSnapshot snapshot,
  ) {
    final summary = _decodeJsonObject(activity.summaryJson, 'leerpadvoortgang');
    final rawCompleted = summary['completedEntryIds'];
    final currentIndex = summary['currentEntryIndex'];
    if (rawCompleted is! List || currentIndex is! int) {
      throw StateError('De opgeslagen leerpadvoortgang is onvolledig.');
    }
    final completed = rawCompleted.whereType<String>().toList(growable: false);
    if (completed.length != rawCompleted.length ||
        completed.length != completed.toSet().length ||
        completed.any((id) => !snapshot.entryIds.contains(id))) {
      throw StateError('De opgeslagen leerpadvoortgang is ongeldig.');
    }
    final completedSet = completed.toSet();
    final firstIncomplete = snapshot.entryIds.indexWhere(
      (id) => !completedSet.contains(id),
    );
    final expectedIndex = firstIncomplete < 0
        ? snapshot.entryIds.length
        : firstIncomplete;
    if (currentIndex != expectedIndex) {
      throw StateError(
        'De huidige leerpadstap komt niet overeen met de voortgang.',
      );
    }
    return _LearningPathProgress(
      completedEntryIds: List.unmodifiable(completed),
      currentEntryIndex: currentIndex,
    );
  }

  Future<void> _requireCompletedLearningPathDrillEvidence({
    required TrainingActivityRecord activity,
    required _ValidatedLearningPathSnapshot snapshot,
    required Set<String> completedEntryIds,
  }) async {
    final requestedDrills = snapshot.path.entries
        .where(
          (entry) =>
              entry.kind == LearningPathEntryKind.drill &&
              completedEntryIds.contains(entry.id),
        )
        .toList(growable: false);
    if (requestedDrills.isEmpty) return;
    final completedActivities =
        await (database.select(database.trainingActivities)..where(
              (row) =>
                  row.kind.equals(
                    StoredTrainingActivityKind.guidedDrillV2.name,
                  ) &
                  row.status.equals(
                    StoredTrainingActivityStatus.completed.name,
                  ),
            ))
            .get();
    final completedVersionedIds = <String>{};
    for (final candidate in completedActivities) {
      if (candidate.completedAtUtc == null ||
          candidate.completedAtUtc!.toUtc().isBefore(
            activity.startedAtUtc.toUtc(),
          )) {
        continue;
      }
      try {
        final configuration = _decodeJsonObject(
          candidate.configurationJson,
          'drillconfiguratie',
        );
        final versionedId = configuration['drillVersionedId'];
        if (versionedId is String) completedVersionedIds.add(versionedId);
      } on Object {
        continue;
      }
    }
    final missing = requestedDrills
        .where(
          (entry) => !completedVersionedIds.contains(entry.versionedContentId),
        )
        .map((entry) => entry.id)
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError(
        'Rond de begeleide drill eerst af voordat dit onderdeel telt.',
      );
    }
  }

  bool _hasResumableTrainingSnapshot(TrainingActivityRecord activity) {
    if (activity.kind != StoredTrainingActivityKind.guidedDrillV2.name &&
        activity.kind != StoredTrainingActivityKind.trainingPlan.name) {
      return false;
    }
    return TrainingActivitySnapshotValidator.validateEncoded(
      kind: activity.kind,
      activitySchemaVersion: activity.schemaVersion,
      configurationJson: activity.configurationJson,
      summaryJson: activity.summaryJson,
      status: activity.status,
    ).canResume;
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

  _ValidatedPhotoAlignment _validateAlignment(
    domain.StoredPhotoAlignment alignment, {
    required domain.TargetProfile target,
  }) {
    final reportedStatus = alignment.planarityStatus.trim().toLowerCase();
    if (reportedStatus == 'rejected' ||
        reportedStatus == 'unstable' ||
        reportedStatus == 'unknown') {
      throw StateError('Deze uitlijning is afgekeurd of numeriek onstabiel.');
    }
    final mode = switch (alignment.alignmentMode.trim()) {
      'fullCard' || 'fourCorners' => geo.PhotoAlignmentMode.fourCorners,
      'ringAssisted' => geo.PhotoAlignmentMode.ringAssisted,
      _ => throw StateError('Onbekende foto-uitlijningsmodus.'),
    };
    Object? decodedAnchors;
    if (alignment.anchorsJson != null) {
      try {
        decodedAnchors = jsonDecode(alignment.anchorsJson!);
      } on Object {
        throw StateError('De opgeslagen uitlijningsankers zijn ongeldig.');
      }
      if (decodedAnchors is! List) {
        throw StateError('De opgeslagen uitlijningsankers zijn ongeldig.');
      }
    } else if (mode == geo.PhotoAlignmentMode.ringAssisted) {
      throw StateError('Ringuitlijning vereist opgeslagen ankers.');
    }

    final points = alignment.orderedCorners
        .map((point) => geo.NormalizedPoint(point.x, point.y))
        .toList(growable: false);
    final payload = <String, Object?>{
      'schemaVersion': geo.photoAlignmentSchemaVersion,
      'algorithmVersion': alignment.algorithmVersion,
      'alignmentMode': mode.name,
      'anchors': ?decodedAnchors,
      'cardWidthMm': target.physicalCardWidthMm,
      'cardHeightMm': target.physicalCardHeightMm,
      'corners': geo.NormalizedQuad.fromOrderedPoints(points).toJson(),
      'homographyMatrix': alignment.homographyMatrix,
      'rotationQuarterTurns': alignment.rotationQuarterTurns,
    };
    late final geo.ManualPhotoAlignment geometry;
    try {
      geometry = geo.ManualPhotoAlignment.fromJson(payload);
    } on Object catch (error) {
      throw StateError('De foto-uitlijning is ongeldig: $error');
    }
    final residuals = geometry.residuals;
    if (!residuals.conditionEstimate.isFinite ||
        residuals.conditionEstimate > 1e10) {
      throw StateError('De foto-uitlijning is numeriek onstabiel.');
    }
    for (final pair in [
      (alignment.reprojectionRmsMm, residuals.rmsMm),
      (alignment.reprojectionMaxMm, residuals.maximumMm),
    ]) {
      final supplied = pair.$1;
      if (supplied != null &&
          (supplied - pair.$2).abs() > _alignmentPreviewToleranceMm) {
        throw StateError(
          'De opgegeven uitlijningsresiduen wijken af van de '
          'autoritatieve herberekening.',
        );
      }
    }
    final planarityStatus = switch ((residuals.rmsMm, residuals.maximumMm)) {
      (final rms, final maximum) when rms <= 0.75 && maximum <= 1.5 =>
        'accepted',
      (final rms, final maximum) when rms <= 1.5 && maximum <= 3.0 =>
        'manualReviewOnly',
      _ => throw StateError(
        'De foto-uitlijning overschrijdt de toegestane foutmarge.',
      ),
    };
    return _ValidatedPhotoAlignment(
      geometry: geometry,
      persistedMode: mode == geo.PhotoAlignmentMode.fourCorners
          ? 'fullCard'
          : 'ringAssisted',
      anchorsJson: jsonEncode(
        geometry.anchors.map((anchor) => anchor.toJson()).toList(),
      ),
      planarityStatus: planarityStatus,
      confirmedAtUtc:
          alignment.confirmedAtUtc?.toUtc() ?? alignment.updatedAtUtc.toUtc(),
    );
  }

  _PersistedPhotoAlignment? _tryDecodePersistedAlignment(
    PhotoAlignmentRecord record, {
    required domain.TargetProfile target,
  }) {
    try {
      final matrix = (jsonDecode(record.matrixJson) as List<Object?>)
          .map((value) => (value! as num).toDouble())
          .toList(growable: false);
      if (record.rotationQuarterTurns < 0 ||
          record.rotationQuarterTurns > 3 ||
          target.physicalCardWidthMm <= 0 ||
          target.physicalCardHeightMm <= 0) {
        return null;
      }
      return _PersistedPhotoAlignment(
        transform: geo.ProjectiveTransform(matrix),
        rotationQuarterTurns: record.rotationQuarterTurns,
      );
    } on Object {
      // A malformed legacy alignment must not be allowed to redefine the
      // canonical source coordinate. The new alignment remains authoritative.
      return null;
    }
  }

  geo.NormalizedPoint _canonicalOriginalSourcePoint({
    required ImpactRecord existing,
    required geo.NormalizedPoint storedSourcePoint,
    required _PersistedPhotoAlignment? previousAlignment,
  }) {
    if (previousAlignment == null ||
        previousAlignment.rotationQuarterTurns == 0) {
      return storedSourcePoint;
    }

    // Schema 8 defines stored image coordinates in the immutable original
    // EXIF-normalized image. A short-lived pre-schema implementation stored
    // coordinates in the rotated view. Detect that representation against the
    // previous physical position and migrate it deterministically.
    final canonicalProjection = previousAlignment.fromOriginal(
      storedSourcePoint,
    );
    final legacyProjection = previousAlignment.fromDisplayed(storedSourcePoint);
    final canonicalError = math.sqrt(
      math.pow(canonicalProjection.x - existing.xMm, 2) +
          math.pow(canonicalProjection.y - existing.yMm, 2),
    );
    final legacyError = math.sqrt(
      math.pow(legacyProjection.x - existing.xMm, 2) +
          math.pow(legacyProjection.y - existing.yMm, 2),
    );
    if (legacyError + _alignmentPreviewToleranceMm < canonicalError &&
        legacyError <= 3.0) {
      return geo.unrotateNormalizedPoint(
        storedSourcePoint,
        previousAlignment.rotationQuarterTurns,
      );
    }
    return storedSourcePoint;
  }

  domain.ShotImpact _domainImpact(ImpactRecord record) => domain.ShotImpact(
    id: record.id,
    xMm: record.xMm,
    yMm: record.yMm,
    sourceImageId: record.sourceImageId,
    imageXNormalized: record.imageXNormalized,
    imageYNormalized: record.imageYNormalized,
    multiplicity: record.multiplicity,
    isMiss: record.isMiss,
    isPositionUncertain: record.isPositionUncertain,
    targetBullId: record.targetBullId,
    rawScoreValue: record.rawScoreValue,
    scoreDisposition: domain.ScoreDisposition.values.byName(
      record.scoreDisposition,
    ),
    placementMethod: domain.ImpactPlacementMethod.values.byName(
      record.placementMethod,
    ),
    visionAnalysisId: record.visionAnalysisId,
    positionalUncertaintyMm: record.positionalUncertaintyMm,
  );

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
      existing.isPositionUncertain == resulting.isPositionUncertain &&
      existing.placementMethod == resulting.placementMethod.name &&
      existing.visionAnalysisId == resulting.visionAnalysisId &&
      existing.positionalUncertaintyMm == resulting.positionalUncertaintyMm;

  bool _sameStoredImpact(ImpactRecord existing, domain.ShotImpact resulting) =>
      _sameImpactMetadata(existing, resulting) &&
      existing.targetBullId == resulting.targetBullId &&
      existing.rawScoreValue == resulting.rawScoreValue &&
      existing.scoreDisposition == resulting.scoreDisposition.name &&
      existing.xMm == resulting.xMm &&
      existing.yMm == resulting.yMm;

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

List<int> _readIntList(Object? value) => switch (value) {
  final List<dynamic> items => items.whereType<int>().toList(growable: false),
  _ => const [],
};

List<String> _readStringList(Object? value) => switch (value) {
  final List<dynamic> items => items.whereType<String>().toList(
    growable: false,
  ),
  _ => const [],
};

Map<String, String> _readStringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

class _ValidatedTrainingPlanBinding {
  const _ValidatedTrainingPlanBinding({
    required this.planId,
    required this.slotIndex,
    required this.slotCount,
    required this.drillVersionedId,
    required this.validSlotIndexes,
  });

  final String planId;
  final int slotIndex;
  final int slotCount;
  final String drillVersionedId;
  final Set<int> validSlotIndexes;
}

class _ValidatedLearningPathSnapshot {
  const _ValidatedLearningPathSnapshot({
    required this.path,
    required this.entryIds,
    required this.lessonSnapshotsByEntryId,
    required this.drillSnapshotsByEntryId,
  });

  final LearningPathV2 path;
  final List<String> entryIds;
  final Map<String, TechniqueLessonV2> lessonSnapshotsByEntryId;
  final Map<String, DrillDefinitionV2> drillSnapshotsByEntryId;
}

class _LearningPathProgress {
  const _LearningPathProgress({
    required this.completedEntryIds,
    required this.currentEntryIndex,
  });

  final List<String> completedEntryIds;
  final int currentEntryIndex;
}

const double _alignmentPreviewToleranceMm = 0.05;

class _ValidatedPhotoAlignment {
  const _ValidatedPhotoAlignment({
    required this.geometry,
    required this.persistedMode,
    required this.anchorsJson,
    required this.planarityStatus,
    required this.confirmedAtUtc,
  });

  final geo.ManualPhotoAlignment geometry;
  final String persistedMode;
  final String anchorsJson;
  final String planarityStatus;
  final DateTime confirmedAtUtc;
}

class _PersistedPhotoAlignment {
  const _PersistedPhotoAlignment({
    required this.transform,
    required this.rotationQuarterTurns,
  });

  final geo.ProjectiveTransform transform;
  final int rotationQuarterTurns;

  geo.PhysicalPointMm fromOriginal(geo.NormalizedPoint original) {
    final displayed = geo.rotateNormalizedPoint(original, rotationQuarterTurns);
    return fromDisplayed(displayed);
  }

  geo.PhysicalPointMm fromDisplayed(geo.NormalizedPoint displayed) {
    final mapped = transform.apply(
      geo.TransformPoint(displayed.x, displayed.y),
    );
    return geo.PhysicalPointMm(mapped.x, mapped.y);
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
