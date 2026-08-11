import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:test/test.dart';

void main() {
  test('fake engine produces deterministic shot times', () async {
    final clock = FakeShotTimerClock(1000000);
    final engine = FakeShotTimerEngine(clock: clock);

    await engine.prepare(
      ShotTimerConfiguration(mode: ShotTimerMode.acousticLiveFire),
    );
    await engine.scheduleStart(const Duration(seconds: 2));
    clock.advance(const Duration(seconds: 2));
    engine.beginRun();
    clock.advance(const Duration(milliseconds: 800));
    engine.detectShot(normalizedPeak: 0.8);
    clock.advance(const Duration(milliseconds: 350));
    engine.detectShot(normalizedPeak: 0.9);

    final result = await engine.stop();

    expect(result.actualStartDelay, const Duration(seconds: 2));
    expect(result.firstShotTime, const Duration(milliseconds: 800));
    expect(result.averageSplit, const Duration(milliseconds: 350));
    expect(result.countedShotCount, 2);
    await engine.dispose();
  });
}
