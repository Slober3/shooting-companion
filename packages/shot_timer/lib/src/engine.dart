import 'models.dart';

abstract interface class ShotTimerEngine {
  ShotTimerSnapshot get snapshot;
  Stream<ShotTimerSnapshot> get snapshots;
  Stream<double> get normalizedAudioLevels;

  Future<void> prepare(ShotTimerConfiguration configuration);
  Future<void> start();
  Future<ShotTimerResult> stop();
  Future<void> abort(String reason);
  Future<void> dispose();
}

abstract interface class ShotTimerClock {
  int get monotonicMicroseconds;
}

class StopwatchShotTimerClock implements ShotTimerClock {
  StopwatchShotTimerClock() : _stopwatch = Stopwatch()..start();
  final Stopwatch _stopwatch;

  @override
  int get monotonicMicroseconds => _stopwatch.elapsedMicroseconds;
}

abstract interface class ShotTimerSignalOutput {
  Future<void> emit(
    ShotTimerSignalKind kind,
    Set<ShotTimerOutputSignal> outputs,
  );
}

abstract interface class CancellableShotTimerTask {
  bool get isCancelled;
  void cancel();
}

abstract interface class ShotTimerScheduler {
  CancellableShotTimerTask schedule(Duration delay, void Function() callback);
}
