import 'dart:convert';

import 'package:shooting_companion_training/training.dart';

/// Compatibility outcome for a persisted guided-training snapshot.
///
/// Future versions are deliberately preserved, but must remain read-only until
/// this app version understands their schema. Current versions are only
/// resumable after their complete runtime snapshot has been validated.
enum TrainingSnapshotCompatibility { resumable, futureReadOnly, invalid }

class TrainingSnapshotValidation {
  const TrainingSnapshotValidation._(this.compatibility, this.message);

  const TrainingSnapshotValidation.resumable()
    : this._(TrainingSnapshotCompatibility.resumable, null);

  const TrainingSnapshotValidation.futureReadOnly(String message)
    : this._(TrainingSnapshotCompatibility.futureReadOnly, message);

  const TrainingSnapshotValidation.invalid(String message)
    : this._(TrainingSnapshotCompatibility.invalid, message);

  final TrainingSnapshotCompatibility compatibility;
  final String? message;

  bool get canResume =>
      compatibility == TrainingSnapshotCompatibility.resumable;
  bool get isAcceptedForRestore =>
      compatibility != TrainingSnapshotCompatibility.invalid;
}

/// Validates the version-bound runtime snapshots stored in TrainingActivities.
///
/// It intentionally has no dependency on widgets or a repository so backup
/// restore and local resume classification use exactly the same rules.
class TrainingActivitySnapshotValidator {
  const TrainingActivitySnapshotValidator._();

  static const guidedDrillSchemaVersion = 2;
  static const trainingPlanSchemaVersion = 1;
  static const learningPathSchemaVersion = 2;
  static const plannerVersion = 1;

  static TrainingSnapshotValidation validateEncoded({
    required String kind,
    required int activitySchemaVersion,
    required String configurationJson,
    String? summaryJson,
    String? status,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(configurationJson);
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsconfiguratie bevat geen geldig JSON-object.',
      );
    }
    if (decoded is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsconfiguratie bevat geen geldig JSON-object.',
      );
    }
    final configuration = decoded.cast<String, Object?>();
    final configurationValidation = validate(
      kind: kind,
      activitySchemaVersion: activitySchemaVersion,
      configuration: configuration,
    );
    if (!configurationValidation.canResume) {
      return configurationValidation;
    }
    final structuredKind =
        kind == 'guidedDrillV2' ||
        kind == 'trainingPlan' ||
        kind == 'learningPathV2';
    if (summaryJson == null) {
      return structuredKind
          ? const TrainingSnapshotValidation.invalid(
              'Trainingssnapshot mist opgeslagen voortgang.',
            )
          : configurationValidation;
    }
    Object? decodedSummary;
    try {
      decodedSummary = jsonDecode(summaryJson);
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsvoortgang bevat geen geldig JSON-object.',
      );
    }
    if (decodedSummary is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsvoortgang bevat geen geldig JSON-object.',
      );
    }
    return validateSummary(
      kind: kind,
      activitySchemaVersion: activitySchemaVersion,
      configuration: configuration,
      summary: decodedSummary.cast<String, Object?>(),
      status: status,
    );
  }

  static TrainingSnapshotValidation validate({
    required String kind,
    required int activitySchemaVersion,
    required Map<String, Object?> configuration,
  }) {
    if (kind == 'guidedDrillV2') {
      return _validateGuidedDrill(activitySchemaVersion, configuration);
    }
    if (kind == 'trainingPlan') {
      return _validateTrainingPlan(activitySchemaVersion, configuration);
    }
    if (kind == 'learningPathV2') {
      return _validateLearningPath(activitySchemaVersion, configuration);
    }
    return const TrainingSnapshotValidation.resumable();
  }

  /// Validates persisted progress against its immutable content snapshot.
  ///
  /// Relation checks that require database rows (timer activities, linked
  /// series and plan-slot activities) deliberately remain repository/backup
  /// responsibilities. This method validates the complete JSON shape and the
  /// state machine encoded in it.
  static TrainingSnapshotValidation validateSummary({
    required String kind,
    required int activitySchemaVersion,
    required Map<String, Object?> configuration,
    required Map<String, Object?> summary,
    String? status,
  }) {
    if (status != null &&
        !const {'draft', 'interrupted', 'completed'}.contains(status)) {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsstatus is ongeldig.',
      );
    }
    final configurationValidation = validate(
      kind: kind,
      activitySchemaVersion: activitySchemaVersion,
      configuration: configuration,
    );
    if (!configurationValidation.canResume) return configurationValidation;
    if (kind == 'guidedDrillV2') {
      return _validateGuidedDrillSummary(configuration, summary, status);
    }
    if (kind == 'trainingPlan') {
      return _validateTrainingPlanSummary(configuration, summary, status);
    }
    if (kind == 'learningPathV2') {
      return _validateLearningPathSummary(configuration, summary, status);
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static TrainingSnapshotValidation validateTrainingPlanContext(
    Map<String, Object?> context,
  ) => _validateTrainingPlanContext(context);

  static TrainingSnapshotValidation validateGeneratedPlan(
    Map<String, Object?> plan,
  ) {
    final version = plan['plannerVersion'];
    if (version is! int || version < 1) {
      return const TrainingSnapshotValidation.invalid(
        'GeneratedDrillPlan bevat geen geldige plannerVersion.',
      );
    }
    if (version > plannerVersion) {
      return TrainingSnapshotValidation.futureReadOnly(
        'Planner $version is nieuwer dan ondersteund.',
      );
    }
    final planId = _nonEmptyString(plan['id']);
    if (planId == null) {
      return const TrainingSnapshotValidation.invalid(
        'GeneratedDrillPlan bevat geen geldig id.',
      );
    }
    return _validateCurrentGeneratedPlan(planId, plan);
  }

  static TrainingSnapshotValidation _validateGuidedDrill(
    int schemaVersion,
    Map<String, Object?> configuration,
  ) {
    if (schemaVersion > guidedDrillSchemaVersion) {
      return TrainingSnapshotValidation.futureReadOnly(
        'Drillschema $schemaVersion is nieuwer dan ondersteund.',
      );
    }
    if (schemaVersion != guidedDrillSchemaVersion) {
      return TrainingSnapshotValidation.invalid(
        'guidedDrillV2 vereist schema $guidedDrillSchemaVersion.',
      );
    }
    final versionedId = _nonEmptyString(configuration['drillVersionedId']);
    final rawDrill = configuration['drill'];
    if (versionedId == null || rawDrill is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Drillsnapshot of drillVersionedId ontbreekt.',
      );
    }
    DrillDefinitionV2 drill;
    try {
      drill = DrillDefinitionV2.fromJson(rawDrill.cast<String, Object?>());
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Drillsnapshot voldoet niet aan DrillDefinitionV2.',
      );
    }
    if (drill.versionedId != versionedId) {
      return const TrainingSnapshotValidation.invalid(
        'drillVersionedId komt niet overeen met de drillsnapshot.',
      );
    }

    final rawContext = configuration['trainingPlan'];
    if (rawContext == null) {
      return const TrainingSnapshotValidation.resumable();
    }
    if (rawContext is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'TrainingPlanContext is geen JSON-object.',
      );
    }
    return _validateTrainingPlanContext(rawContext.cast<String, Object?>());
  }

  static TrainingSnapshotValidation _validateTrainingPlan(
    int schemaVersion,
    Map<String, Object?> configuration,
  ) {
    if (schemaVersion > trainingPlanSchemaVersion) {
      return TrainingSnapshotValidation.futureReadOnly(
        'Trainingsplanschema $schemaVersion is nieuwer dan ondersteund.',
      );
    }
    if (schemaVersion != trainingPlanSchemaVersion) {
      return TrainingSnapshotValidation.invalid(
        'trainingPlan vereist schema $trainingPlanSchemaVersion.',
      );
    }
    final rawPlan = configuration['plan'];
    if (rawPlan is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'GeneratedDrillPlan-snapshot ontbreekt.',
      );
    }
    final plan = rawPlan.cast<String, Object?>();
    final version = plan['plannerVersion'];
    if (version is! int || version < 1) {
      return const TrainingSnapshotValidation.invalid(
        'GeneratedDrillPlan bevat geen geldige plannerVersion.',
      );
    }
    if (version > plannerVersion) {
      return TrainingSnapshotValidation.futureReadOnly(
        'Planner $version is nieuwer dan ondersteund.',
      );
    }
    final planId = _nonEmptyString(configuration['planId']);
    if (planId == null) {
      return const TrainingSnapshotValidation.invalid('PlanId ontbreekt.');
    }
    return _validateCurrentGeneratedPlan(planId, plan);
  }

  static TrainingSnapshotValidation _validateLearningPath(
    int schemaVersion,
    Map<String, Object?> configuration,
  ) {
    if (schemaVersion > learningPathSchemaVersion) {
      return TrainingSnapshotValidation.futureReadOnly(
        'Leerpadschema $schemaVersion is nieuwer dan ondersteund.',
      );
    }
    if (schemaVersion != learningPathSchemaVersion) {
      return TrainingSnapshotValidation.invalid(
        'learningPathV2 vereist schema $learningPathSchemaVersion.',
      );
    }
    final embeddedSchema = configuration['schemaVersion'];
    if (embeddedSchema != null && embeddedSchema != learningPathSchemaVersion) {
      return const TrainingSnapshotValidation.invalid(
        'De interne leerpad-schemaversie is ongeldig.',
      );
    }
    final versionedId = _nonEmptyString(
      configuration['learningPathVersionedId'],
    );
    final rawPath = configuration['learningPath'];
    if (versionedId == null || rawPath is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Leerpadsnapshot of learningPathVersionedId ontbreekt.',
      );
    }
    LearningPathV2 path;
    try {
      path = LearningPathV2.fromJson(rawPath.cast<String, Object?>());
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Leerpadsnapshot voldoet niet aan LearningPathV2.',
      );
    }
    if (path.versionedId != versionedId) {
      return const TrainingSnapshotValidation.invalid(
        'learningPathVersionedId komt niet overeen met de snapshot.',
      );
    }
    final entryIndex = <String, int>{};
    for (var index = 0; index < path.entries.length; index++) {
      final entry = path.entries[index];
      if (entryIndex.putIfAbsent(entry.id, () => index) != index ||
          entry.prerequisiteEntryIds.length !=
              entry.prerequisiteEntryIds.toSet().length) {
        return const TrainingSnapshotValidation.invalid(
          'Het leerpad bevat dubbele onderdeel- of prerequisite-ID’s.',
        );
      }
    }
    for (var index = 0; index < path.entries.length; index++) {
      for (final prerequisite in path.entries[index].prerequisiteEntryIds) {
        final prerequisiteIndex = entryIndex[prerequisite];
        if (prerequisiteIndex == null || prerequisiteIndex >= index) {
          return const TrainingSnapshotValidation.invalid(
            'Een leerpad-prerequisite ontbreekt of staat niet vóór de stap.',
          );
        }
      }
    }
    // Early 0.8 development snapshots stored only the path structure. Keep
    // those records resumable when their referenced catalog versions still
    // exist, but strictly validate the immutable entry payloads written by
    // current builds whenever the field is present.
    if (!configuration.containsKey('entrySnapshots')) {
      return const TrainingSnapshotValidation.resumable();
    }
    final rawEntrySnapshots = configuration['entrySnapshots'];
    if (rawEntrySnapshots is! List ||
        rawEntrySnapshots.length != path.entries.length) {
      return const TrainingSnapshotValidation.invalid(
        'Het leerpad bevat geen volledige lijst onderdeelsnapshots.',
      );
    }
    try {
      for (var index = 0; index < path.entries.length; index++) {
        final entry = path.entries[index];
        final rawSnapshot = rawEntrySnapshots[index];
        if (rawSnapshot is! Map) {
          return const TrainingSnapshotValidation.invalid(
            'Een leerpadonderdeelsnapshot is geen JSON-object.',
          );
        }
        final snapshot = rawSnapshot.cast<String, Object?>();
        final rawContent = snapshot['content'];
        if (snapshot['entryId'] != entry.id ||
            snapshot['kind'] != entry.kind.name ||
            snapshot['versionedContentId'] != entry.versionedContentId ||
            rawContent is! Map) {
          return const TrainingSnapshotValidation.invalid(
            'Een leerpadonderdeelsnapshot hoort niet bij de opgeslagen stap.',
          );
        }
        final content = rawContent.cast<String, Object?>();
        final contentVersionedId = switch (entry.kind) {
          LearningPathEntryKind.lesson => TechniqueLessonV2.fromJson(
            content,
          ).versionedId,
          LearningPathEntryKind.drill => DrillDefinitionV2.fromJson(
            content,
          ).versionedId,
        };
        if (contentVersionedId != entry.versionedContentId) {
          return const TrainingSnapshotValidation.invalid(
            'De leerpadinhoud heeft een andere inhoudsversie.',
          );
        }
      }
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Een leerpadonderdeelsnapshot kan niet worden gelezen.',
      );
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static TrainingSnapshotValidation _validateGuidedDrillSummary(
    Map<String, Object?> configuration,
    Map<String, Object?> summary,
    String? status,
  ) {
    final rawDrill = configuration['drill'];
    if (rawDrill is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Drillsnapshot ontbreekt bij de voortgang.',
      );
    }
    final DrillDefinitionV2 drill;
    try {
      drill = DrillDefinitionV2.fromJson(rawDrill.cast<String, Object?>());
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Drillsnapshot kan niet voor voortgang worden gelezen.',
      );
    }
    final summaryVersionedId = summary['drillVersionedId'];
    if (summaryVersionedId != null && summaryVersionedId != drill.versionedId) {
      return const TrainingSnapshotValidation.invalid(
        'De drillvoortgang hoort bij een andere drillversie.',
      );
    }
    for (final key in const [
      'setupConfirmed',
      'safetyConfirmed',
      'validExecution',
      'primaryMeasurementSuccess',
    ]) {
      final value = summary[key];
      if (value != null && value is! bool) {
        return TrainingSnapshotValidation.invalid(
          '$key moet een boolean zijn.',
        );
      }
    }

    final phaseIds = drill.phases.map((phase) => phase.id).toSet();
    final acknowledgedPhaseIds = drill.phases
        .where(
          (phase) =>
              phase.completionKind == DrillPhaseCompletionKind.acknowledged,
        )
        .map((phase) => phase.id)
        .toSet();
    final timerPhaseIds = drill.phases
        .where(
          (phase) =>
              phase.completionKind == DrillPhaseCompletionKind.timerActivity,
        )
        .map((phase) => phase.id)
        .toSet();
    final reflectionPhaseIds = drill.phases
        .where(
          (phase) =>
              phase.completionKind == DrillPhaseCompletionKind.reflection,
        )
        .map((phase) => phase.id)
        .toSet();

    final acknowledged = _validatedStringSet(
      summary['acknowledgedPhaseIds'],
      allowed: acknowledgedPhaseIds,
      optional: true,
    );
    final completed = _validatedStringSet(
      summary['completedPhaseIds'],
      allowed: phaseIds,
      optional: true,
    );
    final sessions = _validatedStringSet(summary['sessionIds'], optional: true);
    final timers = _validatedStringMap(
      summary['timerActivityIds'],
      allowedKeys: timerPhaseIds,
      optional: true,
    );
    final reflections = _validatedStringMap(
      summary['phaseReflections'],
      allowedKeys: reflectionPhaseIds,
      optional: true,
    );
    if (acknowledged == null ||
        completed == null ||
        sessions == null ||
        timers == null ||
        reflections == null) {
      return const TrainingSnapshotValidation.invalid(
        'De drillvoortgang bevat ongeldige fasegegevens.',
      );
    }
    for (final key in const [
      'primaryMeasurementValue',
      'personalBaselineValue',
    ]) {
      final value = summary[key];
      if (value != null && (value is! num || !value.isFinite)) {
        return TrainingSnapshotValidation.invalid('$key moet eindig zijn.');
      }
    }
    final sampleSize = summary['primaryMeasurementSampleSize'];
    final linkedSeriesCount = summary['linkedSeriesCount'];
    if (sampleSize != null && (sampleSize is! int || sampleSize < 0) ||
        linkedSeriesCount != null &&
            (linkedSeriesCount is! int || linkedSeriesCount < 0) ||
        summary['primaryMetric'] != null &&
            _nonEmptyString(summary['primaryMetric']) == null ||
        summary['metricSnapshot'] != null &&
            summary['metricSnapshot'] is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'De drillmeting of reekstelling is ongeldig.',
      );
    }

    if (status == 'completed') {
      final allPhasesCompleted =
          completed.length == phaseIds.length &&
          completed.containsAll(phaseIds);
      if (summaryVersionedId != drill.versionedId ||
          summary['setupConfirmed'] != true ||
          summary['safetyConfirmed'] != true ||
          summary['validExecution'] != true ||
          linkedSeriesCount is! int ||
          linkedSeriesCount < drill.recommendedSeries ||
          !allPhasesCompleted ||
          !acknowledged.containsAll(acknowledgedPhaseIds) ||
          !timers.keys.toSet().containsAll(timerPhaseIds) ||
          !reflections.keys.toSet().containsAll(reflectionPhaseIds)) {
        return const TrainingSnapshotValidation.invalid(
          'Een afgeronde drill mist veiligheids-, fase- of meetbewijs.',
        );
      }
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static TrainingSnapshotValidation _validateTrainingPlanSummary(
    Map<String, Object?> configuration,
    Map<String, Object?> summary,
    String? status,
  ) {
    final rawPlan = configuration['plan'];
    if (rawPlan is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsplansnapshot ontbreekt bij de voortgang.',
      );
    }
    final plan = rawPlan.cast<String, Object?>();
    final slots = (plan['slots'] as List?)?.whereType<Map>().toList();
    final steps = (plan['steps'] as List?)?.whereType<Map>().toList();
    if (slots == null ||
        steps == null ||
        slots.length != (plan['slots'] as List).length ||
        steps.length != (plan['steps'] as List).length) {
      return const TrainingSnapshotValidation.invalid(
        'Trainingsplanstappen kunnen niet voor voortgang worden gelezen.',
      );
    }
    final slotIndexes = slots
        .map((slot) => slot['index'])
        .whereType<int>()
        .toSet();
    final stepIds = steps.map((step) => step['id']).whereType<String>().toSet();
    final completedSlots = _validatedIntSet(
      summary['completedSlotIndexes'],
      allowed: slotIndexes,
    );
    final completedSteps = _validatedStringSet(
      summary['completedStepIds'],
      allowed: stepIds,
    );
    final drillActivities = _validatedIndexedStringMap(
      summary['guidedDrillActivityIds'],
      allowedIndexes: slotIndexes,
    );
    final currentStepIndex = summary['currentStepIndex'];
    final reflection = summary['finalReflection'];
    if (completedSlots == null ||
        completedSteps == null ||
        drillActivities == null ||
        currentStepIndex is! int ||
        currentStepIndex < 0 ||
        currentStepIndex >= steps.length ||
        reflection != null && _nonEmptyString(reflection) == null ||
        !drillActivities.keys.toSet().containsAll(completedSlots)) {
      return const TrainingSnapshotValidation.invalid(
        'De trainingsplanvoortgang is ongeldig.',
      );
    }
    for (final step in steps) {
      if (step['kind'] == 'drill' && completedSteps.contains(step['id'])) {
        final slotIndex = step['slotIndex'];
        if (slotIndex is! int || !completedSlots.contains(slotIndex)) {
          return const TrainingSnapshotValidation.invalid(
            'Een voltooide drillstap mist een afgeronde planslot.',
          );
        }
      }
      if (step['kind'] == 'finalReflection' &&
          completedSteps.contains(step['id']) &&
          _nonEmptyString(reflection) == null) {
        return const TrainingSnapshotValidation.invalid(
          'De afgeronde reflectiestap bevat geen eindreflectie.',
        );
      }
    }
    final firstIncomplete = steps.indexWhere(
      (step) => !completedSteps.contains(step['id']),
    );
    final expectedCurrent = firstIncomplete < 0
        ? steps.length - 1
        : firstIncomplete;
    if (currentStepIndex != expectedCurrent) {
      return const TrainingSnapshotValidation.invalid(
        'De huidige planstap komt niet overeen met de voortgang.',
      );
    }
    if (status == 'completed' &&
        (completedSlots.length != slotIndexes.length ||
            !completedSlots.containsAll(slotIndexes) ||
            drillActivities.length != slotIndexes.length ||
            completedSteps.length != stepIds.length ||
            !completedSteps.containsAll(stepIds) ||
            _nonEmptyString(reflection) == null)) {
      return const TrainingSnapshotValidation.invalid(
        'Een afgerond trainingsplan mist stappen, drills of eindreflectie.',
      );
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static TrainingSnapshotValidation _validateLearningPathSummary(
    Map<String, Object?> configuration,
    Map<String, Object?> summary,
    String? status,
  ) {
    final rawPath = configuration['learningPath'];
    if (rawPath is! Map) {
      return const TrainingSnapshotValidation.invalid(
        'Leerpadsnapshot ontbreekt bij de voortgang.',
      );
    }
    final LearningPathV2 path;
    try {
      path = LearningPathV2.fromJson(rawPath.cast<String, Object?>());
    } on Object {
      return const TrainingSnapshotValidation.invalid(
        'Leerpadsnapshot kan niet voor voortgang worden gelezen.',
      );
    }
    final entryIds = path.entries
        .map((entry) => entry.id)
        .toList(growable: false);
    final completed = _validatedStringSet(
      summary['completedEntryIds'],
      allowed: entryIds.toSet(),
    );
    final currentIndex = summary['currentEntryIndex'];
    if (completed == null ||
        currentIndex is! int ||
        currentIndex < 0 ||
        currentIndex > entryIds.length) {
      return const TrainingSnapshotValidation.invalid(
        'De leerpadvoortgang is ongeldig.',
      );
    }
    final firstIncomplete = entryIds.indexWhere(
      (entryId) => !completed.contains(entryId),
    );
    final expectedIndex = firstIncomplete < 0
        ? entryIds.length
        : firstIncomplete;
    if (currentIndex != expectedIndex ||
        status == 'completed' && completed.length != entryIds.length) {
      return const TrainingSnapshotValidation.invalid(
        'De huidige leerpadstap komt niet overeen met de voortgang.',
      );
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static TrainingSnapshotValidation _validateTrainingPlanContext(
    Map<String, Object?> context,
  ) {
    final version = context['plannerVersion'];
    if (version is! int || version < 1) {
      return const TrainingSnapshotValidation.invalid(
        'TrainingPlanContext bevat geen geldige plannerVersion.',
      );
    }
    if (version > plannerVersion) {
      return TrainingSnapshotValidation.futureReadOnly(
        'Plannercontext $version is nieuwer dan ondersteund.',
      );
    }
    final duration = context['durationMinutes'];
    final slotIndex = context['slotIndex'];
    final slotCount = context['slotCount'];
    if (_nonEmptyString(context['planActivityId']) == null ||
        _nonEmptyString(context['planId']) == null ||
        duration is! int ||
        !const {30, 45, 60}.contains(duration) ||
        slotIndex is! int ||
        slotCount is! int ||
        slotCount < 1 ||
        slotIndex < 0 ||
        slotIndex >= slotCount ||
        !_supportedPlanDiscipline(context['discipline']) ||
        !_enumName<TrainingSkillLevel>(
          context['skillLevel'],
          TrainingSkillLevel.values,
        )) {
      return const TrainingSnapshotValidation.invalid(
        'TrainingPlanContext is inhoudelijk ongeldig.',
      );
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static TrainingSnapshotValidation _validateCurrentGeneratedPlan(
    String configuredPlanId,
    Map<String, Object?> plan,
  ) {
    final planId = _nonEmptyString(plan['id']);
    final title = _nonEmptyString(plan['title']);
    final duration = plan['durationMinutes'];
    final preparation = plan['preparationMinutes'];
    final review = plan['reviewMinutes'];
    final ammunitionBudget = plan['ammunitionBudget'];
    final disciplineName = plan['discipline'];
    final skillLevelName = plan['skillLevel'];
    final slotsRaw = plan['slots'];
    final stepsRaw = plan['steps'];
    if (planId == null ||
        planId != configuredPlanId ||
        title == null ||
        duration is! int ||
        !const {30, 45, 60}.contains(duration) ||
        preparation is! int ||
        preparation < 0 ||
        review is! int ||
        review < 0 ||
        ammunitionBudget is! int ||
        ammunitionBudget < 0 ||
        !_optionalString(plan['firearmId']) ||
        !_optionalString(plan['ammoLotId']) ||
        !_supportedPlanDiscipline(disciplineName) ||
        !_enumName<TrainingSkillLevel>(
          skillLevelName,
          TrainingSkillLevel.values,
        ) ||
        !_enumNameByNames(plan['focus'], const {
          'fundamentals',
          'groupSize',
          'consistency',
          'matchProcess',
        }) ||
        slotsRaw is! List ||
        slotsRaw.isEmpty ||
        stepsRaw is! List ||
        stepsRaw.isEmpty) {
      return const TrainingSnapshotValidation.invalid(
        'GeneratedDrillPlan bevat ongeldige basisvelden.',
      );
    }

    final slotIndexes = <int>{};
    var usedAmmunition = 0;
    var plannedDrillMinutes = 0;
    for (final rawSlot in slotsRaw) {
      if (rawSlot is! Map) {
        return const TrainingSnapshotValidation.invalid(
          'GeneratedDrillPlan bevat een ongeldige drillplaats.',
        );
      }
      final slot = rawSlot.cast<String, Object?>();
      final index = slot['index'];
      final allocatedMinutes = slot['allocatedMinutes'];
      final rawDrill = slot['drill'];
      if (index is! int ||
          index < 0 ||
          !slotIndexes.add(index) ||
          allocatedMinutes is! int ||
          allocatedMinutes < 1 ||
          rawDrill is! Map) {
        return const TrainingSnapshotValidation.invalid(
          'GeneratedDrillPlan bevat een ongeldige drillplaats.',
        );
      }
      try {
        final drill = DrillDefinitionV2.fromJson(
          rawDrill.cast<String, Object?>(),
        );
        if (allocatedMinutes != drill.estimatedDurationMinutes ||
            drill.skillLevel.name != skillLevelName ||
            drill.discipline != TrainingDiscipline.universal &&
                drill.discipline.name != disciplineName) {
          return const TrainingSnapshotValidation.invalid(
            'Planplaats komt niet overeen met de opgeslagen drill.',
          );
        }
        usedAmmunition += drill.ammunitionBudget;
      } on Object {
        return const TrainingSnapshotValidation.invalid(
          'Plan bevat geen geldige DrillDefinitionV2-snapshot.',
        );
      }
      plannedDrillMinutes += allocatedMinutes;
    }
    final expectedIndexes = {
      for (var index = 0; index < slotsRaw.length; index++) index,
    };
    if (slotIndexes.length != expectedIndexes.length ||
        !slotIndexes.containsAll(expectedIndexes) ||
        usedAmmunition > ammunitionBudget) {
      return const TrainingSnapshotValidation.invalid(
        'Planplaatsen zijn niet aaneensluitend of overschrijden het budget.',
      );
    }

    final stepIds = <String>{};
    final drillStepSlots = <int>{};
    var plannedMinutes = 0;
    for (final rawStep in stepsRaw) {
      if (rawStep is! Map) {
        return const TrainingSnapshotValidation.invalid(
          'GeneratedDrillPlan bevat een ongeldige stap.',
        );
      }
      final step = rawStep.cast<String, Object?>();
      final id = _nonEmptyString(step['id']);
      final minutes = step['allocatedMinutes'];
      final kind = step['kind'];
      final slotIndex = step['slotIndex'];
      if (id == null ||
          !stepIds.add(id) ||
          minutes is! int ||
          minutes < 1 ||
          !_enumNameByNames(kind, const {
            'safetyAndSetup',
            'techniqueReview',
            'drill',
            'restAndReview',
            'finalReflection',
          }) ||
          (slotIndex != null &&
              (slotIndex is! int || !slotIndexes.contains(slotIndex)))) {
        return const TrainingSnapshotValidation.invalid(
          'GeneratedDrillPlan bevat een ongeldige stap.',
        );
      }
      if (kind == 'drill') {
        if (slotIndex is! int || !drillStepSlots.add(slotIndex)) {
          return const TrainingSnapshotValidation.invalid(
            'Iedere drillplaats vereist exact één drillstap.',
          );
        }
      }
      plannedMinutes += minutes;
    }
    if (drillStepSlots.length != slotIndexes.length ||
        !drillStepSlots.containsAll(slotIndexes) ||
        plannedDrillMinutes + preparation + review > duration ||
        plannedMinutes > duration) {
      return const TrainingSnapshotValidation.invalid(
        'GeneratedDrillPlan overschrijdt tijd of mist een drillstap.',
      );
    }
    return const TrainingSnapshotValidation.resumable();
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  static bool _optionalString(Object? value) =>
      value == null || value is String && value.trim().isNotEmpty;

  static bool _enumName<T extends Enum>(Object? value, List<T> values) =>
      value is String && values.any((item) => item.name == value);

  static bool _enumNameByNames(Object? value, Set<String> names) =>
      value is String && names.contains(value);

  static bool _supportedPlanDiscipline(Object? value) =>
      value == TrainingDiscipline.precisionPistol.name ||
      value == TrainingDiscipline.br50.name;

  static Set<String>? _validatedStringSet(
    Object? value, {
    Set<String>? allowed,
    bool optional = false,
  }) {
    if (value == null && optional) return <String>{};
    if (value is! List) return null;
    final result = <String>{};
    for (final item in value) {
      final normalized = _nonEmptyString(item);
      if (normalized == null ||
          !result.add(normalized) ||
          allowed != null && !allowed.contains(normalized)) {
        return null;
      }
    }
    return result;
  }

  static Set<int>? _validatedIntSet(
    Object? value, {
    required Set<int> allowed,
  }) {
    if (value is! List) return null;
    final result = <int>{};
    for (final item in value) {
      if (item is! int || !result.add(item) || !allowed.contains(item)) {
        return null;
      }
    }
    return result;
  }

  static Map<String, String>? _validatedStringMap(
    Object? value, {
    Set<String>? allowedKeys,
    bool optional = false,
  }) {
    if (value == null && optional) return <String, String>{};
    if (value is! Map) return null;
    final result = <String, String>{};
    for (final entry in value.entries) {
      final key = _nonEmptyString(entry.key);
      final mapped = _nonEmptyString(entry.value);
      if (key == null ||
          mapped == null ||
          result.containsKey(key) ||
          allowedKeys != null && !allowedKeys.contains(key)) {
        return null;
      }
      result[key] = mapped;
    }
    return result;
  }

  static Map<int, String>? _validatedIndexedStringMap(
    Object? value, {
    required Set<int> allowedIndexes,
  }) {
    if (value is! Map) return null;
    final result = <int, String>{};
    final activityIds = <String>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final index = key is String ? int.tryParse(key) : null;
      final mapped = _nonEmptyString(entry.value);
      if (index == null ||
          '$index' != key ||
          !allowedIndexes.contains(index) ||
          mapped == null ||
          result.containsKey(index) ||
          !activityIds.add(mapped)) {
        return null;
      }
      result[index] = mapped;
    }
    return result;
  }
}
