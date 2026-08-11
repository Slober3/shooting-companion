import 'dart:async';

import 'engine.dart';
import 'models.dart';
import 'state_machine.dart';
import 'statistics.dart';

class FakeShotTimerClock implements ShotTimerClock {
  FakeShotTimerClock([this.monotonicMicroseconds = 0]);

  @override
  int monotonicMicroseconds;

  void advance(Duration duration) {
    if (duration.isNegative) throw ArgumentError.value(duration, 'duration');
    monotonicMicroseconds += duration.inMicroseconds;
  }
}

/// Fully controllable engine for UI, repository and state-machine tests.
class FakeShotTimerEngine implements ShotTimerEngine {
  FakeShotTimerEngine({FakeShotTimerClock? clock})
    : clock = clock ?? FakeShotTimerClock();

  final FakeShotTimerClock clock;
  final _machine = ShotTimerStateMachine();
  final _snapshots = StreamController<ShotTimerSnapshot>.broadcast();
  final _levels = StreamController<double>.broadcast();
  bool _disposed = false;

  @override
  ShotTimerSnapshot get snapshot => _machine.snapshot;

  @override
  Stream<ShotTimerSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<double> get normalizedAudioLevels => _levels.stream;

  @override
  Future<void> prepare(ShotTimerConfiguration configuration) async {
    _ensureActive();
    _emit(_machine.dispatch(PrepareTimer(configuration)));
    if (configuration.mode == ShotTimerMode.acousticLiveFire) {
      _emit(_machine.dispatch(const TimerCalibrating()));
    }
    _emit(_machine.dispatch(const TimerReady()));
  }

  @override
  Future<void> start() => scheduleStart(Duration.zero);

  Future<void> scheduleStart(Duration actualDelay) async {
    _ensureActive();
    _emit(_machine.dispatch(ScheduleTimerStart(actualDelay)));
  }

  void beginRun() {
    _ensureActive();
    _emit(_machine.dispatch(BeginTimerRun(clock.monotonicMicroseconds)));
  }

  ShotTimerEvent detectShot({
    ShotTimerEventSource source = ShotTimerEventSource.acoustic,
    double? normalizedPeak,
    ShotTimerDetectionQuality? quality,
  }) {
    _ensureActive();
    final start = snapshot.runStartMonotonicMicros;
    if (start == null) throw StateError('The fake run has not started.');
    final elapsed = Duration(microseconds: clock.monotonicMicroseconds - start);
    final counted = snapshot.events
        .where(
          (event) => event.disposition == ShotTimerEventDisposition.counted,
        )
        .toList();
    final event = ShotTimerEvent(
      id: 'fake-${snapshot.events.length + 1}',
      sequenceNumber: counted.length + 1,
      elapsed: elapsed,
      split: counted.isEmpty ? elapsed : elapsed - counted.last.elapsed,
      source: source,
      normalizedPeak: normalizedPeak,
      detectionQuality: quality,
    );
    _emit(_machine.dispatch(RegisterTimerEvent(event)));
    return event;
  }

  void emitAudioLevel(double value) {
    _ensureActive();
    if (value < 0 || value > 1 || !value.isFinite) {
      throw ArgumentError.value(value, 'value');
    }
    _levels.add(value);
  }

  @override
  Future<ShotTimerResult> stop() async {
    _ensureActive();
    if (snapshot.state == ShotTimerState.running) {
      _emit(_machine.dispatch(const ReviewTimerRun()));
    }
    final result = ShotTimerStatistics.summarize(
      actualStartDelay: snapshot.actualStartDelay ?? Duration.zero,
      events: snapshot.events,
    );
    _emit(_machine.dispatch(const CompleteTimerRun()));
    return result;
  }

  @override
  Future<void> abort(String reason) async {
    _ensureActive();
    _emit(_machine.dispatch(InterruptTimerRun(reason)));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _machine.dispatch(const DisposeTimer());
    await _snapshots.close();
    await _levels.close();
  }

  void _emit(ShotTimerSnapshot value) => _snapshots.add(value);

  void _ensureActive() {
    if (_disposed) throw StateError('The fake shot timer has been disposed.');
  }
}
