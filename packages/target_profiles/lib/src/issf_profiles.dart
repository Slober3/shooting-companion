import 'package:shooting_companion_domain/domain.dart';

/// Target geometry from ISSF Edition 2025, Second Print (07/2026), rules
/// 6.3.4.4 and 6.3.4.5, effective 1 July 2026.
///
/// The canonical card is stored as 550 x 550 mm. The rulebook allows a visible
/// height between 520 and 550 mm; scoring geometry is unaffected by that margin.
abstract final class IssfTargetProfiles {
  static final precision25m50m = TargetProfile(
    schemaVersion: 1,
    profileId: 'issf-25m-precision-50m-pistol',
    profileVersion: 2,
    displayName: 'ISSF 25 m Precision / 50 m Pistol',
    authority: 'ISSF',
    rulesEdition:
        '2025 Second Print 07/2026 (effective 2026-07-01), rule 6.3.4.5',
    physicalCardWidthMm: 550,
    physicalCardHeightMm: 550,
    rings: const [
      RingZone(value: 10, outerDiameterMm: 50),
      RingZone(value: 9, outerDiameterMm: 100),
      RingZone(value: 8, outerDiameterMm: 150),
      RingZone(value: 7, outerDiameterMm: 200),
      RingZone(value: 6, outerDiameterMm: 250),
      RingZone(value: 5, outerDiameterMm: 300),
      RingZone(value: 4, outerDiameterMm: 350),
      RingZone(value: 3, outerDiameterMm: 400),
      RingZone(value: 2, outerDiameterMm: 450),
      RingZone(value: 1, outerDiameterMm: 500),
    ],
    innerTenDiameterMm: 25,
    blackOuterDiameterMm: 200,
    lineThicknessMm: 0.5,
    lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
    validationStatus: ValidationStatus.official,
    defaultDistanceMeters: 25,
    supportedDistancesMeters: const [25, 50],
  );

  static final rapidFire25m = TargetProfile(
    schemaVersion: 1,
    profileId: 'issf-25m-rapid-fire-pistol',
    profileVersion: 2,
    displayName: 'ISSF 25 m Rapid Fire Pistol',
    authority: 'ISSF',
    rulesEdition:
        '2025 Second Print 07/2026 (effective 2026-07-01), rule 6.3.4.4',
    physicalCardWidthMm: 550,
    physicalCardHeightMm: 550,
    rings: const [
      RingZone(value: 10, outerDiameterMm: 100),
      RingZone(value: 9, outerDiameterMm: 180),
      RingZone(value: 8, outerDiameterMm: 260),
      RingZone(value: 7, outerDiameterMm: 340),
      RingZone(value: 6, outerDiameterMm: 420),
      RingZone(value: 5, outerDiameterMm: 500),
    ],
    innerTenDiameterMm: 50,
    blackOuterDiameterMm: 500,
    lineThicknessMm: 1,
    lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
    validationStatus: ValidationStatus.official,
    defaultDistanceMeters: 25,
    supportedDistancesMeters: const [25],
  );

  static final all = [precision25m50m, rapidFire25m];

  static TargetProfile byVersionedId(String id) => all.firstWhere(
    (profile) => profile.versionedId == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Onbekend doelprofiel'),
  );
}
