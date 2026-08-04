import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  final target = WrabfTargetProfiles.rimfire50mBr50;

  test('BR50 uses the official A3 geometry and 25 record bulls', () {
    expect(target.schemaVersion, 2);
    expect(target.targetKind, TargetKind.multiBullConcentric);
    expect(target.physicalCardWidthMm, 420);
    expect(target.physicalCardHeightMm, 297);
    expect(
      target.validationStatus,
      ValidationStatus.officialGeometryTrainingRendering,
    );
    expect(target.recordBulls, hasLength(25));
    expect(
      target.bulls.where((bull) => bull.role == TargetBullRole.sighter),
      hasLength(10),
    );
    expect(target.multiBullScoringPolicy!.fixedMaximumScore, 250);
  });

  test('BR50 survives target profile JSON roundtrip', () {
    final restored = TargetProfile.fromJsonString(target.toJsonString());
    expect(restored.targetKind, TargetKind.multiBullConcentric);
    expect(restored.rendererKind, TargetRendererKind.br50Training);
    expect(
      restored.recordBulls.map((bull) => bull.id),
      target.recordBulls.map((bull) => bull.id),
    );
    expect(restored.supportedDistancesMeters, [50]);
  });

  test('record bull centres follow the measured 55 mm grid', () {
    final records = target.recordBulls;
    expect(records[1].centerXMm - records[0].centerXMm, closeTo(55, 0.001));
    expect(records[5].centerYMm - records[0].centerYMm, closeTo(55, 0.001));
    expect(records.first.label, '1');
    expect(records.last.label, '25');
  });
}
