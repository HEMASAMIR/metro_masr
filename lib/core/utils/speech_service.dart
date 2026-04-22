import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;

  static Future<bool> init() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('SpeechService error: $error'),
      onStatus: (status) => debugPrint('SpeechService status: $status'),
    );
    return _isInitialized;
  }

  static bool get isListening => _speech.isListening;
  static bool get isAvailable => _isInitialized;

  /// Starts listening and calls [onResult] with recognised text.
  /// [localeId] can be 'ar-EG', 'en-US', 'fr-FR', 'de-DE'.
  static Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'ar-EG',
  }) async {
    if (!_isInitialized) {
      final ok = await init();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.search,
      ),
    );
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Returns true if [heard] fuzzy-matches [candidate] (Arabic or English).
  static bool fuzzyMatch(String heard, String candidate) {
    final h = heard.toLowerCase().trim();
    final c = candidate.toLowerCase().trim();
    if (h.isEmpty || c.isEmpty) return false;
    // Exact or substring match
    if (c.contains(h) || h.contains(c)) return true;
    // Simple character overlap ratio >= 60%
    final hChars = h.split('');
    final matches = hChars.where((ch) => c.contains(ch)).length;
    return matches / hChars.length >= 0.6;
  }
}
