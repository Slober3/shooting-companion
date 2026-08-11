import 'dart:io';

const _sources = <String, String>{
  'builtInTechniquesJson': 'assets/content/v2/techniques.nl-BE.json',
  'builtInDrillsJson': 'assets/content/v2/drills.nl-BE.json',
  'builtInLearningPathsJson': 'assets/content/v2/learning_paths.nl-BE.json',
};

void main() {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart run tool/embed_content.dart')
    ..writeln();
  for (final entry in _sources.entries) {
    final content = File(entry.value).readAsStringSync();
    buffer
      ..write('const ${entry.key} = r\'\'\'')
      ..write(content)
      ..writeln("''';")
      ..writeln();
  }
  final output = File('lib/src/generated/built_in_content_json.g.dart');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(buffer.toString());
}
