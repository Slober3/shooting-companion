import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  final target = IssfTargetProfiles.precision25m50m;

  CohortSeriesInput sample(
    String id, {
    DateTime? occurredAtUtc,
    int? sequenceNumber,
    double distance = 25,
    String? cartridge = '22-lr',
    double projectileDiameterMm = 5.6,
    String? ammo = 'ammo-a',
    double score = 80,
    List<ShotImpact>? impacts,
  }) => CohortSeriesInput(
    seriesId: id,
    occurredAtUtc: occurredAtUtc ?? DateTime.utc(2026, 8, 1, 12, int.parse(id)),
    sequenceNumber: sequenceNumber ?? int.parse(id),
    updatedAtUtc: DateTime.utc(2026, 8, 1, 12, int.parse(id)),
    targetProfileVersionedId: target.versionedId,
    targetProfile: target,
    distanceMeters: distance,
    projectileDiameterMm: projectileDiameterMm,
    cartridgeId: cartridge,
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
    final withoutAmmoLot = CohortAnalyzer.analyzeAll([
      sample('1'),
      sample('2', ammo: 'ammo-b'),
    ], includeAmmoLot: false);
    expect(withoutAmmoLot, hasLength(1));
    expect(withoutAmmoLot.values.single.cohort.ammoLotId, isNull);

    final directWithoutAmmoLot = CohortAnalyzer.analyze([
      sample('1'),
      sample('2', ammo: 'ammo-b'),
    ], includeAmmoLot: false);
    expect(directWithoutAmmoLot.cohort.ammoLotId, isNull);
  });

  test('separates cartridge and projectile diameter without an ammo lot', () {
    final result = CohortAnalyzer.analyzeAll([
      sample('1', ammo: null),
      sample('2', ammo: null, cartridge: '9x19', projectileDiameterMm: 9.01),
      sample('3', ammo: null, cartridge: null, projectileDiameterMm: 5.5),
    ]);

    expect(result, hasLength(3));
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

  test('score trend keeps a selected series without physical positions', () {
    final result = CohortAnalyzer.analyze([
      sample(
        '1',
        score: 20,
        impacts: const [ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true)],
      ),
      sample('2', score: 80),
    ]);

    expect(result.seriesAnalyses, hasLength(2));
    expect(result.pooledMetrics.positionedShotCount, 2);
    expect(result.scoreTrend.percentages, [20, 80]);
    expect(
      result.scoreTrend.linearSlopePercentagePointsPerSeries,
      closeTo(60, 1e-9),
    );
  });

  test('rejects a manually mixed cohort', () {
    expect(
      () => CohortAnalyzer.analyze([sample('1'), sample('2', distance: 50)]),
      throwsArgumentError,
    );
  });

  test(
    'orders sessions by occurrence and series within a session by sequence',
    () {
      final laterSession = DateTime.utc(2026, 8, 2);
      final earlierSession = DateTime.utc(2026, 8, 1);
      final result = CohortAnalyzer.analyze([
        sample('3', occurredAtUtc: laterSession, sequenceNumber: 2, score: 30),
        sample('2', occurredAtUtc: laterSession, sequenceNumber: 1, score: 20),
        sample(
          '1',
          occurredAtUtc: earlierSession,
          sequenceNumber: 1,
          score: 10,
        ),
      ]);

      expect(result.seriesAnalyses.map((item) => item.seriesId), [
        '1',
        '2',
        '3',
      ]);
      expect(result.scoreTrend.percentages, [10, 20, 30]);
    },
  );
}
