import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  final target = IssfTargetProfiles.precision25m50m;

  test('line-breaking d-b and r+b formulations are equivalent', () {
    const projectileDiameterMm = 5.6;
    final projectileRadiusMm = projectileDiameterMm / 2;
    final evaluation = RadialScoreEvaluator.evaluate(
      target: target,
      xMm: 25 + projectileRadiusMm,
      yMm: 0,
      projectileDiameterMm: projectileDiameterMm,
    );

    expect(evaluation.value, 10);
    expect(evaluation.qualifyingRadiusMm, closeTo(25, 1e-12));
    expect(evaluation.nearestBoundaryValue, 10);
    expect(evaluation.nearestBoundaryDistanceMm, closeTo(0, 1e-12));
  });

  test('center-only scoring does not add projectile radius', () {
    final centerOnly = TargetProfile(
      schemaVersion: 1,
      profileId: 'center-only',
      profileVersion: 1,
      displayName: 'Center only',
      authority: 'Test',
      rulesEdition: '1',
      physicalCardWidthMm: 100,
      physicalCardHeightMm: 100,
      rings: const [RingZone(value: 10, outerDiameterMm: 20)],
      lineThicknessMm: 0.5,
      lineBreakingRule: LineBreakingRule.centerOnly,
      validationStatus: ValidationStatus.experimental,
    );

    final evaluation = RadialScoreEvaluator.evaluate(
      target: centerOnly,
      xMm: 10.1,
      yMm: 0,
      projectileDiameterMm: 5.6,
    );

    expect(evaluation.value, 0);
    expect(evaluation.qualifyingRadiusMm, closeTo(10.1, 1e-12));
  });

  test('inner-ten boundary participates in uncertainty evaluation', () {
    const projectileDiameterMm = 5.6;
    final boundaryMm =
        target.innerTenDiameterMm! / 2 + projectileDiameterMm / 2;
    final evaluation = RadialScoreEvaluator.evaluate(
      target: target,
      xMm: boundaryMm,
      yMm: 0,
      projectileDiameterMm: projectileDiameterMm,
      positionUncertaintyMm: 0,
    );

    expect(evaluation.value, 10);
    expect(evaluation.isInnerTen, isTrue);
    expect(evaluation.nearestBoundaryKind, BoundaryKind.innerTen);
    expect(evaluation.nearestBoundaryDistanceMm, closeTo(0, 1e-12));
    expect(evaluation.isBoundaryUncertain, isTrue);
  });

  test('invalid non-finite numeric input is rejected', () {
    expect(
      () => RadialScoreEvaluator.evaluate(
        target: target,
        xMm: double.nan,
        yMm: 0,
        projectileDiameterMm: 5.6,
      ),
      throwsArgumentError,
    );
    expect(
      () => RadialScoreEvaluator.evaluate(
        target: target,
        xMm: 0,
        yMm: 0,
        projectileDiameterMm: double.infinity,
      ),
      throwsArgumentError,
    );
  });
}
