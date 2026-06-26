import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'gemini_ai_service.dart';

class LiveMetroStatusService {
  static const String _cacheKey = 'live_metro_status_cache';
  static const String _timeKey = 'live_metro_status_time';
  
  // Cache duration to avoid API limits (30 minutes)
  static const int _cacheDurationMinutes = 30;

  /// Fetches the live status of the 3 Cairo Metro lines.
  /// Returns a Map<int, String> where key is line number, and value is 'normal' or 'delay'.
  static Future<Map<int, String>> fetchLiveStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check Cache
      final cachedTimeStr = prefs.getString(_timeKey);
      if (cachedTimeStr != null) {
        final cachedTime = DateTime.parse(cachedTimeStr);
        if (DateTime.now().difference(cachedTime).inMinutes < _cacheDurationMinutes) {
          final cachedData = prefs.getString(_cacheKey);
          if (cachedData != null) {
            return _parseJsonStatus(cachedData);
          }
        }
      }

      // 2. Fetch Latest News via Google News RSS for Cairo Metro delays
      final titles = await _fetchNewsTitles();
      
      if (titles.isEmpty) {
        // If no news, assume everything is normal
        return _defaultNormalStatus();
      }

      // 3. Ask Gemini to analyze the news titles
      final jsonStatus = await _analyzeWithGemini(titles);
      
      // 4. Cache the result
      await prefs.setString(_cacheKey, jsonStatus);
      await prefs.setString(_timeKey, DateTime.now().toIso8601String());

      return _parseJsonStatus(jsonStatus);
    } catch (e) {
      debugPrint('LiveMetroStatusService Error: $e');
      // On any error (no internet, rate limit), fallback to normal to not panic users
      return _defaultNormalStatus();
    }
  }

  static Future<List<String>> _fetchNewsTitles() async {
    try {
      final dio = Dio();
      // Search for "مترو الأنفاق عطل" in the last 24 hours (when:1d)
      final url = 'https://news.google.com/rss/search?q=%D9%85%D8%AA%D8%B1%D9%88+%D8%A7%D9%84%D8%A3%D9%86%D9%81%D8%A7%D9%82+%D8%B9%D8%B7%D9%84+when:1d&hl=ar&gl=EG&ceid=EG:ar';
      
      final response = await dio.get(url, options: Options(responseType: ResponseType.plain));
      final xmlString = response.data.toString();
      
      // Simple Regex to extract <title> tags. 
      // This is lightweight and doesn't require a heavy XML parser.
      final RegExp titleExp = RegExp(r'<title>(.*?)<\/title>');
      final matches = titleExp.allMatches(xmlString);
      
      List<String> titles = [];
      // Skip the first title because it's usually just the feed title
      bool first = true;
      for (final match in matches) {
        if (first) {
          first = false;
          continue;
        }
        final title = match.group(1) ?? '';
        // Clean up Google News suffix if needed
        titles.add(title.replaceAll(' - أخبار Google', ''));
      }
      
      // Limit to top 10 recent news to avoid huge prompts
      if (titles.length > 10) {
        titles = titles.sublist(0, 10);
      }
      return titles;
    } catch (e) {
      debugPrint('RSS Fetch Error: $e');
      return [];
    }
  }

  static Future<String> _analyzeWithGemini(List<String> titles) async {
    final apiKey = GeminiAiService.apiKey;
    if (apiKey.isEmpty) {
      throw Exception('Missing Gemini API Key');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final prompt = '''
You are an Egyptian Metro transit analyst. Read the following recent news headlines about Cairo Metro.
Determine if there is currently a delay, breakdown, or maintenance issue on Line 1, Line 2, or Line 3.
If the news headlines mention an issue specifically on a line, mark it as "delay". Otherwise, mark it as "normal".
If the news is completely unrelated to a metro delay (e.g., traffic on roads, normal news), return "normal" for all.
Return ONLY a strictly valid JSON object, nothing else. No markdown formatting.

Format:
{"1": "normal", "2": "normal", "3": "normal"}

News Headlines:
${titles.join('\n')}
''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    
    // Clean up response in case Gemini added markdown like ```json ... ```
    String rawJson = response.text ?? '{}';
    rawJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
    
    return rawJson;
  }

  static Map<int, String> _parseJsonStatus(String jsonStr) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return {
        1: decoded['1']?.toString() ?? 'normal',
        2: decoded['2']?.toString() ?? 'normal',
        3: decoded['3']?.toString() ?? 'normal',
      };
    } catch (e) {
      return _defaultNormalStatus();
    }
  }

  static Map<int, String> _defaultNormalStatus() {
    return {1: 'normal', 2: 'normal', 3: 'normal'};
  }
}
