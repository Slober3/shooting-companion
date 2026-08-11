import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_training/training.dart';

import '../data/app_database.dart';
import '../data/timer_preset_defaults.dart';
import '../data/training_activity_snapshot_validator.dart';

typedef BackupDirectoryProvider = Future<Directory> Function();

class BackupSummary {
  const BackupSummary({
    required this.createdAtUtc,
    required this.sessionCount,
    required this.seriesCount,
    required this.imageCount,
    this.formatVersion = BackupPayloadAdapter.currentFormatVersion,
  });

  final DateTime createdAtUtc;
  final int sessionCount;
  final int seriesCount;
  final int imageCount;
  final int formatVersion;
}

class RestoreResult {
  const RestoreResult({required this.summary, required this.safetyBackup});

  final BackupSummary summary;
  final File safetyBackup;
}

/// A validated, platform-independent representation of database.json.
///
/// The adapter is intentionally independent from Drift and file I/O. This keeps
/// the v1 compatibility rules deterministic and directly unit-testable.
class NormalizedBackupPayload {
  const NormalizedBackupPayload({
    required this.sourceFormatVersion,
    required this.manifest,
    required this.data,
  });

  final int sourceFormatVersion;
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> data;

  BackupSummary get summary => BackupSummary(
    createdAtUtc: DateTime.parse(manifest['createdAtUtc'] as String).toUtc(),
    sessionCount: manifest['sessionCount'] as int,
    seriesCount: manifest['seriesCount'] as int,
    imageCount: manifest['imageCount'] as int,
    formatVersion: sourceFormatVersion,
  );
}

/// Converts every supported SCB1 payload to the schema-8 JSON shape.
class BackupPayloadAdapter {
  const BackupPayloadAdapter._();

  static const currentFormatVersion = 8;
  static const _formatName = 'shooting-companion-backup';

  static NormalizedBackupPayload normalize({
    required Map<String, dynamic> manifest,
    required Map<String, dynamic> data,
  }) {
    if (manifest['format'] != _formatName) {
      throw const FormatException('Onbekend back-upformaat.');
    }
    final version = _integer(manifest['formatVersion'], 'formatVersion');
    if (version < 1 || version > currentFormatVersion) {
      throw const FormatException('Niet-ondersteunde back-upversie.');
    }
    final createdAt = manifest['createdAtUtc'];
    if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
      throw const FormatException('Ongeldige aanmaakdatum in manifest.');
    }

    final normalized = switch (version) {
      1 => _upgradeV8(
        _upgradeV7(
          _upgradeV6(_upgradeV5(_upgradeV4(_upgradeV2(_upgradeV1(data))))),
        ),
      ),
      2 => _upgradeV8(
        _upgradeV7(_upgradeV6(_upgradeV5(_upgradeV4(_upgradeV2(data))))),
      ),
      3 => _upgradeV8(
        _upgradeV7(_upgradeV6(_upgradeV5(_upgradeV4(_normalizeV3(data))))),
      ),
      4 => _upgradeV8(_upgradeV7(_upgradeV6(_upgradeV5(_normalizeV4(data))))),
      5 => _upgradeV8(_upgradeV7(_upgradeV6(_normalizeV5(data)))),
      6 => _upgradeV8(_upgradeV7(_normalizeV6(data))),
      7 => _upgradeV8(_normalizeV7(data)),
      _ => _normalizeV8(data),
    };
    final sessionCount = _integer(manifest['sessionCount'], 'sessionCount');
    final seriesCount = _integer(manifest['seriesCount'], 'seriesCount');
    final imageCount = _integer(manifest['imageCount'], 'imageCount');
    if (sessionCount != (normalized['sessions']! as List).length ||
        seriesCount != (normalized['series']! as List).length ||
        imageCount != (normalized['images']! as List).length) {
      throw const FormatException(
        'Recordaantallen in het manifest komen niet overeen.',
      );
    }
    _validateDomainRecords(normalized);

    return NormalizedBackupPayload(
      sourceFormatVersion: version,
      manifest: Map<String, dynamic>.from(manifest),
      data: normalized,
    );
  }

  static Map<String, dynamic> _normalizeV2(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final key in _v2Tables) {
      result[key] = _table(data, key);
    }
    return result;
  }

  static Map<String, dynamic> _normalizeV3(Map<String, dynamic> data) {
    final result = _normalizeV2(data);
    _validateLibraryRelations(result);
    return result;
  }

  static Map<String, dynamic> _normalizeV4(Map<String, dynamic> data) {
    final result = _normalizeV3(data);
    _validateBullReferences(result);
    return result;
  }

  static Map<String, dynamic> _normalizeV5(Map<String, dynamic> data) {
    final result = _normalizeV4(data);
    result['seriesReflections'] = _table(data, 'seriesReflections');
    result['coachFeedback'] = _table(data, 'coachFeedback');
    _validateInsightRelations(result);
    return result;
  }

  static Map<String, dynamic> _normalizeV6(Map<String, dynamic> data) {
    final result = _normalizeV5(data);
    result['trainingActivities'] = _table(data, 'trainingActivities');
    result['trainingActivitySeriesLinks'] = _table(
      data,
      'trainingActivitySeriesLinks',
    );
    result['shotTimerEvents'] = _table(data, 'shotTimerEvents');
    result['timerPresets'] = _table(data, 'timerPresets');
    result['acousticCalibrationProfiles'] = _table(
      data,
      'acousticCalibrationProfiles',
    );
    _validateTrainingRelations(result);
    return result;
  }

  static Map<String, dynamic> _normalizeV7(Map<String, dynamic> data) {
    final result = _normalizeV6(data);
    result['visionScanDrafts'] = _table(data, 'visionScanDrafts');
    result['visionAnalyses'] = _table(data, 'visionAnalyses');
    _validateVisionRelations(result);
    return result;
  }

  static Map<String, dynamic> _normalizeV8(Map<String, dynamic> data) {
    final result = _normalizeV7(data);
    _validateAlignmentV8(result);
    return result;
  }

  static Map<String, dynamic> _upgradeV8(Map<String, dynamic> data) {
    final result = <String, dynamic>{
      for (final entry in data.entries) entry.key: entry.value,
    };
    result['photoAlignments'] = (result['photoAlignments']! as List).map((
      value,
    ) {
      final row = Map<String, dynamic>.from(value as Map);
      return row
        ..['rotationQuarterTurns'] = 0
        ..['alignmentMode'] = 'fullCard'
        ..['anchorsJson'] = row['cornersJson']
        ..['reprojectionRmsMm'] = null
        ..['reprojectionMaxMm'] = null
        ..['planarityStatus'] = 'unknown'
        ..['confirmedAtUtc'] = row['updatedAtUtc'];
    }).toList();
    result['visionScanDrafts'] = (result['visionScanDrafts']! as List).map((
      value,
    ) {
      final row = Map<String, dynamic>.from(value as Map);
      return row
        ..['rotationQuarterTurns'] = 0
        ..['alignmentMode'] = 'fullCard'
        ..['anchorsJson'] = null
        ..['reprojectionRmsMm'] = null
        ..['reprojectionMaxMm'] = null
        ..['planarityStatus'] = 'unknown'
        ..['alignmentAlgorithmVersion'] = null
        ..['alignmentConfirmedAtUtc'] = null;
    }).toList();
    _validateAlignmentV8(result);
    return result;
  }

  static void _validateAlignmentV8(Map<String, dynamic> data) {
    const modes = {'fullCard', 'ringAssisted', 'drawnTarget'};
    const planarity = {'accepted', 'manualReviewOnly', 'rejected', 'unknown'};
    for (final value in data['photoAlignments']! as List) {
      final row = value as Map;
      final rotation = row['rotationQuarterTurns'];
      final mode = row['alignmentMode'];
      final status = row['planarityStatus'];
      if (rotation is! int ||
          rotation < 0 ||
          rotation > 3 ||
          mode is! String ||
          !modes.contains(mode) ||
          status is! String ||
          !planarity.contains(status) ||
          !_nullableFiniteNonNegative(row['reprojectionRmsMm']) ||
          !_nullableFiniteNonNegative(row['reprojectionMaxMm'])) {
        throw const FormatException('Foto-uitlijning versie 8 is ongeldig.');
      }
    }
    for (final value in data['visionScanDrafts']! as List) {
      final row = value as Map;
      final rotation = row['rotationQuarterTurns'];
      final mode = row['alignmentMode'];
      final status = row['planarityStatus'];
      if (rotation is! int ||
          rotation < 0 ||
          rotation > 3 ||
          mode is! String ||
          !modes.contains(mode) ||
          status is! String ||
          !planarity.contains(status) ||
          !_nullableFiniteNonNegative(row['reprojectionRmsMm']) ||
          !_nullableFiniteNonNegative(row['reprojectionMaxMm'])) {
        throw const FormatException('Visionconcept versie 8 is ongeldig.');
      }
    }
  }

  static bool _nullableFiniteNonNegative(Object? value) =>
      value == null || (value is num && value.isFinite && value >= 0);

  /// Enforces the same runtime invariants used by repositories and scoring at
  /// the point where untrusted backup JSON enters the application.
  ///
  /// Historical v1 series snapshots did not yet contain the complete target
  /// schema. Those snapshots retain a deliberately narrow compatibility path:
  /// their ring values are validated, but absent geometry is never invented.
  static void _validateDomainRecords(Map<String, dynamic> data) {
    final profilesBySeries = <String, domain.TargetProfile?>{};
    final seriesIds = <String>{};
    for (final value in data['series']! as List) {
      final row = value as Map;
      final seriesId = row['id'];
      if (seriesId is! String ||
          seriesId.trim().isEmpty ||
          !seriesIds.add(seriesId)) {
        throw const FormatException('Reeks-ID is leeg of dubbel opgeslagen.');
      }
      final snapshot = row['targetProfileJson'];
      final target = _validatedTargetSnapshot(
        snapshot,
        context: 'Reeks $seriesId',
        allowLegacySnapshot: true,
      );
      final storedVersionedId = row['targetProfileVersionedId'];
      if (storedVersionedId is! String ||
          storedVersionedId.trim().isEmpty ||
          (target != null && storedVersionedId != target.versionedId)) {
        throw const FormatException(
          'Reeks verwijst niet naar het opgeslagen doelprofielsnapshot.',
        );
      }
      final distance = row['distanceMeters'];
      final projectileDiameter = row['projectileDiameterMm'];
      if (distance is! num ||
          !distance.isFinite ||
          distance <= 0 ||
          projectileDiameter is! num ||
          !projectileDiameter.isFinite ||
          projectileDiameter <= 0) {
        throw const FormatException(
          'Reeks bevat een ongeldige afstand of projectieldiameter.',
        );
      }
      profilesBySeries[seriesId] = target;
    }

    final targetProfileIds = <String>{};
    for (final value in data['targetProfiles']! as List) {
      final row = value as Map;
      final versionedId = row['versionedId'];
      if (versionedId is! String ||
          versionedId.trim().isEmpty ||
          !targetProfileIds.add(versionedId)) {
        throw const FormatException(
          'Doelprofiel-ID is leeg of dubbel opgeslagen.',
        );
      }
      final target = _validatedTargetSnapshot(
        row['profileJson'],
        context: 'Bibliotheekprofiel $versionedId',
      );
      if (target == null ||
          target.versionedId != versionedId ||
          row['profileId'] != target.profileId ||
          row['profileVersion'] != target.profileVersion) {
        throw const FormatException(
          'Bibliotheekprofiel en profielmetadata komen niet overeen.',
        );
      }
    }

    for (final value in data['visionScanDrafts']! as List) {
      final row = value as Map;
      _validatedTargetSnapshot(
        row['targetProfileJson'],
        context: 'Visionconcept ${row['id']}',
      );
      final projectileDiameter = row['projectileDiameterMm'];
      if (projectileDiameter is! num ||
          !projectileDiameter.isFinite ||
          projectileDiameter <= 0) {
        throw const FormatException(
          'Visionconcept bevat een ongeldige projectieldiameter.',
        );
      }
    }

    final impactIds = <String>{};
    for (final value in data['impacts']! as List) {
      final row = value as Map;
      final id = row['id'];
      final seriesId = row['seriesId'];
      if (id is! String || id.trim().isEmpty || !impactIds.add(id)) {
        throw const FormatException('Treffer-ID is leeg of dubbel opgeslagen.');
      }
      if (seriesId is! String || !profilesBySeries.containsKey(seriesId)) {
        throw const FormatException(
          'Treffer verwijst naar een onbekende reeks.',
        );
      }

      final impact = _validatedImpact(row);
      final target = profilesBySeries[seriesId];
      if (target == null) {
        // A legacy v1 target has no bull geometry. Its impacts can therefore
        // only be valid when they do not claim a bull assignment.
        if (impact.targetBullId != null) {
          throw const FormatException(
            'Legacytreffer bevat een niet-controleerbaar doelroosje.',
          );
        }
        continue;
      }
      _validateImpactBull(target, impact);
    }
  }

  static domain.TargetProfile? _validatedTargetSnapshot(
    Object? source, {
    required String context,
    bool allowLegacySnapshot = false,
  }) {
    if (source is! String) {
      throw FormatException('$context bevat geen doelprofielsnapshot.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw FormatException('$context bevat ongeldige doelprofiel-JSON.');
    }
    if (decoded is! Map) {
      throw FormatException('$context bevat geen doelprofielobject.');
    }
    final json = decoded.cast<String, Object?>();
    if (allowLegacySnapshot && !json.containsKey('schemaVersion')) {
      _validateLegacyTargetSnapshot(json, context);
      return null;
    }

    domain.TargetProfile target;
    try {
      target = domain.TargetProfile.fromJson(json);
    } on Object {
      throw FormatException(
        '$context kan niet als doelprofiel worden gelezen.',
      );
    }
    final validation = target.validateRuntime();
    if (!validation.isValid) {
      throw FormatException(
        '$context is ongeldig: '
        '${validation.issues.map((issue) => issue.toString()).join('; ')}',
      );
    }
    return target;
  }

  static void _validateLegacyTargetSnapshot(
    Map<String, Object?> json,
    String context,
  ) {
    final rings = json['rings'];
    if (rings is! List || rings.isEmpty) {
      throw FormatException('$context bevat geen scoringsringen.');
    }
    final values = <int>{};
    for (final value in rings) {
      if (value is! Map) {
        throw FormatException('$context bevat een ongeldige scoringsring.');
      }
      final score = value['value'];
      if (score is! int || score <= 0 || !values.add(score)) {
        throw FormatException(
          '$context bevat ongeldige of dubbele ringwaarden.',
        );
      }
      final diameter = value['outerDiameterMm'];
      if (diameter != null &&
          (diameter is! num || !diameter.isFinite || diameter <= 0)) {
        throw FormatException('$context bevat een ongeldige ringdiameter.');
      }
    }
  }

  static domain.ShotImpact _validatedImpact(Map row) {
    final xMm = _finiteDouble(row['xMm'], 'xMm');
    final yMm = _finiteDouble(row['yMm'], 'yMm');
    final multiplicity = row['multiplicity'];
    final imageX = _nullableFiniteDouble(
      row['imageXNormalized'],
      'imageXNormalized',
    );
    final imageY = _nullableFiniteDouble(
      row['imageYNormalized'],
      'imageYNormalized',
    );
    final uncertainty = _nullableFiniteDouble(
      row['positionalUncertaintyMm'],
      'positionalUncertaintyMm',
    );
    final sourceImageId = row['sourceImageId'];
    final visionAnalysisId = row['visionAnalysisId'];
    final targetBullId = row['targetBullId'];
    final rawScoreValue = row['rawScoreValue'];
    if (multiplicity is! int ||
        multiplicity < 1 ||
        row['isMiss'] is! bool ||
        row['isPositionUncertain'] is! bool ||
        (sourceImageId != null && sourceImageId is! String) ||
        (visionAnalysisId != null && visionAnalysisId is! String) ||
        (targetBullId != null && targetBullId is! String) ||
        (rawScoreValue != null && rawScoreValue is! int) ||
        (imageX == null) != (imageY == null) ||
        (imageX != null && (imageX < 0 || imageX > 1)) ||
        (imageY != null && (imageY < 0 || imageY > 1)) ||
        (uncertainty != null && uncertainty < 0)) {
      throw const FormatException('Trefferrecord bevat ongeldige waarden.');
    }

    domain.ScoreDisposition disposition;
    domain.ImpactPlacementMethod placementMethod;
    try {
      disposition = domain.ScoreDisposition.values.byName(
        row['scoreDisposition'] as String,
      );
      placementMethod = domain.ImpactPlacementMethod.values.byName(
        row['placementMethod'] as String,
      );
    } on Object {
      throw const FormatException('Trefferrecord bevat een ongeldige status.');
    }

    final impact = domain.ShotImpact(
      id: row['id']! as String,
      xMm: xMm,
      yMm: yMm,
      sourceImageId: sourceImageId as String?,
      imageXNormalized: imageX,
      imageYNormalized: imageY,
      multiplicity: multiplicity,
      isMiss: row['isMiss']! as bool,
      isPositionUncertain: row['isPositionUncertain']! as bool,
      targetBullId: targetBullId as String?,
      rawScoreValue: rawScoreValue as int?,
      scoreDisposition: disposition,
      placementMethod: placementMethod,
      visionAnalysisId: visionAnalysisId as String?,
      positionalUncertaintyMm: uncertainty,
    );
    final validation = impact.validateRuntime();
    if (!validation.isValid) {
      throw FormatException(
        'Treffer ${impact.id} is ongeldig: '
        '${validation.issues.map((issue) => issue.toString()).join('; ')}',
      );
    }
    return impact;
  }

  static void _validateImpactBull(
    domain.TargetProfile target,
    domain.ShotImpact impact,
  ) {
    final bullId = impact.targetBullId;
    if (target.targetKind != domain.TargetKind.multiBullConcentric) {
      if (bullId != null) {
        throw const FormatException(
          'Treffer op een enkel doel bevat een doelroosje.',
        );
      }
      return;
    }
    if (bullId == null) return;
    final bull = target.bullById(bullId);
    if (bull == null || bull.role != domain.TargetBullRole.record) {
      throw const FormatException(
        'Treffer verwijst niet naar een geldig wedstrijdroosje.',
      );
    }
    if (!impact.isMiss &&
        target.bullAt(impact.xMm, impact.yMm, recordOnly: true)?.id != bullId) {
      throw const FormatException(
        'Trefferpositie en opgeslagen doelroosje komen niet overeen.',
      );
    }
  }

  static double _finiteDouble(Object? value, String field) {
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException('Ongeldige eindige waarde voor $field.');
  }

  static double? _nullableFiniteDouble(Object? value, String field) =>
      value == null ? null : _finiteDouble(value, field);

  static Map<String, dynamic> _upgradeV7(Map<String, dynamic> data) {
    final result = <String, dynamic>{
      for (final entry in data.entries) entry.key: entry.value,
    };
    result['impacts'] = (result['impacts']! as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return row
        ..['placementMethod'] = 'manual'
        ..['visionAnalysisId'] = null
        ..['positionalUncertaintyMm'] = null;
    }).toList();
    result['visionScanDrafts'] = <Map<String, dynamic>>[];
    result['visionAnalyses'] = <Map<String, dynamic>>[];
    _validateVisionRelations(result);
    return result;
  }

  static void _validateVisionRelations(Map<String, dynamic> data) {
    final seriesIds = (data['series']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    final imageIds = (data['images']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    final analysisIds = <String>{};
    for (final value in data['visionAnalyses']! as List) {
      final row = value as Map;
      final id = row['id'];
      if (id is! String ||
          !analysisIds.add(id) ||
          !seriesIds.contains(row['seriesId']) ||
          !imageIds.contains(row['imageId']) ||
          !_isJsonObject(row['qualityJson']) ||
          !_isJsonObject(row['registrationJson']) ||
          !_isJsonList(row['candidatesJson']) ||
          !_isJsonObject(row['reviewJson'])) {
        throw const FormatException('Visionanalyse is ongeldig.');
      }
    }
    for (final value in data['impacts']! as List) {
      final row = value as Map;
      final placement = row['placementMethod'];
      final analysisId = row['visionAnalysisId'];
      if (!const {
            'manual',
            'assistedAccepted',
            'assistedEdited',
          }.contains(placement) ||
          (analysisId != null &&
              (analysisId is! String || !analysisIds.contains(analysisId)))) {
        throw const FormatException('Trefferprovenance is ongeldig.');
      }
    }
    final draftIds = <String>{};
    for (final value in data['visionScanDrafts']! as List) {
      final row = value as Map;
      final id = row['id'];
      if (id is! String ||
          !draftIds.add(id) ||
          row['originalImagePath'] is! String ||
          row['sha256'] is! String ||
          row['width'] is! int ||
          row['height'] is! int ||
          row['sizeBytes'] is! int ||
          row['targetProfileJson'] is! String ||
          row['projectileDiameterMm'] is! num ||
          (row['qualityJson'] != null && !_isJsonObject(row['qualityJson'])) ||
          (row['registrationJson'] != null &&
              !_isJsonObject(row['registrationJson'])) ||
          (row['candidatesJson'] != null &&
              !_isJsonList(row['candidatesJson'])) ||
          (row['reviewJson'] != null && !_isJsonObject(row['reviewJson']))) {
        throw const FormatException('Visionconceptscan is ongeldig.');
      }
    }
  }

  static Map<String, dynamic> _upgradeV6(Map<String, dynamic> data) {
    final result = <String, dynamic>{
      for (final entry in data.entries) entry.key: entry.value,
    };
    result['trainingActivities'] = <Map<String, dynamic>>[];
    result['trainingActivitySeriesLinks'] = <Map<String, dynamic>>[];
    result['shotTimerEvents'] = <Map<String, dynamic>>[];
    result['timerPresets'] = <Map<String, dynamic>>[];
    result['acousticCalibrationProfiles'] = <Map<String, dynamic>>[];
    _validateTrainingRelations(result);
    return result;
  }

  static Map<String, dynamic> _upgradeV5(Map<String, dynamic> data) {
    final result = <String, dynamic>{
      for (final entry in data.entries) entry.key: entry.value,
    };
    result['goals'] = (result['goals']! as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      final targetPercentage = row.remove('targetPercentage');
      return row
        ..['metric'] = 'scorePercentage'
        ..['targetValue'] = targetPercentage
        ..['comparison'] = 'atLeast';
    }).toList();
    result['seriesReflections'] = <Map<String, dynamic>>[];
    result['coachFeedback'] = <Map<String, dynamic>>[];
    _validateInsightRelations(result);
    return result;
  }

  static Map<String, dynamic> _upgradeV4(Map<String, dynamic> data) {
    final result = <String, dynamic>{
      for (final entry in data.entries) entry.key: entry.value,
    };
    result['series'] = (result['series']! as List).map((value) {
      return Map<String, dynamic>.from(value as Map)
        ..['scorePenalty'] = 0
        ..['scoredBullCount'] = null;
    }).toList();
    result['impacts'] = (result['impacts']! as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return row
        ..['targetBullId'] = null
        ..['rawScoreValue'] = row['scoreValue'] ?? 0
        ..['scoreDisposition'] = 'counted';
    }).toList();
    _validateBullReferences(result);
    return result;
  }

  static Map<String, dynamic> _upgradeV2(Map<String, dynamic> data) {
    final result = _normalizeV2(data);
    result['cartridges'] = (result['cartridges']! as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map)
        ..['builtIn'] = true
        ..['archived'] = false;
      return row;
    }).toList();
    for (final table in ['ammoLots', 'ranges', 'targetProfiles']) {
      result[table] = (result[table]! as List).map((value) {
        final row = Map<String, dynamic>.from(value as Map);
        row['archived'] = false;
        return row;
      }).toList();
    }
    _validateLibraryRelations(result);
    return result;
  }

  static void _validateLibraryRelations(Map<String, dynamic> data) {
    final cartridgeIds = (data['cartridges']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    for (final value in data['ammoLots']! as List) {
      final row = value as Map;
      if (row['id'] is! String || !cartridgeIds.contains(row['cartridgeId'])) {
        throw const FormatException(
          'Munitieprofiel verwijst naar een onbekend kaliber.',
        );
      }
    }
  }

  static void _validateBullReferences(Map<String, dynamic> data) {
    final bullIdsBySeries = <String, Set<String>>{};
    for (final value in data['series']! as List) {
      final row = value as Map;
      final seriesId = row['id'];
      final snapshot = row['targetProfileJson'];
      if (seriesId is! String || snapshot is! String) {
        throw const FormatException('Reeks bevat geen geldig doelprofiel.');
      }
      final decoded = jsonDecode(snapshot);
      if (decoded is! Map) {
        throw const FormatException('Ongeldig doelprofielsnapshot.');
      }
      final bulls = decoded['bulls'];
      bullIdsBySeries[seriesId] = bulls is List
          ? bulls
                .whereType<Map>()
                .map((bull) => bull['id'])
                .whereType<String>()
                .toSet()
          : <String>{};
    }
    for (final value in data['impacts']! as List) {
      final row = value as Map;
      final bullId = row['targetBullId'];
      if (bullId == null) continue;
      final seriesId = row['seriesId'];
      if (bullId is! String ||
          seriesId is! String ||
          !(bullIdsBySeries[seriesId]?.contains(bullId) ?? false)) {
        throw const FormatException(
          'Treffer verwijst naar een onbekend doelroosje.',
        );
      }
    }
  }

  static void _validateInsightRelations(Map<String, dynamic> data) {
    final seriesIds = (data['series']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    final targetIds = (data['targetProfiles']! as List)
        .map((value) => (value as Map)['versionedId'])
        .whereType<String>()
        .toSet();
    final firearmIds = (data['firearms']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    final ammoLotIds = (data['ammoLots']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();

    for (final value in data['goals']! as List) {
      final row = value as Map;
      final targetId = row['targetProfileVersionedId'];
      final firearmId = row['firearmId'];
      final ammoLotId = row['ammoLotId'];
      final distance = row['distanceMeters'];
      final targetValue = row['targetValue'];
      if (row['id'] is! String ||
          targetId is! String ||
          !targetIds.contains(targetId) ||
          distance is! num ||
          !distance.isFinite ||
          distance <= 0 ||
          targetValue is! num ||
          !targetValue.isFinite ||
          targetValue < 0 ||
          !_goalMetrics.contains(row['metric']) ||
          !_goalComparisons.contains(row['comparison']) ||
          row['active'] is! bool ||
          (firearmId != null &&
              (firearmId is! String || !firearmIds.contains(firearmId))) ||
          (ammoLotId != null &&
              (ammoLotId is! String || !ammoLotIds.contains(ammoLotId)))) {
        throw const FormatException(
          'Persoonlijk doel bevat ongeldige of onbekende referenties.',
        );
      }
    }

    for (final value in data['seriesReflections']! as List) {
      final row = value as Map;
      if (row['seriesId'] is! String || !seriesIds.contains(row['seriesId'])) {
        throw const FormatException(
          'Reflectie verwijst naar een onbekende reeks.',
        );
      }
      if (!_perceivedQualities.contains(row['perceivedQuality'])) {
        throw const FormatException('Reflectie bevat een ongeldige ervaring.');
      }
      final rawTags = row['contextTagsJson'];
      Object? decodedTags;
      try {
        decodedTags = rawTags is String ? jsonDecode(rawTags) : null;
      } on FormatException {
        throw const FormatException('Reflectie bevat ongeldige contexttags.');
      }
      if (decodedTags is! List ||
          decodedTags.length > 3 ||
          decodedTags.any(
            (tag) => tag is! String || !_reflectionContextTags.contains(tag),
          ) ||
          decodedTags.whereType<String>().toSet().length !=
              decodedTags.length) {
        throw const FormatException('Reflectie bevat ongeldige contexttags.');
      }
    }

    final feedbackFingerprints = <String>{};
    for (final value in data['coachFeedback']! as List) {
      final row = value as Map;
      final fingerprint = row['insightFingerprint'];
      final ruleId = row['ruleId'];
      final ruleVersion = row['ruleVersion'];
      if (fingerprint is! String ||
          fingerprint.trim().isEmpty ||
          !feedbackFingerprints.add(fingerprint) ||
          ruleId is! String ||
          ruleId.trim().isEmpty ||
          ruleVersion is! int ||
          ruleVersion < 1 ||
          !_coachFeedbackResponses.contains(row['response'])) {
        throw const FormatException('Coachfeedback is ongeldig.');
      }
    }
  }

  static void _validateTrainingRelations(Map<String, dynamic> data) {
    final sessionIds = (data['sessions']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    final seriesSessionById = <String, String>{};
    final seriesStatusById = <String, String>{};
    for (final value in data['series']! as List) {
      final row = value as Map;
      final id = row['id'];
      final sessionId = row['sessionId'];
      if (id is String && sessionId is String) {
        seriesSessionById[id] = sessionId;
        if (row['status'] is String) {
          seriesStatusById[id] = row['status']! as String;
        }
      }
    }
    final firearmIds = (data['firearms']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    final cartridgeIds = (data['cartridges']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();

    final activitiesById = <String, Map>{};
    for (final value in data['trainingActivities']! as List) {
      final row = value as Map;
      final id = row['id'];
      final kind = row['kind'];
      final status = row['status'];
      final schemaVersion = row['schemaVersion'];
      final sessionId = row['sessionId'];
      if (id is! String ||
          id.trim().isEmpty ||
          activitiesById.containsKey(id) ||
          !_trainingActivityKinds.contains(kind) ||
          !_trainingActivityStatuses.contains(status) ||
          schemaVersion is! int ||
          schemaVersion < 1 ||
          (sessionId != null &&
              (sessionId is! String || !sessionIds.contains(sessionId))) ||
          !_isJsonObject(row['configurationJson']) ||
          !_isJsonObject(row['summaryJson']) ||
          row['localUtcOffsetMinutes'] is! int ||
          (row['localUtcOffsetMinutes'] as int).abs() > 24 * 60 ||
          status == 'completed' && row['completedAtUtc'] == null) {
        throw const FormatException('Trainingsactiviteit is ongeldig.');
      }
      if (kind == 'guidedDrillV2' ||
          kind == 'trainingPlan' ||
          kind == 'learningPathV2') {
        final snapshot = TrainingActivitySnapshotValidator.validateEncoded(
          kind: kind as String,
          activitySchemaVersion: schemaVersion,
          configurationJson: row['configurationJson']! as String,
          summaryJson: row['summaryJson']! as String,
          status: status as String,
        );
        if (!snapshot.isAcceptedForRestore) {
          throw FormatException(
            snapshot.message ?? 'Trainingssnapshot is ongeldig.',
          );
        }
      }
      activitiesById[id] = row;
    }

    final linkKeys = <String>{};
    final linkSequences = <String, Set<int>>{};
    final linkCountByActivity = <String, int>{};
    final linksByActivity = <String, List<Map>>{};
    for (final value in data['trainingActivitySeriesLinks']! as List) {
      final row = value as Map;
      final activityId = row['activityId'];
      final seriesId = row['seriesId'];
      final sequenceNumber = row['sequenceNumber'];
      final activity = activitiesById[activityId];
      final seriesSessionId = seriesSessionById[seriesId];
      if (activityId is! String ||
          seriesId is! String ||
          activity == null ||
          seriesSessionId == null ||
          activity['sessionId'] != seriesSessionId ||
          sequenceNumber is! int ||
          sequenceNumber < 1 ||
          !linkKeys.add('$activityId\u0000$seriesId') ||
          !linkSequences
              .putIfAbsent(activityId, () => <int>{})
              .add(sequenceNumber)) {
        throw const FormatException(
          'Trainingsactiviteit bevat een ongeldige reekskoppeling.',
        );
      }
      linkCountByActivity.update(
        activityId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      linksByActivity.putIfAbsent(activityId, () => <Map>[]).add(row);
    }
    for (final entry in linkCountByActivity.entries) {
      final kind = activitiesById[entry.key]!['kind'];
      if (_timerActivityKinds.contains(kind) && entry.value > 1) {
        throw const FormatException(
          'Een timerrun is aan meer dan één reeks gekoppeld.',
        );
      }
    }

    final eventIds = <String>{};
    final eventsByActivity = <String, List<Map>>{};
    for (final value in data['shotTimerEvents']! as List) {
      final row = value as Map;
      final id = row['id'];
      final activityId = row['activityId'];
      final sequenceNumber = row['sequenceNumber'];
      final elapsed = row['elapsedMicroseconds'];
      final split = row['splitMicroseconds'];
      final peak = row['normalizedPeak'];
      final disposition = row['disposition'];
      final exclusionReason = row['exclusionReason'];
      if (id is! String ||
          id.trim().isEmpty ||
          !eventIds.add(id) ||
          activityId is! String ||
          !activitiesById.containsKey(activityId) ||
          !_timerActivityKinds.contains(activitiesById[activityId]!['kind']) ||
          sequenceNumber is! int ||
          sequenceNumber < 1 ||
          elapsed is! int ||
          elapsed < 0 ||
          split is! int ||
          split < 0 ||
          !_timerEventSources.contains(row['source']) ||
          !_timerEventDispositions.contains(disposition) ||
          (peak != null &&
              (peak is! num || !peak.isFinite || peak < 0 || peak > 1)) ||
          (disposition == 'excluded' &&
              (exclusionReason is! String || exclusionReason.trim().isEmpty))) {
        throw const FormatException('Timerevent is ongeldig.');
      }
      eventsByActivity.putIfAbsent(activityId, () => <Map>[]).add(row);
    }
    for (final events in eventsByActivity.values) {
      events.sort(
        (left, right) => (left['sequenceNumber'] as int).compareTo(
          right['sequenceNumber'] as int,
        ),
      );
      var previousElapsed = 0;
      var previousCountedElapsed = 0;
      for (var index = 0; index < events.length; index++) {
        final row = events[index];
        final sequenceNumber = row['sequenceNumber'] as int;
        final elapsed = row['elapsedMicroseconds'] as int;
        final split = row['splitMicroseconds'] as int;
        if (sequenceNumber != index + 1 ||
            index > 0 && elapsed <= previousElapsed ||
            split > elapsed) {
          throw const FormatException(
            'Timerevents zijn niet geldig chronologisch opgeslagen.',
          );
        }
        if (row['disposition'] == 'counted') {
          if (split != elapsed - previousCountedElapsed) {
            throw const FormatException(
              'Timerevents hebben geen geldige getelde splits.',
            );
          }
          previousCountedElapsed = elapsed;
        }
        previousElapsed = elapsed;
      }
    }

    _validateStructuredTrainingActivityRelations(
      activitiesById: activitiesById,
      linksByActivity: linksByActivity,
      seriesStatusById: seriesStatusById,
    );

    final presetIds = <String>{};
    for (final value in data['timerPresets']! as List) {
      final row = value as Map;
      final id = row['id'];
      final name = row['name'];
      if (id is! String ||
          !presetIds.add(id) ||
          name is! String ||
          name.trim().isEmpty ||
          !_timerActivityKinds.contains(row['mode']) ||
          !_isJsonObject(row['configurationJson']) ||
          row['builtIn'] is! bool ||
          row['archived'] is! bool) {
        throw const FormatException('Timerpreset is ongeldig.');
      }
    }

    final calibrationIds = <String>{};
    for (final value in data['acousticCalibrationProfiles']! as List) {
      final row = value as Map;
      final id = row['id'];
      final firearmId = row['firearmId'];
      final cartridgeId = row['cartridgeId'];
      final sampleRate = row['sampleRate'];
      final sensitivity = row['sensitivity'];
      final echoLockout = row['echoLockoutMicroseconds'];
      final beepBlanking = row['beepBlankingMicroseconds'];
      if (id is! String ||
          !calibrationIds.add(id) ||
          row['name'] is! String ||
          (row['name'] as String).trim().isEmpty ||
          (firearmId != null &&
              (firearmId is! String || !firearmIds.contains(firearmId))) ||
          (cartridgeId != null &&
              (cartridgeId is! String ||
                  !cartridgeIds.contains(cartridgeId))) ||
          row['environment'] is! String ||
          (row['environment'] as String).trim().isEmpty ||
          row['audioRoute'] is! String ||
          (row['audioRoute'] as String).trim().isEmpty ||
          sampleRate is! int ||
          sampleRate <= 0 ||
          sensitivity is! num ||
          !sensitivity.isFinite ||
          sensitivity < 0 ||
          echoLockout is! int ||
          echoLockout < 0 ||
          beepBlanking is! int ||
          beepBlanking < 0 ||
          row['detectorVersion'] is! String ||
          (row['detectorVersion'] as String).trim().isEmpty) {
        throw const FormatException(
          'Akoestisch kalibratieprofiel is ongeldig.',
        );
      }
    }
  }

  static void _validateStructuredTrainingActivityRelations({
    required Map<String, Map> activitiesById,
    required Map<String, List<Map>> linksByActivity,
    required Map<String, String> seriesStatusById,
  }) {
    for (final activity in activitiesById.values) {
      final kind = activity['kind'];
      if (kind != 'guidedDrillV2' && kind != 'trainingPlan') continue;
      final validation = TrainingActivitySnapshotValidator.validateEncoded(
        kind: kind! as String,
        activitySchemaVersion: activity['schemaVersion']! as int,
        configurationJson: activity['configurationJson']! as String,
        summaryJson: activity['summaryJson']! as String,
        status: activity['status']! as String,
      );
      if (!validation.canResume) continue;
      final configuration =
          (jsonDecode(activity['configurationJson']! as String) as Map)
              .cast<String, Object?>();
      final summary = (jsonDecode(activity['summaryJson']! as String) as Map)
          .cast<String, Object?>();
      if (kind == 'guidedDrillV2') {
        _validateGuidedBackupRelations(
          activity: activity,
          configuration: configuration,
          summary: summary,
          activitiesById: activitiesById,
          links: linksByActivity[activity['id']] ?? const [],
          seriesStatusById: seriesStatusById,
        );
      } else {
        _validatePlanBackupRelations(
          activity: activity,
          configuration: configuration,
          summary: summary,
          activitiesById: activitiesById,
          linksByActivity: linksByActivity,
          seriesStatusById: seriesStatusById,
        );
      }
    }
  }

  static void _validateGuidedBackupRelations({
    required Map activity,
    required Map<String, Object?> configuration,
    required Map<String, Object?> summary,
    required Map<String, Map> activitiesById,
    required List<Map> links,
    required Map<String, String> seriesStatusById,
  }) {
    final timers = (summary['timerActivityIds'] as Map? ?? const {})
        .cast<String, String>();
    for (final entry in timers.entries) {
      final timer = activitiesById[entry.value];
      if (timer == null ||
          !_timerActivityKinds.contains(timer['kind']) ||
          timer['status'] != 'completed' ||
          timer['completedAtUtc'] == null ||
          activity['sessionId'] != null &&
              timer['sessionId'] != null &&
              activity['sessionId'] != timer['sessionId']) {
        throw FormatException(
          'Timerfase ${entry.key} verwijst naar een ongeldige timerrun.',
        );
      }
    }
    if (activity['status'] != 'completed') return;

    final rawDrill = configuration['drill'];
    if (rawDrill is! Map) {
      throw const FormatException('Afgeronde drill mist zijn snapshot.');
    }
    final drill = DrillDefinitionV2.fromJson(rawDrill.cast<String, Object?>());
    if (summary['linkedSeriesCount'] != links.length ||
        links.any(
          (link) => seriesStatusById[link['seriesId']] != 'confirmed',
        )) {
      throw const FormatException(
        'Afgeronde drill heeft geen geldige bevestigde reeksbasis.',
      );
    }
    final seriesPhases = drill.phases
        .where(
          (phase) =>
              phase.completionKind == DrillPhaseCompletionKind.confirmedSeries,
        )
        .toList(growable: false);
    for (final phase in seriesPhases) {
      final explicit = links.where((link) => link['role'] == phase.id).length;
      final effective = explicit > 0
          ? explicit
          : seriesPhases.length == 1 &&
                links.every((link) => link['role'] == null)
          ? links.length
          : 0;
      if (effective < (phase.seriesCount ?? 1)) {
        throw FormatException(
          'Afgeronde drillfase ${phase.id} mist bevestigde reeksen.',
        );
      }
    }
  }

  static void _validatePlanBackupRelations({
    required Map activity,
    required Map<String, Object?> configuration,
    required Map<String, Object?> summary,
    required Map<String, Map> activitiesById,
    required Map<String, List<Map>> linksByActivity,
    required Map<String, String> seriesStatusById,
  }) {
    final rawPlan = configuration['plan'];
    if (rawPlan is! Map) {
      throw const FormatException('Trainingsplan mist zijn snapshot.');
    }
    final plan = rawPlan.cast<String, Object?>();
    final slots = (plan['slots'] as List).cast<Map>();
    final slotByIndex = <int, Map>{
      for (final slot in slots) slot['index']! as int: slot,
    };
    final completedSlots = (summary['completedSlotIndexes'] as List)
        .cast<int>()
        .toSet();
    final mapped = (summary['guidedDrillActivityIds'] as Map)
        .cast<String, String>();
    final planSeriesIds = (linksByActivity[activity['id']] ?? const [])
        .map((link) => link['seriesId'])
        .whereType<String>()
        .toSet();
    for (final entry in mapped.entries) {
      final slotIndex = int.parse(entry.key);
      final slot = slotByIndex[slotIndex];
      final drill = activitiesById[entry.value];
      if (slot == null || drill == null || drill['kind'] != 'guidedDrillV2') {
        throw const FormatException(
          'Trainingsplan verwijst naar een ongeldige guided drill.',
        );
      }
      final drillValidation = TrainingActivitySnapshotValidator.validateEncoded(
        kind: 'guidedDrillV2',
        activitySchemaVersion: drill['schemaVersion']! as int,
        configurationJson: drill['configurationJson']! as String,
        summaryJson: drill['summaryJson']! as String,
        status: drill['status']! as String,
      );
      if (!drillValidation.canResume) {
        throw const FormatException(
          'Trainingsplan verwijst naar een niet-hervatbare drill.',
        );
      }
      final drillConfiguration =
          (jsonDecode(drill['configurationJson']! as String) as Map)
              .cast<String, Object?>();
      final context = drillConfiguration['trainingPlan'];
      final slotDrill = slot['drill'];
      if (context is! Map ||
          context['planActivityId'] != activity['id'] ||
          context['planId'] != plan['id'] ||
          context['slotIndex'] != slotIndex ||
          context['slotCount'] != slots.length ||
          slotDrill is! Map ||
          drillConfiguration['drillVersionedId'] !=
              '${slotDrill['id']}@${slotDrill['version']}') {
        throw const FormatException(
          'Guided drill hoort niet bij de opgeslagen trainingsplanslot.',
        );
      }
      if (completedSlots.contains(slotIndex) ||
          activity['status'] == 'completed') {
        if (drill['status'] != 'completed') {
          throw const FormatException(
            'Afgeronde planslot verwijst naar een onvoltooide drill.',
          );
        }
        final drillSummary =
            (jsonDecode(drill['summaryJson']! as String) as Map)
                .cast<String, Object?>();
        final drillLinks = linksByActivity[drill['id']] ?? const [];
        _validateGuidedBackupRelations(
          activity: drill,
          configuration: drillConfiguration,
          summary: drillSummary,
          activitiesById: activitiesById,
          links: drillLinks,
          seriesStatusById: seriesStatusById,
        );
        if (!planSeriesIds.containsAll(
          drillLinks.map((link) => link['seriesId']).whereType<String>(),
        )) {
          throw const FormatException(
            'Trainingsplan mist reeksdata van een afgeronde drill.',
          );
        }
      }
    }
    if (activity['status'] == 'completed' &&
        (mapped.length != slotByIndex.length ||
            completedSlots.length != slotByIndex.length)) {
      throw const FormatException(
        'Afgerond trainingsplan mist een gekoppelde drill.',
      );
    }
  }

  static bool _isJsonObject(Object? source) {
    if (source is! String) return false;
    try {
      return jsonDecode(source) is Map;
    } on FormatException {
      return false;
    }
  }

  static bool _isJsonList(Object? source) {
    if (source is! String) return false;
    try {
      return jsonDecode(source) is List;
    } on FormatException {
      return false;
    }
  }

  static const _goalMetrics = {
    'scorePercentage',
    'meanRadiusMm',
    'extremeSpreadMm',
    'absoluteHorizontalBiasMm',
    'absoluteVerticalBiasMm',
    'trainingCount',
    'completedBr50Bulls',
    'consistency',
  };

  static const _goalComparisons = {'atLeast', 'atMost'};

  static const _perceivedQualities = {'good', 'neutral', 'difficult'};

  static const _reflectionContextTags = {
    'sightPicture',
    'trigger',
    'gripOrPosition',
    'breathing',
    'followThrough',
    'tempo',
    'lightOrWind',
    'equipment',
    'perceivedFatigue',
  };

  static const _coachFeedbackResponses = {
    'useful',
    'notUseful',
    'later',
    'dismiss',
  };

  static const _trainingActivityKinds = {
    'acousticLiveFire',
    'par',
    'cadence',
    'externalManual',
    'drill',
    'experiment',
    'sightVerification',
    'coldSeries',
    'guidedDrillV2',
    'learningPathV2',
    'trainingPlan',
  };

  static const _timerActivityKinds = {
    'acousticLiveFire',
    'par',
    'cadence',
    'externalManual',
  };

  static const _trainingActivityStatuses = {
    'draft',
    'completed',
    'interrupted',
  };

  static const _timerEventSources = {
    'acoustic',
    'manual',
    'generatedPar',
    'external',
  };

  static const _timerEventDispositions = {'counted', 'excluded'};

  static Map<String, dynamic> _upgradeV1(Map<String, dynamic> data) {
    final firearms = _table(data, 'firearms');
    final cartridges = _table(data, 'cartridges');
    final ammoLots = _table(data, 'ammoLots');
    final ranges = _table(data, 'ranges');
    final targets = _table(data, 'targetProfiles');
    final goals = _table(data, 'goals');
    final preferences = _table(data, 'preferences');
    final oldSessions = _table(data, 'sessions');
    final oldSeries = _table(data, 'series');
    final oldImpacts = _table(data, 'impacts');
    final oldImages = _table(data, 'images');

    final sessions = oldSessions.map((row) {
      final copy = Map<String, dynamic>.from(row);
      copy['updatedAtUtc'] = copy['endedAtUtc'] ?? copy['startedAtUtc'];
      copy['photoSafetyAcknowledgedAtUtc'] = null;
      return copy;
    }).toList();

    final impactsBySeries = <String, List<Map<String, dynamic>>>{};
    final impacts = oldImpacts.map((row) {
      final copy = Map<String, dynamic>.from(row)
        ..remove('origin')
        ..remove('confidence');
      copy['sourceImageId'] = null;
      copy['imageXNormalized'] = null;
      copy['imageYNormalized'] = null;
      copy['multiplicity'] ??= 1;
      final seriesId = copy['seriesId'];
      if (seriesId is! String) {
        throw const FormatException('Treffer zonder geldige reeks.');
      }
      impactsBySeries.putIfAbsent(seriesId, () => []).add(copy);
      return copy;
    }).toList();

    final cartridgeByAmmoLot = <String, String>{};
    for (final ammoLot in ammoLots) {
      final id = ammoLot['id'];
      final cartridgeId = ammoLot['cartridgeId'];
      if (id is String && cartridgeId is String) {
        cartridgeByAmmoLot[id] = cartridgeId;
      }
    }

    final seriesById = <String, Map<String, dynamic>>{};
    final series = oldSeries.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final id = copy['id'];
      if (id is! String) {
        throw const FormatException('Reeks zonder geldige id.');
      }
      final seriesImpacts = impactsBySeries[id] ?? const [];
      final shotCount = seriesImpacts.isEmpty
          ? _integer(copy['expectedShots'] ?? 0, 'expectedShots')
          : seriesImpacts.fold<int>(
              0,
              (sum, impact) =>
                  sum + _integer(impact['multiplicity'] ?? 1, 'multiplicity'),
            );
      final maximumPerShot = targetMaximumFromJson(copy['targetProfileJson']);
      final ammoLotId = copy['ammoLotId'];
      copy
        ..remove('expectedShots')
        ..['cartridgeId'] = ammoLotId is String
            ? cartridgeByAmmoLot[ammoLotId]
            : null
        ..['shotCount'] = shotCount
        ..['maximumPossibleScore'] = shotCount * maximumPerShot
        ..['notes'] = null
        ..['updatedAtUtc'] = copy['confirmedAtUtc'] ?? copy['createdAtUtc'];
      seriesById[id] = copy;
      return copy;
    }).toList();

    final primaryImageSeries = <String>{};
    final images = oldImages.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final seriesId = copy['seriesId'];
      if (seriesId is! String || !seriesById.containsKey(seriesId)) {
        throw const FormatException('Foto zonder geldige reeks.');
      }
      final sessionId = seriesById[seriesId]!['sessionId'];
      if (sessionId is! String) {
        throw const FormatException('Foto zonder geldige sessie.');
      }
      final isPrimary =
          copy['kind'] == 'after' && primaryImageSeries.add(seriesId);
      copy
        ..remove('kind')
        ..['sessionId'] = sessionId
        ..['role'] = isPrimary ? 'primaryScoringPhoto' : 'attachment'
        ..['caption'] = null
        ..['updatedAtUtc'] = copy['createdAtUtc'];
      return copy;
    }).toList();

    return {
      'sessions': sessions,
      'series': series,
      'impacts': impacts,
      'images': images,
      'photoAlignments': <Map<String, dynamic>>[],
      'firearms': firearms,
      'cartridges': cartridges,
      'ammoLots': ammoLots,
      'ranges': ranges,
      'goals': goals,
      'settings': preferences,
      'targetProfiles': targets,
    };
  }

  static int targetMaximumFromJson(Object? source) {
    if (source is! String) {
      throw const FormatException('Doelprofielsnapshot ontbreekt.');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Ongeldig doelprofielsnapshot.');
    }
    final rings = decoded['rings'];
    if (rings is! List || rings.isEmpty) {
      throw const FormatException('Doelprofiel bevat geen scoringsringen.');
    }
    var maximum = 0;
    for (final ring in rings) {
      if (ring is! Map) {
        throw const FormatException('Ongeldige scoringsring.');
      }
      final value = _integer(ring['value'], 'ring.value');
      if (value > maximum) maximum = value;
    }
    return maximum;
  }

  static List<Map<String, dynamic>> _table(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is! List) {
      throw FormatException('Tabel $key ontbreekt.');
    }
    return value.map((row) {
      if (row is! Map) {
        throw FormatException('Ongeldig record in tabel $key.');
      }
      return row.cast<String, dynamic>();
    }).toList();
  }

  static int _integer(Object? value, String field) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('Ongeldige gehele waarde voor $field.');
  }

  static const _v2Tables = {
    'sessions',
    'series',
    'impacts',
    'images',
    'photoAlignments',
    'firearms',
    'cartridges',
    'ammoLots',
    'ranges',
    'goals',
    'settings',
    'targetProfiles',
  };
}

/// Shared integrity gate for every media file restored from a backup.
class BackupMediaIntegrity {
  const BackupMediaIntegrity._();

  static void verify({
    required String imageId,
    required List<int> bytes,
    required String recordSha256,
    required int recordSizeBytes,
    required String manifestSha256,
    int? manifestSizeBytes,
  }) {
    final digest = sha256.convert(bytes).toString();
    if (digest != recordSha256 || digest != manifestSha256) {
      throw FormatException('Controlegetal van foto $imageId klopt niet.');
    }
    if (bytes.length != recordSizeBytes ||
        (manifestSizeBytes != null && bytes.length != manifestSizeBytes)) {
      throw FormatException('Bestandsgrootte van foto $imageId klopt niet.');
    }
  }
}

class BackupService {
  BackupService(
    this.database, {
    BackupDirectoryProvider? temporaryDirectory,
    BackupDirectoryProvider? applicationDocumentsDirectory,
    DateTime Function()? now,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _applicationDocumentsDirectory =
           applicationDocumentsDirectory ?? getApplicationDocumentsDirectory,
       _now = now ?? DateTime.now;

  static const _magic = [0x53, 0x43, 0x42, 0x31]; // SCB1
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  final AppDatabase database;
  final BackupDirectoryProvider _temporaryDirectory;
  final BackupDirectoryProvider _applicationDocumentsDirectory;
  final DateTime Function() _now;

  Future<File> createEncryptedBackup(String password) async {
    if (password.length < 10) {
      throw const FormatException(
        'Gebruik een wachtwoord van minstens 10 tekens.',
      );
    }
    final archive = await _createArchive();
    final zipBytes = ZipEncoder().encode(archive);
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final key = await _deriveKey(password, salt);
    final box = await AesGcm.with256bits().encrypt(
      zipBytes,
      secretKey: key,
      nonce: nonce,
    );

    final container = BytesBuilder(copy: false)
      ..add(_magic)
      ..add(salt)
      ..add(nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    final directory = Directory(
      path.join(
        (await _temporaryDirectory()).path,
        'shooting_companion_exports',
      ),
    );
    await directory.create(recursive: true);
    final stamp = _now().toUtc().toIso8601String().replaceAll(
      RegExp('[:.]'),
      '-',
    );
    final file = File(
      path.join(directory.path, 'shooting-companion-$stamp.scbackup'),
    );
    return file.writeAsBytes(container.takeBytes(), flush: true);
  }

  Future<BackupSummary> inspectEncryptedBackup(
    File file,
    String password,
  ) async {
    final archive = await _decryptArchive(await file.readAsBytes(), password);
    return _readPayload(archive).summary;
  }

  Future<RestoreResult> restoreEncryptedBackup(
    File file,
    String password,
  ) async {
    final archive = await _decryptArchive(await file.readAsBytes(), password);
    final payload = _readPayload(archive);
    final data = payload.data;

    final cartridges = _rows(data, 'cartridges', CartridgeRecord.fromJson);
    final ranges = _rows(data, 'ranges', RangeRecord.fromJson);
    final firearms = _rows(data, 'firearms', FirearmRecord.fromJson);
    final ammoLots = _rows(data, 'ammoLots', AmmoLotRecord.fromJson);
    final targetProfiles = _rows(
      data,
      'targetProfiles',
      TargetProfileRecord.fromJson,
    );
    final sessions = _rows(data, 'sessions', SessionRecord.fromJson);
    final series = _rows(data, 'series', SeriesRecord.fromJson);
    final impacts = _rows(data, 'impacts', ImpactRecord.fromJson);
    final goals = _rows(data, 'goals', GoalRecord.fromJson);
    final reflections = _rows(
      data,
      'seriesReflections',
      SeriesReflectionRecord.fromJson,
    );
    final coachFeedback = _rows(
      data,
      'coachFeedback',
      CoachFeedbackRecord.fromJson,
    );
    final settings = _rows(data, 'settings', PreferenceRecord.fromJson);
    final imageRecords = _rows(data, 'images', ImageAssetRecord.fromJson);
    final alignments = _rows(
      data,
      'photoAlignments',
      PhotoAlignmentRecord.fromJson,
    );
    final trainingActivities = _rows(
      data,
      'trainingActivities',
      TrainingActivityRecord.fromJson,
    );
    final trainingActivitySeriesLinks = _rows(
      data,
      'trainingActivitySeriesLinks',
      TrainingActivitySeriesLinkRecord.fromJson,
    );
    final shotTimerEvents = _rows(
      data,
      'shotTimerEvents',
      ShotTimerEventRecord.fromJson,
    );
    final timerPresets = _rows(
      data,
      'timerPresets',
      TimerPresetRecord.fromJson,
    );
    final acousticCalibrationProfiles = _rows(
      data,
      'acousticCalibrationProfiles',
      AcousticCalibrationProfileRecord.fromJson,
    );
    final visionScanDraftRecords = _rows(
      data,
      'visionScanDrafts',
      VisionScanDraftRecord.fromJson,
    );
    final visionAnalyses = _rows(
      data,
      'visionAnalyses',
      VisionAnalysisRecord.fromJson,
    );

    // A safety backup must exist before either files or records are replaced.
    final safetyBackup = await createEncryptedBackup(password);
    final oldImages = await database.select(database.imageAssets).get();
    final oldVisionDrafts = await database
        .select(database.visionScanDrafts)
        .get();
    final appRoot = await _applicationDocumentsDirectory();
    final imageDirectory = Directory(
      path.join(appRoot.path, 'target_images', 'originals'),
    );
    await imageDirectory.create(recursive: true);
    final stagedFiles = <File>[];
    final restoredImages = <ImageAssetRecord>[];
    final restoredVisionDrafts = <VisionScanDraftRecord>[];

    try {
      final fileEntries = _mediaEntries(payload, imageRecords);
      for (final record in imageRecords) {
        final entry = fileEntries[record.id];
        if (entry == null) {
          throw FormatException(
            'Bestandsbeschrijving voor foto ${record.id} ontbreekt.',
          );
        }
        final archived = archive.findFile(entry.archivePath);
        if (archived == null) {
          throw FormatException('Foto ${record.id} ontbreekt in de back-up.');
        }
        final bytes = Uint8List.fromList(archived.content as List<int>);
        BackupMediaIntegrity.verify(
          imageId: record.id,
          bytes: bytes,
          recordSha256: record.sha256,
          recordSizeBytes: record.sizeBytes,
          manifestSha256: entry.sha256,
          manifestSizeBytes: entry.sizeBytes,
        );
        final destination = await _uniqueRestoreFile(
          imageDirectory,
          record.id,
          entry.extension,
        );
        await destination.writeAsBytes(bytes, flush: true);
        stagedFiles.add(destination);
        restoredImages.add(record.copyWith(path: destination.path));
      }
      final draftFileEntries = _visionDraftMediaEntries(
        payload,
        visionScanDraftRecords,
      );
      for (final record in visionScanDraftRecords) {
        final entry = draftFileEntries[record.id];
        if (entry == null) {
          throw FormatException(
            'Bestandsbeschrijving voor conceptscan ${record.id} ontbreekt.',
          );
        }
        final archived = archive.findFile(entry.archivePath);
        if (archived == null) {
          throw FormatException(
            'Conceptscanfoto ${record.id} ontbreekt in de back-up.',
          );
        }
        final bytes = Uint8List.fromList(archived.content as List<int>);
        BackupMediaIntegrity.verify(
          imageId: record.id,
          bytes: bytes,
          recordSha256: record.sha256,
          recordSizeBytes: record.sizeBytes,
          manifestSha256: entry.sha256,
          manifestSizeBytes: entry.sizeBytes,
        );
        final destination = await _uniqueRestoreFile(
          imageDirectory,
          'vision-${record.id}',
          entry.extension,
        );
        await destination.writeAsBytes(bytes, flush: true);
        stagedFiles.add(destination);
        restoredVisionDrafts.add(
          record.copyWith(originalImagePath: destination.path),
        );
      }

      await database.transaction(() async {
        await database.batch((batch) {
          batch.deleteAll(database.visionAnalyses);
          batch.deleteAll(database.visionScanDrafts);
          batch.deleteAll(database.shotTimerEvents);
          batch.deleteAll(database.trainingActivitySeriesLinks);
          batch.deleteAll(database.trainingActivities);
          batch.deleteAll(database.timerPresets);
          batch.deleteAll(database.acousticCalibrationProfiles);
          batch.deleteAll(database.photoAlignments);
          batch.deleteAll(database.shotImpacts);
          batch.deleteAll(database.seriesReflections);
          batch.deleteAll(database.imageAssets);
          batch.deleteAll(database.shootingSeries);
          batch.deleteAll(database.trainingSessions);
          batch.deleteAll(database.goals);
          batch.deleteAll(database.coachFeedback);
          batch.deleteAll(database.ammoLots);
          batch.deleteAll(database.firearms);
          batch.deleteAll(database.ranges);
          batch.deleteAll(database.targetProfiles);
          batch.deleteAll(database.cartridges);
          batch.deleteAll(database.preferences);

          batch.insertAll(database.cartridges, cartridges);
          batch.insertAll(database.ranges, ranges);
          batch.insertAll(database.firearms, firearms);
          batch.insertAll(database.ammoLots, ammoLots);
          batch.insertAll(database.targetProfiles, targetProfiles);
          batch.insertAll(database.trainingSessions, sessions);
          batch.insertAll(database.shootingSeries, series);
          batch.insertAll(database.imageAssets, restoredImages);
          batch.insertAll(database.visionAnalyses, visionAnalyses);
          batch.insertAll(database.shotImpacts, impacts);
          batch.insertAll(database.photoAlignments, alignments);
          batch.insertAll(database.goals, goals);
          batch.insertAll(database.seriesReflections, reflections);
          batch.insertAll(database.coachFeedback, coachFeedback);
          batch.insertAll(database.preferences, settings);
          batch.insertAll(database.trainingActivities, trainingActivities);
          batch.insertAll(
            database.trainingActivitySeriesLinks,
            trainingActivitySeriesLinks,
          );
          batch.insertAll(database.shotTimerEvents, shotTimerEvents);
          batch.insertAll(database.timerPresets, timerPresets);
          batch.insertAllOnConflictUpdate(
            database.timerPresets,
            builtInTimerPresetCompanions(),
          );
          batch.insertAll(
            database.acousticCalibrationProfiles,
            acousticCalibrationProfiles,
          );
          batch.insertAll(database.visionScanDrafts, restoredVisionDrafts);
        });
      });
    } catch (_) {
      for (final staged in stagedFiles) {
        try {
          if (await staged.exists()) await staged.delete();
        } on FileSystemException {
          // The database transaction is still rolled back. Cleanup can be
          // retried by storage diagnostics without hiding the original error.
        }
      }
      rethrow;
    }

    final restoredPaths = restoredImages
        .map((item) => path.normalize(path.absolute(item.path)))
        .followedBy(
          restoredVisionDrafts.map(
            (item) => path.normalize(path.absolute(item.originalImagePath)),
          ),
        )
        .toSet();
    final ownedRoot = path.normalize(
      path.absolute(path.join(appRoot.path, 'target_images')),
    );
    final oldOwnedPaths = oldImages
        .map((image) => image.path)
        .followedBy(oldVisionDrafts.map((draft) => draft.originalImagePath));
    for (final imagePath in oldOwnedPaths) {
      final normalized = path.normalize(path.absolute(imagePath));
      if (restoredPaths.contains(normalized) ||
          !(normalized == ownedRoot || path.isWithin(ownedRoot, normalized))) {
        continue;
      }
      try {
        final oldFile = File(normalized);
        if (await oldFile.exists()) await oldFile.delete();
      } on FileSystemException {
        // Records have already been restored successfully. A stale private
        // file is safer than rolling back a successful logical restore.
      }
    }
    return RestoreResult(summary: payload.summary, safetyBackup: safetyBackup);
  }

  Future<Archive> _createArchive() async {
    final sessions = await database.select(database.trainingSessions).get();
    final series = await database.select(database.shootingSeries).get();
    final impacts = await database.select(database.shotImpacts).get();
    final firearms = await database.select(database.firearms).get();
    final cartridges = await database.select(database.cartridges).get();
    final ammoLots = await database.select(database.ammoLots).get();
    final ranges = await database.select(database.ranges).get();
    final images = await database.select(database.imageAssets).get();
    final alignments = await database.select(database.photoAlignments).get();
    final goals = await database.select(database.goals).get();
    final reflections = await database.select(database.seriesReflections).get();
    final coachFeedback = await database.select(database.coachFeedback).get();
    final settings = await database.select(database.preferences).get();
    final targetProfiles = await database.select(database.targetProfiles).get();
    final trainingActivities = await database
        .select(database.trainingActivities)
        .get();
    final trainingActivitySeriesLinks = await database
        .select(database.trainingActivitySeriesLinks)
        .get();
    final shotTimerEvents = await database
        .select(database.shotTimerEvents)
        .get();
    final timerPresets = await database.select(database.timerPresets).get();
    final acousticCalibrationProfiles = await database
        .select(database.acousticCalibrationProfiles)
        .get();
    final visionScanDrafts = await database
        .select(database.visionScanDrafts)
        .get();
    final visionAnalyses = await database.select(database.visionAnalyses).get();
    final createdAt = _now().toUtc();
    final archive = Archive();
    final files = <Map<String, dynamic>>[];
    final databaseJson = <String, dynamic>{
      'sessions': sessions.map((row) => row.toJson()).toList(),
      'series': series.map((row) => row.toJson()).toList(),
      'impacts': impacts.map((row) => row.toJson()).toList(),
      'firearms': firearms.map((row) => row.toJson()).toList(),
      'cartridges': cartridges.map((row) => row.toJson()).toList(),
      'ammoLots': ammoLots.map((row) => row.toJson()).toList(),
      'ranges': ranges.map((row) => row.toJson()).toList(),
      'images': images.map((row) => row.toJson()).toList(),
      'photoAlignments': alignments.map((row) => row.toJson()).toList(),
      'goals': goals.map((row) => row.toJson()).toList(),
      'seriesReflections': reflections.map((row) => row.toJson()).toList(),
      'coachFeedback': coachFeedback.map((row) => row.toJson()).toList(),
      'settings': settings.map((row) => row.toJson()).toList(),
      'targetProfiles': targetProfiles.map((row) => row.toJson()).toList(),
      'trainingActivities': trainingActivities
          .map((row) => row.toJson())
          .toList(),
      'trainingActivitySeriesLinks': trainingActivitySeriesLinks
          .map((row) => row.toJson())
          .toList(),
      'shotTimerEvents': shotTimerEvents.map((row) => row.toJson()).toList(),
      'timerPresets': timerPresets.map((row) => row.toJson()).toList(),
      'acousticCalibrationProfiles': acousticCalibrationProfiles
          .map((row) => row.toJson())
          .toList(),
      'visionScanDrafts': visionScanDrafts.map((row) => row.toJson()).toList(),
      'visionAnalyses': visionAnalyses.map((row) => row.toJson()).toList(),
    };
    BackupPayloadAdapter._validateDomainRecords(databaseJson);

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final file = File(image.path);
      if (!await file.exists()) {
        throw StateError('Fotobestand ${image.id} bestaat niet meer.');
      }
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != image.sha256 || bytes.length != image.sizeBytes) {
        throw StateError('Fotobestand ${image.id} is gewijzigd of beschadigd.');
      }
      final extension = _safeExtension(file.path);
      final archivePath =
          'media/${index.toString().padLeft(6, '0')}-${_safeFilePart(image.id)}$extension';
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
      files.add({
        'imageId': image.id,
        'archivePath': archivePath,
        'sha256': digest,
        'sizeBytes': bytes.length,
      });
    }
    for (var index = 0; index < visionScanDrafts.length; index++) {
      final draft = visionScanDrafts[index];
      final file = File(draft.originalImagePath);
      if (!await file.exists()) {
        throw StateError('Conceptscanfoto ${draft.id} bestaat niet meer.');
      }
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != draft.sha256 || bytes.length != draft.sizeBytes) {
        throw StateError(
          'Conceptscanfoto ${draft.id} is gewijzigd of beschadigd.',
        );
      }
      final extension = _safeExtension(file.path);
      final archivePath =
          'vision/${index.toString().padLeft(6, '0')}-${_safeFilePart(draft.id)}$extension';
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
      files.add({
        'visionScanDraftId': draft.id,
        'archivePath': archivePath,
        'sha256': digest,
        'sizeBytes': bytes.length,
      });
    }

    archive.addFile(
      ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'format': 'shooting-companion-backup',
          'formatVersion': BackupPayloadAdapter.currentFormatVersion,
          'appVersion': '0.8.0+1',
          'databaseSchemaVersion': 8,
          'minimumAppVersion': '0.2.0',
          'createdAtUtc': createdAt.toIso8601String(),
          'sessionCount': sessions.length,
          'seriesCount': series.length,
          'imageCount': images.length,
          'visionScanDraftCount': visionScanDrafts.length,
          'files': files,
        }),
      ),
    );
    archive.addFile(
      ArchiveFile.string('database.json', jsonEncode(databaseJson)),
    );
    return archive;
  }

  NormalizedBackupPayload _readPayload(Archive archive) {
    final manifestFile = archive.findFile('manifest.json');
    final databaseFile = archive.findFile('database.json');
    if (manifestFile == null || databaseFile == null) {
      throw const FormatException('Manifest of databasebestand ontbreekt.');
    }
    return BackupPayloadAdapter.normalize(
      manifest: _jsonObject(manifestFile, 'manifest.json'),
      data: _jsonObject(databaseFile, 'database.json'),
    );
  }

  Map<String, _BackupMediaEntry> _mediaEntries(
    NormalizedBackupPayload payload,
    List<ImageAssetRecord> images,
  ) {
    if (payload.sourceFormatVersion == 1) {
      return {
        for (final image in images)
          image.id: _BackupMediaEntry(
            archivePath: 'images/${image.id}.jpg',
            sha256: image.sha256,
            sizeBytes: image.sizeBytes,
            extension: '.jpg',
          ),
      };
    }
    final rawFiles = payload.manifest['files'];
    if (rawFiles is! List) {
      throw const FormatException('Bestandsmanifest ontbreekt.');
    }
    final result = <String, _BackupMediaEntry>{};
    for (final value in rawFiles) {
      if (value is! Map) {
        throw const FormatException('Ongeldige bestandsbeschrijving.');
      }
      final item = value.cast<String, dynamic>();
      final imageId = item['imageId'];
      if (imageId == null) continue;
      final archivePath = item['archivePath'];
      final digest = item['sha256'];
      final size = item['sizeBytes'];
      if (imageId is! String ||
          archivePath is! String ||
          digest is! String ||
          size is! int ||
          result.containsKey(imageId) ||
          !_isSafeArchiveMediaPath(archivePath)) {
        throw const FormatException('Ongeldige bestandsbeschrijving.');
      }
      result[imageId] = _BackupMediaEntry(
        archivePath: archivePath,
        sha256: digest,
        sizeBytes: size,
        extension: _safeExtension(archivePath),
      );
    }
    if (result.length != images.length) {
      throw const FormatException(
        'Aantal bestanden komt niet overeen met het fotoregister.',
      );
    }
    return result;
  }

  Map<String, _BackupMediaEntry> _visionDraftMediaEntries(
    NormalizedBackupPayload payload,
    List<VisionScanDraftRecord> drafts,
  ) {
    if (payload.sourceFormatVersion < 7) return const {};
    final rawFiles = payload.manifest['files'];
    if (rawFiles is! List) {
      throw const FormatException('Bestandsmanifest ontbreekt.');
    }
    final result = <String, _BackupMediaEntry>{};
    for (final value in rawFiles) {
      if (value is! Map) {
        throw const FormatException('Ongeldige bestandsbeschrijving.');
      }
      final item = value.cast<String, dynamic>();
      final draftId = item['visionScanDraftId'];
      if (draftId == null) continue;
      final archivePath = item['archivePath'];
      final digest = item['sha256'];
      final size = item['sizeBytes'];
      if (draftId is! String ||
          archivePath is! String ||
          digest is! String ||
          size is! int ||
          result.containsKey(draftId) ||
          !_isSafeArchiveMediaPath(archivePath)) {
        throw const FormatException('Ongeldige visionbestandsbeschrijving.');
      }
      result[draftId] = _BackupMediaEntry(
        archivePath: archivePath,
        sha256: digest,
        sizeBytes: size,
        extension: _safeExtension(archivePath),
      );
    }
    if (result.length != drafts.length) {
      throw const FormatException(
        'Aantal conceptscanfoto’s komt niet overeen met het register.',
      );
    }
    return result;
  }

  Future<Archive> _decryptArchive(Uint8List bytes, String password) async {
    final minimum = _magic.length + _saltLength + _nonceLength + _macLength;
    if (bytes.length <= minimum || !_startsWith(bytes, _magic)) {
      throw const FormatException(
        'Geen geldig Shooting Companion-back-upbestand.',
      );
    }
    var offset = _magic.length;
    final salt = bytes.sublist(offset, offset += _saltLength);
    final nonce = bytes.sublist(offset, offset += _nonceLength);
    final mac = bytes.sublist(offset, offset += _macLength);
    final cipherText = bytes.sublist(offset);
    final key = await _deriveKey(password, salt);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
      return ZipDecoder().decodeBytes(clear, verify: true);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Onjuist wachtwoord of beschadigde back-up.');
    } on ArchiveException {
      throw const FormatException('Back-uparchief is beschadigd.');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Argon2id(
    parallelism: 1,
    memory: 19 * 1024,
    iterations: 2,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  bool _startsWith(List<int> bytes, List<int> prefix) {
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[index] != prefix[index]) return false;
    }
    return true;
  }

  List<T> _rows<T>(
    Map<String, dynamic> data,
    String key,
    T Function(Map<String, dynamic>) decoder,
  ) => (data[key]! as List)
      .map((row) => decoder((row as Map).cast<String, dynamic>()))
      .toList();

  Map<String, dynamic> _jsonObject(ArchiveFile file, String label) {
    try {
      final decoded = jsonDecode(utf8.decode(file.content as List<int>));
      if (decoded is! Map) throw const FormatException();
      return decoded.cast<String, dynamic>();
    } on FormatException {
      throw FormatException('$label bevat geen geldige JSON.');
    }
  }

  Future<File> _uniqueRestoreFile(
    Directory directory,
    String imageId,
    String extension,
  ) async {
    final stem =
        'restore-${_now().toUtc().microsecondsSinceEpoch}-${_safeFilePart(imageId)}';
    var suffix = 0;
    while (true) {
      final name = suffix == 0 ? '$stem$extension' : '$stem-$suffix$extension';
      final candidate = File(path.join(directory.path, name));
      if (!await candidate.exists()) return candidate;
      suffix++;
    }
  }

  static bool _isSafeArchiveMediaPath(String value) {
    final normalized = path.posix.normalize(value.replaceAll('\\', '/'));
    return (normalized.startsWith('media/') ||
            normalized.startsWith('vision/')) &&
        !normalized.startsWith('/') &&
        !normalized.contains('../');
  }

  static String _safeFilePart(String value) {
    final safe = value.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');
    return safe.isEmpty ? 'image' : safe;
  }

  static String _safeExtension(String value) {
    final extension = path.extension(value).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}

class _BackupMediaEntry {
  const _BackupMediaEntry({
    required this.archivePath,
    required this.sha256,
    required this.sizeBytes,
    required this.extension,
  });

  final String archivePath;
  final String sha256;
  final int? sizeBytes;
  final String extension;
}
