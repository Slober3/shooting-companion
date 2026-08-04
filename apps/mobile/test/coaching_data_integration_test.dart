import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
    await repository.seedDefaults();
  });

  tearDown(() => database.close());

  test('goal save rejects invalid values and an unknown target', () async {
    final target = (await database.select(database.targetProfiles).get()).first;
    final goalId = await repository.saveGoal(
      targetProfileVersionedId: target.versionedId,
      distanceMeters: 25,
      metric: GoalMetric.absoluteHorizontalBiasMm,
      targetValue: 0,
      comparison: GoalComparison.atMost,
    );
    expect((await database.select(database.goals).getSingle()).id, goalId);

    expect(
      () => repository.saveGoal(
        targetProfileVersionedId: target.versionedId,
        distanceMeters: 25,
        metric: GoalMetric.meanRadiusMm,
        targetValue: -1,
        comparison: GoalComparison.atMost,
      ),
      throwsArgumentError,
    );
    expect(
      () => repository.saveGoal(
        targetProfileVersionedId: 'missing@1',
        distanceMeters: 25,
        metric: GoalMetric.scorePercentage,
        targetValue: 80,
        comparison: GoalComparison.atLeast,
      ),
      throwsArgumentError,
    );
  });

  test(
    'reflection updates preserve creation time and cascade with series',
    () async {
      final quick = await repository.startQuickSession();
      await repository.saveSeriesReflection(
        seriesId: quick.draftSeriesId,
        perceivedQuality: PerceivedQuality.good,
        contextTags: const {ReflectionContextTag.followThrough},
      );
      final first = await database
          .select(database.seriesReflections)
          .getSingle();

      await repository.saveSeriesReflection(
        seriesId: quick.draftSeriesId,
        perceivedQuality: PerceivedQuality.neutral,
        contextTags: const {
          ReflectionContextTag.sightPicture,
          ReflectionContextTag.trigger,
        },
      );
      final updated = await database
          .select(database.seriesReflections)
          .getSingle();
      expect(updated.createdAtUtc, first.createdAtUtc);
      expect(updated.perceivedQuality, 'neutral');
      expect(updated.contextTagsJson, '["sightPicture","trigger"]');

      await (database.delete(
        database.shootingSeries,
      )..where((row) => row.id.equals(quick.draftSeriesId))).go();
      expect(await database.select(database.seriesReflections).get(), isEmpty);
    },
  );
}
