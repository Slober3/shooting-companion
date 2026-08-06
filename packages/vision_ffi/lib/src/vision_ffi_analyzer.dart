import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';

typedef NativeLibraryLoader = DynamicLibrary Function();

class VisionFfiAnalyzer implements VisionAnalyzer {
  VisionFfiAnalyzer({NativeLibraryLoader? libraryLoader})
    : _libraryLoader = libraryLoader ?? _openDefaultLibrary;

  final NativeLibraryLoader _libraryLoader;
  final Map<String, Pointer<Void>> _activeJobs = {};
  _VisionBindings? _bindings;
  Object? _loadError;

  _VisionBindings? get _loadedBindings {
    if (_bindings != null) return _bindings;
    if (_loadError != null) return null;
    try {
      _bindings = _VisionBindings(_libraryLoader());
      return _bindings;
    } catch (error) {
      _loadError = error;
      return null;
    }
  }

  @override
  Future<VisionAnalyzerCapabilities> capabilities() async {
    final bindings = _loadedBindings;
    if (bindings == null) {
      return VisionAnalyzerCapabilities.unavailable(
        'De lokale visionbibliotheek kon niet worden geladen.',
      );
    }
    final abi = bindings.abiVersion();
    if (abi != 2) {
      return VisionAnalyzerCapabilities.unavailable(
        'Vision ABI $abi is niet compatibel met ABI 2.',
      );
    }
    final mask = bindings.capabilities();
    return VisionAnalyzerCapabilities(
      available: true,
      abiVersion: abi,
      engineVersion: bindings.engineVersion().toDartString(),
      hasOpenCv: mask & _VisionCapability.openCv != 0,
      supportsRegistration: mask & _VisionCapability.registration != 0,
      supportsCandidates: mask & _VisionCapability.candidates != 0,
    );
  }

  @override
  Future<AnalyzeTargetResult> analyze(AnalyzeTargetRequest request) async {
    final bindings = _loadedBindings;
    if (bindings == null) {
      throw StateError('De lokale visionbibliotheek is niet beschikbaar.');
    }
    final capabilities = await this.capabilities();
    if (!capabilities.supportsCandidates) {
      throw StateError(
        'Deze build bevat geen OpenCV-trefferdetector. Handmatig scoren blijft beschikbaar.',
      );
    }
    if (_activeJobs.containsKey(request.jobId)) {
      throw StateError('Visionjob ${request.jobId} is al actief.');
    }

    final handle = _createJob(bindings, request);
    _activeJobs[request.jobId] = handle;
    try {
      final receivePort = ReceivePort();
      await Isolate.spawn<(SendPort, int, String)>(_runJobInWorker, (
        receivePort.sendPort,
        handle.address,
        _libraryFileName,
      ));
      final message = await receivePort.first as Map<Object?, Object?>;
      receivePort.close();
      final code = message['code']! as int;
      if (code == _VisionReturnCode.cancelled) {
        throw VisionAnalysisCancelled(request.jobId);
      }
      if (code != _VisionReturnCode.ok) {
        throw StateError(
          (message['error'] as String?) ??
              'Visionanalyse mislukte met code $code.',
        );
      }
      return AnalyzeTargetResult.fromJsonString(message['json']! as String);
    } finally {
      _activeJobs.remove(request.jobId);
      bindings.destroyJob(handle);
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    final handle = _activeJobs[jobId];
    if (handle != null) _loadedBindings?.cancelJob(handle);
  }

  Pointer<Void> _createJob(
    _VisionBindings bindings,
    AnalyzeTargetRequest request,
  ) {
    final nativeRequest = calloc<_VisionRequestV2>();
    final handleOut = calloc<Pointer<Void>>();
    final jobId = request.jobId.toNativeUtf8();
    final imagePath = request.imagePath.toNativeUtf8();
    final rings = calloc<_VisionRingV2>(
      request.targetProfileSnapshot.rings.length,
    );
    Pointer<Double> corners = nullptr;
    try {
      nativeRequest.ref
        ..structSize = sizeOf<_VisionRequestV2>()
        ..jobIdUtf8 = jobId.cast()
        ..imagePathUtf8 = imagePath.cast()
        ..cardWidthMm = request.targetProfileSnapshot.physicalCardWidthMm
        ..cardHeightMm = request.targetProfileSnapshot.physicalCardHeightMm
        ..projectileDiameterMm = request.projectileDiameterMm
        ..lineThicknessMm = request.targetProfileSnapshot.lineThicknessMm
        ..rings = rings
        ..ringCount = request.targetProfileSnapshot.rings.length
        ..minimumLongSidePx = request.processingOptions.minimumLongSidePx
        ..minimumCardMarginFraction =
            request.processingOptions.minimumCardMarginFraction
        ..maximumPerspectiveAngleDegrees =
            request.processingOptions.maximumPerspectiveAngleDegrees
        ..canonicalPixelsPerMm = request.processingOptions.canonicalPixelsPerMm
        ..enableCandidateDetection =
            request.processingOptions.enableCandidateDetection ? 1 : 0;
      for (
        var index = 0;
        index < request.targetProfileSnapshot.rings.length;
        index++
      ) {
        final ring = request.targetProfileSnapshot.rings[index];
        rings[index]
          ..outerDiameterMm = ring.outerDiameterMm
          ..scoreValue = ring.value;
      }
      final manual = request.optionalManualAlignment;
      if (manual != null) {
        corners = calloc<Double>(8);
        for (var index = 0; index < 4; index++) {
          corners[index * 2] = manual.orderedSourceCornersNormalized[index].x;
          corners[index * 2 + 1] =
              manual.orderedSourceCornersNormalized[index].y;
        }
        nativeRequest.ref
          ..orderedSourceCornersNormalizedXy = corners
          ..orderedSourceCornerCount = 4;
      }
      final code = bindings.createJob(nativeRequest, handleOut);
      if (code != _VisionReturnCode.ok || handleOut.value == nullptr) {
        throw StateError('Visionjob kon niet worden aangemaakt (code $code).');
      }
      return handleOut.value;
    } finally {
      calloc.free(nativeRequest);
      calloc.free(handleOut);
      calloc.free(jobId);
      calloc.free(imagePath);
      calloc.free(rings);
      if (corners != nullptr) calloc.free(corners);
    }
  }
}

void _runJobInWorker((SendPort, int, String) message) {
  final (sendPort, address, libraryName) = message;
  try {
    final bindings = _VisionBindings(DynamicLibrary.open(libraryName));
    final output = calloc<_VisionOwnedString>();
    try {
      final code = bindings.runJob(Pointer<Void>.fromAddress(address), output);
      final json = output.ref.data == nullptr
          ? null
          : output.ref.data.cast<Utf8>().toDartString(
              length: output.ref.length,
            );
      if (output.ref.data != nullptr) bindings.freeString(output);
      sendPort.send(<Object?, Object?>{'code': code, 'json': json});
    } finally {
      calloc.free(output);
    }
  } catch (error) {
    sendPort.send(<Object?, Object?>{
      'code': _VisionReturnCode.internalError,
      'error': error.toString(),
    });
  }
}

DynamicLibrary _openDefaultLibrary() => DynamicLibrary.open(_libraryFileName);

String get _libraryFileName {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libshooting_companion_vision.so';
  }
  if (Platform.isWindows) {
    return 'shooting_companion_vision.dll';
  }
  if (Platform.isMacOS || Platform.isIOS) {
    return 'libshooting_companion_vision.dylib';
  }
  throw UnsupportedError('Vision FFI ondersteunt dit platform niet.');
}

abstract final class _VisionCapability {
  static const openCv = 1 << 2;
  static const registration = 1 << 3;
  static const candidates = 1 << 4;
}

abstract final class _VisionReturnCode {
  static const ok = 0;
  static const internalError = 2;
  static const cancelled = 3;
}

final class _VisionRingV2 extends Struct {
  @Double()
  external double outerDiameterMm;

  @Int32()
  external int scoreValue;
}

final class _VisionRequestV2 extends Struct {
  @Size()
  external int structSize;

  external Pointer<Char> jobIdUtf8;
  external Pointer<Char> imagePathUtf8;

  @Double()
  external double cardWidthMm;

  @Double()
  external double cardHeightMm;

  @Double()
  external double projectileDiameterMm;

  @Double()
  external double lineThicknessMm;

  external Pointer<_VisionRingV2> rings;

  @Size()
  external int ringCount;

  external Pointer<Double> orderedSourceCornersNormalizedXy;

  @Size()
  external int orderedSourceCornerCount;

  @Int32()
  external int minimumLongSidePx;

  @Double()
  external double minimumCardMarginFraction;

  @Double()
  external double maximumPerspectiveAngleDegrees;

  @Double()
  external double canonicalPixelsPerMm;

  @Uint8()
  external int enableCandidateDetection;
}

final class _VisionOwnedString extends Struct {
  external Pointer<Char> data;

  @Size()
  external int length;
}

class _VisionBindings {
  _VisionBindings(DynamicLibrary library)
    : abiVersion = library.lookupFunction<Uint32 Function(), int Function()>(
        'sc_vision_abi_version',
      ),
      engineVersion = library
          .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'sc_vision_engine_version',
          ),
      capabilities = library.lookupFunction<Uint32 Function(), int Function()>(
        'sc_vision_capabilities',
      ),
      createJob = library
          .lookupFunction<
            Int32 Function(Pointer<_VisionRequestV2>, Pointer<Pointer<Void>>),
            int Function(Pointer<_VisionRequestV2>, Pointer<Pointer<Void>>)
          >('sc_vision_create_job_v2'),
      runJob = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<_VisionOwnedString>),
            int Function(Pointer<Void>, Pointer<_VisionOwnedString>)
          >('sc_vision_run_job_v2'),
      cancelJob = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('sc_vision_cancel_job_v2'),
      destroyJob = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('sc_vision_destroy_job_v2'),
      freeString = library
          .lookupFunction<
            Void Function(Pointer<_VisionOwnedString>),
            void Function(Pointer<_VisionOwnedString>)
          >('sc_vision_free_string');

  final int Function() abiVersion;
  final Pointer<Utf8> Function() engineVersion;
  final int Function() capabilities;
  final int Function(Pointer<_VisionRequestV2>, Pointer<Pointer<Void>>)
  createJob;
  final int Function(Pointer<Void>, Pointer<_VisionOwnedString>) runJob;
  final void Function(Pointer<Void>) cancelJob;
  final void Function(Pointer<Void>) destroyJob;
  final void Function(Pointer<_VisionOwnedString>) freeString;
}
