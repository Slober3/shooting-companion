import 'dart:collection';

enum ShotTimerMode {
  acousticLiveFire('acousticLiveFire'),
  par('par'),
  cadence('cadence'),
  externalManual('externalManual');

  const ShotTimerMode(this.wireName);
  final String wireName;

  static ShotTimerMode fromWire(Object? value) => values.firstWhere(
    (candidate) => candidate.wireName == value,
    orElse: () => throw FormatException('Unknown shot timer mode: $value'),
  );
}

enum ShotTimerState {
  idle('idle'),
  preparing('preparing'),
  calibrating('calibrating'),
  ready('ready'),
  startDelay('startDelay'),
  running('running'),
  reviewing('reviewing'),
  completed('completed'),
  interrupted('interrupted'),
  error('error'),
  disposed('disposed');

  const ShotTimerState(this.wireName);
  final String wireName;

  static ShotTimerState fromWire(Object? value) => values.firstWhere(
    (candidate) => candidate.wireName == value,
    orElse: () => throw FormatException('Unknown shot timer state: $value'),
  );
}

enum ShotTimerDelayMode {
  immediate('immediate'),
  fixed('fixed'),
  random('random');

  const ShotTimerDelayMode(this.wireName);
  final String wireName;

  static ShotTimerDelayMode fromWire(Object? value) => values.firstWhere(
    (candidate) => candidate.wireName == value,
    orElse: () => throw FormatException('Unknown delay mode: $value'),
  );
}

enum ShotTimerOutputSignal {
  sound('sound'),
  haptic('haptic'),
  flash('flash');

  const ShotTimerOutputSignal(this.wireName);
  final String wireName;
}

enum ShotTimerSignalKind { start, par, cadence, complete }

enum ShotTimerEventSource {
  acoustic('acoustic'),
  manual('manual'),
  generatedPar('generatedPar'),
  external('external');

  const ShotTimerEventSource(this.wireName);
  final String wireName;

  static ShotTimerEventSource fromWire(Object? value) => values.firstWhere(
    (candidate) => candidate.wireName == value,
    orElse: () => throw FormatException('Unknown timer event source: $value'),
  );
}

enum ShotTimerEventDisposition {
  counted('counted'),
  excluded('excluded');

  const ShotTimerEventDisposition(this.wireName);
  final String wireName;

  static ShotTimerEventDisposition fromWire(Object? value) => values.firstWhere(
    (candidate) => candidate.wireName == value,
    orElse: () => throw FormatException('Unknown event disposition: $value'),
  );
}

enum ShotTimerDetectionQuality {
  high('high'),
  medium('medium'),
  low('low');

  const ShotTimerDetectionQuality(this.wireName);
  final String wireName;

  static ShotTimerDetectionQuality? fromNullableWire(Object? value) {
    if (value == null) return null;
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException('Unknown detection quality: $value'),
    );
  }
}

class AcousticCalibrationSnapshot {
  const AcousticCalibrationSnapshot({
    required this.sampleRate,
    required this.sensitivity,
    required this.echoLockout,
    required this.beepBlanking,
    this.profileId,
    this.detectorVersion = 'impulse-v1',
  });

  final String? profileId;
  final int sampleRate;
  final double sensitivity;
  final Duration echoLockout;
  final Duration beepBlanking;
  final String detectorVersion;

  void validate() {
    if (sampleRate < 8000 || sampleRate > 192000) {
      throw ArgumentError.value(sampleRate, 'sampleRate');
    }
    if (!sensitivity.isFinite || sensitivity < 0 || sensitivity > 1) {
      throw ArgumentError.value(sensitivity, 'sensitivity');
    }
    if (echoLockout.isNegative || beepBlanking.isNegative) {
      throw ArgumentError('Blanking and lockout durations cannot be negative.');
    }
  }

  Map<String, Object?> toMap() => {
    'profileId': profileId,
    'sampleRate': sampleRate,
    'sensitivity': sensitivity,
    'echoLockoutMicros': echoLockout.inMicroseconds,
    'beepBlankingMicros': beepBlanking.inMicroseconds,
    'detectorVersion': detectorVersion,
  };

  factory AcousticCalibrationSnapshot.fromMap(Map<Object?, Object?> map) =>
      AcousticCalibrationSnapshot(
        profileId: map['profileId'] as String?,
        sampleRate: (map['sampleRate'] as num).toInt(),
        sensitivity: (map['sensitivity'] as num).toDouble(),
        echoLockout: Duration(
          microseconds: (map['echoLockoutMicros'] as num).toInt(),
        ),
        beepBlanking: Duration(
          microseconds: (map['beepBlankingMicros'] as num).toInt(),
        ),
        detectorVersion: map['detectorVersion'] as String? ?? 'impulse-v1',
      );
}

class ShotTimerConfiguration {
  ShotTimerConfiguration({
    required this.mode,
    this.delayMode = ShotTimerDelayMode.immediate,
    this.fixedDelay = Duration.zero,
    this.randomDelayMinimum = const Duration(seconds: 2),
    this.randomDelayMaximum = const Duration(seconds: 4),
    Iterable<Duration> parSignals = const [],
    this.repetitions = 1,
    this.restDuration = Duration.zero,
    this.cadenceStartInterval = const Duration(seconds: 1),
    Duration? cadenceEndInterval,
    this.cadenceSignalCount = 0,
    this.maximumShots,
    this.inactivityTimeout,
    Set<ShotTimerOutputSignal> outputSignals = const {
      ShotTimerOutputSignal.sound,
    },
    this.calibration,
  }) : parSignals = List.unmodifiable(parSignals),
       cadenceEndInterval = cadenceEndInterval ?? cadenceStartInterval,
       outputSignals = Set.unmodifiable(outputSignals);

  final ShotTimerMode mode;
  final ShotTimerDelayMode delayMode;
  final Duration fixedDelay;
  final Duration randomDelayMinimum;
  final Duration randomDelayMaximum;
  final List<Duration> parSignals;
  final int repetitions;
  final Duration restDuration;
  final Duration cadenceStartInterval;
  final Duration cadenceEndInterval;
  final int cadenceSignalCount;
  final int? maximumShots;
  final Duration? inactivityTimeout;
  final Set<ShotTimerOutputSignal> outputSignals;
  final AcousticCalibrationSnapshot? calibration;

  void validate() {
    if (fixedDelay.isNegative ||
        randomDelayMinimum.isNegative ||
        randomDelayMaximum.isNegative ||
        restDuration.isNegative) {
      throw ArgumentError('Timer durations cannot be negative.');
    }
    if (randomDelayMaximum < randomDelayMinimum) {
      throw ArgumentError('Random delay maximum must be at least the minimum.');
    }
    if (mode == ShotTimerMode.par && parSignals.isEmpty) {
      throw ArgumentError('Par mode requires at least one par signal.');
    }
    if (parSignals.length > 3 ||
        parSignals.any((value) => value <= Duration.zero)) {
      throw ArgumentError('Par mode supports one to three positive signals.');
    }
    for (var index = 1; index < parSignals.length; index++) {
      if (parSignals[index] <= parSignals[index - 1]) {
        throw ArgumentError('Par signals must be strictly increasing.');
      }
    }
    if (repetitions < 1) throw ArgumentError.value(repetitions, 'repetitions');
    if (maximumShots != null && maximumShots! < 1) {
      throw ArgumentError.value(maximumShots, 'maximumShots');
    }
    if (inactivityTimeout != null && inactivityTimeout! <= Duration.zero) {
      throw ArgumentError.value(inactivityTimeout, 'inactivityTimeout');
    }
    if (mode == ShotTimerMode.cadence) {
      if (cadenceSignalCount < 1 ||
          cadenceStartInterval <= Duration.zero ||
          cadenceEndInterval <= Duration.zero) {
        throw ArgumentError(
          'Cadence mode needs positive intervals and signals.',
        );
      }
    }
    calibration?.validate();
  }

  Map<String, Object?> toMap() => {
    'mode': mode.wireName,
    'delayMode': delayMode.wireName,
    'fixedDelayMicros': fixedDelay.inMicroseconds,
    'randomDelayMinimumMicros': randomDelayMinimum.inMicroseconds,
    'randomDelayMaximumMicros': randomDelayMaximum.inMicroseconds,
    'parSignalsMicros': parSignals
        .map((value) => value.inMicroseconds)
        .toList(),
    'repetitions': repetitions,
    'restDurationMicros': restDuration.inMicroseconds,
    'cadenceStartIntervalMicros': cadenceStartInterval.inMicroseconds,
    'cadenceEndIntervalMicros': cadenceEndInterval.inMicroseconds,
    'cadenceSignalCount': cadenceSignalCount,
    'maximumShots': maximumShots,
    'inactivityTimeoutMicros': inactivityTimeout?.inMicroseconds,
    'outputSignals': outputSignals.map((value) => value.wireName).toList(),
    'calibration': calibration?.toMap(),
  };

  factory ShotTimerConfiguration.fromMap(Map<Object?, Object?> map) {
    final outputValues =
        map['outputSignals'] as List<Object?>? ?? const ['sound'];
    final calibrationMap = map['calibration'];
    return ShotTimerConfiguration(
      mode: ShotTimerMode.fromWire(map['mode']),
      delayMode: ShotTimerDelayMode.fromWire(map['delayMode'] ?? 'immediate'),
      fixedDelay: _duration(map['fixedDelayMicros']),
      randomDelayMinimum: _duration(
        map['randomDelayMinimumMicros'],
        fallback: const Duration(seconds: 2),
      ),
      randomDelayMaximum: _duration(
        map['randomDelayMaximumMicros'],
        fallback: const Duration(seconds: 4),
      ),
      parSignals: (map['parSignalsMicros'] as List<Object?>? ?? const []).map(
        _duration,
      ),
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 1,
      restDuration: _duration(map['restDurationMicros']),
      cadenceStartInterval: _duration(
        map['cadenceStartIntervalMicros'],
        fallback: const Duration(seconds: 1),
      ),
      cadenceEndInterval: _duration(
        map['cadenceEndIntervalMicros'],
        fallback: const Duration(seconds: 1),
      ),
      cadenceSignalCount: (map['cadenceSignalCount'] as num?)?.toInt() ?? 0,
      maximumShots: (map['maximumShots'] as num?)?.toInt(),
      inactivityTimeout: map['inactivityTimeoutMicros'] == null
          ? null
          : _duration(map['inactivityTimeoutMicros']),
      outputSignals: outputValues
          .map(
            (value) => ShotTimerOutputSignal.values.firstWhere(
              (candidate) => candidate.wireName == value,
            ),
          )
          .toSet(),
      calibration: calibrationMap is Map<Object?, Object?>
          ? AcousticCalibrationSnapshot.fromMap(calibrationMap)
          : null,
    );
  }
}

class ShotTimerEvent {
  const ShotTimerEvent({
    required this.id,
    required this.sequenceNumber,
    required this.elapsed,
    required this.split,
    required this.source,
    this.disposition = ShotTimerEventDisposition.counted,
    this.normalizedPeak,
    this.detectionQuality,
    this.exclusionReason,
  });

  final String id;
  final int sequenceNumber;
  final Duration elapsed;
  final Duration split;
  final ShotTimerEventSource source;
  final ShotTimerEventDisposition disposition;
  final double? normalizedPeak;
  final ShotTimerDetectionQuality? detectionQuality;
  final String? exclusionReason;

  ShotTimerEvent copyWith({
    int? sequenceNumber,
    Duration? elapsed,
    Duration? split,
    ShotTimerEventDisposition? disposition,
    Object? normalizedPeak = _unset,
    Object? detectionQuality = _unset,
    Object? exclusionReason = _unset,
  }) => ShotTimerEvent(
    id: id,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    elapsed: elapsed ?? this.elapsed,
    split: split ?? this.split,
    source: source,
    disposition: disposition ?? this.disposition,
    normalizedPeak: identical(normalizedPeak, _unset)
        ? this.normalizedPeak
        : normalizedPeak as double?,
    detectionQuality: identical(detectionQuality, _unset)
        ? this.detectionQuality
        : detectionQuality as ShotTimerDetectionQuality?,
    exclusionReason: identical(exclusionReason, _unset)
        ? this.exclusionReason
        : exclusionReason as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'sequenceNumber': sequenceNumber,
    'elapsedMicros': elapsed.inMicroseconds,
    'splitMicros': split.inMicroseconds,
    'source': source.wireName,
    'disposition': disposition.wireName,
    'normalizedPeak': normalizedPeak,
    'detectionQuality': detectionQuality?.wireName,
    'exclusionReason': exclusionReason,
  };

  factory ShotTimerEvent.fromMap(Map<Object?, Object?> map) => ShotTimerEvent(
    id: map['id'] as String,
    sequenceNumber: (map['sequenceNumber'] as num).toInt(),
    elapsed: _duration(map['elapsedMicros']),
    split: _duration(map['splitMicros']),
    source: ShotTimerEventSource.fromWire(map['source']),
    disposition: ShotTimerEventDisposition.fromWire(
      map['disposition'] ?? 'counted',
    ),
    normalizedPeak: (map['normalizedPeak'] as num?)?.toDouble(),
    detectionQuality: ShotTimerDetectionQuality.fromNullableWire(
      map['detectionQuality'],
    ),
    exclusionReason: map['exclusionReason'] as String?,
  );
}

class ShotTimerSnapshot {
  ShotTimerSnapshot({
    required this.state,
    this.configuration,
    Iterable<ShotTimerEvent> events = const [],
    this.actualStartDelay,
    this.runStartMonotonicMicros,
    this.interruptionReason,
    this.errorCode,
    this.errorMessage,
  }) : events = UnmodifiableListView(events);

  factory ShotTimerSnapshot.idle() =>
      ShotTimerSnapshot(state: ShotTimerState.idle);

  final ShotTimerState state;
  final ShotTimerConfiguration? configuration;
  final List<ShotTimerEvent> events;
  final Duration? actualStartDelay;
  final int? runStartMonotonicMicros;
  final String? interruptionReason;
  final String? errorCode;
  final String? errorMessage;

  ShotTimerSnapshot copyWith({
    ShotTimerState? state,
    Object? configuration = _unset,
    Iterable<ShotTimerEvent>? events,
    Object? actualStartDelay = _unset,
    Object? runStartMonotonicMicros = _unset,
    Object? interruptionReason = _unset,
    Object? errorCode = _unset,
    Object? errorMessage = _unset,
  }) => ShotTimerSnapshot(
    state: state ?? this.state,
    configuration: identical(configuration, _unset)
        ? this.configuration
        : configuration as ShotTimerConfiguration?,
    events: events ?? this.events,
    actualStartDelay: identical(actualStartDelay, _unset)
        ? this.actualStartDelay
        : actualStartDelay as Duration?,
    runStartMonotonicMicros: identical(runStartMonotonicMicros, _unset)
        ? this.runStartMonotonicMicros
        : runStartMonotonicMicros as int?,
    interruptionReason: identical(interruptionReason, _unset)
        ? this.interruptionReason
        : interruptionReason as String?,
    errorCode: identical(errorCode, _unset)
        ? this.errorCode
        : errorCode as String?,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
  );
}

class ShotTimerResult {
  ShotTimerResult({
    required this.actualStartDelay,
    required Iterable<ShotTimerEvent> events,
    required this.countedShotCount,
    required this.firstShotTime,
    required this.lastShotTime,
    required this.totalTime,
    required this.fastestSplit,
    required this.slowestSplit,
    required this.averageSplit,
    required this.splitStandardDeviation,
    Iterable<String> qualityWarnings = const [],
    this.userEdited = false,
  }) : events = UnmodifiableListView(events),
       qualityWarnings = UnmodifiableListView(qualityWarnings);

  final Duration actualStartDelay;
  final List<ShotTimerEvent> events;
  final int countedShotCount;
  final Duration? firstShotTime;
  final Duration? lastShotTime;
  final Duration totalTime;
  final Duration? fastestSplit;
  final Duration? slowestSplit;
  final Duration? averageSplit;
  final Duration? splitStandardDeviation;
  final List<String> qualityWarnings;
  final bool userEdited;
}

const Object _unset = Object();

Duration _duration(Object? value, {Duration fallback = Duration.zero}) =>
    value == null ? fallback : Duration(microseconds: (value as num).toInt());
