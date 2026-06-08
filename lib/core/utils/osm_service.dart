import 'package:dio/dio.dart';
import 'tourism_data.dart';

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

  /// جلب الأماكن القريبة (مطاعم، كافيهات، متاحف، نوادي، ترفيه) حول نقطة معينة
  static Future<List<TouristAttraction>> fetchNearbyAmenities(
    double lat,
    double lng, {
    double radius = 1200,
    AttractionCategory? category,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = "${lat}_${lng}_${category?.index ?? 'all'}";

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

          return results;
        }
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) rethrow;
        continue; // جرب المراية اللي بعدها
      }
    }
    return _cache[cacheKey] ?? []; // لو كله فشل، رجع الكاش القديم لو متاح
  }

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
      wikiUrl: tags['wikipedia'] != null
          ? "https://en.wikipedia.org/wiki/${tags['wikipedia']}"
          : null,
    );
  }
}
