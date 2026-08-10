import 'package:shooting_companion_domain/domain.dart';
import 'package:test/test.dart';

TargetProfile singleBullTarget({List<RingZone>? rings}) => TargetProfile(
  schemaVersion: 1,
  profileId: 'single',
  profileVersion: 1,
  displayName: 'Single',
  authority: 'Test',
  rulesEdition: '1',
  physicalCardWidthMm: 100,
  physicalCardHeightMm: 100,
  rings:
      rings ??
      const [
        RingZone(value: 10, outerDiameterMm: 20),
        RingZone(value: 9, outerDiameterMm: 40),
      ],
  lineThicknessMm: 0.5,
  lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
  validationStatus: ValidationStatus.experimental,
  defaultDistanceMeters: 25,
  supportedDistancesMeters: const [25],
);

TargetProfile multiBullTarget({
  List<TargetBull>? bulls,
  int maximumShotsPerBull = 1,
  int fixedMaximumScore = 20,
}) => TargetProfile(
  schemaVersion: 2,
  profileId: 'multi',
  profileVersion: 1,
  displayName: 'Multi',
  authority: 'Test',
  rulesEdition: '1',
  targetKind: TargetKind.multiBullConcentric,
  physicalCardWidthMm: 100,
  physicalCardHeightMm: 100,
  rings: const [
    RingZone(value: 10, outerDiameterMm: 10),
    RingZone(value: 9, outerDiameterMm: 20),
  ],
  lineThicknessMm: 0.2,
  lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
  validationStatus: ValidationStatus.experimental,
  bulls:
      bulls ??
      const [
        TargetBull(
          id: 'record-1',
          label: '1',
          centerXMm: -20,
          centerYMm: 0,
          role: TargetBullRole.record,
          scoringWidthMm: 30,
          scoringHeightMm: 30,
        ),
        TargetBull(
          id: 'record-2',
          label: '2',
          centerXMm: 20,
          centerYMm: 0,
          role: TargetBullRole.record,
          scoringWidthMm: 30,
          scoringHeightMm: 30,
        ),
      ],
  multiBullScoringPolicy: MultiBullScoringPolicy(
    recordBullCount: 2,
    maximumShotsPerBull: maximumShotsPerBull,
    duplicatePolicy: DuplicateShotPolicy.lowestScoreCounts,
    excessShotPenalty: 1,
    fixedMaximumScore: fixedMaximumScore,
  ),
);

void main() {
  test('valid target and impact pass runtime validation', () {
    expect(singleBullTarget().validateRuntime().isValid, isTrue);
    expect(multiBullTarget().validateRuntime().isValid, isTrue);
    expect(
      const ShotImpact(id: 'impact', xMm: 1, yMm: 2).validateRuntime().isValid,
      isTrue,
    );
  });

  test('invalid ring geometry is rejected at runtime', () {
    final result = singleBullTarget(
      rings: const [
        RingZone(value: 10, outerDiameterMm: 30),
        RingZone(value: 9, outerDiameterMm: 20),
      ],
    ).validateRuntime();

    expect(result.isValid, isFalse);
    expect(result.issues.map((issue) => issue.code), contains('ring_order'));
    expect(() => result.requireValid(), throwsArgumentError);
  });

  test('ambiguous and duplicate record bulls are rejected', () {
    final result = multiBullTarget(
      bulls: const [
        TargetBull(
          id: 'duplicate',
          label: '1',
          centerXMm: 0,
          centerYMm: 0,
          role: TargetBullRole.record,
          scoringWidthMm: 30,
          scoringHeightMm: 30,
        ),
        TargetBull(
          id: 'duplicate',
          label: '2',
          centerXMm: 10,
          centerYMm: 0,
          role: TargetBullRole.record,
          scoringWidthMm: 30,
          scoringHeightMm: 30,
        ),
      ],
    ).validateRuntime();

    final codes = result.issues.map((issue) => issue.code);
    expect(codes, contains('bull_id_duplicate'));
    expect(codes, contains('record_bulls_overlap'));
  });

  test('multi-bull policy must match supported score semantics', () {
    final result = multiBullTarget(
      maximumShotsPerBull: 2,
      fixedMaximumScore: 19,
    ).validateRuntime();

    final codes = result.issues.map((issue) => issue.code);
    expect(codes, contains('unsupported_maximum_shots_per_bull'));
    expect(codes, contains('fixed_maximum_score_mismatch'));
  });

  test('non-finite impact data is rejected beyond debug assertions', () {
    const invalid = ShotImpact(
      id: 'invalid',
      xMm: double.nan,
      yMm: 0,
      positionalUncertaintyMm: double.infinity,
    );
    final result = invalid.validateRuntime();

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      containsAll(['impact_position', 'impact_uncertainty']),
    );
  });

  test('photo alignment metadata roundtrips and is runtime validated', () {
    final alignment = StoredPhotoAlignment(
      imageId: 'image',
      orderedCorners: const [
        NormalizedPoint(x: 0.1, y: 0.1),
        NormalizedPoint(x: 0.9, y: 0.1),
        NormalizedPoint(x: 0.9, y: 0.9),
        NormalizedPoint(x: 0.1, y: 0.9),
      ],
      homographyMatrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
      algorithmVersion: 'ring-assisted-homography-v1',
      rotationQuarterTurns: 3,
      alignmentMode: 'ringAssisted',
      anchorsJson: '[{"id":"center"}]',
      reprojectionRmsMm: 0.4,
      reprojectionMaxMm: 0.9,
      planarityStatus: 'accepted',
      confirmedAtUtc: DateTime.utc(2026, 8, 9, 12),
      updatedAtUtc: DateTime.utc(2026, 8, 9, 12),
    );

    final restored = StoredPhotoAlignment.fromJson(alignment.toJson());
    expect(restored.rotationQuarterTurns, 3);
    expect(restored.alignmentMode, 'ringAssisted');
    expect(restored.anchorsJson, contains('center'));
    expect(restored.reprojectionRmsMm, 0.4);
    expect(restored.planarityStatus, 'accepted');

    expect(
      () => StoredPhotoAlignment(
        imageId: 'image',
        orderedCorners: const [],
        homographyMatrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
        algorithmVersion: 'invalid',
        updatedAtUtc: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });
}
