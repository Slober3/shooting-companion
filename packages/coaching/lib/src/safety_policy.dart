import 'models.dart';

abstract final class CoachSafetyPolicy {
  static const _forbiddenFragments = <String>[
    'dit bewijst',
    'wordt veroorzaakt door',
    'de oorzaak is',
    'je bent vermoeid',
    'trekkerfout',
    'pas je vizier',
    'moet je vizier',
    'deze flyer moet',
    'is beter dan',
    'garandeert',
  ];

  static List<String> violations(CoachInsight insight) {
    final text = [
      insight.observation,
      insight.evidence.summary,
      for (final explanation in insight.possibleExplanations)
        '${explanation.title} ${explanation.detail}',
      insight.proposedExperiment.title,
      insight.proposedExperiment.instructions,
      insight.nextMeasurement.label,
      insight.nextMeasurement.instructions,
      ...insight.warnings,
    ].join(' ').toLowerCase();
    return [
      for (final fragment in _forbiddenFragments)
        if (text.contains(fragment)) fragment,
    ];
  }

  static void ensureSafe(CoachInsight insight) {
    final found = violations(insight);
    if (found.isNotEmpty) {
      throw StateError(
        'Coachregel ${insight.ruleId} bevat verboden causale taal: '
        '${found.join(', ')}',
      );
    }
    if (insight.possibleExplanations.length < 2) {
      throw StateError(
        'Coachregel ${insight.ruleId} moet meerdere mogelijke verklaringen '
        'geven.',
      );
    }
    if (insight.proposedExperiment.controlledVariable.trim().isEmpty) {
      throw StateError(
        'Coachregel ${insight.ruleId} moet een gecontroleerde variabele '
        'benoemen.',
      );
    }
  }
}
