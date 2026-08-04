enum ExperimentVariable { firearm, ammoLot, position, sightSetting, other }

class ExperimentVariant {
  factory ExperimentVariant({
    required String id,
    required String label,
    String? details,
  }) => ExperimentVariant._(
    id: _requiredText(id, 'id'),
    label: _requiredText(label, 'label'),
    details: _optionalText(details),
  );

  const ExperimentVariant._({
    required this.id,
    required this.label,
    this.details,
  });

  final String id;
  final String label;
  final String? details;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'details': details,
  };

  factory ExperimentVariant.fromJson(Map<String, Object?> json) =>
      ExperimentVariant(
        id: json['id']! as String,
        label: json['label']! as String,
        details: json['details'] as String?,
      );
}

class ExperimentDefinition {
  factory ExperimentDefinition({
    required String id,
    required int version,
    required String name,
    required ExperimentVariable variable,
    required ExperimentVariant variantA,
    required ExperimentVariant variantB,
    required String targetProfileVersionedId,
    required double distanceMeters,
    int plannedBlocks = 3,
    int minimumSeriesPerVariant = 5,
    int minimumPositionedShotsPerVariant = 50,
  }) {
    if (version <= 0) {
      throw ArgumentError.value(version, 'version');
    }
    if (variantA.id == variantB.id) {
      throw ArgumentError('Variant A en B moeten verschillende ID’s hebben.');
    }
    if (!distanceMeters.isFinite || distanceMeters <= 0) {
      throw ArgumentError.value(distanceMeters, 'distanceMeters');
    }
    if (plannedBlocks <= 0) {
      throw ArgumentError.value(plannedBlocks, 'plannedBlocks');
    }
    if (minimumSeriesPerVariant <= 0) {
      throw ArgumentError.value(
        minimumSeriesPerVariant,
        'minimumSeriesPerVariant',
      );
    }
    if (minimumPositionedShotsPerVariant <= 0) {
      throw ArgumentError.value(
        minimumPositionedShotsPerVariant,
        'minimumPositionedShotsPerVariant',
      );
    }
    return ExperimentDefinition._(
      id: _requiredText(id, 'id'),
      version: version,
      name: _requiredText(name, 'name'),
      variable: variable,
      variantA: variantA,
      variantB: variantB,
      targetProfileVersionedId: _requiredText(
        targetProfileVersionedId,
        'targetProfileVersionedId',
      ),
      distanceMeters: distanceMeters,
      plannedBlocks: plannedBlocks,
      minimumSeriesPerVariant: minimumSeriesPerVariant,
      minimumPositionedShotsPerVariant: minimumPositionedShotsPerVariant,
    );
  }

  const ExperimentDefinition._({
    required this.id,
    required this.version,
    required this.name,
    required this.variable,
    required this.variantA,
    required this.variantB,
    required this.targetProfileVersionedId,
    required this.distanceMeters,
    required this.plannedBlocks,
    required this.minimumSeriesPerVariant,
    required this.minimumPositionedShotsPerVariant,
  });

  final String id;
  final int version;
  final String name;
  final ExperimentVariable variable;
  final ExperimentVariant variantA;
  final ExperimentVariant variantB;
  final String targetProfileVersionedId;
  final double distanceMeters;
  final int plannedBlocks;
  final int minimumSeriesPerVariant;
  final int minimumPositionedShotsPerVariant;

  String get versionedId => '$id@$version';

  Map<String, Object> toJson() => {
    'id': id,
    'version': version,
    'name': name,
    'variable': variable.name,
    'variantA': variantA.toJson(),
    'variantB': variantB.toJson(),
    'targetProfileVersionedId': targetProfileVersionedId,
    'distanceMeters': distanceMeters,
    'plannedBlocks': plannedBlocks,
    'minimumSeriesPerVariant': minimumSeriesPerVariant,
    'minimumPositionedShotsPerVariant': minimumPositionedShotsPerVariant,
  };

  factory ExperimentDefinition.fromJson(Map<String, Object?> json) =>
      ExperimentDefinition(
        id: json['id']! as String,
        version: json['version']! as int,
        name: json['name']! as String,
        variable: ExperimentVariable.values.byName(json['variable']! as String),
        variantA: ExperimentVariant.fromJson(
          (json['variantA']! as Map).cast<String, Object?>(),
        ),
        variantB: ExperimentVariant.fromJson(
          (json['variantB']! as Map).cast<String, Object?>(),
        ),
        targetProfileVersionedId: json['targetProfileVersionedId']! as String,
        distanceMeters: (json['distanceMeters']! as num).toDouble(),
        plannedBlocks: json['plannedBlocks']! as int,
        minimumSeriesPerVariant: json['minimumSeriesPerVariant']! as int,
        minimumPositionedShotsPerVariant:
            json['minimumPositionedShotsPerVariant']! as int,
      );
}

class ExperimentAssignment {
  const ExperimentAssignment({
    required this.sequenceNumber,
    required this.blockNumber,
    required this.positionInBlock,
    required this.variantId,
  });

  final int sequenceNumber;
  final int blockNumber;
  final int positionInBlock;
  final String variantId;

  Map<String, Object> toJson() => {
    'sequenceNumber': sequenceNumber,
    'blockNumber': blockNumber,
    'positionInBlock': positionInBlock,
    'variantId': variantId,
  };

  factory ExperimentAssignment.fromJson(Map<String, Object?> json) =>
      ExperimentAssignment(
        sequenceNumber: json['sequenceNumber']! as int,
        blockNumber: json['blockNumber']! as int,
        positionInBlock: json['positionInBlock']! as int,
        variantId: json['variantId']! as String,
      );
}

class ExperimentPlan {
  ExperimentPlan({
    required this.definitionVersionedId,
    required Iterable<ExperimentAssignment> assignments,
  }) : assignments = List.unmodifiable(assignments);

  final String definitionVersionedId;
  final List<ExperimentAssignment> assignments;

  Map<String, Object> toJson() => {
    'definitionVersionedId': definitionVersionedId,
    'assignments': assignments
        .map((assignment) => assignment.toJson())
        .toList(),
  };

  factory ExperimentPlan.fromJson(Map<String, Object?> json) => ExperimentPlan(
    definitionVersionedId: json['definitionVersionedId']! as String,
    assignments: (json['assignments']! as List<Object?>).map(
      (value) => ExperimentAssignment.fromJson(
        (value! as Map).cast<String, Object?>(),
      ),
    ),
  );
}

abstract final class ExperimentPlanner {
  /// Creates deterministic balanced blocks in the order A-B-B-A.
  static ExperimentPlan create(ExperimentDefinition definition) {
    final pattern = [
      definition.variantA.id,
      definition.variantB.id,
      definition.variantB.id,
      definition.variantA.id,
    ];
    final assignments = <ExperimentAssignment>[];
    for (var block = 0; block < definition.plannedBlocks; block++) {
      for (var position = 0; position < pattern.length; position++) {
        assignments.add(
          ExperimentAssignment(
            sequenceNumber: assignments.length + 1,
            blockNumber: block + 1,
            positionInBlock: position + 1,
            variantId: pattern[position],
          ),
        );
      }
    }
    return ExperimentPlan(
      definitionVersionedId: definition.versionedId,
      assignments: assignments,
    );
  }
}

class ExperimentSample {
  const ExperimentSample({
    required this.variantId,
    required this.positionedShotCount,
  }) : assert(positionedShotCount >= 0);

  final String variantId;
  final int positionedShotCount;
}

enum ExperimentDataState {
  notStarted,
  collectingBoth,
  collectingVariantA,
  collectingVariantB,
  sufficient,
}

class VariantDataProgress {
  const VariantDataProgress({
    required this.variantId,
    required this.seriesCount,
    required this.positionedShotCount,
    required this.missingSeriesCount,
    required this.missingPositionedShotCount,
  });

  final String variantId;
  final int seriesCount;
  final int positionedShotCount;
  final int missingSeriesCount;
  final int missingPositionedShotCount;

  bool get minimumReached =>
      missingSeriesCount == 0 && missingPositionedShotCount == 0;
}

class ExperimentMinimumDataStatus {
  const ExperimentMinimumDataStatus({
    required this.state,
    required this.variantA,
    required this.variantB,
  });

  final ExperimentDataState state;
  final VariantDataProgress variantA;
  final VariantDataProgress variantB;

  bool get isSufficient => state == ExperimentDataState.sufficient;
}

abstract final class ExperimentEvaluator {
  static ExperimentMinimumDataStatus minimumDataStatus(
    ExperimentDefinition definition,
    Iterable<ExperimentSample> samples,
  ) {
    var seriesA = 0;
    var seriesB = 0;
    var shotsA = 0;
    var shotsB = 0;
    for (final sample in samples) {
      if (sample.positionedShotCount < 0) {
        throw ArgumentError.value(
          sample.positionedShotCount,
          'sample.positionedShotCount',
        );
      }
      if (sample.variantId == definition.variantA.id) {
        seriesA++;
        shotsA += sample.positionedShotCount;
      } else if (sample.variantId == definition.variantB.id) {
        seriesB++;
        shotsB += sample.positionedShotCount;
      } else {
        throw ArgumentError.value(
          sample.variantId,
          'sample.variantId',
          'De steekproef hoort niet bij dit experiment.',
        );
      }
    }

    VariantDataProgress progress(String variantId, int series, int shots) =>
        VariantDataProgress(
          variantId: variantId,
          seriesCount: series,
          positionedShotCount: shots,
          missingSeriesCount: (definition.minimumSeriesPerVariant - series)
              .clamp(0, definition.minimumSeriesPerVariant),
          missingPositionedShotCount:
              (definition.minimumPositionedShotsPerVariant - shots).clamp(
                0,
                definition.minimumPositionedShotsPerVariant,
              ),
        );

    final a = progress(definition.variantA.id, seriesA, shotsA);
    final b = progress(definition.variantB.id, seriesB, shotsB);
    final state = switch ((
      seriesA + seriesB,
      a.minimumReached,
      b.minimumReached,
    )) {
      (0, _, _) => ExperimentDataState.notStarted,
      (_, true, true) => ExperimentDataState.sufficient,
      (_, false, true) => ExperimentDataState.collectingVariantA,
      (_, true, false) => ExperimentDataState.collectingVariantB,
      _ => ExperimentDataState.collectingBoth,
    };
    return ExperimentMinimumDataStatus(state: state, variantA: a, variantB: b);
  }
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String? _optionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
