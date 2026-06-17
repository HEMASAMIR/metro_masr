import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'tourism_data.dart';
import 'connectivity_service.dart';

/// خدمة جلب البيانات من OpenStreetMap عبر Overpass API
class OsmService {
  static final Dio _dio = Dio();

  // قائمة بسيرفرات المرايا لضمان الاستمرارية لو واحد وقع أو عمل Block
  static const List<String> _overpassMirrors = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://lz4.overpass-api.de/api/interpreter",
  ];

  // كاش بسيط في الميموري لمنع تكرار الطلبات في نفس الجلسة
  static final Map<String, List<TouristAttraction>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};

  static Map<String, dynamic> _attractionToJson(TouristAttraction attr) {
    return {
      'id': attr.id,
      'name': attr.name,
      'description': attr.description,
      'category': attr.category.name,
      'emoji': attr.emoji,
      'rating': attr.rating,
      'openHours': attr.openHours,
      'isFree': attr.isFree,
      'admissionEGP': attr.admissionEGP,
      'walkingMinutes': attr.walkingMinutes,
      'boardingHint': attr.boardingHint,
      'tags': attr.tags,
      'lat': attr.lat,
      'lng': attr.lng,
      'imageUrl': attr.imageUrl,
      'wikiUrl': attr.wikiUrl,
      'galleryUrls': attr.galleryUrls,
    };
  }

  static TouristAttraction _attractionFromJson(Map<String, dynamic> json) {
    return TouristAttraction(
      id: json['id'] as String,
      name: Map<String, String>.from(json['name'] ?? {}),
      description: Map<String, String>.from(json['description'] ?? {}),
      category: AttractionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AttractionCategory.landmark,
      ),
      emoji: json['emoji'] as String? ?? "📍",
      rating: (json['rating'] as num?)?.toDouble() ?? 4.2,
      openHours: json['openHours'] as String? ?? "Check locally",
      isFree: json['isFree'] as bool? ?? true,
      admissionEGP: json['admissionEGP'] as String? ?? "N/A",
      walkingMinutes: json['walkingMinutes'] as String? ?? "5-10",
      boardingHint: json['boardingHint'] != null
          ? Map<String, String>.from(json['boardingHint'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      wikiUrl: json['wikiUrl'] as String?,
      galleryUrls: json['galleryUrls'] != null
          ? List<String>.from(json['galleryUrls'])
          : null,
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // math.pi / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // Returns meters
  }

  static Future<void> _saveToPersistentCache(String key, List<TouristAttraction> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((e) => _attractionToJson(e)).toList();
      await prefs.setString("osm_cache_$key", jsonEncode(jsonList));
      
      final parts = key.split('_');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          List<String> keys = prefs.getStringList("osm_cache_keys") ?? [];
          if (!keys.contains(key)) {
            keys.add(key);
            await prefs.setStringList("osm_cache_keys", keys);
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to save OSM cache: $e");
    }
  }

  static Future<List<TouristAttraction>?> _loadFromPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString("osm_cache_$key");
      if (data != null) {
        final list = jsonDecode(data) as List;
        return list.map((e) => _attractionFromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("Failed to load OSM cache: $e");
    }
    return null;
  }

  static Future<List<TouristAttraction>> _findClosestCachedPlaces(double lat, double lng, AttractionCategory? category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getStringList("osm_cache_keys") ?? [];
      String? bestKey;
      double minDistance = double.infinity;

      for (final key in keys) {
        final parts = key.split('_');
        if (parts.length >= 3) {
          final kLat = double.tryParse(parts[0]);
          final kLng = double.tryParse(parts[1]);
          final kCat = parts[2];
          final reqCatName = category?.name ?? 'all';
          if (kLat != null && kLng != null && kCat == reqCatName) {
            final distance = _calculateDistance(lat, lng, kLat, kLng);
            if (distance < minDistance && distance < 3000) { // Within 3km
              minDistance = distance;
              bestKey = key;
            }
          }
        }
      }

      if (bestKey != null) {
        final cached = await _loadFromPersistentCache(bestKey);
        if (cached != null) {
          debugPrint("Offline Mode: Found closest cached places at distance ${minDistance.round()}m");
          return cached;
        }
      }
    } catch (e) {
      debugPrint("Error finding offline cached places: $e");
    }
    return [];
  }

  /// جلب الأماكن القريبة (مطاعم، كافيهات، متاحف، نوادي، ترفيه) حول نقطة معينة
  static Future<List<TouristAttraction>> fetchNearbyAmenities(
    double lat,
    double lng, {
    double radius = 1200,
    AttractionCategory? category,
    CancelToken? cancelToken,
  }) async {
    final reqCategoryName = category?.name ?? 'all';
    final cacheKey = "${lat}_${lng}_$reqCategoryName";

    // لو الجهاز أوفلاين، ابحث عن أقرب إحداثيات مخزنة فوراً
    if (ConnectivityService.instance.isOffline) {
      return await _findClosestCachedPlaces(lat, lng, category);
    }

    // لو الداتا موجودة في الكاش ومعداش عليها 5 دقايق، هاتها فوراً
    if (_cache.containsKey(cacheKey)) {
      final diff = DateTime.now().difference(_cacheTime[cacheKey]!);
      if (diff.inMinutes < 5) {
        return _cache[cacheKey]!;
      }
    }

    String filter = "";

    if (category == null) {
      // البحث العام عن كل شيء (الحالة الافتراضية)
      filter =
          """
        node["amenity"~"restaurant|cafe|fast_food|bar|pub|cinema|theatre|nightclub|community_centre"](around:$radius, $lat, $lng);
        node["tourism"~"museum|attraction|viewpoint|zoo|artwork"](around:$radius, $lat, $lng);
        node["leisure"~"park|garden|sports_centre|stadium|fitness_centre|playground|club"](around:$radius, $lat, $lng);
        way["amenity"~"restaurant|cafe|cinema|theatre"](around:$radius, $lat, $lng);
        way["leisure"~"park|garden|sports_centre|stadium"](around:$radius, $lat, $lng);
      """;
    } else {
      // بناء استعلام مخصص بناءً على فئة المكان المختار في التطبيق
      switch (category) {
        case AttractionCategory.restaurant:
          filter =
              'node["amenity"~"restaurant|fast_food|food_court"](around:$radius, $lat, $lng); way["amenity"~"restaurant|fast_food"](around:$radius, $lat, $lng);';
          break;
        case AttractionCategory.cafe:
          filter =
              'node["amenity"~"cafe|bar|pub"](around:$radius, $lat, $lng); way["amenity"~"cafe"](around:$radius, $lat, $lng);';
          break;
        case AttractionCategory.museum:
          filter =
              'node["tourism"~"museum|artwork|attraction|gallery"](around:$radius, $lat, $lng);';
          break;
        case AttractionCategory.park:
          filter =
              'node["leisure"~"park|garden|nature_reserve"](around:$radius, $lat, $lng); way["leisure"~"park|garden"](around:$radius, $lat, $lng);';
          break;
        case AttractionCategory.sport:
          filter =
              'node["leisure"~"sports_centre|stadium|fitness_centre|club"](around:$radius, $lat, $lng); way["leisure"~"sports_centre|stadium"](around:$radius, $lat, $lng);';
          break;
        case AttractionCategory.entertainment:
          filter =
              'node["amenity"~"cinema|theatre|nightclub|casino|arts_centre"](around:$radius, $lat, $lng); way["amenity"~"cinema|theatre"](around:$radius, $lat, $lng);';
          break;
        default:
          filter = 'node(around:$radius, $lat, $lng);';
      }
    }

    final String query =
        """
      [out:json];
      (
        $filter
      );
      out center;
    """;

    // محاولة الاتصال بالمرايا المتاحة بالتتابع في حالة فشل واحد
    for (String url in _overpassMirrors) {
      try {
        final response = await _dio.post(
          url,
          data: {'data': query},
          cancelToken: cancelToken,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'User-Agent': 'RafiqMetro_Assistant/1.1',
              'Accept': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final List elements = response.data['elements'] ?? [];
          final results = elements
              .map((e) => _mapOsmElementToAttraction(e))
              .toList();

          // حفظ في الكاش
          _cache[cacheKey] = results;
          _cacheTime[cacheKey] = DateTime.now();

          // حفظ في الكاش المستمر
          await _saveToPersistentCache(cacheKey, results);

          return results;
        }
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) rethrow;
        continue; // جرب المراية اللي بعدها
      }
    }
    return _cache[cacheKey] ?? []; // لو كله فشل، رجع الكاش القديم لو متاح
  }

  static const Map<AttractionCategory, String> categoryDefaultImages = {
    AttractionCategory.restaurant: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=600",
    AttractionCategory.cafe: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?q=80&w=600",
    AttractionCategory.museum: "https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?q=80&w=600",
    AttractionCategory.park: "https://images.unsplash.com/photo-1502082553048-f009c37129b9?q=80&w=600",
    AttractionCategory.sport: "https://images.unsplash.com/photo-1517649763962-0c623066013b?q=80&w=600",
    AttractionCategory.entertainment: "https://images.unsplash.com/photo-1513151233558-d860c5398176?q=80&w=600",
    AttractionCategory.landmark: "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?q=80&w=600",
  };

  static TouristAttraction _mapOsmElementToAttraction(
    Map<String, dynamic> element,
  ) {
    final tags = element['tags'] ?? {};
    final id = element['id'].toString();

    // الحصول على الإحداثيات (سواء كانت نقطة أو مركز مساحة)
    final double? lat =
        element['lat']?.toDouble() ?? element['center']?['lat']?.toDouble();
    final double? lng =
        element['lon']?.toDouble() ?? element['center']?['lon']?.toDouble();

    final nameAr = tags['name:ar'] ?? tags['name'] ?? "مكان غير مسمى";
    final nameEn = tags['name:en'] ?? tags['name'] ?? "Unnamed Place";

    // تحديد الفئة والأيقونة بناءً على التاجات من OSM
    AttractionCategory category = AttractionCategory.landmark;
    String emoji = "📍";

    final amenity = tags['amenity'];
    final tourism = tags['tourism'];
    final leisure = tags['leisure'];

    if (amenity == 'restaurant' || amenity == 'fast_food') {
      category = AttractionCategory.restaurant;
      emoji = "🍔";
    } else if (amenity == 'cafe') {
      category = AttractionCategory.cafe;
      emoji = "☕";
    } else if (tourism == 'museum') {
      category = AttractionCategory.museum;
      emoji = "🏛️";
    } else if (leisure == 'park' || leisure == 'garden') {
      category = AttractionCategory.park;
      emoji = "🌳";
    } else if (leisure != null &&
        (leisure.toString().contains('sports') ||
            leisure == 'stadium' ||
            leisure == 'fitness_centre')) {
      category = AttractionCategory.sport;
      emoji = "🏆";
    } else if (amenity == 'cinema' ||
        amenity == 'theatre' ||
        amenity == 'nightclub') {
      category = AttractionCategory.entertainment;
      emoji = "🎭";
    }

    return TouristAttraction(
      id: "osm_$id",
      name: {'ar': nameAr, 'en': nameEn},
      description: {
        'ar':
            tags['description:ar'] ??
            tags['description'] ??
            "تم العثور على هذا المكان عبر OpenStreetMap (OSM).",
        'en':
            tags['description:en'] ??
            tags['description'] ??
            "Found via OpenStreetMap (OSM).",
      },
      category: category,
      emoji: emoji,
      rating: 4.2,
      openHours: tags['opening_hours'] ?? "Check locally",
      isFree: true,
      admissionEGP: "N/A",
      walkingMinutes: "5-10",
      tags: [amenity ?? tourism ?? leisure ?? "osm"],
      lat: lat,
      lng: lng,
      imageUrl: categoryDefaultImages[category],
      wikiUrl: tags['wikipedia'] != null
          ? "https://en.wikipedia.org/wiki/${tags['wikipedia']}"
          : null,
    );
  }
}
