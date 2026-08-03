import 'package:shooting_companion_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('target profile JSON roundtrip preserves immutable identity', () {
    final source = TargetProfile(
      schemaVersion: 1,
      profileId: 'test-target',
      profileVersion: 2,
      displayName: 'Test target',
      authority: 'Test',
      rulesEdition: '1',
      physicalCardWidthMm: 100,
      physicalCardHeightMm: 100,
      rings: const [RingZone(value: 10, outerDiameterMm: 20)],
      lineThicknessMm: 0.5,
      lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
      validationStatus: ValidationStatus.experimental,
    );

    final restored = TargetProfile.fromJsonString(source.toJsonString());

    expect(restored.versionedId, 'test-target@2');
    expect(restored.rings.single.outerDiameterMm, 20);
  });

  test('legacy target JSON ignores removed capture-mode metadata', () {
    final legacy = <String, Object?>{
      'schemaVersion': 1,
      'profileId': 'legacy-target',
      'profileVersion': 1,
      'displayName': 'Legacy',
      'authority': 'Test',
      'rulesEdition': '1',
      'targetKind': 'concentricRings',
      'physicalCardWidthMm': 100,
      'physicalCardHeightMm': 100,
      'rings': <Object?>[
        <String, Object>{'value': 10, 'outerDiameterMm': 20},
      ],
      'lineThicknessMm': 0.5,
      'lineBreakingRule': 'bulletEdgeTouchesHigherRing',
      'supportedCaptureModes': <String>['singleImage', 'manual'],
      'validationStatus': 'experimental',
    };

    final restored = TargetProfile.fromJson(legacy);

    expect(restored.versionedId, 'legacy-target@1');
    expect(restored.toJson(), isNot(contains('supportedCaptureModes')));
  });

  test('photo coordinates must be supplied as a normalized pair', () {
    expect(
      () => ShotImpact(id: 'invalid', xMm: 0, yMm: 0, imageXNormalized: 0.5),
      throwsA(isA<AssertionError>()),
    );

    const impact = ShotImpact(
      id: 'photo-impact',
      xMm: 1,
      yMm: 2,
      sourceImageId: 'image',
      imageXNormalized: 0.25,
      imageYNormalized: 0.75,
    );
    expect(impact.imageXNormalized, 0.25);
    expect(impact.copyWith(clearSourceImage: true).sourceImageId, isNull);
  });

  test('photo alignment JSON roundtrip preserves geometry', () {
    final source = StoredPhotoAlignment(
      imageId: 'image',
      orderedCorners: const [
        NormalizedPoint(x: 0.1, y: 0.1),
        NormalizedPoint(x: 0.9, y: 0.1),
        NormalizedPoint(x: 0.9, y: 0.9),
        NormalizedPoint(x: 0.1, y: 0.9),
      ],
      homographyMatrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
      algorithmVersion: 'manual-homography-v1',
      updatedAtUtc: DateTime.utc(2026, 8, 3),
    );

    final restored = StoredPhotoAlignment.fromJson(source.toJson());

    expect(restored.orderedCorners, hasLength(4));
    expect(restored.homographyMatrix, hasLength(9));
    expect(restored.updatedAtUtc, DateTime.utc(2026, 8, 3));
  });
}
