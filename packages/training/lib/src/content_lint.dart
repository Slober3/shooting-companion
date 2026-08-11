import 'content_catalog.dart';
import 'content_v2.dart';

class TrainingContentIssue {
  const TrainingContentIssue({
    required this.code,
    required this.contentId,
    required this.message,
  });

  final String code;
  final String contentId;
  final String message;

  @override
  String toString() => '$code [$contentId] $message';
}

abstract final class TrainingContentLint {
  static List<TrainingContentIssue> validateBuiltIn(
    TrainingContentCatalog catalog,
  ) {
    final issues = validateCatalog(catalog);
    if (catalog.lessons.length != 18) {
      issues.add(_issue('count.lessons', 'catalog', 'Verwacht 18 lessen.'));
    }
    if (catalog.drills.length != 12) {
      issues.add(_issue('count.drills', 'catalog', 'Verwacht 12 drills.'));
    }
    if (catalog.learningPaths.length != 4) {
      issues.add(_issue('count.paths', 'catalog', 'Verwacht 4 leerpaden.'));
    }
    return issues;
  }

  static List<TrainingContentIssue> validateCatalog(
    TrainingContentCatalog catalog,
  ) {
    final issues = <TrainingContentIssue>[];
    final lessonIds = catalog.lessons.map((item) => item.versionedId).toSet();
    final drillIds = catalog.drills.map((item) => item.versionedId).toSet();
    final lessonsById = {
      for (final lesson in catalog.lessons) lesson.versionedId: lesson,
    };
    final drillsById = {
      for (final drill in catalog.drills) drill.versionedId: drill,
    };
    final pathIds = catalog.learningPaths
        .map((item) => item.versionedId)
        .toSet();
    _checkUnique(
      issues,
      catalog.lessons.map((item) => item.versionedId),
      'lesson',
    );
    _checkUnique(
      issues,
      catalog.drills.map((item) => item.versionedId),
      'drill',
    );
    _checkUnique(
      issues,
      catalog.learningPaths.map((item) => item.versionedId),
      'path',
    );

    for (final lesson in catalog.lessons) {
      final sourceIds = lesson.references.map((item) => item.id).toSet();
      final sectionTypes = lesson.sections.map((item) => item.type).toSet();
      for (final requiredType in TechniqueSectionType.values) {
        if (!sectionTypes.contains(requiredType)) {
          issues.add(
            _issue(
              'lesson.section.missing',
              lesson.versionedId,
              'Sectie ${requiredType.name} ontbreekt.',
            ),
          );
        }
      }
      for (final section in lesson.sections) {
        if (section.sourceIds.isEmpty) {
          issues.add(
            _issue(
              'lesson.section.unsourced',
              lesson.versionedId,
              'Sectie ${section.type.name} vereist minstens één bron-ID.',
            ),
          );
        }
        final sectionText = [...section.paragraphs, ...section.steps].join(' ');
        if (_wordCount(sectionText) < 5) {
          issues.add(
            _issue(
              'lesson.section.thin',
              lesson.versionedId,
              'Sectie ${section.type.name} is niet concreet genoeg.',
            ),
          );
        }
        for (final sourceId in section.sourceIds) {
          if (!sourceIds.contains(sourceId)) {
            issues.add(
              _issue(
                'reference.unknown',
                lesson.versionedId,
                'Sectie verwijst naar onbekende bron $sourceId.',
              ),
            );
          }
        }
      }
      for (final drillId in lesson.linkedDrillIds) {
        if (!drillIds.contains(drillId)) {
          issues.add(
            _issue(
              'lesson.drill.unknown',
              lesson.versionedId,
              'Onbekende gekoppelde drill $drillId.',
            ),
          );
        }
      }
      for (final prerequisite in lesson.prerequisites) {
        if (!lessonIds.contains(prerequisite)) {
          issues.add(
            _issue(
              'lesson.prerequisite.unknown',
              lesson.versionedId,
              'Onbekende voorwaarde $prerequisite.',
            ),
          );
        }
      }
      if (lesson.diagramIds.toSet().length != lesson.diagramIds.length) {
        issues.add(
          _issue(
            'lesson.diagram.duplicate',
            lesson.versionedId,
            'Dubbele diagram-ID.',
          ),
        );
      }
      _lintReferences(issues, lesson.versionedId, lesson.references);
      _lintReview(issues, lesson.versionedId, lesson.review);
      final lessonTexts = <String>[
        lesson.title,
        lesson.shortPromise,
        ...lesson.applicability,
        ...lesson.sections.expand(
          (section) => [section.title, ...section.paragraphs, ...section.steps],
        ),
        ...lesson.selfChecks.expand(
          (check) => [check.prompt, check.observableSuccess, check.resetIf],
        ),
        ...lesson.safetyCallouts.expand(
          (callout) => [callout.title, callout.instruction],
        ),
      ];
      _lintLanguage(issues, lesson.versionedId, lessonTexts);
      if (_mentionsDryFire(lessonTexts)) {
        final safetyText = lesson.safetyCallouts
            .expand((callout) => [callout.title, callout.instruction])
            .join(' ')
            .toLowerCase();
        if (!safetyText.contains('erkende baan') ||
            !safetyText.contains('munitie fysiek gescheiden')) {
          issues.add(
            _issue(
              'lesson.dryfire.safety',
              lesson.versionedId,
              'Een droge lesfase vereist een erkende baan en fysiek gescheiden munitie.',
            ),
          );
        }
      }
    }

    for (final drill in catalog.drills) {
      final primary = drill.measurements
          .where((item) => item.role == TrainingMeasurementRole.primary)
          .length;
      if (primary != 1) {
        issues.add(
          _issue(
            'drill.metric.primary',
            drill.versionedId,
            'Een drill vereist exact één primaire metric.',
          ),
        );
      }
      for (final measurement in drill.measurements) {
        if (measurement.metric == TrainingMetricKind.completion &&
            measurement.minimumSampleSize > drill.phases.length) {
          issues.add(
            _issue(
              'drill.metric.unreachable',
              drill.versionedId,
              'De voltooiingsdrempel is hoger dan het aantal drillfasen.',
            ),
          );
        }
      }
      for (final techniqueId in drill.techniqueReferences) {
        if (!lessonIds.contains(techniqueId)) {
          issues.add(
            _issue(
              'drill.lesson.unknown',
              drill.versionedId,
              'Onbekende techniek $techniqueId.',
            ),
          );
        }
      }
      for (final prerequisite in drill.prerequisites) {
        if (!lessonIds.contains(prerequisite) &&
            !drillIds.contains(prerequisite)) {
          issues.add(
            _issue(
              'drill.prerequisite.unknown',
              drill.versionedId,
              'Onbekende voorwaarde $prerequisite.',
            ),
          );
        }
      }
      final next = drill.progression.nextDrillId;
      if (next != null && !drillIds.contains(next)) {
        issues.add(
          _issue(
            'drill.next.unknown',
            drill.versionedId,
            'Onbekende vervolgdrill $next.',
          ),
        );
      }
      final drillTexts = <String>[
        drill.title,
        drill.shortPurpose,
        drill.setup.target,
        drill.setup.distance,
        ...drill.setup.equipment,
        drill.setup.dataBasis,
        drill.setup.safetyGate,
        ...drill.phases.expand((phase) => [phase.title, ...phase.instructions]),
        ...drill.measurements.map((item) => item.interpretation),
        drill.masteryRule.explanation,
        ...drill.stopRules,
        ...drill.reflectionPrompts,
        drill.progression.usableResult,
        drill.progression.insufficientData,
        drill.progression.unreliableResult,
      ];
      if (drill.mode == TrainingMode.rangeDryFire ||
          _mentionsDryFire(drillTexts)) {
        final gate = drill.setup.safetyGate.toLowerCase();
        final invalidBudget =
            drill.mode == TrainingMode.rangeDryFire &&
            drill.ammunitionBudget != 0;
        if (invalidBudget ||
            !gate.contains('erkende baan') ||
            !gate.contains('munitie fysiek gescheiden')) {
          issues.add(
            _issue(
              'drill.dryfire.safety',
              drill.versionedId,
              'Een droge drillfase vereist een erkende baan en fysiek gescheiden munitie; een volledig droge drill heeft nul patronen.',
            ),
          );
        }
      }
      if (_wordCount(drill.setup.dataBasis) < 4 ||
          _wordCount(drill.setup.safetyGate) < 6 ||
          drill.stopRules.any((item) => _wordCount(item) < 4) ||
          drill.reflectionPrompts.any((item) => _wordCount(item) < 4)) {
        issues.add(
          _issue(
            'drill.protocol.thin',
            drill.versionedId,
            'Setup, stopregels en reflectie moeten concrete criteria bevatten.',
          ),
        );
      }
      if (drill.masteryRule.usesPersonalBaseline &&
          (drill.masteryRule.minimumValidExecutions != 3 ||
              drill.masteryRule.requiredSuccesses != 2 ||
              drill.masteryRule.evaluationWindow != 3)) {
        issues.add(
          _issue(
            'drill.mastery.policy',
            drill.versionedId,
            'Persoonlijke baseline vereist 3 uitvoeringen en 2 successen uit 3.',
          ),
        );
      }
      _lintReferences(issues, drill.versionedId, drill.references);
      _lintReview(issues, drill.versionedId, drill.review);
      _lintLanguage(issues, drill.versionedId, drillTexts);
    }

    for (final path in catalog.learningPaths) {
      final entryIds = path.entries.map((item) => item.id).toSet();
      if (entryIds.length != path.entries.length) {
        issues.add(
          _issue('path.entry.duplicate', path.versionedId, 'Dubbele stap-ID.'),
        );
      }
      final seenEntryIds = <String>{};
      final seenContentIds = <String>{};
      for (final entry in path.entries) {
        final exists = entry.kind == LearningPathEntryKind.lesson
            ? lessonIds.contains(entry.versionedContentId)
            : drillIds.contains(entry.versionedContentId);
        if (!exists) {
          issues.add(
            _issue(
              'path.content.unknown',
              path.versionedId,
              'Onbekende content ${entry.versionedContentId}.',
            ),
          );
        }
        for (final prerequisite in entry.prerequisiteEntryIds) {
          if (!entryIds.contains(prerequisite) ||
              !seenEntryIds.contains(prerequisite) ||
              prerequisite == entry.id) {
            issues.add(
              _issue(
                'path.prerequisite.invalid',
                path.versionedId,
                'Ongeldige stapvoorwaarde $prerequisite.',
              ),
            );
          }
        }
        final contentPrerequisites = switch (entry.kind) {
          LearningPathEntryKind.lesson =>
            lessonsById[entry.versionedContentId]?.prerequisites ??
                const <String>[],
          LearningPathEntryKind.drill =>
            drillsById[entry.versionedContentId]?.prerequisites ??
                const <String>[],
        };
        for (final prerequisite in contentPrerequisites) {
          if (!seenContentIds.contains(prerequisite)) {
            issues.add(
              _issue(
                'path.content.prerequisite',
                path.versionedId,
                '${entry.versionedContentId} vereist eerst $prerequisite.',
              ),
            );
          }
        }
        seenEntryIds.add(entry.id);
        seenContentIds.add(entry.versionedContentId);
      }
      _lintReferences(issues, path.versionedId, path.references);
      _lintReview(issues, path.versionedId, path.review);
      _lintLanguage(issues, path.versionedId, [
        path.title,
        path.shortDescription,
      ]);
    }

    if (lessonIds.intersection(drillIds).isNotEmpty ||
        lessonIds.intersection(pathIds).isNotEmpty ||
        drillIds.intersection(pathIds).isNotEmpty) {
      issues.add(
        _issue(
          'catalog.id.collision',
          'catalog',
          'Content-ID botst over typen.',
        ),
      );
    }
    return issues;
  }

  static void _lintReferences(
    List<TrainingContentIssue> issues,
    String id,
    List<TrainingReference> references,
  ) {
    for (final reference in references) {
      if (reference.locator == null || reference.locator!.length < 8) {
        issues.add(
          _issue(
            'reference.locator',
            id,
            'Bron ${reference.id} vereist een concrete locator.',
          ),
        );
      }
      final uri = Uri.parse(reference.url);
      final path = uri.path.toLowerCase();
      final allowedLandingPage =
          reference.id.contains('safety') ||
          reference.id.contains('rules') ||
          path.endsWith('.pdf') ||
          path.contains('rules');
      if ((path.isEmpty || path == '/') && !allowedLandingPage) {
        issues.add(
          _issue(
            'reference.homepage',
            id,
            'Algemene homepage ${reference.id} is geen concrete bewijsbron.',
          ),
        );
      }
    }
  }

  static void _lintReview(
    List<TrainingContentIssue> issues,
    String id,
    ContentReview review,
  ) {
    if (review.coachReviewStatus == CoachReviewStatus.reviewed &&
        (review.reviewerRole == null || review.reviewedAtUtc == null)) {
      issues.add(
        _issue('review.missing', id, 'Coachreview mist reviewerrecord.'),
      );
    }
  }

  static void _lintLanguage(
    List<TrainingContentIssue> issues,
    String id,
    Iterable<String> texts,
  ) {
    final text = texts.join(' ').toLowerCase();
    const banned = <String>[
      'laag-links betekent',
      'de kaart bewijst dat',
      'deze flyer moet',
      'je bent vermoeid',
    ];
    for (final phrase in banned) {
      if (text.contains(phrase)) {
        issues.add(
          _issue('language.causal', id, 'Verboden causale frase: $phrase.'),
        );
      }
    }
    for (final candidate in texts) {
      final normalized = candidate.toLowerCase();
      final mentionsTargetEvidence = RegExp(
        r'\b(treffer(?:s)?|trefbeeld|groep|impact(?:s)?|schot(?:en)?)\b',
      ).hasMatch(normalized);
      final mentionsDirection = RegExp(
        r'\b(links|rechts|hoog|laag|boven|onder)\b',
      ).hasMatch(normalized);
      final makesCausalClaim = RegExp(
        r'\b(betekent(?: dat)?|bewijst(?: dat)?|wordt veroorzaakt door|worden veroorzaakt door|komt door)\b',
      ).hasMatch(normalized);
      final explicitlyRejectsClaim = RegExp(
        r'\b(geen|niet|nooit|onvoldoende)\b',
      ).hasMatch(normalized);
      if (mentionsTargetEvidence &&
          mentionsDirection &&
          makesCausalClaim &&
          !explicitlyRejectsClaim) {
        issues.add(
          _issue(
            'language.causal',
            id,
            'Trefbeeld en richting mogen geen technische oorzaak vastleggen.',
          ),
        );
      }
    }
    const genericOnly = <String>{
      'focus',
      'controleer',
      'wees consistent',
      'doe dit goed',
    };
    for (final candidate in texts) {
      final normalized = candidate
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zà-ÿ ]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (genericOnly.contains(normalized)) {
        issues.add(
          _issue(
            'language.generic',
            id,
            'Nietszeggende losse instructie: $candidate.',
          ),
        );
      }
    }
  }

  static void _checkUnique(
    List<TrainingContentIssue> issues,
    Iterable<String> ids,
    String type,
  ) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) {
        issues.add(_issue('$type.id.duplicate', id, 'Dubbele versie-ID.'));
      }
    }
  }

  static TrainingContentIssue _issue(String code, String id, String message) =>
      TrainingContentIssue(code: code, contentId: id, message: message);

  static int _wordCount(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;

  static bool _mentionsDryFire(Iterable<String> texts) => RegExp(
    r'\b(droog|droge|dry[ -]?fire)\b',
    caseSensitive: false,
  ).hasMatch(texts.join(' '));
}
