import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion_shot_timer/shot_timer.dart';

void main() {
  test(
    'platform controller forwards capabilities and selected signals',
    () async {
      final calls = <(String, Object?)>[];
      final controller = ShotTimerPlatformController(
        methodChannel: _FakeMethodChannel((method, arguments) async {
          calls.add((method, arguments));
          if (method == 'getCapabilities') {
            return <Object?, Object?>{
              'hasMicrophone': true,
              'nativeSampleRate': 48000,
            };
          }
          return null;
        }),
      );

      final capabilities = await controller.getCapabilities();
      await controller.testSignals({
        ShotTimerOutputSignal.sound,
        ShotTimerOutputSignal.haptic,
      });

      expect(capabilities['hasMicrophone'], isTrue);
      expect(capabilities['nativeSampleRate'], 48000);
      expect(calls.first.$1, 'getCapabilities');
      expect(calls.last.$1, 'testSignals');
      expect(calls.last.$2, <String, Object?>{
        'outputSignals': <String>['sound', 'haptic'],
      });
    },
  );

  test(
    'start response does not regress native running state or drop events',
    () async {
      final platformEvents = StreamController<Object?>.broadcast(sync: true);
      late MethodChannelShotTimerEngine engine;
      final methods = _FakeMethodChannel((method, arguments) async {
        switch (method) {
          case 'prepare':
            return <Object?, Object?>{'needsCalibration': false};
          case 'start':
            platformEvents
              ..add(<Object?, Object?>{
                'type': 'state',
                'state': 'running',
                'runStartMonotonicMicros': 123456,
              })
              ..add(<Object?, Object?>{
                'type': 'shot',
                'id': 'first-shot',
                'sequenceNumber': 1,
                'elapsedMicros': 850000,
                'splitMicros': 850000,
                'source': 'acoustic',
                'disposition': 'counted',
              });
            expect(engine.snapshot.state, ShotTimerState.running);
            return <Object?, Object?>{'actualStartDelayMicros': 0};
          case 'dispose':
            return null;
          default:
            fail('Unexpected platform call: $method');
        }
      });
      engine = MethodChannelShotTimerEngine(
        methodChannel: methods,
        eventChannel: _FakeEventChannel(platformEvents.stream),
      );

      await engine.prepare(
        ShotTimerConfiguration(mode: ShotTimerMode.acousticLiveFire),
      );
      await engine.start();

      expect(engine.snapshot.state, ShotTimerState.running);
      expect(engine.snapshot.actualStartDelay, Duration.zero);
      expect(engine.snapshot.runStartMonotonicMicros, 123456);
      expect(engine.snapshot.events.map((event) => event.id), ['first-shot']);

      await engine.dispose();
      await platformEvents.close();
    },
  );
}

class _FakeMethodChannel extends MethodChannel {
  _FakeMethodChannel(this.handler) : super('shot_timer_test/methods');

  final Future<Object?> Function(String method, Object? arguments) handler;

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async =>
      await handler(method, arguments) as T?;
}

class _FakeEventChannel extends EventChannel {
  _FakeEventChannel(this.events) : super('shot_timer_test/events');

  final Stream<Object?> events;

  @override
  Stream<dynamic> receiveBroadcastStream([Object? arguments]) => events;
}
