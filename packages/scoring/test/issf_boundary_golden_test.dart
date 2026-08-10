import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

const _projectileDiametersMm = <String, double>{
  '.22 LR': 5.60,
  '9x19 mm': 9.01,
  '.38 Special': 9.07,
  '.357 Magnum': 9.07,
};

const _precisionRings = <(int, double)>[
  (10, 50),
  (9, 100),
  (8, 150),
  (7, 200),
  (6, 250),
  (5, 300),
  (4, 350),
  (3, 400),
  (2, 450),
  (1, 500),
];

const _rapidFireRings = <(int, double)>[
  (10, 100),
  (9, 180),
  (8, 260),
  (7, 340),
  (6, 420),
  (5, 500),
];

void main() {
  for (final fixture
      in <
        ({
          String name,
          TargetProfile target,
          List<(int, double)> rings,
          double innerTenDiameterMm,
        })
      >[
        (
          name: 'ISSF Precision',
          target: IssfTargetProfiles.precision25m50m,
          rings: _precisionRings,
          innerTenDiameterMm: 25,
        ),
        (
          name: 'ISSF Rapid Fire',
          target: IssfTargetProfiles.rapidFire25m,
          rings: _rapidFireRings,
          innerTenDiameterMm: 50,
        ),
      ]) {
    group('${fixture.name} independent boundary goldens', () {
      test('profile geometry still matches the independent fixture table', () {
        expect(
          fixture.target.rings
              .map((ring) => (ring.value, ring.outerDiameterMm))
              .toList(),
          fixture.rings,
        );
        expect(fixture.target.innerTenDiameterMm, fixture.innerTenDiameterMm);
      });

      for (final projectile in _projectileDiametersMm.entries) {
        test(
          '${projectile.key}: every ring is tangent-inclusive in all axes',
          () {
            final bulletRadiusMm = projectile.value / 2;
            for (
              var ringIndex = 0;
              ringIndex < fixture.rings.length;
              ringIndex++
            ) {
              final ring = fixture.rings[ringIndex];
              final tangentCenterDistanceMm = ring.$2 / 2 + bulletRadiusMm;
              final nextLowerValue = ringIndex + 1 < fixture.rings.length
                  ? fixture.rings[ringIndex + 1].$1
                  : 0;

              for (final angle in <double>[
                0,
                math.pi / 2,
                math.pi,
                3 * math.pi / 2,
                math.pi / 4,
                3 * math.pi / 4,
                5 * math.pi / 4,
                7 * math.pi / 4,
              ]) {
                expect(
                  _scoreAt(
                    fixture.target,
                    tangentCenterDistanceMm - 0.01,
                    angle,
                    projectile.value,
                  ),
                  ring.$1,
                  reason: '${projectile.key}, ring ${ring.$1}, 0.01 mm inside',
                );
                expect(
                  _scoreAt(
                    fixture.target,
                    tangentCenterDistanceMm,
                    angle,
                    projectile.value,
                  ),
                  ring.$1,
                  reason: '${projectile.key}, ring ${ring.$1}, exact tangent',
                );
                expect(
                  _scoreAt(
                    fixture.target,
                    tangentCenterDistanceMm + 0.01,
                    angle,
                    projectile.value,
                  ),
                  nextLowerValue,
                  reason: '${projectile.key}, ring ${ring.$1}, 0.01 mm outside',
                );
              }
            }
          },
        );

        test('${projectile.key}: inner ten tangent and +/- 0.01 mm', () {
          final xBoundaryMm =
              fixture.innerTenDiameterMm / 2 + projectile.value / 2;
          for (final delta in <double>[-0.01, 0, 0.01]) {
            final result = ScoreEngine.score(
              target: fixture.target,
              impacts: [
                ShotImpact(
                  id: 'inner-ten-${projectile.key}-$delta',
                  xMm: xBoundaryMm + delta,
                  yMm: 0,
                ),
              ],
              projectileDiameterMm: projectile.value,
              positionUncertaintyMm: 0,
            );
            expect(result.total, 10);
            expect(result.innerTenCount, delta <= 0 ? 1 : 0);
          }
        });
      }
    });
  }

  test('center-only fixture ignores projectile radius at its boundary', () {
    final target = TargetProfile(
      schemaVersion: 1,
      profileId: 'center-only-golden',
      profileVersion: 1,
      displayName: 'Center-only golden',
      authority: 'Independent test fixture',
      rulesEdition: '1',
      physicalCardWidthMm: 100,
      physicalCardHeightMm: 100,
      rings: const [
        RingZone(value: 10, outerDiameterMm: 20),
        RingZone(value: 9, outerDiameterMm: 40),
      ],
      lineThicknessMm: 5,
      lineBreakingRule: LineBreakingRule.centerOnly,
      validationStatus: ValidationStatus.experimental,
    );

    for (final projectile in _projectileDiametersMm.values) {
      expect(_scoreAt(target, 9.99, 0, projectile), 10);
      expect(_scoreAt(target, 10, 0, projectile), 10);
      expect(_scoreAt(target, 10.01, 0, projectile), 9);
    }
  });
}

int _scoreAt(
  TargetProfile target,
  double distanceMm,
  double angle,
  double projectileDiameterMm,
) {
  final result = ScoreEngine.score(
    target: target,
    impacts: [
      ShotImpact(
        id: 'golden-$distanceMm-$angle-$projectileDiameterMm',
        xMm: distanceMm * math.cos(angle),
        yMm: distanceMm * math.sin(angle),
      ),
    ],
    projectileDiameterMm: projectileDiameterMm,
    positionUncertaintyMm: 0,
  );
  return result.total;
}
