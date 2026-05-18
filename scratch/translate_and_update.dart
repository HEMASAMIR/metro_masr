import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyAqUr3eSodPnVq5glBKMw0RnbWGpTAOvuE'; // from .env
  final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  final extractedFile = File('scratch/extracted_translations.json');
  final extractedJson = jsonDecode(extractedFile.readAsStringSync()) as Map<String, dynamic>;

  // Load existing localization files
  final enFile = File('assets/translations/en.json');
  final arFile = File('assets/translations/ar.json');
  final frFile = File('assets/translations/fr.json');
  final deFile = File('assets/translations/de.json');

  final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final arMap = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
  final frMap = jsonDecode(frFile.readAsStringSync()) as Map<String, dynamic>;
  final deMap = jsonDecode(deFile.readAsStringSync()) as Map<String, dynamic>;

  final missingFr = <String, String>{};
  final missingDe = <String, String>{};

  for (final entry in extractedJson.entries) {
    final enKey = entry.key;
    final arVal = entry.value;

    enMap[enKey] = enKey;
    arMap[enKey] = arVal;

    if (!frMap.containsKey(enKey) || frMap[enKey] == enKey) {
      missingFr[enKey] = enKey;
    }
    if (!deMap.containsKey(enKey) || deMap[enKey] == enKey) {
      missingDe[enKey] = enKey;
    }
  }

  print('Missing FR: ${missingFr.length}, Missing DE: ${missingDe.length}');

  // Helper to translate in batches
  Future<void> translateMap(Map<String, String> targetMap, String language) async {
    final keys = targetMap.keys.toList();
    int batchSize = 100;
    
    for (int i = 0; i < keys.length; i += batchSize) {
      final batchKeys = keys.sublist(i, (i + batchSize > keys.length) ? keys.length : i + batchSize);
      final batchInput = {};
      for (var k in batchKeys) batchInput[k] = targetMap[k];

      print('Translating batch ${i ~/ batchSize + 1} for $language...');
      try {
        final prompt = '''
Translate the following JSON object's values into $language.
Keep the exact same keys. Return ONLY valid JSON, without any markdown formatting like ```json.
Input:
${jsonEncode(batchInput)}
''';
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        
        String resText = response.text ?? '{}';
        resText = resText.replaceAll('```json', '').replaceAll('```', '').trim();
        final translatedBatch = jsonDecode(resText) as Map<String, dynamic>;
        
        for (var k in translatedBatch.keys) {
          if (targetMap.containsKey(k)) {
            targetMap[k] = translatedBatch[k].toString();
          }
        }
      } catch (e) {
        print('Error translating batch for $language: $e');
      }
    }
  }

  if (missingFr.isNotEmpty) {
    await translateMap(missingFr, 'French');
    frMap.addAll(missingFr);
  }
  
  if (missingDe.isNotEmpty) {
    await translateMap(missingDe, 'German');
    deMap.addAll(missingDe);
  }

  // Save everything back
  final encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enMap));
  arFile.writeAsStringSync(encoder.convert(arMap));
  frFile.writeAsStringSync(encoder.convert(frMap));
  deFile.writeAsStringSync(encoder.convert(deMap));

  print('Translation update complete!');
}
