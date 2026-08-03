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
}
