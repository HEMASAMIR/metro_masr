import 'dart:io';
import 'dart:convert';

void main() {
  final directory = Directory('lib');
  final pattern = RegExp(r"isAr\s*\?\s*['""](.*?)['""]\s*:\s*['""](.*?)['""]");
  
  final results = [];
  
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final matches = pattern.allMatches(content);
      if (matches.isNotEmpty) {
        final fileMatches = [];
        for (final match in matches) {
          fileMatches.add({
            'ar': match.group(1),
            'en': match.group(2)
          });
        }
        results.add({
          'file': entity.path,
          'matches': fileMatches
        });
      }
    }
  }
  
  final file = File('scratch/extracted_strings.json');
  file.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(results));
  
  int totalStrings = 0;
  for (var r in results) {
    totalStrings += (r['matches'] as List).length;
  }
  print('Extracted $totalStrings strings from ${results.length} files.');
}
