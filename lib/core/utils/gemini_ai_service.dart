import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAiService {
  static String get apiKey {
    String key = const String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      try {
        key = dotenv.get('GEMINI_API_KEY', fallback: '');
      } catch (_) {}
    }
    return key;
  }

  static GenerativeModel getModel({String? systemInstruction}) {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null,
    );
  }
}
