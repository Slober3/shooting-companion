import 'dart:math' as math;

/// A point expressed relative to the original image dimensions.
///
/// `(0, 0)` is the image's top-left and `(1, 1)` its bottom-right.
class NormalizedPoint {
  const NormalizedPoint(this.x, this.y);

  final double x;
  final double y;

  bool get isFinite => x.isFinite && y.isFinite;

  bool get isInsideImage => x >= 0 && x <= 1 && y >= 0 && y <= 1;

  double distanceTo(NormalizedPoint other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));

  Map<String, double> toJson() => {'x': x, 'y': y};

  factory NormalizedPoint.fromJson(Map<String, Object?> json) =>
      NormalizedPoint(
        (json['x']! as num).toDouble(),
        (json['y']! as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is NormalizedPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NormalizedPoint($x, $y)';
}

/// A position in the target card's physical coordinate system.
///
/// The target centre is `(0, 0)`. Positive x points right; positive y points
/// down, matching image coordinates.
class PhysicalPointMm {
  const PhysicalPointMm(this.x, this.y);

  final double x;
  final double y;

  bool get isFinite => x.isFinite && y.isFinite;

  Map<String, double> toJson() => {'x': x, 'y': y};

  factory PhysicalPointMm.fromJson(Map<String, Object?> json) =>
      PhysicalPointMm(
        (json['x']! as num).toDouble(),
        (json['y']! as num).toDouble(),
      );

  double distanceTo(PhysicalPointMm other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));

  @override
  bool operator ==(Object other) =>
      other is PhysicalPointMm && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PhysicalPointMm($x, $y)';
}

class PixelPoint {
  const PixelPoint(this.x, this.y);

  final double x;
  final double y;

  bool get isFinite => x.isFinite && y.isFinite;

  @override
  String toString() => 'PixelPoint($x, $y)';
}

class ImageDimensions {
  const ImageDimensions({required this.width, required this.height})
    : assert(width > 0),
      assert(height > 0);

  final double width;
  final double height;

  NormalizedPoint normalize(PixelPoint point) =>
      NormalizedPoint(point.x / width, point.y / height);

  PixelPoint denormalize(NormalizedPoint point) =>
      PixelPoint(point.x * width, point.y * height);
}

/// The target corners in the mandatory target-relative order TL, TR, BR, BL.
///
/// These labels follow the physical card, so the quad remains valid when a
/// photo is rotated. They do not mean the points must occupy those positions
/// on the phone screen.
class NormalizedQuad {
  const NormalizedQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final NormalizedPoint topLeft;
  final NormalizedPoint topRight;
  final NormalizedPoint bottomRight;
  final NormalizedPoint bottomLeft;

  List<NormalizedPoint> get points =>
      List.unmodifiable([topLeft, topRight, bottomRight, bottomLeft]);

  Map<String, Object> toJson() => {
    'topLeft': topLeft.toJson(),
    'topRight': topRight.toJson(),
    'bottomRight': bottomRight.toJson(),
    'bottomLeft': bottomLeft.toJson(),
  };

  factory NormalizedQuad.fromJson(Map<String, Object?> json) {
    Map<String, Object?> point(String key) =>
        (json[key]! as Map).cast<String, Object?>();

    return NormalizedQuad(
      topLeft: NormalizedPoint.fromJson(point('topLeft')),
      topRight: NormalizedPoint.fromJson(point('topRight')),
      bottomRight: NormalizedPoint.fromJson(point('bottomRight')),
      bottomLeft: NormalizedPoint.fromJson(point('bottomLeft')),
    );
  }

  factory NormalizedQuad.fromOrderedPoints(List<NormalizedPoint> points) {
    if (points.length != 4) {
      throw ArgumentError.value(
        points.length,
        'points.length',
        'A target quad requires exactly four ordered points.',
      );
    }
    return NormalizedQuad(
      topLeft: points[0],
      topRight: points[1],
      bottomRight: points[2],
      bottomLeft: points[3],
    );
  }
}
