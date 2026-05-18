import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('scratch/extracted_translations.json');
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final problematicKeys = map.keys.where((k) => k.contains("'")).toList();
  print('Found ${problematicKeys.length} keys with single quotes.');

  final directory = Directory('lib');
  int filesModified = 0;
  int replaceCount = 0;

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;

      for (final key in problematicKeys) {
        // The script erroneously replaced it with '$key'.tr()
        // Example: 'Today's Crowd'.tr()
        final brokenSyntax = "'$key'.tr()";
        if (content.contains(brokenSyntax)) {
          final fixedSyntax = '"$key".tr()'; // Wrap with double quotes instead
          content = content.replaceAll(brokenSyntax, fixedSyntax);
          modified = true;
          replaceCount++;
        }
      }

      if (modified) {
        entity.writeAsStringSync(content);
        filesModified++;
      }
    }
  }

  print('Fixed $replaceCount occurrences across $filesModified files.');
}
