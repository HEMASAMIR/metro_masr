import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tourism_data.dart';
import 'connectivity_service.dart';
import 'gemini_ai_service.dart';

class EnrichedPlaceData {
  final String description;
  final String didYouKnow;
  final List<Map<String, String>> highlights; // [{icon, value, label}]
  final List<String> tags;

  EnrichedPlaceData({
    required this.description,
    required this.didYouKnow,
    required this.highlights,
    required this.tags,
  });

  factory EnrichedPlaceData.fromJson(Map<String, dynamic> json) {
    var rawHighlights = json['highlights'] as List? ?? [];
    List<Map<String, String>> parsedHighlights = rawHighlights.map((item) {
      if (item is Map) {
        return {
          'icon': item['icon']?.toString() ?? '📍',
          'value': item['value']?.toString() ?? 'N/A',
          'label': item['label']?.toString() ?? 'Detail',
        };
      }
      return {'icon': '📍', 'value': 'N/A', 'label': 'Detail'};
    }).toList();

    var rawTags = json['tags'] as List? ?? [];
    List<String> parsedTags = rawTags.map((e) => e.toString()).toList();

    return EnrichedPlaceData(
      description: json['description']?.toString() ?? '',
      didYouKnow: json['didYouKnow']?.toString() ?? '',
      highlights: parsedHighlights,
      tags: parsedTags,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'didYouKnow': didYouKnow,
        'highlights': highlights,
        'tags': tags,
      };
}

class PlaceEnrichmentService {
  static final Map<String, EnrichedPlaceData> _memoryCache = {};

  // ✅ Bump this version whenever you want to invalidate old cache
  static const String _cacheVersion = 'v2';

  static Future<EnrichedPlaceData> enrichPlace(
    TouristAttraction attraction,
    String lang,
  ) async {
    final cacheKey = "${_cacheVersion}_${attraction.id}_$lang";

    // 1. Check memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. Check SharedPreferences cache — only accept versioned keys
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString("enrich_$cacheKey");
      if (cachedJson != null) {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        // Only use cache if it has a real description (not empty fallback)
        final data = EnrichedPlaceData.fromJson(decoded);
        if (data.description.length > 100) {
          _memoryCache[cacheKey] = data;
          return data;
        } else {
          // Stale/empty cache — delete it and re-fetch
          await prefs.remove("enrich_$cacheKey");
        }
      }
    } catch (e) {
      debugPrint("SharedPreferences read error: $e");
    }

    // 3. If offline, return fallback data immediately
    if (ConnectivityService.instance.isOffline) {
      final fallback = _getFallbackData(attraction, lang);
      _memoryCache[cacheKey] = fallback;
      return fallback;
    }

    // 4. Fetch from Gemini API
    try {
      String apiKey = GeminiAiService.apiKey;
      if (apiKey.isEmpty) {
        throw Exception("Gemini API key is not configured.");
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final name = attraction.name[lang] ?? attraction.name['en'] ?? attraction.id;
      final categoryLabel = TourismDatabase.categoryLabel[attraction.category]?['en'] ?? "Place";

      final prompt = '''
You are an expert local guide and travel historian in Egypt. 
Write a highly detailed, comprehensive, and engaging tourist overview of the place: '$name' (Category: $categoryLabel) in the requested language (language code: $lang).
Your response MUST be a strictly valid JSON object with the following schema:
{
  "description": "Write a complete, highly detailed description of the place. It must be at least 4 detailed paragraphs covering history, significance, top highlights, best time to visit, and local tips. The text must be in the requested language ($lang). Do not include any markdown headings or bullet points inside the description, only write long paragraphs separated by \\n\\n.",
  "didYouKnow": "A single, highly interesting, historical, or surprising fact about this place. Keep it interesting and in $lang.",
  "highlights": [
    {"icon": "🏛️", "value": "e.g., 1869 or 10 min", "label": "e.g., Opened or Walk"},
    {"icon": "⭐", "value": "4.5", "label": "Rating"},
    {"icon": "🚶", "value": "5-10m", "label": "Entry"},
    {"icon": "🎟️", "value": "Free / 50 EGP", "label": "Ticket"}
  ],
  "tags": ["historical", "museum", "family-friendly"]
}

Ensure that the highlights array has 4 objects matching the style above, choosing appropriate icons and labels relevant to the place category ($categoryLabel).
All text returned in the JSON (description, didYouKnow, labels, tags) MUST be translated to the requested language ($lang) unless they are names/technical terms.
Return ONLY the JSON. No markdown code blocks, no ```json, no extra text.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final decoded = jsonDecode(responseText) as Map<String, dynamic>;
      final data = EnrichedPlaceData.fromJson(decoded);

      // Save to memory cache
      _memoryCache[cacheKey] = data;

      // Save to SharedPreferences cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("enrich_$cacheKey", jsonEncode(data.toJson()));
      } catch (e) {
        debugPrint("SharedPreferences write error: $e");
      }

      return data;
    } catch (e) {
      debugPrint("PlaceEnrichmentService Error: $e");
      // Fallback data if Gemini fails
      final fallback = _getFallbackData(attraction, lang);
      _memoryCache[cacheKey] = fallback;
      return fallback;
    }
  }

  static EnrichedPlaceData _getFallbackData(TouristAttraction attraction, String lang) {
    final isAr = lang == 'ar';
    final desc = attraction.description[lang] ?? attraction.description['en'] ?? '';
    
    return EnrichedPlaceData(
      description: desc + (isAr 
          ? "\n\nيتميز هذا المكان بموقعه الفريد وأجوائه الرائعة، ويعتبر وجهة ممتازة للزوار الراغبين في الاستمتاع بالمعالم المحلية والأنشطة الترفيهية المتنوعة."
          : "\n\nThis place is known for its unique location and wonderful atmosphere, making it a great destination for visitors wishing to enjoy local sights and various recreational activities."),
      didYouKnow: isAr 
          ? "يتم تحديث تفاصيل ومعلومات هذا الموقع باستمرار عبر خرائط مجتمع المساهمين."
          : "Details and information about this location are constantly updated via community contributor maps.",
      highlights: [
        {'icon': '⭐', 'value': attraction.rating.toString(), 'label': isAr ? 'التقييم' : 'Rating'},
        {'icon': '🚶', 'value': attraction.walkingMinutes, 'label': isAr ? 'سيرًا' : 'Walk'},
        {'icon': '🎟️', 'value': attraction.isFree ? (isAr ? 'مجاني' : 'Free') : attraction.admissionEGP, 'label': isAr ? 'الدخول' : 'Entry'},
        {'icon': '⏰', 'value': attraction.openHours.length > 15 ? attraction.openHours.substring(0, 15) : attraction.openHours, 'label': isAr ? 'المواعيد' : 'Hours'},
      ],
      tags: attraction.tags,
    );
  }
}
