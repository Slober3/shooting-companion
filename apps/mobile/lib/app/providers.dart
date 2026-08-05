import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/coaching_preferences_repository.dart';
import '../data/shooting_repository.dart';
import '../features/progress/analysis_context.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final repositoryProvider = Provider<ShootingRepository>(
  (ref) => ShootingRepository(ref.watch(databaseProvider)),
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
