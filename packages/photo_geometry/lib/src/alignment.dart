import 'geometry_models.dart';
import 'projective_transform.dart';
import 'quad_validator.dart';

const manualHomographyAlgorithmVersion = 'manual-homography-v1';

class AlignmentBuildResult {
  const AlignmentBuildResult({required this.validation, this.alignment});

  final QuadValidationResult validation;
  final ManualPhotoAlignment? alignment;

  bool get isValid => validation.isValid && alignment != null;
}

/// Reproducible manual mapping between an immutable photo and target millimetres.
class ManualPhotoAlignment {
  ManualPhotoAlignment._({
    required this.corners,
    required this.cardWidthMm,
    required this.cardHeightMm,
    required ProjectiveTransform normalizedToPhysicalTransform,
    required this.algorithmVersion,
  }) : _normalizedToPhysical = normalizedToPhysicalTransform,
       _physicalToNormalized = normalizedToPhysicalTransform.inverse();

  final NormalizedQuad corners;
  final double cardWidthMm;
  final double cardHeightMm;
  final String algorithmVersion;
  final ProjectiveTransform _normalizedToPhysical;
  final ProjectiveTransform _physicalToNormalized;

  List<double> get homographyMatrix => _normalizedToPhysical.matrix;

  static AlignmentBuildResult build({
    required NormalizedQuad corners,
    required double cardWidthMm,
    required double cardHeightMm,
    double minimumAreaFraction = QuadValidator.defaultMinimumAreaFraction,
  }) {
    if (!cardWidthMm.isFinite ||
        !cardHeightMm.isFinite ||
        cardWidthMm <= 0 ||
        cardHeightMm <= 0) {
      throw ArgumentError(
        'Card dimensions must be finite and greater than zero.',
      );
    }
    final validation = QuadValidator.validate(
      corners,
      minimumAreaFraction: minimumAreaFraction,
    );
    if (!validation.isValid) {
      return AlignmentBuildResult(validation: validation);
    }

    final halfWidth = cardWidthMm / 2;
    final halfHeight = cardHeightMm / 2;
    final transform = ProjectiveTransform.fromPointPairs(
      source: corners.points
          .map((point) => TransformPoint(point.x, point.y))
          .toList(),
      destination: [
        TransformPoint(-halfWidth, -halfHeight),
        TransformPoint(halfWidth, -halfHeight),
        TransformPoint(halfWidth, halfHeight),
        TransformPoint(-halfWidth, halfHeight),
      ],
    );
    return AlignmentBuildResult(
      validation: validation,
      alignment: ManualPhotoAlignment._(
        corners: corners,
        cardWidthMm: cardWidthMm,
        cardHeightMm: cardHeightMm,
        normalizedToPhysicalTransform: transform,
        algorithmVersion: manualHomographyAlgorithmVersion,
      ),
    );
  }

  PhysicalPointMm normalizedToPhysical(NormalizedPoint point) {
    final transformed = _normalizedToPhysical.apply(
      TransformPoint(point.x, point.y),
    );
    return PhysicalPointMm(transformed.x, transformed.y);
  }

  NormalizedPoint physicalToNormalized(PhysicalPointMm point) {
    final transformed = _physicalToNormalized.apply(
      TransformPoint(point.x, point.y),
    );
    return NormalizedPoint(transformed.x, transformed.y);
  }

  PhysicalPointMm pixelToPhysical(PixelPoint point, ImageDimensions image) =>
      normalizedToPhysical(image.normalize(point));

  PixelPoint physicalToPixel(PhysicalPointMm point, ImageDimensions image) =>
      image.denormalize(physicalToNormalized(point));

  Map<String, Object> toJson() => {
    'algorithmVersion': algorithmVersion,
    'cardWidthMm': cardWidthMm,
    'cardHeightMm': cardHeightMm,
    'corners': corners.toJson(),
    'homographyMatrix': homographyMatrix,
  };

  factory ManualPhotoAlignment.fromJson(Map<String, Object?> json) {
    final algorithmVersion = json['algorithmVersion']! as String;
    if (algorithmVersion != manualHomographyAlgorithmVersion) {
      throw FormatException(
        'Unsupported photo-alignment algorithm: $algorithmVersion',
      );
    }
    final corners = NormalizedQuad.fromJson(
      (json['corners']! as Map).cast<String, Object?>(),
    );
    final cardWidthMm = (json['cardWidthMm']! as num).toDouble();
    final cardHeightMm = (json['cardHeightMm']! as num).toDouble();
    final validation = QuadValidator.validate(corners);
    if (!validation.isValid) {
      throw const FormatException(
        'Stored photo-alignment corners are invalid.',
      );
    }
    if (!cardWidthMm.isFinite ||
        !cardHeightMm.isFinite ||
        cardWidthMm <= 0 ||
        cardHeightMm <= 0) {
      throw const FormatException('Stored card dimensions are invalid.');
    }
    final serializedMatrix = (json['homographyMatrix']! as List<Object?>)
        .map((value) => (value! as num).toDouble())
        .toList();
    try {
      return ManualPhotoAlignment._(
        corners: corners,
        cardWidthMm: cardWidthMm,
        cardHeightMm: cardHeightMm,
        normalizedToPhysicalTransform: ProjectiveTransform(serializedMatrix),
        algorithmVersion: algorithmVersion,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Stored homography matrix is invalid.', error);
    }
  }
}
