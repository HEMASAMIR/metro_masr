import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiAiService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
  }

  static String get apiKey {
    if (_prefs != null) {
      final customKey = _prefs!.getString('custom_gemini_api_key');
      if (customKey != null && customKey.trim().isNotEmpty) {
        return customKey.trim();
      }
    }
    String key = const String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      try {
        key = dotenv.get('GEMINI_API_KEY', fallback: '');
      } catch (_) {}
    }
    return key;
  }

  static Future<void> setCustomApiKey(String newKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('custom_gemini_api_key', newKey.trim());
  }

  static Future<void> clearCustomApiKey() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('custom_gemini_api_key');
  }

  static GenerativeModel getModel({String? systemInstruction}) {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null,
    );
  }
}
