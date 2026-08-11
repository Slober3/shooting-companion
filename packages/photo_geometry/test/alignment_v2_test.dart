import 'package:shooting_companion_photo_geometry/photo_geometry.dart';
import 'package:test/test.dart';

void main() {
  group('normalized projective fitting', () {
    test(
      'fits an overdetermined large-unit mapping with bounded residuals',
      () {
        const source = [
          TransformPoint(0.08, 0.12),
          TransformPoint(0.91, 0.07),
          TransformPoint(0.95, 0.90),
          TransformPoint(0.04, 0.86),
          TransformPoint(0.50, 0.48),
          TransformPoint(0.28, 0.37),
          TransformPoint(0.72, 0.62),
          TransformPoint(0.48, 0.78),
        ];
        final truth = ProjectiveTransform([
          8120,
          430,
          -4210,
          -275,
          6030,
          -2980,
          0.18,
          -0.11,
          1,
        ]);
        final destination = [
          for (var index = 0; index < source.length; index++)
            _withNoise(truth.apply(source[index]), index),
        ];

        final fit = ProjectiveTransform.fitPointPairs(
          source: source,
          destination: destination,
        );

        expect(fit.residuals, hasLength(source.length));
        expect(fit.rmsResidual, lessThan(0.08));
        expect(fit.maximumResidual, lessThan(0.15));
        expect(fit.conditionEstimate.isFinite, isTrue);
        expect(fit.conditionEstimate, lessThan(1e8));
        final check = fit.transform.apply(const TransformPoint(0.61, 0.33));
        final expected = truth.apply(const TransformPoint(0.61, 0.33));
        expect(check.x, closeTo(expected.x, 0.15));
        expect(check.y, closeTo(expected.y, 0.15));
      },
    );

    test('rejects a point set without two-dimensional extent', () {
      const collinear = [
        TransformPoint(0.1, 0.1),
        TransformPoint(0.2, 0.2),
        TransformPoint(0.3, 0.3),
        TransformPoint(0.4, 0.4),
      ];

      expect(
        () => ProjectiveTransform.fitPointPairs(
          source: collinear,
          destination: const [
            TransformPoint(-10, -10),
            TransformPoint(-5, -5),
            TransformPoint(5, 5),
            TransformPoint(10, 10),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ring-assisted alignment', () {
    test('builds, serializes, restores and maps cardinal ring anchors', () {
      final result = ManualPhotoAlignment.buildRingAssisted(
        center: const NormalizedPoint(0.5, 0.5),
        topDirection: const NormalizedPoint(0.5, 0.35),
        ringSeries: const [
          RingAnchorSeries(
            id: 'ring-30',
            radiusMm: 30,
            top: NormalizedPoint(0.5, 0.38),
            right: NormalizedPoint(0.62, 0.5),
            bottom: NormalizedPoint(0.5, 0.62),
            left: NormalizedPoint(0.38, 0.5),
          ),
          RingAnchorSeries(
            id: 'ring-60',
            radiusMm: 60,
            top: NormalizedPoint(0.5, 0.26),
            right: NormalizedPoint(0.74, 0.5),
            bottom: NormalizedPoint(0.5, 0.74),
            left: NormalizedPoint(0.26, 0.5),
          ),
        ],
        cardWidthMm: 200,
        cardHeightMm: 200,
        rotationQuarterTurns: 1,
      );

      expect(result.issues, isEmpty);
      final alignment = result.alignment!;
      expect(
        alignment.algorithmVersion,
        ringAssistedHomographyAlgorithmVersion,
      );
      expect(alignment.alignmentMode, PhotoAlignmentMode.ringAssisted);
      expect(alignment.rotationQuarterTurns, 1);
      expect(alignment.anchors, hasLength(10));
      expect(alignment.residuals.fittedAnchorCount, 9);
      expect(alignment.residuals.rmsMm, lessThan(1e-8));
      expect(alignment.quality, AlignmentQualityGrade.excellent);
      _expectPhysical(
        alignment.normalizedToPhysical(const NormalizedPoint(0.62, 0.5)),
        30,
        0,
      );

      final restored = ManualPhotoAlignment.fromJson(alignment.toJson());
      expect(restored.alignmentMode, PhotoAlignmentMode.ringAssisted);
      expect(restored.anchors, hasLength(10));
      expect(restored.rotationQuarterTurns, 1);
      _expectPhysical(
        restored.normalizedToPhysical(const NormalizedPoint(0.5, 0.26)),
        0,
        -60,
      );
    });

    test('supports cropped cards when all ring evidence is still visible', () {
      final result = ManualPhotoAlignment.buildRingAssisted(
        center: const NormalizedPoint(0.5, 0.5),
        topDirection: const NormalizedPoint(0.5, 0.35),
        ringSeries: const [
          RingAnchorSeries(
            id: 'ring-100',
            radiusMm: 100,
            top: NormalizedPoint(0.5, 0.3),
            right: NormalizedPoint(0.7, 0.5),
            bottom: NormalizedPoint(0.5, 0.7),
            left: NormalizedPoint(0.3, 0.5),
          ),
          RingAnchorSeries(
            id: 'ring-200',
            radiusMm: 200,
            top: NormalizedPoint(0.5, 0.1),
            right: NormalizedPoint(0.9, 0.5),
            bottom: NormalizedPoint(0.5, 0.9),
            left: NormalizedPoint(0.1, 0.5),
          ),
        ],
        cardWidthMm: 550,
        cardHeightMm: 550,
      );

      expect(result.isValid, isTrue);
      final corners = result.alignment!.corners;
      expect(corners.topLeft.x, closeTo(-0.05, 1e-8));
      expect(corners.topLeft.y, closeTo(-0.05, 1e-8));
      expect(corners.bottomRight.x, closeTo(1.05, 1e-8));
      expect(corners.bottomRight.y, closeTo(1.05, 1e-8));
    });

    test('requires two distinct, consistently oriented ring series', () {
      final tooFew = ManualPhotoAlignment.buildRingAssisted(
        center: const NormalizedPoint(0.5, 0.5),
        topDirection: const NormalizedPoint(0.5, 0.35),
        ringSeries: const [
          RingAnchorSeries(
            id: 'ring-30',
            radiusMm: 30,
            top: NormalizedPoint(0.5, 0.38),
            right: NormalizedPoint(0.62, 0.5),
            bottom: NormalizedPoint(0.5, 0.62),
            left: NormalizedPoint(0.38, 0.5),
          ),
        ],
        cardWidthMm: 200,
        cardHeightMm: 200,
      );
      expect(
        tooFew.issues,
        contains(RingAlignmentBuildIssue.insufficientRingSeries),
      );

      final mirrored = ManualPhotoAlignment.buildRingAssisted(
        center: const NormalizedPoint(0.5, 0.5),
        topDirection: const NormalizedPoint(0.5, 0.35),
        ringSeries: const [
          RingAnchorSeries(
            id: 'ring-30',
            radiusMm: 30,
            top: NormalizedPoint(0.5, 0.38),
            right: NormalizedPoint(0.38, 0.5),
            bottom: NormalizedPoint(0.5, 0.62),
            left: NormalizedPoint(0.62, 0.5),
          ),
          RingAnchorSeries(
            id: 'ring-60',
            radiusMm: 60,
            top: NormalizedPoint(0.5, 0.26),
            right: NormalizedPoint(0.26, 0.5),
            bottom: NormalizedPoint(0.5, 0.74),
            left: NormalizedPoint(0.74, 0.5),
          ),
        ],
        cardWidthMm: 200,
        cardHeightMm: 200,
      );
      expect(
        mirrored.issues,
        contains(RingAlignmentBuildIssue.inconsistentTopDirection),
      );
    });

    test('rejects a tampered stored ring-assisted matrix', () {
      final built = _ringAlignment();
      final json = built.toJson();
      final matrix = List<double>.from(
        json['homographyMatrix']! as List<double>,
      );
      matrix[2] += 2;
      json['homographyMatrix'] = matrix;

      expect(
        () => ManualPhotoAlignment.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

TransformPoint _withNoise(TransformPoint point, int index) {
  const noise = [
    TransformPoint(0.02, -0.01),
    TransformPoint(-0.03, 0.015),
    TransformPoint(0.01, 0.025),
    TransformPoint(-0.02, -0.015),
  ];
  final offset = noise[index % noise.length];
  return TransformPoint(point.x + offset.x, point.y + offset.y);
}

ManualPhotoAlignment _ringAlignment() {
  return ManualPhotoAlignment.buildRingAssisted(
    center: const NormalizedPoint(0.5, 0.5),
    topDirection: const NormalizedPoint(0.5, 0.35),
    ringSeries: const [
      RingAnchorSeries(
        id: 'ring-30',
        radiusMm: 30,
        top: NormalizedPoint(0.5, 0.38),
        right: NormalizedPoint(0.62, 0.5),
        bottom: NormalizedPoint(0.5, 0.62),
        left: NormalizedPoint(0.38, 0.5),
      ),
      RingAnchorSeries(
        id: 'ring-60',
        radiusMm: 60,
        top: NormalizedPoint(0.5, 0.26),
        right: NormalizedPoint(0.74, 0.5),
        bottom: NormalizedPoint(0.5, 0.74),
        left: NormalizedPoint(0.26, 0.5),
      ),
    ],
    cardWidthMm: 200,
    cardHeightMm: 200,
  ).alignment!;
}

void _expectPhysical(
  PhysicalPointMm actual,
  double expectedX,
  double expectedY,
) {
  expect(actual.x, closeTo(expectedX, 1e-7));
  expect(actual.y, closeTo(expectedY, 1e-7));
}
