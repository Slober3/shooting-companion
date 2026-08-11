import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/training_tools/external_timer_input.dart';

void main() {
  test('summary-only input keeps first and total without inventing events', () {
    final validation = ExternalTimerInputParser.validate(
      firstShotText: '1,14',
      totalTimeText: '4,72',
      cumulativeShotTimesText: '',
    );

    expect(validation.isValid, isTrue);
    final result = validation.measurement!.toResult();
    expect(result.events, isEmpty);
    expect(result.countedShotCount, 0);
    expect(result.firstShotTime, const Duration(milliseconds: 1140));
    expect(result.lastShotTime, const Duration(milliseconds: 4720));
    expect(result.totalTime, const Duration(milliseconds: 4720));
    expect(result.averageSplit, isNull);
    expect(
      result.qualityWarnings,
      contains('Geen afzonderlijke splits ingevoerd'),
    );
  });

  test('complete cumulative times create truthful shot events and splits', () {
    final validation = ExternalTimerInputParser.validate(
      firstShotText: '1.14',
      totalTimeText: '4,72',
      cumulativeShotTimesText: '1,14\n1,66\n2,12\n4,72',
    );

    expect(validation.isValid, isTrue);
    final result = validation.measurement!.toResult();
    expect(result.countedShotCount, 4);
    expect(result.events.map((event) => event.elapsed.inMilliseconds), [
      1140,
      1660,
      2120,
      4720,
    ]);
    expect(result.events.map((event) => event.split.inMilliseconds), [
      1140,
      520,
      460,
      2600,
    ]);
    expect(result.totalTime, const Duration(milliseconds: 4720));
  });

  test('detail list must be complete, matching and strictly increasing', () {
    final mismatchedFirst = ExternalTimerInputParser.validate(
      firstShotText: '1,14',
      totalTimeText: '4,72',
      cumulativeShotTimesText: '1,20\n4,72',
    );
    expect(
      mismatchedFirst.errorFor(ExternalTimerInputField.cumulativeShotTimes),
      contains('eerste detailtijd'),
    );

    final mismatchedLast = ExternalTimerInputParser.validate(
      firstShotText: '1,14',
      totalTimeText: '4,72',
      cumulativeShotTimesText: '1,14\n4,50',
    );
    expect(
      mismatchedLast.errorFor(ExternalTimerInputField.cumulativeShotTimes),
      contains('laatste detailtijd'),
    );

    final nonMonotone = ExternalTimerInputParser.validate(
      firstShotText: '1,14',
      totalTimeText: '4,72',
      cumulativeShotTimesText: '1,14\n2,12\n1,66\n4,72',
    );
    expect(
      nonMonotone.errorFor(ExternalTimerInputField.cumulativeShotTimes),
      contains('strikt oplopende'),
    );
  });

  test('total time cannot precede the first shot', () {
    final validation = ExternalTimerInputParser.validate(
      firstShotText: '2,00',
      totalTimeText: '1,50',
      cumulativeShotTimesText: '',
    );

    expect(
      validation.errorFor(ExternalTimerInputField.totalTime),
      contains('niet vóór het eerste schot'),
    );
  });
}
