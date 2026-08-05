import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:test/test.dart';

void main() {
  ShotTimerEvent event(
    String id,
    int milliseconds, {
    ShotTimerEventDisposition disposition = ShotTimerEventDisposition.counted,
  }) => ShotTimerEvent(
    id: id,
    sequenceNumber: 0,
    elapsed: Duration(milliseconds: milliseconds),
    split: Duration.zero,
    source: ShotTimerEventSource.acoustic,
    disposition: disposition,
  );

  test('summarizes first shot and later splits only', () {
    final result = ShotTimerStatistics.summarize(
      actualStartDelay: const Duration(seconds: 3),
      events: [event('a', 1000), event('b', 1400), event('c', 2000)],
    );

    expect(result.countedShotCount, 3);
    expect(result.firstShotTime, const Duration(seconds: 1));
    expect(result.totalTime, const Duration(seconds: 2));
    expect(result.fastestSplit, const Duration(milliseconds: 400));
    expect(result.slowestSplit, const Duration(milliseconds: 600));
    expect(result.averageSplit, const Duration(milliseconds: 500));
    expect(result.splitStandardDeviation?.inMilliseconds, 141);
  });

  test('excluded detections do not alter shot statistics', () {
    final result = ShotTimerStatistics.summarize(
      actualStartDelay: Duration.zero,
      events: [
        event('a', 1000),
        event('echo', 1050, disposition: ShotTimerEventDisposition.excluded),
        event('b', 1500),
      ],
    );

    expect(result.countedShotCount, 2);
    expect(result.averageSplit, const Duration(milliseconds: 500));
    expect(result.events, hasLength(3));
  });

  test('normalization produces monotonic sequence and splits', () {
    final normalized = ShotTimerStatistics.normalizeEvents([
      event('b', 1300),
      event('ignored', 1100, disposition: ShotTimerEventDisposition.excluded),
      event('a', 900),
    ]);

    expect(normalized.map((value) => value.id), ['a', 'ignored', 'b']);
    expect(normalized.first.sequenceNumber, 1);
    expect(normalized[1].sequenceNumber, 0);
    expect(normalized.last.sequenceNumber, 2);
    expect(normalized.last.split, const Duration(milliseconds: 400));
  });
}
