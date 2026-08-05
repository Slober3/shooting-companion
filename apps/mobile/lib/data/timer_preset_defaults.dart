import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

List<TimerPresetsCompanion> builtInTimerPresetCompanions() {
  final seededAt = DateTime.utc(2026, 1, 1);
  return [
    TimerPresetsCompanion.insert(
      id: 'builtin-live-fire-random-2-4',
      name: 'Live fire · willekeurig 2–4 s',
      mode: 'acousticLiveFire',
      configurationJson: jsonEncode({
        'mode': 'acousticLiveFire',
        'delayMode': 'random',
        'fixedDelayMicros': 0,
        'randomDelayMinimumMicros': 2000000,
        'randomDelayMaximumMicros': 4000000,
        'parSignalsMicros': <int>[],
        'repetitions': 1,
        'restDurationMicros': 0,
        'cadenceStartIntervalMicros': 1000000,
        'cadenceEndIntervalMicros': 1000000,
        'cadenceSignalCount': 0,
        'maximumShots': null,
        'inactivityTimeoutMicros': 3000000,
        'outputSignals': ['sound'],
        'calibration': null,
      }),
      builtIn: const Value(true),
      createdAtUtc: seededAt,
      updatedAtUtc: seededAt,
    ),
    TimerPresetsCompanion.insert(
      id: 'builtin-par-5-seconds',
      name: 'Par · 5 seconden',
      mode: 'par',
      configurationJson: jsonEncode({
        'mode': 'par',
        'delayMode': 'immediate',
        'fixedDelayMicros': 0,
        'randomDelayMinimumMicros': 2000000,
        'randomDelayMaximumMicros': 4000000,
        'parSignalsMicros': [5000000],
        'repetitions': 1,
        'restDurationMicros': 0,
        'cadenceStartIntervalMicros': 1000000,
        'cadenceEndIntervalMicros': 1000000,
        'cadenceSignalCount': 0,
        'maximumShots': null,
        'inactivityTimeoutMicros': null,
        'outputSignals': ['sound'],
        'calibration': null,
      }),
      builtIn: const Value(true),
      createdAtUtc: seededAt,
      updatedAtUtc: seededAt,
    ),
    TimerPresetsCompanion.insert(
      id: 'builtin-cadence-1-second',
      name: 'Cadans · 1 seconde',
      mode: 'cadence',
      configurationJson: jsonEncode({
        'mode': 'cadence',
        'delayMode': 'immediate',
        'fixedDelayMicros': 0,
        'randomDelayMinimumMicros': 2000000,
        'randomDelayMaximumMicros': 4000000,
        'parSignalsMicros': <int>[],
        'repetitions': 1,
        'restDurationMicros': 0,
        'cadenceStartIntervalMicros': 1000000,
        'cadenceEndIntervalMicros': 1000000,
        'cadenceSignalCount': 10,
        'maximumShots': null,
        'inactivityTimeoutMicros': null,
        'outputSignals': ['sound'],
        'calibration': null,
      }),
      builtIn: const Value(true),
      createdAtUtc: seededAt,
      updatedAtUtc: seededAt,
    ),
  ];
}
