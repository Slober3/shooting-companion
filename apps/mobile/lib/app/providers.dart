import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/coaching_preferences_repository.dart';
import '../data/shooting_repository.dart';
import '../data/vision_scan_repository.dart';
import '../features/progress/analysis_context.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';
import 'package:shooting_companion_vision_ffi/vision_ffi.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final repositoryProvider = Provider<ShootingRepository>(
  (ref) => ShootingRepository(ref.watch(databaseProvider)),
);

final visionScanRepositoryProvider = Provider<VisionScanRepository>(
  (ref) => VisionScanRepository(ref.watch(databaseProvider)),
);

final visionAnalyzerProvider = Provider<VisionAnalyzer>(
  (ref) => VisionFfiAnalyzer(),
);

final visionCapabilitiesProvider = FutureProvider<VisionAnalyzerCapabilities>(
  (ref) => ref.watch(visionAnalyzerProvider).capabilities(),
);

final visionScanDraftsProvider = StreamProvider<List<VisionScanDraftRecord>>(
  (ref) => ref.watch(visionScanRepositoryProvider).watchDrafts(),
);

final visionScanDraftCountProvider = StreamProvider<int>(
  (ref) => ref.watch(visionScanRepositoryProvider).watchDraftCount(),
);

final visionScanDraftProvider =
    StreamProvider.family<VisionScanDraftRecord?, String>(
      (ref, scanId) =>
          ref.watch(visionScanRepositoryProvider).watchDraft(scanId),
    );

final coachingPreferencesRepositoryProvider =
    Provider<CoachingPreferencesRepository>(
      (ref) => CoachingPreferencesRepository(ref.watch(databaseProvider)),
    );

final coachModeEnabledProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(coachingPreferencesRepositoryProvider).watchCoachMode(),
);

final initializationProvider = FutureProvider<void>(
  (ref) => ref.watch(repositoryProvider).seedDefaults(),
);

final sessionsProvider = StreamProvider<List<SessionRecord>>(
  (ref) => ref.watch(repositoryProvider).watchSessions(),
);

final sessionListItemsProvider =
    StreamProvider.family<List<SessionListItem>, SessionListFilters>(
      (ref, filters) =>
          ref.watch(repositoryProvider).watchSessionListItems(filters),
    );

final activeSessionProvider = StreamProvider<SessionRecord?>(
  (ref) => ref.watch(repositoryProvider).watchActiveSession(),
);

final sessionDetailProvider = StreamProvider.family<SessionDetail?, String>(
  (ref, sessionId) =>
      ref.watch(repositoryProvider).watchSessionDetail(sessionId),
);

final seriesProvider = StreamProvider.family<List<SeriesRecord>, String>(
  (ref, sessionId) => ref.watch(repositoryProvider).watchSeries(sessionId),
);

final confirmedSeriesProvider = StreamProvider<List<SeriesRecord>>(
  (ref) => ref.watch(repositoryProvider).watchConfirmedSeries(),
);

final analysisDatasetProvider = StreamProvider<List<AnalysisSeriesData>>(
  (ref) => ref.watch(repositoryProvider).watchAnalysisDataset(),
);

final analysisContextCatalogProvider =
    Provider<AsyncValue<AnalysisContextCatalog>>(
      (ref) => ref
          .watch(analysisDatasetProvider)
          .whenData(AnalysisContextCatalog.fromDataset),
    );

final seriesAnalysisContextProvider =
    Provider.family<AsyncValue<SeriesAnalysisContext?>, String>(
      (ref, seriesId) => ref
          .watch(analysisContextCatalogProvider)
          .whenData((catalog) => catalog.series(seriesId)),
    );

final sessionAnalysisContextProvider =
    Provider.family<AsyncValue<SessionAnalysisContext?>, String>(
      (ref, sessionId) => ref
          .watch(analysisContextCatalogProvider)
          .whenData((catalog) => catalog.session(sessionId)),
    );

final comparableSeriesAnalysisContextProvider =
    Provider.family<AsyncValue<ComparableSeriesAnalysisContext?>, String>(
      (ref, seriesId) => ref
          .watch(analysisContextCatalogProvider)
          .whenData((catalog) => catalog.comparableForSeries(seriesId)),
    );

final activeGoalsProvider = StreamProvider<List<GoalRecord>>(
  (ref) => ref.watch(repositoryProvider).watchGoals(activeOnly: true),
);

final allGoalsProvider = StreamProvider<List<GoalRecord>>(
  (ref) => ref.watch(repositoryProvider).watchGoals(),
);

final seriesReflectionProvider =
    StreamProvider.family<SeriesReflectionRecord?, String>(
      (ref, seriesId) =>
          ref.watch(repositoryProvider).watchSeriesReflection(seriesId),
    );

final seriesReflectionsProvider = StreamProvider<List<SeriesReflectionRecord>>(
  (ref) => ref.watch(repositoryProvider).watchSeriesReflections(),
);

final coachFeedbackProvider = StreamProvider<List<CoachFeedbackRecord>>(
  (ref) => ref.watch(repositoryProvider).watchCoachFeedback(),
);

final trainingActivitiesProvider = StreamProvider<List<TrainingActivityRecord>>(
  (ref) => ref.watch(repositoryProvider).watchTrainingActivities(),
);

final resumableDrillActivitiesProvider =
    StreamProvider<List<TrainingActivityRecord>>(
      (ref) => ref.watch(repositoryProvider).watchResumableDrillActivities(),
    );

final resumableTrainingPlansProvider =
    StreamProvider<List<TrainingActivityRecord>>(
      (ref) => ref.watch(repositoryProvider).watchResumableTrainingPlans(),
    );

/// The sole current plan used by the Start resume action. History and drill
/// lists keep their plural providers; starting/resuming a plan never guesses
/// between multiple active records.
final activeTrainingPlanProvider = StreamProvider<TrainingActivityRecord?>(
  (ref) => ref.watch(repositoryProvider).watchActiveTrainingPlan(),
);

/// The sole unfinished learning path. Its embedded content snapshot remains
/// authoritative when the bundled catalog changes after a process restart.
final activeLearningPathProvider =
    StreamProvider<LearningPathActivityOverview?>(
      (ref) => ref.watch(repositoryProvider).watchActiveLearningPath(),
    );

final learningPathActivityOverviewsProvider =
    StreamProvider<List<LearningPathActivityOverview>>(
      (ref) =>
          ref.watch(repositoryProvider).watchLearningPathActivityOverviews(),
    );

/// One authoritative feed for V2 drill/plan resume cards and read-only
/// history. The repository owns JSON decoding and prevents legacy V1 drills
/// from being resumed as if they were V2 runs.
final guidedTrainingActivityOverviewsProvider =
    StreamProvider<List<GuidedTrainingActivityOverview>>(
      (ref) =>
          ref.watch(repositoryProvider).watchGuidedTrainingActivityOverviews(),
    );

final trainingActivityProvider =
    StreamProvider.family<TrainingActivityDetail?, String>(
      (ref, activityId) =>
          ref.watch(repositoryProvider).watchTrainingActivity(activityId),
    );

final seriesTrainingActivitiesProvider =
    StreamProvider.family<List<TrainingActivityRecord>, String>(
      (ref, seriesId) =>
          ref.watch(repositoryProvider).watchSeriesTrainingActivities(seriesId),
    );

final sessionTrainingActivitiesProvider =
    StreamProvider.family<List<TrainingActivityRecord>, String>(
      (ref, sessionId) => ref
          .watch(repositoryProvider)
          .watchSessionTrainingActivities(sessionId),
    );

final timerPresetsProvider = StreamProvider<List<TimerPresetRecord>>(
  (ref) => ref.watch(repositoryProvider).watchTimerPresets(),
);

final acousticCalibrationProfilesProvider =
    StreamProvider<List<AcousticCalibrationProfileRecord>>(
      (ref) => ref.watch(repositoryProvider).watchAcousticCalibrationProfiles(),
    );

final seriesDetailProvider = StreamProvider.family<SeriesDetail?, String>(
  (ref, seriesId) => ref.watch(repositoryProvider).watchSeriesDetail(seriesId),
);

final impactsProvider = StreamProvider.family<List<ImpactRecord>, String>(
  (ref, seriesId) => ref.watch(repositoryProvider).watchImpacts(seriesId),
);

final sessionImagesProvider =
    StreamProvider.family<List<ImageAssetRecord>, String>(
      (ref, sessionId) =>
          ref.watch(repositoryProvider).watchSessionImages(sessionId),
    );

final seriesImagesProvider =
    StreamProvider.family<List<ImageAssetRecord>, String>(
      (ref, seriesId) =>
          ref.watch(repositoryProvider).watchSeriesImages(seriesId),
    );

final imageProvider = StreamProvider.family<ImageAssetRecord?, String>(
  (ref, imageId) => ref.watch(repositoryProvider).watchImage(imageId),
);

final firearmsProvider = StreamProvider<List<FirearmRecord>>(
  (ref) => ref.watch(repositoryProvider).watchFirearms(),
);

final allFirearmsProvider = StreamProvider<List<FirearmRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAllFirearms(),
);

final cartridgesProvider = StreamProvider<List<CartridgeRecord>>(
  (ref) => ref.watch(repositoryProvider).watchCartridges(),
);

final allCartridgesProvider = StreamProvider<List<CartridgeRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAllCartridges(),
);

final ammoLotsProvider = StreamProvider<List<AmmoLotRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAmmoLots(),
);

final allAmmoLotsProvider = StreamProvider<List<AmmoLotRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAllAmmoLots(),
);

final rangesProvider = StreamProvider<List<RangeRecord>>(
  (ref) => ref.watch(repositoryProvider).watchRanges(),
);

final allRangesProvider = StreamProvider<List<RangeRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAllRanges(),
);

final targetProfilesProvider = StreamProvider<List<TargetProfileRecord>>(
  (ref) => ref.watch(repositoryProvider).watchTargetProfiles(),
);

final allTargetProfilesProvider = StreamProvider<List<TargetProfileRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAllTargetProfiles(),
);
