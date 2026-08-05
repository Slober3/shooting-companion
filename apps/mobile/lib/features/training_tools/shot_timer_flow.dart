import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_shot_timer/shot_timer.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_notice.dart';
import 'shot_timer_release_gate.dart';
import 'shot_timer_screens.dart';

/// Opens the timer workflow and persists the reviewed result.
///
/// A run can remain standalone or be linked to a single series. Timer events
/// never alter the score, impacts or shot count of that series.
Future<String?> launchShotTimerFlow({
  required BuildContext context,
  required WidgetRef ref,
  ShotTimerMode? initialMode,
  String? sessionId,
  String? seriesId,
}) async {
  final releasedMode =
      !acousticShotTimerEnabled && initialMode == ShotTimerMode.acousticLiveFire
      ? ShotTimerMode.par
      : initialMode;
  final draft = await Navigator.of(context).push<ShotTimerDraft>(
    MaterialPageRoute(
      builder: (_) => ShotTimerSetupScreen(initialMode: releasedMode),
    ),
  );
  if (draft == null || !context.mounted) return null;

  final repository = ref.read(repositoryProvider);
  try {
    final activityId = await repository.saveCompletedTimerActivity(
      kind: storedActivityKind(draft.configuration.mode),
      sessionId: sessionId,
      seriesId: seriesId,
      configuration: draft.configuration.toMap(),
      summary: shotTimerSummaryMap(
        draft.result,
        mode: draft.configuration.mode,
      ),
      events: draft.result.events.map(newStoredTimerEvent).toList(),
      startedAtUtc: draft.startedAtUtc,
      localUtcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
      completedAtUtc: DateTime.now().toUtc(),
      detectorVersion: draft.configuration.calibration?.detectorVersion,
    );
    if (context.mounted) {
      AppMessenger.success(
        context,
        seriesId == null
            ? 'Timerrun bewaard'
            : 'Timerrun aan de reeks gekoppeld',
      );
    }
    return activityId;
  } on Object {
    if (context.mounted) {
      AppMessenger.error(
        context,
        'De timerrun kon niet worden bewaard. Probeer opnieuw.',
      );
    }
    return null;
  }
}

StoredTrainingActivityKind storedActivityKind(ShotTimerMode mode) =>
    switch (mode) {
      ShotTimerMode.acousticLiveFire =>
        StoredTrainingActivityKind.acousticLiveFire,
      ShotTimerMode.par => StoredTrainingActivityKind.par,
      ShotTimerMode.cadence => StoredTrainingActivityKind.cadence,
      ShotTimerMode.externalManual => StoredTrainingActivityKind.externalManual,
    };

NewShotTimerEvent newStoredTimerEvent(ShotTimerEvent event) =>
    NewShotTimerEvent(
      id: event.id,
      elapsedMicroseconds: event.elapsed.inMicroseconds,
      splitMicroseconds: event.split.inMicroseconds,
      source: StoredTimerEventSource.values.byName(event.source.wireName),
      disposition: StoredTimerEventDisposition.values.byName(
        event.disposition.wireName,
      ),
      normalizedPeak: event.normalizedPeak,
      detectionQuality: event.detectionQuality?.wireName,
      exclusionReason: event.exclusionReason,
    );

Map<String, Object?> shotTimerSummaryMap(
  ShotTimerResult result, {
  ShotTimerMode? mode,
}) {
  final isExternalSummaryOnly =
      mode == ShotTimerMode.externalManual && result.events.isEmpty;
  return {
    'countedShotCount': isExternalSummaryOnly ? null : result.countedShotCount,
    'actualStartDelayMicros': result.actualStartDelay.inMicroseconds,
    'firstShotTimeMicros': result.firstShotTime?.inMicroseconds,
    'lastShotTimeMicros': result.lastShotTime?.inMicroseconds,
    'totalTimeMicros': result.totalTime.inMicroseconds,
    'fastestSplitMicros': result.fastestSplit?.inMicroseconds,
    'slowestSplitMicros': result.slowestSplit?.inMicroseconds,
    'averageSplitMicros': result.averageSplit?.inMicroseconds,
    'splitStandardDeviationMicros':
        result.splitStandardDeviation?.inMicroseconds,
    'qualityWarnings': result.qualityWarnings,
    'userEdited': result.userEdited,
    if (mode == ShotTimerMode.externalManual)
      'externalTimingCompleteness': isExternalSummaryOnly
          ? 'summaryOnly'
          : 'complete',
    if (mode == ShotTimerMode.externalManual)
      'shotCountKnown': !isExternalSummaryOnly,
  };
}
