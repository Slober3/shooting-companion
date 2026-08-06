import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

enum PhotoCanvasImpactStyle { confirmed, needsReview, suggestion }

/// A database-independent impact rendered on an aligned target photo.
class PhotoCanvasImpact {
  const PhotoCanvasImpact({
    required this.id,
    required this.positionMm,
    required this.sequenceNumber,
    this.scoreLabel,
    this.multiplicity = 1,
    this.isPositionUncertain = false,
    this.style = PhotoCanvasImpactStyle.confirmed,
  }) : assert(multiplicity > 0),
       assert(sequenceNumber > 0);

  final String id;
  final PhysicalPointMm positionMm;
  final int sequenceNumber;
  final String? scoreLabel;
  final int multiplicity;
  final bool isPositionUncertain;
  final PhotoCanvasImpactStyle style;
}

/// Both coordinate representations returned for a manual tap or drag.
class PhotoCanvasPosition {
  const PhotoCanvasPosition({
    required this.normalized,
    required this.physicalMm,
  });

  final NormalizedPoint normalized;
  final PhysicalPointMm physicalMm;
}

typedef PhotoImpactMoved =
    void Function(String impactId, PhotoCanvasPosition position);
