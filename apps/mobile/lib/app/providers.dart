import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/shooting_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final repositoryProvider = Provider<ShootingRepository>(
  (ref) => ShootingRepository(ref.watch(databaseProvider)),
);

final initializationProvider = FutureProvider<void>(
  (ref) => ref.watch(repositoryProvider).seedDefaults(),
);

final sessionsProvider = StreamProvider<List<SessionRecord>>(
  (ref) => ref.watch(repositoryProvider).watchSessions(),
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

final firearmsProvider = StreamProvider<List<FirearmRecord>>(
  (ref) => ref.watch(repositoryProvider).watchFirearms(),
);

final cartridgesProvider = StreamProvider<List<CartridgeRecord>>(
  (ref) => ref.watch(repositoryProvider).watchCartridges(),
);

final ammoLotsProvider = StreamProvider<List<AmmoLotRecord>>(
  (ref) => ref.watch(repositoryProvider).watchAmmoLots(),
);

final rangesProvider = StreamProvider<List<RangeRecord>>(
  (ref) => ref.watch(repositoryProvider).watchRanges(),
);

final targetProfilesProvider = StreamProvider<List<TargetProfileRecord>>(
  (ref) => ref.watch(repositoryProvider).watchTargetProfiles(),
);
