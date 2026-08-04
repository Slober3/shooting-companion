import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/appearance_repository.dart';

final appearanceRepositoryProvider = Provider<AppearanceRepository>(
  (ref) => AppearanceRepository(ref.watch(databaseProvider)),
);

final appearanceSettingsProvider = StreamProvider<AppearanceSettings>(
  (ref) => ref.watch(appearanceRepositoryProvider).watchSettings(),
);
