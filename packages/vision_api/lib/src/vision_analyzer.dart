import 'vision_models.dart';

class VisionAnalyzerCapabilities {
  const VisionAnalyzerCapabilities({
    required this.available,
    required this.abiVersion,
    required this.engineVersion,
    required this.hasOpenCv,
    required this.supportsRegistration,
    required this.supportsCandidates,
    this.unavailableReason,
  });

  const VisionAnalyzerCapabilities.unavailable(this.unavailableReason)
    : available = false,
      abiVersion = 0,
      engineVersion = 'unavailable',
      hasOpenCv = false,
      supportsRegistration = false,
      supportsCandidates = false;

  final bool available;
  final int abiVersion;
  final String engineVersion;
  final bool hasOpenCv;
  final bool supportsRegistration;
  final bool supportsCandidates;
  final String? unavailableReason;
}

abstract interface class VisionAnalyzer {
  Future<VisionAnalyzerCapabilities> capabilities();

  Future<AnalyzeTargetResult> analyze(AnalyzeTargetRequest request);

  Future<void> cancel(String jobId);
}

class VisionAnalysisCancelled implements Exception {
  const VisionAnalysisCancelled(this.jobId);

  final String jobId;

  @override
  String toString() => 'VisionAnalysisCancelled(jobId: $jobId)';
}
