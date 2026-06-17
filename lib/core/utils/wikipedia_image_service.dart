import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

class WikipediaImageService {
  static final Dio _dio = Dio();
  static final Map<String, String> _imageCache = {};

  static Future<String?> getRealImage(String name) async {
    if (name.isEmpty) return null;
    if (_imageCache.containsKey(name)) {
      return _imageCache[name];
    }

    // Try reading from persistent cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString("wiki_img_$name");
      if (cachedUrl != null) {
        _imageCache[name] = cachedUrl;
        return cachedUrl;
      }
    } catch (_) {}

    // If offline, stop immediately
    if (ConnectivityService.instance.isOffline) {
      return null;
    }

    try {
      // Clean name: remove content in parentheses and punctuation
      String cleanName = name
          .replaceAll(RegExp(r'\([\s\S]*?\)'), '')
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
          .trim();
          
      if (cleanName.isEmpty) return null;

      // Try Arabic first (for Egyptian locations), then English
      for (final lang in ['ar', 'en']) {
        final url = 'https://$lang.wikipedia.org/w/api.php';
        final response = await _dio.get(
          url,
          queryParameters: {
            'action': 'query',
            'generator': 'search',
            'gsrsearch': cleanName,
            'gsrlimit': 1,
            'prop': 'pageimages',
            'piprop': 'original',
            'format': 'json',
            'origin': '*',
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final query = response.data['query'];
          if (query != null) {
            final pages = query['pages'] as Map?;
            if (pages != null && pages.isNotEmpty) {
              final page = pages.values.first;
              final original = page['original'];
              if (original != null && original['source'] != null) {
                final imageUrl = original['source'] as String;
                
                // Validate that the image URL is not a placeholder/icon/logo
                final lowerUrl = imageUrl.toLowerCase();
                final isPlaceholder = lowerUrl.endsWith('.svg') ||
                    lowerUrl.contains('no_image') ||
                    lowerUrl.contains('no-image') ||
                    lowerUrl.contains('placeholder') ||
                    lowerUrl.contains('disambig') ||
                    lowerUrl.contains('question') ||
                    lowerUrl.contains('missing') ||
                    lowerUrl.contains('default') ||
                    lowerUrl.contains('logo') ||
                    lowerUrl.contains('icon') ||
                    lowerUrl.contains('image_not_available');

                if (!isPlaceholder) {
                  _imageCache[name] = imageUrl;

                  // Save to persistent cache
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString("wiki_img_$name", imageUrl);
                  } catch (_) {}

                  return imageUrl;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // Return null quietly to fallback to category default
    }
    return null;
  }
}
