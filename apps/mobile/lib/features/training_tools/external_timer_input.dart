import 'package:shooting_companion_shot_timer/shot_timer.dart';

enum ExternalTimerInputField { firstShot, totalTime, cumulativeShotTimes }

class ExternalTimerInputValidation {
  const ExternalTimerInputValidation._({
    required this.errors,
    this.measurement,
  });

  final Map<ExternalTimerInputField, String> errors;
  final ExternalTimerMeasurement? measurement;

  bool get isValid => measurement != null && errors.isEmpty;

  String? errorFor(ExternalTimerInputField field) => errors[field];
}

/// A manually copied measurement from a separate shot timer.
///
/// [cumulativeShotTimes] is `null` when only the first-shot and total times
/// are known. In that case no shot events are invented: the two summary
/// values remain aggregates rather than being stored as two shots.
class ExternalTimerMeasurement {
  const ExternalTimerMeasurement({
    required this.firstShotTime,
    required this.totalTime,
    required this.cumulativeShotTimes,
  });

  final Duration firstShotTime;
  final Duration totalTime;
  final List<Duration>? cumulativeShotTimes;

  bool get hasCompleteShotTimes => cumulativeShotTimes != null;

  ShotTimerResult toResult() {
    final times = cumulativeShotTimes;
    if (times == null) {
      return ShotTimerResult(
        actualStartDelay: Duration.zero,
        events: const [],
        countedShotCount: 0,
        firstShotTime: firstShotTime,
        lastShotTime: totalTime,
        totalTime: totalTime,
        fastestSplit: null,
        slowestSplit: null,
        averageSplit: null,
        splitStandardDeviation: null,
        qualityWarnings: const ['Geen afzonderlijke splits ingevoerd'],
        userEdited: true,
      );
    }

    Duration? previous;
    final events = <ShotTimerEvent>[];
    for (var index = 0; index < times.length; index++) {
      final elapsed = times[index];
      events.add(
        ShotTimerEvent(
          id: 'external-${index + 1}',
          sequenceNumber: index + 1,
          elapsed: elapsed,
          split: previous == null ? elapsed : elapsed - previous,
          source: ShotTimerEventSource.external,
        ),
      );
      previous = elapsed;
    }
    return ShotTimerStatistics.summarize(
      actualStartDelay: Duration.zero,
      events: events,
      recordedTotalTime: totalTime,
      userEdited: true,
    );
  }
}

class ExternalTimerInputParser {
  const ExternalTimerInputParser._();

  static ExternalTimerInputValidation validate({
    required String firstShotText,
    required String totalTimeText,
    required String cumulativeShotTimesText,
  }) {
    final errors = <ExternalTimerInputField, String>{};
    final firstShot = _positiveDuration(firstShotText);
    final totalTime = _positiveDuration(totalTimeText);

    if (firstShot == null) {
      errors[ExternalTimerInputField.firstShot] =
          'Vul een positieve eerste-schottijd in';
    }
    if (totalTime == null) {
      errors[ExternalTimerInputField.totalTime] =
          'Vul een positieve totale tijd in';
    } else if (firstShot != null && totalTime < firstShot) {
      errors[ExternalTimerInputField.totalTime] =
          'Totale tijd mag niet vóór het eerste schot liggen';
    }

    List<Duration>? cumulativeTimes;
    final detailsText = cumulativeShotTimesText.trim();
    if (detailsText.isNotEmpty) {
      cumulativeTimes = _durationList(detailsText);
      if (cumulativeTimes == null) {
        errors[ExternalTimerInputField.cumulativeShotTimes] =
            'Gebruik positieve, strikt oplopende tijden';
      } else if (firstShot != null && cumulativeTimes.first != firstShot) {
        errors[ExternalTimerInputField.cumulativeShotTimes] =
            'De eerste detailtijd moet gelijk zijn aan de eerste-schottijd';
      } else if (totalTime != null && cumulativeTimes.last != totalTime) {
        errors[ExternalTimerInputField.cumulativeShotTimes] =
            'De laatste detailtijd moet gelijk zijn aan de totale tijd';
      }
    }

    if (errors.isNotEmpty || firstShot == null || totalTime == null) {
      return ExternalTimerInputValidation._(errors: errors);
    }
    return ExternalTimerInputValidation._(
      errors: const {},
      measurement: ExternalTimerMeasurement(
        firstShotTime: firstShot,
        totalTime: totalTime,
        cumulativeShotTimes: cumulativeTimes,
      ),
    );
  }

  static Duration? _positiveDuration(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
    return Duration(microseconds: (parsed * 1000000).round());
  }

  static List<Duration>? _durationList(String value) {
    final tokens = value
        .split(RegExp(r'[\s;]+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return null;
    final durations = <Duration>[];
    for (final token in tokens) {
      final duration = _positiveDuration(token);
      if (duration == null) return null;
      if (durations.isNotEmpty && duration <= durations.last) return null;
      durations.add(duration);
    }
    return List.unmodifiable(durations);
  }
}
