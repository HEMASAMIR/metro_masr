import 'dart:io';

void main() {
  final directory = Directory('lib');
  final pattern = RegExp(r"isAr\s*\?");
  int count = 0;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final matches = pattern.allMatches(content);
      if (matches.isNotEmpty) {
        count += matches.length;
        print('${entity.path} has ${matches.length} occurrences');
      }
    }
  }
  print('Total occurrences of isAr: $count');
}
