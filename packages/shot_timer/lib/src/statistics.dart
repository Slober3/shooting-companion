import 'dart:math' as math;

import 'models.dart';

class ShotTimerStatistics {
  const ShotTimerStatistics._();

  static ShotTimerResult summarize({
    required Duration actualStartDelay,
    required Iterable<ShotTimerEvent> events,
    Duration? recordedTotalTime,
    Iterable<String> qualityWarnings = const [],
    bool userEdited = false,
  }) {
    final allEvents = List<ShotTimerEvent>.of(events)
      ..sort((left, right) {
        final byElapsed = left.elapsed.compareTo(right.elapsed);
        if (byElapsed != 0) return byElapsed;
        return left.sequenceNumber.compareTo(right.sequenceNumber);
      });
    final counted = allEvents
        .where(
          (event) => event.disposition == ShotTimerEventDisposition.counted,
        )
        .toList(growable: false);
    final normalized = _normalizeSplits(counted);
    final splitValues = normalized.length < 2
        ? const <Duration>[]
        : normalized.skip(1).map((event) => event.split).toList();

    return ShotTimerResult(
      actualStartDelay: actualStartDelay,
      events: allEvents,
      countedShotCount: counted.length,
      firstShotTime: normalized.isEmpty ? null : normalized.first.elapsed,
      lastShotTime: normalized.isEmpty ? null : normalized.last.elapsed,
      totalTime:
          recordedTotalTime ??
          (normalized.isEmpty ? Duration.zero : normalized.last.elapsed),
      fastestSplit: splitValues.isEmpty
          ? null
          : splitValues.reduce(_minimumDuration),
      slowestSplit: splitValues.isEmpty
          ? null
          : splitValues.reduce(_maximumDuration),
      averageSplit: splitValues.isEmpty ? null : _average(splitValues),
      splitStandardDeviation: splitValues.length < 2
          ? null
          : _sampleStandardDeviation(splitValues),
      qualityWarnings: qualityWarnings,
      userEdited: userEdited,
    );
  }

  /// Recalculates sequence numbers and splits after review edits.
  static List<ShotTimerEvent> normalizeEvents(Iterable<ShotTimerEvent> events) {
    final ordered = List<ShotTimerEvent>.of(events)
      ..sort((left, right) {
        final comparison = left.elapsed.compareTo(right.elapsed);
        if (comparison != 0) return comparison;
        return left.id.compareTo(right.id);
      });
    Duration? previousCounted;
    var countedSequence = 0;
    final result = <ShotTimerEvent>[];
    for (final event in ordered) {
      if (event.disposition == ShotTimerEventDisposition.counted) {
        countedSequence++;
        result.add(
          event.copyWith(
            sequenceNumber: countedSequence,
            split: previousCounted == null
                ? event.elapsed
                : event.elapsed - previousCounted,
          ),
        );
        previousCounted = event.elapsed;
      } else {
        result.add(event.copyWith(sequenceNumber: 0));
      }
    }
    return result;
  }

  static List<ShotTimerEvent> _normalizeSplits(List<ShotTimerEvent> events) {
    final ordered = List<ShotTimerEvent>.of(events)
      ..sort((left, right) => left.elapsed.compareTo(right.elapsed));
    Duration? previous;
    final result = <ShotTimerEvent>[];
    for (var index = 0; index < ordered.length; index++) {
      result.add(
        ordered[index].copyWith(
          sequenceNumber: index + 1,
          split: previous == null
              ? ordered[index].elapsed
              : ordered[index].elapsed - previous,
        ),
      );
      previous = ordered[index].elapsed;
    }
    return result;
  }

  static Duration _average(List<Duration> values) => Duration(
    microseconds:
        values.fold<int>(0, (sum, value) => sum + value.inMicroseconds) ~/
        values.length,
  );

  static Duration _sampleStandardDeviation(List<Duration> values) {
    final mean =
        values.fold<double>(0, (sum, value) => sum + value.inMicroseconds) /
        values.length;
    final variance =
        values.fold<double>(0, (sum, value) {
          final delta = value.inMicroseconds - mean;
          return sum + delta * delta;
        }) /
        (values.length - 1);
    return Duration(microseconds: math.sqrt(variance).round());
  }

  static Duration _minimumDuration(Duration left, Duration right) =>
      left <= right ? left : right;

  static Duration _maximumDuration(Duration left, Duration right) =>
      left >= right ? left : right;
}
