import 'dart:io';
import 'dart:convert';

void main() {
  final directory = Directory('lib');
  final pattern = RegExp("(?:widget\\\\.)?isAr\\s*\\?\\s*(['\"])(.*?)\\1\\s*:\\s*(['\"])(.*?)\\3");
  
  final translations = <String, String>{}; // en -> ar
  int replacedCount = 0;

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;

      // Find all matches
      final matches = pattern.allMatches(content).toList();
      
      for (final match in matches.reversed) {
        final arString = match.group(2)!;
        final enString = match.group(4)!;
        
        if (arString.contains(r'$') || enString.contains(r'$')) {
          continue; // Skip interpolated strings for manual review later
        }

        translations[enString] = arString;
        
        // Use jsonEncode to safely escape the string and wrap it in double quotes!
        final safeString = jsonEncode(enString);
        final replacement = "$safeString.tr()";
        
        content = content.replaceRange(match.start, match.end, replacement);
        modified = true;
        replacedCount++;
      }

      if (modified) {
        // Also ensure easy_localization is imported if we are using .tr()
        if (!content.contains("easy_localization.dart") && !content.contains("import 'package:easy_localization")) {
          // Just inject it after the last import
          final importPattern = RegExp(r"import\s+['""].*?['""];\n");
          final importMatches = importPattern.allMatches(content);
          if (importMatches.isNotEmpty) {
            final lastImport = importMatches.last;
            content = content.replaceRange(lastImport.end, lastImport.end, "import 'package:easy_localization/easy_localization.dart' hide TextDirection;\n");
          } else {
             // If no imports, put at top
             content = "import 'package:easy_localization/easy_localization.dart' hide TextDirection;\n" + content;
          }
        }
        entity.writeAsStringSync(content);
      }
    }
  }

  final file = File('scratch/extracted_translations.json');
  file.createSync(recursive: true);
  
  // Format json
  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(translations));

  print('Successfully replaced $replacedCount occurrences and extracted ${translations.length} unique translations.');
}
