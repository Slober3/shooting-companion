import 'dart:async';

import 'package:flutter/services.dart';

import 'engine.dart';
import 'models.dart';
import 'statistics.dart';

class ShotTimerPlatformException implements Exception {
  const ShotTimerPlatformException(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'ShotTimerPlatformException($code, $message)';
}

/// Small device-facing API used by the guided setup before a timer run starts.
class ShotTimerPlatformController {
  const ShotTimerPlatformController({MethodChannel? methodChannel})
    : _methods =
          methodChannel ??
          const MethodChannel(MethodChannelShotTimerEngine.methodChannelName);

  final MethodChannel _methods;

  Future<Map<String, Object?>> getCapabilities() async {
    final raw = await _methods.invokeMethod<Map<Object?, Object?>>(
      'getCapabilities',
    );
    return (raw ?? const <Object?, Object?>{}).map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  Future<void> testSignals(Set<ShotTimerOutputSignal> signals) =>
      _methods.invokeMethod<void>('testSignals', {
        'outputSignals': signals.map((value) => value.wireName).toList(),
      });
}

/// Android acoustic timer adapter.
///
/// Only structured status, level and impulse events cross the platform channel;
/// raw audio samples never leave the Android audio worker.
class MethodChannelShotTimerEngine implements ShotTimerEngine {
  MethodChannelShotTimerEngine({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methods = methodChannel ?? const MethodChannel(methodChannelName),
       _eventChannel = eventChannel ?? const EventChannel(eventChannelName) {
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      _handlePlatformEvent,
      onError: _handlePlatformError,
    );
  }

  static const methodChannelName = 'shooting_companion/shot_timer/methods';
  static const eventChannelName = 'shooting_companion/shot_timer/events';

  final MethodChannel _methods;
  final EventChannel _eventChannel;
  final _snapshots = StreamController<ShotTimerSnapshot>.broadcast();
  final _levels = StreamController<double>.broadcast();
  StreamSubscription<Object?>? _subscription;
  ShotTimerSnapshot _snapshot = ShotTimerSnapshot.idle();
  bool _disposed = false;

  @override
  ShotTimerSnapshot get snapshot => _snapshot;

  @override
  Stream<ShotTimerSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<double> get normalizedAudioLevels => _levels.stream;

  Future<Map<String, Object?>> getCapabilities() async {
    _ensureActive();
    final raw = await _invoke<Map<Object?, Object?>>('getCapabilities');
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<void> prepare(ShotTimerConfiguration configuration) async {
    _ensureActive();
    configuration.validate();
    if (configuration.mode != ShotTimerMode.acousticLiveFire) {
      throw UnsupportedError(
        'The method-channel engine only provides acoustic live-fire timing.',
      );
    }
    _setSnapshot(
      ShotTimerSnapshot(
        state: ShotTimerState.preparing,
        configuration: configuration,
      ),
    );
    try {
      final raw = await _invoke<Map<Object?, Object?>>(
        'prepare',
        configuration.toMap(),
      );
      final needsCalibration = raw['needsCalibration'] == true;
      _setSnapshot(
        _snapshot.copyWith(
          state: needsCalibration
              ? ShotTimerState.calibrating
              : ShotTimerState.ready,
        ),
      );
      if (needsCalibration) {
        _setSnapshot(_snapshot.copyWith(state: ShotTimerState.ready));
      }
    } catch (error) {
      _setPlatformFailure(error);
      rethrow;
    }
  }

  @override
  Future<void> start() async {
    _ensureActive();
    if (_snapshot.state != ShotTimerState.ready) {
      throw StateError('Prepare the acoustic timer before starting.');
    }
    // Move into the delay state before invoking native code. With an immediate
    // start, the EventChannel can deliver `running` (and even a first shot)
    // before the MethodChannel response completes. Updating only the delay
    // after the response prevents those newer native events from being lost or
    // regressed back to `startDelay`.
    _setSnapshot(
      _snapshot.copyWith(
        state: ShotTimerState.startDelay,
        actualStartDelay: null,
        events: const [],
        runStartMonotonicMicros: null,
      ),
    );
    try {
      final raw = await _invoke<Map<Object?, Object?>>('start');
      final actualDelay = Duration(
        microseconds: (raw['actualStartDelayMicros'] as num?)?.toInt() ?? 0,
      );
      _setSnapshot(_snapshot.copyWith(actualStartDelay: actualDelay));
    } catch (error) {
      _setPlatformFailure(error);
      rethrow;
    }
  }

  @override
  Future<ShotTimerResult> stop() async {
    _ensureActive();
    try {
      await _invoke<Object?>('stop');
      _setSnapshot(_snapshot.copyWith(state: ShotTimerState.reviewing));
      final result = ShotTimerStatistics.summarize(
        actualStartDelay: _snapshot.actualStartDelay ?? Duration.zero,
        events: _snapshot.events,
        qualityWarnings: _qualityWarnings(_snapshot.events),
      );
      _setSnapshot(_snapshot.copyWith(state: ShotTimerState.completed));
      return result;
    } catch (error) {
      _setPlatformFailure(error);
      rethrow;
    }
  }

  @override
  Future<void> abort(String reason) async {
    _ensureActive();
    try {
      await _invoke<Object?>('abort', {'reason': reason});
    } finally {
      _setSnapshot(
        _snapshot.copyWith(
          state: ShotTimerState.interrupted,
          interruptionReason: reason,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _methods.invokeMethod<Object?>('dispose');
    } on PlatformException {
      // Native resources are also released when the plugin detaches.
    }
    await _subscription?.cancel();
    _subscription = null;
    _snapshot = _snapshot.copyWith(state: ShotTimerState.disposed);
    await _snapshots.close();
    await _levels.close();
  }

  void _handlePlatformEvent(Object? event) {
    if (_disposed || event is! Map<Object?, Object?>) return;
    final type = event['type'];
    switch (type) {
      case 'state':
        final next = ShotTimerState.fromWire(event['state']);
        if (_snapshot.state == ShotTimerState.completed &&
            next == ShotTimerState.reviewing) {
          return;
        }
        _setSnapshot(
          _snapshot.copyWith(
            state: next,
            runStartMonotonicMicros: event['runStartMonotonicMicros'] == null
                ? _snapshot.runStartMonotonicMicros
                : (event['runStartMonotonicMicros'] as num).toInt(),
          ),
        );
      case 'shot':
        final shotMap = Map<Object?, Object?>.of(event)..remove('type');
        final shot = ShotTimerEvent.fromMap(shotMap);
        final withoutSameId = _snapshot.events
            .where((existing) => existing.id != shot.id)
            .toList();
        _setSnapshot(_snapshot.copyWith(events: [...withoutSameId, shot]));
      case 'audioLevel':
        final value = (event['normalizedLevel'] as num?)?.toDouble();
        if (value != null && value.isFinite && !_levels.isClosed) {
          _levels.add(value.clamp(0, 1));
        }
      case 'warning':
        break;
      case 'error':
        _setSnapshot(
          _snapshot.copyWith(
            state: ShotTimerState.error,
            errorCode: event['code']?.toString() ?? 'native_error',
            errorMessage: event['message']?.toString() ?? 'Unknown error',
          ),
        );
    }
  }

  void _handlePlatformError(Object error) {
    if (_disposed) return;
    _setPlatformFailure(error);
  }

  void _setPlatformFailure(Object error) {
    final code = error is PlatformException ? error.code : 'platform_error';
    final message = error is PlatformException
        ? error.message ?? code
        : error.toString();
    _setSnapshot(
      _snapshot.copyWith(
        state: ShotTimerState.error,
        errorCode: code,
        errorMessage: message,
      ),
    );
  }

  List<String> _qualityWarnings(Iterable<ShotTimerEvent> events) => [
    if (events.any(
      (event) => event.detectionQuality == ShotTimerDetectionQuality.low,
    ))
      'low_confidence_detection',
  ];

  void _setSnapshot(ShotTimerSnapshot value) {
    _snapshot = value;
    if (!_snapshots.isClosed) _snapshots.add(value);
  }

  Future<T> _invoke<T>(String method, [Object? arguments]) async {
    try {
      final value = await _methods.invokeMethod<T>(method, arguments);
      if (value == null && null is! T) {
        throw const ShotTimerPlatformException(
          'empty_response',
          'The native shot timer returned no response.',
        );
      }
      return value as T;
    } on PlatformException catch (error) {
      throw ShotTimerPlatformException(
        error.code,
        error.message ?? error.code,
        error.details,
      );
    }
  }

  void _ensureActive() {
    if (_disposed) throw StateError('The shot timer has been disposed.');
  }
}
