import 'package:shooting_companion_training/training.dart';

import '../../data/training_activity_snapshot_validator.dart';

enum TrainingPlanFocus { fundamentals, groupSize, consistency, matchProcess }

enum TrainingPlanStepKind {
  safetyAndSetup,
  techniqueReview,
  drill,
  restAndReview,
  finalReflection,
}

class TrainingPlanContext {
  const TrainingPlanContext({
    required this.planActivityId,
    required this.planId,
    required this.durationMinutes,
    required this.slotIndex,
    required this.slotCount,
    required this.discipline,
    required this.skillLevel,
    this.firearmId,
    this.ammoLotId,
  });

  final String planActivityId;
  final String planId;
  final int durationMinutes;
  final int slotIndex;
  final int slotCount;
  final TrainingDiscipline discipline;
  final TrainingSkillLevel skillLevel;
  final String? firearmId;
  final String? ammoLotId;

  factory TrainingPlanContext.fromJson(Map<String, Object?> json) {
    final validation =
        TrainingActivitySnapshotValidator.validateTrainingPlanContext(json);
    if (!validation.canResume) {
      throw FormatException(
        validation.message ?? 'TrainingPlanContext is niet ondersteund.',
      );
    }
    return TrainingPlanContext(
      planActivityId: json['planActivityId']! as String,
      planId: json['planId']! as String,
      durationMinutes: json['durationMinutes']! as int,
      slotIndex: json['slotIndex']! as int,
      slotCount: json['slotCount']! as int,
      discipline: TrainingDiscipline.values.byName(
        json['discipline']! as String,
      ),
      skillLevel: TrainingSkillLevel.values.byName(
        json['skillLevel']! as String,
      ),
      firearmId: json['firearmId'] as String?,
      ammoLotId: json['ammoLotId'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'planActivityId': planActivityId,
    'planId': planId,
    'durationMinutes': durationMinutes,
    'slotIndex': slotIndex,
    'slotCount': slotCount,
    'discipline': discipline.name,
    'skillLevel': skillLevel.name,
    'firearmId': firearmId,
    'ammoLotId': ammoLotId,
    'plannerVersion': 1,
  };
}

class PlannedDrillSlot {
  const PlannedDrillSlot({
    required this.drill,
    required this.allocatedMinutes,
    required this.index,
  });

  final DrillDefinitionV2 drill;
  final int allocatedMinutes;
  final int index;

  Map<String, Object?> toJson() => {
    'drill': drill.toJson(),
    'allocatedMinutes': allocatedMinutes,
    'index': index,
  };

  factory PlannedDrillSlot.fromJson(Map<String, Object?> json) =>
      PlannedDrillSlot(
        drill: DrillDefinitionV2.fromJson(
          (json['drill']! as Map).cast<String, Object?>(),
        ),
        allocatedMinutes: json['allocatedMinutes']! as int,
        index: json['index']! as int,
      );
}

class GeneratedDrillPlan {
  const GeneratedDrillPlan({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.preparationMinutes,
    required this.reviewMinutes,
    required this.discipline,
    required this.skillLevel,
    required this.focus,
    required this.ammunitionBudget,
    required this.firearmId,
    required this.ammoLotId,
    required this.slots,
    required this.steps,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final int preparationMinutes;
  final int reviewMinutes;
  final TrainingDiscipline discipline;
  final TrainingSkillLevel skillLevel;
  final TrainingPlanFocus focus;
  final int ammunitionBudget;
  final String? firearmId;
  final String? ammoLotId;
  final List<PlannedDrillSlot> slots;
  final List<GeneratedTrainingPlanStep> steps;

  int get plannedDrillMinutes =>
      slots.fold(0, (total, slot) => total + slot.allocatedMinutes);

  int get plannedMinutes =>
      steps.fold(0, (total, step) => total + step.allocatedMinutes);

  int get usedAmmunition =>
      slots.fold(0, (total, slot) => total + slot.drill.ammunitionBudget);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'durationMinutes': durationMinutes,
    'preparationMinutes': preparationMinutes,
    'reviewMinutes': reviewMinutes,
    'discipline': discipline.name,
    'skillLevel': skillLevel.name,
    'focus': focus.name,
    'ammunitionBudget': ammunitionBudget,
    'firearmId': firearmId,
    'ammoLotId': ammoLotId,
    'slots': slots.map((slot) => slot.toJson()).toList(growable: false),
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
    'plannerVersion': 1,
  };

  factory GeneratedDrillPlan.fromJson(Map<String, Object?> json) {
    final validation = TrainingActivitySnapshotValidator.validateGeneratedPlan(
      json,
    );
    if (!validation.canResume) {
      throw FormatException(
        validation.message ?? 'GeneratedDrillPlan is niet ondersteund.',
      );
    }
    return GeneratedDrillPlan(
      id: json['id']! as String,
      title: json['title']! as String,
      durationMinutes: json['durationMinutes']! as int,
      preparationMinutes: json['preparationMinutes']! as int,
      reviewMinutes: json['reviewMinutes']! as int,
      discipline: TrainingDiscipline.values.byName(
        json['discipline']! as String,
      ),
      skillLevel: TrainingSkillLevel.values.byName(
        json['skillLevel']! as String,
      ),
      focus: TrainingPlanFocus.values.byName(json['focus']! as String),
      ammunitionBudget: json['ammunitionBudget']! as int,
      firearmId: json['firearmId'] as String?,
      ammoLotId: json['ammoLotId'] as String?,
      slots: (json['slots']! as List)
          .map(
            (item) => PlannedDrillSlot.fromJson(
              (item as Map).cast<String, Object?>(),
            ),
          )
          .toList(growable: false),
      steps: (json['steps']! as List)
          .map(
            (item) => GeneratedTrainingPlanStep.fromJson(
              (item as Map).cast<String, Object?>(),
            ),
          )
          .toList(growable: false),
    );
  }
}

class GeneratedTrainingPlanStep {
  const GeneratedTrainingPlanStep({
    required this.id,
    required this.kind,
    required this.title,
    required this.allocatedMinutes,
    this.slotIndex,
    this.lessonVersionedId,
    this.lessonTitle,
  });

  final String id;
  final TrainingPlanStepKind kind;
  final String title;
  final int allocatedMinutes;
  final int? slotIndex;
  final String? lessonVersionedId;
  final String? lessonTitle;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'allocatedMinutes': allocatedMinutes,
    'slotIndex': slotIndex,
    'lessonVersionedId': lessonVersionedId,
    'lessonTitle': lessonTitle,
  };

  factory GeneratedTrainingPlanStep.fromJson(Map<String, Object?> json) =>
      GeneratedTrainingPlanStep(
        id: json['id']! as String,
        kind: TrainingPlanStepKind.values.byName(json['kind']! as String),
        title: json['title']! as String,
        allocatedMinutes: json['allocatedMinutes']! as int,
        slotIndex: json['slotIndex'] as int?,
        lessonVersionedId: json['lessonVersionedId'] as String?,
        lessonTitle: json['lessonTitle'] as String?,
      );
}
