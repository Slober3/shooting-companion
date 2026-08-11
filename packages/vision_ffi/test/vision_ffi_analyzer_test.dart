import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion_vision_ffi/vision_ffi.dart';

void main() {
  test('reports an unavailable native library honestly', () async {
    final analyzer = VisionFfiAnalyzer(
      libraryLoader: () => throw const FormatException('missing test library'),
    );

    final capabilities = await analyzer.capabilities();

    expect(capabilities.available, isFalse);
    expect(capabilities.supportsCandidates, isFalse);
    expect(capabilities.unavailableReason, isNotEmpty);
  });

  test('does not invent support when an invalid library is supplied', () async {
    final analyzer = VisionFfiAnalyzer(libraryLoader: DynamicLibrary.process);

    final capabilities = await analyzer.capabilities();

    expect(capabilities.available, isFalse);
    expect(capabilities.supportsRegistration, isFalse);
  });
}
