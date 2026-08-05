import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/progress/potential_score_compute_service.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  test('worker round-trips only sendable data and returns a result', () async {
    final request = PotentialScoreComputeRequest(
      seriesId: 'series',
      seriesUpdatedAtUtc: DateTime.utc(2026, 8, 5),
      target: IssfTargetProfiles.precision25m50m,
      projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
      impacts: const [
        ShotImpact(id: 'a', xMm: 40, yMm: 0),
        ShotImpact(
          id: 'b',
          xMm: 42,
          yMm: 1,
          multiplicity: 2,
          isPositionUncertain: true,
          rawScoreValue: 5,
        ),
      ],
    );

    final workerMessage = potentialScoreWorker(request.toMessage());
    expect(workerMessage['bestScore'], greaterThanOrEqualTo(15));

    final response = await PotentialScoreComputeService().calculate(request);
    expect(
      response.result.bestScore,
      greaterThanOrEqualTo(response.result.currentScore),
    );
    expect(response.calculationFingerprint, request.calculationFingerprint);
  });
}
