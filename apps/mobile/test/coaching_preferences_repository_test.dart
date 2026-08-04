import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/coaching_preferences_repository.dart';

void main() {
  late AppDatabase database;
  late CoachingPreferencesRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CoachingPreferencesRepository(database);
  });

  tearDown(() => database.close());

  test('coach mode is opt-in and disabled by default', () async {
    expect(await repository.readCoachMode(), isFalse);
  });

  test('coach mode is persisted in the shared preferences table', () async {
    await repository.setCoachMode(true);

    expect(await repository.readCoachMode(), isTrue);
    final record =
        await (database.select(database.preferences)..where(
              (row) =>
                  row.key.equals(CoachingPreferencesRepository.coachModeKey),
            ))
            .getSingle();
    expect(record.value, 'true');

    await repository.setCoachMode(false);
    expect(await repository.readCoachMode(), isFalse);
  });

  test('coach mode stream emits preference changes', () async {
    final values = <bool>[];
    final subscription = repository.watchCoachMode().listen(values.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    await repository.setCoachMode(true);
    await Future<void>.delayed(Duration.zero);

    expect(values, [false, true]);
  });
}
