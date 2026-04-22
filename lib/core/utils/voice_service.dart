import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  static Future<void> speak(String text, String languageCode) async {
    // Map language codes to TTS supported locales
    String locale = "en-US";
    if (languageCode == "ar") locale = "ar-SA";
    if (languageCode == "fr") locale = "fr-FR";
    if (languageCode == "de") locale = "de-DE";

    await _flutterTts.setLanguage(locale);
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}
