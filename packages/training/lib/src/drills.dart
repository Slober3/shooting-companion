import 'package:shooting_companion_domain/domain.dart';

enum DrillValidationStatus { experimental, coachReviewed }

enum DrillMetric {
  completion,
  scorePercentage,
  meanRadiusMm,
  extremeSpreadMm,
  consistency,
  absoluteBiasMm,
  selfEvaluation,
}

enum DrillMetricDirection { complete, maximize, minimize }

class DrillShotStructure {
  factory DrillShotStructure({int? shotsPerSeries, String? description}) {
    if (shotsPerSeries != null && shotsPerSeries <= 0) {
      throw ArgumentError.value(
        shotsPerSeries,
        'shotsPerSeries',
        'Het aantal schoten moet positief zijn.',
      );
    }
    final normalizedDescription = _optionalText(description);
    if (shotsPerSeries == null && normalizedDescription == null) {
      throw ArgumentError(
        'Een schotstructuur vereist een aantal of een beschrijving.',
      );
    }
    return DrillShotStructure._(
      shotsPerSeries: shotsPerSeries,
      description: normalizedDescription,
    );
  }

  const DrillShotStructure._({this.shotsPerSeries, this.description});

  final int? shotsPerSeries;
  final String? description;

  Map<String, Object?> toJson() => {
    'shotsPerSeries': shotsPerSeries,
    'description': description,
  };

  factory DrillShotStructure.fromJson(Map<String, Object?> json) =>
      DrillShotStructure(
        shotsPerSeries: json['shotsPerSeries'] as int?,
        description: json['description'] as String?,
      );
}

class DrillSuccessMetric {
  factory DrillSuccessMetric({
    required DrillMetric metric,
    required DrillMetricDirection direction,
    double? targetValue,
  }) {
    if (targetValue != null && !targetValue.isFinite) {
      throw ArgumentError.value(targetValue, 'targetValue');
    }
    if (direction == DrillMetricDirection.complete && targetValue != null) {
      throw ArgumentError(
        'Een voltooiingsdoel heeft geen numerieke doelwaarde.',
      );
    }
    return DrillSuccessMetric._(
      metric: metric,
      direction: direction,
      targetValue: targetValue,
    );
  }

  const DrillSuccessMetric._({
    required this.metric,
    required this.direction,
    this.targetValue,
  });

  final DrillMetric metric;
  final DrillMetricDirection direction;
  final double? targetValue;

  Map<String, Object?> toJson() => {
    'metric': metric.name,
    'direction': direction.name,
    'targetValue': targetValue,
  };

  factory DrillSuccessMetric.fromJson(Map<String, Object?> json) =>
      DrillSuccessMetric(
        metric: DrillMetric.values.byName(json['metric']! as String),
        direction: DrillMetricDirection.values.byName(
          json['direction']! as String,
        ),
        targetValue: (json['targetValue'] as num?)?.toDouble(),
      );
}

class DrillDefinition {
  factory DrillDefinition({
    required String id,
    required int version,
    required String name,
    required String objective,
    required Iterable<TargetKind> compatibleTargetKinds,
    required int recommendedSeries,
    DrillShotStructure? shotStructure,
    required DrillSuccessMetric successMetric,
    required Iterable<String> instructions,
    required String safetyNote,
    DrillValidationStatus validationStatus = DrillValidationStatus.experimental,
  }) {
    final normalizedId = _requiredText(id, 'id');
    if (version <= 0) {
      throw ArgumentError.value(
        version,
        'version',
        'Versie moet positief zijn.',
      );
    }
    final kinds = compatibleTargetKinds.toSet().toList(growable: false);
    if (kinds.isEmpty) {
      throw ArgumentError('Minstens één compatibel doeltype is vereist.');
    }
    if (recommendedSeries <= 0) {
      throw ArgumentError.value(
        recommendedSeries,
        'recommendedSeries',
        'Het aanbevolen aantal reeksen moet positief zijn.',
      );
    }
    final steps = instructions
        .map((instruction) => instruction.trim())
        .where((instruction) => instruction.isNotEmpty)
        .toList(growable: false);
    if (steps.isEmpty) {
      throw ArgumentError('Minstens één instructie is vereist.');
    }
    return DrillDefinition._(
      id: normalizedId,
      version: version,
      name: _requiredText(name, 'name'),
      objective: _requiredText(objective, 'objective'),
      compatibleTargetKinds: kinds,
      recommendedSeries: recommendedSeries,
      shotStructure: shotStructure,
      successMetric: successMetric,
      instructions: steps,
      safetyNote: _requiredText(safetyNote, 'safetyNote'),
      validationStatus: validationStatus,
    );
  }

  DrillDefinition._({
    required this.id,
    required this.version,
    required this.name,
    required this.objective,
    required List<TargetKind> compatibleTargetKinds,
    required this.recommendedSeries,
    required this.shotStructure,
    required this.successMetric,
    required List<String> instructions,
    required this.safetyNote,
    required this.validationStatus,
  }) : compatibleTargetKinds = List.unmodifiable(compatibleTargetKinds),
       instructions = List.unmodifiable(instructions);

  final String id;
  final int version;
  final String name;
  final String objective;
  final List<TargetKind> compatibleTargetKinds;
  final int recommendedSeries;
  final DrillShotStructure? shotStructure;
  final DrillSuccessMetric successMetric;
  final List<String> instructions;
  final String safetyNote;
  final DrillValidationStatus validationStatus;

  String get versionedId => '$id@$version';

  bool supports(TargetKind kind) => compatibleTargetKinds.contains(kind);

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'name': name,
    'objective': objective,
    'compatibleTargetKinds': compatibleTargetKinds
        .map((kind) => kind.name)
        .toList(),
    'recommendedSeries': recommendedSeries,
    'shotStructure': shotStructure?.toJson(),
    'successMetric': successMetric.toJson(),
    'instructions': instructions,
    'safetyNote': safetyNote,
    'validationStatus': validationStatus.name,
  };

  factory DrillDefinition.fromJson(Map<String, Object?> json) =>
      DrillDefinition(
        id: json['id']! as String,
        version: json['version']! as int,
        name: json['name']! as String,
        objective: json['objective']! as String,
        compatibleTargetKinds: (json['compatibleTargetKinds']! as List<Object?>)
            .map((name) => TargetKind.values.byName(name! as String)),
        recommendedSeries: json['recommendedSeries']! as int,
        shotStructure: json['shotStructure'] == null
            ? null
            : DrillShotStructure.fromJson(
                (json['shotStructure']! as Map).cast<String, Object?>(),
              ),
        successMetric: DrillSuccessMetric.fromJson(
          (json['successMetric']! as Map).cast<String, Object?>(),
        ),
        instructions: (json['instructions']! as List<Object?>).cast<String>(),
        safetyNote: json['safetyNote']! as String,
        validationStatus: DrillValidationStatus.values.byName(
          json['validationStatus']! as String,
        ),
      );
}

abstract final class BuiltInDrills {
  static const _safety =
      'Volg altijd de baanregels en behandel ieder wapen als geladen.';

  static final coldSeriesBenchmark = DrillDefinition(
    id: 'cold-series-benchmark',
    version: 1,
    name: 'Cold-series benchmark',
    objective: 'Meet een representatieve eerste reeks zonder opwarmreeks.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 1,
    shotStructure: DrillShotStructure(
      description: 'Gebruik je normale wedstrijd- of trainingsreeks.',
    ),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.scorePercentage,
      direction: DrillMetricDirection.maximize,
    ),
    instructions: const [
      'Gebruik je normale materiaal en voorbereiding.',
      'Schiet de eerste bevestigde reeks zonder voorafgaande proefreeks.',
      'Bewaar de reeks en voeg alleen achteraf context toe.',
    ],
    safetyNote: _safety,
  );

  static final groupSize = DrillDefinition(
    id: 'group-size-no-score-focus',
    version: 1,
    name: 'Groepsgrootte zonder scorefocus',
    objective: 'Verklein de groep zonder je door de ringscore te laten sturen.',
    compatibleTargetKinds: const [TargetKind.concentricRings],
    recommendedSeries: 3,
    shotStructure: DrillShotStructure(shotsPerSeries: 5),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.meanRadiusMm,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Gebruik voor alle reeksen dezelfde kaart, afstand en uitrusting.',
      'Richt op een identiek punt en beoordeel pas na de reeks.',
      'Vergelijk mean radius en extreme spreiding tussen de reeksen.',
    ],
    safetyNote: _safety,
  );

  static final fiveSeriesConsistency = DrillDefinition(
    id: 'five-series-consistency',
    version: 1,
    name: 'Consistentie over vijf reeksen',
    objective: 'Meet hoe stabiel score en trefbeeld over vijf reeksen blijven.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 5,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.consistency,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Wijzig geen materiaal of doelinstellingen tussen reeksen.',
      'Bewaar iedere reeks afzonderlijk.',
      'Vergelijk spreiding tussen en binnen de reeksen.',
    ],
    safetyNote: _safety,
  );

  static final positionComparison = DrillDefinition(
    id: 'position-comparison',
    version: 1,
    name: 'Opgelegd versus gebruikelijke houding',
    objective: 'Vergelijk twee houdingen zonder andere variabelen te wijzigen.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 4,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.meanRadiusMm,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Leg beide houdingen vooraf duidelijk vast.',
      'Schiet in de volgorde A-B-B-A.',
      'Vergelijk pas nadat beide varianten evenveel reeksen hebben.',
    ],
    safetyNote: _safety,
  );

  static final ammunitionComparison = DrillDefinition(
    id: 'ammunition-lot-comparison',
    version: 1,
    name: 'Munitielot A/B',
    objective: 'Vergelijk twee munitielots onder dezelfde omstandigheden.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 4,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.meanRadiusMm,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Gebruik hetzelfde wapen, doel en dezelfde afstand.',
      'Schiet in de volgorde A-B-B-A.',
      'Trek pas een conclusie na voldoende reeksen en treffers.',
    ],
    safetyNote: _safety,
  );

  static final centeringVersusSpread = DrillDefinition(
    id: 'centering-versus-spread',
    version: 1,
    name: 'Groepscentrum versus spreiding',
    objective: 'Onderscheid een centreerprobleem van een ruime groep.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 3,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.absoluteBiasMm,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Behoud dezelfde richtinstelling tijdens alle reeksen.',
      'Vergelijk groepscentrum, mean radius en extreme spreiding.',
      'Wijzig pas nadien één variabele voor een controlegroep.',
    ],
    safetyNote: _safety,
  );

  static final br50Discipline = DrillDefinition(
    id: 'br50-card-discipline',
    version: 1,
    name: 'BR50 kaartdiscipline',
    objective: 'Voltooi alle 25 wedstrijdroosjes met een vaste routine.',
    compatibleTargetKinds: const [TargetKind.multiBullConcentric],
    recommendedSeries: 1,
    shotStructure: DrillShotStructure(
      shotsPerSeries: 25,
      description: 'Eén wedstrijdschot per recordroosje.',
    ),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.scorePercentage,
      direction: DrillMetricDirection.maximize,
    ),
    instructions: const [
      'Werk de wedstrijdroosjes in een vooraf gekozen volgorde af.',
      'Controleer voor bewaren of ieder recordroosje is ingevuld.',
      'Gebruik proefroosjes alleen volgens de geldende baan- en wedstrijdregels.',
    ],
    safetyNote: _safety,
  );

  static final selfEvaluation = DrillDefinition(
    id: 'self-evaluation-follow-through',
    version: 1,
    name: 'Zelfevaluatie en follow-through',
    objective: 'Vergelijk je korte zelfevaluatie met het gemeten resultaat.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 3,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.selfEvaluation,
      direction: DrillMetricDirection.complete,
    ),
    instructions: const [
      'Beoordeel iedere reeks direct als goed, neutraal of moeilijk.',
      'Voeg alleen context toe die je daadwerkelijk hebt waargenomen.',
      'Vergelijk evaluatie en trefbeeld pas na alle reeksen.',
    ],
    safetyNote: _safety,
  );

  static final sightVerification = DrillDefinition(
    id: 'sight-verification',
    version: 1,
    name: 'Vizierverificatie',
    objective: 'Controleer het groepscentrum vóór een vizieraanpassing.',
    compatibleTargetKinds: const [TargetKind.concentricRings],
    recommendedSeries: 2,
    shotStructure: DrillShotStructure(shotsPerSeries: 5),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.absoluteBiasMm,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Schiet eerst een controlegroep zonder het vizier te wijzigen.',
      'Bevestig klikwaarde en bewegingsrichting van het vizier.',
      'Schiet na een eventuele aanpassing een tweede controlegroep.',
    ],
    safetyNote: _safety,
  );

  static final List<DrillDefinition> all = List.unmodifiable([
    coldSeriesBenchmark,
    groupSize,
    fiveSeriesConsistency,
    positionComparison,
    ammunitionComparison,
    centeringVersusSpread,
    br50Discipline,
    selfEvaluation,
    sightVerification,
  ]);

  static DrillDefinition byVersionedId(String versionedId) => all.firstWhere(
    (drill) => drill.versionedId == versionedId,
    orElse: () => throw ArgumentError.value(
      versionedId,
      'versionedId',
      'Onbekende ingebouwde drill.',
    ),
  );
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Waarde mag niet leeg zijn.');
  }
  return normalized;
}

String? _optionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
