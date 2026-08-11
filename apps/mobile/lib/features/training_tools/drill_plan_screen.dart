import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_training/training.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'guided_drill_runner_screen.dart';
import 'technique_screens.dart';
import 'training_plan_models.dart';

export 'training_plan_models.dart';

/// Deterministic time budgeting for the supported 0.8 disciplines.
class DeterministicDrillPlanner {
  const DeterministicDrillPlanner();

  GeneratedDrillPlan generate({
    required int durationMinutes,
    required TrainingDiscipline discipline,
    required TrainingSkillLevel skillLevel,
    required TrainingPlanFocus focus,
    required int ammunitionBudget,
    String? firearmId,
    String? ammoLotId,
    required List<DrillDefinitionV2> drills,
    required List<LearningPathV2> learningPaths,
  }) {
    if (!const {30, 45, 60}.contains(durationMinutes)) {
      throw ArgumentError.value(durationMinutes, 'durationMinutes');
    }
    if (discipline != TrainingDiscipline.precisionPistol &&
        discipline != TrainingDiscipline.br50) {
      throw ArgumentError.value(discipline, 'discipline');
    }
    if (ammunitionBudget < 0) {
      throw ArgumentError.value(ammunitionBudget, 'ammunitionBudget');
    }
    const preparationMinutes = 4;
    const finalReflectionMinutes = 2;
    const restReviewMinutesPerDrill = 2;
    var remainingMinutes =
        durationMinutes - preparationMinutes - finalReflectionMinutes;
    var remainingAmmunition = ammunitionBudget;
    final maximumSlots = switch (durationMinutes) {
      30 => 1,
      45 => 2,
      60 => 2,
      _ => throw StateError('Onbereikbare planduur.'),
    };
    final candidates = drills
        .where(
          (drill) =>
              (drill.discipline == discipline ||
                  drill.discipline == TrainingDiscipline.universal) &&
              drill.skillLevel == skillLevel,
        )
        .toList(growable: true);
    if (candidates.isEmpty) {
      throw StateError('Geen passende drills in deze catalogus.');
    }

    final pathOrder = <String, int>{};
    var position = 0;
    for (final path in learningPaths.where(
      (path) => path.discipline == discipline,
    )) {
      for (final entry in path.entries.where(
        (entry) => entry.kind == LearningPathEntryKind.drill,
      )) {
        pathOrder.putIfAbsent(entry.versionedContentId, () => position++);
      }
    }
    candidates.sort((left, right) {
      final leftFocus = _focusRank(left, focus);
      final rightFocus = _focusRank(right, focus);
      if (leftFocus != rightFocus) return leftFocus.compareTo(rightFocus);
      final leftPath = pathOrder[left.versionedId] ?? 1 << 20;
      final rightPath = pathOrder[right.versionedId] ?? 1 << 20;
      if (leftPath != rightPath) return leftPath.compareTo(rightPath);
      final exactDiscipline =
          (left.discipline == discipline ? 0 : 1) -
          (right.discipline == discipline ? 0 : 1);
      if (exactDiscipline != 0) return exactDiscipline;
      return left.versionedId.compareTo(right.versionedId);
    });

    final slots = <PlannedDrillSlot>[];
    for (final drill in candidates) {
      if (slots.length >= maximumSlots || remainingMinutes <= 0) break;
      final requiredMinutes =
          drill.estimatedDurationMinutes + restReviewMinutesPerDrill;
      if (requiredMinutes > remainingMinutes ||
          drill.ammunitionBudget > remainingAmmunition) {
        continue;
      }
      slots.add(
        PlannedDrillSlot(
          drill: drill,
          allocatedMinutes: drill.estimatedDurationMinutes,
          index: slots.length,
        ),
      );
      remainingMinutes -= requiredMinutes;
      remainingAmmunition -= drill.ammunitionBudget;
    }
    if (slots.isEmpty) {
      throw StateError(
        'Geen volledige drill past binnen tijd en munitiebudget.',
      );
    }
    final techniqueLesson = _techniqueLessonFor(slots.first.drill);
    final steps = <GeneratedTrainingPlanStep>[
      const GeneratedTrainingPlanStep(
        id: 'safety-setup',
        kind: TrainingPlanStepKind.safetyAndSetup,
        title: 'Veiligheid en opstelling',
        allocatedMinutes: 2,
      ),
      GeneratedTrainingPlanStep(
        id: 'technique-review',
        kind: TrainingPlanStepKind.techniqueReview,
        title: techniqueLesson == null
            ? 'Korte techniekherhaling'
            : 'Techniek: ${techniqueLesson.title}',
        allocatedMinutes: 2,
        lessonVersionedId: techniqueLesson?.versionedId,
        lessonTitle: techniqueLesson?.title,
      ),
      for (final slot in slots) ...[
        GeneratedTrainingPlanStep(
          id: 'drill-${slot.index}',
          kind: TrainingPlanStepKind.drill,
          title: slot.drill.title,
          allocatedMinutes: slot.drill.estimatedDurationMinutes,
          slotIndex: slot.index,
        ),
        GeneratedTrainingPlanStep(
          id: 'review-${slot.index}',
          kind: TrainingPlanStepKind.restAndReview,
          title: 'Rust en korte resultaatcontrole',
          allocatedMinutes: restReviewMinutesPerDrill,
          slotIndex: slot.index,
        ),
      ],
      const GeneratedTrainingPlanStep(
        id: 'final-reflection',
        kind: TrainingPlanStepKind.finalReflection,
        title: 'Eindreflectie',
        allocatedMinutes: finalReflectionMinutes,
      ),
    ];
    final id = [
      'plan-v1',
      durationMinutes,
      discipline.name,
      skillLevel.name,
      focus.name,
      ammunitionBudget,
      firearmId ?? '-',
      ammoLotId ?? '-',
      ...slots.map((slot) => slot.drill.versionedId),
    ].join(':');
    return GeneratedDrillPlan(
      id: id,
      title: '${_disciplineLabel(discipline)} · $durationMinutes min',
      durationMinutes: durationMinutes,
      preparationMinutes: preparationMinutes,
      reviewMinutes:
          finalReflectionMinutes + slots.length * restReviewMinutesPerDrill,
      discipline: discipline,
      skillLevel: skillLevel,
      focus: focus,
      ammunitionBudget: ammunitionBudget,
      firearmId: firearmId,
      ammoLotId: ammoLotId,
      slots: List.unmodifiable(slots),
      steps: List.unmodifiable(steps),
    );
  }

  TechniqueLessonV2? _techniqueLessonFor(DrillDefinitionV2 drill) {
    for (final reference in drill.techniqueReferences) {
      final lesson = BuiltInTrainingContent.catalog.lessonByVersionedId(
        reference,
      );
      if (lesson != null) return lesson;
    }
    return null;
  }

  int _focusRank(DrillDefinitionV2 drill, TrainingPlanFocus focus) {
    final primary = drill.measurements.firstWhere(
      (item) => item.role == TrainingMeasurementRole.primary,
    );
    final matches = switch (focus) {
      TrainingPlanFocus.fundamentals =>
        drill.skillLevel == TrainingSkillLevel.foundation,
      TrainingPlanFocus.groupSize =>
        primary.metric == TrainingMetricKind.meanRadiusMm ||
            primary.metric == TrainingMetricKind.extremeSpreadMm ||
            primary.metric == TrainingMetricKind.absoluteBiasMm,
      TrainingPlanFocus.consistency =>
        primary.metric == TrainingMetricKind.consistency,
      TrainingPlanFocus.matchProcess =>
        drill.mode == TrainingMode.matchSimulation,
    };
    return matches ? 0 : 1;
  }
}

class DeterministicDrillPlannerScreen extends ConsumerStatefulWidget {
  const DeterministicDrillPlannerScreen({
    required this.drills,
    required this.learningPaths,
    this.activityId,
    super.key,
  });

  const DeterministicDrillPlannerScreen.resume({
    required String activityId,
    required List<DrillDefinitionV2> drills,
    required List<LearningPathV2> learningPaths,
    Key? key,
  }) : this(
         drills: drills,
         learningPaths: learningPaths,
         activityId: activityId,
         key: key,
       );

  final List<DrillDefinitionV2> drills;
  final List<LearningPathV2> learningPaths;
  final String? activityId;

  @override
  ConsumerState<DeterministicDrillPlannerScreen> createState() =>
      _DeterministicDrillPlannerScreenState();
}

class _DeterministicDrillPlannerScreenState
    extends ConsumerState<DeterministicDrillPlannerScreen> {
  int _durationMinutes = 30;
  late TrainingDiscipline _discipline;
  TrainingSkillLevel _skillLevel = TrainingSkillLevel.foundation;
  TrainingPlanFocus _focus = TrainingPlanFocus.fundamentals;
  int _ammunitionBudget = 25;
  String? _firearmId;
  String? _ammoLotId;
  String? _activityId;
  GeneratedDrillPlan? _savedPlan;
  Set<int> _completedSlots = {};
  Set<String> _completedStepIds = {};
  Map<int, String> _guidedDrillActivityIds = {};
  int _currentStepIndex = 0;
  String? _finalReflection;
  bool _loading = false;
  bool _busy = false;
  bool _allowPop = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _discipline = _availableDisciplines.first;
    if (widget.activityId != null) {
      _loading = true;
      unawaited(_restore(widget.activityId!));
    }
  }

  List<TrainingDiscipline> get _availableDisciplines => [
    if (widget.drills.any(
      (drill) => drill.discipline == TrainingDiscipline.precisionPistol,
    ))
      TrainingDiscipline.precisionPistol,
    if (widget.drills.any(
      (drill) => drill.discipline == TrainingDiscipline.br50,
    ))
      TrainingDiscipline.br50,
  ];

  GeneratedDrillPlan? get _preview {
    if (_savedPlan case final saved?) return saved;
    try {
      return const DeterministicDrillPlanner().generate(
        durationMinutes: _durationMinutes,
        discipline: _discipline,
        skillLevel: _skillLevel,
        focus: _focus,
        ammunitionBudget: _ammunitionBudget,
        firearmId: _firearmId,
        ammoLotId: _ammoLotId,
        drills: widget.drills,
        learningPaths: widget.learningPaths,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return CompactPageScaffold(
        title: 'Training hervatten',
        body: Center(child: Text('Plan laden mislukt: $_loadError')),
      );
    }
    final plan = _preview;
    final firearms = ref.watch(firearmsProvider).valueOrNull ?? const [];
    final ammoLots = ref.watch(ammoLotsProvider).valueOrNull ?? const [];
    final started = _activityId != null;
    final allComplete =
        plan != null &&
        plan.steps.every((step) => _completedStepIds.contains(step.id));
    final currentStep = plan == null || allComplete
        ? null
        : plan.steps[_firstIncompleteStepIndex(plan)];
    return PopScope<Object?>(
      canPop: _allowPop || !started || allComplete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_interruptAndClose());
      },
      child: CompactPageScaffold(
        title: started ? 'Trainingsplan' : 'Training plannen',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
          children: [
            if (!started) ...[
              const Text(
                'Kies je tijd. Dezelfde keuzes geven steeds dezelfde, '
                'controleerbare opbouw.',
              ),
              const SizedBox(height: 20),
              SegmentedButton<int>(
                key: const ValueKey('drill-plan-duration'),
                segments: const [
                  ButtonSegment(value: 30, label: Text('30 min')),
                  ButtonSegment(value: 45, label: Text('45 min')),
                  ButtonSegment(value: 60, label: Text('60 min')),
                ],
                selected: {_durationMinutes},
                onSelectionChanged: (value) =>
                    setState(() => _durationMinutes = value.single),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrainingDiscipline>(
                key: const ValueKey('drill-plan-discipline'),
                initialValue: _discipline,
                decoration: const InputDecoration(labelText: 'Discipline'),
                items: [
                  for (final value in _availableDisciplines)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_disciplineLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _discipline = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrainingSkillLevel>(
                key: const ValueKey('drill-plan-level'),
                initialValue: _skillLevel,
                decoration: const InputDecoration(labelText: 'Niveau'),
                items: [
                  for (final value in TrainingSkillLevel.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_skillLevelLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _skillLevel = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrainingPlanFocus>(
                key: const ValueKey('drill-plan-focus'),
                initialValue: _focus,
                decoration: const InputDecoration(labelText: 'Focus'),
                items: [
                  for (final value in TrainingPlanFocus.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_focusLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _focus = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const ValueKey('drill-plan-ammunition-budget'),
                initialValue: _ammunitionBudget,
                decoration: const InputDecoration(
                  labelText: 'Beschikbare patronen',
                ),
                items: [
                  for (final value in const [0, 5, 10, 15, 20, 25, 30, 50])
                    DropdownMenuItem(value: value, child: Text('$value')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _ammunitionBudget = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('drill-plan-firearm'),
                initialValue: _firearmId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Wapen (optioneel)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Geen voorkeur'),
                  ),
                  for (final firearm in firearms)
                    DropdownMenuItem(
                      value: firearm.id,
                      child: Text(firearm.name),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _firearmId = value == null || value.isEmpty
                      ? null
                      : value,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('drill-plan-ammo-lot'),
                initialValue: _ammoLotId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Munitieprofiel (optioneel)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Geen voorkeur'),
                  ),
                  for (final ammo in ammoLots)
                    DropdownMenuItem(
                      value: ammo.id,
                      child: Text(ammo.displayName),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _ammoLotId = value == null || value.isEmpty
                      ? null
                      : value,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (plan == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Voor deze combinatie is nog geen drill.'),
                ),
              )
            else ...[
              Text(plan.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${plan.preparationMinutes} min voorbereiding · '
                '${plan.plannedDrillMinutes} min drills · '
                '${plan.reviewMinutes} min evaluatie',
              ),
              Text(
                '${plan.usedAmmunition}/${plan.ammunitionBudget} patronen · '
                '${plan.plannedMinutes}/${plan.durationMinutes} minuten gepland',
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: plan.steps.isEmpty
                    ? 0
                    : _completedStepIds.length / plan.steps.length,
              ),
              const SizedBox(height: 8),
              Text(
                '${_completedStepIds.length}/${plan.steps.length} stappen '
                'klaar · ${_completedSlots.length}/${plan.slots.length} '
                'drills',
              ),
              const SizedBox(height: 12),
              for (
                var stepIndex = 0;
                stepIndex < plan.steps.length;
                stepIndex++
              )
                Card(
                  key: ValueKey('drill-plan-step-$stepIndex'),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(_stepIcon(plan.steps[stepIndex].kind)),
                    ),
                    title: Text(plan.steps[stepIndex].title),
                    subtitle: Text(_stepSubtitle(plan, plan.steps[stepIndex])),
                    isThreeLine: plan.steps[stepIndex].slotIndex != null,
                    selected: stepIndex == _currentStepIndex,
                    trailing:
                        _completedStepIds.contains(plan.steps[stepIndex].id)
                        ? const Icon(Icons.check_circle)
                        : stepIndex == _firstIncompleteStepIndex(plan)
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: _busy || stepIndex != _firstIncompleteStepIndex(plan)
                        ? null
                        : () => _runPlanStep(plan, stepIndex),
                  ),
                ),
              if (allComplete)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Plan afgerond. Alle gekoppelde reeksen blijven '
                      'beschikbaar in je sessie en analyse.',
                    ),
                  ),
                ),
            ],
          ],
        ),
        bottomNavigationBar: plan == null || allComplete
            ? null
            : AppActionDock(
                actions: [
                  FilledButton.icon(
                    key: const ValueKey('start-generated-plan'),
                    onPressed: _busy || currentStep == null
                        ? null
                        : () => _runPlanStep(
                            plan,
                            _firstIncompleteStepIndex(plan),
                          ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      !started
                          ? 'Plan starten'
                          : currentStep?.kind == TrainingPlanStepKind.drill
                          ? 'Drill starten'
                          : 'Stap afronden',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _restore(String activityId) async {
    try {
      final repository = ref.read(repositoryProvider);
      final detail = await repository.getTrainingActivity(activityId);
      if (detail == null ||
          detail.activity.kind !=
              StoredTrainingActivityKind.trainingPlan.name) {
        throw StateError('Het trainingsplan bestaat niet meer.');
      }
      final configuration = _jsonObject(detail.activity.configurationJson);
      final rawPlan = configuration['plan'];
      if (rawPlan is! Map) throw StateError('Plansnapshot ontbreekt.');
      _savedPlan = GeneratedDrillPlan.fromJson(rawPlan.cast<String, Object?>());
      _durationMinutes = _savedPlan!.durationMinutes;
      _discipline = _savedPlan!.discipline;
      _skillLevel = _savedPlan!.skillLevel;
      _focus = _savedPlan!.focus;
      _ammunitionBudget = _savedPlan!.ammunitionBudget;
      _firearmId = _savedPlan!.firearmId;
      _ammoLotId = _savedPlan!.ammoLotId;
      _restoreSummary(_jsonObject(detail.activity.summaryJson));
      _activityId = activityId;
      if (detail.activity.status ==
          StoredTrainingActivityStatus.interrupted.name) {
        await repository.resumeTrainingPlan(activityId);
      }
    } on Object catch (error) {
      _loadError = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _restoreSummary(Map<String, Object?> summary) {
    _currentStepIndex = summary['currentStepIndex'] as int? ?? 0;
    _completedSlots = (summary['completedSlotIndexes'] as List? ?? const [])
        .whereType<int>()
        .toSet();
    _completedStepIds = (summary['completedStepIds'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final plan = _savedPlan;
    if (plan != null) {
      for (final step in plan.steps) {
        if (step.kind == TrainingPlanStepKind.drill &&
            step.slotIndex != null &&
            _completedSlots.contains(step.slotIndex)) {
          _completedStepIds.add(step.id);
        }
      }
    }
    _finalReflection = summary['finalReflection'] as String?;
    final rawIds = summary['guidedDrillActivityIds'];
    _guidedDrillActivityIds = rawIds is Map
        ? {
            for (final entry in rawIds.entries)
              if (int.tryParse('${entry.key}') case final index?)
                if (entry.value is String) index: entry.value! as String,
          }
        : {};
  }

  Future<String> _ensurePlanActivity(GeneratedDrillPlan plan) async {
    if (_activityId case final id?) return id;
    final now = DateTime.now();
    final id = await ref
        .read(repositoryProvider)
        .createTrainingPlanActivity(
          configuration: {'planId': plan.id, 'plan': plan.toJson()},
          summary: const {
            'completedSlotIndexes': <int>[],
            'completedStepIds': <String>[],
            'guidedDrillActivityIds': <String, String>{},
            'currentStepIndex': 0,
          },
          startedAtUtc: now.toUtc(),
          localUtcOffsetMinutes: now.timeZoneOffset.inMinutes,
        );
    if (mounted) {
      setState(() {
        _activityId = id;
        _savedPlan = plan;
      });
    }
    return id;
  }

  Future<void> _startSlot(
    GeneratedDrillPlan plan,
    PlannedDrillSlot slot,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final planActivityId = await _ensurePlanActivity(plan);
      final drillStepIndex = plan.steps.indexWhere(
        (step) =>
            step.kind == TrainingPlanStepKind.drill &&
            step.slotIndex == slot.index,
      );
      if (drillStepIndex >= 0) {
        _currentStepIndex = drillStepIndex;
        await ref
            .read(repositoryProvider)
            .updateTrainingPlanProgress(
              activityId: planActivityId,
              summary: _planSummary(),
            );
      }
      if (!mounted) return;
      final now = DateTime.now();
      final planContext = TrainingPlanContext(
        planActivityId: planActivityId,
        planId: plan.id,
        durationMinutes: plan.durationMinutes,
        slotIndex: slot.index,
        slotCount: plan.slots.length,
        discipline: plan.discipline,
        skillLevel: plan.skillLevel,
        firearmId: plan.firearmId,
        ammoLotId: plan.ammoLotId,
      );
      final guidedDrillId = await ref
          .read(repositoryProvider)
          .findOrCreateGuidedDrillSlot(
            planActivityId: planActivityId,
            slotIndex: slot.index,
            drillVersionedId: slot.drill.versionedId,
            drillSnapshot: slot.drill.toJson(),
            trainingPlanContext: planContext.toJson(),
            startedAtUtc: now.toUtc(),
            localUtcOffsetMinutes: now.timeZoneOffset.inMinutes,
          );
      _guidedDrillActivityIds[slot.index] = guidedDrillId;
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => GuidedDrillRunnerScreen(
            drill: slot.drill,
            activityId: guidedDrillId,
            planContext: planContext,
          ),
        ),
      );
      final detail = await ref
          .read(repositoryProvider)
          .getTrainingActivity(planActivityId);
      if (detail != null) {
        _restoreSummary(_jsonObject(detail.activity.summaryJson));
        if (detail.activity.status !=
            StoredTrainingActivityStatus.completed.name) {
          _currentStepIndex = _firstIncompleteStepIndex(plan);
          await ref
              .read(repositoryProvider)
              .updateTrainingPlanProgress(
                activityId: planActivityId,
                summary: _planSummary(),
              );
        }
      }
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, 'Plan starten mislukt: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runPlanStep(GeneratedDrillPlan plan, int stepIndex) async {
    if (_busy || stepIndex < 0 || stepIndex >= plan.steps.length) return;
    final step = plan.steps[stepIndex];
    if (step.kind == TrainingPlanStepKind.drill) {
      final slotIndex = step.slotIndex;
      if (slotIndex == null || slotIndex >= plan.slots.length) {
        AppMessenger.error(context, 'De opgeslagen drillstap is ongeldig.');
        return;
      }
      await _startSlot(plan, plan.slots[slotIndex]);
      return;
    }
    setState(() => _busy = true);
    try {
      final activityId = await _ensurePlanActivity(plan);
      String? reflection = _finalReflection;
      if (step.kind == TrainingPlanStepKind.techniqueReview) {
        final reviewed = await _reviewTechnique(step);
        if (!reviewed || !mounted) return;
      }
      if (step.kind == TrainingPlanStepKind.finalReflection) {
        reflection = await _askFinalReflection();
        if (reflection == null || !mounted) return;
      }
      _completedStepIds.add(step.id);
      _finalReflection = reflection;
      _currentStepIndex = _firstIncompleteStepIndex(plan);
      final allDone = plan.steps.every(
        (candidate) => _completedStepIds.contains(candidate.id),
      );
      final repository = ref.read(repositoryProvider);
      if (allDone) {
        await repository.completeTrainingPlan(
          activityId: activityId,
          summary: _planSummary(),
          completedAtUtc: DateTime.now().toUtc(),
        );
      } else {
        await repository.updateTrainingPlanProgress(
          activityId: activityId,
          summary: _planSummary(),
        );
      }
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, 'Stap afronden mislukt: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _reviewTechnique(GeneratedTrainingPlanStep step) async {
    final lessonId = step.lessonVersionedId;
    final lesson = lessonId == null
        ? null
        : BuiltInTrainingContent.catalog.lessonByVersionedId(lessonId);
    if (lesson == null) {
      AppMessenger.warning(
        context,
        'De gekoppelde techniekles is niet beschikbaar. Dit plan blijft '
        'alleen-lezen tot de inhoud weer beschikbaar is.',
      );
      return false;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TechniqueLessonScreen(lesson: lesson)),
    );
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Techniek doorgenomen?'),
            content: Text(
              'Markeer “${lesson.title}” pas als afgerond nadat je de '
              'belangrijkste aandachtspunten hebt bekeken.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Nog niet'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Doorgenomen'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _askFinalReflection() async {
    final controller = TextEditingController(text: _finalReflection);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eindreflectie'),
          content: TextField(
            key: const ValueKey('training-plan-final-reflection'),
            controller: controller,
            minLines: 3,
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Wat neem je mee naar de volgende training?',
              alignLabelWithHint: true,
            ),
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
              child: const Text('Bewaren en afronden'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  int _firstIncompleteStepIndex(GeneratedDrillPlan plan) {
    final index = plan.steps.indexWhere(
      (step) => !_completedStepIds.contains(step.id),
    );
    return index < 0 ? plan.steps.length - 1 : index;
  }

  Future<void> _interruptAndClose() async {
    if (_busy || _activityId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan onderbreken?'),
        content: const Text(
          'Je afgeronde drills en gekoppelde reeksen blijven bewaard.',
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
            summary: {..._planSummary()},
          );
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.pop(context);
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        AppMessenger.error(context, 'Plan onderbreken mislukt.');
      }
    }
  }

  Map<String, Object?> _planSummary() => {
    'completedSlotIndexes': _completedSlots.toList()..sort(),
    'completedStepIds': _completedStepIds.toList()..sort(),
    'guidedDrillActivityIds': {
      for (final entry in _guidedDrillActivityIds.entries)
        '${entry.key}': entry.value,
    },
    'currentStepIndex': _currentStepIndex,
    'finalReflection': _finalReflection,
  };
}

Map<String, Object?> _jsonObject(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) throw const FormatException('JSON-object verwacht.');
  return decoded.cast<String, Object?>();
}

String _disciplineLabel(TrainingDiscipline value) => switch (value) {
  TrainingDiscipline.universal => 'Algemeen',
  TrainingDiscipline.precisionPistol => 'Precisiepistool',
  TrainingDiscipline.br50 => 'BR50 / rimfire benchrest',
};

String _skillLevelLabel(TrainingSkillLevel value) => switch (value) {
  TrainingSkillLevel.foundation => 'Basis',
  TrainingSkillLevel.development => 'Gevorderd',
};

String _focusLabel(TrainingPlanFocus value) => switch (value) {
  TrainingPlanFocus.fundamentals => 'Basisproces',
  TrainingPlanFocus.groupSize => 'Groepsgrootte en centrum',
  TrainingPlanFocus.consistency => 'Herhaalbaarheid',
  TrainingPlanFocus.matchProcess => 'Wedstrijdproces',
};

IconData _stepIcon(TrainingPlanStepKind kind) => switch (kind) {
  TrainingPlanStepKind.safetyAndSetup => Icons.health_and_safety_outlined,
  TrainingPlanStepKind.techniqueReview => Icons.menu_book_outlined,
  TrainingPlanStepKind.drill => Icons.sports_score_outlined,
  TrainingPlanStepKind.restAndReview => Icons.self_improvement_outlined,
  TrainingPlanStepKind.finalReflection => Icons.edit_note_outlined,
};

String _stepSubtitle(GeneratedDrillPlan plan, GeneratedTrainingPlanStep step) {
  final slotIndex = step.slotIndex;
  if (slotIndex == null) {
    final lessonId = step.lessonVersionedId;
    return lessonId == null
        ? '${step.allocatedMinutes} min'
        : '${step.allocatedMinutes} min · $lessonId';
  }
  final drill = plan.slots[slotIndex].drill;
  return '${step.allocatedMinutes} min · '
      '${drill.ammunitionBudget} patronen\n${drill.shortPurpose}';
}
