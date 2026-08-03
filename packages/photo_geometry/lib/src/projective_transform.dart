class TransformPoint {
  const TransformPoint(this.x, this.y);

  final double x;
  final double y;
}

/// Immutable 3x3 projective transform using row-major serialization.
class ProjectiveTransform {
  ProjectiveTransform(List<double> matrix)
    : matrix = List.unmodifiable(matrix) {
    if (matrix.length != 9 || matrix.any((value) => !value.isFinite)) {
      throw ArgumentError.value(
        matrix,
        'matrix',
        'A finite 3x3 row-major matrix is required.',
      );
    }
    if (_determinant(matrix).abs() < _epsilon) {
      throw ArgumentError.value(matrix, 'matrix', 'The matrix is singular.');
    }
  }

  static const double _epsilon = 1e-12;

  final List<double> matrix;

  factory ProjectiveTransform.fromPointPairs({
    required List<TransformPoint> source,
    required List<TransformPoint> destination,
  }) {
    if (source.length != 4 || destination.length != 4) {
      throw ArgumentError(
        'Exactly four source and destination points are required.',
      );
    }
    if (source.any((point) => !point.x.isFinite || !point.y.isFinite) ||
        destination.any((point) => !point.x.isFinite || !point.y.isFinite)) {
      throw ArgumentError('All point coordinates must be finite.');
    }

    final coefficients = List.generate(8, (_) => List.filled(8, 0.0));
    final values = List.filled(8, 0.0);
    for (var index = 0; index < 4; index++) {
      final sourcePoint = source[index];
      final destinationPoint = destination[index];
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

    final solved = _solve(coefficients, values);
    return ProjectiveTransform([...solved, 1]);
  }

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

  static List<double> _solve(
    List<List<double>> coefficients,
    List<double> values,
  ) {
    final size = values.length;
    final augmented = List.generate(
      size,
      (row) => [...coefficients[row], values[row]],
    );

    for (var column = 0; column < size; column++) {
      var pivot = column;
      for (var row = column + 1; row < size; row++) {
        if (augmented[row][column].abs() > augmented[pivot][column].abs()) {
          pivot = row;
        }
      }
      if (augmented[pivot][column].abs() < _epsilon) {
        throw ArgumentError('The supplied points do not define a homography.');
      }
      if (pivot != column) {
        final temporary = augmented[column];
        augmented[column] = augmented[pivot];
        augmented[pivot] = temporary;
      }

      final divisor = augmented[column][column];
      for (var item = column; item <= size; item++) {
        augmented[column][item] /= divisor;
      }
      for (var row = 0; row < size; row++) {
        if (row == column) continue;
        final factor = augmented[row][column];
        if (factor.abs() < _epsilon) continue;
        for (var item = column; item <= size; item++) {
          augmented[row][item] -= factor * augmented[column][item];
        }
      }
    }
    return List.generate(size, (index) => augmented[index][size]);
  }

  static double _determinant(List<double> m) =>
      m[0] * (m[4] * m[8] - m[5] * m[7]) -
      m[1] * (m[3] * m[8] - m[5] * m[6]) +
      m[2] * (m[3] * m[7] - m[4] * m[6]);
}
