import 'dart:convert';

import 'content_lint.dart';
import 'content_v2.dart';
import 'generated/built_in_content_json.g.dart';

abstract final class TrainingContentAssetPaths {
  static const techniques = 'assets/content/v2/techniques.nl-BE.json';
  static const drills = 'assets/content/v2/drills.nl-BE.json';
  static const learningPaths = 'assets/content/v2/learning_paths.nl-BE.json';
}

class TrainingContentCatalog {
  TrainingContentCatalog({
    required Iterable<TechniqueLessonV2> lessons,
    required Iterable<DrillDefinitionV2> drills,
    required Iterable<LearningPathV2> learningPaths,
  }) : lessons = List.unmodifiable(lessons),
       drills = List.unmodifiable(drills),
       learningPaths = List.unmodifiable(learningPaths) {
    final issues = TrainingContentLint.validateCatalog(this);
    if (issues.isNotEmpty) {
      throw FormatException(issues.map((issue) => issue.toString()).join('\n'));
    }
  }

  factory TrainingContentCatalog.fromJsonStrings({
    required String techniquesJson,
    required String drillsJson,
    required String learningPathsJson,
  }) {
    Map<String, Object?> decodeDocument(String source, String label) {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw FormatException('$label moet een JSON-object zijn.');
      }
      final document = decoded.cast<String, Object?>();
      if (document['schemaVersion'] != 2 || document['locale'] != 'nl-BE') {
        throw FormatException('$label vereist schemaVersion 2 en nl-BE.');
      }
      return document;
    }

    final techniques = decodeDocument(techniquesJson, 'Technieken');
    final drills = decodeDocument(drillsJson, 'Drills');
    final paths = decodeDocument(learningPathsJson, 'Leerpaden');
    return TrainingContentCatalog(
      lessons: _objects(techniques['lessons']).map(TechniqueLessonV2.fromJson),
      drills: _objects(drills['drills']).map(DrillDefinitionV2.fromJson),
      learningPaths: _objects(
        paths['learningPaths'],
      ).map(LearningPathV2.fromJson),
    );
  }

  final List<TechniqueLessonV2> lessons;
  final List<DrillDefinitionV2> drills;
  final List<LearningPathV2> learningPaths;

  TechniqueLessonV2? lessonByVersionedId(String id) =>
      _singleOrNull(lessons.where((item) => item.versionedId == id));

  DrillDefinitionV2? drillByVersionedId(String id) =>
      _singleOrNull(drills.where((item) => item.versionedId == id));

  LearningPathV2? learningPathByVersionedId(String id) =>
      _singleOrNull(learningPaths.where((item) => item.versionedId == id));
}

abstract final class BuiltInTrainingContent {
  static final TrainingContentCatalog catalog =
      TrainingContentCatalog.fromJsonStrings(
        techniquesJson: builtInTechniquesJson,
        drillsJson: builtInDrillsJson,
        learningPathsJson: builtInLearningPathsJson,
      );
}

Iterable<Map<String, Object?>> _objects(Object? value) sync* {
  if (value is! List) throw const FormatException('Verwachte een JSON-lijst.');
  for (final item in value) {
    if (item is! Map) throw const FormatException('Ongeldig lijstitem.');
    yield item.cast<String, Object?>();
  }
}

T? _singleOrNull<T>(Iterable<T> items) {
  final iterator = items.iterator;
  if (!iterator.moveNext()) return null;
  final value = iterator.current;
  if (iterator.moveNext()) throw StateError('Dubbele content-ID.');
  return value;
}
