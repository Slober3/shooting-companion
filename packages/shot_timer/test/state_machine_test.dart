import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:test/test.dart';

void main() {
  final configuration = ShotTimerConfiguration(
    mode: ShotTimerMode.acousticLiveFire,
  );

  test('accepts the complete acoustic lifecycle', () {
    final machine = ShotTimerStateMachine();

    machine.dispatch(PrepareTimer(configuration));
    machine.dispatch(const TimerCalibrating());
    machine.dispatch(const TimerReady());
    machine.dispatch(const ScheduleTimerStart(Duration(seconds: 2)));
    machine.dispatch(const BeginTimerRun(100000));
    machine.dispatch(
      const RegisterTimerEvent(
        ShotTimerEvent(
          id: 'shot-1',
          sequenceNumber: 1,
          elapsed: Duration(milliseconds: 800),
          split: Duration(milliseconds: 800),
          source: ShotTimerEventSource.acoustic,
        ),
      ),
    );
    machine.dispatch(const ReviewTimerRun());
    machine.dispatch(const CompleteTimerRun());

    expect(machine.snapshot.state, ShotTimerState.completed);
    expect(machine.snapshot.events, hasLength(1));
    expect(machine.snapshot.actualStartDelay, const Duration(seconds: 2));
  });

  test('rejects a shot before a run starts', () {
    final machine = ShotTimerStateMachine();
    machine.dispatch(PrepareTimer(configuration));
    machine.dispatch(const TimerReady());

    expect(
      () => machine.dispatch(
        const RegisterTimerEvent(
          ShotTimerEvent(
            id: 'early',
            sequenceNumber: 1,
            elapsed: Duration.zero,
            split: Duration.zero,
            source: ShotTimerEventSource.acoustic,
          ),
        ),
      ),
      throwsStateError,
    );
  });

  test('interruption keeps captured events for review', () {
    final machine = ShotTimerStateMachine();
    machine.dispatch(PrepareTimer(configuration));
    machine.dispatch(const TimerReady());
    machine.dispatch(const ScheduleTimerStart(Duration.zero));
    machine.dispatch(const BeginTimerRun(0));
    machine.dispatch(
      const RegisterTimerEvent(
        ShotTimerEvent(
          id: 'shot-1',
          sequenceNumber: 1,
          elapsed: Duration(milliseconds: 500),
          split: Duration(milliseconds: 500),
          source: ShotTimerEventSource.acoustic,
        ),
      ),
    );

    machine.dispatch(const InterruptTimerRun('app_backgrounded'));

    expect(machine.snapshot.state, ShotTimerState.interrupted);
    expect(machine.snapshot.events.single.id, 'shot-1');
  });
}
