import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_training/training.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../progress/analysis_adapter.dart';
import '../progress/analysis_series_picker_screen.dart';
import '../session/manual_series_screen.dart';
import 'shot_timer_flow.dart';
import 'training_plan_models.dart';

class GuidedDrillRunnerScreen extends ConsumerStatefulWidget {
  const GuidedDrillRunnerScreen({
    required this.drill,
    this.activityId,
    this.planContext,
    super.key,
  });

  final DrillDefinitionV2 drill;
  final String? activityId;
  final TrainingPlanContext? planContext;

  @override
  ConsumerState<GuidedDrillRunnerScreen> createState() =>
      _GuidedDrillRunnerScreenState();
}

class _GuidedDrillRunnerScreenState
    extends ConsumerState<GuidedDrillRunnerScreen> {
  late DrillDefinitionV2 _drill;
  TrainingPlanContext? _planContext;
  String? _activityId;
  bool _initializing = true;
  bool _busy = false;
  bool _allowPop = false;
  Object? _loadError;
  bool _setupConfirmed = false;
  bool _safetyConfirmed = false;
  final Set<String> _acknowledgedPhaseIds = {};
  final Map<String, String> _timerActivityIds = {};
  final Map<String, String> _phaseReflections = {};

  @override
  void initState() {
    super.initState();
    _drill = widget.drill;
    _planContext = widget.planContext;
    unawaited(_initialize());
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || _activityId == null) {
      return CompactPageScaffold(
        title: 'Drill openen',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44),
                const SizedBox(height: 12),
                const Text('Deze drill kon niet worden geopend.'),
                const SizedBox(height: 8),
                Text('$_loadError', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final activityAsync = ref.watch(trainingActivityProvider(_activityId!));
    final detail = activityAsync.valueOrNull;
    final analyzed = ref
        .watch(analysisDatasetProvider)
        .valueOrNull
        ?.let(analyzeSeriesDataset);
    final linked = detail == null || analyzed == null
        ? const <AnalyzedSeriesView>[]
        : _linkedAnalyzedSeries(detail, analyzed);
    final phase = detail == null ? null : _currentPhase(detail);
    final completedPhases = detail == null
        ? 0
        : _drill.phases.where((item) => _phaseComplete(item, detail)).length;
    final activities =
        ref.watch(trainingActivitiesProvider).valueOrNull ?? const [];
    final evaluation = detail == null || analyzed == null
        ? null
        : DrillRunMeasurementEvaluator.evaluate(
            drill: _drill,
            linked: linked,
            activityStartedAtUtc: detail.activity.startedAtUtc,
            historicalActivities: activities,
            completedEvidenceCount: completedPhases,
          );
    final canComplete =
        detail != null &&
        _setupConfirmed &&
        _safetyConfirmed &&
        completedPhases == _drill.phases.length &&
        (evaluation?.valid ?? false) &&
        !_busy;

    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmInterrupt());
      },
      child: CompactPageScaffold(
        title: _drill.title,
        body: activityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Laden mislukt: $error')),
          data: (value) {
            if (value == null) {
              return const Center(child: Text('Deze drill bestaat niet meer.'));
            }
            return ListView(
              key: const ValueKey('guided-drill-runner-list'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
              children: [
                _RunnerHeader(
                  drill: _drill,
                  completedPhases: completedPhases,
                  linkedSeriesCount: value.links.length,
                ),
                const SizedBox(height: 16),
                _SetupGateCard(
                  drill: _drill,
                  setupConfirmed: _setupConfirmed,
                  safetyConfirmed: _safetyConfirmed,
                  enabled: !_busy,
                  onSetupChanged: (selected) => _updateGate(setup: selected),
                  onSafetyChanged: (selected) => _updateGate(safety: selected),
                ),
                if (_drill.mode == TrainingMode.analysisOnly) ...[
                  const SizedBox(height: 16),
                  _AnalysisEvidenceCard(
                    linkedSeries: linked,
                    enabled: !_busy && _setupConfirmed && _safetyConfirmed,
                    onLink: () =>
                        _linkAnalysisEvidence(value, analyzed ?? const []),
                    onUnlink: _unlinkSeries,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Uitvoering',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final item in _drill.phases)
                  _PhaseCard(
                    phase: item,
                    completed: _phaseComplete(item, value),
                    current: phase?.id == item.id,
                    linkedSeries: _phaseLinkedSeries(item, value, linked),
                    timerCompleted: _timerActivityIds.containsKey(item.id),
                    reflection: _phaseReflections[item.id],
                    enabled:
                        !_busy &&
                        _setupConfirmed &&
                        _safetyConfirmed &&
                        phase?.id == item.id,
                    onAcknowledge: () => _acknowledge(item),
                    onStartSeries: () => _startSeries(item, value),
                    onLinkExisting: () =>
                        _linkExistingSeries(item, value, analyzed ?? const []),
                    onStartTimer: () => _startTimer(item, value),
                    onReflect: () => _recordReflection(item),
                    onUnlinkSeries: (seriesId) => _unlinkSeries(seriesId),
                  ),
                const SizedBox(height: 12),
                _MeasurementCard(evaluation: evaluation),
                const SizedBox(height: 16),
                _MasteryCard(
                  rule: _drill.masteryRule,
                  activities: activities,
                  currentDrillVersionedId: _drill.versionedId,
                  currentEvaluation: evaluation,
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stopregels',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final rule in _drill.stopRules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $rule'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: AppActionDock(
          actions: [
            OutlinedButton.icon(
              key: const ValueKey('interrupt-guided-drill'),
              onPressed: _busy ? null : _confirmInterrupt,
              icon: const Icon(Icons.pause_outlined),
              label: const Text('Onderbreken'),
            ),
            FilledButton.icon(
              key: const ValueKey('complete-guided-drill'),
              onPressed: canComplete
                  ? () => _complete(detail, evaluation!)
                  : null,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Afronden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    try {
      final repository = ref.read(repositoryProvider);
      final requestedId = widget.activityId;
      if (requestedId == null) {
        final now = DateTime.now();
        _activityId = await repository.createTrainingActivity(
          kind: StoredTrainingActivityKind.guidedDrillV2,
          activitySchemaVersion: 2,
          configuration: {
            'drillVersionedId': _drill.versionedId,
            'drill': _drill.toJson(),
            if (_planContext != null) 'trainingPlan': _planContext!.toJson(),
          },
          summary: _summary(),
          startedAtUtc: now.toUtc(),
          localUtcOffsetMinutes: now.timeZoneOffset.inMinutes,
        );
      } else {
        final detail = await repository.getTrainingActivity(requestedId);
        if (detail == null) {
          throw StateError('De opgeslagen drill bestaat niet meer.');
        }
        if (detail.activity.kind !=
            StoredTrainingActivityKind.guidedDrillV2.name) {
          throw StateError('De opgeslagen activiteit is geen drill.');
        }
        final configuration = _jsonObject(detail.activity.configurationJson);
        final snapshot = configuration['drill'];
        if (snapshot is Map) {
          try {
            _drill = DrillDefinitionV2.fromJson(
              snapshot.cast<String, Object?>(),
            );
          } on Object {
            throw StateError(
              'Deze historische drill gebruikt een oud runnerformaat en is '
              'alleen leesbaar in de activiteitengeschiedenis.',
            );
          }
        }
        final storedPlan = configuration['trainingPlan'];
        if (_planContext == null && storedPlan is Map) {
          _planContext = TrainingPlanContext.fromJson(
            storedPlan.cast<String, Object?>(),
          );
        }
        _restoreSummary(_jsonObject(detail.activity.summaryJson));
        _activityId = requestedId;
        if (detail.activity.status ==
            StoredTrainingActivityStatus.interrupted.name) {
          await repository.resumeDrillActivity(requestedId);
        }
      }
    } on Object catch (error) {
      _loadError = error;
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _restoreSummary(Map<String, Object?> summary) {
    _setupConfirmed = summary['setupConfirmed'] == true;
    _safetyConfirmed = summary['safetyConfirmed'] == true;
    _acknowledgedPhaseIds
      ..clear()
      ..addAll(_stringList(summary['acknowledgedPhaseIds']));
    _timerActivityIds
      ..clear()
      ..addAll(_stringMap(summary['timerActivityIds']));
    _phaseReflections
      ..clear()
      ..addAll(_stringMap(summary['phaseReflections']));
  }

  Map<String, Object?> _summary({DrillMeasurementEvaluation? evaluation}) => {
    'drillVersionedId': _drill.versionedId,
    'setupConfirmed': _setupConfirmed,
    'safetyConfirmed': _safetyConfirmed,
    'acknowledgedPhaseIds': _acknowledgedPhaseIds.toList()..sort(),
    'timerActivityIds': Map<String, String>.from(_timerActivityIds),
    'phaseReflections': Map<String, String>.from(_phaseReflections),
    if (evaluation != null) ...{
      'validExecution': evaluation.valid,
      'primaryMetric': evaluation.metric.name,
      'primaryMeasurementValue': evaluation.value,
      'primaryMeasurementSampleSize': evaluation.sampleSize,
      'personalBaselineValue': evaluation.baselineValue,
      'primaryMeasurementSuccess': evaluation.success,
      'metricSnapshot': evaluation.toSnapshotJson(),
      'sessionIds': evaluation.sessionIds,
    },
  };

  Future<void> _persistProgress({
    DrillMeasurementEvaluation? evaluation,
  }) async {
    final id = _activityId;
    if (id == null) return;
    await ref
        .read(repositoryProvider)
        .updateDrillActivityProgress(
          activityId: id,
          summary: _summary(evaluation: evaluation),
        );
  }

  Future<void> _updateGate({bool? setup, bool? safety}) async {
    if (_busy) return;
    setState(() {
      if (setup != null) _setupConfirmed = setup;
      if (safety != null) _safetyConfirmed = safety;
      _busy = true;
    });
    try {
      await _persistProgress();
    } on Object {
      if (mounted) AppMessenger.error(context, 'Voortgang bewaren mislukt.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acknowledge(DrillPhaseV2 phase) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _acknowledgedPhaseIds.add(phase.id);
    });
    try {
      await _persistProgress();
    } on Object {
      _acknowledgedPhaseIds.remove(phase.id);
      if (mounted) AppMessenger.error(context, 'Voortgang bewaren mislukt.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startSeries(
    DrillPhaseV2 phase,
    TrainingActivityDetail activity,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(repositoryProvider);
      final active = await ref.read(activeSessionProvider.future);
      late String sessionId;
      late String seriesId;
      var reusedExistingDraft = false;
      if (active == null) {
        final createSession = await _confirmQuickSessionForDrill();
        if (!createSession) return;
        final quick = await repository.startQuickSession();
        sessionId = quick.sessionId;
        seriesId = quick.draftSeriesId;
      } else {
        sessionId = active.id;
        final session = await repository.getSessionDetail(sessionId);
        final existingDraft = session?.draftSeries;
        if (existingDraft != null) {
          seriesId = existingDraft.id;
          reusedExistingDraft = true;
        } else {
          seriesId = await repository.createOrResumeDraftSeries(sessionId);
        }
      }
      if (!mounted) return;
      if (reusedExistingDraft) {
        AppMessenger.info(
          context,
          'Het bestaande concept wordt geopend en niet vervangen.',
        );
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ManualSeriesScreen(
            sessionId: sessionId,
            seriesId: seriesId,
            guidedSingleSeries: true,
            preferredFirearmId: _planContext?.firearmId,
            preferredAmmoLotId: _planContext?.ammoLotId,
            onSeriesConfirmed: (confirmedId) async {
              final plan = _planContext;
              await repository.linkConfirmedSeriesToGuidedDrill(
                drillActivityId: _activityId!,
                seriesId: confirmedId,
                drillRole: phase.id,
                planActivityId: plan?.planActivityId,
                planRole: plan == null
                    ? null
                    : 'slot:${plan.slotIndex}:${phase.id}',
                variantId: _drill.versionedId,
              );
            },
          ),
        ),
      );
      if (!mounted) return;
      ref.invalidate(trainingActivityProvider(_activityId!));
    } on ActiveSessionExistsException {
      if (mounted) {
        AppMessenger.info(context, 'Open eerst de actieve sessie.');
      }
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, 'Reeks openen mislukt: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmQuickSessionForDrill() async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Nieuwe sessie starten?'),
            content: const Text(
              'Er is geen actieve sessie. Voor deze drill wordt een nieuwe '
              'sessie met een conceptreeks aangemaakt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuleren'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sessie starten'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _linkExistingSeries(
    DrillPhaseV2 phase,
    TrainingActivityDetail detail,
    List<AnalyzedSeriesView> all,
  ) async {
    if (_busy) return;
    final linkedIds = detail.links.map((link) => link.seriesId).toSet();
    final candidates = all
        .where(
          (item) =>
              !linkedIds.contains(item.source.series.id) &&
              (_drill.mode == TrainingMode.analysisOnly ||
                  !item.source.series.createdAtUtc.isBefore(
                    detail.activity.startedAtUtc,
                  )) &&
              (detail.activity.sessionId == null ||
                  item.source.series.sessionId == detail.activity.sessionId),
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      AppMessenger.info(
        context,
        'Geen nog niet gekoppelde bevestigde reeks uit deze drill gevonden.',
      );
      return;
    }
    final selectedId = await showAnalysisSeriesPicker(context, candidates);
    if (selectedId == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final plan = _planContext;
      await ref
          .read(repositoryProvider)
          .linkConfirmedSeriesToGuidedDrill(
            drillActivityId: _activityId!,
            seriesId: selectedId,
            drillRole: phase.id,
            planActivityId: plan?.planActivityId,
            planRole: plan == null
                ? null
                : 'slot:${plan.slotIndex}:${phase.id}',
            variantId: _drill.versionedId,
          );
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, 'Koppelen mislukt: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkAnalysisEvidence(
    TrainingActivityDetail detail,
    List<AnalyzedSeriesView> all,
  ) async {
    if (_busy) return;
    final linkedIds = detail.links.map((link) => link.seriesId).toSet();
    final candidates = all
        .where((item) => !linkedIds.contains(item.source.series.id))
        .toList(growable: false);
    if (candidates.isEmpty) {
      AppMessenger.info(
        context,
        'Geen nog niet gekoppelde bevestigde reeks beschikbaar.',
      );
      return;
    }
    final selectedId = await showAnalysisSeriesPicker(context, candidates);
    if (selectedId == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final plan = _planContext;
      await ref
          .read(repositoryProvider)
          .linkConfirmedSeriesToGuidedDrill(
            drillActivityId: _activityId!,
            seriesId: selectedId,
            drillRole: 'analysis-evidence',
            planActivityId: plan?.planActivityId,
            planRole: plan == null
                ? null
                : 'slot:${plan.slotIndex}:analysis-evidence',
            variantId: _drill.versionedId,
          );
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, 'Koppelen mislukt: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkSeries(String seriesId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(repositoryProvider)
          .unlinkConfirmedSeriesFromGuidedDrill(
            drillActivityId: _activityId!,
            seriesId: seriesId,
          );
    } on Object {
      if (mounted) AppMessenger.error(context, 'Loskoppelen mislukt.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startTimer(
    DrillPhaseV2 phase,
    TrainingActivityDetail detail,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final active = await ref.read(activeSessionProvider.future);
      if (!mounted) return;
      final timerActivityId = await launchShotTimerFlow(
        context: context,
        ref: ref,
        sessionId: detail.activity.sessionId ?? active?.id,
      );
      if (timerActivityId == null || !mounted) return;
      _timerActivityIds[phase.id] = timerActivityId;
      await _persistProgress();
    } on Object {
      if (mounted) AppMessenger.error(context, 'Timer bewaren mislukt.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordReflection(DrillPhaseV2 phase) async {
    final controller = TextEditingController(text: _phaseReflections[phase.id]);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Korte reflectie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final prompt in _drill.reflectionPrompts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $prompt'),
                ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('drill-reflection-input'),
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Wat neem je mee?',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              child: const Text('Bewaren'),
            ),
          ],
        ),
      );
      if (result == null || !mounted) return;
      setState(() {
        _phaseReflections[phase.id] = result;
        _busy = true;
      });
      await _persistProgress();
    } on Object {
      if (mounted) AppMessenger.error(context, 'Reflectie bewaren mislukt.');
    } finally {
      controller.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmInterrupt() async {
    if (_busy || _activityId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Training onderbreken?'),
        content: const Text(
          'Je echte reekskoppelingen en voortgang blijven bewaard. '
          'Je kunt later verdergaan vanuit de drillbibliotheek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Verder trainen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Onderbreken'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(repositoryProvider)
          .interruptTrainingActivity(
            activityId: _activityId!,
            summary: _summary(),
          );
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.pop(context, false);
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        AppMessenger.error(context, 'Onderbreken mislukt.');
      }
    }
  }

  Future<void> _complete(
    TrainingActivityDetail detail,
    DrillMeasurementEvaluation evaluation,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(repositoryProvider)
          .completeGuidedDrillActivity(
            activityId: _activityId!,
            summary: {
              ..._summary(evaluation: evaluation),
              'linkedSeriesCount': detail.links.length,
              'completedPhaseIds': _drill.phases
                  .where((phase) => _phaseComplete(phase, detail))
                  .map((phase) => phase.id)
                  .toList(growable: false),
            },
            completedAtUtc: DateTime.now().toUtc(),
            minimumLinkedSeries: _drill.recommendedSeries,
          );
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.pop(context, true);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        AppMessenger.error(context, 'Afronden mislukt: $error');
      }
    }
  }

  DrillPhaseV2? _currentPhase(TrainingActivityDetail detail) => _drill.phases
      .where((phase) => !_phaseComplete(phase, detail))
      .firstOrNull;

  bool _phaseComplete(DrillPhaseV2 phase, TrainingActivityDetail detail) =>
      switch (phase.completionKind) {
        DrillPhaseCompletionKind.acknowledged => _acknowledgedPhaseIds.contains(
          phase.id,
        ),
        DrillPhaseCompletionKind.confirmedSeries =>
          _phaseLinks(phase, detail).length >= (phase.seriesCount ?? 1),
        DrillPhaseCompletionKind.timerActivity => _timerActivityIds.containsKey(
          phase.id,
        ),
        DrillPhaseCompletionKind.reflection =>
          _phaseReflections[phase.id]?.trim().isNotEmpty ?? false,
      };

  List<TrainingActivitySeriesLinkRecord> _phaseLinks(
    DrillPhaseV2 phase,
    TrainingActivityDetail detail,
  ) {
    final explicit = detail.links
        .where((link) => link.role == phase.id)
        .toList(growable: false);
    if (explicit.isNotEmpty) return explicit;
    final confirmedPhases = _drill.phases
        .where(
          (item) =>
              item.completionKind == DrillPhaseCompletionKind.confirmedSeries,
        )
        .toList(growable: false);
    if (confirmedPhases.length == 1 &&
        detail.links.every((link) => link.role == null)) {
      return detail.links;
    }
    return const [];
  }

  List<AnalyzedSeriesView> _phaseLinkedSeries(
    DrillPhaseV2 phase,
    TrainingActivityDetail detail,
    List<AnalyzedSeriesView> linked,
  ) {
    final ids = _phaseLinks(phase, detail).map((link) => link.seriesId).toSet();
    return linked
        .where((item) => ids.contains(item.source.series.id))
        .toList(growable: false);
  }
}

class DrillMeasurementEvaluation {
  const DrillMeasurementEvaluation({
    required this.metric,
    required this.direction,
    required this.value,
    required this.sampleSize,
    required this.minimumSampleSize,
    required this.baselineValue,
    required this.baselineTolerance,
    required this.valid,
    required this.success,
    required this.explanation,
    required this.cohort,
    required this.sessionIds,
    required this.baselineExecutionCount,
    required this.baselineSessionCount,
  });

  final TrainingMetricKind metric;
  final TrainingMetricDirection direction;
  final double? value;
  final int sampleSize;
  final int minimumSampleSize;
  final double? baselineValue;
  final double? baselineTolerance;
  final bool valid;
  final bool? success;
  final String explanation;
  final Map<String, Object?>? cohort;
  final List<String> sessionIds;
  final int baselineExecutionCount;
  final int baselineSessionCount;

  Map<String, Object?> toSnapshotJson() => {
    'metric': metric.name,
    'direction': direction.name,
    'value': value,
    'sampleSize': sampleSize,
    'minimumSampleSize': minimumSampleSize,
    'valid': valid,
    'success': success,
    'cohort': cohort,
    'baselineTolerance': baselineTolerance,
    'sessionIds': sessionIds,
  };
}

class DrillRunMeasurementEvaluator {
  const DrillRunMeasurementEvaluator._();

  static DrillMeasurementEvaluation evaluate({
    required DrillDefinitionV2 drill,
    required List<AnalyzedSeriesView> linked,
    required DateTime activityStartedAtUtc,
    required List<TrainingActivityRecord> historicalActivities,
    required int completedEvidenceCount,
  }) {
    final measurement = drill.measurements.firstWhere(
      (item) => item.role == TrainingMeasurementRole.primary,
    );
    final cohort = _cohortFor(linked, drill: drill);
    final sessions =
        linked
            .map((item) => item.source.series.sessionId)
            .toSet()
            .toList(growable: false)
          ..sort();
    final current = _measurementValue(
      measurement.metric,
      linked,
      completedEvidenceCount: completedEvidenceCount,
    );
    final baselineExecutions = measurement.baselineEligible && cohort != null
        ? _baselineExecutions(
            drill: drill,
            measurement: measurement,
            cohort: cohort,
            historicalActivities: historicalActivities,
            beforeUtc: activityStartedAtUtc,
          )
        : const <_HistoricalMetricExecution>[];
    final baselineSessionIds = baselineExecutions
        .expand((item) => item.sessionIds)
        .toSet();
    final baselineReady =
        baselineExecutions.length >= 3 && baselineSessionIds.length >= 2;
    final baseline = baselineReady
        ? _median(
            baselineExecutions
                .take(5)
                .map((item) => item.value)
                .toList(growable: false),
          )
        : null;
    final baselineTolerance =
        baseline == null ||
            measurement.direction != TrainingMetricDirection.stabilize
        ? null
        : _stabilityTolerance(
            measurement.metric,
            baseline,
            baselineExecutions.map((item) => item.value).toList(),
          );
    final valid =
        current.value != null &&
        current.sampleSize >= measurement.minimumSampleSize &&
        (linked.isEmpty || cohort != null);
    bool? success;
    if (valid && measurement.metric == TrainingMetricKind.completion) {
      success = true;
    } else if (valid && drill.masteryRule.usesPersonalBaseline) {
      if (baseline != null) {
        success = switch (measurement.direction) {
          TrainingMetricDirection.maximize => current.value! >= baseline,
          TrainingMetricDirection.minimize => current.value! <= baseline,
          TrainingMetricDirection.stabilize => isWithinStabilityBand(
            current: current.value!,
            baseline: baseline,
            tolerance: baselineTolerance!,
          ),
          TrainingMetricDirection.complete => true,
        };
      }
    }
    final explanation = !valid
        ? 'Nog ${math.max(0, measurement.minimumSampleSize - current.sampleSize)} '
              'geldige metingen nodig.'
        : drill.masteryRule.usesPersonalBaseline && baseline == null
        ? 'Geldige meting; voor een persoonlijke referentie zijn 3 eerdere '
              'geldige uitvoeringen over minstens 2 sessies nodig '
              '(${baselineExecutions.length}/3 uitvoeringen, '
              '${baselineSessionIds.length}/2 sessies).'
        : success == true
        ? measurement.direction == TrainingMetricDirection.stabilize &&
                  baselineTolerance != null
              ? 'Deze uitvoering ligt binnen de persoonlijke band van '
                    '±${baselineTolerance.toStringAsFixed(1)}.'
              : 'Deze uitvoering haalt het meetcriterium.'
        : success == false
        ? measurement.direction == TrainingMetricDirection.stabilize
              ? 'Geldige meting, maar buiten de persoonlijke band.'
              : 'Geldige meting, maar buiten het huidige criterium.'
        : 'Geldige meting opgeslagen voor je voortgang.';
    return DrillMeasurementEvaluation(
      metric: measurement.metric,
      direction: measurement.direction,
      value: current.value,
      sampleSize: current.sampleSize,
      minimumSampleSize: measurement.minimumSampleSize,
      baselineValue: baseline,
      baselineTolerance: baselineTolerance,
      valid: valid,
      success: success,
      explanation: explanation,
      cohort: cohort,
      sessionIds: List.unmodifiable(sessions),
      baselineExecutionCount: baselineExecutions.length,
      baselineSessionCount: baselineSessionIds.length,
    );
  }

  static Map<String, Object?>? _cohortFor(
    List<AnalyzedSeriesView> linked, {
    required DrillDefinitionV2 drill,
  }) {
    if (linked.isEmpty) return const {};
    final fixesAmmunition = _fixesAmmunitionVariable(drill);
    Map<String, Object?> value(AnalyzedSeriesView item) => {
      'targetProfileVersionedId': item.source.series.targetProfileVersionedId,
      'distanceMeters': item.source.series.distanceMeters,
      'firearmId': item.source.series.firearmId,
      if (fixesAmmunition) 'ammoLotId': item.source.series.ammoLotId,
    };
    final first = value(linked.first);
    if (linked.skip(1).any((item) => !_mapsEqual(first, value(item)))) {
      return null;
    }
    return Map.unmodifiable(first);
  }

  static List<_HistoricalMetricExecution> _baselineExecutions({
    required DrillDefinitionV2 drill,
    required DrillMeasurementV2 measurement,
    required Map<String, Object?> cohort,
    required List<TrainingActivityRecord> historicalActivities,
    required DateTime beforeUtc,
  }) {
    final results = <_HistoricalMetricExecution>[];
    for (final activity in historicalActivities) {
      if (activity.kind != StoredTrainingActivityKind.guidedDrillV2.name ||
          activity.status != StoredTrainingActivityStatus.completed.name ||
          !activity.startedAtUtc.isBefore(beforeUtc)) {
        continue;
      }
      try {
        final summary = _jsonObject(activity.summaryJson);
        if (summary['drillVersionedId'] != drill.versionedId) continue;
        final raw = summary['metricSnapshot'];
        if (raw is! Map) continue;
        final snapshot = raw.cast<String, Object?>();
        if (snapshot['metric'] != measurement.metric.name ||
            snapshot['valid'] != true ||
            snapshot['value'] is! num ||
            snapshot['cohort'] is! Map ||
            !_mapsEqual(
              cohort,
              (snapshot['cohort'] as Map).cast<String, Object?>(),
            )) {
          continue;
        }
        final sessionIds = _stringList(snapshot['sessionIds']).toSet();
        if (sessionIds.isEmpty) continue;
        results.add(
          _HistoricalMetricExecution(
            value: (snapshot['value']! as num).toDouble(),
            sessionIds: sessionIds,
            completedAtUtc: activity.completedAtUtc ?? activity.updatedAtUtc,
          ),
        );
      } on Object {
        continue;
      }
    }
    results.sort(
      (left, right) => right.completedAtUtc.compareTo(left.completedAtUtc),
    );
    return results.take(5).toList(growable: false);
  }

  static ({double? value, int sampleSize}) _measurementValue(
    TrainingMetricKind metric,
    List<AnalyzedSeriesView> items, {
    int completedEvidenceCount = 0,
  }) {
    switch (metric) {
      case TrainingMetricKind.completion:
        return (
          value: completedEvidenceCount.toDouble(),
          sampleSize: completedEvidenceCount,
        );
      case TrainingMetricKind.scorePercentage:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        return (
          value: _mean(items.map((item) => item.scorePercentage)),
          sampleSize: items.length,
        );
      case TrainingMetricKind.meanRadiusMm:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        final valid = items
            .where((item) => item.analysis.positionedShotCount >= 2)
            .toList(growable: false);
        return (
          value: valid.isEmpty
              ? null
              : _mean(valid.map((item) => item.analysis.metrics.meanRadiusMm)),
          sampleSize: valid.fold(
            0,
            (total, item) => total + item.analysis.positionedShotCount,
          ),
        );
      case TrainingMetricKind.extremeSpreadMm:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        final valid = items
            .where((item) => item.analysis.positionedShotCount >= 2)
            .toList(growable: false);
        return (
          value: valid.isEmpty
              ? null
              : _mean(
                  valid.map((item) => item.analysis.metrics.extremeSpreadMm),
                ),
          sampleSize: valid.fold(
            0,
            (total, item) => total + item.analysis.positionedShotCount,
          ),
        );
      case TrainingMetricKind.consistency:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        final values = items.map((item) => item.scorePercentage).toList();
        return (
          value: values.length < 2 ? null : _sampleStandardDeviation(values),
          sampleSize: values.length,
        );
      case TrainingMetricKind.absoluteBiasMm:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        final valid = items
            .where((item) => item.analysis.positionedShotCount > 0)
            .toList(growable: false);
        return (
          value: valid.isEmpty
              ? null
              : _mean(
                  valid.map(
                    (item) => math.sqrt(
                      math.pow(item.analysis.metrics.centroidXMm, 2) +
                          math.pow(item.analysis.metrics.centroidYMm, 2),
                    ),
                  ),
                ),
          sampleSize: valid.fold(
            0,
            (total, item) => total + item.analysis.positionedShotCount,
          ),
        );
      case TrainingMetricKind.selfEvaluation:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        final reflected = items
            .where((item) => item.source.reflection != null)
            .length;
        return (value: reflected / items.length * 100, sampleSize: reflected);
      case TrainingMetricKind.filledBullCount:
        if (items.isEmpty) return (value: null, sampleSize: 0);
        final filled = items.fold<int>(
          0,
          (total, item) => total + (item.source.series.scoredBullCount ?? 0),
        );
        return (value: filled.toDouble(), sampleSize: filled);
      case TrainingMetricKind.shotCallAccuracy:
        return (value: null, sampleSize: 0);
    }
  }

  static double _mean(Iterable<double> values) {
    final list = values.toList(growable: false);
    return list.fold<double>(0, (total, value) => total + value) / list.length;
  }

  static double _sampleStandardDeviation(List<double> values) {
    final mean = _mean(values);
    final squared = values.fold<double>(0, (total, value) {
      final delta = value - mean;
      return total + delta * delta;
    });
    return math.sqrt(squared / (values.length - 1));
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double _stabilityTolerance(
    TrainingMetricKind metric,
    double baseline,
    List<double> values,
  ) {
    final deviations = values
        .map((value) => (value - baseline).abs())
        .toList(growable: false);
    final robustSpread = deviations.isEmpty
        ? 0.0
        : 1.4826 * _median(deviations);
    final minimumBand = switch (metric) {
      TrainingMetricKind.scorePercentage => 2.0,
      TrainingMetricKind.consistency => 1.0,
      TrainingMetricKind.selfEvaluation => 5.0,
      TrainingMetricKind.filledBullCount => 1.0,
      TrainingMetricKind.meanRadiusMm ||
      TrainingMetricKind.extremeSpreadMm ||
      TrainingMetricKind.absoluteBiasMm => 0.5,
      TrainingMetricKind.completion ||
      TrainingMetricKind.shotCallAccuracy => 0.01,
    };
    return math.max(minimumBand, math.max(robustSpread, baseline.abs() * 0.05));
  }

  /// A stabilize criterion is a symmetric band around the personal baseline.
  /// It is deliberately not interpreted as "lower is always better".
  @visibleForTesting
  static bool isWithinStabilityBand({
    required double current,
    required double baseline,
    required double tolerance,
  }) => (current - baseline).abs() <= tolerance;
}

bool _fixesAmmunitionVariable(DrillDefinitionV2 drill) {
  final evidence = <String>[
    drill.setup.dataBasis,
    ...drill.setup.equipment,
  ].join(' ').toLowerCase();
  return evidence.contains('munitieprofiel') ||
      evidence.contains('munitielot') ||
      evidence.contains('dezelfde munitie');
}

class DrillMasteryProgress {
  const DrillMasteryProgress({
    required this.validExecutionsInWindow,
    required this.successesInWindow,
    required this.minimumValidExecutions,
    required this.requiredSuccesses,
    required this.evaluationWindow,
    required this.mastered,
  });

  final int validExecutionsInWindow;
  final int successesInWindow;
  final int minimumValidExecutions;
  final int requiredSuccesses;
  final int evaluationWindow;
  final bool mastered;
}

/// Evaluates progression from complete, valid V2 executions only. A current
/// in-progress evaluation can be supplied for the preview shown before the
/// completion transaction. Legacy V1 activities are never eligible.
class DrillMasteryEvaluator {
  const DrillMasteryEvaluator._();

  static DrillMasteryProgress evaluate({
    required DrillMasteryRuleV2 rule,
    required String drillVersionedId,
    required List<TrainingActivityRecord> activities,
    required Map<String, Object?>? cohort,
    DrillMeasurementEvaluation? currentEvaluation,
  }) {
    final historical =
        <({Map<String, Object?> summary, DateTime completedAt})>[];
    for (final activity in activities) {
      if (activity.kind != StoredTrainingActivityKind.guidedDrillV2.name ||
          activity.status != StoredTrainingActivityStatus.completed.name) {
        continue;
      }
      try {
        final summary = _jsonObject(activity.summaryJson);
        if (summary['drillVersionedId'] != drillVersionedId ||
            summary['validExecution'] != true ||
            summary['metricSnapshot'] is! Map) {
          continue;
        }
        final snapshot = (summary['metricSnapshot'] as Map)
            .cast<String, Object?>();
        if (cohort == null ||
            snapshot['cohort'] is! Map ||
            !_mapsEqual(
              cohort,
              (snapshot['cohort'] as Map).cast<String, Object?>(),
            )) {
          continue;
        }
        historical.add((
          summary: summary,
          completedAt: activity.completedAtUtc ?? activity.updatedAtUtc,
        ));
      } on Object {
        continue;
      }
    }
    historical.sort(
      (left, right) => left.completedAt.compareTo(right.completedAt),
    );
    final executions = <Map<String, Object?>>[
      ...historical.map((item) => item.summary),
      if (currentEvaluation?.valid == true)
        {
          'validExecution': true,
          'primaryMeasurementSuccess': currentEvaluation!.success,
          'metricSnapshot': currentEvaluation.toSnapshotJson(),
        },
    ];
    final baselineRule = rule.usesPersonalBaseline;
    final evaluationWindow = baselineRule ? 3 : rule.evaluationWindow;
    final minimumValidExecutions = baselineRule
        ? 3
        : rule.minimumValidExecutions;
    final requiredSuccesses = baselineRule ? 2 : rule.requiredSuccesses;
    final window = executions.reversed
        .take(evaluationWindow)
        .toList(growable: false);
    final successes = window
        .where((summary) => summary['primaryMeasurementSuccess'] == true)
        .length;
    return DrillMasteryProgress(
      validExecutionsInWindow: window.length,
      successesInWindow: successes,
      minimumValidExecutions: minimumValidExecutions,
      requiredSuccesses: requiredSuccesses,
      evaluationWindow: evaluationWindow,
      mastered:
          window.length >= minimumValidExecutions &&
          successes >= requiredSuccesses,
    );
  }
}

class _HistoricalMetricExecution {
  const _HistoricalMetricExecution({
    required this.value,
    required this.sessionIds,
    required this.completedAtUtc,
  });

  final double value;
  final Set<String> sessionIds;
  final DateTime completedAtUtc;
}

class _RunnerHeader extends StatelessWidget {
  const _RunnerHeader({
    required this.drill,
    required this.completedPhases,
    required this.linkedSeriesCount,
  });

  final DrillDefinitionV2 drill;
  final int completedPhases;
  final int linkedSeriesCount;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(drill.shortPurpose),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: drill.phases.isEmpty
                ? 0
                : completedPhases / drill.phases.length,
          ),
          const SizedBox(height: 8),
          Text(
            '$completedPhases/${drill.phases.length} fasen · '
            '$linkedSeriesCount echte ${linkedSeriesCount == 1 ? 'reeks' : 'reeksen'} gekoppeld',
          ),
        ],
      ),
    ),
  );
}

class _SetupGateCard extends StatelessWidget {
  const _SetupGateCard({
    required this.drill,
    required this.setupConfirmed,
    required this.safetyConfirmed,
    required this.enabled,
    required this.onSetupChanged,
    required this.onSafetyChanged,
  });

  final DrillDefinitionV2 drill;
  final bool setupConfirmed;
  final bool safetyConfirmed;
  final bool enabled;
  final ValueChanged<bool> onSetupChanged;
  final ValueChanged<bool> onSafetyChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Voorbereiding', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${drill.setup.target} · ${drill.setup.distance}'),
          const SizedBox(height: 6),
          Text(drill.setup.equipment.join(' · ')),
          const SizedBox(height: 6),
          Text(drill.setup.dataBasis),
          CheckboxListTile(
            key: const ValueKey('drill-setup-confirmed'),
            contentPadding: EdgeInsets.zero,
            value: setupConfirmed,
            onChanged: enabled
                ? (value) => onSetupChanged(value ?? false)
                : null,
            title: const Text('Opstelling gecontroleerd'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            key: const ValueKey('drill-safety-confirmed'),
            contentPadding: EdgeInsets.zero,
            value: safetyConfirmed,
            onChanged: enabled
                ? (value) => onSafetyChanged(value ?? false)
                : null,
            title: Text(drill.setup.safetyGate),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    ),
  );
}

class _AnalysisEvidenceCard extends StatelessWidget {
  const _AnalysisEvidenceCard({
    required this.linkedSeries,
    required this.enabled,
    required this.onLink,
    required this.onUnlink,
  });

  final List<AnalyzedSeriesView> linkedSeries;
  final bool enabled;
  final VoidCallback onLink;
  final ValueChanged<String> onUnlink;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('analysis-only-evidence-card'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vergelijkbare reeksen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Koppel bevestigde historische reeksen met dezelfde kaart, '
            'afstand en uitrusting. De app wijzigt hun score niet.',
          ),
          const SizedBox(height: 10),
          for (final item in linkedSeries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Reeks ${item.source.series.sequenceNumber} · '
                '${item.source.series.totalScore}/'
                '${item.source.series.maximumPossibleScore}',
              ),
              subtitle: Text(
                '${item.analysis.positionedShotCount} positionele schoten',
              ),
              trailing: IconButton(
                tooltip: 'Reeks loskoppelen',
                onPressed: enabled
                    ? () => onUnlink(item.source.series.id)
                    : null,
                icon: const Icon(Icons.link_off),
              ),
            ),
          OutlinedButton.icon(
            key: const ValueKey('link-analysis-evidence'),
            onPressed: enabled ? onLink : null,
            icon: const Icon(Icons.add_link),
            label: const Text('Historische reeks koppelen'),
          ),
        ],
      ),
    ),
  );
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.completed,
    required this.current,
    required this.linkedSeries,
    required this.timerCompleted,
    required this.reflection,
    required this.enabled,
    required this.onAcknowledge,
    required this.onStartSeries,
    required this.onLinkExisting,
    required this.onStartTimer,
    required this.onReflect,
    required this.onUnlinkSeries,
  });

  final DrillPhaseV2 phase;
  final bool completed;
  final bool current;
  final List<AnalyzedSeriesView> linkedSeries;
  final bool timerCompleted;
  final String? reflection;
  final bool enabled;
  final VoidCallback onAcknowledge;
  final VoidCallback onStartSeries;
  final VoidCallback onLinkExisting;
  final VoidCallback onStartTimer;
  final VoidCallback onReflect;
  final ValueChanged<String> onUnlinkSeries;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('drill-phase-${phase.id}'),
    color: current ? Theme.of(context).colorScheme.secondaryContainer : null,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  phase.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < phase.instructions.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text('${index + 1}. ${phase.instructions[index]}'),
            ),
          if (phase.seriesCount != null)
            Text(
              '${linkedSeries.length}/${phase.seriesCount} bevestigde reeksen',
            ),
          for (final item in linkedSeries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Reeks ${item.source.series.sequenceNumber} · '
                '${item.source.series.totalScore}/${item.source.series.maximumPossibleScore}',
              ),
              subtitle: Text(
                '${item.analysis.metrics.positionedShotCount} positionele schoten',
              ),
              trailing: IconButton(
                tooltip: 'Reeks loskoppelen',
                onPressed: enabled
                    ? () => onUnlinkSeries(item.source.series.id)
                    : null,
                icon: const Icon(Icons.link_off),
              ),
            ),
          if (timerCompleted) const Text('Timerrun bewaard'),
          if (reflection != null) Text('Reflectie: $reflection'),
          if (current) ...[
            const SizedBox(height: 12),
            switch (phase.completionKind) {
              DrillPhaseCompletionKind.acknowledged => FilledButton.icon(
                key: ValueKey('acknowledge-phase-${phase.id}'),
                onPressed: enabled ? onAcknowledge : null,
                icon: const Icon(Icons.check),
                label: const Text('Stap uitgevoerd'),
              ),
              DrillPhaseCompletionKind.confirmedSeries => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: ValueKey('start-series-phase-${phase.id}'),
                    onPressed: enabled ? onStartSeries : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Nieuwe reeks scoren'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: ValueKey('link-series-phase-${phase.id}'),
                    onPressed: enabled ? onLinkExisting : null,
                    icon: const Icon(Icons.link),
                    label: const Text('Bevestigde reeks koppelen'),
                  ),
                ],
              ),
              DrillPhaseCompletionKind.timerActivity => FilledButton.icon(
                key: ValueKey('start-timer-phase-${phase.id}'),
                onPressed: enabled ? onStartTimer : null,
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Timer starten'),
              ),
              DrillPhaseCompletionKind.reflection => FilledButton.icon(
                key: ValueKey('reflect-phase-${phase.id}'),
                onPressed: enabled ? onReflect : null,
                icon: const Icon(Icons.edit_note),
                label: const Text('Reflectie noteren'),
              ),
            },
          ],
        ],
      ),
    ),
  );
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.evaluation});

  final DrillMeasurementEvaluation? evaluation;

  @override
  Widget build(BuildContext context) {
    final value = evaluation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Meetresultaat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (value == null)
              const Text('Analysegegevens worden geladen.')
            else ...[
              Text(
                value.value == null
                    ? 'Nog geen meetbare waarde'
                    : '${_metricLabel(value.metric)}: ${_formatMetric(value.metric, value.value!)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text('Databasis ${value.sampleSize}/${value.minimumSampleSize}'),
              if (value.baselineValue != null)
                Text(
                  'Persoonlijke referentie: '
                  '${_formatMetric(value.metric, value.baselineValue!)}',
                ),
              const SizedBox(height: 8),
              Text(value.explanation),
            ],
          ],
        ),
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.rule,
    required this.activities,
    required this.currentDrillVersionedId,
    required this.currentEvaluation,
  });

  final DrillMasteryRuleV2 rule;
  final List<TrainingActivityRecord> activities;
  final String currentDrillVersionedId;
  final DrillMeasurementEvaluation? currentEvaluation;

  @override
  Widget build(BuildContext context) {
    final progress = DrillMasteryEvaluator.evaluate(
      rule: rule,
      drillVersionedId: currentDrillVersionedId,
      activities: activities,
      cohort: currentEvaluation?.cohort,
      currentEvaluation: currentEvaluation,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(progress.mastered ? Icons.verified : Icons.trending_up),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progress.mastered
                        ? 'Beheersingsniveau gehaald'
                        : 'Progressie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rule.explanation),
            const SizedBox(height: 8),
            Text(
              '${progress.validExecutionsInWindow}/'
              '${progress.minimumValidExecutions} geldige uitvoeringen · '
              '${progress.successesInWindow}/'
              '${progress.requiredSuccesses} successen in de laatste '
              '${progress.evaluationWindow}',
            ),
          ],
        ),
      ),
    );
  }
}

List<AnalyzedSeriesView> _linkedAnalyzedSeries(
  TrainingActivityDetail detail,
  List<AnalyzedSeriesView> all,
) {
  final byId = {for (final item in all) item.source.series.id: item};
  return detail.links
      .map((link) => byId[link.seriesId])
      .whereType<AnalyzedSeriesView>()
      .toList(growable: false);
}

Map<String, Object?> _jsonObject(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) throw const FormatException('JSON-object verwacht.');
  return decoded.cast<String, Object?>();
}

List<String> _stringList(Object? value) => switch (value) {
  final List<dynamic> items => items.whereType<String>().toList(
    growable: false,
  ),
  _ => const [],
};

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

String _metricLabel(TrainingMetricKind metric) => switch (metric) {
  TrainingMetricKind.completion => 'Voltooide reeksen',
  TrainingMetricKind.scorePercentage => 'Gemiddelde score',
  TrainingMetricKind.meanRadiusMm => 'Mean radius',
  TrainingMetricKind.extremeSpreadMm => 'Extreme spreiding',
  TrainingMetricKind.consistency => 'Scorevariatie',
  TrainingMetricKind.absoluteBiasMm => 'Afwijking groepscentrum',
  TrainingMetricKind.selfEvaluation => 'Reeksen met reflectie',
  TrainingMetricKind.shotCallAccuracy => 'Voorspelnauwkeurigheid',
  TrainingMetricKind.filledBullCount => 'Ingevulde roosjes',
};

String _formatMetric(TrainingMetricKind metric, double value) =>
    switch (metric) {
      TrainingMetricKind.scorePercentage ||
      TrainingMetricKind.selfEvaluation => '${value.toStringAsFixed(1)}%',
      TrainingMetricKind.consistency =>
        '${value.toStringAsFixed(1)} procentpunt',
      TrainingMetricKind.meanRadiusMm ||
      TrainingMetricKind.extremeSpreadMm ||
      TrainingMetricKind.absoluteBiasMm => '${value.toStringAsFixed(1)} mm',
      _ => value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
    };

extension<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}

bool _mapsEqual(Map<String, Object?> left, Map<String, Object?> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
