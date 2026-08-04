import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/appearance_repository.dart';

void main() {
  late AppDatabase database;
  late AppearanceRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AppearanceRepository(database);
  });

  tearDown(() => database.close());

  test('uses the offline defaults when no preferences exist', () async {
    expect(await repository.readSettings(), const AppearanceSettings());
  });

  test('persists mode and palette atomically', () async {
    const expected = AppearanceSettings(
      mode: AppearanceMode.dark,
      palette: AppearancePalette.steelBlue,
    );

    await repository.save(expected);

    expect(await repository.readSettings(), expected);
    final records = await database.select(database.preferences).get();
    expect(
      {for (final record in records) record.key: record.value},
      {
        AppearanceRepository.modePreferenceKey: 'dark',
        AppearanceRepository.palettePreferenceKey: 'steelBlue',
      },
    );
  });

  test('watch emits a changed selection', () async {
    final values = <AppearanceSettings>[];
    final subscription = repository.watchSettings().listen(values.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    await repository.save(
      const AppearanceSettings(
        mode: AppearanceMode.light,
        palette: AppearancePalette.forestGreen,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(values.first, const AppearanceSettings());
    expect(
      values.last,
      const AppearanceSettings(
        mode: AppearanceMode.light,
        palette: AppearancePalette.forestGreen,
      ),
    );
  });

  test('honours legacy v1 theme and safely ignores unknown values', () async {
    await database.customStatement(
      "INSERT INTO preferences (key, value) VALUES ('theme', 'dark')",
    );
    expect((await repository.readSettings()).mode, AppearanceMode.dark);

    await database.customStatement(
      "INSERT OR REPLACE INTO preferences (key, value) "
      "VALUES ('appearance.mode', 'future-mode'), "
      "('appearance.palette', 'future-palette')",
    );
    expect(await repository.readSettings(), const AppearanceSettings());
  });
}
