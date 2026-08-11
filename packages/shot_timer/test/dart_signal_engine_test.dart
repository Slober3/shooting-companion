import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:test/test.dart';

void main() {
  test('par engine schedules repeated starts and par signals', () async {
    final clock = FakeShotTimerClock();
    final scheduler = _FakeScheduler(clock);
    final output = _RecordingOutput();
    final engine = DartSignalShotTimerEngine(
      signalOutput: output,
      clock: clock,
      scheduler: scheduler,
    );
    await engine.prepare(
      ShotTimerConfiguration(
        mode: ShotTimerMode.par,
        delayMode: ShotTimerDelayMode.fixed,
        fixedDelay: const Duration(seconds: 2),
        parSignals: const [Duration(seconds: 1)],
        repetitions: 2,
        restDuration: const Duration(milliseconds: 500),
      ),
    );

    await engine.start();
    expect(engine.snapshot.state, ShotTimerState.startDelay);
    scheduler.advance(const Duration(seconds: 2));
    expect(engine.snapshot.state, ShotTimerState.running);
    expect(output.kinds, [ShotTimerSignalKind.start]);

    scheduler.advance(const Duration(seconds: 1));
    scheduler.advance(const Duration(milliseconds: 500));
    scheduler.advance(const Duration(seconds: 1));
    scheduler.advance(const Duration(milliseconds: 20));
    expect(output.kinds, [
      ShotTimerSignalKind.start,
      ShotTimerSignalKind.par,
      ShotTimerSignalKind.start,
      ShotTimerSignalKind.par,
      ShotTimerSignalKind.complete,
    ]);
    expect(engine.snapshot.state, ShotTimerState.reviewing);

    final result = await engine.stop();
    expect(result.totalTime, const Duration(milliseconds: 2520));
    expect(result.countedShotCount, 0);
    await engine.dispose();
  });

  test('abort cancels pending signals', () async {
    final clock = FakeShotTimerClock();
    final scheduler = _FakeScheduler(clock);
    final output = _RecordingOutput();
    final engine = DartSignalShotTimerEngine(
      signalOutput: output,
      clock: clock,
      scheduler: scheduler,
    );
    await engine.prepare(
      ShotTimerConfiguration(
        mode: ShotTimerMode.par,
        delayMode: ShotTimerDelayMode.fixed,
        fixedDelay: const Duration(seconds: 2),
        parSignals: const [Duration(seconds: 1)],
      ),
    );
    await engine.start();

    await engine.abort('route_closed');
    scheduler.advance(const Duration(seconds: 10));

    expect(output.kinds, isEmpty);
    expect(engine.snapshot.state, ShotTimerState.interrupted);
    await engine.dispose();
  });
}

class _RecordingOutput implements ShotTimerSignalOutput {
  final kinds = <ShotTimerSignalKind>[];

  @override
  Future<void> emit(
    ShotTimerSignalKind kind,
    Set<ShotTimerOutputSignal> outputs,
  ) async {
    kinds.add(kind);
  }
}

class _FakeScheduler implements ShotTimerScheduler {
  _FakeScheduler(this.clock);

  final FakeShotTimerClock clock;
  final _tasks = <_FakeTask>[];

  @override
  CancellableShotTimerTask schedule(Duration delay, void Function() callback) {
    final task = _FakeTask(
      dueMicroseconds: clock.monotonicMicroseconds + delay.inMicroseconds,
      callback: callback,
    );
    _tasks.add(task);
    return task;
  }

  void advance(Duration duration) {
    final target = clock.monotonicMicroseconds + duration.inMicroseconds;
    while (true) {
      final due =
          _tasks
              .where(
                (task) =>
                    !task.isCancelled &&
                    !task.hasRun &&
                    task.dueMicroseconds <= target,
              )
              .toList()
            ..sort(
              (left, right) =>
                  left.dueMicroseconds.compareTo(right.dueMicroseconds),
            );
      if (due.isEmpty) break;
      final task = due.first;
      clock.monotonicMicroseconds = task.dueMicroseconds;
      task.hasRun = true;
      task.callback();
    }
    clock.monotonicMicroseconds = target;
  }
}

class _FakeTask implements CancellableShotTimerTask {
  _FakeTask({required this.dueMicroseconds, required this.callback});

  final int dueMicroseconds;
  final void Function() callback;
  bool hasRun = false;
  bool _cancelled = false;

  @override
  bool get isCancelled => _cancelled;

  @override
  void cancel() => _cancelled = true;
}
