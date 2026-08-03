import 'geometry_models.dart';

enum QuadValidationIssue {
  nonFiniteCoordinate,
  pointOutsideImage,
  duplicatePoints,
  selfIntersecting,
  notConvex,
  wrongPointOrder,
  areaTooSmall,
}

class QuadValidationResult {
  const QuadValidationResult({
    required this.issues,
    required this.signedAreaFraction,
    required this.areaFraction,
    required this.minimumAreaFraction,
  });

  final List<QuadValidationIssue> issues;
  final double signedAreaFraction;
  final double areaFraction;
  final double minimumAreaFraction;

  bool get isValid => issues.isEmpty;
}

class QuadValidator {
  const QuadValidator._();

  static const double defaultMinimumAreaFraction = 0.20;
  static const double _epsilon = 1e-9;

  static QuadValidationResult validate(
    NormalizedQuad quad, {
    double minimumAreaFraction = defaultMinimumAreaFraction,
  }) {
    if (minimumAreaFraction < 0 || minimumAreaFraction > 1) {
      throw RangeError.range(minimumAreaFraction, 0, 1, 'minimumAreaFraction');
    }

    final points = quad.points;
    final issues = <QuadValidationIssue>[];

    if (points.any((point) => !point.isFinite)) {
      issues.add(QuadValidationIssue.nonFiniteCoordinate);
    }
    if (points.any((point) => !point.isInsideImage)) {
      issues.add(QuadValidationIssue.pointOutsideImage);
    }

    var hasDuplicates = false;
    for (var first = 0; first < points.length; first++) {
      for (var second = first + 1; second < points.length; second++) {
        if (points[first].distanceTo(points[second]) <= _epsilon) {
          hasDuplicates = true;
        }
      }
    }
    if (hasDuplicates) issues.add(QuadValidationIssue.duplicatePoints);

    final signedArea = _signedArea(points);
    final area = signedArea.abs();

    if (_segmentsProperlyIntersect(
          points[0],
          points[1],
          points[2],
          points[3],
        ) ||
        _segmentsProperlyIntersect(
          points[1],
          points[2],
          points[3],
          points[0],
        )) {
      issues.add(QuadValidationIssue.selfIntersecting);
    }

    final crosses = List<double>.generate(4, (index) {
      final first = points[index];
      final second = points[(index + 1) % 4];
      final third = points[(index + 2) % 4];
      return _cross(first, second, third);
    });
    final strictlyPositive = crosses.every((value) => value > _epsilon);
    final strictlyNegative = crosses.every((value) => value < -_epsilon);
    if (!strictlyPositive && !strictlyNegative) {
      issues.add(QuadValidationIssue.notConvex);
    }
    if (signedArea <= _epsilon) {
      issues.add(QuadValidationIssue.wrongPointOrder);
    }
    if (area + _epsilon < minimumAreaFraction) {
      issues.add(QuadValidationIssue.areaTooSmall);
    }

    return QuadValidationResult(
      issues: List.unmodifiable(issues.toSet()),
      signedAreaFraction: signedArea,
      areaFraction: area,
      minimumAreaFraction: minimumAreaFraction,
    );
  }

  static double _signedArea(List<NormalizedPoint> points) {
    var twiceArea = 0.0;
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      twiceArea += current.x * next.y - next.x * current.y;
    }
    return twiceArea / 2;
  }

  static double _cross(
    NormalizedPoint first,
    NormalizedPoint second,
    NormalizedPoint third,
  ) =>
      (second.x - first.x) * (third.y - second.y) -
      (second.y - first.y) * (third.x - second.x);

  static bool _segmentsProperlyIntersect(
    NormalizedPoint a,
    NormalizedPoint b,
    NormalizedPoint c,
    NormalizedPoint d,
  ) {
    final abC = _orientation(a, b, c);
    final abD = _orientation(a, b, d);
    final cdA = _orientation(c, d, a);
    final cdB = _orientation(c, d, b);
    return abC * abD < -_epsilon && cdA * cdB < -_epsilon;
  }

  static double _orientation(
    NormalizedPoint a,
    NormalizedPoint b,
    NormalizedPoint c,
  ) => (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
