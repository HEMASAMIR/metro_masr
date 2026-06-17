// ─── TOURIST ATTRACTIONS & STATIONS DATABASE FOR CAIRO METRO ─────────────────
// Covers all 3 lines, 85 stations, with full data structure and local insights.
// Languages: ar (Arabic), en (English)

enum AttractionCategory {
  museum,
  mosque,
  church,
  market,
  park,
  palace,
  landmark,
  monument,
  university,
  entertainment,
  restaurant,
  cafe,
  sport,
  transitHub,
  localHub,
}

class TouristAttraction {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final AttractionCategory category;
  final String emoji;
  final double rating;
  final String openHours;
  final bool isFree;
  final String admissionEGP;
  final String walkingMinutes;
  final Map<String, String>? boardingHint;
  final List<String> tags;
  final double? lat;
  final double? lng;
  final String? wikiUrl;
  final List<String>? galleryUrls;
  final String? imageUrl;

  static const String defaultImage =
      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000";
  String get effectiveImageUrl =>
      (imageUrl != null && imageUrl!.isNotEmpty) ? imageUrl! : defaultImage;

  const TouristAttraction({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
    required this.rating,
    required this.openHours,
    required this.isFree,
    required this.admissionEGP,
    required this.walkingMinutes,
    this.boardingHint,
    required this.tags,
    this.lat,
    this.lng,
    this.wikiUrl,
    this.galleryUrls,
    this.imageUrl,
  });
}

class StationAttractions {
  final String stationId;
  final String lineNumber; // "1", "2", or "3"
  final Map<String, String> stationName;
  final List<TouristAttraction> attractions;

  const StationAttractions({
    required this.stationId,
    required this.lineNumber,
    required this.stationName,
    required this.attractions,
  });
}

class TourismDatabase {
  static const Map<AttractionCategory, int> categoryColor = {
    AttractionCategory.museum: 0xFF673AB7, // Deep Purple
    AttractionCategory.mosque: 0xFF4CAF50, // Green
    AttractionCategory.church: 0xFF2196F3, // Blue
    AttractionCategory.market: 0xFFFF9800, // Orange
    AttractionCategory.park: 0xFF8BC34A, // Light Green
    AttractionCategory.palace: 0xFFE91E63, // Pink
    AttractionCategory.landmark: 0xFF9E9E9E, // Grey
    AttractionCategory.monument: 0xFF795548, // Brown
    AttractionCategory.university: 0xFF00BCD4, // Cyan
    AttractionCategory.entertainment: 0xFFF44336, // Red
    AttractionCategory.restaurant: 0xFFFFC107, // Amber
    AttractionCategory.cafe:
        0xFF795548, // Brown (similar to monument, but distinct enough)
    AttractionCategory.sport: 0xFF009688, // Teal
    AttractionCategory.transitHub: 0xFF607D8B, // Blue Grey
    AttractionCategory.localHub: 0xFFCDDC39, // Lime
  };

  static const Map<AttractionCategory, Map<String, String>> categoryLabel = {
    AttractionCategory.museum: {'ar': 'متحف', 'en': 'Museum'},
    AttractionCategory.mosque: {'ar': 'مسجد', 'en': 'Mosque'},
    AttractionCategory.church: {'ar': 'كنيسة', 'en': 'Church'},
    AttractionCategory.market: {'ar': 'سوق', 'en': 'Market'},
    AttractionCategory.park: {'ar': 'حديقة', 'en': 'Park'},
    AttractionCategory.palace: {'ar': 'قصر', 'en': 'Palace'},
    AttractionCategory.landmark: {'ar': 'معلم', 'en': 'Landmark'},
    AttractionCategory.monument: {'ar': 'أثر', 'en': 'Monument'},
    AttractionCategory.university: {'ar': 'جامعة', 'en': 'University'},
    AttractionCategory.entertainment: {'ar': 'ترفيه', 'en': 'Entertainment'},
    AttractionCategory.restaurant: {'ar': 'مطعم', 'en': 'Restaurant'},
    AttractionCategory.cafe: {'ar': 'كافيه', 'en': 'Cafe'},
    AttractionCategory.sport: {'ar': 'رياضة', 'en': 'Sport'},
    AttractionCategory.transitHub: {'ar': 'مواصلات', 'en': 'Transit Hub'},
    AttractionCategory.localHub: {'ar': 'مركز محلي', 'en': 'Local Hub'},
  };

  static const Map<AttractionCategory, String> categoryEmoji = {
    AttractionCategory.museum: '🏛️',
    AttractionCategory.mosque: '🕌',
    AttractionCategory.church: '⛪',
    AttractionCategory.market: '🛍️',
    AttractionCategory.park: '🌳',
    AttractionCategory.palace: '🏰',
    AttractionCategory.landmark: '📍',
    AttractionCategory.monument: '🗿',
    AttractionCategory.university: '🎓',
    AttractionCategory.entertainment: '🎭',
    AttractionCategory.restaurant: '🍔',
    AttractionCategory.cafe: '☕',
    AttractionCategory.sport: '🏆',
    AttractionCategory.transitHub: '🚌',
    AttractionCategory.localHub: '🏘️',
  };

  /// Returns a flat list of all tourist attractions from all stations.
  static List<TouristAttraction> getAllAttractions() {
    final List<TouristAttraction> allAttractions = [];
    for (final stationData in allStationsData) {
      allAttractions.addAll(stationData.attractions);
    }
    return allAttractions;
  }

  /// Finds StationAttractions data by station ID.
  static StationAttractions? findByStation(String stationId) {
    for (final stationData in allStationsData) {
      if (stationData.stationId == stationId) {
        return stationData;
      }
    }
    return null;
  }

  // This is a placeholder for the actual data, which is `allStationsData`.
  // It's used to satisfy the `TourismDatabase.data` call in `nearby_places_page.dart`.
  // In a real application, you might have a more dynamic way to access this.
  static List<StationAttractions> get data => allStationsData;

  static List<StationAttractions> allStationsData = [
    // =========================================================================
    // ─── LINE 1: HELWAN TO EL-MARG (35 STATIONS COMPLETE) ────────────────────
    // =========================================================================
    StationAttractions(
      stationId: 'helwan',
      lineNumber: '1',
      stationName: {'ar': 'حلوان', 'en': 'Helwan'},
      attractions: [
        TouristAttraction(
          id: 'japanese_garden',
          name: {'ar': 'الحديقة اليابانية', 'en': 'Japanese Garden'},
          description: {
            'ar':
                'حديقة تاريخية مميزة بنيت عام 1917 تحتوي على تماثيل بوذا وشلالات وممرات جميلة.',
            'en':
                'A historic garden built in 1917 featuring Buddha statues, waterfalls, and beautiful walkways.',
          },
          category: AttractionCategory.park,
          emoji: '🌸',
          rating: 4.5,
          openHours: '9:00 AM – 6:00 PM',
          isFree: false,
          admissionEGP: '15 EGP',
          walkingMinutes: '5',
          boardingHint: {
            'ar': 'اخرج من المخرج الرئيسي للمحطة وامشي دقيقتين للشمال.',
            'en': 'Exit from the main gates and walk 2 minutes north.',
          },
          tags: ['Nature', 'History', 'Family'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Japanese_Garden_in_Helwan',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Japanese_Garden_in_Helwan_2017.jpg/1280px-Japanese_Garden_in_Helwan_2017.jpg',
          ],
        ),
        TouristAttraction(
          id: 'wax_museum_helwan',
          name: {'ar': 'متحف الشمع بحلوان', 'en': 'Helwan Wax Museum'},
          description: {
            'ar': 'يجسد مقتنيات وتاريخ مصر عبر العصور بتماثيل شمعية متقنة.',
            'en':
                'Displays historical Egyptian scenes crafted brilliantly with wax statues.',
          },
          category: AttractionCategory.museum,
          emoji: '🎭',
          rating: 4.0,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '30 EGP',
          walkingMinutes: '12',
          tags: ['Museum', 'History'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Helwan_Wax_Museum',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Helwan_Wax_Museum_2017.jpg/1280px-Helwan_Wax_Museum_2017.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ain_helwan',
      lineNumber: '1',
      stationName: {'ar': 'عين حلوان', 'en': 'Ain Helwan'},
      attractions: [
        TouristAttraction(
          id: 'helwan_university',
          name: {'ar': 'جامعة حلوان', 'en': 'Helwan University'},
          description: {
            'ar':
                'الحرم الجامعي الرئيسي لجامعة حلوان العريقة، يضم كليات الفنون والتربية والملعب الأولمبي.',
            'en':
                'The main campus of Helwan University, featuring fine arts faculties and sports complexes.',
          },
          category: AttractionCategory.university,
          emoji: '🎓',
          rating: 4.2,
          openHours: '7:00 AM – 7:00 PM',
          isFree: true,
          admissionEGP: 'Free (Students/Visitors ID)',
          walkingMinutes: '2',
          boardingHint: {
            'ar': 'المحطة بتفتح مباشرة على البوابة الرئيسية للجامعة.',
            'en': 'The station exits directly into the university main gate.',
          },
          tags: ['Education', 'Campus'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Helwan_University',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Helwan_University_Main_Gate.jpg/1280px-Helwan_University_Main_Gate.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'helwan_el_balad',
      lineNumber: '1',
      stationName: {'ar': 'حلوان البلد', 'en': 'Helwan El-Balad'},
      attractions: [
        TouristAttraction(
          id: 'helwan_local_market',
          name: {
            'ar': 'أسواق حلوان البلد القديمة',
            'en': 'Old Helwan Traditional Markets',
          },
          description: {
            'ar':
                'منطقة تجارية شعبية لشراء المنتجات الفخارية، المنسوجات، والسلع التقليدية بأسعار محلية.',
            'en':
                'A bustling local market famous for pottery, textiles, and local goods.',
          },
          category: AttractionCategory.market,
          emoji: '🛒',
          rating: 3.9,
          openHours: '10:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '4',
          tags: ['Shopping', 'Local'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Helwan', // General Helwan info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Helwan_Market.jpg/1280px-Helwan_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_masraa',
      lineNumber: '1',
      stationName: {'ar': 'المعصرة', 'en': 'El-Masraa'},
      attractions: [
        TouristAttraction(
          id: 'masraa_corniche',
          name: {
            'ar': 'كورنيش المعصرة والنيل',
            'en': 'El-Masraa Nile Promenade',
          },
          description: {
            'ar':
                'إطلالة محلية هادئة على نهر النيل، مناسبة للمشي ليلاً وتناول الشاي في الكافيهات البسيطة.',
            'en':
                'A simple local Nile side walk, perfect for a budget friendly night stroll.',
          },
          category: AttractionCategory.landmark,
          emoji: '⛵',
          rating: 3.8,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '8',
          tags: ['Nile', 'Relax'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Maadi', // General Maadi/Nile info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Nile_Corniche_Maadi.jpg/1280px-Nile_Corniche_Maadi.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'hadayek_el_helwan',
      lineNumber: '1',
      stationName: {'ar': 'حدائق حلوان', 'en': 'Hadayek El-Helwan'},
      attractions: [
        TouristAttraction(
          id: 'hadayek_villas',
          name: {
            'ar': 'ضواحي حدائق حلوان الهادئة',
            'en': 'Hadayek El-Helwan Suburbs',
          },
          description: {
            'ar':
                'حي سكني يتميز بالهدوء والأشجار المورقة والمباني الكلاسيكية القديمة.',
            'en':
                'A calm, green residential neighborhood featuring classic architecture.',
          },
          category: AttractionCategory.park,
          emoji: '🏡',
          rating: 4.0,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['Walking', 'Suburbs'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Helwan', // General Helwan info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Hadayek_Helwan_Street.jpg/1280px-Hadayek_Helwan_Street.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'wadi_hof',
      lineNumber: '1',
      stationName: {'ar': 'وادي حوف', 'en': 'Wadi Hof'},
      attractions: [
        TouristAttraction(
          id: 'wadi_hof_hills',
          name: {
            'ar': 'مرتفعات وادي حوف الجبلية',
            'en': 'Wadi Hof Desert Hills',
          },
          description: {
            'ar':
                'منطقة طبيعية قريبة من الجبل تتميز بهوائها النقي وهي امتداد طبيعي لصحراء معادي وحلوان.',
            'en':
                'A natural dry valley area near the mountains known for fresh, dry desert air.',
          },
          category: AttractionCategory.landmark,
          emoji: '⛰️',
          rating: 4.1,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '15',
          tags: ['Nature', 'Hills'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Wadi_Hof',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Wadi_Hof_Desert.jpg/1280px-Wadi_Hof_Desert.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId:
          'hadayek_el_ahram_l1', // Note: Named El-Ahram inside Line 1 context sometimes as a district terminal for local microbuses
      lineNumber: '1',
      stationName: {
        'ar': 'حدائق الأهرام (موقف الركاب)',
        'en': 'Hadayek El-Ahram Transit Line 1',
      },
      attractions: [
        TouristAttraction(
          id: 'l1_micro_transit',
          name: {
            'ar': 'موقف ميكروباصات الأهرام السريع',
            'en': 'Express Pyramid Microbus Hub',
          },
          description: {
            'ar':
                'نقطة انطلاق ممتازة عبر الطريق الدائري للوصول للأهرامات والمتحف الكبير بسرعة.',
            'en':
                'A strategic transit spot to grab an express microbus straight to the Pyramids via Ring Road.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🚐',
          rating: 3.7,
          openHours: '6:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free Entry',
          walkingMinutes: '1',
          boardingHint: {
            'ar': 'اركب في أواخر القطار لتكون قريب من مخرج المواصلات.',
            'en':
                'Board at the rear cars to be closer to the microbus square exit.',
          },
          tags: ['Transit', 'Shortcut'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Giza_pyramid_complex', // Link to Pyramids
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Microbus_Egypt.jpg/1280px-Microbus_Egypt.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_maasara_north',
      lineNumber: '1',
      stationName: {'ar': 'طرة الأسمنت', 'en': 'Tora El-Asmant'},
      attractions: [
        TouristAttraction(
          id: 'tora_industrial_history',
          name: {
            'ar': 'منطقة محاجر طرة التاريخية',
            'en': 'Historic Tora Quarries District',
          },
          description: {
            'ar':
                'المنطقة التي جلب منها الفراعنة الحجر الجيري الأبيض لبناء كسوة الأهرامات الثلاثة.',
            'en':
                'The famous historical region where ancient Egyptians quarried white limestone for the Pyramids.',
          },
          category: AttractionCategory.monument,
          emoji: '🧱',
          rating: 4.0,
          openHours: 'Visible from outside',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '10',
          tags: ['History', 'Pharaonic'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Tura_limestone',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Tura_Quarries.jpg/1280px-Tura_Quarries.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'tora_el_balad',
      lineNumber: '1',
      stationName: {'ar': 'طرة البلد', 'en': 'Tora El-Balad'},
      attractions: [
        TouristAttraction(
          id: 'tora_nile_club',
          name: {
            'ar': 'نادي النيل الرياضي بطرة',
            'en': 'Tora Nile Sports Club',
          },
          description: {
            'ar':
                'نادي اجتماعي ورياضي يطل على النيل مباشرة، يوفر جلسات عائلية هادئة وملاعب للأطفال.',
            'en':
                'A riverside sports and social club offering relaxed family seating and green spaces.',
          },
          category: AttractionCategory.sport,
          emoji: '🏆',
          rating: 3.9,
          openHours: '9:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '20 EGP',
          walkingMinutes: '7',
          tags: ['Sports', 'Family', 'Nile'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Tora,_Egypt', // General Tora info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Nile_Club_Tora.jpg/1280px-Nile_Club_Tora.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'thakanat_el_maadi',
      lineNumber: '1',
      stationName: {'ar': 'ثكنات المعادي', 'en': 'Thakanat El-Maadi'},
      attractions: [
        TouristAttraction(
          id: 'maadi_green_streets',
          name: {
            'ar': 'شوارع المعادي الخضراء الكلاسيكية',
            'en': 'Classic Maadi Leafy Streets',
          },
          description: {
            'ar':
                'تتميز شوارع ثكنات المعادي بالفيلات الفخمة، الأشجار الضخمة، والهدوء الأوروبي الساحر ومثالية للمشي.',
            'en':
                'Famous for foreign embassies, magnificent villas, high trees, and serene walking tracks.',
          },
          category: AttractionCategory.park,
          emoji: '🌳',
          rating: 4.7,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          boardingHint: {
            'ar': 'انزل هنا لو عايز تتمشى في هدوء بعيد عن زحمة وسط البلد.',
            'en':
                'Get off here if you want a quiet walk away from Downtown crowds.',
          },
          tags: ['Walking', 'Serene', 'Nature'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Maadi',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Maadi_Street_Cairo.jpg/1280px-Maadi_Street_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'maadi',
      lineNumber: '1',
      stationName: {'ar': 'المعادي', 'en': 'Maadi'},
      attractions: [
        TouristAttraction(
          id: 'road_9_maadi_hub',
          name: {'ar': 'شارع 9 بالمعادي', 'en': 'Road 9 Maadi'},
          description: {
            'ar':
                'القلب النابض للمعاير، يحتوي على مئات المطاعم المحلية والعالمية، الكافيهات، والمكتبات المتميزة.',
            'en':
                'The ultimate foodie and cafe street in Maadi, running parallel to the metro tracks.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🍔',
          rating: 4.8,
          openHours: '8:00 AM – 1:00 AM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'المحطة بتنزلك في الشارع بالظبط، اخرج من مخرج الاتجاه الغربي.',
            'en': 'The station drops you right in the street. Exit west.',
          },
          tags: ['Food', 'Cafes', 'Nightlife'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Maadi#Road_9',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Maadi_Road_9.jpg/1280px-Maadi_Road_9.jpg',
          ],
        ),
        TouristAttraction(
          id: 'wadi_degla_protectorate',
          name: {
            'ar': 'محمية وادي دجلة الطبيعية',
            'en': 'Wadi Degla Protectorate',
          },
          description: {
            'ar':
                'محمية طبيعية خلابة وسط الجبال لممارسة الهايكنج، التخييم، وركوب الدراجات.',
            'en':
                'A massive desert canyon protectorate, perfect for hiking, trail running, and stargazing.',
          },
          category: AttractionCategory.park,
          emoji: '🌵',
          rating: 4.8,
          openHours: '6:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '10 EGP',
          walkingMinutes: '15 (By Taxi)',
          tags: ['Nature', 'Hiking', 'Adventure'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Wadi_Degla_Protectorate',
          lat: 29.9597,
          lng: 31.3149,
        ),
        TouristAttraction(
          id: 'sequoia_maadi',
          name: {'ar': 'مطعم سيكويا المعادي', 'en': 'Sequoia Maadi'},
          description: {
            'ar':
                'مطعم راقٍ على ضفاف النيل يقدم مأكولات بحرية ومشويات فاخرة مع إطلالة خلابة على النيل وأجواء مميزة جداً.',
            'en':
                'An upscale Nile-side restaurant famous for fresh seafood, grills, and a stunning waterfront atmosphere.',
          },
          category: AttractionCategory.restaurant,
          emoji: '🍽️',
          rating: 4.6,
          openHours: '12:00 PM – 2:00 AM',
          isFree: false,
          admissionEGP: '300–600 EGP per person',
          walkingMinutes: '12',
          boardingHint: {
            'ar': 'خذ تاكسي من المحطة باتجاه كورنيش المعادي.',
            'en': 'Grab a taxi from the station towards Maadi Corniche.',
          },
          tags: ['Restaurant', 'Nile View', 'Seafood', 'Fine Dining'],
          lat: 29.9612,
          lng: 31.2398,
        ),
        TouristAttraction(
          id: 'lucilles_maadi',
          name: {'ar': 'لوسيل داينر المعادي', 'en': "Lucille's Diner"},
          description: {
            'ar':
                'مطعم أمريكي شعبي جداً في المعادي، مشهور بالبرجر والباستا والكيك الأمريكي. مكان محبوب من الأجانب والمصريين.',
            'en':
                'A beloved American diner in Maadi, famous for its burgers, pasta, and homemade cake. Popular with expats and locals.',
          },
          category: AttractionCategory.restaurant,
          emoji: '🍔',
          rating: 4.5,
          openHours: '10:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '150–250 EGP per person',
          walkingMinutes: '5',
          tags: ['Restaurant', 'Burger', 'American', 'Casual'],
          lat: 29.9585,
          lng: 31.2517,
        ),
        TouristAttraction(
          id: 'cilantro_maadi',
          name: {'ar': 'كافيه سيلانترو المعادي', 'en': 'Cilantro Café Maadi'},
          description: {
            'ar':
                'فرع من أشهر سلاسل الكافيهات في مصر، يقدم القهوة المتخصصة والمعجنات الطازجة وبيئة عمل هادئة مثالية.',
            'en':
                'A branch of Egypt\'s most popular specialty coffee chain, offering premium coffee, fresh pastries, and a quiet workspace.',
          },
          category: AttractionCategory.cafe,
          emoji: '☕',
          rating: 4.4,
          openHours: '7:00 AM – 12:00 AM',
          isFree: false,
          admissionEGP: '80–150 EGP',
          walkingMinutes: '3',
          boardingHint: {
            'ar': 'قريب جداً من محطة المعادي على شارع 9.',
            'en': 'Very close to Maadi station on Road 9.',
          },
          tags: ['Cafe', 'Coffee', 'Work Space', 'Breakfast'],
          lat: 29.9590,
          lng: 31.2510,
        ),
        TouristAttraction(
          id: 'road9_coffee_maadi',
          name: {'ar': 'رود ناين كوفي', 'en': 'Road 9 Coffee'},
          description: {
            'ar':
                'كافيه أنيق وعصري في قلب شارع 9، مشهور بقهوة الكولد برو والأجواء الهادئة ومناسب للعمل والاجتماعات.',
            'en':
                'A trendy specialty coffee shop on Road 9, known for cold brew, a relaxed vibe, and great for work or meetings.',
          },
          category: AttractionCategory.cafe,
          emoji: '🧋',
          rating: 4.6,
          openHours: '8:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '70–130 EGP',
          walkingMinutes: '2',
          tags: ['Cafe', 'Cold Brew', 'Specialty Coffee', 'Cozy'],
          lat: 29.9592,
          lng: 31.2512,
        ),
        TouristAttraction(
          id: 'maadi_sporting_club',
          name: {'ar': 'نادي المعادي الرياضي', 'en': 'Maadi Sporting Club'},
          description: {
            'ar':
                'من أعرق النوادي الرياضية في القاهرة، يضم ملاعب تنس وسباحة وكرة قدم ومطاعم وحدائق خضراء واسعة.',
            'en':
                'One of Cairo\'s most prestigious sports clubs, featuring tennis courts, pools, football pitches, restaurants, and lush gardens.',
          },
          category: AttractionCategory.sport,
          emoji: '🏆',
          rating: 4.7,
          openHours: '7:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: 'Members / Guest Pass 100 EGP',
          walkingMinutes: '8',
          tags: ['Sports', 'Swimming', 'Tennis', 'Club', 'Family'],
          lat: 29.9619,
          lng: 31.2561,
        ),
      ],
    ),

    StationAttractions(
      stationId: 'hadayek_el_maadi',
      lineNumber: '1',
      stationName: {'ar': 'حدائق المعادي', 'en': 'Hadayek El-Maadi'},
      attractions: [
        TouristAttraction(
          id: 'hadayek_local_shopping',
          name: {
            'ar': 'أسواق حدائق المعادي التجارية',
            'en': 'Hadayek El-Maadi Commercial Markets',
          },
          description: {
            'ar':
                'شوارع تجارية حيوية تبيع الملابس والأجهزة بأسعار اقتصادية وتنافسية جداً.',
            'en':
                'Bustling commercial streets providing affordable clothing and gadgets.',
          },
          category: AttractionCategory.market,
          emoji: '🛍️',
          rating: 4.1,
          openHours: '11:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Shopping', 'Local'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Maadi', // General Maadi info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Hadayek_Maadi_Market.jpg/1280px-Hadayek_Maadi_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'dar_el_salam',
      lineNumber: '1',
      stationName: {'ar': 'دار السلام', 'en': 'Dar El-Salam'},
      attractions: [
        TouristAttraction(
          id: 'local_nile_felucca',
          name: {
            'ar': 'مراسي الفلوكة النيلية بدار السلام',
            'en': 'Local Nile Felucca Docks',
          },
          description: {
            'ar':
                'أماكن ركوب المراكب الشراعية التقليدية (الفلوكة) في النيل بأسعار شعبية رخيصة جداً مقارنة بالزمالك.',
            'en':
                'Traditional Nile sailboat docks offering budget rides compared to upscale areas.',
          },
          category: AttractionCategory.entertainment,
          emoji: '⛵',
          rating: 4.2,
          openHours: '2:00 PM – Midnight',
          isFree: false,
          admissionEGP: '50 EGP per ride',
          walkingMinutes: '10',
          tags: ['Nile', 'Felucca', 'Budget'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Felucca',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Felucca_on_the_Nile.jpg/1280px-Felucca_on_the_Nile.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_zahraa',
      lineNumber: '1',
      stationName: {'ar': 'الزهراء', 'en': 'El-Zahraa'},
      attractions: [
        TouristAttraction(
          id: 'fustat_crafts_center',
          name: {
            'ar': 'مركز الخزف والفخار بالفسطاط',
            'en': 'Fustat Traditional Crafts Center',
          },
          description: {
            'ar':
                'مجمع أثري وفني مذهل لمشاهدة وشراء الفخار والخزف المصنوع يدوياً على الطريقة المصرية القديمة.',
            'en':
                'An amazing artisan center showcasing hand made Egyptian pottery and ceramics designs.',
          },
          category: AttractionCategory.market,
          emoji: '🏺',
          rating: 4.6,
          openHours: '9:00 AM – 4:00 PM',
          isFree: true,
          admissionEGP: 'Free Entry',
          walkingMinutes: '12',
          tags: ['Crafts', 'Art', 'Culture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Fustat',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Fustat_Pottery_Center.jpg/1280px-Fustat_Pottery_Center.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'mar_girgis',
      lineNumber: '1',
      stationName: {'ar': 'مار جرجس', 'en': 'Mar Girgis'},
      attractions: [
        TouristAttraction(
          id: 'hanging_church',
          name: {'ar': 'الكنيسة المعلقة', 'en': 'The Hanging Church'},
          description: {
            'ar':
                'أقدم وأشهر كنيسة قبطية في مصر، بنيت فوق أبراج حصن بابليون الروماني في القرن السابع.',
            'en':
                'Egypt\'s most iconic Coptic church, beautifully suspended atop the towers of Babylon Roman Fortress.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.9,
          openHours: '9:00 AM – 5:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          boardingHint: {
            'ar': 'اخرج من بوابة المترو هتلاقي سلم الكنيسة قدامك مباشرة.',
            'en':
                'Exit the station gates and you will see the church stairs right in front of you.',
          },
          tags: ['Coptic', 'History', 'UNESCO'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Saint_Virgin_Mary%27s_Coptic_Orthodox_Church_(%22The_Hanging_Church%22)',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Hanging_Church_Cairo.jpg/1280px-Hanging_Church_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'coptic_museum',
          name: {'ar': 'المتحف القبطي', 'en': 'Coptic Museum'},
          description: {
            'ar':
                'يضم أكبر مجموعة من الآثار والمخطوطات القبطية والنادرة في العالم.',
            'en':
                'Houses the largest and finest collection of Coptic Christian antiquities globally.',
          },
          category: AttractionCategory.museum,
          emoji: '✝️',
          rating: 4.8,
          openHours: '9:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '2',
          tags: ['Museum', 'History'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Coptic_Museum',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Coptic_Museum_Cairo.jpg/1280px-Coptic_Museum_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'amr_mosque',
          name: {'ar': 'مسجد عمرو بن العاص', 'en': 'Amr Ibn Al-As Mosque'},
          description: {
            'ar':
                'أول مسجد بني في مصر وقارة أفريقيا عام 641 ميلادية، مجمع إسلامي وتاريخي عظيم.',
            'en':
                'The very first mosque built in Egypt and all of Africa, founded in 641 AD.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.8,
          openHours: '5:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '7',
          tags: ['Mosque', 'Islamic', 'Historic'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Mosque_of_Amr_ibn_al-As',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mosque_of_Amr_ibn_al-As_Cairo.jpg/1280px-Mosque_of_Amr_ibn_al-As_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'ben_ezra_synagogue',
          name: {'ar': 'معبد بن عزرا اليهودي', 'en': 'Ben Ezra Synagogue'},
          description: {
            'ar':
                'المعبد اليهودي الأقدم في القاهرة، يتميز بنقوشه المعمارية الرائعة وقيمته التاريخية.',
            'en':
                'The oldest Jewish synagogue in Cairo, famous for its architecture and historical documents.',
          },
          category: AttractionCategory.landmark,
          emoji: '🔯',
          rating: 4.6,
          openHours: '9:00 AM – 4:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Jewish', 'History', 'Religions Complex'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Ben_Ezra_Synagogue',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ben_Ezra_Synagogue_Cairo.jpg/1280px-Ben_Ezra_Synagogue_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_malek_el_saleh',
      lineNumber: '1',
      stationName: {'ar': 'الملك الصالح', 'en': 'El-Malek El-Saleh'},
      attractions: [
        TouristAttraction(
          id: 'roda_island_nilometer',
          name: {'ar': 'مقياس النيل بالروضة', 'en': 'Roda Island Nilometer'},
          description: {
            'ar':
                'بناء عبقري من العصر العباسي (عام 861 م) كان يستخدم لقياسس مستوى فيضان النيل بدقة.',
            'en':
                'An ingenious Abbasid-era structure built in 861 AD to measure the Nile\'s annual flood levels.',
          },
          category: AttractionCategory.monument,
          emoji: '📉',
          rating: 4.7,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '40 EGP',
          walkingMinutes: '11',
          tags: ['History', 'Islamic', 'Architecture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Roda_Island_Nilometer',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Roda_Island_Nilometer_Cairo.jpg/1280px-Roda_Island_Nilometer_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'sayeda_zeinab',
      lineNumber: '1',
      stationName: {'ar': 'السيدة زينب', 'en': 'Sayeda Zeinab'},
      attractions: [
        TouristAttraction(
          id: 'sayeda_zeinab_mosque',
          name: {'ar': 'مسجد السيدة زينب', 'en': 'Sayeda Zeinab Mosque'},
          description: {
            'ar':
                'أحد أهم وأكبر المساجد الصوفية والتاريخية في مصر، يضم ضريح حفيدة الرسول صلي الله عليه وسلم.',
            'en':
                'One of the most sacred and historic mosques in Egypt, housing the shrine of Prophet Muhammad\'s granddaughter.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.9,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '6',
          tags: ['Mosque', 'Islamic', 'Spirituality'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Sayyidah_Zaynab_Mosque',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Sayyidah_Zaynab_Mosque_Cairo.jpg/1280px-Sayyidah_Zaynab_Mosque_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'ibn_tulun_mosque',
          name: {'ar': 'مسجد أحمد بن طولون', 'en': 'Ibn Tulun Mosque'},
          description: {
            'ar':
                'أقدم مسجد احتفظ بحالته الأصلية في مصر، مشهور بمئذنته الملوية الفريدة وساحته الضخمة.',
            'en':
                'The oldest mosque in Egypt intact in its original form, famous for its unique spiral minaret.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.9,
          openHours: '9:00 AM – 5:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '14',
          tags: ['Architecture', 'Islamic', 'Iconic'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Mosque_of_Ibn_Tulun',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mosque_of_Ibn_Tulun_Cairo.jpg/1280px-Mosque_of_Ibn_Tulun_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'saad_zaghloul',
      lineNumber: '1',
      stationName: {'ar': 'سعد زغلول', 'en': 'Saad Zaghloul'},
      attractions: [
        TouristAttraction(
          id: 'saad_zaghloul_mausoleum',
          name: {
            'ar': 'ضريح بيت الأمة (سعد زغلول)',
            'en': 'Saad Zaghloul Mausoleum',
          },
          description: {
            'ar':
                'ضريح تذكاري مبني على الطراز الفرعوني القديم تخليداً لزعيم ثورة 1919 سعد زغلول.',
            'en':
                'A grand mausoleum built in Neo Pharaonic architectural style for Egypt\'s historic leader Saad Zaghloul.',
          },
          category: AttractionCategory.monument,
          emoji: '🏛️',
          rating: 4.5,
          openHours: '9:00 AM – 4:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['History', 'Nationalism'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Saad_Zaghloul',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Saad_Zaghloul_Mausoleum_Cairo.jpg/1280px-Saad_Zaghloul_Mausoleum_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'sadat',
      lineNumber: '1',
      stationName: {'ar': 'السادات (التحرير)', 'en': 'Sadat (Tahrir)'},
      attractions: [
        TouristAttraction(
          id: 'egyptian_museum_tahrir',
          name: {'ar': 'المتحف المصري بالتحرير', 'en': 'The Egyptian Museum'},
          description: {
            'ar':
                'عميد متاحف الآثار في العالم، يضم آلاف القطع الأثرية والتماثيل الذهبية للفراعنة والمومياوات.',
            'en':
                'The legendary repository of ancient Egyptian history, home to iconic treasures and Pharaonic statues.',
          },
          category: AttractionCategory.museum,
          emoji: '🏛️',
          rating: 4.9,
          openHours: '9:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '200 EGP',
          walkingMinutes: '3',
          boardingHint: {
            'ar':
                'اركب في وسط القطار واخرج من مخرج مجمع التحرير لتصل للمتحف مباشرة.',
            'en':
                'Ride in the middle cars and use the Tahrir Complex exit to find the museum right outside.',
          },
          tags: ['UNESCO', 'Museum', 'Pharaohs'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Egyptian_Museum',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Egyptian_Museum_Cairo.jpg/1280px-Egyptian_Museum_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'tahrir_square_monument',
          name: {
            'ar': 'ميدان التحرير والمسلة',
            'en': 'Tahrir Square & Obelisk',
          },
          description: {
            'ar':
                'أشهر ميدان في تاريخ مصر الحديث، يتوسطه الآن مسلة فرعونية حقيقية وأربعة كباش أثرية.',
            'en':
                'The historic heart of modern Cairo, featuring an ancient authentic obelisk and four sphinxes.',
          },
          category: AttractionCategory.landmark,
          emoji: '🗽',
          rating: 4.7,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          tags: ['Landmark', 'Iconic', 'City Center'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Tahrir_Square',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Tahrir_Square_Cairo.jpg/1280px-Tahrir_Square_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'nasser',
      lineNumber: '1',
      stationName: {'ar': 'ناصر', 'en': 'Nasser'},
      attractions: [
        TouristAttraction(
          id: 'high_court_egypt',
          name: {'ar': 'دار القضاء العالي', 'en': 'High Court of Egypt'},
          description: {
            'ar':
                'مبنى تاريخي مهيب يتميز بعمارته الكلاسيكية الفخمة، يمثل قلب المنظومة القضائية بمصر.',
            'en':
                'A grand, imposing historical building featuring neoclassical architecture.',
          },
          category: AttractionCategory.landmark,
          emoji: '⚖️',
          rating: 4.4,
          openHours: 'Visible from outside mostly',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['History', 'Downtown', 'Architecture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/High_Court_of_Egypt',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/High_Court_of_Egypt_Cairo.jpg/1280px-High_Court_of_Egypt_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'wika_shopping_street',
          name: {
            'ar': 'شارع وكالة البلح وسوق التوفيقية',
            'en': 'Tawfikia & Wika Local Shopping Street',
          },
          description: {
            'ar':
                'سوق حيوي نابض لبيع قطع غيار السيارات، الفواكه، والإكسسوارات بأسعار الجملة.',
            'en':
                'A lively street market known for car parts, gadgets, and wholesale items.',
          },
          category: AttractionCategory.market,
          emoji: '🔧',
          rating: 4.2,
          openHours: '10:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '4',
          tags: ['Shopping', 'Local Hub'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Downtown_Cairo', // General Downtown info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Tawfikia_Market_Cairo.jpg/1280px-Tawfikia_Market_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'orabi',
      lineNumber: '1',
      stationName: {'ar': 'عرابي', 'en': 'Orabi'},
      attractions: [
        TouristAttraction(
          id: 'orabi_theaters',
          name: {
            'ar': 'مسارح وسينمات شارع عماد الدين',
            'en': 'Emad El-Din Street Historic Theaters',
          },
          description: {
            'ar':
                'شارع الفن القديم في وسط البلد، كان ملتقى الفنانين ويضم واجهات معمارية على الطراز الأوروبي الخديوي.',
            'en':
                'Cairo\'s historic theater district, famous for its beautiful Khedivial European architectural styles.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🎭',
          rating: 4.5,
          openHours: 'Varies by show',
          isFree: true,
          admissionEGP: 'Free walking',
          walkingMinutes: '5',
          tags: ['Art', 'History', 'Downtown'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Emad_El-Din_Street',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Emad_El-Din_Street_Cairo.jpg/1280px-Emad_El-Din_Street_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'shuhada',
      lineNumber: '1',
      stationName: {'ar': 'الشهداء (رمسيس)', 'en': 'Al-Shuhada (Ramses)'},
      attractions: [
        TouristAttraction(
          id: 'ramses_station_main',
          name: {
            'ar': 'محطة مصر لسكك الحديد',
            'en': 'Ramses Train Station (Main Terminal)',
          },
          description: {
            'ar':
                'المحطة المركزية للقطارات في مصر، تتميز بمبناها الفرعوني الإسلامي ومتحف السكة الحديد.',
            'en':
                'Egypt\'s grand central railway terminal, featuring stunning heritage architecture and a Railway Museum.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🚂',
          rating: 4.5,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free entry',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'محطة التبادل الأكبر، اتبع اللوحات الإرشادية للوصول لرصيف الخط الثاني بسهولة.',
            'en':
                'The largest interchange station. Follow the color coded overhead signs to change lines.',
          },
          tags: ['Transit', 'Landmark', 'History'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Ramses_Station',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ramses_Station_Cairo.jpg/1280px-Ramses_Station_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ghamra',
      lineNumber: '1',
      stationName: {'ar': 'غمرة', 'en': 'Ghamra'},
      attractions: [
        TouristAttraction(
          id: 'st_sakht_church',
          name: {
            'ar': 'كنيسة رئيس الملائكة ميخائيل بغمرة',
            'en': 'St. Michael Archangel Church Ghamra',
          },
          description: {
            'ar':
                'كنيسة قبطية أثرية بارزة تخدم منطقة وسط البلد وغمرة وتتميز بنقوشها الجميلة.',
            'en':
                'A prominent historical Coptic church in the Ghamra district.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.3,
          openHours: '8:00 AM – 8:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '4',
          tags: ['Church', 'Spiritual'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ghamra', // General Ghamra info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/St_Michael_Archangel_Church_Ghamra.jpg/1280px-St_Michael_Archangel_Church_Ghamra.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_demerdash',
      lineNumber: '1',
      stationName: {'ar': 'الدمرداش', 'en': 'El-Demerdash'},
      attractions: [
        TouristAttraction(
          id: 'ain_shams_medicine',
          name: {
            'ar': 'مستشفيات جامعة عين شمس التاريخية',
            'en': 'Ain Shams University Medical Complex',
          },
          description: {
            'ar':
                'أحد أقدم وأكبر المجمعات الطبية والتعليمية في الشرق الأوسط، يضم مبانٍ تراثية.',
            'en':
                'One of the oldest and largest medical and historical educational faculties in Egypt.',
          },
          category: AttractionCategory.university,
          emoji: '🏥',
          rating: 4.0,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['University', 'Landmark'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Ain_Shams_University',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ain_Shams_University_Hospital.jpg/1280px-Ain_Shams_University_Hospital.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'manshiet_el_sadr',
      lineNumber: '1',
      stationName: {'ar': 'منشية الصدر', 'en': 'Manshiet El-Sadr'},
      attractions: [
        TouristAttraction(
          id: 'ain_shams_campus',
          name: {
            'ar': 'حرم جامعة عين شمس الرئيسي',
            'en': 'Ain Shams University Main Campus',
          },
          description: {
            'ar':
                'يضم قصر الزعفران التاريخي الرائع المبني على طراز قصر فرساي الفرنسي والجامعة العريقة.',
            'en':
                'Features the historic Zaafaran Palace built in French Versailles style inside the campus.',
          },
          category: AttractionCategory.university,
          emoji: '🎓',
          rating: 4.6,
          openHours: '8:00 AM – 6:00 PM',
          isFree: true,
          admissionEGP: 'Free (ID Required)',
          walkingMinutes: '4',
          tags: ['University', 'Palace', 'History'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ain_Shams_University#Zaafaran_Palace',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Zaafaran_Palace_Ain_Shams_University.jpg/1280px-Zaafaran_Palace_Ain_Shams_University.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'hammamat_el_kobba',
      lineNumber: '1',
      stationName: {'ar': 'حمامات القبة', 'en': 'Hammamat El-Kobba'},
      attractions: [
        TouristAttraction(
          id: 'kobba_presidential_gardens',
          name: {
            'ar': 'محيط حدائق قصر القبة',
            'en': 'Koubbeh Palace Surrounding Gardens',
          },
          description: {
            'ar':
                'منطقة أشجار ملكية كثيفة تحيط بقصر القبة، تتميز بالهدوء والمظهر الحضاري الرائع.',
            'en':
                'Lush, green areas surrounding the majestic Koubbeh Royal Palace.',
          },
          category: AttractionCategory.park,
          emoji: '🌳',
          rating: 4.3,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free walking',
          walkingMinutes: '5',
          tags: ['Nature', 'Walking'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Koubbeh_Palace', // General Koubbeh info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Koubbeh_Palace_Gardens.jpg/1280px-Koubbeh_Palace_Gardens.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'hadayek_el_kobba',
      lineNumber: '1',
      stationName: {'ar': 'حدائق القبة', 'en': 'Hadayek El-Kobba'},
      attractions: [
        TouristAttraction(
          id: 'koubbeh_royal_palace',
          name: {
            'ar': 'قصر القبة الجمهوري الأثري',
            'en': 'Koubbeh Royal Palace',
          },
          description: {
            'ar':
                'من أكبر القصور الملكية في عهد الأسرة العلوية، مبني على مساحة شاسعة ويستضيف الفعاليات الرسمية والآن الثقافية.',
            'en':
                'One of Egypt\'s largest royal palaces, featuring exceptional Khedivial styling and sprawling private gardens.',
          },
          category: AttractionCategory.palace,
          emoji: '🏰',
          rating: 4.8,
          openHours: 'Varies by event schedules',
          isFree: false,
          admissionEGP: 'Varies',
          walkingMinutes: '4',
          tags: ['Palace', 'Royal', 'History'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Koubbeh_Palace',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Koubbeh_Palace_Cairo.jpg/1280px-Koubbeh_Palace_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'kobri_el_kobba',
      lineNumber: '1',
      stationName: {'ar': 'كوبري القبة', 'en': 'Kobri El-Kobba'},
      attractions: [
        TouristAttraction(
          id: 'gamal_abdel_nasser_mosque',
          name: {
            'ar': 'مسجد وضريح الزعيم جمال عبد الناصر',
            'en': 'Gamal Abdel Nasser Mosque & Mausoleum',
          },
          description: {
            'ar':
                'مسجد فخم يضم ضريح الرئيس المصري الراحل جمال عبد الناصر، يتميز بطرازه المعماري الحديث.',
            'en':
                'Grand mosque housing the final resting place of Egypt\'s historic president Gamal Abdel Nasser.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.7,
          openHours: '9:00 AM – 8:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['History', 'Mosque', 'National Leaders'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Gamal_Abdel_Nasser_Mosque',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Gamal_Abdel_Nasser_Mosque_Cairo.jpg/1280px-Gamal_Abdel_Nasser_Mosque_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'manshiet_el_bakry',
      lineNumber: '1',
      stationName: {'ar': 'منشية البكري', 'en': 'Manshiet El-Bakry'},
      attractions: [
        TouristAttraction(
          id: 'bakry_historic_villas',
          name: {
            'ar': 'ضواحي منشية البكري التاريخية',
            'en': 'Manshiet El-Bakry Historic District',
          },
          description: {
            'ar':
                'الحي التراثي الذي عاش فيه كبار قادة مصر، يتميز بالفيلات القديمة والشوارع الواسعة المنظمة.',
            'en':
                'The classic elite neighborhood that hosted major Egyptian leaders, filled with old vintage villas.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏛️',
          rating: 4.2,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['Walking', 'History'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Manshiet_El-Bakry',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Manshiet_El-Bakry_Villas.jpg/1280px-Manshiet_El-Bakry_Villas.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'saray_el_kobba',
      lineNumber: '1',
      stationName: {'ar': 'سراي القبة', 'en': 'Saraya El-Kobba'},
      attractions: [
        TouristAttraction(
          id: 'tahra_palace_view',
          name: {
            'ar': 'محيط قصر الطاهرة التاريخي',
            'en': 'Al-Tahra Palace Surroundings',
          },
          description: {
            'ar':
                'قصر ملكي إيطالي الطراز مصنف كأحد أجمل القصور الرئاسية الصغيرة والمميزة في القاهرة.',
            'en':
                'An Italianate royal palace considered one of the most elegant boutique palaces in Cairo.',
          },
          category: AttractionCategory.palace,
          emoji: '🏰',
          rating: 4.5,
          openHours: 'Viewable from gates',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '6',
          tags: ['Palace', 'Architecture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Al-Tahra_Palace',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Al-Tahra_Palace_Cairo.jpg/1280px-Al-Tahra_Palace_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'zeitoun',
      lineNumber: '1',
      stationName: {'ar': 'حدائق الزيتون', 'en': 'Hadayek El-Zeitoun'},
      attractions: [
        TouristAttraction(
          id: 'zeitoun_virgin_mary',
          name: {
            'ar': 'كنيسة السيدة العذراء مريم بالزيتون',
            'en': 'Virgin Mary Coptic Church Zeitoun',
          },
          description: {
            'ar':
                'كنيسة شهيرة عالمياً شهدت واقعة تجلي السيدة العذراء مريم عام 1968 فوق قباابها، مزار مسيحي عالمي.',
            'en':
                'World famous church renowned for the public apparition of Virgin Mary in 1968 over its domes.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.9,
          openHours: '6:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['Spiritual', 'Miracle Site', 'Global Attraction'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Our_Lady_of_Zeitoun',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Virgin_Mary_Church_Zeitoun.jpg/1280px-Virgin_Mary_Church_Zeitoun.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'helmieat_el_zaitoun',
      lineNumber: '1',
      stationName: {'ar': 'حلمية الزيتون', 'en': 'Helmieat El-Zeitoun'},
      attractions: [
        TouristAttraction(
          id: 'helmeat_military_club',
          name: {
            'ar': 'نادي 6 أكتوبر الرياضي بالحلمية',
            'en': '6th of October Sports Club Helmia',
          },
          description: {
            'ar':
                'نادي اجتماعي ورياضي ضخم يضم حمامات سباحة، ملاعب تنس، وقاعات مطاعم راقية.',
            'en':
                'A massive sports complex featuring swimming pools, tennis courts, and casual dining sites.',
          },
          category: AttractionCategory.sport,
          emoji: '🎾',
          rating: 4.2,
          openHours: '9:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '30 EGP',
          walkingMinutes: '6',
          tags: ['Sports', 'Family'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Heliopolis', // General Heliopolis info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/6th_of_October_Sports_Club_Helmia.jpg/1280px-6th_of_October_Sports_Club_Helmia.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_matareya',
      lineNumber: '1',
      stationName: {'ar': 'المطرية', 'en': 'El-Matareya'},
      attractions: [
        TouristAttraction(
          id: 'virgin_mary_tree',
          name: {
            'ar': 'شجرة مريم الأثرية بالمطرية',
            'en': 'Virgin Mary\'s Holy Tree',
          },
          description: {
            'ar':
                'أحد أهم محطات رحلة العائلة المقدسة في مصر؛ استظلت تحتها السيدة العذراء والسيد المسيح.',
            'en':
                'One of the key sacred stops of the Holy Family trip in Egypt, where Virgin Mary rested under its shade.',
          },
          category: AttractionCategory.monument,
          emoji: '🌳',
          rating: 4.8,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '60 EGP',
          walkingMinutes: '9',
          tags: ['Holy Family', 'Christianity', 'History'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Tree_of_the_Virgin',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Virgin_Mary_Tree_Matareya.jpg/1280px-Virgin_Mary_Tree_Matareya.jpg',
          ],
        ),
        TouristAttraction(
          id: 'obelisk_senusret',
          name: {
            'ar': 'مسلة سنوسرت الأول (عين شمس القديمة)',
            'en': 'Obelisk of Senusret I',
          },
          description: {
            'ar':
                'أقدم مسلة فرعونية قائمة في مكانها الأصلي بمصر، تعود لعصر الدولة الوسطى بمدينة هليوبوليس القديمة.',
            'en':
                'The oldest standing obelisk in its original position in Egypt, belonging to Middle Kingdom Heliopolis city.',
          },
          category: AttractionCategory.monument,
          emoji: '📐',
          rating: 4.6,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '40 EGP',
          walkingMinutes: '12',
          tags: ['Pharaonic', 'Antiquity', 'Obelisk'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Obelisk_of_Senusret_I',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Obelisk_of_Senusret_I_Matareya.jpg/1280px-Obelisk_of_Senusret_I_Matareya.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ain_shams',
      lineNumber: '1',
      stationName: {'ar': 'عين شمس', 'en': 'Ain Shams'},
      attractions: [
        TouristAttraction(
          id: 'ain_shams_local_bazaar',
          name: {
            'ar': 'أسواق عين شمس للملابس والأقمشة',
            'en': 'Ain Shams Textiles Bazaar',
          },
          description: {
            'ar':
                'سوق شعبي ضخم ممتد لشراء الأقمشة، المفروشات، والملابس الجاهزة بأسعار منخفضة جداً.',
            'en':
                'A massive traditional market for textiles, fabrics, and ready made clothing at rock bottom prices.',
          },
          category: AttractionCategory.market,
          emoji: '🧵',
          rating: 4.0,
          openHours: '11:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Shopping', 'Local Bazaar'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ain_Shams', // General Ain Shams info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ain_Shams_Market.jpg/1280px-Ain_Shams_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ezbet_el_nakhl',
      lineNumber: '1',
      stationName: {'ar': 'عزبة النخل', 'en': 'Ezbet El-Nakhl'},
      attractions: [
        TouristAttraction(
          id: 'nakhl_street_stalls',
          name: {
            'ar': 'شارع المحطة التجاري المزدحم',
            'en': 'Station Street Commercial Hub',
          },
          description: {
            'ar':
                'منطقة تجارية حيوية صاخبة، ممتازة لتجربة الأكل الشعبي السريع والتسوق المحلي الموفر.',
            'en':
                'A bustling local shopping experience, perfect to explore traditional street foods and bargain goods.',
          },
          category: AttractionCategory.market,
          emoji: '🍕',
          rating: 3.8,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          tags: ['Shopping', 'Street Food'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ezbet_El-Nakhl', // General Ezbet El-Nakhl info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ezbet_El-Nakhl_Street_Food.jpg/1280px-Ezbet_El-Nakhl_Street_Food.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_marg',
      lineNumber: '1',
      stationName: {'ar': 'المرج', 'en': 'El-Marg'},
      attractions: [
        TouristAttraction(
          id: 'marg_intercity_hub',
          name: {
            'ar': 'موقف المرج الإقليمي للمحافظات',
            'en': 'El-Marg Intercity Microbus Terminal',
          },
          description: {
            'ar':
                'البوابة الشمالية للقاهرة، ومنها يمكنك ركوب سيارات مباشرة لمدن الدلتا، بنها، والشرقية وسيرك في دقيقة.',
            'en':
                'The major northern transit portal connecting Cairo directly to Delta cities, Benha, and Sharkia.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🚌',
          rating: 3.9,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free entry',
          walkingMinutes: '2',
          tags: ['Transit', 'Delta Route'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/El_Marg', // General El-Marg info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Marg_Microbus_Terminal.jpg/1280px-El_Marg_Microbus_Terminal.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_marg_el_gededa',
      lineNumber: '1',
      stationName: {'ar': 'المرج الجديدة', 'en': 'New El-Marg'},
      attractions: [
        TouristAttraction(
          id: 'marg_ring_road_interchange',
          name: {
            'ar': 'تقاطع الطريق الدائري الشمالي',
            'en': 'North Ring Road Transit Interchange',
          },
          description: {
            'ar':
                'محطة المترو النهائية بالخط الأول، تلتقي مباشرة مع الطريق الدائري لتسهيل الانتقال لشرق وغرب القاهرة.',
            'en':
                'The final terminal of Line 1, meeting the Cairo Ring Road to connect users rapidly to East and West Cairo districts.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🛑',
          rating: 4.0,
          openHours: '5:00 AM – 1:00 AM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'آخر محطة في الخط الأول، اتأكد من جمع متعلقاتك بالكامل قبل مغادرة القطار.',
            'en':
                'Last station of Line 1. Ensure you pick up all your belongings before leaving the train.',
          },
          tags: ['Terminal', 'Transit'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/El_Marg', // General El-Marg info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/New_El_Marg_Metro_Station.jpg/1280px-New_El_Marg_Metro_Station.jpg',
          ],
        ),
      ],
    ),

    // =========================================================================
    // ─── LINE 2: SHUBRA EL-KHEIMA TO MOUNIB (20 STATIONS COMPLETE) ───────────
    // =========================================================================
    StationAttractions(
      stationId: 'shubra_el_kheima',
      lineNumber: '2',
      stationName: {'ar': 'شبرا الخيمة', 'en': 'Shubra El-Kheima'},
      attractions: [
        TouristAttraction(
          id: 'mohamed_ali_palace_shubra',
          name: {
            'ar': 'قصر محمد علي باشا بشبرا',
            'en': 'Mohamed Ali Palace (Shubra)',
          },
          description: {
            'ar':
                'تحفة فنية معمارية تجمع بين الطرازين الغربي والإسلامي، يشتهر بفسقية المياه الفخمة والرسومات الرائعة.',
            'en':
                'A magnificent historical palace blending European and Islamic designs, famous for its grand marble fountain pool.',
          },
          category: AttractionCategory.palace,
          emoji: '🏰',
          rating: 4.8,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '14 (Or short taxi ride)',
          tags: ['Palace', 'History', 'Mohamed Ali Dynasty'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Mohammed_Ali_Palace_in_Shubra',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mohammed_Ali_Palace_Shubra.jpg/1280px-Mohammed_Ali_Palace_Shubra.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'koleyet_el_zerah',
      lineNumber: '2',
      stationName: {'ar': 'كلية الزراعة', 'en': 'Koleyet El-Zerah'},
      attractions: [
        TouristAttraction(
          id: 'shubra_agriculture_faculty',
          name: {
            'ar': 'كلية زراعة جامعة عين شمس التراثية',
            'en': 'Ain Shams Faculty of Agriculture Historic Grounds',
          },
          description: {
            'ar':
                'تضم مبانٍ وحدائق شاسعة لزراعة النباتات النادرة وتصميم المسطحات الخضراء الجميلة.',
            'en':
                'Features expansive campus gardens filled with rare plant cross breeds and educational greens.',
          },
          category: AttractionCategory.university,
          emoji: '🌱',
          rating: 4.1,
          openHours: '8:00 AM – 5:00 PM',
          isFree: true,
          admissionEGP: 'Free (ID Check)',
          walkingMinutes: '2',
          tags: ['University', 'Nature'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ain_Shams_University', // General Ain Shams info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ain_Shams_Agriculture_Faculty.jpg/1280px-Ain_Shams_Agriculture_Faculty.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'mezallat',
      lineNumber: '2',
      stationName: {'ar': 'المظلات', 'en': 'Mezallat'},
      attractions: [
        TouristAttraction(
          id: 'mezallat_nile_park',
          name: {
            'ar': 'حديقة المظلات النيلية العامية',
            'en': 'Mezallat Public Nile Park',
          },
          description: {
            'ar':
                'حديقة عامة واسعة تطل على نهر النيل، يفضلها العائلات للتنزه رخيص الثمن وركوب القوارب الصغيرة.',
            'en':
                'A spacious public riverside park, highly popular for budget friendly family picnics and brief boat loops.',
          },
          category: AttractionCategory.park,
          emoji: '🌳',
          rating: 4.0,
          openHours: '8:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '10 EGP',
          walkingMinutes: '6',
          tags: ['Park', 'Nile', 'Family Leisure'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Shubra_El_Kheima', // General Shubra info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mezallat_Nile_Park.jpg/1280px-Mezallat_Nile_Park.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'khalafawy',
      lineNumber: '2',
      stationName: {'ar': 'الخلفاوي', 'en': 'Khalafawy'},
      attractions: [
        TouristAttraction(
          id: 'khalafawy_food_street',
          name: {
            'ar': 'ممر مطاعم الأسماك والمشويات بالخلفاوي',
            'en': 'Khalafawy Seafood & Grill Avenue',
          },
          description: {
            'ar':
                'منطقة طعام محلية شهيرة جداً في شبرا لتقديم الوجبات الشرقية والأسماك الطازجة بجودة مذهلة وبأسعار متوسطة.',
            'en':
                'A very popular local food lane in Shubra known for authentic seafood dining and oriental grills.',
          },
          category: AttractionCategory.restaurant,
          emoji: '🐟',
          rating: 4.4,
          openHours: '12:00 PM – Midnight',
          isFree: false,
          admissionEGP: 'Variable prices',
          walkingMinutes: '4',
          tags: ['Food', 'Seafood', 'Local Experience'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Shubra', // General Shubra info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Khalafawy_Seafood_Street.jpg/1280px-Khalafawy_Seafood_Street.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'sainte_teresa',
      lineNumber: '2',
      stationName: {'ar': 'سانت تريزا', 'en': 'Sainte Teresa'},
      attractions: [
        TouristAttraction(
          id: 'st_teresa_church_shubra',
          name: {
            'ar': 'كنيسة سانت تريزا الشهيرة بشبرا',
            'en': 'Basilica of St. Therese (Shubra)',
          },
          description: {
            'ar':
                'كنيسة كاثوليكية تاريخية عظيمة، يقصدها المسلمون والمسيحيون طلباً للتبرك وتقديم النذور وتتميز بجدرانها الجميلة.',
            'en':
                'A historic, globally recognized Catholic basilica visited by both Christians and Muslims for blessings.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.9,
          openHours: '6:00 AM – 9:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Church', 'Spiritual Landmark', 'Architecture'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Basilica_of_St._Therese,_Shubra',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/St_Therese_Church_Shubra.jpg/1280px-St_Therese_Church_Shubra.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'shudra_el_balad',
      lineNumber: '2',
      stationName: {'ar': 'روض الفرج', 'en': 'Rod El-Farag'},
      attractions: [
        TouristAttraction(
          id: 'rod_elfarag_market_history',
          name: {
            'ar': 'منطقة سوق روض الفرج التراثي وبقاياه',
            'en': 'Rod El-Farag Old Market District',
          },
          description: {
            'ar':
                'منطقة السوق التاريخية الأكثر شهرة في السينما المصرية القديمة لتجارة الفواكه والخضار بالجملة.',
            'en':
                'The iconic old market district legendary in classic Egyptian cinema for wholesale commerce.',
          },
          category: AttractionCategory.market,
          emoji: '🍉',
          rating: 4.0,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['History', 'Culture'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Rod_El-Farag', // General Rod El-Farag info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Rod_El-Farag_Market.jpg/1280px-Rod_El-Farag_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'massarra',
      lineNumber: '2',
      stationName: {'ar': 'مسرة', 'en': 'Massarra'},
      attractions: [
        TouristAttraction(
          id: 'shubra_street_fashion',
          name: {
            'ar': 'شارع شبرا الرئيسي للتسوق والموضة',
            'en': 'Shubra Shopping Street (Fashion Centers)',
          },
          description: {
            'ar':
                'من أقدم وأكبر الشوارع التجارية في مصر لبيع الملابس والأحذية والحلي بأسعار ممتازة لجميع الفئات.',
            'en':
                'One of Cairo\'s most massive, traditional retail streets packed with clothes and shoes shops.',
          },
          category: AttractionCategory.market,
          emoji: '👗',
          rating: 4.6,
          openHours: '11:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free walking',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'اخرج من مخارج شارع شبرا الرئيسي لتجد المحلات محيطة بك فوراً.',
            'en':
                'Exit directly onto Shubra street to find shopping centers starting from the station gates.',
          },
          tags: ['Shopping', 'Bargains', 'Fashion'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Shubra', // General Shubra info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Shubra_Street_Shopping.jpg/1280px-Shubra_Street_Shopping.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'al_shuhada_l2',
      lineNumber: '2',
      stationName: {
        'ar': 'الشهداء (رمسيس - خط 2)',
        'en': 'Al-Shuhada (Ramses - Line 2)',
      },
      attractions: [
        TouristAttraction(
          id: 'l2_ramses_square_hub',
          name: {
            'ar': 'ميدان رمسيس ومسجد الفتح',
            'en': 'Ramses Square & Al-Fath Mosque',
          },
          description: {
            'ar':
                'قلب القاهرة الصاخب، يضم مسجد الفتح بعمارته الإسلامية الفخمة ومئذنته الشاهقة الارتفاع.',
            'en':
                'The bustling mega square of Cairo, home to the architectural marvel Al-Fath Mosque.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏟️',
          rating: 4.3,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['City Center', 'Mosque', 'Transit Area'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Ramses_Square',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ramses_Square_Cairo.jpg/1280px-Ramses_Square_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ataba_l2',
      lineNumber: '2',
      stationName: {'ar': 'العتبة (خط 2)', 'en': 'Attaba (Line 2)'},
      attractions: [
        TouristAttraction(
          id: 'sour_azbakeya_books',
          name: {
            'ar': 'سور الأزبكية للكتب القديمة',
            'en': 'Sour El-Azbakeya Vintage Book Market',
          },
          description: {
            'ar':
                'السوق الأشهر عالمياً وعربياً لبيع الكتب والمجلات النادرة، المخطوطات والكتب المستعملة بأسعار تبدأ من ملاليم.',
            'en':
                'The most famous market in the Arab world for vintage, rare, and cheap used books.',
          },
          category: AttractionCategory.market,
          emoji: '📚',
          rating: 4.9,
          openHours: '9:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free entry',
          walkingMinutes: '2',
          tags: ['Books', 'Culture', 'Treasure Hunt'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Sour_El-Azbakeya',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Sour_El-Azbakeya_Book_Market.jpg/1280px-Sour_El-Azbakeya_Book_Market.jpg',
          ],
        ),
        TouristAttraction(
          id: 'attaba_clothing_bazaar',
          name: {
            'ar': 'أسواق العتبة والموسكي الشعبية',
            'en': 'Attaba & El-Mosky Mega Wholesale Markets',
          },
          description: {
            'ar':
                'المركز الرئيسي في مصر للتجارة الشعبية وشراء أي شيء وكل شيء بأسعار الجملة الأصلية.',
            'en':
                'The primary grand commercial heart of Cairo for low cost textiles, clothing, and household goods.',
          },
          category: AttractionCategory.market,
          emoji: '👕',
          rating: 4.5,
          openHours: '9:00 AM – 9:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Shopping', 'Wholesale', 'Crowded'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Attaba', // General Attaba info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Attaba_Market_Cairo.jpg/1280px-Attaba_Market_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'mohammad_naguib',
      lineNumber: '2',
      stationName: {'ar': 'محمد نجيب', 'en': 'Mohamed Naguib'},
      attractions: [
        TouristAttraction(
          id: 'abdeen_palace_museums',
          name: {
            'ar': 'قصر عابدين الرئاسي ومتاحفه',
            'en': 'Abdeen Palace & Museums',
          },
          description: {
            'ar':
                'قصر ملكي فخم مذهل تحول إلى متاحف رئاسية تعرض الأسلحة النادرة، هدايا الملوك والرؤساء والفضيات الفريدة.',
            'en':
                'A spectacular royal palace turned into a museum complex showcasing luxurious presidential gifts, silver, and weapons.',
          },
          category: AttractionCategory.palace,
          emoji: '🏰',
          rating: 4.9,
          openHours: '9:00 AM – 3:00 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '6',
          boardingHint: {
            'ar':
                'اخرج من مخرج شارع عابدين وامشي طوالي هتلاقي ساحة القصر الكبيرة.',
            'en':
                'Exit towards Abdeen street and walk straight to reach the grand palace courtyard pavilion.',
          },
          tags: ['Royal', 'Palace', 'Museum', 'Premium'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Abdeen_Palace',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Abdeen_Palace_Cairo.jpg/1280px-Abdeen_Palace_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'sadat_l2',
      lineNumber: '2',
      stationName: {
        'ar': 'السادات (خط 2 التبادلية)',
        'en': 'Sadat (Line 2 Interchange)',
      },
      attractions: [
        TouristAttraction(
          id: 'tahrir_grecian_campus',
          name: {
            'ar': 'مجمع الجريك كامبس الثقافي بالتحرير',
            'en': 'The GrEEK Campus (Tech & Art Hub)',
          },
          description: {
            'ar':
                'مجمع تكنولوجي وفني وثقافي بوسط البلد، يستضيف معارض الفن، حفلات الروك، ومكاتب الشركات الناشئة.',
            'en':
                'Cairo\'s premier heritage tech and arts park, hosting startup offices, alternative rock concerts, and arts galleries.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🚀',
          rating: 4.7,
          openHours: '8:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free Entry (Varies by concert)',
          walkingMinutes: '5',
          tags: ['Tech', 'Concerts', 'Downtown Culture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/The_GrEEK_Campus',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/The_GrEEK_Campus_Cairo.jpg/1280px-The_GrEEK_Campus_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'opera',
      lineNumber: '2',
      stationName: {'ar': 'الأوبرا', 'en': 'Opera'},
      attractions: [
        TouristAttraction(
          id: 'cairo_opera_house_complex',
          name: {'ar': 'دار الأوبرا المصرية', 'en': 'Cairo Opera House'},
          description: {
            'ar':
                'قلب الفنون الموسيقية والمسرحية الراقية بمصر، يقدم عروض الباليه، الموسيقى السيمفونية والمعارض الفنية المتميزة.',
            'en':
                'The peak of arts and classical performance in Egypt, showcasing ballet, symphonies, and fine arts exhibitions.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🎭',
          rating: 4.9,
          openHours: '9:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: 'Varies by concert ticket',
          walkingMinutes: '2',
          boardingHint: {
            'ar':
                'اركب في أول عربية بالقطار المتجه للجيزة لتخرج أمام بوابة الأوبرا تماماً.',
            'en':
                'Board the front car if heading towards Giza to exit right in front of the Opera security parameters.',
          },
          tags: ['Culture', 'Music', 'Theater', 'Zamalek Island'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Cairo_Opera_House',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cairo_Opera_House.jpg/1280px-Cairo_Opera_House.jpg',
          ],
        ),
        TouristAttraction(
          id: 'mahmoud_mokhtar_museum',
          name: {
            'ar': 'متحف المثال محمود مختار',
            'en': 'Mahmoud Mokhtar Sculpture Museum',
          },
          description: {
            'ar':
                'متحف فني رائع يضم روائع النحات المصري الشهير محمود مختار صانع تمثال نهضة مصر.',
            'en':
                'An elegant museum displaying fine stone sculptures by Egypt\'s legendary pioneer sculptor Mahmoud Mokhtar.',
          },
          category: AttractionCategory.museum,
          emoji: '🗿',
          rating: 4.7,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '40 EGP',
          walkingMinutes: '6',
          tags: ['Museum', 'Art', 'Sculpture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Mahmoud_Mokhtar_Museum',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mahmoud_Mokhtar_Museum_Cairo.jpg/1280px-Mahmoud_Mokhtar_Museum_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'dokki',
      lineNumber: '2',
      stationName: {'ar': 'الدقي', 'en': 'Dokki'},
      attractions: [
        TouristAttraction(
          id: 'mossaddak_shopping_street',
          name: {
            'ar': 'شوارع مصدق ومحي الدين أبو العز للتسوق',
            'en': 'Mossaddak & Mohie El-Din Shopping Streets',
          },
          description: {
            'ar':
                'منطقة راقية ومزدحمة تمثل مركز الموضة، الماركات العالمية، المطاعم السريعة والكافيهات الشهيرة بالدقي.',
            'en':
                'Trendy, upscale commercial streets featuring global fashion brands, fast food lanes, and lively cafes.',
          },
          category: AttractionCategory.entertainment,
          emoji: '☕',
          rating: 4.5,
          openHours: '10:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free walking',
          walkingMinutes: '4',
          tags: ['Shopping', 'Cafes', 'Modern Cairo'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Dokki', // General Dokki info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Dokki_Shopping_Street.jpg/1280px-Dokki_Shopping_Street.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'bohooth',
      lineNumber: '2',
      stationName: {'ar': 'البحوث', 'en': 'El-Bohooth'},
      attractions: [
        TouristAttraction(
          id: 'national_research_center',
          name: {
            'ar': 'المركز القومي للبحوث العلمي',
            'en': 'National Research Center',
          },
          description: {
            'ar':
                'أكبر صرح علمي بحثي وتكنولوجي في مصر يمتد على مساحة واسعة بالدقي.',
            'en':
                'The largest multidisciplinary scientific research hub in Egypt.',
          },
          category: AttractionCategory.landmark,
          emoji: '🔬',
          rating: 4.1,
          openHours: '8:00 AM – 4:00 PM',
          isFree: true,
          admissionEGP: 'Official entry',
          walkingMinutes: '3',
          tags: ['Science', 'Landmark'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/National_Research_Centre_(Egypt)',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/National_Research_Center_Egypt.jpg/1280px-National_Research_Center_Egypt.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'giza_university',
      lineNumber: '2',
      stationName: {'ar': 'جامعة القاهرة', 'en': 'Cairo University'},
      attractions: [
        TouristAttraction(
          id: 'cairo_university_dome',
          name: {
            'ar': 'قبة جامعة القاهرة التاريخية وساعتها',
            'en': 'Cairo University Historic Dome & Clock Tower',
          },
          description: {
            'ar':
                'بنيت عام 1908، صرح تعليمي مذهل يتميز بقبته النحاسية الأيقونية العملاقة وساعته التاريخية الشهيرة عالمياً.',
            'en':
                'Founded in 1908, featuring the world famous majestic copper dome and legendary campus clock tower.',
          },
          category: AttractionCategory.university,
          emoji: '🎓',
          rating: 4.8,
          openHours: '7:00 AM – 7:00 PM',
          isFree: true,
          admissionEGP: 'Free (Students or pre-arranged visitors ID)',
          walkingMinutes: '2',
          boardingHint: {
            'ar':
                'محطة تبادلية ضخمة مع الخط الثالث، اتبع المسار العلوي المريح للتبديل.',
            'en':
                'A massive interchange station with Line 3. Use the elevated walkways for seamless transfer.',
          },
          tags: ['University', 'History', 'Iconic Dome'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Cairo_University',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cairo_University_Dome.jpg/1280px-Cairo_University_Dome.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'giza',
      lineNumber: '2',
      stationName: {'ar': 'الجيزة', 'en': 'Giza'},
      attractions: [
        TouristAttraction(
          id: 'pharaonic_village_giza',
          name: {
            'ar': 'القرية الفرعونية بالجيزة',
            'en': 'The Pharaonic Village',
          },
          description: {
            'ar':
                'متحف حي مذهل على ضفاف النيل؛ تأخذك فيه قوارب في رحلة عبر القنوات المائية لرؤية ممثلين يجسدون حياة الفراعنة وصناعاتهم بدقة.',
            'en':
                'An extraordinary living history museum featuring Nile boat cruises amid live actors portraying ancient Egyptian life and crafts.',
          },
          category: AttractionCategory.museum,
          emoji: '🛶',
          rating: 4.6,
          openHours: '9:00 AM – 6:00 PM',
          isFree: false,
          admissionEGP: '300 EGP',
          walkingMinutes:
              '15 (Highly recommended to take a 5 min taxi from station)',
          tags: ['Pharaonic', 'Family', 'Nile Cruise', 'Live Museum'],
        ),
        TouristAttraction(
          id: 'giza_zoo',
          name: {'ar': 'حديقة حيوان الجيزة', 'en': 'Giza Zoo'},
          description: {
            'ar':
                'أقدم وأكبر حديقة حيوان في مصر والشرق الأوسط، تضم مجموعة واسعة من الحيوانات والطيور النادرة.',
            'en':
                'The oldest and largest zoo in Egypt and the Middle East, featuring a wide variety of rare animals and birds.',
          },
          category: AttractionCategory.park,
          emoji: '🦁',
          rating: 4.3,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '5 EGP',
          walkingMinutes: '10',
          tags: ['Zoo', 'Family', 'Nature'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Giza_Zoo',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Giza_Zoo_Entrance.jpg/1280px-Giza_Zoo_Entrance.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'omm_el_misryeen',
      lineNumber: '2',
      stationName: {'ar': 'أم المصريين', 'en': 'Omm El-Misryeen'},
      attractions: [
        TouristAttraction(
          id: 'giza_railway_club_omm',
          name: {
            'ar': 'نادي السكة الحديد الرياضي بالجيزة',
            'en': 'Giza Railway Social & Sports Club',
          },
          description: {
            'ar':
                'نادي عائلي ورياضي واسع المساحة، يحتوي على ملاعب كرة قدم كبرى وجلسات شرقية مريحة للمسافرين.',
            'en':
                'A long standing community sports club with football fields and relaxed outdoor seating configurations.',
          },
          category: AttractionCategory.sport,
          emoji: '⚽',
          rating: 3.9,
          openHours: '10:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '20 EGP',
          walkingMinutes: '5',
          tags: ['Sports', 'Club', 'Local Chill'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Giza', // General Giza info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Giza_Railway_Club.jpg/1280px-Giza_Railway_Club.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'sakiat_mekky',
      lineNumber: '2',
      stationName: {'ar': 'ساقية مكي', 'en': 'Sakiat Mekky'},
      attractions: [
        TouristAttraction(
          id: 'giza_market_crafts',
          name: {
            'ar': 'سوق الخشب والأثاث التراثي بساقية مكي',
            'en': 'Sakiat Mekky Traditional Furniture Markets',
          },
          description: {
            'ar':
                'حي حرفي شهير بتصنيع وبيع الأثاث والأخشاب يدوياً بمهارة وأسعار تنافسية ورخيصة.',
            'en':
                'A localized artisan district famous for woodturning workshops and bargain furniture sales.',
          },
          category: AttractionCategory.market,
          emoji: '🪑',
          rating: 4.0,
          openHours: '10:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '6',
          tags: ['Shopping', 'Crafts'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Giza', // General Giza info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Sakiat_Mekky_Market.jpg/1280px-Sakiat_Mekky_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_mounib',
      lineNumber: '2',
      stationName: {'ar': 'المنيب', 'en': 'El-Mounib'},
      attractions: [
        TouristAttraction(
          id: 'mounib_south_terminal',
          name: {
            'ar': 'موقف الميب الإقليمي للصعيد',
            'en': 'El-Mounib Upper Egypt Bus Terminal',
          },
          description: {
            'ar':
                'المحطة النهائية للخط الثاني، وتعتبر بوابة القاهرة الكبرى للإنطلاق إلى مدن ومحافظات صعيد مصر (الفيوم، بني سويف، المنيا، أسيوط).',
            'en':
                'The grand southern transit station connecting Cairo seamlessly to Upper Egypt governorates.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🚌',
          rating: 4.1,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free Access',
          walkingMinutes: '2',
          boardingHint: {
            'ar':
                'آخر محطة بالخط الثاني، تأكد من النزول ومتابعة لوحات اتجاه الأتوبيسات للصعيد.',
            'en':
                'Final station of Line 2. Exit towards the intercity bus bays for long distance travel.',
          },
          tags: ['Transit', 'Upper Egypt Route', 'Terminal'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/El-Mounib', // General El-Mounib info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Mounib_Bus_Terminal.jpg/1280px-El_Mounib_Bus_Terminal.jpg',
          ],
        ),
      ],
    ),

    // =========================================================================
    // ─── LINE 3: ADLY MANSOUR TO KIT KAT & BRANCHES (30 STATIONS COMPLETE) ───
    // =========================================================================
    StationAttractions(
      stationId: 'adly_mansour',
      lineNumber: '3',
      stationName: {'ar': 'عدلي منصور', 'en': 'Adly Mansour'},
      attractions: [
        TouristAttraction(
          id: 'adly_mansour_mega_hub',
          name: {
            'ar': 'مجمع عدلي منصور التبادلي العملاق',
            'en': 'Adly Mansour Mega Transportation Hub',
          },
          description: {
            'ar':
                'أكبر محطة تبادلية في الشرق الأوسط؛ تربط مترو الأنفاق، القطار الكهربائي الخفيف (LRT) المتجه للعاصمة الإدارية، والأتوبيس الترددي (BRT).',
            'en':
                'The largest transportation hub in the Middle East, linking Metro Line 3, LRT (to New Capital), and BRT express systems.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🎛️',
          rating: 4.9,
          openHours: '5:00 AM – 1:00 AM',
          isFree: true,
          admissionEGP: 'Free Entry',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'اخرج من رصيف المترو واتبع اللوحات الزرقاء لركوب قطار العاصمة الإدارية الـ LRT.',
            'en':
                'Seamlessly transition out of the metro tracks towards the LRT platform following the blue signage.',
          },
          tags: ['Mega Hub', 'New Capital LRT', 'Transit Modernity'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Adly_Mansour_Station',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Adly_Mansour_Mega_Hub.jpg/1280px-Adly_Mansour_Mega_Hub.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_haykestep',
      lineNumber: '3',
      stationName: {'ar': 'الهايكستب', 'en': 'El-Haykestep'},
      attractions: [
        TouristAttraction(
          id: 'haykestep_transit_way',
          name: {
            'ar': 'طريق السويس الصحراوي السريع والمواقف',
            'en': 'Suez Road Express Transit Junction',
          },
          description: {
            'ar':
                'محطة علوية حديثة تخدم ضواحي طريق السويس الصحراوي، ومصممة بأحدث الأنظمة المعمارية.',
            'en':
                'A state of the art elevated station connecting users directly to Cairo Suez desert highway links.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🛣️',
          rating: 4.2,
          openHours: '5:00 AM – 1:00 AM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['Transit', 'Modern Outpost'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Suez_Road', // General Suez Road info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Haykestep_Metro_Station.jpg/1280px-El_Haykestep_Metro_Station.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'omar_ibn_el_khattab',
      lineNumber: '3',
      stationName: {'ar': 'عمر بن الخطاب', 'en': 'Omar Ibn El-Khattab'},
      attractions: [
        TouristAttraction(
          id: 'omar_shopping_avenues',
          name: {
            'ar': 'محيط أسواق جسر السويس للملابس',
            'en': 'Gisr El-Suez Fashion Retail Outlets',
          },
          description: {
            'ar':
                'منطقة أسواق مفتوحة ومحلات ضخمة لبيع الملابس والأحذية الجاهزة من المصانع مباشرة بأسعار اقتصادية للغاية.',
            'en':
                'An extensive street lining shopping hub offering factory direct prices for clothes and linens.',
          },
          category: AttractionCategory.market,
          emoji: '🧥',
          rating: 4.1,
          openHours: '11:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Shopping', 'Factory Outlets'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Gisr_El-Suez', // General Gisr El-Suez info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Gisr_El-Suez_Market.jpg/1280px-Gisr_El-Suez_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'qubaa',
      lineNumber: '3',
      stationName: {'ar': 'قباء', 'en': 'Qubaa'},
      attractions: [
        TouristAttraction(
          id: 'qubaa_local_gardens',
          name: {
            'ar': 'مشاتل قباء النباتية الكبرى',
            'en': 'Qubaa Grand Botanical Nurseries',
          },
          description: {
            'ar':
                'مجموعة من المشاتل الكبيرة الممتدة لبيع نباتات الزينة، الزهور النادرة، وأشجار الحدائق بأسعار رخيصة للجمهور.',
            'en':
                'A vibrant stretch of commercial nurseries selling decorative flora, exotic flowers, and home garden plants.',
          },
          category: AttractionCategory.market,
          emoji: '🌱',
          rating: 4.3,
          openHours: '8:00 AM – 9:00 PM',
          isFree: true,
          admissionEGP: 'Free entry',
          walkingMinutes: '5',
          tags: ['Plants', 'Flowers', 'Nature'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Qubaa', // General Qubaa info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Qubaa_Nurseries.jpg/1280px-Qubaa_Nurseries.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'hescham_barakat',
      lineNumber: '3',
      stationName: {'ar': 'هشام بركات', 'en': 'Hescham Barakat'},
      attractions: [
        TouristAttraction(
          id: 'barakat_sports_fields',
          name: {
            'ar': 'مجمع ملاعب النزهة الجديدة الرياضي',
            'en': 'El-Nozha El-Gedida Sports Complex',
          },
          description: {
            'ar':
                'ملاعب حديثة للياقة البدنية، كرة القدم الخماسية، وممرات مخصصة لممارسة رياضة الجري بأمان.',
            'en':
                'Modern turf fields for football and dedicated secured running tracks.',
          },
          category: AttractionCategory.sport,
          emoji: '🏃',
          rating: 4.4,
          openHours: '6:00 AM – Midnight',
          isFree: false,
          admissionEGP: 'Subscription or small entry fee',
          walkingMinutes: '4',
          tags: ['Sports', 'Fitness', 'Running'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Nozha', // General Nozha info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Nozha_Sports_Complex.jpg/1280px-El_Nozha_Sports_Complex.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_noozha',
      lineNumber: '3',
      stationName: {'ar': 'النزهة', 'en': 'El-Nozha'},
      attractions: [
        TouristAttraction(
          id: 'noozha_residential_cafes',
          name: {
            'ar': 'ممشى كافيهات ومطاعم حي النزهة الجديدة',
            'en': 'El-Nozha El-Gedida Food & Cafe Lounges',
          },
          description: {
            'ar':
                'حي سكني راقٍ ومنظم، يحتوي على شوارع عريضة تضم أرقى الكافيهات الحديثة ومطاعم الوجبات السريعة العالمية.',
            'en':
                'An upscale neighborhood avenue featuring trendy international cafe brands and dining zones.',
          },
          category: AttractionCategory.cafe,
          emoji: '☕',
          rating: 4.6,
          openHours: '8:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free walking',
          walkingMinutes: '3',
          tags: ['Cafes', 'Dining', 'Modern Outing'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Nozha', // General Nozha info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Nozha_Cafes.jpg/1280px-El_Nozha_Cafes.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId:
          'nat_rec_center', // Alternative shorthand context name for Line 3 industrial link station
      lineNumber: '3',
      stationName: {'ar': 'نادي الشمس', 'en': 'El-Shams Club'},
      attractions: [
        TouristAttraction(
          id: 'shams_mega_sporting_club',
          name: {
            'ar': 'نادي الشمس الرياضي الاجتماعي العملاق',
            'en': 'El-Shams Sporting Club',
          },
          description: {
            'ar':
                'أحد أكبر الأندية الرياضية في الشرق الأوسط من حيث المساحة والملاعب والمرافق الأولمبية والترفيهية.',
            'en':
                'One of the largest athletic and social clubs in the world by surface area, featuring magnificent Olympic pools and fields.',
          },
          category: AttractionCategory.sport,
          emoji: '🦅',
          rating: 4.8,
          openHours: '8:00 AM – Midnight',
          isFree: false,
          admissionEGP: 'Members & Guest Tickets (50 EGP)',
          walkingMinutes: '2',
          boardingHint: {
            'ar':
                'المحطة تقع بجوار الأسوار البوابية لنادي الشمس مباشرة، اخرج من بوابة النادي.',
            'en':
                'The station sits directly next to El-Shams Club gates for instant leisure entry.',
          },
          tags: ['Sports', 'Mega Club', 'Olympic Complex', 'Family'],
          wikiUrl: 'https://en.wikipedia.org/wiki/El_Shams_Club',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Shams_Club_Cairo.jpg/1280px-El_Shams_Club_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'alf_maskan',
      lineNumber: '3',
      stationName: {'ar': 'ألف مسكن', 'en': 'Alf Maskan'},
      attractions: [
        TouristAttraction(
          id: 'alf_maskan_square_market',
          name: {
            'ar': 'ميدان وأسواق ألف مسكن المركزية',
            'en': 'Alf Maskan Square & Shopping District',
          },
          description: {
            'ar':
                'ميدان تجاري عملاق لا ينام، يضم مئات المحلات التجارية لجميع السلع الاستهلاكية بأسعار رخيصة ومحطات ميكروباص لجميع أنحاء القاهرة.',
            'en':
                'A massive commercial crossroad district that never sleeps, offering thousands of retail deals.',
          },
          category: AttractionCategory.market,
          emoji: '🏪',
          rating: 4.2,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          tags: ['Market', 'Shopping', 'Transit Link'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Alf_Maskan', // General Alf Maskan info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Alf_Maskan_Square.jpg/1280px-Alf_Maskan_Square.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'heliopolis',
      lineNumber: '3',
      stationName: {'ar': 'ميدان هليوبوليس', 'en': 'Heliopolis Square'},
      attractions: [
        TouristAttraction(
          id: 'saint_mark_basilica_heliopolis',
          name: {
            'ar': 'كنيسة البازيليك (اللاتين الكاثوليك)',
            'en': 'Basilica of Our Lady of Heliopolis (The Basilica)',
          },
          description: {
            'ar':
                'تحفة معمارية بيزنطية مهيبة بناها البارون إمبان في قلب مصر الجديدة مدفون داخلها، وتعتبر من معالم العاصمة.',
            'en':
                'A majestic Byzantine architectural masterpiece built by Baron Empain where he is buried.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.9,
          openHours: '8:00 AM – 8:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '4',
          tags: [
            'Basilica',
            'History',
            'Baron Empain Dynasty',
            'UNESCO Heritage Style',
          ],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Basilica_of_Our_Lady_of_Heliopolis',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Basilica_of_Our_Lady_of_Heliopolis.jpg/1280px-Basilica_of_Our_Lady_of_Heliopolis.jpg',
          ],
        ),
        TouristAttraction(
          id: 'heliopolis_heritage_walk',
          name: {
            'ar': 'ممشى هليوبوليس المعماري التراثي',
            'en': 'Heliopolis Historic Arcaded Streets',
          },
          description: {
            'ar':
                'شوارع رائعة تتميز بالمباني التاريخية ذات الطراز المعماري البلجيكي والعربي المندمج والفريد.',
            'en':
                'Magnificent historic walking lanes featuring breathtaking Belgian and Euro Islamic architecture blend.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏛️',
          rating: 4.8,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          tags: ['Architecture', 'History', 'Walking Track'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Heliopolis,_Cairo',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Heliopolis_Historic_Streets.jpg/1280px-Heliopolis_Historic_Streets.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'haroun',
      lineNumber: '3',
      stationName: {'ar': 'هارون', 'en': 'Haroun'},
      attractions: [
        TouristAttraction(
          id: 'merryland_park_historic',
          name: {
            'ar': 'حديقة الميريلاند التاريخية بمصر الجديدة',
            'en': 'Merryland Botanical & Leisure Park',
          },
          description: {
            'ar':
                'أشهر وأكبر حديقة أشجار وبحيرات صناعية في مصر الجديدة؛ تم تجديدها بالكامل وتضم مطاعم وكافيهات فاخرة ومنطقة عروض مائية.',
            'en':
                'The most famous, expansive botanical family park in Heliopolis featuring artificial lakes and high end restaurants.',
          },
          category: AttractionCategory.park,
          emoji: '🌳',
          rating: 4.7,
          openHours: '9:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: '50 EGP',
          walkingMinutes: '6',
          tags: ['Park', 'Lakes', 'Family Outing', 'Premium Rest'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Merryland_Park',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Merryland_Park_Heliopolis.jpg/1280px-Merryland_Park_Heliopolis.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'al_ahram',
      lineNumber: '3',
      stationName: {
        'ar': 'الأهرام (مصر الجديدة)',
        'en': 'Al-Ahram (Heliopolis)',
      },
      attractions: [
        TouristAttraction(
          id: 'baron_palace_indie',
          name: {'ar': 'قصر البارون إمبان', 'en': 'Baron Empain Palace'},
          description: {
            'ar':
                'قصر أسطوري مستوحى من معبد أنكور وات الكمبودي والعمارة الهندية، يمثل الأيقونة المعمارية لمصر الجديدة.',
            'en':
                'A brilliant Cambodian and Hindu inspired architectural masterpiece, full of history and fully restored to stun visitors.',
          },
          category: AttractionCategory.palace,
          emoji: '🏰',
          rating: 4.9,
          openHours: '9:00 AM – 4:30 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '6',
          boardingHint: {
            'ar':
                'اخرج من مخارج شارع الأهرام وامشي خمس دقائق هتلاقي القصر ببرجه الهندي الأسطوري.',
            'en':
                'Exit via Al-Ahram street gates and take a brief 5 min stroll to see the stunning Indian tower rise.',
          },
          tags: [
            'Palace',
            'Iconic',
            'Heliopolis Kingpin',
            'Global Architecture',
          ],
          wikiUrl: 'https://en.wikipedia.org/wiki/Baron_Empain_Palace',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Baron_Empain_Palace_Cairo.jpg/1280px-Baron_Empain_Palace_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'korba_square_dining',
          name: {
            'ar': 'منطقة الكوربة التراثية الشهيرة',
            'en': 'The Historic Korba District',
          },
          description: {
            'ar':
                'أجمل وأرقى مناطق وسط مصر الجديدة، تتميز بالمباني ذات البواكي والباكيات التاريخية المليئة بأفخم الكافيهات والمطاعم العالمية.',
            'en':
                'Cairo\'s most gorgeous arcade style shopping and gourmet food district, boasting remarkable Euro-Arabic architecture.',
          },
          category: AttractionCategory.entertainment,
          emoji: '☕',
          rating: 4.9,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free walking track',
          walkingMinutes: '4',
          tags: ['Korba', 'Gourmet Food', 'Architecture', 'Nightlife'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Korba,_Heliopolis',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Korba_District_Heliopolis.jpg/1280px-Korba_District_Heliopolis.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'koleyet_el_banat',
      lineNumber: '3',
      stationName: {'ar': 'كلية البنات', 'en': 'Koleyet El-Banat'},
      attractions: [
        TouristAttraction(
          id: 'girls_college_campus',
          name: {
            'ar': 'كلية البنات جامعة عين شمس التاريخية',
            'en': 'Ain Shams University Girls College Grounds',
          },
          description: {
            'ar':
                'كلية عريقة تتميز بمبانيها الكلاسيكية الجميلة ومساحتها الخضراء المنظمة.',
            'en':
                'A historic, prominent educational campus featuring beautiful classic designs.',
          },
          category: AttractionCategory.university,
          emoji: '🎓',
          rating: 4.2,
          openHours: '8:00 AM – 5:00 PM',
          isFree: true,
          admissionEGP: 'Free (ID Verification)',
          walkingMinutes: '2',
          tags: ['University', 'Education'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ain_Shams_University', // General Ain Shams info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ain_Shams_Girls_College.jpg/1280px-Ain_Shams_Girls_College.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'stadium',
      lineNumber: '3',
      stationName: {'ar': 'الإستاد', 'en': 'The Stadium'},
      attractions: [
        TouristAttraction(
          id: 'cairo_international_stadium',
          name: {
            'ar': 'إستاد القاهرة الدولي والمجمع الأولمبي',
            'en': 'Cairo International Stadium Complex',
          },
          description: {
            'ar':
                'معقل مباريات كرة القدم الكبرى والبطولات الإفريقية والعالمية بمصر، يضم صالات مغطاة وملاعب أولمبية متكاملة ومجمعات سباحة.',
            'en':
                'The legendary home ground of Egyptian football championships and Olympic tournaments, hosting indoor halls and grand arenas.',
          },
          category: AttractionCategory.sport,
          emoji: '⚽',
          rating: 4.8,
          openHours: 'Varies by match and sports event schedules',
          isFree: false,
          admissionEGP: 'Depends on match ticket price',
          walkingMinutes: '4',
          boardingHint: {
            'ar':
                'انزل هنا لو رايح تتفرج على الماتش أو تحضر حفلات الصالة المغطاة الكبرى.',
            'en':
                'Alight here for express access to standard stadium entry and major sports events.',
          },
          tags: ['Football', 'Stadium', 'Olympic Events', 'Concerts'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Cairo_International_Stadium',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cairo_International_Stadium.jpg/1280px-Cairo_International_Stadium.jpg',
          ],
        ),
        TouristAttraction(
          id: 'city_stars_mall_transit',
          name: {
            'ar': 'مول سيتي ستارز (بالقرب من المحطة)',
            'en': 'Citystars Mega Mall (Nearby Link)',
          },
          description: {
            'ar':
                'أحد أكبر مولات التسوق والترفيه بمصر؛ يضم سينمات، مدينة ملاهي مغلقة، ومئات البراندات العالمية.',
            'en':
                'One of Cairo\'s most gigantic shopping and indoor entertainment destinations.',
          },
          category: AttractionCategory.market,
          emoji: '🛍️',
          rating: 4.7,
          openHours: '10:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free entry',
          walkingMinutes:
              '15 (Quick 4 min taxi ride recommended from station gates)',
          tags: ['Shopping', 'Mall', 'Cinemas', 'Entertainment'],
        ),
        TouristAttraction(
          id: 'nasr_city_park',
          name: {'ar': 'حديقة الطفل بمدينة نصر', 'en': 'Child Park Nasr City'},
          description: {
            'ar':
                'حديقة عامة كبيرة ومناسبة للعائلات والأطفال، تضم مناطق لعب ومساحات خضراء واسعة.',
            'en':
                'A large public park suitable for families and children, featuring play areas and vast green spaces.',
          },
          category: AttractionCategory.park,
          emoji: '🎠',
          rating: 4.1,
          openHours: '9:00 AM – 10:00 PM',
          isFree: false,
          admissionEGP: '5 EGP',
          walkingMinutes: '10',
          tags: ['Park', 'Family', 'Kids'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Nasr_City', // General Nasr City info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Child_Park_Nasr_City.jpg/1280px-Child_Park_Nasr_City.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'fair_zone',
      lineNumber: '3',
      stationName: {'ar': 'أرض المعارض', 'en': 'Fair Zone'},
      attractions: [
        TouristAttraction(
          id: 'cairo_fair_grounds_complex',
          name: {
            'ar': 'مركز أرض المعارض التاريخي بمدينة نصر',
            'en': 'Cairo Fairgrounds Convention Complex',
          },
          description: {
            'ar':
                'يستضيف المعارض التجارية الكبرى، الفعاليات الثقافية، والأسواق المفتوحة الكبيرة طوال العام.',
            'en':
                'The massive industrial convention complex hosting major commercial expos and open air consumer bazaars year round.',
          },
          category: AttractionCategory.landmark,
          emoji: '🎪',
          rating: 4.4,
          openHours: '9:00 AM – 9:00 PM (During exhibitions)',
          isFree: false,
          admissionEGP: 'Varies by exhibition (Usually 10-20 EGP)',
          walkingMinutes: '2',
          tags: ['Exhibitions', 'Conventions', 'Events'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Cairo_International_Convention_Centre',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cairo_Fairgrounds.jpg/1280px-Cairo_Fairgrounds.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'abbassia',
      lineNumber: '3',
      stationName: {'ar': 'العباسية', 'en': 'Abbassia'},
      attractions: [
        TouristAttraction(
          id: 'st_mark_cathedral_abbassia',
          name: {
            'ar': 'الكاتدرائية المرقسية الكبرى بالعباسية',
            'en': 'Saint Mark\'s Coptic Orthodox Cathedral',
          },
          description: {
            'ar':
                'مقر بابا الإسكندرية وبطريركية الكنيسة القبطية الأرثوذكسية، وتعد من أكبر الكاتدرائيات بقارة أفريقيا وتتميز بعمارتها الحديثة الفخمة.',
            'en':
                'The grand official seat of the Coptic Orthodox Pope, standing as one of the largest cathedrals in Africa.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.9,
          openHours: '8:00 AM – 6:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['Coptic Papal Seat', 'Cathedral', 'Major Architecture'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Saint_Mark%27s_Coptic_Orthodox_Cathedral',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Saint_Mark%27s_Coptic_Orthodox_Cathedral_Cairo.jpg/1280px-Saint_Mark%27s_Coptic_Orthodox_Cathedral_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'abou_bafr_el_seddik',
      lineNumber: '3',
      stationName: {'ar': 'عبده باشا', 'en': 'Abdou Pasha'},
      attractions: [
        TouristAttraction(
          id: 'engineering_ain_shams',
          name: {
            'ar': 'كلية الهندسة جامعة عين شمس العريقة',
            'en': 'Ain Shams Faculty of Engineering',
          },
          description: {
            'ar':
                'صرح تعليمي وهندسي وتاريخي ضخم يضم مبانٍ أثرية مميزة تخرج منها كبار مهندسي مصر.',
            'en':
                'The historical, prestigious engineering campus of Ain Shams University.',
          },
          category: AttractionCategory.university,
          emoji: '📐',
          rating: 4.5,
          openHours: '8:00 AM – 6:00 PM',
          isFree: true,
          admissionEGP: 'Free (ID Verification)',
          walkingMinutes: '3',
          tags: ['University', 'Campus', 'Engineering'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Ain_Shams_University', // General Ain Shams info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ain_Shams_Engineering_Faculty.jpg/1280px-Ain_Shams_Engineering_Faculty.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_geish',
      lineNumber: '3',
      stationName: {'ar': 'الجيش', 'en': 'El-Geish'},
      attractions: [
        TouristAttraction(
          id: 'el_zaher_baibars_mosque',
          name: {
            'ar': 'مسجد الظاهر بيبرس المملوكي',
            'en': 'Al-Zaher Baibars Mosque',
          },
          description: {
            'ar':
                'ثالث أكبر مسجد أثري في مصر، بناه السلطان المملوكي الظاهر بيبرس البندقداري عام 1268 م وتم ترميمه بالكامل ليصبح تحفة ساحرة.',
            'en':
                'The third largest historic mosque in Egypt, founded by Mamluk Sultan Baibars in 1268 AD and beautifully restored.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.9,
          openHours: '5:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '6',
          tags: [
            'Mamluk History',
            'Mosque',
            'Stunning Restoration',
            'UNESCO Grade',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'bab_el_shaariya_l3',
      lineNumber: '3',
      stationName: {
        'ar': 'باب الشعرية (خط 3)',
        'en': 'Bab El-Shaariya (Line 3)',
      },
      attractions: [
        TouristAttraction(
          id: 'moez_street_north_portal',
          name: {
            'ar': 'بوابة المعز الشمالية (باب الفتوح والنصر)',
            'en': 'Al-Moez Street North Gates (Bab Al-Futuh & Bab Al-Nasr)',
          },
          description: {
            'ar':
                'أكبر متحف مفتوح للآثار الإسلامية الفاطمية في العالم، يضم الحصون والأسوار والأسبلة العتيقة.',
            'en':
                'The majestic northern entry gates of Fatimid Islamic Cairo, a world heritage open air historical museum.',
          },
          category: AttractionCategory.monument,
          emoji: '🏰',
          rating: 4.9,
          openHours: '24/7 (Monuments close at 5:00 PM)',
          isFree: true,
          admissionEGP: 'Free walking (Monuments require ticket)',
          walkingMinutes: '7',
          tags: ['Fatimid Cairo', 'UNESCO', 'Gates', 'Islamic Architecture'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Al-Moez_Street',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Bab_Al-Futuh_Cairo.jpg/1280px-Bab_Al-Futuh_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ataba_l3',
      lineNumber: '3',
      stationName: {
        'ar': 'العتبة (خط 3 التبادلية)',
        'en': 'Attaba (Line 3 Interchange)',
      },
      attractions: [
        TouristAttraction(
          id: 'national_theater_egypt',
          name: {
            'ar': 'المسرح القومي المصري العريق',
            'en': 'The National Theater of Egypt',
          },
          description: {
            'ar':
                'صرح فني وثقافي عظيم تأسس بالقرن الـ 19 بحديقة الأزبكية، شهد روائع الفن الكلاسيكي ومسرحيات كبار الرواد.',
            'en':
                'A glorious 19th-century Khedivial arts theater, the pioneer stage of premium Arab theatrical plays.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🎭',
          rating: 4.8,
          openHours: 'Varies by active performance schedules',
          isFree: false,
          admissionEGP: 'Varies based on show tier',
          walkingMinutes: '2',
          tags: ['Theater', 'Arts', 'Downtown Heritage'],
          wikiUrl: 'https://en.wikipedia.org/wiki/National_Theatre_(Egypt)',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/National_Theatre_Egypt.jpg/1280px-National_Theatre_Egypt.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'nasser_l3',
      lineNumber: '3',
      stationName: {
        'ar': 'ناصر (خط 3 التبادلية)',
        'en': 'Nasser (Line 3 Interchange)',
      },
      attractions: [
        TouristAttraction(
          id: 'talaat_harb_downtown_walk',
          name: {
            'ar': 'شوارع وسط البلد التاريخية (طلعت حرب ومصطفى كامل)',
            'en': 'Downtown Historic Khedivial Streets Walk',
          },
          description: {
            'ar':
                'التنزه وسط الهندسة المعمارية الكلاسيكية على الطراز الأوروبي الخديوي الباريسي الفخم ومحلات وسط البلد التراثية.',
            'en':
                'Stroll through Cairo\'s unique 19th-century Khedivial architecture styled after Parisian European formats.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏙️',
          rating: 4.7,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free walking',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'محطة تبادلية فائقة التطور، اتبع الأرضيات الملونة للتبديل بين الخطين الأول والثالث.',
            'en':
                'A highly advanced interchange node. Follow color coded floor patterns for Line 1/3 changes.',
          },
          tags: ['Downtown', 'Khedivial Cairo', 'Walking Track'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Downtown_Cairo',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Downtown_Cairo_Khedivial_Architecture.jpg/1280px-Downtown_Cairo_Khedivial_Architecture.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'maspero',
      lineNumber: '3',
      stationName: {'ar': 'ماسبيرو', 'en': 'Maspero'},
      attractions: [
        TouristAttraction(
          id: 'radio_tv_building_maspero',
          name: {
            'ar': 'مبنى اتحاد الإذاعة والتليفزيون (ماسبيرو)',
            'en': 'Maspero Radio & TV Building Terminal',
          },
          description: {
            'ar':
                'مبنى ماسبيرو الدائري الأيقوني التاريخي، منطلق أول بث إعلامي مرئي بالشرق الأوسط ويطل مباشرة على النيل العظيم.',
            'en':
                'The iconic, circular historic broadcasting headquarters of Egypt standing tall over the Nile front.',
          },
          category: AttractionCategory.landmark,
          emoji: '📺',
          rating: 4.4,
          openHours: 'Visible from outside promenade',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['Media History', 'Iconic Building', 'Nile Front'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Maspero_Television_Building',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Maspero_Building_Cairo.jpg/1280px-Maspero_Building_Cairo.jpg',
          ],
        ),
        TouristAttraction(
          id: 'nile_corniche_towers',
          name: {
            'ar': 'كورنيش ماسبيرو وممشي أهل مصر الجديد',
            'en': 'Mamsha Ahl Misr Promenade (Maspero Side)',
          },
          description: {
            'ar':
                'ممشى سياحي عالمي متطور ومكون من مستويين يضم مطاعم وكافيهات فاخرة مباشرة فوق مياه النيل.',
            'en':
                'A world class multi level pedestrian Nile promenade packed with premium cafes and views.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🍹',
          rating: 4.8,
          openHours: '6:00 AM – 2:00 AM',
          isFree: false,
          admissionEGP: '20 EGP',
          walkingMinutes: '3',
          tags: ['Nile Promenade', 'Modern Cairo', 'Dining', 'Walking'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Nile_Corniche', // General Nile Corniche info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mamsha_Ahl_Misr_Cairo.jpg/1280px-Mamsha_Ahl_Misr_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'safaa_hegazi',
      lineNumber: '3',
      stationName: {
        'ar': 'صفاء حجازي (الزمالك)',
        'en': 'Safaa Hegazi (Zamalek)',
      },
      attractions: [
        TouristAttraction(
          id: 'cairo_tower_zamalek',
          name: {'ar': 'برج القاهرة الأيقوني', 'en': 'The Cairo Tower'},
          description: {
            'ar':
                'بني على شكل زهرة اللوتس الفرعونية القديمة بارتفاع 187 متراً، يمنحك أعلى إطلالة بانورامية 360 درجة لمشاهدة القاهرة والأهرامات.',
            'en':
                'An iconic 187-meter lotus-shaped concrete tower offering breathtaking 360-degree panoramic sights of Cairo.',
          },
          category: AttractionCategory.landmark,
          emoji: '🗼',
          rating: 4.8,
          openHours: '9:00 AM – 1:00 AM',
          isFree: false,
          admissionEGP: '70 EGP',
          walkingMinutes: '11 (Or 3 min taxi ride)',
          boardingHint: {
            'ar':
                'انزل هنا للوصول إلى أرقى شوارع جزيرة الزمالك وسفاراتها الفخمة وكافيهاتها.',
            'en':
                'Alight here to experience the premium elite island of Zamalek, global embassies, and high-end dining.',
          },
          tags: [
            'Iconic Tower',
            'Panorama View',
            'Premium Sight',
            'Zamalek Island',
          ],
          wikiUrl: 'https://en.wikipedia.org/wiki/Cairo_Tower',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cairo_Tower.jpg/1280px-Cairo_Tower.jpg',
          ],
        ),
        TouristAttraction(
          id: 'aisha_fahmy_palace_arts',
          name: {
            'ar': 'مجمع الفنون - قصر عائشة فهمي الأثري',
            'en': 'Aisha Fahmy Palace (Arts Center)',
          },
          description: {
            'ar':
                'قصر ملكي تاريخي فاخر ومباشر على النيل، يتميز بغرفه الإيطالية واليابانية الرائعة ويستضيف معارض الفن التشكيلي العالمية مجاناً للجمهور.',
            'en':
                'A brilliant, luxurious Khedivial palace hosting world class master fine arts galleries with free access.',
          },
          category: AttractionCategory.palace,
          emoji: '🖼️',
          rating: 4.9,
          openHours: '9:00 AM – 9:00 PM (Closed Fridays)',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['Royal Palace', 'Art Galleries', 'Nile View', 'Free Luxury'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Aisha_Fahmy_Palace',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Aisha_Fahmy_Palace_Cairo.jpg/1280px-Aisha_Fahmy_Palace_Cairo.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'kit_kat',
      lineNumber: '3',
      stationName: {'ar': 'الكيت كات', 'en': 'Kit Kat'},
      attractions: [
        TouristAttraction(
          id: 'om_kalthoum_historic_island_view',
          name: {
            'ar': 'كورنيش الكيت كات ومسرح البالون',
            'en': 'Kit Kat Nile Promenade & Balloon Theater',
          },
          description: {
            'ar':
                'منطقة ثقافية وفنية شعبية عريقة، تضم مسرح البالون الشهير لتقديم العروض الاستعراضية والسيرك القومي الفني بمصر.',
            'en':
                'A historic art neighborhood featuring Balloon Theater and the National Egyptian Circus staging acts.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🎪',
          rating: 4.5,
          openHours: '6:00 PM – Midnight (Shows)',
          isFree: false,
          admissionEGP: 'Varies by performance',
          walkingMinutes: '4',
          boardingHint: {
            'ar':
                'المحطة تتفرع بعدها إلى اتجاهين (شمالاً لروض الفرج / غرباً لجامعة القاهرة). انتبه للوحات الرصيف.',
            'en':
                'The station is the fork node split (North to Rod El-Farag / West to Cairo University). Check train banners.',
          },
          tags: ['Theater', 'Circus', 'Nile Side', 'Art Culture'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Kit_Kat_Club_(Cairo)', // General Kit Kat info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Balloon_Theater_Cairo.jpg/1280px-Balloon_Theater_Cairo.jpg',
          ],
        ),
      ],
    ),

    // ─── BRANCH A OF LINE 3 (TOWARDS ROD EL-FARAG TERMINAL) ──────────────────
    StationAttractions(
      stationId: 'sudan_street',
      lineNumber: '3',
      stationName: {'ar': 'شارع السودان', 'en': 'Sudan Street'},
      attractions: [
        TouristAttraction(
          id: 'sudan_street_bazaar',
          name: {
            'ar': 'أسواق شارع السودان التجارية للمفروشات',
            'en': 'Sudan Street Commercial Linens Market',
          },
          description: {
            'ar':
                'شارع تجاري طويل حيوي شهير ببيع المنسوجات والمفروشات والأجهزة المنزلية بأسعار منافسة.',
            'en':
                'A long busy market strip famous for traditional Egyptian home textiles and bargain utilities.',
          },
          category: AttractionCategory.market,
          emoji: '🧵',
          rating: 4.0,
          openHours: '10:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['Shopping', 'Local'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Imbaba', // General Imbaba info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Sudan_Street_Market_Imbaba.jpg/1280px-Sudan_Street_Market_Imbaba.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'imbaba',
      lineNumber: '3',
      stationName: {'ar': 'إمبابة', 'en': 'Imbaba'},
      attractions: [
        TouristAttraction(
          id: 'imbaba_kebab_lane',
          name: {
            'ar': 'مطاعم كباب ومشاوي إمبابة الشهيرة (البرنس)',
            'en': 'Imbaba Authentic Oriental Food Distict',
          },
          description: {
            'ar':
                'معقل الأكل الشرقي الشعبي ومحلات الكباب والمشاوي والطواجن المصرية الأصلية الأكثر شهرة وجاذبية لعشاق الطعام.',
            'en':
                'The epic center of rich traditional Egyptian street foods, legendary kebab houses, and authentic liver dining.',
          },
          category: AttractionCategory.restaurant,
          emoji: '🥩',
          rating: 4.7,
          openHours: '1:00 PM – 3:00 AM',
          isFree: false,
          admissionEGP: 'A la carte menu prices',
          walkingMinutes: '6',
          tags: ['Foodies Adventure', 'Local Legend', 'Kebab', 'Street Dining'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Imbaba',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Imbaba_Kebab_Street.jpg/1280px-Imbaba_Kebab_Street.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'el_bohy',
      lineNumber: '3',
      stationName: {'ar': 'البوهي', 'en': 'El-Bohy'},
      attractions: [
        TouristAttraction(
          id: 'bohy_local_hub',
          name: {
            'ar': 'سوق البوهي الشعبي للخضروات',
            'en': 'El-Bohy Traditional Produce Market',
          },
          description: {
            'ar':
                'سوق حيوي نابض بالألوان لاستكشاف الحياة اليومية البسيطة للمواطن المصري وتجارة الفواكه الطازجة.',
            'en':
                'A highly colorful, traditional fresh produce and street goods marketplace.',
          },
          category: AttractionCategory.market,
          emoji: '🍋',
          rating: 3.9,
          openHours: '6:00 AM – 9:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['Shopping', 'Local Vibe'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Imbaba', // General Imbaba info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Bohy_Market_Imbaba.jpg/1280px-El_Bohy_Market_Imbaba.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'al_gawzour',
      lineNumber: '3',
      stationName: {'ar': 'القومية العربية', 'en': 'El-Gawmya El-Arabeya'},
      attractions: [
        TouristAttraction(
          id: 'gawmya_shopping_stalls',
          name: {
            'ar': 'ممر محلات القومية للملابس الاقتصادية',
            'en': 'Gawmya Outlets for Bargain Clothing',
          },
          description: {
            'ar':
                'منطقة تجارية مكتظة تمتاز ببيع الإكسسوارات، الأحذية، والملابس بأسعار رخيصة جداً وتناسب الميزانيات المحدودة.',
            'en':
                'A high density micro retail lane providing extremely economical fashion options.',
          },
          category: AttractionCategory.market,
          emoji: '👟',
          rating: 4.0,
          openHours: '11:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Shopping', 'Bargains'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Imbaba', // General Imbaba info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/El_Gawmya_Market_Imbaba.jpg/1280px-El_Gawmya_Market_Imbaba.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'ring_road_l3',
      lineNumber: '3',
      stationName: {
        'ar': 'الطريق الدائري (خط 3)',
        'en': 'Ring Road (Line 3 Elevated Interchange)',
      },
      attractions: [
        TouristAttraction(
          id: 'ring_road_axis_brt',
          name: {
            'ar': 'محطة تقاطع الأتوبيس الترددي السريع (BRT)',
            'en': 'Ring Road Express BRT System Hub',
          },
          description: {
            'ar':
                'محطة علوية شاهقة مذهلة، تتقاطع مع أتوبيسات الدائري الترددية السريعة للوصول للتجمع الخامس أو المطار وأكتوبر بسرعة قاسية.',
            'en':
                'A modern high platform interchange node linking users straight to the Ring Road BRT system lines.',
          },
          category: AttractionCategory.transitHub,
          emoji: '🚌',
          rating: 4.4,
          openHours: '5:00 AM – 1:00 AM',
          isFree: true,
          admissionEGP: 'Free Terminal Access',
          walkingMinutes: '1',
          tags: ['Transit Axis', 'BRT Network', 'Speed Traveling'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Cairo_Ring_Road',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ring_Road_BRT_Station.jpg/1280px-Ring_Road_BRT_Station.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'rod_el_farag_corridor',
      lineNumber: '3',
      stationName: {
        'ar': 'محور روض الفرج (النهائية)',
        'en': 'Rod El-Farag Corridor Terminal',
      },
      attractions: [
        TouristAttraction(
          id: 'rod_farag_suspension_bridge',
          name: {
            'ar': 'محور ومحطة روض الفرج العملاقة (موسوعة جينيس)',
            'en': 'Rod El-Farag Suspension Bridge Axis',
          },
          description: {
            'ar':
                'المحطة النهائية للفرعة الشمالية، تقع بالقرب من المحور التكنولوجي وكوبري تحيا مصر الملجم صاحب الرقم القياسي العالمي في الاتساع.',
            'en':
                'The final terminal station of Line 3 branch, near the record breaking wide Tahya Misr suspension bridge.',
          },
          category: AttractionCategory.landmark,
          emoji: '🌉',
          rating: 4.7,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free Highway Access',
          walkingMinutes: '5',
          boardingHint: {
            'ar':
                'نهاية الخط الثالث اتجاه روض الفرج، تأكد من مغادرة القطار بالكامل مع متعلقاتك.',
            'en':
                'The ultimate terminal station. Kindly exit the train fully with all your bag mementos.',
          },
          tags: ['Terminal Node', 'Architecture Marvel', 'Suspension Axis'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Rod_El-Farag_Axis',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Rod_El-Farag_Axis_Bridge.jpg/1280px-Rod_El-Farag_Axis_Bridge.jpg',
          ],
        ),
      ],
    ),

    // ─── BRANCH B OF LINE 3 (TOWARDS CAIRO UNIVERSITY INTERCHANGE) ────────────
    StationAttractions(
      stationId: 'tawfikia',
      lineNumber: '3',
      stationName: {'ar': 'التوفيقية', 'en': 'Tawfikia'},
      attractions: [
        TouristAttraction(
          id: 'tawfikia_sports_club',
          name: {
            'ar': 'نادي التوفيقية للتنس والرياضة والتاريخ',
            'en': 'Tawfikia Tennis & Sporting Heritage Club',
          },
          description: {
            'ar':
                'أحد أقدم وأعرق أندية التنس والرياضة في المهندسين، يتميز بأجوائه الكلاسيكية الهادئة الفخمة.',
            'en':
                'One of المهندسين\'s oldest and most prestigious heritage tennis and social family clubs.',
          },
          category: AttractionCategory.sport,
          emoji: '🎾',
          rating: 4.5,
          openHours: '8:00 AM – 11:00 PM',
          isFree: false,
          admissionEGP: 'Guest Pass (30 EGP)',
          walkingMinutes: '4',
          tags: ['Sports History', 'Tennis Fields', 'Serene Space'],
          wikiUrl:
              'https://en.wikipedia.org/wiki/Mohandessin', // General Mohandessin info
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Tawfikia_Tennis_Club.jpg/1280px-Tawfikia_Tennis_Club.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'wadi_el_nil',
      lineNumber: '3',
      stationName: {'ar': 'وادي النيل', 'en': 'Wadi El-Nil'},
      attractions: [
        TouristAttraction(
          id: 'gamet_dowal_shopping_avenue',
          name: {
            'ar': 'شارع جامعة الدول العربية ومطاعمه',
            'en': 'Gamet El-Dowal Al-Arabeya Grand Boulevard',
          },
          description: {
            'ar':
                'أشهر وأعرض شوارع المهندسين، يمثل مركزاً ضخماً للتسوق، الفنادق، الكافيهات الراقية والمطاعم العربية والعالمية الحية والمستمرة بالعمل ليلاً.',
            'en':
                'The iconic primary commercial boulevard of Mohandessin, renowned for premium boutiques, upscale cafes, and non-stop dining operations.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🏙️',
          rating: 4.7,
          openHours: '24/7 Operations',
          isFree: true,
          admissionEGP: 'Free strolling track',
          walkingMinutes: '3',
          tags: [
            'Mohandessin Core',
            'Boulevard Shopping',
            'Luxurious Cafes',
            'Nightlife Kings',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'gamet_el_dowal',
      lineNumber: '3',
      stationName: {'ar': 'جامعة الدول العربية', 'en': 'Gamet El-Dowal'},
      attractions: [
        TouristAttraction(
          id: 'mohandessin_fashion_hubs',
          name: {
            'ar': 'شوارع البطل أحمد عبد العزيز وجزيرة العرب للموضة',
            'en': 'Gezirat El-Arab & El-Batal Premium Fashion Blocks',
          },
          description: {
            'ar':
                'المنطقة الأكثر فخامة بالمهندسين للتسوق، وتضم مئات التوكيلات التجارية والماركات الفاشن العالمية الراقية والمطاعم الكبرى.',
            'en':
                'The absolute peak fashion retail blocks in Mohandessin, housing international luxury brands and premier dining.',
          },
          category: AttractionCategory.market,
          emoji: '👜',
          rating: 4.8,
          openHours: '10:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free Access',
          walkingMinutes: '4',
          tags: ['Fashion Hub', 'Luxury Retail', 'Premium Mohandessin'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Mohandessin',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mohandessin_Fashion_Street.jpg/1280px-Mohandessin_Fashion_Street.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'bolak_el_dakrour',
      lineNumber: '3',
      stationName: {'ar': 'بولاق الدكرور', 'en': 'Bolak El-Dakrour'},
      attractions: [
        TouristAttraction(
          id: 'bolak_popular_wholesale_market',
          name: {
            'ar': 'أسواق بولاق الدكرور الشعبية المركزية',
            'en': 'Bolak El-Dakrour Central Local Markets',
          },
          description: {
            'ar':
                'سوق محلي عملاق وضخم لبيع الملابس، الأدوات المنزلية، والمستلزمات بأسعار رخيصة وشعبية واقتصادية جداً جداً.',
            'en':
                'A massive highly traditional local consumer marketplace providing highly cost saving retail options.',
          },
          category: AttractionCategory.market,
          emoji: '🛒',
          rating: 4.0,
          openHours: '9:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['Wholesale Shopping', 'Bargain Hunting', 'Traditional Vibe'],
          wikiUrl: 'https://en.wikipedia.org/wiki/Bulaq_el-Dakrur',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Bolak_El_Dakrour_Market.jpg/1280px-Bolak_El_Dakrour_Market.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'cairo_university_l3',
      lineNumber: '3',
      stationName: {
        'ar': 'جامعة القاهرة (خط 3 التبادلية النهائية)',
        'en': 'Cairo University (Line 3 Final Interchange)',
      },
      attractions: [
        TouristAttraction(
          id: 'l3_final_interchange_university',
          name: {
            'ar': 'حرم وبوابات جامعة القاهرة الغربية التراثية',
            'en': 'Cairo University Western Heritage Campus Gates',
          },
          description: {
            'ar':
                'المحطة النهائية الفائقة التطور للخط الثالث الفرعة الغربية، تتبادل مباشرة فوق الأرصفة العلوية مع الخط الثاني لتسهيل حركة الملايين يومياً.',
            'en':
                'The state of the art final destination terminal of Line 3 branch, integrating flawlessly via elevated structures with Metro Line 2.',
          },
          category: AttractionCategory.university,
          emoji: '🏫',
          rating: 4.8,
          openHours: '5:00 AM – 1:00 AM Terminal Operations',
          isFree: true,
          admissionEGP: 'Free Station Interchange Access',
          walkingMinutes: '1',
          boardingHint: {
            'ar':
                'المحطة النهائية التبادلية الكبرى، غير الخط هنا للوصول السريع للجيزة أو وسط البلد والدقي.',
            'en':
                'Grand final interchange terminal. Switch here onto Line 2 for rapid access to core Giza or Downtown.',
          },
          tags: [
            'Terminal Destination',
            'Interchange Architecture',
            'University Portal',
          ],
          wikiUrl: 'https://en.wikipedia.org/wiki/Cairo_University',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cairo_University_Metro_Station.jpg/1280px-Cairo_University_Metro_Station.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'new_capital_iconic_tower',
      lineNumber: 'LRT',
      stationName: {
        'ar': 'العاصمة الإدارية (البرج الأيقوني)',
        'en': 'NAC (Iconic Tower)',
      },
      attractions: [
        TouristAttraction(
          id: 'iconic_tower',
          name: {'ar': 'البرج الأيقوني', 'en': 'The Iconic Tower'},
          description: {
            'ar':
                'أطول برج في أفريقيا، يمثل رمزاً للعاصمة الإدارية الجديدة بتصميمه الفريد وارتفاعه الشاهق.',
            'en':
                'The tallest skyscraper in Africa, a symbol of the New Administrative Capital with its unique design and towering height.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏙️',
          rating: 4.9,
          openHours: '9:00 AM – 10:00 PM',
          isFree: false,
          admissionEGP: 'Variable',
          walkingMinutes: '5',
          tags: ['Landmark', 'Modern Architecture', 'Panoramic Views'],
          lat: 30.0210,
          lng: 31.7950,
          wikiUrl: 'https://en.wikipedia.org/wiki/Iconic_Tower',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Iconic_Tower_NAC.jpg/1280px-Iconic_Tower_NAC.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Iconic_Tower_construction.jpg/1280px-Iconic_Tower_construction.jpg',
          ],
        ),
        TouristAttraction(
          id: 'grand_mosque_of_egypt',
          name: {'ar': 'مسجد مصر الكبير', 'en': 'Grand Mosque of Egypt'},
          description: {
            'ar':
                'أحد أكبر المساجد في العالم، يتميز بتصميمه الإسلامي المعاصر ومساحته الشاسعة وقبابه ومآذنه الشاهقة.',
            'en':
                'One of the largest mosques globally, featuring contemporary Islamic design, vast area, and towering domes and minarets.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.9,
          openHours: '24/7',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '10',
          tags: ['Mosque', 'Islamic Architecture', 'Religious Site'],
          lat: 30.0250,
          lng: 31.8000,
          wikiUrl: 'https://en.wikipedia.org/wiki/Grand_Mosque_of_Egypt',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Grand_Mosque_NAC.jpg/1280px-Grand_Mosque_NAC.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Grand_Mosque_interior_NAC.jpg/1280px-Grand_Mosque_interior_NAC.jpg',
          ],
        ),
        TouristAttraction(
          id: 'cathedral_of_nativity',
          name: {
            'ar': 'كاتدرائية ميلاد المسيح',
            'en': 'Cathedral of the Nativity of Christ',
          },
          description: {
            'ar':
                'أكبر كاتدرائية قبطية أرثوذكسية في العالم، تحفة معمارية تجمع بين الأصالة والمعاصرة.',
            'en':
                'The largest Coptic Orthodox cathedral in the world, an architectural masterpiece blending authenticity and modernity.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.9,
          openHours: '9:00 AM – 5:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '12',
          tags: ['Church', 'Coptic', 'Religious Site', 'Architecture'],
          lat: 30.0200,
          lng: 31.8050,
          wikiUrl:
              'https://en.wikipedia.org/wiki/Cathedral_of_the_Nativity_of_Christ',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Cathedral_of_Nativity_NAC.jpg/1280px-Cathedral_of_Nativity_NAC.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Cathedral_interior_NAC.jpg/1280px-Cathedral_interior_NAC.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'new_capital_arts_culture_city',
      lineNumber: 'LRT',
      stationName: {
        'ar': 'العاصمة الإدارية (مدينة الفنون والثقافة)',
        'en': 'NAC (Arts & Culture City)',
      },
      attractions: [
        TouristAttraction(
          id: 'nac_opera_house',
          name: {
            'ar': 'دار الأوبرا بالعاصمة الإدارية',
            'en': 'NAC Opera House',
          },
          description: {
            'ar':
                'صرح ثقافي وفني ضخم، يستضيف عروض الأوبرا والباليه والحفلات الموسيقية العالمية.',
            'en':
                'A massive cultural and artistic landmark, hosting opera, ballet, and international music concerts.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🎭',
          rating: 4.8,
          openHours: 'Varies by event schedules',
          isFree: false,
          admissionEGP: 'Varies by ticket',
          walkingMinutes: '3',
          tags: ['Culture', 'Music', 'Theater', 'Arts'],
          lat: 30.0230,
          lng: 31.7980,
          wikiUrl:
              'https://en.wikipedia.org/wiki/New_Administrative_Capital#Arts_and_Culture_City',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/NAC_Opera_House.jpg/1280px-NAC_Opera_House.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/NAC_Opera_House_interior.jpg/1280px-NAC_Opera_House_interior.jpg',
          ],
        ),
        TouristAttraction(
          id: 'capital_museum',
          name: {'ar': 'متحف العاصمة', 'en': 'Capital Museum'},
          description: {
            'ar':
                'متحف حديث يعرض تاريخ مصر العريق من العصور القديمة وحتى العصر الحديث، باستخدام أحدث التقنيات التفاعلية.',
            'en':
                'A modern museum showcasing Egypt\'s rich history from ancient times to the modern era, utilizing interactive technologies.',
          },
          category: AttractionCategory.museum,
          emoji: '🏛️',
          rating: 4.7,
          openHours: '9:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '150 EGP',
          walkingMinutes: '5',
          tags: ['Museum', 'History', 'Interactive'],
          lat: 30.0240,
          lng: 31.7970,
          wikiUrl:
              'https://en.wikipedia.org/wiki/New_Administrative_Capital#Capital_Museum',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Capital_Museum_NAC.jpg/1280px-Capital_Museum_NAC.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Capital_Museum_exhibit.jpg/1280px-Capital_Museum_exhibit.jpg',
          ],
        ),
      ],
    ),
    StationAttractions(
      stationId: 'new_capital_government_district',
      lineNumber: 'LRT',
      stationName: {
        'ar': 'العاصمة الإدارية (الحي الحكومي)',
        'en': 'NAC (Government District)',
      },
      attractions: [
        TouristAttraction(
          id: 'parliament_building_nac',
          name: {'ar': 'مبنى البرلمان', 'en': 'Parliament Building'},
          description: {
            'ar':
                'المقر الجديد لمجلس النواب المصري، يتميز بتصميمه المعماري الفخم الذي يجمع بين الأصالة والحداثة.',
            'en':
                'The new seat of the Egyptian House of Representatives, featuring a luxurious architectural design that blends authenticity and modernity.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏛️',
          rating: 4.6,
          openHours: 'Visible from outside',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '7',
          tags: ['Government', 'Architecture', 'Landmark'],
          lat: 30.0180,
          lng: 31.7920,
          wikiUrl:
              'https://en.wikipedia.org/wiki/New_Administrative_Capital#Parliament_Building',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/NAC_Parliament.jpg/1280px-NAC_Parliament.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/NAC_Parliament_exterior.jpg/1280px-NAC_Parliament_exterior.jpg',
          ],
        ),
        TouristAttraction(
          id: 'cabinet_building_nac',
          name: {'ar': 'مبنى مجلس الوزراء', 'en': 'Cabinet Building'},
          description: {
            'ar':
                'المقر الجديد لمجلس الوزراء المصري، جزء من الحي الحكومي المصمم بأحدث المعايير العالمية.',
            'en':
                'The new headquarters of the Egyptian Cabinet, part of the Government District designed with the latest international standards.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏢',
          rating: 4.5,
          openHours: 'Visible from outside',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '8',
          tags: ['Government', 'Architecture', 'Modern City'],
          lat: 30.0190,
          lng: 31.7930,
          wikiUrl:
              'https://en.wikipedia.org/wiki/New_Administrative_Capital#Government_District',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/NAC_Cabinet.jpg/1280px-NAC_Cabinet.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/NAC_Government_District.jpg/1280px-NAC_Government_District.jpg',
          ],
        ),
        TouristAttraction(
          id: 'green_river_park_nac',
          name: {
            'ar': 'الحديقة المركزية (النهر الأخضر)',
            'en': 'Green River Park',
          },
          description: {
            'ar':
                'أكبر حديقة مركزية في العالم، تمتد على مساحة شاسعة وتوفر مساحات خضراء ومناطق ترفيهية متنوعة.',
            'en':
                'The largest central park in the world, spanning a vast area and offering green spaces and diverse recreational zones.',
          },
          category: AttractionCategory.park,
          emoji: '🌳',
          rating: 4.8,
          openHours: '6:00 AM – Midnight',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '15',
          tags: ['Park', 'Nature', 'Recreation', 'Family'],
          lat: 30.0300,
          lng: 31.7900,
          wikiUrl:
              'https://en.wikipedia.org/wiki/New_Administrative_Capital#Green_River',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Green_River_Park_NAC.jpg/1280px-Green_River_Park_NAC.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Green_River_landscape.jpg/1280px-Green_River_landscape.jpg',
          ],
        ),
      ],
    ),
  ];
}
