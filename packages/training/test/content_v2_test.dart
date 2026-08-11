import 'dart:convert';
import 'dart:io';

import 'package:shooting_companion_training/src/generated/built_in_content_json.g.dart';
import 'package:shooting_companion_training/training.dart';
import 'package:test/test.dart';

void main() {
  group('built-in V2 catalog', () {
    final catalog = BuiltInTrainingContent.catalog;

    test('contains the decision-complete 18/12/4 library', () {
      expect(catalog.lessons, hasLength(18));
      expect(catalog.drills, hasLength(12));
      expect(catalog.learningPaths, hasLength(4));
      expect(TrainingContentLint.validateBuiltIn(catalog), isEmpty);
      expect(
        catalog.lessons.expand((item) => item.disciplines).toSet(),
        equals({
          TrainingDiscipline.universal,
          TrainingDiscipline.precisionPistol,
          TrainingDiscipline.br50,
        }),
      );
    });

    test('embedded source is byte-identical to versioned JSON assets', () {
      expect(
        builtInTechniquesJson,
        File(TrainingContentAssetPaths.techniques).readAsStringSync(),
      );
      expect(
        builtInDrillsJson,
        File(TrainingContentAssetPaths.drills).readAsStringSync(),
      );
      expect(
        builtInLearningPathsJson,
        File(TrainingContentAssetPaths.learningPaths).readAsStringSync(),
      );
    });

    test('all records roundtrip without changing their snapshot', () {
      for (final lesson in catalog.lessons) {
        expect(
          TechniqueLessonV2.fromJson(lesson.toJson()).toJson(),
          equals(lesson.toJson()),
        );
      }
      for (final drill in catalog.drills) {
        expect(
          DrillDefinitionV2.fromJson(drill.toJson()).toJson(),
          equals(drill.toJson()),
        );
      }
      for (final path in catalog.learningPaths) {
        expect(
          LearningPathV2.fromJson(path.toJson()).toJson(),
          equals(path.toJson()),
        );
      }
    });

    test('all content has honest pending coach-review metadata', () {
      final reviews = <ContentReview>[
        ...catalog.lessons.map((item) => item.review),
        ...catalog.drills.map((item) => item.review),
        ...catalog.learningPaths.map((item) => item.review),
      ];
      expect(
        reviews.every(
          (review) =>
              review.coachReviewStatus == CoachReviewStatus.pending &&
              review.reviewerRole == null &&
              review.reviewedAtUtc == null,
        ),
        isTrue,
      );
    });

    test('all nineteen diagrams exist in the app registry', () {
      final requested = <String>{
        ...catalog.lessons.expand((item) => item.diagramIds),
        ...catalog.drills.expand((item) => item.diagramIds),
      };
      expect(requested, hasLength(19));
      final registrySource = File(
        '../../apps/mobile/lib/features/training_tools/'
        'training_diagram_canvas.dart',
      ).readAsStringSync();
      final registered = RegExp(
        r"'([-a-z0-9]+)':\s*TrainingDiagramDefinition\(",
      ).allMatches(registrySource).map((match) => match.group(1)!).toSet();
      expect(registered, containsAll(requested));
    });

    test('metric minimum sample sizes have explicit units', () {
      final units = catalog.drills
          .expand((drill) => drill.measurements)
          .map((measurement) => measurement.sampleUnit)
          .toSet();
      expect(units, contains(TrainingSampleUnit.linkedSeries));
      expect(units, contains(TrainingSampleUnit.positionedShots));
      expect(units, contains(TrainingSampleUnit.recordBulls));
      expect(units, contains(TrainingSampleUnit.reflections));
      expect(
        catalog.drills
            .expand((drill) => drill.measurements)
            .firstWhere(
              (measurement) =>
                  measurement.metric == TrainingMetricKind.absoluteBiasMm,
            )
            .sampleUnit,
        TrainingSampleUnit.positionedShots,
      );
    });

    test('legacy adapters preserve identity and usable instructions', () {
      final lesson = catalog.lessons.first.toLegacyTopic();
      final drill = catalog.drills.first.toLegacyDefinition();
      expect(lesson.versionedId, catalog.lessons.first.versionedId);
      expect(lesson.practiceSteps, isNotEmpty);
      expect(drill.versionedId, catalog.drills.first.versionedId);
      expect(drill.instructions, isNotEmpty);
    });
  });

  group('adversarial content validation', () {
    final builtIn = BuiltInTrainingContent.catalog;

    test('rejects a lesson section without a source', () {
      final lessonJson = _deepMap(builtIn.lessons.first.toJson());
      final sections = (lessonJson['sections']! as List).cast<Map>();
      sections.first['sourceIds'] = <String>[];
      expect(
        () => TrainingContentCatalog(
          lessons: [
            TechniqueLessonV2.fromJson(lessonJson),
            ...builtIn.lessons.skip(1),
          ],
          drills: builtIn.drills,
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('lesson.section.unsourced'),
          ),
        ),
      );
    });

    test('rejects a standalone generic instruction', () {
      final lessonJson = _deepMap(builtIn.lessons.first.toJson());
      lessonJson['shortPromise'] = 'Focus';
      expect(
        () => TrainingContentCatalog(
          lessons: [
            TechniqueLessonV2.fromJson(lessonJson),
            ...builtIn.lessons.skip(1),
          ],
          drills: builtIn.drills,
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('language.generic'),
          ),
        ),
      );
    });

    test('rejects range dry fire without recognized-range safety gate', () {
      final drillJson = _deepMap(builtIn.drills.first.toJson());
      (drillJson['setup']! as Map)['safetyGate'] =
          'Controleer de omgeving en begin daarna rustig.';
      expect(
        () => TrainingContentCatalog(
          lessons: builtIn.lessons,
          drills: [
            DrillDefinitionV2.fromJson(drillJson),
            ...builtIn.drills.skip(1),
          ],
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('drill.dryfire.safety'),
          ),
        ),
      );
    });

    test('rejects a mixed drill with an unsafe dry phase', () {
      final source = builtIn.drills.firstWhere(
        (drill) => drill.id == 'pistol-repeatable-window',
      );
      final drillJson = _deepMap(source.toJson());
      (drillJson['setup']! as Map)['safetyGate'] =
          'Droge voorbereiding op de baan; fasen met schot volgen de commando’s.';
      expect(
        () => TrainingContentCatalog(
          lessons: builtIn.lessons,
          drills: [
            ...builtIn.drills.where((drill) => drill.id != source.id),
            DrillDefinitionV2.fromJson(drillJson),
          ],
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('drill.dryfire.safety'),
          ),
        ),
      );
    });

    test('rejects a dry lesson without physical ammunition separation', () {
      final source = builtIn.lessons.firstWhere(
        (lesson) => lesson.id == 'pistol-sight-alignment-picture',
      );
      final lessonJson = _deepMap(source.toJson());
      final callouts = (lessonJson['safetyCallouts']! as List).cast<Map>();
      callouts.first['instruction'] =
          'Voer de droge fase uitsluitend uit op een erkende baan.';
      expect(
        () => TrainingContentCatalog(
          lessons: [
            ...builtIn.lessons.where((lesson) => lesson.id != source.id),
            TechniqueLessonV2.fromJson(lessonJson),
          ],
          drills: builtIn.drills,
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('lesson.dryfire.safety'),
          ),
        ),
      );
    });

    test('rejects causal target diagnosis in visible lesson content', () {
      final source = builtIn.lessons.firstWhere(
        (lesson) => lesson.id == 'reading-target-evidence',
      );
      final lessonJson = _deepMap(source.toJson());
      final sections = (lessonJson['sections']! as List).cast<Map>();
      (sections.first['paragraphs']! as List).first =
          'Treffers links worden veroorzaakt door trekkerdruk van de schutter.';
      expect(
        () => TrainingContentCatalog(
          lessons: [
            ...builtIn.lessons.where((lesson) => lesson.id != source.id),
            TechniqueLessonV2.fromJson(lessonJson),
          ],
          drills: builtIn.drills,
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('language.causal'),
          ),
        ),
      );
    });

    test('rejects a path that bypasses a content prerequisite', () {
      final source = builtIn.learningPaths.firstWhere(
        (path) => path.id == 'precision-pistol-foundations',
      );
      final pathJson = _deepMap(source.toJson());
      final entries = (pathJson['entries']! as List).cast<Map>();
      entries.removeWhere((entry) => entry['id'] == 'body');
      entries.firstWhere(
        (entry) => entry['id'] == 'grip',
      )['prerequisiteEntryIds'] = <String>[
        'stance',
      ];
      expect(
        () => TrainingContentCatalog(
          lessons: builtIn.lessons,
          drills: builtIn.drills,
          learningPaths: [
            LearningPathV2.fromJson(pathJson),
            ...builtIn.learningPaths.where((path) => path.id != source.id),
          ],
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('path.content.prerequisite'),
          ),
        ),
      );
    });

    test('rejects an unreachable completion threshold', () {
      final drillJson = _deepMap(builtIn.drills.first.toJson());
      final measurements = (drillJson['measurements']! as List).cast<Map>();
      measurements.firstWhere(
        (measurement) => measurement['metric'] == 'completion',
      )['minimumSampleSize'] = 99;
      expect(
        () => TrainingContentCatalog(
          lessons: builtIn.lessons,
          drills: [
            DrillDefinitionV2.fromJson(drillJson),
            ...builtIn.drills.skip(1),
          ],
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('drill.metric.unreachable'),
          ),
        ),
      );
    });

    test('rejects a generic homepage as sole evidence', () {
      final lessonJson = _deepMap(builtIn.lessons.first.toJson());
      final references = (lessonJson['references']! as List).cast<Map>();
      references.first
        ..['id'] = 'generic-guide'
        ..['url'] = 'https://example.org/'
        ..['locator'] = 'Een concrete maar niet verifieerbare locator';
      for (final section in (lessonJson['sections']! as List).cast<Map>()) {
        section['sourceIds'] = ['generic-guide'];
      }
      expect(
        () => TrainingContentCatalog(
          lessons: [
            TechniqueLessonV2.fromJson(lessonJson),
            ...builtIn.lessons.skip(1),
          ],
          drills: builtIn.drills,
          learningPaths: builtIn.learningPaths,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('reference.homepage'),
          ),
        ),
      );
    });

    test('constructors reject missing structural content', () {
      final lessonJson = _deepMap(builtIn.lessons.first.toJson());
      lessonJson['diagramIds'] = <String>[];
      expect(() => TechniqueLessonV2.fromJson(lessonJson), throwsArgumentError);

      final drillJson = _deepMap(builtIn.drills.first.toJson());
      drillJson['stopRules'] = <String>[];
      expect(() => DrillDefinitionV2.fromJson(drillJson), throwsArgumentError);
    });

    test('reviewed status requires a real reviewer record', () {
      expect(
        () => ContentReview(
          evidenceStatus: ContentEvidenceStatus.officialGuidance,
          coachReviewStatus: CoachReviewStatus.reviewed,
          sourceEdition: 'test',
          lastSourceCheckUtc: DateTime.utc(2026, 8, 10),
        ),
        throwsArgumentError,
      );
    });
  });
}

Map<String, Object?> _deepMap(Map<String, Object?> value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, Object?>();
