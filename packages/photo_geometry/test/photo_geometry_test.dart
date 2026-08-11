import 'package:shooting_companion_photo_geometry/photo_geometry.dart';
import 'package:test/test.dart';

void main() {
  const tolerance = 1e-7;

  group('ManualPhotoAlignment', () {
    test('identity quad maps the card centre and corners exactly', () {
      final alignment = _alignment(_identityQuad, width: 550, height: 550);

      _expectPhysical(
        alignment.normalizedToPhysical(const NormalizedPoint(0.5, 0.5)),
        0,
        0,
        tolerance,
      );
      _expectPhysical(
        alignment.normalizedToPhysical(const NormalizedPoint(0, 0)),
        -275,
        -275,
        tolerance,
      );
      _expectPhysical(
        alignment.normalizedToPhysical(const NormalizedPoint(1, 1)),
        275,
        275,
        tolerance,
      );
    });

    test('perspective quad maps all selected corners to physical corners', () {
      const quad = NormalizedQuad(
        topLeft: NormalizedPoint(0.08, 0.12),
        topRight: NormalizedPoint(0.88, 0.05),
        bottomRight: NormalizedPoint(0.96, 0.91),
        bottomLeft: NormalizedPoint(0.04, 0.84),
      );
      final alignment = _alignment(quad, width: 500, height: 400);

      final expected = [
        const PhysicalPointMm(-250, -200),
        const PhysicalPointMm(250, -200),
        const PhysicalPointMm(250, 200),
        const PhysicalPointMm(-250, 200),
      ];
      for (var index = 0; index < 4; index++) {
        final actual = alignment.normalizedToPhysical(quad.points[index]);
        _expectPhysical(
          actual,
          expected[index].x,
          expected[index].y,
          tolerance,
        );
      }
    });

    test('rotated target keeps target-relative corner order', () {
      const rotated = NormalizedQuad(
        topLeft: NormalizedPoint(0.9, 0.1),
        topRight: NormalizedPoint(0.9, 0.9),
        bottomRight: NormalizedPoint(0.1, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.1),
      );
      final result = ManualPhotoAlignment.build(
        corners: rotated,
        cardWidthMm: 600,
        cardHeightMm: 400,
      );

      expect(result.validation.isValid, isTrue);
      final alignment = result.alignment!;
      _expectPhysical(
        alignment.normalizedToPhysical(rotated.topRight),
        300,
        -200,
        tolerance,
      );
      _expectPhysical(
        alignment.normalizedToPhysical(rotated.bottomLeft),
        -300,
        200,
        tolerance,
      );
    });

    test('pixel to millimetre to pixel roundtrip remains stable', () {
      const quad = NormalizedQuad(
        topLeft: NormalizedPoint(0.12, 0.08),
        topRight: NormalizedPoint(0.91, 0.16),
        bottomRight: NormalizedPoint(0.82, 0.94),
        bottomLeft: NormalizedPoint(0.06, 0.79),
      );
      final alignment = _alignment(quad, width: 550, height: 550);
      const image = ImageDimensions(width: 4032, height: 3024);

      for (final pixel in const [
        PixelPoint(700, 500),
        PixelPoint(2016, 1512),
        PixelPoint(3280, 2490),
      ]) {
        final physical = alignment.pixelToPhysical(pixel, image);
        final roundtrip = alignment.physicalToPixel(physical, image);
        expect(roundtrip.x, closeTo(pixel.x, 1e-5));
        expect(roundtrip.y, closeTo(pixel.y, 1e-5));
      }
    });

    test('serialized matrix and corners reproduce the same result', () {
      final original = _alignment(_identityQuad, width: 550, height: 550);
      final restored = ManualPhotoAlignment.fromJson(original.toJson());
      const point = NormalizedPoint(0.31, 0.74);

      final expected = original.normalizedToPhysical(point);
      final actual = restored.normalizedToPhysical(point);
      _expectPhysical(actual, expected.x, expected.y, tolerance);
      expect(restored.algorithmVersion, manualHomographyV2AlgorithmVersion);
      expect(restored.alignmentMode, PhotoAlignmentMode.fourCorners);
      expect(restored.quality, AlignmentQualityGrade.excellent);
      expect(restored.anchors, hasLength(4));
      expect(restored.homographyMatrix, hasLength(9));
    });

    test('legacy manual-homography-v1 remains importable', () {
      final legacy = ManualPhotoAlignment.fromJson({
        'algorithmVersion': manualHomographyAlgorithmVersion,
        'cardWidthMm': 550,
        'cardHeightMm': 550,
        'corners': _identityQuad.toJson(),
        'homographyMatrix': const [550, 0, -275, 0, 550, -275, 0, 0, 1],
      });

      expect(legacy.algorithmVersion, manualHomographyAlgorithmVersion);
      expect(legacy.rotationQuarterTurns, 0);
      expect(legacy.alignmentMode, PhotoAlignmentMode.fourCorners);
      expect(legacy.quality, AlignmentQualityGrade.legacyUnverified);
      _expectPhysical(
        legacy.normalizedToPhysical(const NormalizedPoint(0.5, 0.5)),
        0,
        0,
        tolerance,
      );
    });

    test('rejects a stored matrix that disagrees with its corners', () {
      final json = _alignment(_identityQuad, width: 550, height: 550).toJson();
      json['homographyMatrix'] = const [550, 0, -274, 0, 550, -275, 0, 0, 1];

      expect(
        () => ManualPhotoAlignment.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rotation is serialized and coordinate rotation is reversible', () {
      final result = ManualPhotoAlignment.build(
        corners: _identityQuad,
        cardWidthMm: 550,
        cardHeightMm: 550,
        rotationQuarterTurns: 3,
      );
      final restored = ManualPhotoAlignment.fromJson(
        result.alignment!.toJson(),
      );
      const original = NormalizedPoint(0.2, 0.7);
      final rotated = rotateNormalizedPoint(original, 3);

      expect(restored.rotationQuarterTurns, 3);
      expect(unrotateNormalizedPoint(rotated, 3).x, closeTo(original.x, 1e-12));
      expect(unrotateNormalizedPoint(rotated, 3).y, closeTo(original.y, 1e-12));
    });
  });

  group('QuadValidator', () {
    test('rejects crossed corner order', () {
      const crossed = NormalizedQuad(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.9, 0.9),
        bottomRight: NormalizedPoint(0.9, 0.1),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );

      final result = QuadValidator.validate(crossed);
      expect(result.isValid, isFalse);
      expect(result.issues, contains(QuadValidationIssue.selfIntersecting));
    });

    test('rejects a concave card outline', () {
      const concave = NormalizedQuad(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.9, 0.1),
        bottomRight: NormalizedPoint(0.45, 0.45),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );

      final result = QuadValidator.validate(concave);
      expect(result.isValid, isFalse);
      expect(result.issues, contains(QuadValidationIssue.notConvex));
    });

    test('rejects an outline smaller than twenty percent', () {
      const small = NormalizedQuad(
        topLeft: NormalizedPoint(0.3, 0.3),
        topRight: NormalizedPoint(0.7, 0.3),
        bottomRight: NormalizedPoint(0.7, 0.7),
        bottomLeft: NormalizedPoint(0.3, 0.7),
      );

      final result = QuadValidator.validate(small);
      expect(result.areaFraction, closeTo(0.16, tolerance));
      expect(result.issues, contains(QuadValidationIssue.areaTooSmall));
    });

    test('rejects coordinates outside the photo', () {
      const outside = NormalizedQuad(
        topLeft: NormalizedPoint(-0.1, 0),
        topRight: NormalizedPoint(1, 0),
        bottomRight: NormalizedPoint(1, 1),
        bottomLeft: NormalizedPoint(0, 1),
      );

      final result = QuadValidator.validate(outside);
      expect(result.issues, contains(QuadValidationIssue.pointOutsideImage));
    });

    test('rejects clockwise target-relative point order', () {
      const reverseOrder = NormalizedQuad(
        topLeft: NormalizedPoint(0, 0),
        topRight: NormalizedPoint(0, 1),
        bottomRight: NormalizedPoint(1, 1),
        bottomLeft: NormalizedPoint(1, 0),
      );

      final result = QuadValidator.validate(reverseOrder);
      expect(result.issues, contains(QuadValidationIssue.wrongPointOrder));
    });

    test('rejects a nearly collapsed edge before homography fitting', () {
      const collapsed = NormalizedQuad(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.105, 0.1),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );

      final result = QuadValidator.validate(collapsed);
      expect(result.issues, contains(QuadValidationIssue.edgeTooShort));
    });

    test('rejects a nearly collinear vertex', () {
      const unstable = NormalizedQuad(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.5, 0.1001),
        bottomRight: NormalizedPoint(0.9, 0.101),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );

      final result = QuadValidator.validate(unstable, minimumAreaFraction: 0);
      expect(
        result.issues,
        contains(QuadValidationIssue.nearlyCollinearVertex),
      );
    });
  });
}

const _identityQuad = NormalizedQuad(
  topLeft: NormalizedPoint(0, 0),
  topRight: NormalizedPoint(1, 0),
  bottomRight: NormalizedPoint(1, 1),
  bottomLeft: NormalizedPoint(0, 1),
);

ManualPhotoAlignment _alignment(
  NormalizedQuad quad, {
  required double width,
  required double height,
}) {
  final result = ManualPhotoAlignment.build(
    corners: quad,
    cardWidthMm: width,
    cardHeightMm: height,
  );
  expect(result.validation.issues, isEmpty);
  return result.alignment!;
}

void _expectPhysical(
  PhysicalPointMm actual,
  double x,
  double y,
  double tolerance,
) {
  expect(actual.x, closeTo(x, tolerance));
  expect(actual.y, closeTo(y, tolerance));
}
