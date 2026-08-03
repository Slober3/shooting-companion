import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:test/test.dart';

void main() {
  test('calculates centroid and extreme spread', () {
    final metrics = GroupAnalyzer.calculate(const [
      ShotImpact(id: 'a', xMm: -5, yMm: 0),
      ShotImpact(id: 'b', xMm: 5, yMm: 0),
    ]);
    expect(metrics.centroidXMm, 0);
    expect(metrics.extremeSpreadMm, 10);
    expect(metrics.meanRadiusMm, 5);
    expect(metrics.milliradiansAt(25), closeTo(0.4, 0.0001));
  });
}
