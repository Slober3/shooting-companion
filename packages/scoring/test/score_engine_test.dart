import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

ShotImpact impact(double x, {int multiplicity = 1, bool miss = false}) =>
    ShotImpact(
      id: 'impact-$x-$multiplicity-$miss',
      xMm: x,
      yMm: 0,
      multiplicity: multiplicity,
      isMiss: miss,
    );

void main() {
  final target = IssfTargetProfiles.precision25m50m;

  test('center shot is a ten and an inner ten', () {
    final result = ScoreEngine.score(
      target: target,
      impacts: [impact(0)],
      projectileDiameterMm: 5.6,
    );
    expect(result.total, 10);
    expect(result.innerTenCount, 1);
  });

  test('bullet touching outside of higher ring receives higher value', () {
    final bulletRadius = 9.01 / 2;
    final result = ScoreEngine.score(
      target: target,
      impacts: [impact(25 + bulletRadius)],
      projectileDiameterMm: 9.01,
      positionUncertaintyMm: 0,
    );
    expect(result.total, 10);
  });

  test('bullet just outside line receives lower value', () {
    final bulletRadius = 9.01 / 2;
    final result = ScoreEngine.score(
      target: target,
      impacts: [impact(25 + bulletRadius + 0.01)],
      projectileDiameterMm: 9.01,
      positionUncertaintyMm: 0,
    );
    expect(result.total, 9);
  });

  test('miss and multiplicity determine total and actual maximum', () {
    final result = ScoreEngine.score(
      target: target,
      impacts: [impact(0, multiplicity: 2), impact(0, miss: true)],
      projectileDiameterMm: 5.6,
    );
    expect(result.total, 20);
    expect(result.maximumPossible, 30);
    expect(result.actualShotCount, 3);
    expect(result.missCount, 1);
    expect(result.explicitMissShotCount, 1);
    expect(result.zeroValueShotCount, 1);
    expect(result.duplicateShotCount, 0);
    expect(result.shots.first.countedMultiplicity, 2);
  });

  test('runtime validation rejects non-finite input and duplicate IDs', () {
    expect(
      () => ScoreEngine.score(
        target: target,
        impacts: [impact(0)],
        projectileDiameterMm: double.nan,
      ),
      throwsArgumentError,
    );
    expect(
      () => ScoreEngine.score(
        target: target,
        impacts: [impact(0)],
        projectileDiameterMm: 5.6,
        positionUncertaintyMm: double.infinity,
      ),
      throwsArgumentError,
    );
    expect(
      () => ScoreEngine.score(
        target: target,
        impacts: const [
          ShotImpact(id: 'duplicate', xMm: 0, yMm: 0),
          ShotImpact(id: 'duplicate', xMm: 1, yMm: 0),
        ],
        projectileDiameterMm: 5.6,
      ),
      throwsArgumentError,
    );
  });

  test('impact-specific uncertainty overrides the request default', () {
    const projectileDiameterMm = 5.6;
    final tenBoundaryMm = 25 + projectileDiameterMm / 2;
    final result = ScoreEngine.score(
      target: target,
      impacts: [
        ShotImpact(
          id: 'uncertain',
          xMm: tenBoundaryMm + 0.2,
          yMm: 0,
          positionalUncertaintyMm: 0.25,
        ),
      ],
      projectileDiameterMm: projectileDiameterMm,
      positionUncertaintyMm: 0,
    );

    expect(result.total, 9);
    expect(result.shots.single.isBoundaryUncertain, isTrue);
    expect(result.hasBoundaryWarnings, isTrue);
  });

  test('inner-ten boundary produces a score warning', () {
    const projectileDiameterMm = 5.6;
    final innerTenBoundaryMm =
        target.innerTenDiameterMm! / 2 + projectileDiameterMm / 2;
    final result = ScoreEngine.score(
      target: target,
      impacts: [impact(innerTenBoundaryMm)],
      projectileDiameterMm: projectileDiameterMm,
      positionUncertaintyMm: 0,
    );

    expect(result.innerTenCount, 1);
    expect(result.hasBoundaryWarnings, isTrue);
  });

  test('custom target maximum is used instead of a hardcoded ten', () {
    final customTarget = TargetProfile(
      schemaVersion: 1,
      profileId: 'max-five',
      profileVersion: 1,
      displayName: 'Max five',
      authority: 'Test',
      rulesEdition: '1',
      physicalCardWidthMm: 100,
      physicalCardHeightMm: 100,
      rings: const [RingZone(value: 5, outerDiameterMm: 20)],
      lineThicknessMm: 0.5,
      lineBreakingRule: LineBreakingRule.centerOnly,
      validationStatus: ValidationStatus.experimental,
    );

    final result = ScoreEngine.score(
      target: customTarget,
      impacts: [impact(0), impact(0, miss: true)],
      projectileDiameterMm: 5.6,
    );

    expect(result.actualShotCount, 2);
    expect(result.maximumPossible, 10);
    expect(result.total, 5);
  });

  test('score is monotonic toward target center', () {
    var previous = -1;
    for (var distance = 260.0; distance >= 0; distance -= 0.5) {
      final result = ScoreEngine.score(
        target: target,
        impacts: [impact(distance)],
        projectileDiameterMm: 5.6,
      );
      expect(result.total, greaterThanOrEqualTo(previous));
      previous = result.total;
    }
  });

  group('WRABF BR50', () {
    final target = WrabfTargetProfiles.rimfire50mBr50;

    ShotImpact br50Impact(
      int bullNumber,
      double radialDistanceMm, {
      int multiplicity = 1,
      bool miss = false,
    }) {
      final bull = target.recordBulls[bullNumber - 1];
      return ShotImpact(
        id: 'br50-$bullNumber-$radialDistanceMm-$multiplicity-$miss',
        xMm: bull.centerXMm + radialDistanceMm,
        yMm: bull.centerYMm,
        targetBullId: bull.id,
        multiplicity: multiplicity,
        isMiss: miss,
      );
    }

    test('25 tens score 250 with a fixed maximum', () {
      final result = ScoreEngine.score(
        target: target,
        impacts: [for (var bull = 1; bull <= 25; bull++) br50Impact(bull, 0)],
        projectileDiameterMm: 5.6,
        positionUncertaintyMm: 0,
      );
      expect(result.total, 250);
      expect(result.maximumPossible, 250);
      expect(result.scoredBullCount, 25);
      expect(result.innerTenCount, 25);
    });

    test('lowest score counts when one bull has multiple shots', () {
      final result = ScoreEngine.score(
        target: target,
        impacts: [br50Impact(1, 0), br50Impact(1, 10)],
        projectileDiameterMm: 5.6,
        positionUncertaintyMm: 0,
      );
      expect(result.totalBeforePenalty, 8);
      expect(
        result.shots
            .where((shot) => shot.disposition == ScoreDisposition.counted)
            .single
            .value,
        8,
      );
      expect(
        result.shots.where(
          (shot) => shot.disposition == ScoreDisposition.duplicateNotCounted,
        ),
        hasLength(1),
      );
      expect(result.countedShotCount, 1);
      expect(result.duplicateShotCount, 1);
      expect(result.unscoredBullCount, 24);
    });

    test('multiplicity counts one shot and exposes remaining duplicates', () {
      final result = ScoreEngine.score(
        target: target,
        impacts: [br50Impact(1, 0, multiplicity: 3)],
        projectileDiameterMm: 5.6,
        positionUncertaintyMm: 0,
      );

      expect(result.totalBeforePenalty, 10);
      expect(result.actualShotCount, 3);
      expect(result.countedShotCount, 1);
      expect(result.duplicateShotCount, 2);
      expect(result.shots.single.countedMultiplicity, 1);
      expect(result.shots.single.duplicateMultiplicity, 2);
      expect(result.penalty, 0);
    });

    test('extra record shots receive one penalty point each', () {
      final result = ScoreEngine.score(
        target: target,
        impacts: [
          for (var bull = 1; bull <= 25; bull++) br50Impact(bull, 0),
          br50Impact(1, 0, multiplicity: 2),
        ],
        projectileDiameterMm: 5.6,
        positionUncertaintyMm: 0,
      );
      expect(result.actualShotCount, 27);
      expect(result.penalty, 2);
      expect(result.total, 248);
      expect(result.duplicateShotCount, 2);
    });

    test('empty record bulls remain zero in the fixed 250 maximum', () {
      final result = ScoreEngine.score(
        target: target,
        impacts: [br50Impact(1, 0)],
        projectileDiameterMm: 5.6,
        positionUncertaintyMm: 0,
      );
      expect(result.total, 10);
      expect(result.maximumPossible, 250);
      expect(result.missCount, 24);
      expect(result.unscoredBullCount, 24);
      expect(result.explicitMissShotCount, 0);
    });

    test('geometry derives a missing bull id', () {
      final bull = target.recordBulls.first;
      final result = ScoreEngine.score(
        target: target,
        impacts: [
          ShotImpact(id: 'derived', xMm: bull.centerXMm, yMm: bull.centerYMm),
        ],
        projectileDiameterMm: 5.6,
      );

      expect(result.shots.single.targetBullId, bull.id);
      expect(result.shots.single.impact.targetBullId, bull.id);
    });

    test('stored bull id must agree with geometric position', () {
      final first = target.recordBulls.first;
      final second = target.recordBulls[1];
      expect(
        () => ScoreEngine.score(
          target: target,
          impacts: [
            ShotImpact(
              id: 'mismatch',
              xMm: first.centerXMm,
              yMm: first.centerYMm,
              targetBullId: second.id,
            ),
          ],
          projectileDiameterMm: 5.6,
        ),
        throwsArgumentError,
      );
    });

    test('sighter and between-bull positions cannot enter record scoring', () {
      final sighter = target.bulls.firstWhere(
        (bull) => bull.role == TargetBullRole.sighter,
      );
      final first = target.recordBulls.first;
      expect(
        () => ScoreEngine.score(
          target: target,
          impacts: [
            ShotImpact(
              id: 'sighter',
              xMm: sighter.centerXMm,
              yMm: sighter.centerYMm,
              targetBullId: sighter.id,
            ),
          ],
          projectileDiameterMm: 5.6,
        ),
        throwsArgumentError,
      );
      expect(
        () => ScoreEngine.score(
          target: target,
          impacts: [
            ShotImpact(
              id: 'between',
              xMm: first.centerXMm + 27.5,
              yMm: first.centerYMm,
            ),
          ],
          projectileDiameterMm: 5.6,
        ),
        throwsArgumentError,
      );
    });

    test('a multi-bull miss requires an explicit record bull', () {
      expect(
        () => ScoreEngine.score(
          target: target,
          impacts: const [ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true)],
          projectileDiameterMm: 5.6,
        ),
        throwsArgumentError,
      );

      final result = ScoreEngine.score(
        target: target,
        impacts: [br50Impact(1, 0, multiplicity: 2, miss: true)],
        projectileDiameterMm: 5.6,
      );
      expect(result.explicitMissShotCount, 2);
      expect(result.zeroValueShotCount, 2);
      expect(result.countedShotCount, 1);
      expect(result.duplicateShotCount, 1);
      expect(result.unscoredBullCount, 24);
    });
  });
}
