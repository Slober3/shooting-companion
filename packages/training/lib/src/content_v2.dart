/// Shared vocabulary for the version 2 learning and drill content.
enum TrainingDiscipline { universal, precisionPistol, br50 }

enum TrainingSkillLevel { foundation, development }

enum TrainingMode {
  rangeDryFire,
  liveFire,
  mixedOnRange,
  analysisOnly,
  matchSimulation,
}

enum ContentEvidenceStatus {
  officialGuidance,
  researchSupported,
  practiceBased,
}

enum CoachReviewStatus { pending, reviewed }

enum TechniqueCategoryV2 {
  safety,
  measurement,
  position,
  aiming,
  shotExecution,
  routine,
  benchrest,
  matchProcess,
}

enum TechniqueSectionType {
  overview,
  setup,
  sequence,
  observe,
  abortOrReset,
  variation,
  evidence,
  practice,
  limits,
}

enum TrainingMetricKind {
  completion,
  scorePercentage,
  meanRadiusMm,
  extremeSpreadMm,
  consistency,
  absoluteBiasMm,
  selfEvaluation,
  shotCallAccuracy,
  filledBullCount,
}

enum TrainingMetricDirection { complete, maximize, minimize, stabilize }

enum TrainingMeasurementRole { primary, secondary }

enum TrainingSampleUnit {
  evidenceLinks,
  linkedSeries,
  positionedShots,
  recordBulls,
  reflections,
  comparableShotCalls,
}

enum DrillPhaseCompletionKind {
  acknowledged,
  confirmedSeries,
  timerActivity,
  reflection,
}

enum LearningPathEntryKind { lesson, drill }

class TrainingReference {
  factory TrainingReference({
    required String id,
    required String title,
    required String url,
    required String publisher,
    String? documentEdition,
    String? locator,
  }) => TrainingReference._(
    id: _requiredText(id, 'id'),
    title: _requiredText(title, 'title'),
    url: _validatedHttpsUrl(url),
    publisher: _requiredText(publisher, 'publisher'),
    documentEdition: _optionalText(documentEdition),
    locator: _optionalText(locator),
  );

  const TrainingReference._({
    required this.id,
    required this.title,
    required this.url,
    required this.publisher,
    this.documentEdition,
    this.locator,
  });

  final String id;
  final String title;
  final String url;
  final String publisher;
  final String? documentEdition;
  final String? locator;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'publisher': publisher,
    'documentEdition': documentEdition,
    'locator': locator,
  };

  factory TrainingReference.fromJson(Map<String, Object?> json) =>
      TrainingReference(
        id: json['id']! as String,
        title: json['title']! as String,
        url: json['url']! as String,
        publisher: json['publisher']! as String,
        documentEdition: json['documentEdition'] as String?,
        locator: json['locator'] as String?,
      );
}

class ContentReview {
  factory ContentReview({
    required ContentEvidenceStatus evidenceStatus,
    required CoachReviewStatus coachReviewStatus,
    required String sourceEdition,
    required DateTime lastSourceCheckUtc,
    String? reviewerRole,
    DateTime? reviewedAtUtc,
  }) {
    final normalizedReviewerRole = _optionalText(reviewerRole);
    if (coachReviewStatus == CoachReviewStatus.reviewed &&
        (normalizedReviewerRole == null || reviewedAtUtc == null)) {
      throw ArgumentError(
        'Coachgereviewde inhoud vereist reviewerRole en reviewedAtUtc.',
      );
    }
    if (!lastSourceCheckUtc.isUtc ||
        (reviewedAtUtc != null && !reviewedAtUtc.isUtc)) {
      throw ArgumentError('Reviewdatums moeten UTC zijn.');
    }
    return ContentReview._(
      evidenceStatus: evidenceStatus,
      coachReviewStatus: coachReviewStatus,
      reviewerRole: normalizedReviewerRole,
      reviewedAtUtc: reviewedAtUtc,
      sourceEdition: _requiredText(sourceEdition, 'sourceEdition'),
      lastSourceCheckUtc: lastSourceCheckUtc,
    );
  }

  const ContentReview._({
    required this.evidenceStatus,
    required this.coachReviewStatus,
    required this.reviewerRole,
    required this.reviewedAtUtc,
    required this.sourceEdition,
    required this.lastSourceCheckUtc,
  });

  final ContentEvidenceStatus evidenceStatus;
  final CoachReviewStatus coachReviewStatus;
  final String? reviewerRole;
  final DateTime? reviewedAtUtc;
  final String sourceEdition;
  final DateTime lastSourceCheckUtc;

  Map<String, Object?> toJson() => {
    'evidenceStatus': evidenceStatus.name,
    'coachReviewStatus': coachReviewStatus.name,
    'reviewerRole': reviewerRole,
    'reviewedAtUtc': reviewedAtUtc?.toIso8601String(),
    'sourceEdition': sourceEdition,
    'lastSourceCheckUtc': lastSourceCheckUtc.toIso8601String(),
  };

  factory ContentReview.fromJson(Map<String, Object?> json) => ContentReview(
    evidenceStatus: ContentEvidenceStatus.values.byName(
      json['evidenceStatus']! as String,
    ),
    coachReviewStatus: CoachReviewStatus.values.byName(
      json['coachReviewStatus']! as String,
    ),
    reviewerRole: json['reviewerRole'] as String?,
    reviewedAtUtc: _optionalDate(json['reviewedAtUtc']),
    sourceEdition: json['sourceEdition']! as String,
    lastSourceCheckUtc: DateTime.parse(
      json['lastSourceCheckUtc']! as String,
    ).toUtc(),
  );
}

class TechniqueSection {
  factory TechniqueSection({
    required TechniqueSectionType type,
    required String title,
    Iterable<String> paragraphs = const [],
    Iterable<String> steps = const [],
    Iterable<String> sourceIds = const [],
  }) {
    final normalizedParagraphs = _normalizedTexts(paragraphs);
    final normalizedSteps = _normalizedTexts(steps);
    if (normalizedParagraphs.isEmpty && normalizedSteps.isEmpty) {
      throw ArgumentError('Een technieksectie mag niet leeg zijn.');
    }
    return TechniqueSection._(
      type: type,
      title: _requiredText(title, 'title'),
      paragraphs: normalizedParagraphs,
      steps: normalizedSteps,
      sourceIds: _normalizedTexts(sourceIds),
    );
  }

  const TechniqueSection._({
    required this.type,
    required this.title,
    required this.paragraphs,
    required this.steps,
    required this.sourceIds,
  });

  final TechniqueSectionType type;
  final String title;
  final List<String> paragraphs;
  final List<String> steps;
  final List<String> sourceIds;

  Map<String, Object?> toJson() => {
    'type': type.name,
    'title': title,
    'paragraphs': paragraphs,
    'steps': steps,
    'sourceIds': sourceIds,
  };

  factory TechniqueSection.fromJson(Map<String, Object?> json) =>
      TechniqueSection(
        type: TechniqueSectionType.values.byName(json['type']! as String),
        title: json['title']! as String,
        paragraphs: _stringList(json['paragraphs']),
        steps: _stringList(json['steps']),
        sourceIds: _stringList(json['sourceIds']),
      );
}

class TechniqueSelfCheck {
  factory TechniqueSelfCheck({
    required String prompt,
    required String observableSuccess,
    required String resetIf,
  }) => TechniqueSelfCheck._(
    prompt: _requiredText(prompt, 'prompt'),
    observableSuccess: _requiredText(observableSuccess, 'observableSuccess'),
    resetIf: _requiredText(resetIf, 'resetIf'),
  );

  const TechniqueSelfCheck._({
    required this.prompt,
    required this.observableSuccess,
    required this.resetIf,
  });

  final String prompt;
  final String observableSuccess;
  final String resetIf;

  Map<String, Object?> toJson() => {
    'prompt': prompt,
    'observableSuccess': observableSuccess,
    'resetIf': resetIf,
  };

  factory TechniqueSelfCheck.fromJson(Map<String, Object?> json) =>
      TechniqueSelfCheck(
        prompt: json['prompt']! as String,
        observableSuccess: json['observableSuccess']! as String,
        resetIf: json['resetIf']! as String,
      );
}

class SafetyCallout {
  factory SafetyCallout({required String title, required String instruction}) =>
      SafetyCallout._(
        title: _requiredText(title, 'title'),
        instruction: _requiredText(instruction, 'instruction'),
      );

  const SafetyCallout._({required this.title, required this.instruction});

  final String title;
  final String instruction;

  Map<String, Object?> toJson() => {'title': title, 'instruction': instruction};

  factory SafetyCallout.fromJson(Map<String, Object?> json) => SafetyCallout(
    title: json['title']! as String,
    instruction: json['instruction']! as String,
  );
}

class TechniqueLessonV2 {
  factory TechniqueLessonV2({
    required String id,
    required int version,
    required String title,
    required String shortPromise,
    required TechniqueCategoryV2 category,
    required Iterable<TrainingDiscipline> disciplines,
    required Iterable<TrainingSkillLevel> levels,
    required int estimatedMinutes,
    Iterable<String> prerequisites = const [],
    required Iterable<String> applicability,
    required Iterable<TechniqueSection> sections,
    required Iterable<String> diagramIds,
    required Iterable<TechniqueSelfCheck> selfChecks,
    required Iterable<String> linkedDrillIds,
    required Iterable<SafetyCallout> safetyCallouts,
    required Iterable<TrainingReference> references,
    required ContentReview review,
  }) {
    if (version < 1) throw ArgumentError.value(version, 'version');
    if (estimatedMinutes < 1 || estimatedMinutes > 120) {
      throw ArgumentError.value(estimatedMinutes, 'estimatedMinutes');
    }
    return TechniqueLessonV2._(
      id: _requiredText(id, 'id'),
      version: version,
      title: _requiredText(title, 'title'),
      shortPromise: _requiredText(shortPromise, 'shortPromise'),
      category: category,
      disciplines: _uniqueEnums(disciplines, 'disciplines'),
      levels: _uniqueEnums(levels, 'levels'),
      estimatedMinutes: estimatedMinutes,
      prerequisites: _normalizedTexts(prerequisites),
      applicability: _requiredTexts(applicability, 'applicability'),
      sections: _requiredObjects(sections, 'sections'),
      diagramIds: _requiredTexts(diagramIds, 'diagramIds'),
      selfChecks: _requiredObjects(selfChecks, 'selfChecks'),
      linkedDrillIds: _requiredTexts(linkedDrillIds, 'linkedDrillIds'),
      safetyCallouts: _requiredObjects(safetyCallouts, 'safetyCallouts'),
      references: _requiredObjects(references, 'references'),
      review: review,
    );
  }

  const TechniqueLessonV2._({
    required this.id,
    required this.version,
    required this.title,
    required this.shortPromise,
    required this.category,
    required this.disciplines,
    required this.levels,
    required this.estimatedMinutes,
    required this.prerequisites,
    required this.applicability,
    required this.sections,
    required this.diagramIds,
    required this.selfChecks,
    required this.linkedDrillIds,
    required this.safetyCallouts,
    required this.references,
    required this.review,
  });

  final String id;
  final int version;
  final String title;
  final String shortPromise;
  final TechniqueCategoryV2 category;
  final List<TrainingDiscipline> disciplines;
  final List<TrainingSkillLevel> levels;
  final int estimatedMinutes;
  final List<String> prerequisites;
  final List<String> applicability;
  final List<TechniqueSection> sections;
  final List<String> diagramIds;
  final List<TechniqueSelfCheck> selfChecks;
  final List<String> linkedDrillIds;
  final List<SafetyCallout> safetyCallouts;
  final List<TrainingReference> references;
  final ContentReview review;

  String get versionedId => '$id@$version';

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'title': title,
    'shortPromise': shortPromise,
    'category': category.name,
    'disciplines': disciplines.map((value) => value.name).toList(),
    'levels': levels.map((value) => value.name).toList(),
    'estimatedMinutes': estimatedMinutes,
    'prerequisites': prerequisites,
    'applicability': applicability,
    'sections': sections.map((value) => value.toJson()).toList(),
    'diagramIds': diagramIds,
    'selfChecks': selfChecks.map((value) => value.toJson()).toList(),
    'linkedDrillIds': linkedDrillIds,
    'safetyCallouts': safetyCallouts.map((value) => value.toJson()).toList(),
    'references': references.map((value) => value.toJson()).toList(),
    'review': review.toJson(),
  };

  factory TechniqueLessonV2.fromJson(
    Map<String, Object?> json,
  ) => TechniqueLessonV2(
    id: json['id']! as String,
    version: json['version']! as int,
    title: json['title']! as String,
    shortPromise: json['shortPromise']! as String,
    category: TechniqueCategoryV2.values.byName(json['category']! as String),
    disciplines: _enumList(json['disciplines'], TrainingDiscipline.values),
    levels: _enumList(json['levels'], TrainingSkillLevel.values),
    estimatedMinutes: json['estimatedMinutes']! as int,
    prerequisites: _stringList(json['prerequisites']),
    applicability: _stringList(json['applicability']),
    sections: _mapList(json['sections'], TechniqueSection.fromJson),
    diagramIds: _stringList(json['diagramIds']),
    selfChecks: _mapList(json['selfChecks'], TechniqueSelfCheck.fromJson),
    linkedDrillIds: _stringList(json['linkedDrillIds']),
    safetyCallouts: _mapList(json['safetyCallouts'], SafetyCallout.fromJson),
    references: _mapList(json['references'], TrainingReference.fromJson),
    review: ContentReview.fromJson(_jsonMap(json['review'])),
  );
}

class DrillSetupV2 {
  factory DrillSetupV2({
    required String target,
    required String distance,
    required Iterable<String> equipment,
    required String dataBasis,
    required String safetyGate,
  }) => DrillSetupV2._(
    target: _requiredText(target, 'target'),
    distance: _requiredText(distance, 'distance'),
    equipment: _requiredTexts(equipment, 'equipment'),
    dataBasis: _requiredText(dataBasis, 'dataBasis'),
    safetyGate: _requiredText(safetyGate, 'safetyGate'),
  );

  const DrillSetupV2._({
    required this.target,
    required this.distance,
    required this.equipment,
    required this.dataBasis,
    required this.safetyGate,
  });

  final String target;
  final String distance;
  final List<String> equipment;
  final String dataBasis;
  final String safetyGate;

  Map<String, Object?> toJson() => {
    'target': target,
    'distance': distance,
    'equipment': equipment,
    'dataBasis': dataBasis,
    'safetyGate': safetyGate,
  };

  factory DrillSetupV2.fromJson(Map<String, Object?> json) => DrillSetupV2(
    target: json['target']! as String,
    distance: json['distance']! as String,
    equipment: _stringList(json['equipment']),
    dataBasis: json['dataBasis']! as String,
    safetyGate: json['safetyGate']! as String,
  );
}

class DrillPhaseV2 {
  factory DrillPhaseV2({
    required String id,
    required String title,
    required Iterable<String> instructions,
    required DrillPhaseCompletionKind completionKind,
    int? seriesCount,
    int? shotsPerSeries,
    int? restSeconds,
    String? linkedTechniqueId,
  }) {
    if (seriesCount != null && seriesCount < 1) {
      throw ArgumentError.value(seriesCount, 'seriesCount');
    }
    if (shotsPerSeries != null && shotsPerSeries < 1) {
      throw ArgumentError.value(shotsPerSeries, 'shotsPerSeries');
    }
    if (restSeconds != null && restSeconds < 0) {
      throw ArgumentError.value(restSeconds, 'restSeconds');
    }
    if (completionKind == DrillPhaseCompletionKind.confirmedSeries &&
        seriesCount == null) {
      throw ArgumentError('Een reeksfase vereist seriesCount.');
    }
    return DrillPhaseV2._(
      id: _requiredText(id, 'id'),
      title: _requiredText(title, 'title'),
      instructions: _requiredTexts(instructions, 'instructions'),
      completionKind: completionKind,
      seriesCount: seriesCount,
      shotsPerSeries: shotsPerSeries,
      restSeconds: restSeconds,
      linkedTechniqueId: _optionalText(linkedTechniqueId),
    );
  }

  const DrillPhaseV2._({
    required this.id,
    required this.title,
    required this.instructions,
    required this.completionKind,
    required this.seriesCount,
    required this.shotsPerSeries,
    required this.restSeconds,
    required this.linkedTechniqueId,
  });

  final String id;
  final String title;
  final List<String> instructions;
  final DrillPhaseCompletionKind completionKind;
  final int? seriesCount;
  final int? shotsPerSeries;
  final int? restSeconds;
  final String? linkedTechniqueId;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'instructions': instructions,
    'completionKind': completionKind.name,
    'seriesCount': seriesCount,
    'shotsPerSeries': shotsPerSeries,
    'restSeconds': restSeconds,
    'linkedTechniqueId': linkedTechniqueId,
  };

  factory DrillPhaseV2.fromJson(Map<String, Object?> json) => DrillPhaseV2(
    id: json['id']! as String,
    title: json['title']! as String,
    instructions: _stringList(json['instructions']),
    completionKind: DrillPhaseCompletionKind.values.byName(
      json['completionKind']! as String,
    ),
    seriesCount: json['seriesCount'] as int?,
    shotsPerSeries: json['shotsPerSeries'] as int?,
    restSeconds: json['restSeconds'] as int?,
    linkedTechniqueId: json['linkedTechniqueId'] as String?,
  );
}

class DrillMeasurementV2 {
  factory DrillMeasurementV2({
    required TrainingMetricKind metric,
    required TrainingMetricDirection direction,
    required TrainingMeasurementRole role,
    required int minimumSampleSize,
    required bool baselineEligible,
    required String interpretation,
  }) {
    if (minimumSampleSize < 1) {
      throw ArgumentError.value(minimumSampleSize, 'minimumSampleSize');
    }
    return DrillMeasurementV2._(
      metric: metric,
      direction: direction,
      role: role,
      minimumSampleSize: minimumSampleSize,
      baselineEligible: baselineEligible,
      interpretation: _requiredText(interpretation, 'interpretation'),
    );
  }

  const DrillMeasurementV2._({
    required this.metric,
    required this.direction,
    required this.role,
    required this.minimumSampleSize,
    required this.baselineEligible,
    required this.interpretation,
  });

  final TrainingMetricKind metric;
  final TrainingMetricDirection direction;
  final TrainingMeasurementRole role;
  final int minimumSampleSize;
  final bool baselineEligible;
  final String interpretation;

  TrainingSampleUnit get sampleUnit => switch (metric) {
    TrainingMetricKind.completion => TrainingSampleUnit.evidenceLinks,
    TrainingMetricKind.scorePercentage ||
    TrainingMetricKind.consistency => TrainingSampleUnit.linkedSeries,
    TrainingMetricKind.absoluteBiasMm ||
    TrainingMetricKind.meanRadiusMm ||
    TrainingMetricKind.extremeSpreadMm => TrainingSampleUnit.positionedShots,
    TrainingMetricKind.filledBullCount => TrainingSampleUnit.recordBulls,
    TrainingMetricKind.selfEvaluation => TrainingSampleUnit.reflections,
    TrainingMetricKind.shotCallAccuracy =>
      TrainingSampleUnit.comparableShotCalls,
  };

  Map<String, Object?> toJson() => {
    'metric': metric.name,
    'direction': direction.name,
    'role': role.name,
    'minimumSampleSize': minimumSampleSize,
    'baselineEligible': baselineEligible,
    'interpretation': interpretation,
  };

  factory DrillMeasurementV2.fromJson(Map<String, Object?> json) =>
      DrillMeasurementV2(
        metric: TrainingMetricKind.values.byName(json['metric']! as String),
        direction: TrainingMetricDirection.values.byName(
          json['direction']! as String,
        ),
        role: TrainingMeasurementRole.values.byName(json['role']! as String),
        minimumSampleSize: json['minimumSampleSize']! as int,
        baselineEligible: json['baselineEligible']! as bool,
        interpretation: json['interpretation']! as String,
      );
}

class DrillMasteryRuleV2 {
  factory DrillMasteryRuleV2({
    required int minimumValidExecutions,
    required int requiredSuccesses,
    required int evaluationWindow,
    required bool usesPersonalBaseline,
    required String explanation,
  }) {
    if (minimumValidExecutions < 1 ||
        requiredSuccesses < 1 ||
        evaluationWindow < requiredSuccesses ||
        minimumValidExecutions > evaluationWindow) {
      throw ArgumentError('Ongeldige beheersingsregel.');
    }
    return DrillMasteryRuleV2._(
      minimumValidExecutions: minimumValidExecutions,
      requiredSuccesses: requiredSuccesses,
      evaluationWindow: evaluationWindow,
      usesPersonalBaseline: usesPersonalBaseline,
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  const DrillMasteryRuleV2._({
    required this.minimumValidExecutions,
    required this.requiredSuccesses,
    required this.evaluationWindow,
    required this.usesPersonalBaseline,
    required this.explanation,
  });

  final int minimumValidExecutions;
  final int requiredSuccesses;
  final int evaluationWindow;
  final bool usesPersonalBaseline;
  final String explanation;

  Map<String, Object?> toJson() => {
    'minimumValidExecutions': minimumValidExecutions,
    'requiredSuccesses': requiredSuccesses,
    'evaluationWindow': evaluationWindow,
    'usesPersonalBaseline': usesPersonalBaseline,
    'explanation': explanation,
  };

  factory DrillMasteryRuleV2.fromJson(Map<String, Object?> json) =>
      DrillMasteryRuleV2(
        minimumValidExecutions: json['minimumValidExecutions']! as int,
        requiredSuccesses: json['requiredSuccesses']! as int,
        evaluationWindow: json['evaluationWindow']! as int,
        usesPersonalBaseline: json['usesPersonalBaseline']! as bool,
        explanation: json['explanation']! as String,
      );
}

class DrillProgressionV2 {
  factory DrillProgressionV2({
    required String usableResult,
    required String insufficientData,
    required String unreliableResult,
    String? nextDrillId,
  }) => DrillProgressionV2._(
    usableResult: _requiredText(usableResult, 'usableResult'),
    insufficientData: _requiredText(insufficientData, 'insufficientData'),
    unreliableResult: _requiredText(unreliableResult, 'unreliableResult'),
    nextDrillId: _optionalText(nextDrillId),
  );

  const DrillProgressionV2._({
    required this.usableResult,
    required this.insufficientData,
    required this.unreliableResult,
    required this.nextDrillId,
  });

  final String usableResult;
  final String insufficientData;
  final String unreliableResult;
  final String? nextDrillId;

  Map<String, Object?> toJson() => {
    'usableResult': usableResult,
    'insufficientData': insufficientData,
    'unreliableResult': unreliableResult,
    'nextDrillId': nextDrillId,
  };

  factory DrillProgressionV2.fromJson(Map<String, Object?> json) =>
      DrillProgressionV2(
        usableResult: json['usableResult']! as String,
        insufficientData: json['insufficientData']! as String,
        unreliableResult: json['unreliableResult']! as String,
        nextDrillId: json['nextDrillId'] as String?,
      );
}

class DrillDefinitionV2 {
  factory DrillDefinitionV2({
    required String id,
    required int version,
    required String title,
    required String shortPurpose,
    required TrainingDiscipline discipline,
    required TrainingSkillLevel skillLevel,
    required TrainingMode mode,
    required int estimatedDurationMinutes,
    required int ammunitionBudget,
    Iterable<String> prerequisites = const [],
    required DrillSetupV2 setup,
    required Iterable<DrillPhaseV2> phases,
    required Iterable<DrillMeasurementV2> measurements,
    required DrillMasteryRuleV2 masteryRule,
    required Iterable<String> stopRules,
    required Iterable<String> reflectionPrompts,
    required DrillProgressionV2 progression,
    required Iterable<String> diagramIds,
    required Iterable<String> techniqueReferences,
    required Iterable<TrainingReference> references,
    required ContentReview review,
  }) {
    if (version < 1) throw ArgumentError.value(version, 'version');
    if (estimatedDurationMinutes < 1 || estimatedDurationMinutes > 240) {
      throw ArgumentError.value(
        estimatedDurationMinutes,
        'estimatedDurationMinutes',
      );
    }
    if (ammunitionBudget < 0 || ammunitionBudget > 1000) {
      throw ArgumentError.value(ammunitionBudget, 'ammunitionBudget');
    }
    final normalizedMeasurements = _requiredObjects(
      measurements,
      'measurements',
    );
    if (normalizedMeasurements
            .where((value) => value.role == TrainingMeasurementRole.primary)
            .length !=
        1) {
      throw ArgumentError('Een drill vereist exact één primaire meting.');
    }
    if (mode == TrainingMode.rangeDryFire && ammunitionBudget != 0) {
      throw ArgumentError('Range dry fire heeft een munitiebudget van nul.');
    }
    return DrillDefinitionV2._(
      id: _requiredText(id, 'id'),
      version: version,
      title: _requiredText(title, 'title'),
      shortPurpose: _requiredText(shortPurpose, 'shortPurpose'),
      discipline: discipline,
      skillLevel: skillLevel,
      mode: mode,
      estimatedDurationMinutes: estimatedDurationMinutes,
      ammunitionBudget: ammunitionBudget,
      prerequisites: _normalizedTexts(prerequisites),
      setup: setup,
      phases: _requiredObjects(phases, 'phases'),
      measurements: normalizedMeasurements,
      masteryRule: masteryRule,
      stopRules: _requiredTexts(stopRules, 'stopRules'),
      reflectionPrompts: _requiredTexts(reflectionPrompts, 'reflectionPrompts'),
      progression: progression,
      diagramIds: _requiredTexts(diagramIds, 'diagramIds'),
      techniqueReferences: _requiredTexts(
        techniqueReferences,
        'techniqueReferences',
      ),
      references: _requiredObjects(references, 'references'),
      review: review,
    );
  }

  const DrillDefinitionV2._({
    required this.id,
    required this.version,
    required this.title,
    required this.shortPurpose,
    required this.discipline,
    required this.skillLevel,
    required this.mode,
    required this.estimatedDurationMinutes,
    required this.ammunitionBudget,
    required this.prerequisites,
    required this.setup,
    required this.phases,
    required this.measurements,
    required this.masteryRule,
    required this.stopRules,
    required this.reflectionPrompts,
    required this.progression,
    required this.diagramIds,
    required this.techniqueReferences,
    required this.references,
    required this.review,
  });

  final String id;
  final int version;
  final String title;
  final String shortPurpose;
  final TrainingDiscipline discipline;
  final TrainingSkillLevel skillLevel;
  final TrainingMode mode;
  final int estimatedDurationMinutes;
  final int ammunitionBudget;
  final List<String> prerequisites;
  final DrillSetupV2 setup;
  final List<DrillPhaseV2> phases;
  final List<DrillMeasurementV2> measurements;
  final DrillMasteryRuleV2 masteryRule;
  final List<String> stopRules;
  final List<String> reflectionPrompts;
  final DrillProgressionV2 progression;
  final List<String> diagramIds;
  final List<String> techniqueReferences;
  final List<TrainingReference> references;
  final ContentReview review;

  String get versionedId => '$id@$version';

  int get recommendedSeries =>
      phases.fold(0, (total, phase) => total + (phase.seriesCount ?? 0));

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'title': title,
    'shortPurpose': shortPurpose,
    'discipline': discipline.name,
    'skillLevel': skillLevel.name,
    'mode': mode.name,
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'ammunitionBudget': ammunitionBudget,
    'prerequisites': prerequisites,
    'setup': setup.toJson(),
    'phases': phases.map((value) => value.toJson()).toList(),
    'measurements': measurements.map((value) => value.toJson()).toList(),
    'masteryRule': masteryRule.toJson(),
    'stopRules': stopRules,
    'reflectionPrompts': reflectionPrompts,
    'progression': progression.toJson(),
    'diagramIds': diagramIds,
    'techniqueReferences': techniqueReferences,
    'references': references.map((value) => value.toJson()).toList(),
    'review': review.toJson(),
  };

  factory DrillDefinitionV2.fromJson(
    Map<String, Object?> json,
  ) => DrillDefinitionV2(
    id: json['id']! as String,
    version: json['version']! as int,
    title: json['title']! as String,
    shortPurpose: json['shortPurpose']! as String,
    discipline: TrainingDiscipline.values.byName(json['discipline']! as String),
    skillLevel: TrainingSkillLevel.values.byName(json['skillLevel']! as String),
    mode: TrainingMode.values.byName(json['mode']! as String),
    estimatedDurationMinutes: json['estimatedDurationMinutes']! as int,
    ammunitionBudget: json['ammunitionBudget']! as int,
    prerequisites: _stringList(json['prerequisites']),
    setup: DrillSetupV2.fromJson(_jsonMap(json['setup'])),
    phases: _mapList(json['phases'], DrillPhaseV2.fromJson),
    measurements: _mapList(json['measurements'], DrillMeasurementV2.fromJson),
    masteryRule: DrillMasteryRuleV2.fromJson(_jsonMap(json['masteryRule'])),
    stopRules: _stringList(json['stopRules']),
    reflectionPrompts: _stringList(json['reflectionPrompts']),
    progression: DrillProgressionV2.fromJson(_jsonMap(json['progression'])),
    diagramIds: _stringList(json['diagramIds']),
    techniqueReferences: _stringList(json['techniqueReferences']),
    references: _mapList(json['references'], TrainingReference.fromJson),
    review: ContentReview.fromJson(_jsonMap(json['review'])),
  );
}

class LearningPathEntryV2 {
  factory LearningPathEntryV2({
    required String id,
    required LearningPathEntryKind kind,
    required String versionedContentId,
    Iterable<String> prerequisiteEntryIds = const [],
  }) => LearningPathEntryV2._(
    id: _requiredText(id, 'id'),
    kind: kind,
    versionedContentId: _requiredVersionedId(versionedContentId),
    prerequisiteEntryIds: _normalizedTexts(prerequisiteEntryIds),
  );

  const LearningPathEntryV2._({
    required this.id,
    required this.kind,
    required this.versionedContentId,
    required this.prerequisiteEntryIds,
  });

  final String id;
  final LearningPathEntryKind kind;
  final String versionedContentId;
  final List<String> prerequisiteEntryIds;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'versionedContentId': versionedContentId,
    'prerequisiteEntryIds': prerequisiteEntryIds,
  };

  factory LearningPathEntryV2.fromJson(Map<String, Object?> json) =>
      LearningPathEntryV2(
        id: json['id']! as String,
        kind: LearningPathEntryKind.values.byName(json['kind']! as String),
        versionedContentId: json['versionedContentId']! as String,
        prerequisiteEntryIds: _stringList(json['prerequisiteEntryIds']),
      );
}

class LearningPathV2 {
  factory LearningPathV2({
    required String id,
    required int version,
    required String title,
    required String shortDescription,
    required TrainingDiscipline discipline,
    required int estimatedMinutes,
    required Iterable<LearningPathEntryV2> entries,
    required Iterable<TrainingReference> references,
    required ContentReview review,
  }) {
    if (version < 1) throw ArgumentError.value(version, 'version');
    if (estimatedMinutes < 1) {
      throw ArgumentError.value(estimatedMinutes, 'estimatedMinutes');
    }
    return LearningPathV2._(
      id: _requiredText(id, 'id'),
      version: version,
      title: _requiredText(title, 'title'),
      shortDescription: _requiredText(shortDescription, 'shortDescription'),
      discipline: discipline,
      estimatedMinutes: estimatedMinutes,
      entries: _requiredObjects(entries, 'entries'),
      references: _requiredObjects(references, 'references'),
      review: review,
    );
  }

  const LearningPathV2._({
    required this.id,
    required this.version,
    required this.title,
    required this.shortDescription,
    required this.discipline,
    required this.estimatedMinutes,
    required this.entries,
    required this.references,
    required this.review,
  });

  final String id;
  final int version;
  final String title;
  final String shortDescription;
  final TrainingDiscipline discipline;
  final int estimatedMinutes;
  final List<LearningPathEntryV2> entries;
  final List<TrainingReference> references;
  final ContentReview review;

  String get versionedId => '$id@$version';

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'title': title,
    'shortDescription': shortDescription,
    'discipline': discipline.name,
    'estimatedMinutes': estimatedMinutes,
    'entries': entries.map((value) => value.toJson()).toList(),
    'references': references.map((value) => value.toJson()).toList(),
    'review': review.toJson(),
  };

  factory LearningPathV2.fromJson(Map<String, Object?> json) => LearningPathV2(
    id: json['id']! as String,
    version: json['version']! as int,
    title: json['title']! as String,
    shortDescription: json['shortDescription']! as String,
    discipline: TrainingDiscipline.values.byName(json['discipline']! as String),
    estimatedMinutes: json['estimatedMinutes']! as int,
    entries: _mapList(json['entries'], LearningPathEntryV2.fromJson),
    references: _mapList(json['references'], TrainingReference.fromJson),
    review: ContentReview.fromJson(_jsonMap(json['review'])),
  );
}

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String _requiredVersionedId(String value) {
  final normalized = _requiredText(value, 'versionedContentId');
  if (!RegExp(r'^[-a-z0-9]+@[1-9][0-9]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'versionedContentId');
  }
  return normalized;
}

String? _optionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _validatedHttpsUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw ArgumentError.value(
      value,
      'url',
      'Alleen HTTPS-bronnen zijn geldig.',
    );
  }
  return uri.toString();
}

List<String> _normalizedTexts(Iterable<String> values) => List.unmodifiable(
  values.map((value) => value.trim()).where((value) => value.isNotEmpty),
);

List<String> _requiredTexts(Iterable<String> values, String field) {
  final normalized = _normalizedTexts(values);
  if (normalized.isEmpty) throw ArgumentError('$field mag niet leeg zijn.');
  return normalized;
}

List<T> _requiredObjects<T>(Iterable<T> values, String field) {
  final result = List<T>.unmodifiable(values);
  if (result.isEmpty) throw ArgumentError('$field mag niet leeg zijn.');
  return result;
}

List<T> _uniqueEnums<T extends Enum>(Iterable<T> values, String field) {
  final result = values.toSet().toList(growable: false);
  if (result.isEmpty) throw ArgumentError('$field mag niet leeg zijn.');
  return List.unmodifiable(result);
}

List<String> _stringList(Object? value) =>
    ((value as List<Object?>?) ?? const []).cast<String>();

Map<String, Object?> _jsonMap(Object? value) =>
    (value! as Map).cast<String, Object?>();

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, Object?> json) factory,
) => ((value as List<Object?>?) ?? const [])
    .map((item) => factory(_jsonMap(item)))
    .toList(growable: false);

List<T> _enumList<T extends Enum>(Object? value, List<T> values) => _stringList(
  value,
).map((name) => values.byName(name)).toList(growable: false);
