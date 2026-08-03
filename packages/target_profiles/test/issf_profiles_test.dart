import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  test('ISSF precision profile contains ten immutable scoring rings', () {
    final profile = IssfTargetProfiles.precision25m50m;
    expect(profile.rings, hasLength(10));
    expect(profile.rings.first.value, 10);
    expect(profile.rings.last.outerDiameterMm, 500);
    expect(profile.innerTenDiameterMm, 25);
  });

  test('ISSF rapid-fire profile follows 2026 diameters', () {
    final profile = IssfTargetProfiles.rapidFire25m;
    expect(profile.rings.map((ring) => ring.outerDiameterMm), [
      100,
      180,
      260,
      340,
      420,
      500,
    ]);
    expect(profile.innerTenDiameterMm, 50);
  });

  test('target profile JSON roundtrip keeps version identity', () {
    final source = IssfTargetProfiles.precision25m50m;
    final restored = source.toJsonString();
    expect(restored, contains(source.profileId));
  });
}
