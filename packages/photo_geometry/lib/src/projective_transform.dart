import 'dart:math' as math;

class TransformPoint {
  const TransformPoint(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(TransformPoint other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
}

class ProjectiveTransformFitResult {
  const ProjectiveTransformFitResult({
    required this.transform,
    required this.residuals,
    required this.rmsResidual,
    required this.maximumResidual,
    required this.conditionEstimate,
  });

  final ProjectiveTransform transform;
  final List<double> residuals;
  final double rmsResidual;
  final double maximumResidual;

  /// Pivot-ratio estimate from the normalized least-squares solve.
  ///
  /// It is intentionally exposed as an estimate, not as an exact matrix
  /// condition number. Large values are still a useful degeneracy warning.
  final double conditionEstimate;
}

/// Immutable 3x3 projective transform using row-major serialization.
class ProjectiveTransform {
  ProjectiveTransform(List<double> matrix)
    : matrix = List.unmodifiable(_canonicalize(matrix)) {
    if (matrix.length != 9 || matrix.any((value) => !value.isFinite)) {
      throw ArgumentError.value(
        matrix,
        'matrix',
        'A finite 3x3 row-major matrix is required.',
      );
    }
    if (_determinant(this.matrix).abs() < _epsilon) {
      throw ArgumentError.value(matrix, 'matrix', 'The matrix is singular.');
    }
  }

  static const double _epsilon = 1e-12;
  static const double _solverEpsilon = 1e-10;

  final List<double> matrix;

  /// Fits a homography to four or more corresponding point pairs.
  ///
  /// Extra pairs are fitted by a normalized QR least-squares solve, which is
  /// substantially better conditioned than forming unscaled normal equations.
  static ProjectiveTransformFitResult fitPointPairs({
    required List<TransformPoint> source,
    required List<TransformPoint> destination,
  }) {
    if (source.length != destination.length || source.length < 4) {
      throw ArgumentError(
        'At least four equally sized source and destination pairs are required.',
      );
    }
    if (source.any((point) => !point.x.isFinite || !point.y.isFinite) ||
        destination.any((point) => !point.x.isFinite || !point.y.isFinite)) {
      throw ArgumentError('All point coordinates must be finite.');
    }

    final normalizedSource = _PointNormalization.from(source);
    final normalizedDestination = _PointNormalization.from(destination);
    final rowCount = source.length * 2;
    final coefficients = List.generate(rowCount, (_) => List.filled(8, 0.0));
    final values = List.filled(rowCount, 0.0);

    for (var index = 0; index < source.length; index++) {
      final sourcePoint = normalizedSource.points[index];
      final destinationPoint = normalizedDestination.points[index];
      final x = sourcePoint.x;
      final y = sourcePoint.y;
      final u = destinationPoint.x;
      final v = destinationPoint.y;
      final firstRow = index * 2;
      final secondRow = firstRow + 1;

      coefficients[firstRow]
        ..[0] = x
        ..[1] = y
        ..[2] = 1
        ..[6] = -x * u
        ..[7] = -y * u;
      values[firstRow] = u;

      coefficients[secondRow]
        ..[3] = x
        ..[4] = y
        ..[5] = 1
        ..[6] = -x * v
        ..[7] = -y * v;
      values[secondRow] = v;
    }

    final solved = _solveLeastSquares(coefficients, values);
    final normalizedMatrix = [...solved.values, 1.0];
    final denormalized = _multiplyMatrices(
      normalizedDestination.inverseMatrix,
      _multiplyMatrices(normalizedMatrix, normalizedSource.matrix),
    );
    final transform = ProjectiveTransform(denormalized);
    final residuals = List<double>.generate(
      source.length,
      (index) => transform.apply(source[index]).distanceTo(destination[index]),
      growable: false,
    );
    final squaredTotal = residuals.fold<double>(
      0,
      (total, value) => total + value * value,
    );
    final maximum = residuals.fold<double>(0, math.max);
    return ProjectiveTransformFitResult(
      transform: transform,
      residuals: List.unmodifiable(residuals),
      rmsResidual: math.sqrt(squaredTotal / residuals.length),
      maximumResidual: maximum,
      conditionEstimate: solved.conditionEstimate,
    );
  }

  factory ProjectiveTransform.fromPointPairs({
    required List<TransformPoint> source,
    required List<TransformPoint> destination,
  }) => fitPointPairs(source: source, destination: destination).transform;

  TransformPoint apply(TransformPoint point) {
    final denominator = matrix[6] * point.x + matrix[7] * point.y + matrix[8];
    if (denominator.abs() < _epsilon) {
      throw StateError('The point maps to infinity for this transform.');
    }
    return TransformPoint(
      (matrix[0] * point.x + matrix[1] * point.y + matrix[2]) / denominator,
      (matrix[3] * point.x + matrix[4] * point.y + matrix[5]) / denominator,
    );
  }

  ProjectiveTransform inverse() {
    final m = matrix;
    final determinant = _determinant(m);
    if (determinant.abs() < _epsilon) {
      throw StateError('The projective transform is singular.');
    }
    return ProjectiveTransform([
      (m[4] * m[8] - m[5] * m[7]) / determinant,
      (m[2] * m[7] - m[1] * m[8]) / determinant,
      (m[1] * m[5] - m[2] * m[4]) / determinant,
      (m[5] * m[6] - m[3] * m[8]) / determinant,
      (m[0] * m[8] - m[2] * m[6]) / determinant,
      (m[2] * m[3] - m[0] * m[5]) / determinant,
      (m[3] * m[7] - m[4] * m[6]) / determinant,
      (m[1] * m[6] - m[0] * m[7]) / determinant,
      (m[0] * m[4] - m[1] * m[3]) / determinant,
    ]);
  }

  static _LinearSolveResult _solveLeastSquares(
    List<List<double>> coefficients,
    List<double> values,
  ) {
    final rowCount = coefficients.length;
    const columnCount = 8;
    if (rowCount < columnCount || values.length != rowCount) {
      throw ArgumentError('The homography system is underdetermined.');
    }

    final qColumns = <List<double>>[];
    final upper = List.generate(
      columnCount,
      (_) => List.filled(columnCount, 0.0),
    );
    var largestDiagonal = 0.0;
    var smallestDiagonal = double.infinity;

    for (var column = 0; column < columnCount; column++) {
      final vector = List<double>.generate(
        rowCount,
        (row) => coefficients[row][column],
      );
      for (var previous = 0; previous < column; previous++) {
        final projection = _dot(qColumns[previous], vector);
        upper[previous][column] = projection;
        for (var row = 0; row < rowCount; row++) {
          vector[row] -= projection * qColumns[previous][row];
        }
      }

      // A second orthogonalization pass limits loss of orthogonality for
      // difficult perspective configurations.
      for (var previous = 0; previous < column; previous++) {
        final correction = _dot(qColumns[previous], vector);
        upper[previous][column] += correction;
        for (var row = 0; row < rowCount; row++) {
          vector[row] -= correction * qColumns[previous][row];
        }
      }

      final norm = math.sqrt(_dot(vector, vector));
      largestDiagonal = math.max(largestDiagonal, norm);
      smallestDiagonal = math.min(smallestDiagonal, norm);
      if (!norm.isFinite || norm <= _solverEpsilon) {
        throw ArgumentError('The supplied points do not define a homography.');
      }
      upper[column][column] = norm;
      qColumns.add(
        List<double>.generate(rowCount, (row) => vector[row] / norm),
      );
    }

    final projected = List<double>.generate(
      columnCount,
      (column) => _dot(qColumns[column], values),
    );
    final result = List.filled(columnCount, 0.0);
    for (var row = columnCount - 1; row >= 0; row--) {
      var value = projected[row];
      for (var column = row + 1; column < columnCount; column++) {
        value -= upper[row][column] * result[column];
      }
      result[row] = value / upper[row][row];
    }
    return _LinearSolveResult(
      values: result,
      conditionEstimate: largestDiagonal / smallestDiagonal,
    );
  }

  static double _dot(List<double> first, List<double> second) {
    var result = 0.0;
    for (var index = 0; index < first.length; index++) {
      result += first[index] * second[index];
    }
    return result;
  }

  static List<double> _multiplyMatrices(List<double> a, List<double> b) {
    final result = List.filled(9, 0.0);
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        for (var inner = 0; inner < 3; inner++) {
          result[row * 3 + column] +=
              a[row * 3 + inner] * b[inner * 3 + column];
        }
      }
    }
    return result;
  }

  static List<double> _canonicalize(List<double> input) {
    if (input.length != 9 || input.any((value) => !value.isFinite)) {
      return List<double>.from(input);
    }
    final divisor = input[8].abs() > _epsilon
        ? input[8]
        : math.sqrt(input.fold<double>(0, (sum, value) => sum + value * value));
    if (!divisor.isFinite || divisor.abs() <= _epsilon) {
      return List<double>.from(input);
    }
    return input.map((value) => value / divisor).toList(growable: false);
  }

  static double _determinant(List<double> m) =>
      m[0] * (m[4] * m[8] - m[5] * m[7]) -
      m[1] * (m[3] * m[8] - m[5] * m[6]) +
      m[2] * (m[3] * m[7] - m[4] * m[6]);
}

class _PointNormalization {
  _PointNormalization._({
    required this.points,
    required this.matrix,
    required this.inverseMatrix,
  });

  final List<TransformPoint> points;
  final List<double> matrix;
  final List<double> inverseMatrix;

  factory _PointNormalization.from(List<TransformPoint> points) {
    final centreX =
        points.fold<double>(0, (sum, point) => sum + point.x) / points.length;
    final centreY =
        points.fold<double>(0, (sum, point) => sum + point.y) / points.length;
    final meanDistance =
        points.fold<double>(
          0,
          (sum, point) =>
              sum +
              math.sqrt(
                math.pow(point.x - centreX, 2) + math.pow(point.y - centreY, 2),
              ),
        ) /
        points.length;
    if (!meanDistance.isFinite ||
        meanDistance <= ProjectiveTransform._epsilon) {
      throw ArgumentError('The supplied points have no usable spatial extent.');
    }
    final scale = math.sqrt(2) / meanDistance;
    final matrix = [
      scale,
      0.0,
      -scale * centreX,
      0.0,
      scale,
      -scale * centreY,
      0.0,
      0.0,
      1.0,
    ];
    final inverse = [
      1 / scale,
      0.0,
      centreX,
      0.0,
      1 / scale,
      centreY,
      0.0,
      0.0,
      1.0,
    ];
    return _PointNormalization._(
      points: points
          .map(
            (point) => TransformPoint(
              scale * (point.x - centreX),
              scale * (point.y - centreY),
            ),
          )
          .toList(growable: false),
      matrix: matrix,
      inverseMatrix: inverse,
    );
  }
}

class _LinearSolveResult {
  const _LinearSolveResult({
    required this.values,
    required this.conditionEstimate,
  });

  final List<double> values;
  final double conditionEstimate;
}
