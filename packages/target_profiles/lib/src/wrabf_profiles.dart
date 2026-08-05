import 'package:shooting_companion_domain/domain.dart';

/// Neutral training geometry for the official WRABF 50 m rimfire target.
///
/// Ring sizes follow WRABF Rules 2023-2027 V4.4. Bull centres were measured
/// from the official A3 target dated 26 June 2024. No protected artwork,
/// federation branding or print-target styling is bundled with the app.
abstract final class WrabfTargetProfiles {
  static const _recordXs = [-92.537, -37.537, 17.463, 72.463, 127.463];
  static const _rowYs = [-110.0, -55.0, 0.0, 55.0, 110.0];
  static const _leftSighterX = -147.174;
  static const _rightSighterX = 181.152;

  static final rimfire50mBr50 = TargetProfile(
    schemaVersion: 2,
    profileId: 'wrabf-50m-rimfire-br50',
    profileVersion: 1,
    displayName: 'WRABF 50 m Rimfire Benchrest (BR50)',
    authority: 'WRABF',
    rulesEdition: '2023-2027 V4.4 (revised 2026-05-05)',
    targetKind: TargetKind.multiBullConcentric,
    rendererKind: TargetRendererKind.br50Training,
    physicalCardWidthMm: 420,
    physicalCardHeightMm: 297,
    rings: const [
      RingZone(value: 10, outerDiameterMm: 6.350),
      RingZone(value: 9, outerDiameterMm: 12.700),
      RingZone(value: 8, outerDiameterMm: 19.050),
      RingZone(value: 7, outerDiameterMm: 25.400),
      RingZone(value: 6, outerDiameterMm: 31.750),
      RingZone(value: 5, outerDiameterMm: 38.100),
    ],
    innerTenDiameterMm: 0.792,
    blackOuterDiameterMm: null,
    lineThicknessMm: 0.22,
    lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
    validationStatus: ValidationStatus.officialGeometryTrainingRendering,
    defaultDistanceMeters: 50,
    supportedDistancesMeters: const [50],
    bulls: _bulls,
    multiBullScoringPolicy: const MultiBullScoringPolicy(
      recordBullCount: 25,
      maximumShotsPerBull: 1,
      duplicatePolicy: DuplicateShotPolicy.lowestScoreCounts,
      excessShotPenalty: 1,
      fixedMaximumScore: 250,
    ),
  );

  static final List<TargetBull> _bulls = [
    for (var row = 0; row < _rowYs.length; row++) ...[
      TargetBull(
        id: 'sighter-left-${row + 1}',
        label: 'Proef L${row + 1}',
        centerXMm: _leftSighterX,
        centerYMm: _rowYs[row],
        role: TargetBullRole.sighter,
        scoringWidthMm: 50,
        scoringHeightMm: 50,
      ),
      for (var column = 0; column < _recordXs.length; column++)
        TargetBull(
          id: 'record-${row * 5 + column + 1}',
          label: '${row * 5 + column + 1}',
          centerXMm: _recordXs[column],
          centerYMm: _rowYs[row],
          role: TargetBullRole.record,
          scoringWidthMm: 50,
          scoringHeightMm: 50,
        ),
      TargetBull(
        id: 'sighter-right-${row + 1}',
        label: 'Proef R${row + 1}',
        centerXMm: _rightSighterX,
        centerYMm: _rowYs[row],
        role: TargetBullRole.sighter,
        scoringWidthMm: 50,
        scoringHeightMm: 50,
      ),
    ],
  ];

  static final all = [rimfire50mBr50];
}
