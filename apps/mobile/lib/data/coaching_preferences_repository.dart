import 'app_database.dart';

class CoachingPreferencesRepository {
  CoachingPreferencesRepository(this._database);

  static const coachModeKey = 'coaching.mode.enabled';

  final AppDatabase _database;

  Stream<bool> watchCoachMode() =>
      (_database.select(_database.preferences)
            ..where((row) => row.key.equals(coachModeKey)))
          .watchSingleOrNull()
          .map((record) => record?.value == 'true')
          .distinct();

  Future<bool> readCoachMode() async =>
      (await (_database.select(
            _database.preferences,
          )..where((row) => row.key.equals(coachModeKey))).getSingleOrNull())
          ?.value ==
      'true';

  Future<void> setCoachMode(bool enabled) => _database
      .into(_database.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(
          key: coachModeKey,
          value: enabled.toString(),
        ),
      );
}
