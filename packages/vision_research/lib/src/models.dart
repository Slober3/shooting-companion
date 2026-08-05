import 'dart:typed_data';

import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

enum VisionCropMediaType {
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png');

  const VisionCropMediaType(this.mimeType, this.extension);

  final String mimeType;
  final String extension;
}

/// Closed vocabulary: no free text can accidentally carry personal data.
enum VisionQualityLabel {
  unreviewed,
  ringsFullyVisible,
  adequateSharpness,
  motionBlur,
  underexposed,
  overexposed,
  glare,
  unevenLighting,
  steepPerspective,
  paperDamage,
  previousHoles,
  patchedHoles,
  blackZoneImpact,
  whiteZoneImpact,
}

class VisionResearchConsent {
  VisionResearchConsent({
    required this.explicitConsent,
    required this.consentTextVersion,
    required this.acceptedAtUtc,
    required this.allowsAlgorithmValidation,
    required this.allowsModelTraining,
    required this.allowsPublicResearchRelease,
  });

  final bool explicitConsent;
  final String consentTextVersion;
  final DateTime acceptedAtUtc;
  final bool allowsAlgorithmValidation;
  final bool allowsModelTraining;
  final bool allowsPublicResearchRelease;

  Map<String, Object> toJson() => {
    'acceptedAtUtc': acceptedAtUtc.toIso8601String(),
    'allowsAlgorithmValidation': allowsAlgorithmValidation,
    'allowsModelTraining': allowsModelTraining,
    'allowsPublicResearchRelease': allowsPublicResearchRelease,
    'consentTextVersion': consentTextVersion,
    'excludedData': const [
      'deviceIdentifiers',
      'exif',
      'gps',
      'names',
      'notes',
      'rangeLocation',
      'serialNumbers',
    ],
    'explicitConsent': explicitConsent,
    'includedData': const [
      'alignment',
      'confirmedManualImpacts',
      'croppedTargetPixels',
      'projectileDiameterMm',
      'qualityLabels',
      'targetProfileSnapshot',
    ],
  };

  factory VisionResearchConsent.fromJson(Map<String, Object?> json) {
    const expectedKeys = {
      'acceptedAtUtc',
      'allowsAlgorithmValidation',
      'allowsModelTraining',
      'allowsPublicResearchRelease',
      'consentTextVersion',
      'excludedData',
      'explicitConsent',
      'includedData',
    };
    _expectExactKeys(json, expectedKeys, 'consentmanifest');
    _expectExactStringList(json['includedData'], const [
      'alignment',
      'confirmedManualImpacts',
      'croppedTargetPixels',
      'projectileDiameterMm',
      'qualityLabels',
      'targetProfileSnapshot',
    ], 'includedData');
    _expectExactStringList(json['excludedData'], const [
      'deviceIdentifiers',
      'exif',
      'gps',
      'names',
      'notes',
      'rangeLocation',
      'serialNumbers',
    ], 'excludedData');
    final acceptedAt = DateTime.tryParse(
      json['acceptedAtUtc'] as String? ?? '',
    );
    if (acceptedAt == null) {
      throw const FormatException('Ongeldige toestemmingstijd.');
    }
    return VisionResearchConsent(
      explicitConsent: json['explicitConsent']! as bool,
      consentTextVersion: json['consentTextVersion']! as String,
      acceptedAtUtc: acceptedAt,
      allowsAlgorithmValidation: json['allowsAlgorithmValidation']! as bool,
      allowsModelTraining: json['allowsModelTraining']! as bool,
      allowsPublicResearchRelease: json['allowsPublicResearchRelease']! as bool,
    );
  }

  void validate() {
    if (!explicitConsent) {
      throw const FormatException('Expliciete toestemming ontbreekt.');
    }
    if (!acceptedAtUtc.isUtc) {
      throw const FormatException('Toestemmingstijd moet UTC zijn.');
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]{1,64}$').hasMatch(consentTextVersion)) {
      throw const FormatException('Ongeldige versie van de toestemmingstekst.');
    }
    if (!allowsAlgorithmValidation &&
        !allowsModelTraining &&
        !allowsPublicResearchRelease) {
      throw const FormatException('Er is geen onderzoeksdoel toegestaan.');
    }
  }
}

class VisionResearchImpact {
  VisionResearchImpact._({
    required this.ordinal,
    required this.xMm,
    required this.yMm,
    required this.imageXNormalized,
    required this.imageYNormalized,
    required this.multiplicity,
    required this.isMiss,
    required this.isPositionUncertain,
    required this.targetBullId,
    required this.rawScoreValue,
    required this.scoreDisposition,
  });

  factory VisionResearchImpact.fromConfirmedManualShot(
    ShotImpact impact,
    int ordinal,
  ) => VisionResearchImpact._(
    ordinal: ordinal,
    xMm: impact.xMm,
    yMm: impact.yMm,
    imageXNormalized: impact.imageXNormalized,
    imageYNormalized: impact.imageYNormalized,
    multiplicity: impact.multiplicity,
    isMiss: impact.isMiss,
    isPositionUncertain: impact.isPositionUncertain,
    targetBullId: impact.targetBullId,
    rawScoreValue: impact.rawScoreValue,
    scoreDisposition: impact.scoreDisposition,
  );

  final int ordinal;
  final double xMm;
  final double yMm;
  final double? imageXNormalized;
  final double? imageYNormalized;
  final int multiplicity;
  final bool isMiss;
  final bool isPositionUncertain;
  final String? targetBullId;
  final int? rawScoreValue;
  final ScoreDisposition scoreDisposition;

  Map<String, Object?> toJson() => {
    'confirmed': true,
    'imageXNormalized': imageXNormalized,
    'imageYNormalized': imageYNormalized,
    'isMiss': isMiss,
    'isPositionUncertain': isPositionUncertain,
    'multiplicity': multiplicity,
    'ordinal': ordinal,
    'placementMethod': 'manual',
    'rawScoreValue': rawScoreValue,
    'scoreDisposition': scoreDisposition.name,
    'targetBullId': targetBullId,
    'xMm': xMm,
    'yMm': yMm,
  };

  factory VisionResearchImpact.fromJson(Map<String, Object?> json) {
    const expectedKeys = {
      'confirmed',
      'imageXNormalized',
      'imageYNormalized',
      'isMiss',
      'isPositionUncertain',
      'multiplicity',
      'ordinal',
      'placementMethod',
      'rawScoreValue',
      'scoreDisposition',
      'targetBullId',
      'xMm',
      'yMm',
    };
    _expectExactKeys(json, expectedKeys, 'treffer');
    if (json['confirmed'] != true || json['placementMethod'] != 'manual') {
      throw const FormatException(
        'Alleen bevestigde handmatig geplaatste treffers zijn toegestaan.',
      );
    }
    final impact = VisionResearchImpact._(
      ordinal: json['ordinal']! as int,
      xMm: (json['xMm']! as num).toDouble(),
      yMm: (json['yMm']! as num).toDouble(),
      imageXNormalized: (json['imageXNormalized'] as num?)?.toDouble(),
      imageYNormalized: (json['imageYNormalized'] as num?)?.toDouble(),
      multiplicity: json['multiplicity']! as int,
      isMiss: json['isMiss']! as bool,
      isPositionUncertain: json['isPositionUncertain']! as bool,
      targetBullId: json['targetBullId'] as String?,
      rawScoreValue: json['rawScoreValue'] as int?,
      scoreDisposition: ScoreDisposition.values.byName(
        json['scoreDisposition']! as String,
      ),
    );
    impact.validate();
    return impact;
  }

  void validate() {
    if (ordinal < 1 || !xMm.isFinite || !yMm.isFinite || multiplicity < 1) {
      throw const FormatException('Ongeldige handmatige treffer.');
    }
    if ((imageXNormalized == null) != (imageYNormalized == null)) {
      throw const FormatException('Onvolledige fotocoordinaten.');
    }
    for (final value in [imageXNormalized, imageYNormalized]) {
      if (value != null && (!value.isFinite || value < 0 || value > 1)) {
        throw const FormatException(
          'Ongeldige genormaliseerde fotocoordinaat.',
        );
      }
    }
  }
}

/// Geometry-only target snapshot. Free-form profile and bull labels are
/// intentionally omitted because custom names can contain personal data.
class VisionTargetProfileSnapshot {
  VisionTargetProfileSnapshot._(this._profile);

  final TargetProfile _profile;

  String get profileId => _profile.profileId;
  int get profileVersion => _profile.profileVersion;
  String get versionedId => _profile.versionedId;
  double get physicalCardWidthMm => _profile.physicalCardWidthMm;
  double get physicalCardHeightMm => _profile.physicalCardHeightMm;
  List<TargetBull> get bulls => _profile.bulls;

  factory VisionTargetProfileSnapshot.fromTargetProfile(TargetProfile profile) {
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,127}$').hasMatch(profile.profileId)) {
      throw const FormatException(
        'Doelprofiel-ID is niet geschikt voor een privacyveilige export.',
      );
    }
    for (final bull in profile.bulls) {
      if (!RegExp(r'^[a-zA-Z0-9._-]{1,64}$').hasMatch(bull.id)) {
        throw const FormatException(
          'Roos-ID is niet geschikt voor een privacyveilige export.',
        );
      }
    }
    return VisionTargetProfileSnapshot._(profile);
  }

  Map<String, Object?> toJson() => {
    'blackOuterDiameterMm': _profile.blackOuterDiameterMm,
    'bulls': [
      for (final bull in _profile.bulls)
        {
          'centerXMm': bull.centerXMm,
          'centerYMm': bull.centerYMm,
          'id': bull.id,
          'role': bull.role.name,
          'scoringHeightMm': bull.scoringHeightMm,
          'scoringWidthMm': bull.scoringWidthMm,
        },
    ],
    'defaultDistanceMeters': _profile.defaultDistanceMeters,
    'innerTenDiameterMm': _profile.innerTenDiameterMm,
    'lineBreakingRule': _profile.lineBreakingRule.name,
    'lineThicknessMm': _profile.lineThicknessMm,
    'multiBullScoringPolicy': _profile.multiBullScoringPolicy?.toJson(),
    'physicalCardHeightMm': _profile.physicalCardHeightMm,
    'physicalCardWidthMm': _profile.physicalCardWidthMm,
    'profileId': _profile.profileId,
    'profileVersion': _profile.profileVersion,
    'rendererKind': _profile.rendererKind.name,
    'rings': _profile.rings.map((ring) => ring.toJson()).toList(),
    'schemaVersion': _profile.schemaVersion,
    'supportedDistancesMeters': _profile.supportedDistancesMeters,
    'targetKind': _profile.targetKind.name,
    'validationStatus': _profile.validationStatus.name,
  };

  factory VisionTargetProfileSnapshot.fromJson(Map<String, Object?> json) {
    const expectedKeys = {
      'blackOuterDiameterMm',
      'bulls',
      'defaultDistanceMeters',
      'innerTenDiameterMm',
      'lineBreakingRule',
      'lineThicknessMm',
      'multiBullScoringPolicy',
      'physicalCardHeightMm',
      'physicalCardWidthMm',
      'profileId',
      'profileVersion',
      'rendererKind',
      'rings',
      'schemaVersion',
      'supportedDistancesMeters',
      'targetKind',
      'validationStatus',
    };
    _expectExactKeys(json, expectedKeys, 'doelprofielsnapshot');
    final rawBulls = json['bulls'];
    if (rawBulls is! List) {
      throw const FormatException('Ongeldige roosgeometrie.');
    }
    final bulls = <Map<String, Object?>>[];
    for (final raw in rawBulls) {
      if (raw is! Map) {
        throw const FormatException('Ongeldige roosgeometrie.');
      }
      final bull = raw.cast<String, Object?>();
      _expectExactKeys(bull, const {
        'centerXMm',
        'centerYMm',
        'id',
        'role',
        'scoringHeightMm',
        'scoringWidthMm',
      }, 'roosgeometrie');
      bulls.add({...bull, 'label': bull['id']! as String});
    }
    final profile = TargetProfile.fromJson({
      ...json,
      'authority': 'research-export',
      'bulls': bulls,
      'displayName': json['profileId']! as String,
      'rulesEdition': 'profile-${json['profileVersion']}',
    });
    return VisionTargetProfileSnapshot.fromTargetProfile(profile);
  }
}

class VisionResearchExportRequest {
  VisionResearchExportRequest({
    required Uint8List croppedTargetBytes,
    required this.cropMediaType,
    required this.targetProfileSnapshot,
    required this.projectileDiameterMm,
    required List<ShotImpact> confirmedManualImpacts,
    required this.alignment,
    required Set<VisionQualityLabel> qualityLabels,
    required this.consent,
  }) : croppedTargetBytes = Uint8List.fromList(croppedTargetBytes),
       confirmedManualImpacts = List.unmodifiable(confirmedManualImpacts),
       qualityLabels = Set.unmodifiable(qualityLabels);

  final Uint8List croppedTargetBytes;
  final VisionCropMediaType cropMediaType;
  final TargetProfile targetProfileSnapshot;
  final double projectileDiameterMm;
  final List<ShotImpact> confirmedManualImpacts;
  final ManualPhotoAlignment alignment;
  final Set<VisionQualityLabel> qualityLabels;
  final VisionResearchConsent consent;
}

class VisionResearchDecodedExport {
  VisionResearchDecodedExport({
    required Uint8List croppedTargetBytes,
    required this.cropMediaType,
    required this.targetProfileSnapshot,
    required this.projectileDiameterMm,
    required List<VisionResearchImpact> impacts,
    required this.alignment,
    required Set<VisionQualityLabel> qualityLabels,
    required this.consent,
  }) : croppedTargetBytes = Uint8List.fromList(croppedTargetBytes),
       impacts = List.unmodifiable(impacts),
       qualityLabels = Set.unmodifiable(qualityLabels);

  final Uint8List croppedTargetBytes;
  final VisionCropMediaType cropMediaType;
  final VisionTargetProfileSnapshot targetProfileSnapshot;
  final double projectileDiameterMm;
  final List<VisionResearchImpact> impacts;
  final ManualPhotoAlignment alignment;
  final Set<VisionQualityLabel> qualityLabels;
  final VisionResearchConsent consent;

  Map<String, Object?> toPrivacySafeRecordsJson() => {
    'alignment': alignment.toJson(),
    'consent': consent.toJson(),
    'impacts': impacts.map((impact) => impact.toJson()).toList(),
    'projectileDiameterMm': projectileDiameterMm,
    'qualityLabels': qualityLabels.map((label) => label.name).toList()..sort(),
    'targetProfileSnapshot': targetProfileSnapshot.toJson(),
  };
}

class VisionResearchInspection {
  VisionResearchInspection({
    required this.createdAtUtc,
    required this.profileVersionedId,
    required this.projectileDiameterMm,
    required this.impactCount,
    required this.cropMediaType,
    required this.cropSizeBytes,
    required this.cropSha256,
    required this.imageWidth,
    required this.imageHeight,
    required this.manifestSha256,
    required Set<VisionQualityLabel> qualityLabels,
    required this.consent,
  }) : qualityLabels = Set.unmodifiable(qualityLabels);

  final DateTime createdAtUtc;
  final String profileVersionedId;
  final double projectileDiameterMm;
  final int impactCount;
  final VisionCropMediaType cropMediaType;
  final int cropSizeBytes;
  final String cropSha256;
  final int imageWidth;
  final int imageHeight;
  final String manifestSha256;
  final Set<VisionQualityLabel> qualityLabels;
  final VisionResearchConsent consent;
}

class VisionResearchLimits {
  const VisionResearchLimits({
    this.maximumInputCropBytes = 25 * 1024 * 1024,
    this.maximumSanitizedCropBytes = 25 * 1024 * 1024,
    this.maximumContainerBytes = 28 * 1024 * 1024,
    this.maximumMetadataBytes = 2 * 1024 * 1024,
    this.maximumImagePixels = 40 * 1000 * 1000,
    this.maximumImpacts = 5000,
  });

  final int maximumInputCropBytes;
  final int maximumSanitizedCropBytes;
  final int maximumContainerBytes;
  final int maximumMetadataBytes;
  final int maximumImagePixels;
  final int maximumImpacts;
}

void _expectExactKeys(
  Map<String, Object?> json,
  Set<String> expected,
  String label,
) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw FormatException(
      'Ongeldig $label: onverwachte of ontbrekende velden.',
    );
  }
}

void _expectExactStringList(
  Object? value,
  List<String> expected,
  String label,
) {
  if (value is! List || value.length != expected.length) {
    throw FormatException('Ongeldige $label-lijst.');
  }
  for (var index = 0; index < expected.length; index++) {
    if (value[index] != expected[index]) {
      throw FormatException('Ongeldige $label-lijst.');
    }
  }
}
