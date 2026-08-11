import 'package:shooting_companion_domain/domain.dart';

import 'content_v2.dart';
import 'drills.dart';
import 'techniques.dart';

extension TechniqueLessonV2LegacyAdapter on TechniqueLessonV2 {
  TechniqueTopic toLegacyTopic() {
    final sequence = sections
        .where((section) => section.type == TechniqueSectionType.sequence)
        .expand((section) => [...section.steps, ...section.paragraphs])
        .toList();
    final reset = sections
        .where((section) => section.type == TechniqueSectionType.abortOrReset)
        .expand((section) => [...section.paragraphs, ...section.steps])
        .toList();
    final practice = sections
        .where((section) => section.type == TechniqueSectionType.practice)
        .expand((section) => [...section.steps, ...section.paragraphs])
        .toList();
    return TechniqueTopic(
      id: id,
      version: version,
      title: title,
      summary: shortPromise,
      category: _legacyTechniqueCategory(category),
      illustration: _legacyIllustration(category),
      keyPoints: sequence.isEmpty ? applicability : sequence,
      commonPitfalls: reset.isEmpty
          ? const [
              'Breek af wanneer de veilige of observeerbare basis ontbreekt.',
            ]
          : reset,
      practiceSteps: practice.isEmpty
          ? selfChecks.map((item) => item.prompt)
          : practice,
      safetyNote: safetyCallouts.map((item) => item.instruction).join(' '),
      sources: references.map(
        (item) => TechniqueSource(title: item.title, url: item.url),
      ),
      reviewStatus: TechniqueReviewStatus.coachReviewRequired,
    );
  }
}

extension DrillDefinitionV2LegacyAdapter on DrillDefinitionV2 {
  DrillDefinition toLegacyDefinition() {
    final primary = measurements.singleWhere(
      (item) => item.role == TrainingMeasurementRole.primary,
    );
    final shots = phases
        .map((phase) => phase.shotsPerSeries)
        .whereType<int>()
        .fold<int>(0, (maximum, value) => value > maximum ? value : maximum);
    return DrillDefinition(
      id: id,
      version: version,
      name: title,
      objective: shortPurpose,
      compatibleTargetKinds: discipline == TrainingDiscipline.br50
          ? const [TargetKind.multiBullConcentric]
          : const [TargetKind.concentricRings],
      recommendedSeries: recommendedSeries < 1 ? 1 : recommendedSeries,
      shotStructure: shots == 0
          ? DrillShotStructure(description: setup.dataBasis)
          : DrillShotStructure(
              shotsPerSeries: shots,
              description: setup.dataBasis,
            ),
      successMetric: DrillSuccessMetric(
        metric: _legacyMetric(primary.metric),
        direction: _legacyDirection(primary.direction),
      ),
      instructions: phases.expand(
        (phase) => ['${phase.title}: ${phase.instructions.join(' ')}'],
      ),
      safetyNote: setup.safetyGate,
      category: _legacyDrillCategory(this),
      estimatedMinutes: estimatedDurationMinutes,
      validationStatus: DrillValidationStatus.experimental,
    );
  }
}

TechniqueCategory _legacyTechniqueCategory(TechniqueCategoryV2 category) =>
    switch (category) {
      TechniqueCategoryV2.safety => TechniqueCategory.safety,
      TechniqueCategoryV2.position => TechniqueCategory.position,
      TechniqueCategoryV2.aiming => TechniqueCategory.aiming,
      TechniqueCategoryV2.shotExecution => TechniqueCategory.shotExecution,
      TechniqueCategoryV2.benchrest => TechniqueCategory.benchrest,
      TechniqueCategoryV2.measurement ||
      TechniqueCategoryV2.routine ||
      TechniqueCategoryV2.matchProcess => TechniqueCategory.mentalRoutine,
    };

TechniqueIllustration _legacyIllustration(TechniqueCategoryV2 category) =>
    switch (category) {
      TechniqueCategoryV2.safety => TechniqueIllustration.safetyTriangle,
      TechniqueCategoryV2.position => TechniqueIllustration.naturalAlignment,
      TechniqueCategoryV2.aiming => TechniqueIllustration.sightAlignment,
      TechniqueCategoryV2.shotExecution =>
        TechniqueIllustration.triggerPressure,
      TechniqueCategoryV2.benchrest => TechniqueIllustration.benchrestSupport,
      TechniqueCategoryV2.measurement ||
      TechniqueCategoryV2.routine ||
      TechniqueCategoryV2.matchProcess => TechniqueIllustration.shotRoutine,
    };

DrillMetric _legacyMetric(TrainingMetricKind metric) => switch (metric) {
  TrainingMetricKind.completion ||
  TrainingMetricKind.filledBullCount => DrillMetric.completion,
  TrainingMetricKind.scorePercentage => DrillMetric.scorePercentage,
  TrainingMetricKind.meanRadiusMm => DrillMetric.meanRadiusMm,
  TrainingMetricKind.extremeSpreadMm => DrillMetric.extremeSpreadMm,
  TrainingMetricKind.consistency ||
  TrainingMetricKind.shotCallAccuracy => DrillMetric.consistency,
  TrainingMetricKind.absoluteBiasMm => DrillMetric.absoluteBiasMm,
  TrainingMetricKind.selfEvaluation => DrillMetric.selfEvaluation,
};

DrillMetricDirection _legacyDirection(TrainingMetricDirection direction) =>
    switch (direction) {
      TrainingMetricDirection.complete => DrillMetricDirection.complete,
      TrainingMetricDirection.maximize => DrillMetricDirection.maximize,
      TrainingMetricDirection.minimize ||
      TrainingMetricDirection.stabilize => DrillMetricDirection.minimize,
    };

DrillCategory _legacyDrillCategory(DrillDefinitionV2 drill) {
  if (drill.mode == TrainingMode.matchSimulation) {
    return DrillCategory.matchPreparation;
  }
  if (drill.mode == TrainingMode.analysisOnly) return DrillCategory.reflection;
  if (drill.title.toLowerCase().contains('basis') ||
      drill.title.toLowerCase().contains('koude')) {
    return DrillCategory.baseline;
  }
  return DrillCategory.technique;
}
