import 'dart:math' as math;

import 'geometry_models.dart';
import 'projective_transform.dart';
import 'quad_validator.dart';

/// Legacy four-corner format. Existing databases and backups remain readable.
const manualHomographyAlgorithmVersion = 'manual-homography-v1';
const manualHomographyV2AlgorithmVersion = 'manual-homography-v2';
const ringAssistedHomographyAlgorithmVersion = 'ring-assisted-homography-v1';
const photoAlignmentSchemaVersion = 2;

class AlignmentBuildResult {
  const AlignmentBuildResult({required this.validation, this.alignment});

  final QuadValidationResult validation;
  final ManualPhotoAlignment? alignment;

  bool get isValid => validation.isValid && alignment != null;
}

enum RingAlignmentBuildIssue {
  invalidCenter,
  invalidTopDirection,
  insufficientRingSeries,
  invalidRingSeries,
  duplicateRingSeries,
  inconsistentTopDirection,
  unstableTransform,
  invalidEstimatedCardOutline,
}

class RingAlignmentBuildResult {
  const RingAlignmentBuildResult({required this.issues, this.alignment});

  final List<RingAlignmentBuildIssue> issues;
  final ManualPhotoAlignment? alignment;

  bool get isValid => issues.isEmpty && alignment != null;
}

/// Reproducible mapping between a rotated photo view and target millimetres.
///
/// The historical name is retained to avoid breaking app and backup callsites.
/// Version 2 can describe both a four-corner and a ring-assisted alignment.
class ManualPhotoAlignment {
  ManualPhotoAlignment._({
    required this.corners,
    required this.cardWidthMm,
    required this.cardHeightMm,
    required ProjectiveTransform normalizedToPhysicalTransform,
    required this.algorithmVersion,
    required this.rotationQuarterTurns,
    required this.alignmentMode,
    required List<PhotoAlignmentAnchor> anchors,
    required this.quality,
    required this.residuals,
  }) : anchors = List.unmodifiable(anchors),
       _normalizedToPhysical = normalizedToPhysicalTransform,
       _physicalToNormalized = normalizedToPhysicalTransform.inverse();

  final NormalizedQuad corners;
  final double cardWidthMm;
  final double cardHeightMm;
  final String algorithmVersion;
  final int rotationQuarterTurns;
  final PhotoAlignmentMode alignmentMode;
  final List<PhotoAlignmentAnchor> anchors;
  final AlignmentQualityGrade quality;
  final AlignmentResiduals residuals;
  final ProjectiveTransform _normalizedToPhysical;
  final ProjectiveTransform _physicalToNormalized;

  List<double> get homographyMatrix => _normalizedToPhysical.matrix;

  static AlignmentBuildResult build({
    required NormalizedQuad corners,
    required double cardWidthMm,
    required double cardHeightMm,
    int rotationQuarterTurns = 0,
    double minimumAreaFraction = QuadValidator.defaultMinimumAreaFraction,
  }) {
    _validateCardDimensions(cardWidthMm, cardHeightMm);
    _validateRotation(rotationQuarterTurns);
    final validation = QuadValidator.validate(
      corners,
      minimumAreaFraction: minimumAreaFraction,
    );
    if (!validation.isValid) {
      return AlignmentBuildResult(validation: validation);
    }

    final anchors = _manualCornerAnchors(corners, cardWidthMm, cardHeightMm);
    final fit = _fitAnchors(anchors);
    final residuals = _residualsFromFit(fit);
    return AlignmentBuildResult(
      validation: validation,
      alignment: ManualPhotoAlignment._(
        corners: corners,
        cardWidthMm: cardWidthMm,
        cardHeightMm: cardHeightMm,
        normalizedToPhysicalTransform: fit.transform,
        algorithmVersion: manualHomographyV2AlgorithmVersion,
        rotationQuarterTurns: rotationQuarterTurns,
        alignmentMode: PhotoAlignmentMode.fourCorners,
        anchors: anchors,
        quality: _qualityFor(residuals),
        residuals: residuals,
      ),
    );
  }

  /// Builds an alignment from the target centre and at least two known rings.
  ///
  /// Every ring contributes its target-relative top, right, bottom and left
  /// point. [topDirection] is a separate orientation guide and is retained in
  /// the stored anchors; it prevents a silently mirrored cardinal labelling.
  static RingAlignmentBuildResult buildRingAssisted({
    required NormalizedPoint center,
    required NormalizedPoint topDirection,
    required List<RingAnchorSeries> ringSeries,
    required double cardWidthMm,
    required double cardHeightMm,
    int rotationQuarterTurns = 0,
  }) {
    _validateCardDimensions(cardWidthMm, cardHeightMm);
    _validateRotation(rotationQuarterTurns);
    final issues = <RingAlignmentBuildIssue>[];
    if (!center.isFinite || !center.isInsideImage) {
      issues.add(RingAlignmentBuildIssue.invalidCenter);
    }
    if (!topDirection.isFinite ||
        !topDirection.isInsideImage ||
        (center.isFinite && center.distanceTo(topDirection) < 0.01)) {
      issues.add(RingAlignmentBuildIssue.invalidTopDirection);
    }
    if (ringSeries.length < 2) {
      issues.add(RingAlignmentBuildIssue.insufficientRingSeries);
    }

    final ids = <String>{};
    final radii = <double>[];
    final maximumRadius = math.min(cardWidthMm, cardHeightMm) / 2;
    for (final series in ringSeries) {
      if (!RegExp(r'^[a-zA-Z0-9._-]{1,64}$').hasMatch(series.id) ||
          !series.radiusMm.isFinite ||
          series.radiusMm <= 0 ||
          series.radiusMm > maximumRadius ||
          series.points.any(
            (point) => !point.isFinite || !point.isInsideImage,
          )) {
        issues.add(RingAlignmentBuildIssue.invalidRingSeries);
      }
      if (!ids.add(series.id) ||
          radii.any((radius) => (radius - series.radiusMm).abs() < 1e-6)) {
        issues.add(RingAlignmentBuildIssue.duplicateRingSeries);
      }
      radii.add(series.radiusMm);
    }

    if (issues.isEmpty &&
        !_directionsAreConsistent(center, topDirection, ringSeries)) {
      issues.add(RingAlignmentBuildIssue.inconsistentTopDirection);
    }
    if (issues.isNotEmpty) {
      return RingAlignmentBuildResult(
        issues: List.unmodifiable(issues.toSet()),
      );
    }

    final anchors = <PhotoAlignmentAnchor>[
      PhotoAlignmentAnchor(
        id: 'target.center',
        role: PhotoAlignmentAnchorRole.targetCenter,
        sourcePoint: center,
        physicalPointMm: const PhysicalPointMm(0, 0),
      ),
      PhotoAlignmentAnchor(
        id: 'target.top-direction',
        role: PhotoAlignmentAnchorRole.topDirection,
        sourcePoint: topDirection,
      ),
      for (final series in ringSeries) ...series.toAlignmentAnchors(),
    ];

    ProjectiveTransformFitResult fit;
    try {
      fit = _fitAnchors(anchors);
    } on ArgumentError {
      return const RingAlignmentBuildResult(
        issues: [RingAlignmentBuildIssue.unstableTransform],
      );
    }
    if (!fit.conditionEstimate.isFinite || fit.conditionEstimate > 1e12) {
      return const RingAlignmentBuildResult(
        issues: [RingAlignmentBuildIssue.unstableTransform],
      );
    }

    NormalizedQuad estimatedCorners;
    try {
      final inverse = fit.transform.inverse();
      final halfWidth = cardWidthMm / 2;
      final halfHeight = cardHeightMm / 2;
      final physicalCorners = [
        TransformPoint(-halfWidth, -halfHeight),
        TransformPoint(halfWidth, -halfHeight),
        TransformPoint(halfWidth, halfHeight),
        TransformPoint(-halfWidth, halfHeight),
      ];
      estimatedCorners = NormalizedQuad.fromOrderedPoints(
        physicalCorners
            .map((point) {
              final transformed = inverse.apply(point);
              return NormalizedPoint(transformed.x, transformed.y);
            })
            .toList(growable: false),
      );
    } on Object {
      return const RingAlignmentBuildResult(
        issues: [RingAlignmentBuildIssue.unstableTransform],
      );
    }
    final validation = QuadValidator.validate(
      estimatedCorners,
      minimumAreaFraction: 0,
      minimumEdgeLength: 0.001,
      requirePointsInsideImage: false,
    );
    if (!validation.isValid) {
      return const RingAlignmentBuildResult(
        issues: [RingAlignmentBuildIssue.invalidEstimatedCardOutline],
      );
    }

    final residuals = _residualsFromFit(fit);
    return RingAlignmentBuildResult(
      issues: const [],
      alignment: ManualPhotoAlignment._(
        corners: estimatedCorners,
        cardWidthMm: cardWidthMm,
        cardHeightMm: cardHeightMm,
        normalizedToPhysicalTransform: fit.transform,
        algorithmVersion: ringAssistedHomographyAlgorithmVersion,
        rotationQuarterTurns: rotationQuarterTurns,
        alignmentMode: PhotoAlignmentMode.ringAssisted,
        anchors: anchors,
        quality: _qualityFor(residuals),
        residuals: residuals,
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
    'alignmentMode': alignmentMode.name,
    'anchors': anchors.map((anchor) => anchor.toJson()).toList(),
    'cardHeightMm': cardHeightMm,
    'cardWidthMm': cardWidthMm,
    'corners': corners.toJson(),
    'homographyMatrix': homographyMatrix,
    'quality': quality.name,
    'residuals': residuals.toJson(),
    'rotationQuarterTurns': rotationQuarterTurns,
    'schemaVersion': photoAlignmentSchemaVersion,
  };

  factory ManualPhotoAlignment.fromJson(Map<String, Object?> json) {
    try {
      final schemaVersion = (json['schemaVersion'] as num?)?.toInt();
      if (schemaVersion != null &&
          schemaVersion > photoAlignmentSchemaVersion) {
        throw FormatException(
          'Unsupported photo-alignment schema: $schemaVersion',
        );
      }
      final algorithmVersion = json['algorithmVersion']! as String;
      final isLegacy = algorithmVersion == manualHomographyAlgorithmVersion;
      if (!isLegacy &&
          algorithmVersion != manualHomographyV2AlgorithmVersion &&
          algorithmVersion != ringAssistedHomographyAlgorithmVersion) {
        throw FormatException(
          'Unsupported photo-alignment algorithm: $algorithmVersion',
        );
      }
      final corners = NormalizedQuad.fromJson(
        (json['corners']! as Map).cast<String, Object?>(),
      );
      final cardWidthMm = (json['cardWidthMm']! as num).toDouble();
      final cardHeightMm = (json['cardHeightMm']! as num).toDouble();
      _validateStoredCardDimensions(cardWidthMm, cardHeightMm);
      final rotationQuarterTurns =
          (json['rotationQuarterTurns'] as num?)?.toInt() ?? 0;
      _validateStoredRotation(rotationQuarterTurns);
      final mode = json['alignmentMode'] == null
          ? PhotoAlignmentMode.fourCorners
          : PhotoAlignmentMode.values.byName(json['alignmentMode']! as String);
      if (isLegacy && mode != PhotoAlignmentMode.fourCorners) {
        throw const FormatException(
          'Legacy photo alignment must use four corners.',
        );
      }
      final validation = QuadValidator.validate(
        corners,
        minimumAreaFraction: mode == PhotoAlignmentMode.ringAssisted ? 0 : 0.20,
        minimumEdgeLength: mode == PhotoAlignmentMode.ringAssisted
            ? 0.001
            : 0.01,
        requirePointsInsideImage: mode == PhotoAlignmentMode.fourCorners,
      );
      if (!validation.isValid) {
        throw const FormatException(
          'Stored photo-alignment corners are invalid.',
        );
      }

      final rawAnchors = json['anchors'];
      final anchors = rawAnchors == null
          ? _manualCornerAnchors(corners, cardWidthMm, cardHeightMm)
          : (rawAnchors as List<Object?>)
                .map(
                  (value) => PhotoAlignmentAnchor.fromJson(
                    (value! as Map).cast<String, Object?>(),
                  ),
                )
                .toList(growable: false);
      _validateStoredAnchors(anchors, mode, cardWidthMm, cardHeightMm);
      final fit = _fitAnchors(anchors);
      final serializedMatrix = (json['homographyMatrix']! as List<Object?>)
          .map((value) => (value! as num).toDouble())
          .toList();
      final storedTransform = ProjectiveTransform(serializedMatrix);
      _crossCheckStoredMatrix(
        stored: storedTransform,
        recomputed: fit.transform,
        anchors: anchors,
        corners: corners,
        cardWidthMm: cardWidthMm,
        cardHeightMm: cardHeightMm,
      );
      final residuals = _residualsFor(storedTransform, anchors, fit);
      final quality = isLegacy
          ? AlignmentQualityGrade.legacyUnverified
          : _qualityFor(residuals);
      final storedQuality = json['quality'] as String?;
      if (storedQuality != null &&
          AlignmentQualityGrade.values.byName(storedQuality) != quality) {
        throw const FormatException(
          'Stored alignment quality is inconsistent.',
        );
      }
      return ManualPhotoAlignment._(
        corners: corners,
        cardWidthMm: cardWidthMm,
        cardHeightMm: cardHeightMm,
        normalizedToPhysicalTransform: storedTransform,
        algorithmVersion: algorithmVersion,
        rotationQuarterTurns: rotationQuarterTurns,
        alignmentMode: mode,
        anchors: anchors,
        quality: quality,
        residuals: residuals,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Stored photo alignment is invalid.', error);
    }
  }
}

List<PhotoAlignmentAnchor> _manualCornerAnchors(
  NormalizedQuad corners,
  double cardWidthMm,
  double cardHeightMm,
) {
  final halfWidth = cardWidthMm / 2;
  final halfHeight = cardHeightMm / 2;
  return [
    PhotoAlignmentAnchor(
      id: 'card.top-left',
      role: PhotoAlignmentAnchorRole.cornerTopLeft,
      sourcePoint: corners.topLeft,
      physicalPointMm: PhysicalPointMm(-halfWidth, -halfHeight),
    ),
    PhotoAlignmentAnchor(
      id: 'card.top-right',
      role: PhotoAlignmentAnchorRole.cornerTopRight,
      sourcePoint: corners.topRight,
      physicalPointMm: PhysicalPointMm(halfWidth, -halfHeight),
    ),
    PhotoAlignmentAnchor(
      id: 'card.bottom-right',
      role: PhotoAlignmentAnchorRole.cornerBottomRight,
      sourcePoint: corners.bottomRight,
      physicalPointMm: PhysicalPointMm(halfWidth, halfHeight),
    ),
    PhotoAlignmentAnchor(
      id: 'card.bottom-left',
      role: PhotoAlignmentAnchorRole.cornerBottomLeft,
      sourcePoint: corners.bottomLeft,
      physicalPointMm: PhysicalPointMm(-halfWidth, halfHeight),
    ),
  ];
}

ProjectiveTransformFitResult _fitAnchors(List<PhotoAlignmentAnchor> anchors) {
  final fitted = anchors.where((anchor) => anchor.contributesToFit).toList();
  if (fitted.length < 4) {
    throw ArgumentError('At least four metric alignment anchors are required.');
  }
  return ProjectiveTransform.fitPointPairs(
    source: fitted
        .map(
          (anchor) =>
              TransformPoint(anchor.sourcePoint.x, anchor.sourcePoint.y),
        )
        .toList(growable: false),
    destination: fitted
        .map(
          (anchor) => TransformPoint(
            anchor.physicalPointMm!.x,
            anchor.physicalPointMm!.y,
          ),
        )
        .toList(growable: false),
  );
}

AlignmentResiduals _residualsFromFit(ProjectiveTransformFitResult fit) =>
    AlignmentResiduals(
      anchorResidualsMm: List.unmodifiable(fit.residuals),
      rmsMm: fit.rmsResidual,
      maximumMm: fit.maximumResidual,
      conditionEstimate: fit.conditionEstimate,
    );

AlignmentResiduals _residualsFor(
  ProjectiveTransform transform,
  List<PhotoAlignmentAnchor> anchors,
  ProjectiveTransformFitResult fit,
) {
  final fitted = anchors.where((anchor) => anchor.contributesToFit);
  final values = fitted
      .map((anchor) {
        final mapped = transform.apply(
          TransformPoint(anchor.sourcePoint.x, anchor.sourcePoint.y),
        );
        final physical = anchor.physicalPointMm!;
        return mapped.distanceTo(TransformPoint(physical.x, physical.y));
      })
      .toList(growable: false);
  final squared = values.fold<double>(0, (sum, value) => sum + value * value);
  return AlignmentResiduals(
    anchorResidualsMm: List.unmodifiable(values),
    rmsMm: math.sqrt(squared / values.length),
    maximumMm: values.fold<double>(0, math.max),
    conditionEstimate: fit.conditionEstimate,
  );
}

AlignmentQualityGrade _qualityFor(AlignmentResiduals residuals) {
  if (!residuals.rmsMm.isFinite ||
      !residuals.maximumMm.isFinite ||
      !residuals.conditionEstimate.isFinite ||
      residuals.conditionEstimate > 1e10 ||
      residuals.rmsMm > 1.0 ||
      residuals.maximumMm > 2.0) {
    return AlignmentQualityGrade.reviewRequired;
  }
  if (residuals.conditionEstimate <= 1e8 &&
      residuals.rmsMm <= 0.5 &&
      residuals.maximumMm <= 1.0) {
    return AlignmentQualityGrade.excellent;
  }
  return AlignmentQualityGrade.acceptable;
}

bool _directionsAreConsistent(
  NormalizedPoint center,
  NormalizedPoint topDirection,
  List<RingAnchorSeries> series,
) {
  final upX = topDirection.x - center.x;
  final upY = topDirection.y - center.y;
  final upLength = math.sqrt(upX * upX + upY * upY);
  if (upLength <= 1e-9) return false;
  final ux = upX / upLength;
  final uy = upY / upLength;
  final rx = -uy;
  final ry = ux;
  for (final ring in series) {
    bool pointsTowards(NormalizedPoint point, double dx, double dy) {
      final x = point.x - center.x;
      final y = point.y - center.y;
      final length = math.sqrt(x * x + y * y);
      return length > 1e-6 && (x * dx + y * dy) / length > 0.15;
    }

    if (!pointsTowards(ring.top, ux, uy) ||
        !pointsTowards(ring.right, rx, ry) ||
        !pointsTowards(ring.bottom, -ux, -uy) ||
        !pointsTowards(ring.left, -rx, -ry)) {
      return false;
    }
  }
  return true;
}

void _crossCheckStoredMatrix({
  required ProjectiveTransform stored,
  required ProjectiveTransform recomputed,
  required List<PhotoAlignmentAnchor> anchors,
  required NormalizedQuad corners,
  required double cardWidthMm,
  required double cardHeightMm,
}) {
  final samples = <NormalizedPoint>{
    ...anchors.map((anchor) => anchor.sourcePoint),
    ...corners.points,
    const NormalizedPoint(0.5, 0.5),
  };
  final toleranceMm = math.max(cardWidthMm, cardHeightMm) * 1e-5 + 1e-6;
  try {
    for (final point in samples) {
      final source = TransformPoint(point.x, point.y);
      if (stored.apply(source).distanceTo(recomputed.apply(source)) >
          toleranceMm) {
        throw const FormatException(
          'Stored homography matrix does not match its alignment anchors.',
        );
      }
    }
    final halfWidth = cardWidthMm / 2;
    final halfHeight = cardHeightMm / 2;
    final expectedCorners = [
      TransformPoint(-halfWidth, -halfHeight),
      TransformPoint(halfWidth, -halfHeight),
      TransformPoint(halfWidth, halfHeight),
      TransformPoint(-halfWidth, halfHeight),
    ];
    for (var index = 0; index < corners.points.length; index++) {
      final point = corners.points[index];
      final mapped = stored.apply(TransformPoint(point.x, point.y));
      if (mapped.distanceTo(expectedCorners[index]) > toleranceMm) {
        throw const FormatException(
          'Stored homography matrix does not match its card outline.',
        );
      }
    }
  } on FormatException {
    rethrow;
  } on Object catch (error) {
    throw FormatException(
      'Stored homography matrix cannot be verified.',
      error,
    );
  }
}

void _validateStoredAnchors(
  List<PhotoAlignmentAnchor> anchors,
  PhotoAlignmentMode mode,
  double cardWidthMm,
  double cardHeightMm,
) {
  final ids = <String>{};
  for (final anchor in anchors) {
    if (!RegExp(r'^[a-zA-Z0-9._-]{1,64}$').hasMatch(anchor.id) ||
        !ids.add(anchor.id) ||
        !anchor.sourcePoint.isFinite ||
        !anchor.sourcePoint.isInsideImage ||
        (anchor.physicalPointMm != null && !anchor.physicalPointMm!.isFinite) ||
        (anchor.ringRadiusMm != null &&
            (!anchor.ringRadiusMm!.isFinite || anchor.ringRadiusMm! <= 0))) {
      throw const FormatException('Stored alignment anchors are invalid.');
    }
  }

  if (mode == PhotoAlignmentMode.fourCorners) {
    final expected = _manualCornerAnchors(
      NormalizedQuad.fromOrderedPoints(
        anchors.map((anchor) => anchor.sourcePoint).take(4).toList(),
      ),
      cardWidthMm,
      cardHeightMm,
    );
    if (anchors.length != 4) {
      throw const FormatException('Four-corner alignment needs four anchors.');
    }
    for (var index = 0; index < expected.length; index++) {
      if (anchors[index].role != expected[index].role ||
          anchors[index].physicalPointMm != expected[index].physicalPointMm) {
        throw const FormatException('Stored corner anchors are inconsistent.');
      }
    }
    return;
  }

  if (anchors
              .where((a) => a.role == PhotoAlignmentAnchorRole.targetCenter)
              .length !=
          1 ||
      anchors
              .where((a) => a.role == PhotoAlignmentAnchorRole.topDirection)
              .length !=
          1) {
    throw const FormatException(
      'Ring alignment needs one centre and one top-direction anchor.',
    );
  }
  final center = anchors.singleWhere(
    (a) => a.role == PhotoAlignmentAnchorRole.targetCenter,
  );
  final topDirection = anchors.singleWhere(
    (a) => a.role == PhotoAlignmentAnchorRole.topDirection,
  );
  if (center.physicalPointMm != const PhysicalPointMm(0, 0) ||
      topDirection.physicalPointMm != null) {
    throw const FormatException('Stored ring orientation anchors are invalid.');
  }
  final grouped = <String, List<PhotoAlignmentAnchor>>{};
  for (final anchor in anchors.where((a) => a.seriesId != null)) {
    grouped.putIfAbsent(anchor.seriesId!, () => []).add(anchor);
  }
  if (grouped.length < 2) {
    throw const FormatException('Ring alignment needs at least two rings.');
  }
  for (final entry in grouped.entries) {
    if (entry.value.length != 4 ||
        entry.value.map((a) => a.role).toSet().length != 4 ||
        entry.value.any((a) => a.ringRadiusMm == null)) {
      throw const FormatException('Stored ring anchors are incomplete.');
    }
  }
}

void _validateCardDimensions(double width, double height) {
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    throw ArgumentError(
      'Card dimensions must be finite and greater than zero.',
    );
  }
}

void _validateStoredCardDimensions(double width, double height) {
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    throw const FormatException('Stored card dimensions are invalid.');
  }
}

void _validateRotation(int rotationQuarterTurns) {
  if (rotationQuarterTurns < 0 || rotationQuarterTurns > 3) {
    throw RangeError.range(rotationQuarterTurns, 0, 3, 'rotationQuarterTurns');
  }
}

void _validateStoredRotation(int rotationQuarterTurns) {
  if (rotationQuarterTurns < 0 || rotationQuarterTurns > 3) {
    throw const FormatException('Stored photo rotation is invalid.');
  }
}
