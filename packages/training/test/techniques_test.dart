import 'package:shooting_companion_training/training.dart';
import 'package:test/test.dart';

void main() {
  test('built-in technique topics have stable unique IDs and roundtrip', () {
    final ids = <String>{};
    for (final topic in BuiltInTechniques.all) {
      expect(ids.add(topic.versionedId), isTrue, reason: topic.versionedId);
      expect(TechniqueTopic.fromJson(topic.toJson()).toJson(), topic.toJson());
      expect(topic.sources, isNotEmpty);
      expect(
        topic.sources.every((source) => source.url.startsWith('https://')),
        isTrue,
      );
    }
  });

  test('library covers safety, execution, position and benchrest', () {
    final categories = BuiltInTechniques.all
        .map((topic) => topic.category)
        .toSet();
    expect(categories, contains(TechniqueCategory.safety));
    expect(categories, contains(TechniqueCategory.position));
    expect(categories, contains(TechniqueCategory.shotExecution));
    expect(categories, contains(TechniqueCategory.benchrest));
  });

  test('invalid source URL is rejected', () {
    expect(
      () => TechniqueSource.fromJson(const {
        'title': 'Onveilig',
        'url': 'http://example.test',
      }),
      throwsArgumentError,
    );
  });
}
