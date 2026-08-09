import 'dart:convert';

import 'package:shooting_companion_domain/domain.dart';

enum VisionCaptureMode { singleImage }

enum VisionAnalysisStatus { completed, unsupported, notAnalyzed, failed }

enum VisionQualityStatus {
  accepted,
  review,
  rejected,
  notAnalyzed,
  unsupported,
}

enum VisionRegistrationStatus {
  registered,
  manualAlignmentRequired,
  unsupported,
  notAnalyzed,
  failed,
}

enum VisionBackend { geometryOnly, openCv }

enum VisionConfidenceBand { low, medium, high }

enum VisionIssueSeverity { info, warning, error }

enum VisionQualityIssueCode {
  imageUnreadable,
  unsupportedImageFormat,
  resolutionTooLow,
  lowContrast,
  overexposed,
  underexposed,
  blurred,
  clippedTarget,
  extremePerspective,
  pixelStatisticsUnavailable,
}

enum VisionWarningCode {
  openCvUnavailable,
  unsupportedImageFormat,
  imageUnreadable,
  qualityRejected,
  registrationFailed,
  candidateDetectionDisabled,
  candidatesRequireReview,
  experimentalBackend,
}

enum VisionCandidateReason {
  localContrast,
  darkCore,
  fiberEdge,
  diameterMatchesProjectile,
  lowContrastBlackZone,
  nearScoringLine,
  geometryUnverified,
}

/// Numeric, detector-produced evidence retained for an auditable review.
///
/// It is deliberately descriptive: these values never decide the ring score
/// and never become a confirmed impact without an explicit user decision.
class VisionDetectorEvidence {
  const VisionDetectorEvidence({
    required this.localContrast,
    required this.darkCoreContrast,
    required this.fiberEdgeContrast,
    required this.diameterRatio,
    required this.circularity,
    required this.raggedness,
    required this.ringLineOverlapFraction,
    required this.uniformPatchEdgeOverlapFraction,
    required this.blackZoneFraction,
    required this.distanceTransformPeakCount,
    required this.possibleOverlap,
    required this.zone,
  });

  final double localContrast;
  final double darkCoreContrast;
  final double fiberEdgeContrast;
  final double diameterRatio;
  final double circularity;
  final double raggedness;
  final double ringLineOverlapFraction;
  final double uniformPatchEdgeOverlapFraction;
  final double blackZoneFraction;
  final int distanceTransformPeakCount;
  final bool possibleOverlap;
  final String zone;

  Map<String, Object> toJson() => {
    'localContrast': localContrast,
    'darkCoreContrast': darkCoreContrast,
    'fiberEdgeContrast': fiberEdgeContrast,
    'diameterRatio': diameterRatio,
    'circularity': circularity,
    'raggedness': raggedness,
    'ringLineOverlapFraction': ringLineOverlapFraction,
    'uniformPatchEdgeOverlapFraction': uniformPatchEdgeOverlapFraction,
    'blackZoneFraction': blackZoneFraction,
    'distanceTransformPeakCount': distanceTransformPeakCount,
    'possibleOverlap': possibleOverlap,
    'zone': zone,
  };

  factory VisionDetectorEvidence.fromJson(Map<String, Object?> json) {
    double value(String key) => (json[key]! as num).toDouble();
    final evidence = VisionDetectorEvidence(
      localContrast: value('localContrast'),
      darkCoreContrast: value('darkCoreContrast'),
      fiberEdgeContrast: value('fiberEdgeContrast'),
      diameterRatio: value('diameterRatio'),
      circularity: value('circularity'),
      raggedness: value('raggedness'),
      ringLineOverlapFraction: value('ringLineOverlapFraction'),
      uniformPatchEdgeOverlapFraction: value('uniformPatchEdgeOverlapFraction'),
      blackZoneFraction: value('blackZoneFraction'),
      distanceTransformPeakCount: (json['distanceTransformPeakCount']! as num)
          .toInt(),
      possibleOverlap: json['possibleOverlap']! as bool,
      zone: json['zone']! as String,
    );
    final numericValues = [
      evidence.localContrast,
      evidence.darkCoreContrast,
      evidence.fiberEdgeContrast,
      evidence.diameterRatio,
      evidence.circularity,
      evidence.raggedness,
      evidence.ringLineOverlapFraction,
      evidence.uniformPatchEdgeOverlapFraction,
      evidence.blackZoneFraction,
    ];
    if (numericValues.any((item) => !item.isFinite) ||
        evidence.distanceTransformPeakCount < 0 ||
        evidence.zone.trim().isEmpty) {
      throw const FormatException('Detector evidence is invalid.');
    }
    return evidence;
  }
}

class VisionProcessingOptions {
  const VisionProcessingOptions({
    this.minimumLongSidePx = 2000,
    this.minimumCardMarginFraction = 0.02,
    this.maximumPerspectiveAngleDegrees = 35,
    this.canonicalPixelsPerMm = 4,
    this.enableCandidateDetection = true,
  }) : assert(minimumLongSidePx > 0),
       assert(
         minimumCardMarginFraction >= 0 && minimumCardMarginFraction < 0.5,
       ),
       assert(
         maximumPerspectiveAngleDegrees > 0 &&
             maximumPerspectiveAngleDegrees < 90,
       ),
       assert(canonicalPixelsPerMm > 0);

  final int minimumLongSidePx;
  final double minimumCardMarginFraction;
  final double maximumPerspectiveAngleDegrees;
  final double canonicalPixelsPerMm;
  final bool enableCandidateDetection;

  Map<String, Object> toJson() => {
    'minimumLongSidePx': minimumLongSidePx,
    'minimumCardMarginFraction': minimumCardMarginFraction,
    'maximumPerspectiveAngleDegrees': maximumPerspectiveAngleDegrees,
    'canonicalPixelsPerMm': canonicalPixelsPerMm,
    'enableCandidateDetection': enableCandidateDetection,
  };

  factory VisionProcessingOptions.fromJson(Map<String, Object?> json) =>
      VisionProcessingOptions(
        minimumLongSidePx: (json['minimumLongSidePx'] as int?) ?? 2000,
        minimumCardMarginFraction:
            (json['minimumCardMarginFraction'] as num?)?.toDouble() ?? 0.02,
        maximumPerspectiveAngleDegrees:
            (json['maximumPerspectiveAngleDegrees'] as num?)?.toDouble() ?? 35,
        canonicalPixelsPerMm:
            (json['canonicalPixelsPerMm'] as num?)?.toDouble() ?? 4,
        enableCandidateDetection:
            (json['enableCandidateDetection'] as bool?) ?? true,
      );
}

class AnalyzeTargetRequest {
  const AnalyzeTargetRequest({
    this.jobId = 'anonymous',
    required this.imagePath,
    required this.targetProfileSnapshot,
    required this.projectileDiameterMm,
    this.optionalManualAlignment,
    this.captureMode = VisionCaptureMode.singleImage,
    this.processingOptions = const VisionProcessingOptions(),
  }) : assert(imagePath != ''),
       assert(projectileDiameterMm > 0);

  static const schemaVersion = 2;

  final String jobId;
  final String imagePath;
  final TargetProfile targetProfileSnapshot;
  final double projectileDiameterMm;
  final VisionCaptureMode captureMode;
  final VisionProcessingOptions processingOptions;
  final VisionManualAlignment? optionalManualAlignment;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'jobId': jobId,
    'imagePath': imagePath,
    'targetProfileSnapshot': targetProfileSnapshot.toJson(),
    'projectileDiameterMm': projectileDiameterMm,
    'captureMode': captureMode.name,
    'processingOptions': processingOptions.toJson(),
    'optionalManualAlignment': optionalManualAlignment?.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory AnalyzeTargetRequest.fromJson(Map<String, Object?> json) {
    _requireSchema(json);
    return AnalyzeTargetRequest(
      jobId: (json['jobId'] as String?) ?? 'legacy-v1',
      imagePath: json['imagePath']! as String,
      targetProfileSnapshot: TargetProfile.fromJson(
        _map(json['targetProfileSnapshot']),
      ),
      projectileDiameterMm: (json['projectileDiameterMm']! as num).toDouble(),
      captureMode: VisionCaptureMode.values.byName(
        json['captureMode']! as String,
      ),
      processingOptions: VisionProcessingOptions.fromJson(
        _map(json['processingOptions']),
      ),
      optionalManualAlignment: json['optionalManualAlignment'] == null
          ? null
          : VisionManualAlignment.fromJson(
              _map(json['optionalManualAlignment']),
            ),
    );
  }

  factory AnalyzeTargetRequest.fromJsonString(String source) =>
      AnalyzeTargetRequest.fromJson(_map(jsonDecode(source)));
}

class VisionManualAlignment {
  VisionManualAlignment({
    required List<VisionPoint> orderedSourceCornersNormalized,
    required List<double> sourceNormalizedToCardMmHomography,
  }) : orderedSourceCornersNormalized = List.unmodifiable(
         orderedSourceCornersNormalized,
       ),
       sourceNormalizedToCardMmHomography = List.unmodifiable(
         sourceNormalizedToCardMmHomography,
       ) {
    if (this.orderedSourceCornersNormalized.length != 4 ||
        this.sourceNormalizedToCardMmHomography.length != 9) {
      throw ArgumentError(
        'Handmatige uitlijning vereist vier hoeken en een 3x3-matrix.',
      );
    }
  }

  final List<VisionPoint> orderedSourceCornersNormalized;
  final List<double> sourceNormalizedToCardMmHomography;

  Map<String, Object> toJson() => {
    'orderedSourceCornersNormalized': orderedSourceCornersNormalized
        .map((point) => point.toJson())
        .toList(),
    'sourceNormalizedToCardMmHomography': sourceNormalizedToCardMmHomography,
  };

  factory VisionManualAlignment.fromJson(Map<String, Object?> json) =>
      VisionManualAlignment(
        orderedSourceCornersNormalized: _list(
          json['orderedSourceCornersNormalized'],
        ).map((item) => VisionPoint.fromJson(_map(item))).toList(),
        sourceNormalizedToCardMmHomography: _list(
          json['sourceNormalizedToCardMmHomography'],
        ).map((item) => (item! as num).toDouble()).toList(),
      );
}

class VisionPoint {
  const VisionPoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object> toJson() => {'x': x, 'y': y};

  factory VisionPoint.fromJson(Map<String, Object?> json) => VisionPoint(
    x: (json['x']! as num).toDouble(),
    y: (json['y']! as num).toDouble(),
  );
}

class VisionQualityIssue {
  const VisionQualityIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.measuredValue,
    this.threshold,
  });

  final VisionQualityIssueCode code;
  final VisionIssueSeverity severity;
  final String message;
  final double? measuredValue;
  final double? threshold;

  Map<String, Object?> toJson() => {
    'code': code.name,
    'severity': severity.name,
    'message': message,
    'measuredValue': measuredValue,
    'threshold': threshold,
  };

  factory VisionQualityIssue.fromJson(Map<String, Object?> json) =>
      VisionQualityIssue(
        code: VisionQualityIssueCode.values.byName(json['code']! as String),
        severity: VisionIssueSeverity.values.byName(
          json['severity']! as String,
        ),
        message: json['message']! as String,
        measuredValue: (json['measuredValue'] as num?)?.toDouble(),
        threshold: (json['threshold'] as num?)?.toDouble(),
      );
}

class VisionQualityAssessment {
  VisionQualityAssessment({
    required this.status,
    this.widthPx,
    this.heightPx,
    this.blurScore,
    this.contrastScore,
    this.darkClippedFraction,
    this.brightClippedFraction,
    List<VisionQualityIssue> issues = const [],
  }) : assert(widthPx == null || widthPx > 0),
       assert(heightPx == null || heightPx > 0),
       issues = List.unmodifiable(issues);

  final VisionQualityStatus status;
  final int? widthPx;
  final int? heightPx;
  final double? blurScore;
  final double? contrastScore;
  final double? darkClippedFraction;
  final double? brightClippedFraction;
  final List<VisionQualityIssue> issues;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'widthPx': widthPx,
    'heightPx': heightPx,
    'blurScore': blurScore,
    'contrastScore': contrastScore,
    'darkClippedFraction': darkClippedFraction,
    'brightClippedFraction': brightClippedFraction,
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };

  factory VisionQualityAssessment.fromJson(Map<String, Object?> json) =>
      VisionQualityAssessment(
        status: VisionQualityStatus.values.byName(json['status']! as String),
        widthPx: json['widthPx'] as int?,
        heightPx: json['heightPx'] as int?,
        blurScore: (json['blurScore'] as num?)?.toDouble(),
        contrastScore: (json['contrastScore'] as num?)?.toDouble(),
        darkClippedFraction: (json['darkClippedFraction'] as num?)?.toDouble(),
        brightClippedFraction: (json['brightClippedFraction'] as num?)
            ?.toDouble(),
        issues: _list(
          json['issues'],
        ).map((item) => VisionQualityIssue.fromJson(_map(item))).toList(),
      );
}

class VisionRegistrationResult {
  VisionRegistrationResult({
    required this.status,
    List<VisionPoint> orderedSourceCornersNormalized = const [],
    List<double>? sourceNormalizedToCardMmHomography,
    this.reprojectionErrorPx,
    this.estimatedPerspectiveAngleDegrees,
    this.algorithmVersion,
  }) : orderedSourceCornersNormalized = List.unmodifiable(
         orderedSourceCornersNormalized,
       ),
       sourceNormalizedToCardMmHomography =
           sourceNormalizedToCardMmHomography == null
           ? null
           : List.unmodifiable(sourceNormalizedToCardMmHomography) {
    if (this.sourceNormalizedToCardMmHomography != null &&
        this.sourceNormalizedToCardMmHomography!.length != 9) {
      throw ArgumentError.value(
        sourceNormalizedToCardMmHomography,
        'sourceNormalizedToCardMmHomography',
        'Een homografie moet negen row-major waarden bevatten.',
      );
    }
    if (this.orderedSourceCornersNormalized.isNotEmpty &&
        this.orderedSourceCornersNormalized.length != 4) {
      throw ArgumentError.value(
        orderedSourceCornersNormalized,
        'orderedSourceCornersNormalized',
        'Een registratie moet nul of vier geordende hoeken bevatten.',
      );
    }
  }

  final VisionRegistrationStatus status;
  final List<VisionPoint> orderedSourceCornersNormalized;
  final List<double>? sourceNormalizedToCardMmHomography;
  final double? reprojectionErrorPx;
  final double? estimatedPerspectiveAngleDegrees;
  final String? algorithmVersion;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'orderedSourceCornersNormalized': orderedSourceCornersNormalized
        .map((point) => point.toJson())
        .toList(),
    'sourceNormalizedToCardMmHomography': sourceNormalizedToCardMmHomography,
    'reprojectionErrorPx': reprojectionErrorPx,
    'estimatedPerspectiveAngleDegrees': estimatedPerspectiveAngleDegrees,
    'algorithmVersion': algorithmVersion,
  };

  factory VisionRegistrationResult.fromJson(Map<String, Object?> json) =>
      VisionRegistrationResult(
        status: VisionRegistrationStatus.values.byName(
          json['status']! as String,
        ),
        orderedSourceCornersNormalized: _list(
          json['orderedSourceCornersNormalized'] ??
              json['orderedNormalizedCorners'],
        ).map((item) => VisionPoint.fromJson(_map(item))).toList(),
        sourceNormalizedToCardMmHomography:
            (json['sourceNormalizedToCardMmHomography'] ??
                    json['homographyMatrix']) ==
                null
            ? null
            : _list(
                json['sourceNormalizedToCardMmHomography'] ??
                    json['homographyMatrix'],
              ).map((item) => (item! as num).toDouble()).toList(),
        reprojectionErrorPx: (json['reprojectionErrorPx'] as num?)?.toDouble(),
        estimatedPerspectiveAngleDegrees:
            (json['estimatedPerspectiveAngleDegrees'] as num?)?.toDouble(),
        algorithmVersion: json['algorithmVersion'] as String?,
      );
}

class VisionCandidateImpact {
  VisionCandidateImpact({
    required this.id,
    required this.sourceImageXNormalized,
    required this.sourceImageYNormalized,
    required this.cardXMm,
    required this.cardYMm,
    required this.estimatedDiameterMm,
    required this.confidenceBand,
    required List<VisionCandidateReason> reasons,
    required this.boundaryUncertaintyMm,
    this.nearScoringBoundary = false,
    this.detectorEvidence,
  }) : reasons = List.unmodifiable(reasons) {
    if (sourceImageXNormalized < 0 ||
        sourceImageXNormalized > 1 ||
        sourceImageYNormalized < 0 ||
        sourceImageYNormalized > 1) {
      throw ArgumentError(
        'Genormaliseerde kandidaatcoördinaten moeten 0–1 zijn.',
      );
    }
    if (estimatedDiameterMm <= 0 || boundaryUncertaintyMm < 0) {
      throw ArgumentError('Kandidaatdiameter en onzekerheid zijn ongeldig.');
    }
    if (this.reasons.isEmpty) {
      throw ArgumentError.value(
        reasons,
        'reasons',
        'Een kandidaat moet controleerbare redenen bevatten.',
      );
    }
  }

  final String id;
  final double sourceImageXNormalized;
  final double sourceImageYNormalized;
  final double cardXMm;
  final double cardYMm;
  final double estimatedDiameterMm;
  final VisionConfidenceBand confidenceBand;
  final List<VisionCandidateReason> reasons;
  final double boundaryUncertaintyMm;
  final bool nearScoringBoundary;
  final VisionDetectorEvidence? detectorEvidence;

  VisionCandidateImpact copyWith({
    double? cardXMm,
    double? cardYMm,
    List<VisionCandidateReason>? reasons,
    double? boundaryUncertaintyMm,
    bool? nearScoringBoundary,
    VisionDetectorEvidence? detectorEvidence,
  }) => VisionCandidateImpact(
    id: id,
    sourceImageXNormalized: sourceImageXNormalized,
    sourceImageYNormalized: sourceImageYNormalized,
    cardXMm: cardXMm ?? this.cardXMm,
    cardYMm: cardYMm ?? this.cardYMm,
    estimatedDiameterMm: estimatedDiameterMm,
    confidenceBand: confidenceBand,
    reasons: reasons ?? this.reasons,
    boundaryUncertaintyMm: boundaryUncertaintyMm ?? this.boundaryUncertaintyMm,
    nearScoringBoundary: nearScoringBoundary ?? this.nearScoringBoundary,
    detectorEvidence: detectorEvidence ?? this.detectorEvidence,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'sourceImageXNormalized': sourceImageXNormalized,
    'sourceImageYNormalized': sourceImageYNormalized,
    'cardXMm': cardXMm,
    'cardYMm': cardYMm,
    'estimatedDiameterMm': estimatedDiameterMm,
    'confidenceBand': confidenceBand.name,
    'reasons': reasons.map((reason) => reason.name).toList(),
    'boundaryUncertaintyMm': boundaryUncertaintyMm,
    'nearScoringBoundary': nearScoringBoundary,
    if (detectorEvidence != null)
      'detectorEvidence': detectorEvidence!.toJson(),
  };

  factory VisionCandidateImpact.fromJson(
    Map<String, Object?> json,
  ) => VisionCandidateImpact(
    id: json['id']! as String,
    sourceImageXNormalized:
        ((json['sourceImageXNormalized'] ?? json['imageXNormalized'])! as num)
            .toDouble(),
    sourceImageYNormalized:
        ((json['sourceImageYNormalized'] ?? json['imageYNormalized'])! as num)
            .toDouble(),
    cardXMm: ((json['cardXMm'] ?? json['xMm'])! as num).toDouble(),
    cardYMm: ((json['cardYMm'] ?? json['yMm'])! as num).toDouble(),
    estimatedDiameterMm: (json['estimatedDiameterMm']! as num).toDouble(),
    confidenceBand: VisionConfidenceBand.values.byName(
      json['confidenceBand']! as String,
    ),
    reasons: _list(json['reasons'])
        .map((item) => VisionCandidateReason.values.byName(item! as String))
        .toList(),
    boundaryUncertaintyMm: (json['boundaryUncertaintyMm']! as num).toDouble(),
    nearScoringBoundary: (json['nearScoringBoundary'] as bool?) ?? false,
    detectorEvidence: json['detectorEvidence'] == null
        ? null
        : VisionDetectorEvidence.fromJson(_map(json['detectorEvidence'])),
  );
}

class VisionWarning {
  const VisionWarning({required this.code, required this.message});

  final VisionWarningCode code;
  final String message;

  Map<String, Object> toJson() => {'code': code.name, 'message': message};

  factory VisionWarning.fromJson(Map<String, Object?> json) => VisionWarning(
    code: VisionWarningCode.values.byName(json['code']! as String),
    message: json['message']! as String,
  );
}

class VisionProvenance {
  VisionProvenance({
    required this.backend,
    required this.abiVersion,
    required this.engineVersion,
    required List<String> capabilities,
    required Map<String, String> algorithmVersions,
    this.analyzedAtUtc,
  }) : capabilities = List.unmodifiable(capabilities),
       algorithmVersions = Map.unmodifiable(algorithmVersions);

  final VisionBackend backend;
  final int abiVersion;
  final String engineVersion;
  final List<String> capabilities;
  final Map<String, String> algorithmVersions;
  final DateTime? analyzedAtUtc;

  Map<String, Object?> toJson() => {
    'backend': backend.name,
    'abiVersion': abiVersion,
    'engineVersion': engineVersion,
    'capabilities': capabilities,
    'algorithmVersions': algorithmVersions,
    'analyzedAtUtc': analyzedAtUtc?.toUtc().toIso8601String(),
  };

  factory VisionProvenance.fromJson(Map<String, Object?> json) =>
      VisionProvenance(
        backend: VisionBackend.values.byName(json['backend']! as String),
        abiVersion: json['abiVersion']! as int,
        engineVersion: json['engineVersion']! as String,
        capabilities: _list(json['capabilities']).cast<String>(),
        algorithmVersions: _map(
          json['algorithmVersions'],
        ).map((key, value) => MapEntry(key, value! as String)),
        analyzedAtUtc: json['analyzedAtUtc'] == null
            ? null
            : DateTime.parse(json['analyzedAtUtc']! as String).toUtc(),
      );
}

class AnalyzeTargetResult {
  AnalyzeTargetResult({
    required this.status,
    required this.engineVersion,
    required this.provenance,
    required this.registrationResult,
    required this.qualityAssessment,
    List<VisionCandidateImpact> candidateImpacts = const [],
    List<VisionWarning> warnings = const [],
    Map<String, double> diagnosticMetrics = const {},
    this.modelVersion,
  }) : candidateImpacts = List.unmodifiable(candidateImpacts),
       warnings = List.unmodifiable(warnings),
       diagnosticMetrics = Map.unmodifiable(diagnosticMetrics) {
    if (status != VisionAnalysisStatus.completed &&
        this.candidateImpacts.isNotEmpty) {
      throw ArgumentError.value(
        candidateImpacts,
        'candidateImpacts',
        'Alleen een voltooide analyse mag kandidaten teruggeven.',
      );
    }
  }

  static const schemaVersion = 2;

  final VisionAnalysisStatus status;
  final String engineVersion;
  final String? modelVersion;
  final VisionProvenance provenance;
  final VisionRegistrationResult registrationResult;
  final VisionQualityAssessment qualityAssessment;
  final List<VisionCandidateImpact> candidateImpacts;
  final List<VisionWarning> warnings;
  final Map<String, double> diagnosticMetrics;

  bool get requiresManualReview =>
      candidateImpacts.isNotEmpty ||
      status != VisionAnalysisStatus.completed ||
      warnings.isNotEmpty;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'status': status.name,
    'engineVersion': engineVersion,
    'modelVersion': modelVersion,
    'provenance': provenance.toJson(),
    'registrationResult': registrationResult.toJson(),
    'qualityAssessment': qualityAssessment.toJson(),
    'candidateImpacts': candidateImpacts
        .map((candidate) => candidate.toJson())
        .toList(),
    'warnings': warnings.map((warning) => warning.toJson()).toList(),
    'diagnosticMetrics': diagnosticMetrics,
  };

  String toJsonString() => jsonEncode(toJson());

  factory AnalyzeTargetResult.fromJson(Map<String, Object?> json) {
    _requireSchema(json);
    return AnalyzeTargetResult(
      status: VisionAnalysisStatus.values.byName(json['status']! as String),
      engineVersion: json['engineVersion']! as String,
      modelVersion: json['modelVersion'] as String?,
      provenance: VisionProvenance.fromJson(_map(json['provenance'])),
      registrationResult: VisionRegistrationResult.fromJson(
        _map(json['registrationResult']),
      ),
      qualityAssessment: VisionQualityAssessment.fromJson(
        _map(json['qualityAssessment']),
      ),
      candidateImpacts: _list(
        json['candidateImpacts'],
      ).map((item) => VisionCandidateImpact.fromJson(_map(item))).toList(),
      warnings: _list(
        json['warnings'],
      ).map((item) => VisionWarning.fromJson(_map(item))).toList(),
      diagnosticMetrics: _map(
        json['diagnosticMetrics'],
      ).map((key, value) => MapEntry(key, (value! as num).toDouble())),
    );
  }

  factory AnalyzeTargetResult.fromJsonString(String source) =>
      AnalyzeTargetResult.fromJson(_map(jsonDecode(source)));
}

void _requireSchema(Map<String, Object?> json) {
  final version = json['schemaVersion'];
  if (version != 1 && version != 2) {
    throw FormatException('Unsupported vision contract schema: $version');
  }
}

Map<String, Object?> _map(Object? source) =>
    (source! as Map).cast<String, Object?>();

List<Object?> _list(Object? source) => (source as List<Object?>?) ?? const [];
