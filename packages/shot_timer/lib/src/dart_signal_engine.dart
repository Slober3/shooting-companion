import 'dart:async';
import 'dart:math' as math;

import 'engine.dart';
import 'models.dart';
import 'state_machine.dart';
import 'statistics.dart';

/// Permission-free engine for par and cadence signals.
///
/// Acoustic timing is intentionally delegated to the Android platform engine.
class DartSignalShotTimerEngine implements ShotTimerEngine {
  DartSignalShotTimerEngine({
    required this.signalOutput,
    ShotTimerClock? clock,
    ShotTimerScheduler? scheduler,
    math.Random? random,
  }) : _clock = clock ?? StopwatchShotTimerClock(),
       _scheduler = scheduler ?? const TimerShotTimerScheduler(),
       _random = random ?? math.Random.secure();

  final ShotTimerSignalOutput signalOutput;
  final ShotTimerClock _clock;
  final ShotTimerScheduler _scheduler;
  final math.Random _random;
  final _machine = ShotTimerStateMachine();
  final _snapshots = StreamController<ShotTimerSnapshot>.broadcast();
  final _levels = StreamController<double>.broadcast();
  final List<CancellableShotTimerTask> _tasks = [];
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
    if (configuration.mode == ShotTimerMode.acousticLiveFire) {
      throw UnsupportedError(
        'Acoustic timing requires MethodChannelShotTimerEngine.',
      );
    }
    _cancelTasks();
    _emit(_machine.dispatch(PrepareTimer(configuration)));
    _emit(_machine.dispatch(const TimerReady()));
  }

  @override
  Future<void> start() async {
    _ensureActive();
    final configuration = snapshot.configuration;
    if (configuration == null) throw StateError('Prepare the timer first.');
    final delay = _resolveDelay(configuration);
    _emit(_machine.dispatch(ScheduleTimerStart(delay)));
    _schedule(delay, () => _beginRun(configuration));
  }

  @override
  Future<ShotTimerResult> stop() async {
    _ensureActive();
    _cancelTasks();
    if (snapshot.state == ShotTimerState.running) {
      _emit(_machine.dispatch(const ReviewTimerRun()));
    }
    if (snapshot.state != ShotTimerState.reviewing) {
      throw StateError('Only a running or reviewable timer can be stopped.');
    }
    final result = ShotTimerStatistics.summarize(
      actualStartDelay: snapshot.actualStartDelay ?? Duration.zero,
      events: snapshot.events,
      recordedTotalTime: snapshot.runStartMonotonicMicros == null
          ? Duration.zero
          : Duration(
              microseconds:
                  _clock.monotonicMicroseconds -
                  snapshot.runStartMonotonicMicros!,
            ),
    );
    _emit(_machine.dispatch(const CompleteTimerRun()));
    return result;
  }

  @override
  Future<void> abort(String reason) async {
    _ensureActive();
    _cancelTasks();
    _emit(_machine.dispatch(InterruptTimerRun(reason)));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cancelTasks();
    _machine.dispatch(const DisposeTimer());
    await _snapshots.close();
    await _levels.close();
  }

  void _beginRun(ShotTimerConfiguration configuration) {
    if (_disposed || snapshot.state != ShotTimerState.startDelay) return;
    _emit(_machine.dispatch(BeginTimerRun(_clock.monotonicMicroseconds)));
    unawaited(
      signalOutput.emit(ShotTimerSignalKind.start, configuration.outputSignals),
    );
    switch (configuration.mode) {
      case ShotTimerMode.par:
        _scheduleParRun(configuration);
      case ShotTimerMode.cadence:
        _scheduleCadenceRun(configuration);
      case ShotTimerMode.externalManual:
        break;
      case ShotTimerMode.acousticLiveFire:
        throw StateError('Acoustic mode cannot run in the Dart signal engine.');
    }
  }

  void _scheduleParRun(ShotTimerConfiguration configuration) {
    var offset = Duration.zero;
    for (
      var repetition = 0;
      repetition < configuration.repetitions;
      repetition++
    ) {
      if (repetition > 0) {
        offset += configuration.restDuration;
        _scheduleSignal(offset, ShotTimerSignalKind.start, configuration);
      }
      for (final par in configuration.parSignals) {
        _scheduleSignal(offset + par, ShotTimerSignalKind.par, configuration);
      }
      offset += configuration.parSignals.isEmpty
          ? Duration.zero
          : configuration.parSignals.last;
    }
    _scheduleReview(offset, configuration);
  }

  void _scheduleCadenceRun(ShotTimerConfiguration configuration) {
    var offset = Duration.zero;
    for (
      var repetition = 0;
      repetition < configuration.repetitions;
      repetition++
    ) {
      if (repetition > 0) {
        offset += configuration.restDuration;
        _scheduleSignal(offset, ShotTimerSignalKind.start, configuration);
      }
      for (var index = 0; index < configuration.cadenceSignalCount; index++) {
        final progress = configuration.cadenceSignalCount <= 1
            ? 0.0
            : index / (configuration.cadenceSignalCount - 1);
        final intervalMicros =
            configuration.cadenceStartInterval.inMicroseconds +
            ((configuration.cadenceEndInterval.inMicroseconds -
                        configuration.cadenceStartInterval.inMicroseconds) *
                    progress)
                .round();
        offset += Duration(microseconds: intervalMicros);
        _scheduleSignal(offset, ShotTimerSignalKind.cadence, configuration);
      }
    }
    _scheduleReview(offset, configuration);
  }

  void _scheduleSignal(
    Duration offset,
    ShotTimerSignalKind kind,
    ShotTimerConfiguration configuration,
  ) {
    _schedule(offset, () {
      if (snapshot.state != ShotTimerState.running) return;
      unawaited(signalOutput.emit(kind, configuration.outputSignals));
    });
  }

  void _scheduleReview(Duration offset, ShotTimerConfiguration configuration) {
    _schedule(offset + const Duration(milliseconds: 20), () {
      if (snapshot.state != ShotTimerState.running) return;
      unawaited(
        signalOutput.emit(
          ShotTimerSignalKind.complete,
          configuration.outputSignals,
        ),
      );
      _emit(_machine.dispatch(const ReviewTimerRun()));
    });
  }

  Duration _resolveDelay(ShotTimerConfiguration configuration) {
    return switch (configuration.delayMode) {
      ShotTimerDelayMode.immediate => Duration.zero,
      ShotTimerDelayMode.fixed => configuration.fixedDelay,
      ShotTimerDelayMode.random => Duration(
        microseconds:
            configuration.randomDelayMinimum.inMicroseconds +
            _random.nextInt(
              configuration.randomDelayMaximum.inMicroseconds -
                  configuration.randomDelayMinimum.inMicroseconds +
                  1,
            ),
      ),
    };
  }

  void _schedule(Duration delay, void Function() callback) {
    _tasks.add(_scheduler.schedule(delay, callback));
  }

  void _cancelTasks() {
    for (final task in _tasks) {
      task.cancel();
    }
    _tasks.clear();
  }

  void _emit(ShotTimerSnapshot value) {
    if (!_snapshots.isClosed) _snapshots.add(value);
  }

  void _ensureActive() {
    if (_disposed) throw StateError('The shot timer has been disposed.');
  }
}

class TimerShotTimerScheduler implements ShotTimerScheduler {
  const TimerShotTimerScheduler();

  @override
  CancellableShotTimerTask schedule(Duration delay, void Function() callback) =>
      _TimerTask(Timer(delay, callback));
}

class _TimerTask implements CancellableShotTimerTask {
  _TimerTask(this._timer);
  final Timer _timer;

  @override
  bool get isCancelled => !_timer.isActive;

  @override
  void cancel() => _timer.cancel();
}
