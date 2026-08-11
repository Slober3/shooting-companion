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

enum DrillCategory {
  baseline,
  grouping,
  consistency,
  technique,
  equipment,
  matchPreparation,
  reflection,
}

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
    DrillCategory category = DrillCategory.technique,
    int estimatedMinutes = 20,
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
    if (estimatedMinutes <= 0 || estimatedMinutes > 240) {
      throw ArgumentError.value(estimatedMinutes, 'estimatedMinutes');
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
      category: category,
      estimatedMinutes: estimatedMinutes,
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
    required this.category,
    required this.estimatedMinutes,
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
  final DrillCategory category;
  final int estimatedMinutes;
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
    'category': category.name,
    'estimatedMinutes': estimatedMinutes,
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
        category: DrillCategory.values.byName(
          (json['category'] as String?) ?? DrillCategory.technique.name,
        ),
        estimatedMinutes: (json['estimatedMinutes'] as int?) ?? 20,
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
    category: DrillCategory.baseline,
    estimatedMinutes: 15,
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
    category: DrillCategory.grouping,
    estimatedMinutes: 25,
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
    category: DrillCategory.consistency,
    estimatedMinutes: 40,
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
    category: DrillCategory.technique,
    estimatedMinutes: 35,
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
    category: DrillCategory.equipment,
    estimatedMinutes: 40,
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
    category: DrillCategory.grouping,
    estimatedMinutes: 25,
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
    category: DrillCategory.matchPreparation,
    estimatedMinutes: 45,
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
    category: DrillCategory.reflection,
    estimatedMinutes: 25,
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
    category: DrillCategory.equipment,
    estimatedMinutes: 25,
  );

  static final naturalAlignmentCheck = DrillDefinition(
    id: 'natural-alignment-check',
    version: 1,
    name: 'Natuurlijke uitlijning controleren',
    objective:
        'Vergelijk een normale opbouw met een bewust gecontroleerde natuurlijke uitlijning.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 2,
    shotStructure: DrillShotStructure(shotsPerSeries: 5),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.absoluteBiasMm,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Bouw de eerste reeks op volgens je gewone routine.',
      'Controleer vóór de tweede reeks waar houding en steun natuurlijk terugkomen.',
      'Verplaats de volledige houding of steun; forceer de richting niet met extra spierspanning.',
      'Vergelijk groepscentrum én groepsgrootte, zonder één treffer als oorzaak te gebruiken.',
    ],
    safetyNote: _safety,
    category: DrillCategory.technique,
    estimatedMinutes: 20,
  );

  static final holdRestCycle = DrillDefinition(
    id: 'hold-rest-cycle',
    version: 1,
    name: 'Hold- en rustcyclus',
    objective:
        'Vind een herhaalbaar uitvoeringsvenster zonder een te lange houding te forceren.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 3,
    shotStructure: DrillShotStructure(
      description:
          'Gebruik par- of cadanssignalen voor opbouw en bewuste rust.',
    ),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.consistency,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Kies vooraf een comfortabele maximale opbouwtijd en rusttijd.',
      'Breek de opbouw veilig af wanneer het venster voorbij is.',
      'Gebruik dezelfde timing voor drie korte reeksen.',
      'Vergelijk consistentie en zelfevaluatie, niet alleen totaalscore.',
    ],
    safetyNote: _safety,
    category: DrillCategory.technique,
    estimatedMinutes: 25,
  );

  static final calledShot = DrillDefinition(
    id: 'called-shot-comparison',
    version: 1,
    name: 'Schotbeeld vooraf inschatten',
    objective:
        'Vergelijk wat je tijdens de uitvoering waarnam met het latere trefbeeld.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 3,
    shotStructure: DrillShotStructure(shotsPerSeries: 5),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.selfEvaluation,
      direction: DrillMetricDirection.complete,
    ),
    instructions: const [
      'Beoordeel na ieder schot alleen richting of kwaliteit die je werkelijk waarnam.',
      'Bekijk de kaart pas na de volledige korte reeks.',
      'Noteer overeenkomsten en verschillen zonder achteraf een oorzaak in te vullen.',
    ],
    safetyNote: _safety,
    category: DrillCategory.reflection,
    estimatedMinutes: 20,
  );

  static final shotRoutineReset = DrillDefinition(
    id: 'shot-routine-reset',
    version: 1,
    name: 'Routine en veilige reset',
    objective:
        'Oefen een korte herhaalbare routine én bewust afbreken wanneer de opbouw niet klopt.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 3,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.consistency,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Kies drie tot vijf korte controlepunten voor de opbouw.',
      'Breek minstens één keer bewust en veilig af vóór de eerste reeks.',
      'Gebruik dezelfde routine voor de volgende reeksen.',
      'Noteer alleen welke stap veranderde; maak geen diagnose uit de score.',
    ],
    safetyNote: _safety,
    category: DrillCategory.matchPreparation,
    estimatedMinutes: 30,
  );

  static final pressureSimulation = DrillDefinition(
    id: 'controlled-pressure-simulation',
    version: 1,
    name: 'Gecontroleerde druksimulatie',
    objective:
        'Vergelijk een normale reeks met een vooraf begrensde tijds- of scoreopdracht.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 4,
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.consistency,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Schiet eerst twee normale vergelijkbare reeksen.',
      'Kies één milde drukfactor, bijvoorbeeld een parsignaal of vooraf bepaald doel.',
      'Schiet twee reeksen met dezelfde kaart, afstand en uitrusting.',
      'Vergelijk uitvoering, spreiding en reflectie; de drukreeks hoeft niet hoger te scoren.',
    ],
    safetyNote: _safety,
    category: DrillCategory.matchPreparation,
    estimatedMinutes: 35,
  );

  static final benchrestReturn = DrillDefinition(
    id: 'benchrest-return-consistency',
    version: 1,
    name: 'Benchrest terugkeerconsistentie',
    objective:
        'Controleer of steun, contactpunten en terugkeer tussen korte reeksen gelijk blijven.',
    compatibleTargetKinds: TargetKind.values,
    recommendedSeries: 4,
    shotStructure: DrillShotStructure(shotsPerSeries: 5),
    successMetric: DrillSuccessMetric(
      metric: DrillMetric.consistency,
      direction: DrillMetricDirection.minimize,
    ),
    instructions: const [
      'Leg voor- en achtersteun en contactpunten vooraf vast.',
      'Wijzig niets tijdens de eerste twee reeksen.',
      'Herbouw daarna bewust dezelfde opstelling en schiet twee controlegroepen.',
      'Vergelijk groepscentrum en mean radius vóór en na de heropbouw.',
    ],
    safetyNote: _safety,
    category: DrillCategory.equipment,
    estimatedMinutes: 35,
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
    naturalAlignmentCheck,
    holdRestCycle,
    calledShot,
    shotRoutineReset,
    pressureSimulation,
    benchrestReturn,
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
