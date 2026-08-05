import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:test/test.dart';

void main() {
  group('ShotTimerConfiguration', () {
    test('round-trips every platform field', () {
      final value = ShotTimerConfiguration(
        mode: ShotTimerMode.acousticLiveFire,
        delayMode: ShotTimerDelayMode.random,
        randomDelayMinimum: const Duration(milliseconds: 1500),
        randomDelayMaximum: const Duration(milliseconds: 3500),
        parSignals: const [Duration(seconds: 3)],
        repetitions: 2,
        restDuration: const Duration(seconds: 5),
        maximumShots: 10,
        inactivityTimeout: const Duration(seconds: 2),
        outputSignals: const {
          ShotTimerOutputSignal.sound,
          ShotTimerOutputSignal.haptic,
        },
        calibration: const AcousticCalibrationSnapshot(
          profileId: 'indoor-22',
          sampleRate: 48000,
          sensitivity: 0.65,
          echoLockout: Duration(milliseconds: 80),
          beepBlanking: Duration(milliseconds: 160),
        ),
      );

      final restored = ShotTimerConfiguration.fromMap(value.toMap());

      expect(restored.mode, value.mode);
      expect(restored.delayMode, value.delayMode);
      expect(restored.randomDelayMinimum, value.randomDelayMinimum);
      expect(restored.randomDelayMaximum, value.randomDelayMaximum);
      expect(restored.parSignals, value.parSignals);
      expect(restored.outputSignals, value.outputSignals);
      expect(restored.calibration?.sampleRate, 48000);
      expect(restored.calibration?.sensitivity, 0.65);
    });

    test('rejects non-monotonic par signals', () {
      final value = ShotTimerConfiguration(
        mode: ShotTimerMode.par,
        parSignals: const [Duration(seconds: 2), Duration(seconds: 1)],
      );

      expect(value.validate, throwsArgumentError);
    });

    test('rejects invalid cadence', () {
      final value = ShotTimerConfiguration(mode: ShotTimerMode.cadence);

      expect(value.validate, throwsArgumentError);
    });
  });

  test('event maps preserve review provenance', () {
    const value = ShotTimerEvent(
      id: 'shot-3',
      sequenceNumber: 3,
      elapsed: Duration(milliseconds: 900),
      split: Duration(milliseconds: 310),
      source: ShotTimerEventSource.acoustic,
      disposition: ShotTimerEventDisposition.excluded,
      normalizedPeak: 0.91,
      detectionQuality: ShotTimerDetectionQuality.low,
      exclusionReason: 'echo',
    );

    final restored = ShotTimerEvent.fromMap(value.toMap());

    expect(restored.id, value.id);
    expect(restored.elapsed, value.elapsed);
    expect(restored.disposition, ShotTimerEventDisposition.excluded);
    expect(restored.exclusionReason, 'echo');
  });
}
