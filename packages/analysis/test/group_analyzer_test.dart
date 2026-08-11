import 'dart:math' as math;

import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  group('group metrics', () {
    test('counts misses but excludes them from physical measurements', () {
      final analysis = _analyze(const [
        ShotImpact(
          id: 'miss',
          xMm: 500,
          yMm: 500,
          multiplicity: 2,
          isMiss: true,
          scoreDisposition: ScoreDisposition.miss,
        ),
      ]);

      expect(analysis.actualShotCount, 2);
      expect(analysis.positionedShotCount, 0);
      expect(analysis.metrics.extremeSpreadMm, 0);
      expect(analysis.metrics.extremeSpreadSegment, isNull);
      expect(analysis.reliability, AnalysisReliability.noPositionData);
      expect(
        _warning(
          analysis,
          AnalysisWarningCode.missWithoutPosition,
        ).affectedShotCount,
        2,
      );
      expect(
        _warning(
          analysis,
          AnalysisWarningCode.noPositionData,
        ).affectedShotCount,
        0,
      );
    });

    test('calculates centroid, dispersion, covariance and angular spread', () {
      final analysis = _analyze(const [
        ShotImpact(id: 'left', xMm: -5, yMm: 0),
        ShotImpact(id: 'right', xMm: 5, yMm: 0),
      ], distanceMeters: 25);
      final metrics = analysis.metrics;

      expect(metrics.actualShotCount, 2);
      expect(metrics.positionedShotCount, 2);
      expect(metrics.centroidXMm, closeTo(0, 1e-12));
      expect(metrics.horizontalBiasMm, closeTo(0, 1e-12));
      expect(metrics.verticalBiasMm, closeTo(0, 1e-12));
      expect(metrics.extremeSpreadMm, closeTo(10, 1e-12));
      expect(metrics.extremeSpreadSegment, isNotNull);
      expect(metrics.extremeSpreadSegment!.firstImpactId, 'left');
      expect(metrics.extremeSpreadSegment!.secondImpactId, 'right');
      expect(metrics.extremeSpreadSegment!.firstXMm, -5);
      expect(metrics.extremeSpreadSegment!.secondXMm, 5);
      expect(metrics.extremeSpreadSegment!.distanceMm, closeTo(10, 1e-12));
      expect(metrics.meanRadiusMm, closeTo(5, 1e-12));
      expect(metrics.sampleStandardDeviationXMm, closeTo(math.sqrt(50), 1e-12));
      expect(metrics.sampleStandardDeviationYMm, 0);
      expect(
        metrics.covarianceEllipse.semiMajorAxisMm,
        closeTo(math.sqrt(50), 1e-12),
      );
      expect(metrics.covarianceEllipse.semiMinorAxisMm, 0);
      expect(metrics.covarianceEllipse.angleDegrees, closeTo(0, 1e-12));
      expect(metrics.extremeSpreadMoa, closeTo(1.3751, 0.0001));
      expect(metrics.extremeSpreadMilliradians, closeTo(0.4, 1e-12));
    });

    test('weights multiplicity and qualifies its positional precision', () {
      final analysis = _analyze(const [
        ShotImpact(id: 'double', xMm: 0, yMm: 0, multiplicity: 2),
        ShotImpact(id: 'single', xMm: 9, yMm: 0),
        ShotImpact(id: 'miss', xMm: 0, yMm: 0, multiplicity: 2, isMiss: true),
      ]);

      expect(analysis.actualShotCount, 5);
      expect(analysis.positionedShotCount, 3);
      expect(analysis.metrics.centroidXMm, closeTo(3, 1e-12));
      expect(analysis.metrics.meanRadiusMm, closeTo(4, 1e-12));
      expect(analysis.metrics.extremeSpreadMm, 9);
      expect(analysis.metrics.extremeSpreadSegment!.firstImpactId, 'double');
      expect(analysis.metrics.extremeSpreadSegment!.secondImpactId, 'single');
      expect(
        analysis.metrics.sampleStandardDeviationXMm,
        closeTo(math.sqrt(27), 1e-12),
      );
      expect(
        _warning(
          analysis,
          AnalysisWarningCode.multiplicityApproximation,
        ).affectedShotCount,
        2,
      );
      expect(
        _warning(
          analysis,
          AnalysisWarningCode.missWithoutPosition,
        ).affectedShotCount,
        2,
      );
    });

    test(
      'includes a distant impact and deterministically selects endpoints',
      () {
        const impacts = [
          ShotImpact(id: 'right', xMm: 10, yMm: 0),
          ShotImpact(id: 'top', xMm: 0, yMm: -10),
          ShotImpact(id: 'left', xMm: -10, yMm: 0),
          ShotImpact(id: 'bottom', xMm: 0, yMm: 10),
          ShotImpact(id: 'outlier', xMm: 80, yMm: 0),
        ];

        final forward = _analyze(impacts).metrics;
        final reversed = _analyze(impacts.reversed).metrics;

        expect(forward.extremeSpreadMm, 90);
        expect(forward.extremeSpreadSegment!.firstImpactId, 'left');
        expect(forward.extremeSpreadSegment!.secondImpactId, 'outlier');
        expect(
          reversed.extremeSpreadSegment!.firstImpactId,
          forward.extremeSpreadSegment!.firstImpactId,
        );
        expect(
          reversed.extremeSpreadSegment!.secondImpactId,
          forward.extremeSpreadSegment!.secondImpactId,
        );
        expect(forward.centroidXMm, greaterThan(0));
      },
    );

    test('uses deterministic interpolated empirical radial percentiles', () {
      final metrics = _analyze(const [
        ShotImpact(id: 'a', xMm: -2, yMm: 0),
        ShotImpact(id: 'b', xMm: -1, yMm: 0),
        ShotImpact(id: 'c', xMm: 0, yMm: 0),
        ShotImpact(id: 'd', xMm: 1, yMm: 0),
        ShotImpact(id: 'e', xMm: 2, yMm: 0),
      ]).metrics;

      expect(metrics.meanRadiusMm, closeTo(1.2, 1e-12));
      expect(metrics.empiricalR50Mm, closeTo(1, 1e-12));
      expect(metrics.empiricalR90Mm, closeTo(2, 1e-12));
    });

    test('reports every reliability tier at its exact boundary', () {
      SeriesAnalysis withCount(int count) => _analyze([
        for (var index = 0; index < count; index++)
          ShotImpact(id: '$index', xMm: index.toDouble(), yMm: 0),
      ]);

      expect(withCount(0).reliability, AnalysisReliability.noPositionData);
      expect(withCount(1).reliability, AnalysisReliability.positionsOnly);
      expect(withCount(2).reliability, AnalysisReliability.positionsOnly);
      expect(withCount(3).reliability, AnalysisReliability.provisional);
      expect(withCount(4).reliability, AnalysisReliability.provisional);
      expect(withCount(5).reliability, AnalysisReliability.smallSample);
      expect(withCount(9).reliability, AnalysisReliability.smallSample);
      expect(withCount(10).reliability, AnalysisReliability.full);
    });

    test('can include or exclude uncertain positions explicitly', () {
      const impacts = [
        ShotImpact(id: 'certain', xMm: 0, yMm: 0),
        ShotImpact(
          id: 'uncertain',
          xMm: 10,
          yMm: 0,
          multiplicity: 2,
          isPositionUncertain: true,
        ),
      ];

      final included = _analyze(impacts);
      final excluded = _analyze(impacts, includeUncertainPositions: false);

      expect(included.positionedShotCount, 3);
      expect(
        _warning(
          included,
          AnalysisWarningCode.uncertainPositionsIncluded,
        ).affectedShotCount,
        2,
      );
      expect(excluded.actualShotCount, 3);
      expect(excluded.positionedShotCount, 1);
      expect(excluded.metrics.centroidXMm, 0);
      expect(
        _warning(
          excluded,
          AnalysisWarningCode.uncertainPositionsExcluded,
        ).affectedShotCount,
        2,
      );
    });

    test(
      'invalid distance is qualified and does not invent angular values',
      () {
        final analysis = _analyze(const [
          ShotImpact(id: 'a', xMm: 1, yMm: 1),
        ], distanceMeters: 0);

        expect(analysis.metrics.extremeSpreadMoa, isNull);
        expect(analysis.metrics.extremeSpreadMilliradians, isNull);
        expect(
          _warning(
            analysis,
            AnalysisWarningCode.invalidDistance,
          ).affectedShotCount,
          1,
        );
      },
    );

    test('dispersion is invariant under translation and rotation', () {
      const source = [
        ShotImpact(id: 'a', xMm: -3, yMm: 1),
        ShotImpact(id: 'b', xMm: 2, yMm: 4),
        ShotImpact(id: 'c', xMm: 5, yMm: -2),
        ShotImpact(id: 'd', xMm: -4, yMm: -3),
        ShotImpact(id: 'e', xMm: 1, yMm: 0),
      ];
      final transformed = source
          .map(
            (impact) => ShotImpact(
              id: impact.id,
              xMm: -impact.yMm + 120,
              yMm: impact.xMm - 35,
            ),
          )
          .toList();

      final original = _analyze(source).metrics;
      final moved = _analyze(transformed).metrics;

      expect(moved.extremeSpreadMm, closeTo(original.extremeSpreadMm, 1e-10));
      expect(moved.meanRadiusMm, closeTo(original.meanRadiusMm, 1e-10));
      expect(moved.empiricalR50Mm, closeTo(original.empiricalR50Mm, 1e-10));
      expect(moved.empiricalR90Mm, closeTo(original.empiricalR90Mm, 1e-10));
      expect(
        moved.covarianceEllipse.semiMajorAxisMm,
        closeTo(original.covarianceEllipse.semiMajorAxisMm, 1e-10),
      );
      expect(
        moved.covarianceEllipse.semiMinorAxisMm,
        closeTo(original.covarianceEllipse.semiMinorAxisMm, 1e-10),
      );
      expect(moved.centroidXMm, closeTo(-original.centroidYMm + 120, 1e-10));
      expect(moved.centroidYMm, closeTo(original.centroidXMm - 35, 1e-10));
    });
  });

  group('multi-bull normalization', () {
    test('normalizes each BR50 impact around its referenced record bull', () {
      final target = WrabfTargetProfiles.rimfire50mBr50;
      final first = target.recordBulls[0];
      final second = target.recordBulls[12];
      final analysis = GroupAnalyzer.analyze(
        seriesId: 'br50',
        targetProfile: target,
        impacts: [
          ShotImpact(
            id: 'first',
            xMm: first.centerXMm + 1,
            yMm: first.centerYMm - 2,
            targetBullId: first.id,
          ),
          ShotImpact(
            id: 'second',
            xMm: second.centerXMm + 1,
            yMm: second.centerYMm - 2,
            targetBullId: second.id,
          ),
        ],
      );

      expect(analysis.positionedShotCount, 2);
      expect(analysis.metrics.centroidXMm, closeTo(1, 1e-10));
      expect(analysis.metrics.centroidYMm, closeTo(-2, 1e-10));
      expect(analysis.metrics.extremeSpreadMm, closeTo(0, 1e-10));
      expect(analysis.positions[0].targetBullId, first.id);
    });

    test(
      'excludes missing, unknown and sighter bull references separately',
      () {
        final target = WrabfTargetProfiles.rimfire50mBr50;
        final record = target.recordBulls.first;
        final sighter = target.bulls.firstWhere(
          (bull) => bull.role == TargetBullRole.sighter,
        );
        final analysis = GroupAnalyzer.analyze(
          seriesId: 'br50-invalid',
          targetProfile: target,
          impacts: [
            ShotImpact(
              id: 'valid',
              xMm: record.centerXMm,
              yMm: record.centerYMm,
              targetBullId: record.id,
            ),
            const ShotImpact(id: 'missing', xMm: 0, yMm: 0),
            const ShotImpact(
              id: 'unknown',
              xMm: 0,
              yMm: 0,
              multiplicity: 2,
              targetBullId: 'not-a-bull',
            ),
            ShotImpact(
              id: 'sighter',
              xMm: sighter.centerXMm,
              yMm: sighter.centerYMm,
              targetBullId: sighter.id,
            ),
            const ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
          ],
        );

        expect(analysis.actualShotCount, 6);
        expect(analysis.positionedShotCount, 1);
        expect(
          _warning(
            analysis,
            AnalysisWarningCode.missingTargetBull,
          ).affectedShotCount,
          1,
        );
        expect(
          _warning(
            analysis,
            AnalysisWarningCode.unknownTargetBull,
          ).affectedShotCount,
          2,
        );
        expect(
          _warning(
            analysis,
            AnalysisWarningCode.sighterBullExcluded,
          ).affectedShotCount,
          1,
        );
      },
    );
  });

  group('possible subgroup detection', () {
    test('suggests two clear, stable subgroups', () {
      final impacts = <ShotImpact>[
        const ShotImpact(id: 'a1', xMm: -11, yMm: -1),
        const ShotImpact(id: 'a2', xMm: -10, yMm: 0),
        const ShotImpact(id: 'a3', xMm: -9, yMm: 1),
        const ShotImpact(id: 'a4', xMm: -10.5, yMm: 1),
        const ShotImpact(id: 'a5', xMm: -9.5, yMm: -1),
        const ShotImpact(id: 'b1', xMm: 9, yMm: -1),
        const ShotImpact(id: 'b2', xMm: 10, yMm: 0),
        const ShotImpact(id: 'b3', xMm: 11, yMm: 1),
        const ShotImpact(id: 'b4', xMm: 9.5, yMm: 1),
        const ShotImpact(id: 'b5', xMm: 10.5, yMm: -1),
      ];

      final first = GroupAnalyzer.suggestSubgroups(
        impacts,
        targetProfile: _target,
      );
      final second = GroupAnalyzer.suggestSubgroups(
        impacts.reversed,
        targetProfile: _target,
      );

      expect(first, isNotNull);
      expect(first!.clusterCount, 2);
      expect(first.silhouetteScore, greaterThanOrEqualTo(0.55));
      expect(first.stability, greaterThanOrEqualTo(0.8));
      expect(first.clusters.map((cluster) => cluster.logicalShotCount), [5, 5]);
      expect(first.clusters.first.centroidXMm, lessThan(0));
      expect(first.clusters.last.centroidXMm, greaterThan(0));
      expect(second!.clusterCount, first.clusterCount);
      expect(second.silhouetteScore, first.silhouetteScore);
      expect(second.stability, first.stability);
      expect(
        second.clusters.map((cluster) => cluster.impactIds),
        first.clusters.map((cluster) => cluster.impactIds),
      );
    });

    test(
      'detects three clearly separated groups when that fit is stronger',
      () {
        final impacts = <ShotImpact>[
          for (var group = 0; group < 3; group++)
            for (var index = 0; index < 4; index++)
              ShotImpact(
                id: '$group-$index',
                xMm: (group - 1) * 30 + (index.isEven ? -0.5 : 0.5),
                yMm: index < 2 ? -0.5 : 0.5,
              ),
        ];

        final suggestion = GroupAnalyzer.suggestSubgroups(
          impacts,
          targetProfile: _target,
        );

        expect(suggestion, isNotNull);
        expect(suggestion!.clusterCount, 3);
        expect(suggestion.clusters.map((cluster) => cluster.logicalShotCount), [
          4,
          4,
          4,
        ]);
      },
    );

    test('returns no suggestion below ten positioned shots', () {
      final impacts = [
        for (var index = 0; index < 9; index++)
          ShotImpact(
            id: '$index',
            xMm: index < 5 ? -10 : 10,
            yMm: index.toDouble(),
          ),
      ];

      expect(
        GroupAnalyzer.suggestSubgroups(impacts, targetProfile: _target),
        isNull,
      );
    });

    test('does not invent subgroups for one identical point', () {
      final impacts = [
        for (var index = 0; index < 10; index++)
          ShotImpact(id: '$index', xMm: 2, yMm: -3),
      ];

      expect(
        GroupAnalyzer.suggestSubgroups(impacts, targetProfile: _target),
        isNull,
      );
    });

    test('never mutates or replaces source impacts', () {
      final impacts = <ShotImpact>[
        for (var index = 0; index < 10; index++)
          ShotImpact(
            id: '$index',
            xMm: index < 5 ? -10 + index * 0.1 : 10 + index * 0.1,
            yMm: index * 0.2,
          ),
      ];
      final identities = impacts.map(identityHashCode).toList();
      final coordinates = impacts
          .map((impact) => (impact.xMm, impact.yMm))
          .toList();

      GroupAnalyzer.suggestSubgroups(impacts, targetProfile: _target);

      expect(impacts.map(identityHashCode), identities);
      expect(impacts.map((impact) => (impact.xMm, impact.yMm)), coordinates);
    });
  });
}

SeriesAnalysis _analyze(
  Iterable<ShotImpact> impacts, {
  double? distanceMeters,
  bool includeUncertainPositions = true,
}) => GroupAnalyzer.analyze(
  seriesId: 'series',
  impacts: impacts,
  targetProfile: _target,
  distanceMeters: distanceMeters,
  includeUncertainPositions: includeUncertainPositions,
);

AnalysisWarning _warning(SeriesAnalysis analysis, AnalysisWarningCode code) =>
    analysis.warnings.singleWhere((warning) => warning.code == code);

final _target = TargetProfile(
  schemaVersion: 1,
  profileId: 'analysis-test',
  profileVersion: 1,
  displayName: 'Analysis test target',
  authority: 'Tests',
  rulesEdition: '1',
  physicalCardWidthMm: 100,
  physicalCardHeightMm: 100,
  rings: const [RingZone(value: 10, outerDiameterMm: 20)],
  lineThicknessMm: 0.5,
  lineBreakingRule: LineBreakingRule.centerOnly,
  validationStatus: ValidationStatus.experimental,
);
