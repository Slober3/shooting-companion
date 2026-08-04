import 'dart:convert';

import 'models.dart';

abstract final class CoachFingerprint {
  static String create({
    required String ruleId,
    required int ruleVersion,
    required CoachCohortReference cohort,
    required Iterable<String> evidenceKeys,
    String discriminator = '',
  }) {
    final sortedEvidence = evidenceKeys.toList()..sort();
    final canonical = [
      'coach-fingerprint-v1',
      ruleId,
      ruleVersion,
      cohort.canonicalKey,
      discriminator,
      ...sortedEvidence,
    ].join('\n');
    final bytes = utf8.encode(canonical);
    final first = _fnv1a32(bytes, 0x811c9dc5);
    final second = _fnv1a32(bytes.reversed, 0x9e3779b9);
    return 'ci_${first.toRadixString(16).padLeft(8, '0')}'
        '${second.toRadixString(16).padLeft(8, '0')}';
  }

  static int _fnv1a32(Iterable<int> bytes, int seed) {
    var hash = seed & 0xffffffff;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
