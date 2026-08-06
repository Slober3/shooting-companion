import 'dart:convert';

enum FirearmType { pistol, revolver, rifle, other }

enum SessionStatus { draft, active, completed }

enum SeriesStatus { draft, confirmed }

enum ImageRole { primaryScoringPhoto, attachment }

/// Describes how a confirmed impact entered the editor.
///
/// Assisted impacts are still user-confirmed; this value is provenance and
/// never changes scoring behavior.
enum ImpactPlacementMethod { manual, assistedAccepted, assistedEdited }

enum ValidationStatus {
  official,
  officialGeometryTrainingRendering,
  experimental,
}

enum TargetKind { concentricRings, multiBullConcentric }

enum TargetBullRole { record, sighter }

enum TargetRendererKind { standard, br50Training }

enum DuplicateShotPolicy { lowestScoreCounts }

enum ScoreDisposition { counted, duplicateNotCounted, miss }

enum LineBreakingRule { bulletEdgeTouchesHigherRing, centerOnly }

class CartridgeProfile {
  const CartridgeProfile({
    required this.id,
    required this.name,
    required this.projectileDiameterMm,
    this.notes,
  });

  final String id;
  final String name;
  final double projectileDiameterMm;
  final String? notes;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'projectileDiameterMm': projectileDiameterMm,
    'notes': notes,
  };

  factory CartridgeProfile.fromJson(Map<String, Object?> json) =>
      CartridgeProfile(
        id: json['id']! as String,
        name: json['name']! as String,
        projectileDiameterMm: (json['projectileDiameterMm']! as num).toDouble(),
        notes: json['notes'] as String?,
      );
}

class Firearm {
  const Firearm({
    required this.id,
    required this.name,
    required this.type,
    this.manufacturer,
    this.model,
    this.defaultCartridgeId,
    this.sightNotes,
    this.archived = false,
  });

  final String id;
  final String name;
  final FirearmType type;
  final String? manufacturer;
  final String? model;
  final String? defaultCartridgeId;
  final String? sightNotes;
  final bool archived;
}

class AmmoLot {
  const AmmoLot({
    required this.id,
    required this.cartridgeId,
    required this.displayName,
    this.manufacturer,
    this.productName,
    this.lotNumber,
    this.bulletWeightGrains,
    this.projectileType,
    this.notes,
  });

  final String id;
  final String cartridgeId;
  final String displayName;
  final String? manufacturer;
  final String? productName;
  final String? lotNumber;
  final double? bulletWeightGrains;
  final String? projectileType;
  final String? notes;
}

class ShootingRange {
  const ShootingRange({
    required this.id,
    required this.name,
    this.locationDescription,
    this.isIndoor = true,
    this.availableDistancesMeters = const [],
    this.notes,
  });

  final String id;
  final String name;
  final String? locationDescription;
  final bool isIndoor;
  final List<double> availableDistancesMeters;
  final String? notes;
}

class RingZone {
  const RingZone({required this.value, required this.outerDiameterMm});

  final int value;
  final double outerDiameterMm;

  Map<String, Object> toJson() => {
    'value': value,
    'outerDiameterMm': outerDiameterMm,
  };

  factory RingZone.fromJson(Map<String, Object?> json) => RingZone(
    value: json['value']! as int,
    outerDiameterMm: (json['outerDiameterMm']! as num).toDouble(),
  );
}

class TargetBull {
  const TargetBull({
    required this.id,
    required this.label,
    required this.centerXMm,
    required this.centerYMm,
    required this.role,
    required this.scoringWidthMm,
    required this.scoringHeightMm,
  });

  final String id;
  final String label;
  final double centerXMm;
  final double centerYMm;
  final TargetBullRole role;
  final double scoringWidthMm;
  final double scoringHeightMm;

  bool contains(double xMm, double yMm) =>
      (xMm - centerXMm).abs() <= scoringWidthMm / 2 &&
      (yMm - centerYMm).abs() <= scoringHeightMm / 2;

  Map<String, Object> toJson() => {
    'id': id,
    'label': label,
    'centerXMm': centerXMm,
    'centerYMm': centerYMm,
    'role': role.name,
    'scoringWidthMm': scoringWidthMm,
    'scoringHeightMm': scoringHeightMm,
  };

  factory TargetBull.fromJson(Map<String, Object?> json) => TargetBull(
    id: json['id']! as String,
    label: json['label']! as String,
    centerXMm: (json['centerXMm']! as num).toDouble(),
    centerYMm: (json['centerYMm']! as num).toDouble(),
    role: TargetBullRole.values.byName(json['role']! as String),
    scoringWidthMm: (json['scoringWidthMm']! as num).toDouble(),
    scoringHeightMm: (json['scoringHeightMm']! as num).toDouble(),
  );
}

class MultiBullScoringPolicy {
  const MultiBullScoringPolicy({
    required this.recordBullCount,
    required this.maximumShotsPerBull,
    required this.duplicatePolicy,
    required this.excessShotPenalty,
    required this.fixedMaximumScore,
  });

  final int recordBullCount;
  final int maximumShotsPerBull;
  final DuplicateShotPolicy duplicatePolicy;
  final int excessShotPenalty;
  final int fixedMaximumScore;

  Map<String, Object> toJson() => {
    'recordBullCount': recordBullCount,
    'maximumShotsPerBull': maximumShotsPerBull,
    'duplicatePolicy': duplicatePolicy.name,
    'excessShotPenalty': excessShotPenalty,
    'fixedMaximumScore': fixedMaximumScore,
  };

  factory MultiBullScoringPolicy.fromJson(Map<String, Object?> json) =>
      MultiBullScoringPolicy(
        recordBullCount: json['recordBullCount']! as int,
        maximumShotsPerBull: json['maximumShotsPerBull']! as int,
        duplicatePolicy: DuplicateShotPolicy.values.byName(
          json['duplicatePolicy']! as String,
        ),
        excessShotPenalty: json['excessShotPenalty']! as int,
        fixedMaximumScore: json['fixedMaximumScore']! as int,
      );
}

class TargetProfile {
  TargetProfile({
    required this.schemaVersion,
    required this.profileId,
    required this.profileVersion,
    required this.displayName,
    required this.authority,
    required this.rulesEdition,
    required this.physicalCardWidthMm,
    required this.physicalCardHeightMm,
    required List<RingZone> rings,
    required this.lineThicknessMm,
    required this.lineBreakingRule,
    required this.validationStatus,
    this.targetKind = TargetKind.concentricRings,
    this.defaultDistanceMeters,
    List<double> supportedDistancesMeters = const [],
    List<TargetBull> bulls = const [],
    this.multiBullScoringPolicy,
    this.rendererKind = TargetRendererKind.standard,
    this.innerTenDiameterMm,
    this.blackOuterDiameterMm,
  }) : assert(
         targetKind != TargetKind.multiBullConcentric ||
             (bulls.isNotEmpty && multiBullScoringPolicy != null),
       ),
       rings = List.unmodifiable(
         [...rings]..sort((a, b) => b.value.compareTo(a.value)),
       ),
       supportedDistancesMeters = List.unmodifiable(supportedDistancesMeters),
       bulls = List.unmodifiable(bulls);

  final int schemaVersion;
  final String profileId;
  final int profileVersion;
  final String displayName;
  final String authority;
  final String rulesEdition;
  final TargetKind targetKind;
  final double physicalCardWidthMm;
  final double physicalCardHeightMm;
  final List<RingZone> rings;
  final double? innerTenDiameterMm;
  final double? blackOuterDiameterMm;
  final double lineThicknessMm;
  final LineBreakingRule lineBreakingRule;
  final ValidationStatus validationStatus;
  final double? defaultDistanceMeters;
  final List<double> supportedDistancesMeters;
  final List<TargetBull> bulls;
  final MultiBullScoringPolicy? multiBullScoringPolicy;
  final TargetRendererKind rendererKind;

  String get versionedId => '$profileId@$profileVersion';

  int get maximumScore =>
      rings.fold(0, (max, ring) => ring.value > max ? ring.value : max);

  List<TargetBull> get recordBulls => bulls
      .where((bull) => bull.role == TargetBullRole.record)
      .toList(growable: false);

  TargetBull? bullById(String? id) {
    if (id == null) return null;
    for (final bull in bulls) {
      if (bull.id == id) return bull;
    }
    return null;
  }

  TargetBull? bullAt(double xMm, double yMm, {bool recordOnly = false}) {
    for (final bull in bulls) {
      if ((!recordOnly || bull.role == TargetBullRole.record) &&
          bull.contains(xMm, yMm)) {
        return bull;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'profileId': profileId,
    'profileVersion': profileVersion,
    'displayName': displayName,
    'authority': authority,
    'rulesEdition': rulesEdition,
    'targetKind': targetKind.name,
    'physicalCardWidthMm': physicalCardWidthMm,
    'physicalCardHeightMm': physicalCardHeightMm,
    'rings': rings.map((ring) => ring.toJson()).toList(),
    'innerTenDiameterMm': innerTenDiameterMm,
    'blackOuterDiameterMm': blackOuterDiameterMm,
    'lineThicknessMm': lineThicknessMm,
    'lineBreakingRule': lineBreakingRule.name,
    'validationStatus': validationStatus.name,
    'defaultDistanceMeters': defaultDistanceMeters,
    'supportedDistancesMeters': supportedDistancesMeters,
    'bulls': bulls.map((bull) => bull.toJson()).toList(),
    'multiBullScoringPolicy': multiBullScoringPolicy?.toJson(),
    'rendererKind': rendererKind.name,
  };

  String toJsonString() => jsonEncode(toJson());

  factory TargetProfile.fromJson(Map<String, Object?> json) => TargetProfile(
    schemaVersion: json['schemaVersion']! as int,
    profileId: json['profileId']! as String,
    profileVersion: json['profileVersion']! as int,
    displayName: json['displayName']! as String,
    authority: json['authority']! as String,
    rulesEdition: json['rulesEdition']! as String,
    physicalCardWidthMm: (json['physicalCardWidthMm']! as num).toDouble(),
    physicalCardHeightMm: (json['physicalCardHeightMm']! as num).toDouble(),
    rings: (json['rings']! as List<Object?>)
        .map(
          (ring) => RingZone.fromJson((ring! as Map).cast<String, Object?>()),
        )
        .toList(),
    innerTenDiameterMm: (json['innerTenDiameterMm'] as num?)?.toDouble(),
    blackOuterDiameterMm: (json['blackOuterDiameterMm'] as num?)?.toDouble(),
    lineThicknessMm: (json['lineThicknessMm']! as num).toDouble(),
    lineBreakingRule: LineBreakingRule.values.byName(
      json['lineBreakingRule']! as String,
    ),
    validationStatus: ValidationStatus.values.byName(
      json['validationStatus']! as String,
    ),
    targetKind: TargetKind.values.byName(
      (json['targetKind'] as String?) ?? TargetKind.concentricRings.name,
    ),
    defaultDistanceMeters: (json['defaultDistanceMeters'] as num?)?.toDouble(),
    supportedDistancesMeters:
        (json['supportedDistancesMeters'] as List<Object?>?)
            ?.map((value) => (value! as num).toDouble())
            .toList() ??
        const [],
    bulls:
        (json['bulls'] as List<Object?>?)
            ?.map(
              (bull) =>
                  TargetBull.fromJson((bull! as Map).cast<String, Object?>()),
            )
            .toList() ??
        const [],
    multiBullScoringPolicy: json['multiBullScoringPolicy'] == null
        ? null
        : MultiBullScoringPolicy.fromJson(
            (json['multiBullScoringPolicy']! as Map).cast<String, Object?>(),
          ),
    rendererKind: TargetRendererKind.values.byName(
      (json['rendererKind'] as String?) ?? TargetRendererKind.standard.name,
    ),
  );

  factory TargetProfile.fromJsonString(String source) => TargetProfile.fromJson(
    (jsonDecode(source) as Map).cast<String, Object?>(),
  );
}

class ShotImpact {
  const ShotImpact({
    required this.id,
    required this.xMm,
    required this.yMm,
    this.sourceImageId,
    this.imageXNormalized,
    this.imageYNormalized,
    this.multiplicity = 1,
    this.isMiss = false,
    this.isPositionUncertain = false,
    this.targetBullId,
    this.rawScoreValue,
    this.scoreDisposition = ScoreDisposition.counted,
    this.placementMethod = ImpactPlacementMethod.manual,
    this.visionAnalysisId,
    this.positionalUncertaintyMm,
  }) : assert(multiplicity > 0),
       assert(
         (imageXNormalized == null) == (imageYNormalized == null),
         'Genormaliseerde fotocoordinaten moeten samen aanwezig zijn.',
       ),
       assert(
         imageXNormalized == null ||
             (imageXNormalized >= 0 && imageXNormalized <= 1),
       ),
       assert(
         imageYNormalized == null ||
             (imageYNormalized >= 0 && imageYNormalized <= 1),
       ),
       assert(positionalUncertaintyMm == null || positionalUncertaintyMm >= 0);

  final String id;
  final double xMm;
  final double yMm;
  final String? sourceImageId;
  final double? imageXNormalized;
  final double? imageYNormalized;
  final int multiplicity;
  final bool isMiss;
  final bool isPositionUncertain;
  final String? targetBullId;
  final int? rawScoreValue;
  final ScoreDisposition scoreDisposition;
  final ImpactPlacementMethod placementMethod;
  final String? visionAnalysisId;
  final double? positionalUncertaintyMm;

  ShotImpact copyWith({
    double? xMm,
    double? yMm,
    String? sourceImageId,
    bool clearSourceImage = false,
    double? imageXNormalized,
    double? imageYNormalized,
    bool clearImageCoordinates = false,
    int? multiplicity,
    bool? isMiss,
    bool? isPositionUncertain,
    String? targetBullId,
    bool clearTargetBull = false,
    int? rawScoreValue,
    ScoreDisposition? scoreDisposition,
    ImpactPlacementMethod? placementMethod,
    String? visionAnalysisId,
    bool clearVisionAnalysis = false,
    double? positionalUncertaintyMm,
    bool clearPositionalUncertainty = false,
  }) => ShotImpact(
    id: id,
    xMm: xMm ?? this.xMm,
    yMm: yMm ?? this.yMm,
    sourceImageId: clearSourceImage
        ? null
        : sourceImageId ?? this.sourceImageId,
    imageXNormalized: clearImageCoordinates
        ? null
        : imageXNormalized ?? this.imageXNormalized,
    imageYNormalized: clearImageCoordinates
        ? null
        : imageYNormalized ?? this.imageYNormalized,
    multiplicity: multiplicity ?? this.multiplicity,
    isMiss: isMiss ?? this.isMiss,
    isPositionUncertain: isPositionUncertain ?? this.isPositionUncertain,
    targetBullId: clearTargetBull ? null : targetBullId ?? this.targetBullId,
    rawScoreValue: rawScoreValue ?? this.rawScoreValue,
    scoreDisposition: scoreDisposition ?? this.scoreDisposition,
    placementMethod: placementMethod ?? this.placementMethod,
    visionAnalysisId: clearVisionAnalysis
        ? null
        : visionAnalysisId ?? this.visionAnalysisId,
    positionalUncertaintyMm: clearPositionalUncertainty
        ? null
        : positionalUncertaintyMm ?? this.positionalUncertaintyMm,
  );
}

class NormalizedPoint {
  const NormalizedPoint({required this.x, required this.y})
    : assert(x >= 0 && x <= 1),
      assert(y >= 0 && y <= 1);

  final double x;
  final double y;

  Map<String, Object> toJson() => {'x': x, 'y': y};

  factory NormalizedPoint.fromJson(Map<String, Object?> json) =>
      NormalizedPoint(
        x: (json['x']! as num).toDouble(),
        y: (json['y']! as num).toDouble(),
      );
}

class StoredPhotoAlignment {
  StoredPhotoAlignment({
    required this.imageId,
    required List<NormalizedPoint> orderedCorners,
    required List<double> homographyMatrix,
    required this.algorithmVersion,
    required this.updatedAtUtc,
  }) : assert(orderedCorners.length == 4),
       assert(homographyMatrix.length == 9),
       orderedCorners = List.unmodifiable(orderedCorners),
       homographyMatrix = List.unmodifiable(homographyMatrix);

  final String imageId;
  final List<NormalizedPoint> orderedCorners;
  final List<double> homographyMatrix;
  final String algorithmVersion;
  final DateTime updatedAtUtc;

  Map<String, Object> toJson() => {
    'imageId': imageId,
    'orderedCorners': orderedCorners.map((point) => point.toJson()).toList(),
    'homographyMatrix': homographyMatrix,
    'algorithmVersion': algorithmVersion,
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
  };

  factory StoredPhotoAlignment.fromJson(
    Map<String, Object?> json,
  ) => StoredPhotoAlignment(
    imageId: json['imageId']! as String,
    orderedCorners: (json['orderedCorners']! as List<Object?>)
        .map(
          (point) =>
              NormalizedPoint.fromJson((point! as Map).cast<String, Object?>()),
        )
        .toList(),
    homographyMatrix: (json['homographyMatrix']! as List<Object?>)
        .map((value) => (value! as num).toDouble())
        .toList(),
    algorithmVersion: json['algorithmVersion']! as String,
    updatedAtUtc: DateTime.parse(json['updatedAtUtc']! as String).toUtc(),
  );
}

class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.status,
    required this.startedAtUtc,
    required this.localUtcOffsetMinutes,
    required this.updatedAtUtc,
    this.endedAtUtc,
    this.photoSafetyAcknowledgedAtUtc,
    this.rangeId,
    this.trainingGoal,
    this.conditions,
    this.notes,
  });

  final String id;
  final SessionStatus status;
  final DateTime startedAtUtc;
  final int localUtcOffsetMinutes;
  final DateTime updatedAtUtc;
  final DateTime? endedAtUtc;
  final DateTime? photoSafetyAcknowledgedAtUtc;
  final String? rangeId;
  final String? trainingGoal;
  final String? conditions;
  final String? notes;
}

class ShootingSeries {
  const ShootingSeries({
    required this.id,
    required this.sessionId,
    required this.sequenceNumber,
    required this.status,
    required this.targetProfileSnapshot,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    required this.shotCount,
    required this.maximumPossibleScore,
    required this.updatedAtUtc,
    this.cartridgeId,
    this.firearmId,
    this.ammoLotId,
    this.notes,
    this.totalScore = 0,
    this.innerTenCount = 0,
  });

  final String id;
  final String sessionId;
  final int sequenceNumber;
  final SeriesStatus status;
  final TargetProfile targetProfileSnapshot;
  final double distanceMeters;
  final double projectileDiameterMm;
  final int shotCount;
  final int maximumPossibleScore;
  final DateTime updatedAtUtc;
  final String? cartridgeId;
  final String? firearmId;
  final String? ammoLotId;
  final String? notes;
  final int totalScore;
  final int innerTenCount;
}
