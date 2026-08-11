import 'package:flutter/foundation.dart';
import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';

const _potentialScoreWorkerVersion = 'potential-score-worker-v1';

/// Isolate-safe input for deterministic potential-score calculations.
class PotentialScoreComputeRequest {
  PotentialScoreComputeRequest({
    required this.seriesId,
    required this.seriesUpdatedAtUtc,
    required this.target,
    required Iterable<ShotImpact> impacts,
    required this.projectileDiameterMm,
    this.config = const PotentialScoreSearchConfig(),
  }) : impacts = List.unmodifiable(impacts);

  final String seriesId;
  final DateTime seriesUpdatedAtUtc;
  final TargetProfile target;
  final List<ShotImpact> impacts;
  final double projectileDiameterMm;
  final PotentialScoreSearchConfig config;

  String get calculationFingerprint =>
      '$seriesId:${seriesUpdatedAtUtc.toUtc().microsecondsSinceEpoch}:'
      '$_potentialScoreWorkerVersion:'
      '${config.coarseStepMm}:${config.refinementLevels}:'
      '${config.refinementFactor}:${config.maximumTranslationMm ?? 'auto'}';

  Map<String, Object?> toMessage() => {
    'target': target.toJson(),
    'impacts': impacts.map(_impactToMessage).toList(growable: false),
    'projectileDiameterMm': projectileDiameterMm,
    'config': {
      'coarseStepMm': config.coarseStepMm,
      'refinementLevels': config.refinementLevels,
      'refinementFactor': config.refinementFactor,
      'maximumTranslationMm': config.maximumTranslationMm,
    },
  };
}

class PotentialScoreComputeResponse {
  const PotentialScoreComputeResponse({
    required this.result,
    required this.calculationFingerprint,
  });

  final PotentialScoreResult result;
  final String calculationFingerprint;
}

/// Shared entry point that keeps Flutter objects outside the worker isolate.
class PotentialScoreComputeService {
  final Map<String, Future<PotentialScoreComputeResponse>> _cache = {};

  Future<PotentialScoreComputeResponse> calculate(
    PotentialScoreComputeRequest request,
  ) {
    final fingerprint = request.calculationFingerprint;
    return _cache.putIfAbsent(fingerprint, () async {
      try {
        final message = await compute(
          potentialScoreWorker,
          request.toMessage(),
          debugLabel: _potentialScoreWorkerVersion,
        );
        return PotentialScoreComputeResponse(
          result: _resultFromMessage(message),
          calculationFingerprint: fingerprint,
        );
      } catch (_) {
        _cache.remove(fingerprint);
        rethrow;
      }
    });
  }

  void invalidate(String seriesId) {
    _cache.removeWhere((key, _) => key.startsWith('$seriesId:'));
  }
}

final potentialScoreComputeService = PotentialScoreComputeService();

/// Top-level callback: only isolate-sendable maps, lists and primitives cross
/// the boundary. Keep this function free of BuildContext and widget state.
@pragma('vm:entry-point')
Map<String, Object?> potentialScoreWorker(Map<String, Object?> message) {
  final target = TargetProfile.fromJson(_objectMap(message['target']));
  final impacts = (message['impacts']! as List<Object?>)
      .map((value) => _impactFromMessage(_objectMap(value)))
      .toList(growable: false);
  final configMessage = _objectMap(message['config']);
  final result = PotentialScoreAnalyzer.analyze(
    target: target,
    impacts: impacts,
    projectileDiameterMm: (message['projectileDiameterMm']! as num).toDouble(),
    config: PotentialScoreSearchConfig(
      coarseStepMm: (configMessage['coarseStepMm']! as num).toDouble(),
      refinementLevels: configMessage['refinementLevels']! as int,
      refinementFactor: (configMessage['refinementFactor']! as num).toDouble(),
      maximumTranslationMm: (configMessage['maximumTranslationMm'] as num?)
          ?.toDouble(),
    ),
  );
  return {
    'currentScore': result.currentScore,
    'bestScore': result.bestScore,
    'maximumPossible': result.maximumPossible,
    'translationXMm': result.translationXMm,
    'translationYMm': result.translationYMm,
  };
}

Map<String, Object?> _impactToMessage(ShotImpact impact) => {
  'id': impact.id,
  'xMm': impact.xMm,
  'yMm': impact.yMm,
  'sourceImageId': impact.sourceImageId,
  'imageXNormalized': impact.imageXNormalized,
  'imageYNormalized': impact.imageYNormalized,
  'multiplicity': impact.multiplicity,
  'isMiss': impact.isMiss,
  'isPositionUncertain': impact.isPositionUncertain,
  'targetBullId': impact.targetBullId,
  'rawScoreValue': impact.rawScoreValue,
  'scoreDisposition': impact.scoreDisposition.name,
};

ShotImpact _impactFromMessage(Map<String, Object?> message) => ShotImpact(
  id: message['id']! as String,
  xMm: (message['xMm']! as num).toDouble(),
  yMm: (message['yMm']! as num).toDouble(),
  sourceImageId: message['sourceImageId'] as String?,
  imageXNormalized: (message['imageXNormalized'] as num?)?.toDouble(),
  imageYNormalized: (message['imageYNormalized'] as num?)?.toDouble(),
  multiplicity: message['multiplicity']! as int,
  isMiss: message['isMiss']! as bool,
  isPositionUncertain: message['isPositionUncertain']! as bool,
  targetBullId: message['targetBullId'] as String?,
  rawScoreValue: message['rawScoreValue'] as int?,
  scoreDisposition: ScoreDisposition.values.byName(
    message['scoreDisposition']! as String,
  ),
);

PotentialScoreResult _resultFromMessage(Map<String, Object?> message) =>
    PotentialScoreResult(
      currentScore: message['currentScore']! as int,
      bestScore: message['bestScore']! as int,
      maximumPossible: message['maximumPossible']! as int,
      translationXMm: (message['translationXMm']! as num).toDouble(),
      translationYMm: (message['translationYMm']! as num).toDouble(),
    );

Map<String, Object?> _objectMap(Object? value) =>
    (value! as Map).cast<String, Object?>();
