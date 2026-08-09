import 'models.dart';

class DomainValidationIssue {
  const DomainValidationIssue({
    required this.code,
    required this.field,
    required this.message,
  });

  final String code;
  final String field;
  final String message;

  @override
  String toString() => '$field: $message';
}

class DomainValidationResult {
  DomainValidationResult(Iterable<DomainValidationIssue> issues)
    : issues = List.unmodifiable(issues);

  final List<DomainValidationIssue> issues;

  bool get isValid => issues.isEmpty;

  void requireValid({String argumentName = 'value'}) {
    if (isValid) return;
    throw ArgumentError.value(
      argumentName,
      argumentName,
      issues.map((issue) => issue.toString()).join('; '),
    );
  }
}

abstract final class DomainValidators {
  static DomainValidationResult targetProfile(TargetProfile target) {
    final issues = <DomainValidationIssue>[];

    void add(String code, String field, String message) {
      issues.add(
        DomainValidationIssue(code: code, field: field, message: message),
      );
    }

    if (target.schemaVersion < 1) {
      add('schema_version', 'schemaVersion', 'Moet minstens 1 zijn.');
    }
    if (target.profileVersion < 1) {
      add('profile_version', 'profileVersion', 'Moet minstens 1 zijn.');
    }
    if (target.profileId.trim().isEmpty) {
      add('profile_id', 'profileId', 'Mag niet leeg zijn.');
    }
    if (target.displayName.trim().isEmpty) {
      add('display_name', 'displayName', 'Mag niet leeg zijn.');
    }
    if (!_isFinitePositive(target.physicalCardWidthMm)) {
      add(
        'card_width',
        'physicalCardWidthMm',
        'Moet eindig en groter dan nul zijn.',
      );
    }
    if (!_isFinitePositive(target.physicalCardHeightMm)) {
      add(
        'card_height',
        'physicalCardHeightMm',
        'Moet eindig en groter dan nul zijn.',
      );
    }
    if (!target.lineThicknessMm.isFinite || target.lineThicknessMm < 0) {
      add(
        'line_thickness',
        'lineThicknessMm',
        'Moet eindig en minstens nul zijn.',
      );
    }
    if (target.rings.isEmpty) {
      add('rings_empty', 'rings', 'Minstens een scoringsring is vereist.');
    }

    final ringValues = <int>{};
    var previousDiameter = 0.0;
    for (var index = 0; index < target.rings.length; index++) {
      final ring = target.rings[index];
      if (ring.value <= 0) {
        add('ring_value', 'rings[$index].value', 'Moet groter dan nul zijn.');
      }
      if (!ringValues.add(ring.value)) {
        add(
          'ring_value_duplicate',
          'rings[$index].value',
          'Ringwaarden moeten uniek zijn.',
        );
      }
      if (!_isFinitePositive(ring.outerDiameterMm)) {
        add(
          'ring_diameter',
          'rings[$index].outerDiameterMm',
          'Moet eindig en groter dan nul zijn.',
        );
      } else if (index > 0 && ring.outerDiameterMm <= previousDiameter) {
        add(
          'ring_order',
          'rings[$index].outerDiameterMm',
          'Lagere scores moeten een strikt grotere diameter hebben.',
        );
      }
      previousDiameter = ring.outerDiameterMm;
    }

    if (target.rings.isNotEmpty &&
        target.physicalCardWidthMm.isFinite &&
        target.physicalCardHeightMm.isFinite) {
      final outerDiameter = target.rings.last.outerDiameterMm;
      final cardMinimum =
          target.physicalCardWidthMm < target.physicalCardHeightMm
          ? target.physicalCardWidthMm
          : target.physicalCardHeightMm;
      if (outerDiameter.isFinite && outerDiameter > cardMinimum) {
        add(
          'outer_ring_outside_card',
          'rings',
          'De buitenste ring moet binnen de fysieke kaart vallen.',
        );
      }
    }

    final innerTen = target.innerTenDiameterMm;
    if (innerTen != null) {
      if (!_isFinitePositive(innerTen)) {
        add(
          'inner_ten',
          'innerTenDiameterMm',
          'Moet eindig en groter dan nul zijn.',
        );
      } else if (target.rings.isNotEmpty &&
          innerTen > target.rings.first.outerDiameterMm) {
        add(
          'inner_ten_outside_ten',
          'innerTenDiameterMm',
          'Mag niet groter zijn dan de hoogste scoringsring.',
        );
      }
    }

    final black = target.blackOuterDiameterMm;
    if (black != null) {
      if (!_isFinitePositive(black)) {
        add(
          'black_diameter',
          'blackOuterDiameterMm',
          'Moet eindig en groter dan nul zijn.',
        );
      } else if (target.rings.isNotEmpty &&
          black > target.rings.last.outerDiameterMm) {
        add(
          'black_outside_target',
          'blackOuterDiameterMm',
          'Mag niet groter zijn dan de buitenste scoringsring.',
        );
      }
    }

    final distances = <double>{};
    for (
      var index = 0;
      index < target.supportedDistancesMeters.length;
      index++
    ) {
      final distance = target.supportedDistancesMeters[index];
      if (!_isFinitePositive(distance)) {
        add(
          'supported_distance',
          'supportedDistancesMeters[$index]',
          'Moet eindig en groter dan nul zijn.',
        );
      } else if (!distances.add(distance)) {
        add(
          'supported_distance_duplicate',
          'supportedDistancesMeters[$index]',
          'Afstanden moeten uniek zijn.',
        );
      }
    }
    final defaultDistance = target.defaultDistanceMeters;
    if (defaultDistance != null && !_isFinitePositive(defaultDistance)) {
      add(
        'default_distance',
        'defaultDistanceMeters',
        'Moet eindig en groter dan nul zijn.',
      );
    } else if (defaultDistance != null &&
        distances.isNotEmpty &&
        !distances.contains(defaultDistance)) {
      add(
        'default_distance_unsupported',
        'defaultDistanceMeters',
        'Moet in supportedDistancesMeters voorkomen.',
      );
    }

    final bullIds = <String>{};
    for (var index = 0; index < target.bulls.length; index++) {
      final bull = target.bulls[index];
      if (bull.id.trim().isEmpty) {
        add('bull_id', 'bulls[$index].id', 'Mag niet leeg zijn.');
      } else if (!bullIds.add(bull.id)) {
        add(
          'bull_id_duplicate',
          'bulls[$index].id',
          'Bull-ID’s moeten uniek zijn.',
        );
      }
      if (!bull.centerXMm.isFinite || !bull.centerYMm.isFinite) {
        add(
          'bull_center',
          'bulls[$index]',
          'Het bullcentrum moet eindig zijn.',
        );
      }
      if (!_isFinitePositive(bull.scoringWidthMm) ||
          !_isFinitePositive(bull.scoringHeightMm)) {
        add(
          'bull_bounds',
          'bulls[$index]',
          'Scoringsafmetingen moeten eindig en groter dan nul zijn.',
        );
      } else if (target.rings.isNotEmpty &&
          (bull.scoringWidthMm < target.rings.last.outerDiameterMm ||
              bull.scoringHeightMm < target.rings.last.outerDiameterMm)) {
        add(
          'bull_too_small_for_rings',
          'bulls[$index]',
          'Het scoringsgebied moet de volledige buitenste ring bevatten.',
        );
      }
      if (target.physicalCardWidthMm.isFinite &&
          target.physicalCardHeightMm.isFinite &&
          bull.centerXMm.isFinite &&
          bull.centerYMm.isFinite &&
          bull.scoringWidthMm.isFinite &&
          bull.scoringHeightMm.isFinite &&
          (bull.centerXMm.abs() + bull.scoringWidthMm / 2 >
                  target.physicalCardWidthMm / 2 ||
              bull.centerYMm.abs() + bull.scoringHeightMm / 2 >
                  target.physicalCardHeightMm / 2)) {
        add(
          'bull_outside_card',
          'bulls[$index]',
          'Het scoringsgebied moet binnen de kaart vallen.',
        );
      }
    }

    final records = target.recordBulls;
    for (var first = 0; first < records.length; first++) {
      for (var second = first + 1; second < records.length; second++) {
        if (_rectanglesOverlap(records[first], records[second])) {
          add(
            'record_bulls_overlap',
            'bulls',
            'Recordbulls ${records[first].id} en ${records[second].id} '
                'hebben een ambigu overlappend scoringsgebied.',
          );
        }
      }
    }

    if (target.targetKind == TargetKind.multiBullConcentric) {
      if (target.schemaVersion < 2) {
        add(
          'multi_bull_schema_version',
          'schemaVersion',
          'Een multi-bullprofiel vereist schemaVersion 2 of hoger.',
        );
      }
      final policy = target.multiBullScoringPolicy;
      if (policy == null) {
        add(
          'multi_bull_policy',
          'multiBullScoringPolicy',
          'Een multi-bullprofiel vereist een scorebeleid.',
        );
      }
      if (records.isEmpty) {
        add(
          'record_bulls_empty',
          'bulls',
          'Een multi-bullprofiel vereist minstens een recordbull.',
        );
      }
      if (policy != null) {
        if (policy.recordBullCount != records.length) {
          add(
            'record_bull_count',
            'multiBullScoringPolicy.recordBullCount',
            'Moet gelijk zijn aan het aantal recordbulls.',
          );
        }
        if (policy.maximumShotsPerBull < 1) {
          add(
            'maximum_shots_per_bull',
            'multiBullScoringPolicy.maximumShotsPerBull',
            'Moet minstens 1 zijn.',
          );
        } else if (policy.duplicatePolicy ==
                DuplicateShotPolicy.lowestScoreCounts &&
            policy.maximumShotsPerBull != 1) {
          add(
            'unsupported_maximum_shots_per_bull',
            'multiBullScoringPolicy.maximumShotsPerBull',
            'lowestScoreCounts ondersteunt precies één tellend schot per bull.',
          );
        }
        if (policy.excessShotPenalty < 0) {
          add(
            'excess_shot_penalty',
            'multiBullScoringPolicy.excessShotPenalty',
            'Mag niet negatief zijn.',
          );
        }
        if (policy.fixedMaximumScore <= 0) {
          add(
            'fixed_maximum_score',
            'multiBullScoringPolicy.fixedMaximumScore',
            'Moet groter dan nul zijn.',
          );
        } else if (target.maximumScore > 0 &&
            policy.fixedMaximumScore !=
                policy.recordBullCount * target.maximumScore) {
          add(
            'fixed_maximum_score_mismatch',
            'multiBullScoringPolicy.fixedMaximumScore',
            'Moet recordBullCount maal de maximale ringwaarde zijn.',
          );
        }
      }
    } else {
      if (target.bulls.isNotEmpty) {
        add(
          'single_bull_has_bulls',
          'bulls',
          'Een concentrisch enkeldoel mag geen multi-bullgeometrie bevatten.',
        );
      }
      if (target.multiBullScoringPolicy != null) {
        add(
          'single_bull_has_policy',
          'multiBullScoringPolicy',
          'Een concentrisch enkeldoel mag geen multi-bullscorebeleid bevatten.',
        );
      }
    }

    return DomainValidationResult(issues);
  }

  static DomainValidationResult shotImpact(ShotImpact impact) {
    final issues = <DomainValidationIssue>[];

    void add(String code, String field, String message) {
      issues.add(
        DomainValidationIssue(code: code, field: field, message: message),
      );
    }

    if (impact.id.trim().isEmpty) {
      add('impact_id', 'id', 'Mag niet leeg zijn.');
    }
    if (!impact.xMm.isFinite || !impact.yMm.isFinite) {
      add('impact_position', 'position', 'Coordinaten moeten eindig zijn.');
    }
    if (impact.multiplicity < 1) {
      add('impact_multiplicity', 'multiplicity', 'Moet minstens 1 zijn.');
    }
    final imageX = impact.imageXNormalized;
    final imageY = impact.imageYNormalized;
    if ((imageX == null) != (imageY == null)) {
      add(
        'impact_image_coordinates_pair',
        'imageCoordinates',
        'Genormaliseerde fotocoordinaten moeten samen aanwezig zijn.',
      );
    }
    if (imageX != null && (!imageX.isFinite || imageX < 0 || imageX > 1)) {
      add(
        'impact_image_x',
        'imageXNormalized',
        'Moet eindig en tussen 0 en 1 liggen.',
      );
    }
    if (imageY != null && (!imageY.isFinite || imageY < 0 || imageY > 1)) {
      add(
        'impact_image_y',
        'imageYNormalized',
        'Moet eindig en tussen 0 en 1 liggen.',
      );
    }
    final uncertainty = impact.positionalUncertaintyMm;
    if (uncertainty != null && (!uncertainty.isFinite || uncertainty < 0)) {
      add(
        'impact_uncertainty',
        'positionalUncertaintyMm',
        'Moet eindig en minstens nul zijn.',
      );
    }

    return DomainValidationResult(issues);
  }

  static bool _isFinitePositive(double value) => value.isFinite && value > 0;

  static bool _rectanglesOverlap(TargetBull first, TargetBull second) =>
      (first.centerXMm - second.centerXMm).abs() <=
          (first.scoringWidthMm + second.scoringWidthMm) / 2 &&
      (first.centerYMm - second.centerYMm).abs() <=
          (first.scoringHeightMm + second.scoringHeightMm) / 2;
}

extension TargetProfileRuntimeValidation on TargetProfile {
  DomainValidationResult validateRuntime() =>
      DomainValidators.targetProfile(this);
}

extension ShotImpactRuntimeValidation on ShotImpact {
  DomainValidationResult validateRuntime() => DomainValidators.shotImpact(this);
}
