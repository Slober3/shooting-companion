import 'models.dart';

sealed class ShotTimerAction {
  const ShotTimerAction();
}

class PrepareTimer extends ShotTimerAction {
  const PrepareTimer(this.configuration);
  final ShotTimerConfiguration configuration;
}

class TimerReady extends ShotTimerAction {
  const TimerReady();
}

class TimerCalibrating extends ShotTimerAction {
  const TimerCalibrating();
}

class ScheduleTimerStart extends ShotTimerAction {
  const ScheduleTimerStart(this.actualDelay);
  final Duration actualDelay;
}

class BeginTimerRun extends ShotTimerAction {
  const BeginTimerRun(this.monotonicMicros);
  final int monotonicMicros;
}

class RegisterTimerEvent extends ShotTimerAction {
  const RegisterTimerEvent(this.event);
  final ShotTimerEvent event;
}

class ReviewTimerRun extends ShotTimerAction {
  const ReviewTimerRun();
}

class CompleteTimerRun extends ShotTimerAction {
  const CompleteTimerRun();
}

class InterruptTimerRun extends ShotTimerAction {
  const InterruptTimerRun(this.reason);
  final String reason;
}

class FailTimer extends ShotTimerAction {
  const FailTimer(this.code, this.message);
  final String code;
  final String message;
}

class ResetTimer extends ShotTimerAction {
  const ResetTimer();
}

class DisposeTimer extends ShotTimerAction {
  const DisposeTimer();
}

class ShotTimerStateMachine {
  ShotTimerStateMachine({ShotTimerSnapshot? initial})
    : _snapshot = initial ?? ShotTimerSnapshot.idle();

  ShotTimerSnapshot _snapshot;
  ShotTimerSnapshot get snapshot => _snapshot;

  ShotTimerSnapshot dispatch(ShotTimerAction action) {
    _snapshot = ShotTimerReducer.reduce(_snapshot, action);
    return _snapshot;
  }
}

class ShotTimerReducer {
  const ShotTimerReducer._();

  static ShotTimerSnapshot reduce(
    ShotTimerSnapshot current,
    ShotTimerAction action,
  ) {
    if (current.state == ShotTimerState.disposed && action is! ResetTimer) {
      throw StateError('A disposed shot timer cannot be reused.');
    }
    return switch (action) {
      PrepareTimer(:final configuration) => _prepare(current, configuration),
      TimerCalibrating() => _transition(current, const {
        ShotTimerState.preparing,
      }, ShotTimerState.calibrating),
      TimerReady() => _transition(current, const {
        ShotTimerState.preparing,
        ShotTimerState.calibrating,
      }, ShotTimerState.ready),
      ScheduleTimerStart(:final actualDelay) => _schedule(current, actualDelay),
      BeginTimerRun(:final monotonicMicros) => _begin(current, monotonicMicros),
      RegisterTimerEvent(:final event) => _event(current, event),
      ReviewTimerRun() => _transition(current, const {
        ShotTimerState.running,
      }, ShotTimerState.reviewing),
      CompleteTimerRun() => _transition(current, const {
        ShotTimerState.reviewing,
      }, ShotTimerState.completed),
      InterruptTimerRun(:final reason) => current.copyWith(
        state: ShotTimerState.interrupted,
        interruptionReason: reason,
      ),
      FailTimer(:final code, :final message) => current.copyWith(
        state: ShotTimerState.error,
        errorCode: code,
        errorMessage: message,
      ),
      ResetTimer() => ShotTimerSnapshot.idle(),
      DisposeTimer() => current.copyWith(state: ShotTimerState.disposed),
    };
  }

  static ShotTimerSnapshot _prepare(
    ShotTimerSnapshot current,
    ShotTimerConfiguration configuration,
  ) {
    _requireState(current, const {
      ShotTimerState.idle,
      ShotTimerState.completed,
      ShotTimerState.interrupted,
      ShotTimerState.error,
    });
    configuration.validate();
    return ShotTimerSnapshot(
      state: ShotTimerState.preparing,
      configuration: configuration,
    );
  }

  static ShotTimerSnapshot _schedule(
    ShotTimerSnapshot current,
    Duration actualDelay,
  ) {
    _requireState(current, const {ShotTimerState.ready});
    if (actualDelay.isNegative) {
      throw ArgumentError.value(actualDelay, 'actualDelay');
    }
    return current.copyWith(
      state: ShotTimerState.startDelay,
      actualStartDelay: actualDelay,
      events: const [],
      runStartMonotonicMicros: null,
      interruptionReason: null,
      errorCode: null,
      errorMessage: null,
    );
  }

  static ShotTimerSnapshot _begin(
    ShotTimerSnapshot current,
    int monotonicMicros,
  ) {
    _requireState(current, const {ShotTimerState.startDelay});
    if (monotonicMicros < 0) {
      throw ArgumentError.value(monotonicMicros, 'monotonicMicros');
    }
    return current.copyWith(
      state: ShotTimerState.running,
      runStartMonotonicMicros: monotonicMicros,
    );
  }

  static ShotTimerSnapshot _event(
    ShotTimerSnapshot current,
    ShotTimerEvent event,
  ) {
    _requireState(current, const {
      ShotTimerState.running,
      ShotTimerState.reviewing,
    });
    if (event.elapsed.isNegative || event.split.isNegative) {
      throw ArgumentError('Shot event times cannot be negative.');
    }
    final events = [...current.events, event];
    return current.copyWith(events: events);
  }

  static ShotTimerSnapshot _transition(
    ShotTimerSnapshot current,
    Set<ShotTimerState> allowed,
    ShotTimerState next,
  ) {
    _requireState(current, allowed);
    return current.copyWith(state: next);
  }

  static void _requireState(
    ShotTimerSnapshot current,
    Set<ShotTimerState> allowed,
  ) {
    if (!allowed.contains(current.state)) {
      throw StateError(
        'Invalid shot timer transition from ${current.state.wireName}.',
      );
    }
  }
}
