import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  final target = IssfTargetProfiles.precision25m50m;

  CohortSeriesInput sample(
    String id, {
    double distance = 25,
    String? ammo = 'ammo-a',
    double score = 80,
    List<ShotImpact>? impacts,
  }) => CohortSeriesInput(
    seriesId: id,
    occurredAtUtc: DateTime.utc(2026, 8, 1, 12, int.parse(id)),
    updatedAtUtc: DateTime.utc(2026, 8, 1, 12, int.parse(id)),
    targetProfileVersionedId: target.versionedId,
    targetProfile: target,
    distanceMeters: distance,
    firearmId: 'firearm',
    ammoLotId: ammo,
    scorePercentage: score,
    impacts:
        impacts ??
        [
          ShotImpact(id: '$id-a', xMm: 1, yMm: 0),
          ShotImpact(id: '$id-b', xMm: -1, yMm: 0),
        ],
  );

  test('groups only truly comparable series by default', () {
    final result = CohortAnalyzer.analyzeAll([
      sample('1'),
      sample('2', ammo: 'ammo-b'),
      sample('3', distance: 50),
    ]);
    expect(result, hasLength(3));
    expect(
      CohortAnalyzer.analyzeAll([
        sample('1'),
        sample('2', ammo: 'ammo-b'),
      ], includeAmmoLot: false),
      hasLength(1),
    );
  });

  test('calculates pooled metrics, moving averages and consistency', () {
    final result = CohortAnalyzer.analyze([
      sample('1', score: 70),
      sample('2', score: 80),
      sample('3', score: 90),
    ]);
    expect(result.pooledMetrics.positionedShotCount, 6);
    expect(
      result.scoreTrend.linearSlopePercentagePointsPerSeries,
      closeTo(10, 1e-9),
    );
    expect(result.scoreTrend.movingAverage(2), [70, 75, 85]);
    expect(result.consistency.scoreStandardDeviation, closeTo(10, 1e-9));
    expect(
      result.comparisonWarnings,
      contains('Minder dan dertig positionele treffers.'),
    );
  });

  test('rejects a manually mixed cohort', () {
    expect(
      () => CohortAnalyzer.analyze([sample('1'), sample('2', distance: 50)]),
      throwsArgumentError,
    );
  });
}
