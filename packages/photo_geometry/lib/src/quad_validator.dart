import 'dart:math' as math;

import 'geometry_models.dart';

enum QuadValidationIssue {
  nonFiniteCoordinate,
  pointOutsideImage,
  duplicatePoints,
  edgeTooShort,
  selfIntersecting,
  notConvex,
  nearlyCollinearVertex,
  wrongPointOrder,
  areaTooSmall,
}

class QuadValidationResult {
  const QuadValidationResult({
    required this.issues,
    required this.signedAreaFraction,
    required this.areaFraction,
    required this.minimumAreaFraction,
    required this.minimumEdgeLength,
    required this.smallestEdgeLength,
    required this.smallestVertexSine,
  });

  final List<QuadValidationIssue> issues;
  final double signedAreaFraction;
  final double areaFraction;
  final double minimumAreaFraction;
  final double minimumEdgeLength;
  final double smallestEdgeLength;
  final double smallestVertexSine;

  bool get isValid => issues.isEmpty;
}

class QuadValidator {
  const QuadValidator._();

  static const double defaultMinimumAreaFraction = 0.20;
  static const double defaultMinimumEdgeLength = 0.01;
  static const double defaultMinimumVertexSine = 0.01;
  static const double _epsilon = 1e-9;

  static QuadValidationResult validate(
    NormalizedQuad quad, {
    double minimumAreaFraction = defaultMinimumAreaFraction,
    double minimumEdgeLength = defaultMinimumEdgeLength,
    double minimumVertexSine = defaultMinimumVertexSine,
    bool requirePointsInsideImage = true,
  }) {
    if (minimumAreaFraction < 0 || minimumAreaFraction > 1) {
      throw RangeError.range(minimumAreaFraction, 0, 1, 'minimumAreaFraction');
    }
    if (!minimumEdgeLength.isFinite || minimumEdgeLength < 0) {
      throw RangeError.value(minimumEdgeLength, 'minimumEdgeLength');
    }
    if (!minimumVertexSine.isFinite ||
        minimumVertexSine < 0 ||
        minimumVertexSine > 1) {
      throw RangeError.range(minimumVertexSine, 0, 1, 'minimumVertexSine');
    }

    final points = quad.points;
    final issues = <QuadValidationIssue>[];
    final allFinite = points.every((point) => point.isFinite);
    if (!allFinite) {
      issues.add(QuadValidationIssue.nonFiniteCoordinate);
    }
    if (requirePointsInsideImage &&
        points.any((point) => !point.isInsideImage)) {
      issues.add(QuadValidationIssue.pointOutsideImage);
    }

    var signedArea = double.nan;
    var area = double.nan;
    var smallestEdge = double.nan;
    var smallestSine = double.nan;
    if (allFinite) {
      var hasDuplicates = false;
      for (var first = 0; first < points.length; first++) {
        for (var second = first + 1; second < points.length; second++) {
          if (points[first].distanceTo(points[second]) <= _epsilon) {
            hasDuplicates = true;
          }
        }
      }
      if (hasDuplicates) issues.add(QuadValidationIssue.duplicatePoints);

      final edgeLengths = List<double>.generate(
        points.length,
        (index) => points[index].distanceTo(points[(index + 1) % 4]),
      );
      smallestEdge = edgeLengths.fold<double>(double.infinity, math.min);
      if (smallestEdge + _epsilon < minimumEdgeLength) {
        issues.add(QuadValidationIssue.edgeTooShort);
      }

      signedArea = _signedArea(points);
      area = signedArea.abs();
      if (_segmentsIntersect(points[0], points[1], points[2], points[3]) ||
          _segmentsIntersect(points[1], points[2], points[3], points[0])) {
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

      final vertexSines = List<double>.generate(4, (index) {
        final previous = points[(index + 3) % 4];
        final vertex = points[index];
        final next = points[(index + 1) % 4];
        final firstX = previous.x - vertex.x;
        final firstY = previous.y - vertex.y;
        final secondX = next.x - vertex.x;
        final secondY = next.y - vertex.y;
        final denominator = math.sqrt(
          (firstX * firstX + firstY * firstY) *
              (secondX * secondX + secondY * secondY),
        );
        if (denominator <= _epsilon) return 0;
        return (firstX * secondY - firstY * secondX).abs() / denominator;
      });
      smallestSine = vertexSines.fold<double>(double.infinity, math.min);
      if (smallestSine + _epsilon < minimumVertexSine) {
        issues.add(QuadValidationIssue.nearlyCollinearVertex);
      }
      if (signedArea <= _epsilon) {
        issues.add(QuadValidationIssue.wrongPointOrder);
      }
      if (area + _epsilon < minimumAreaFraction) {
        issues.add(QuadValidationIssue.areaTooSmall);
      }
    }

    return QuadValidationResult(
      issues: List.unmodifiable(issues.toSet()),
      signedAreaFraction: signedArea,
      areaFraction: area,
      minimumAreaFraction: minimumAreaFraction,
      minimumEdgeLength: minimumEdgeLength,
      smallestEdgeLength: smallestEdge,
      smallestVertexSine: smallestSine,
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

  static bool _segmentsIntersect(
    NormalizedPoint a,
    NormalizedPoint b,
    NormalizedPoint c,
    NormalizedPoint d,
  ) {
    final abC = _orientation(a, b, c);
    final abD = _orientation(a, b, d);
    final cdA = _orientation(c, d, a);
    final cdB = _orientation(c, d, b);
    if (abC * abD < -_epsilon && cdA * cdB < -_epsilon) return true;
    return (abC.abs() <= _epsilon && _onSegment(a, b, c)) ||
        (abD.abs() <= _epsilon && _onSegment(a, b, d)) ||
        (cdA.abs() <= _epsilon && _onSegment(c, d, a)) ||
        (cdB.abs() <= _epsilon && _onSegment(c, d, b));
  }

  static bool _onSegment(
    NormalizedPoint a,
    NormalizedPoint b,
    NormalizedPoint point,
  ) =>
      point.x >= math.min(a.x, b.x) - _epsilon &&
      point.x <= math.max(a.x, b.x) + _epsilon &&
      point.y >= math.min(a.y, b.y) - _epsilon &&
      point.y <= math.max(a.y, b.y) + _epsilon;

  static double _orientation(
    NormalizedPoint a,
    NormalizedPoint b,
    NormalizedPoint c,
  ) => (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
