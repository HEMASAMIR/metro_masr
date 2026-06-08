import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rafiq_metrro/core/utils/gamification_service.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/utils/tourism_data.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/theme/app_colors.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final File? imageFile;
  final TouristAttraction? featuredAttraction;
  final double? lat;
  final double? lng;
  final String? mapLabel;
  final double? distanceToUser; // New field for distance

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageFile,
    this.featuredAttraction,
    this.lat,
    this.lng,
    this.mapLabel,
    this.distanceToUser,
  }) : timestamp = DateTime.now();
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Position? _currentLocation; // User's current location
  bool _isLocatingUser = false; // To prevent multiple location requests

  @override
  void initState() {
    super.initState();
    _initGemini();

    // رسالة ترحيبية أولية
    _messages.add(
      ChatMessage(
        text:
            'أهلاً بيك في رفيق الذكي! 🤖\nأنا هنا عشان أساعدك في أي حاجة تخص مترو القاهرة (مسارات، تذاكر، محطات زحمة). اسألني كتابة أو بالصوت!',
        isUser: false,
      ),
    );
    _getUserCurrentLocation(); // Fetch initial location
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initGemini() {
    // بنجرب نجيب المفتاح من الـ Environment أولاً (أكثر أماناً)
    String apiKey = const String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.isEmpty) {
      try {
        apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
      } catch (e) {
        debugPrint("Rafiq AI: Dotenv not initialized. Please ensure 'await dotenv.load()' is called in main.dart");
      }
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are "Rafiq", the world-class smart assistant for the Cairo Metro app. '
        'Always respond in the same language the user uses (Egyptian Slang, English, German/Deutsch, or French/Français). '
        'If the user speaks Egyptian Arabic, use friendly "Abn Balad" slang. '
        'Help users with: full routes (explaining transfers between lines), ticket prices, crowd levels, and full tourism itineraries. '
        'CRITICAL: Always mention the specific Metro Station Name for any landmark or destination mentioned. '
        'Feature "Image Search": Identify landmarks and tell the user the nearest Metro Station. '
        'Feature "Smart Boarding": Advise on which car to board based on the station exit. '
        'Always suggest a full "Trip Experience" (where to eat, visit, and chill) based on the time they have (e.g., 2 hours vs. full day). '
        'Keep formatting simple for text-to-speech clarity.',
      ),
    );
    _chatSession = _model.startChat(); // حفظ سياق الشات
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _getUserCurrentLocation() async {
    if (_isLocatingUser) return;
    setState(() {
      _isLocatingUser = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        debugPrint("User location fetched: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
      } else {
        _currentLocation = null; // Clear if permission denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission denied. Cannot calculate distance.'.tr())),
          );
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      _currentLocation = null;
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  // دالة لفحص البيانات المحلية قبل سؤال الذكاء الاصطناعي
  String? _checkLocalKnowledge(String query) {
    final q = query.toLowerCase();
    final lang = context.locale.languageCode;
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';

    // 1. الكشف عن المحطة المذكورة (سواء بالاسم أو عبر معلم سياحي فيها)
    StationAttractions? contextStation;
    for (var s in TourismDatabase.data) {
      if (q.contains(s.stationName['ar']!.replaceAll('محطة ', '').trim()) ||
          q.contains(s.stationName['en']!.toLowerCase().trim())) {
        contextStation = s;
      } else {
        for (var a in s.attractions) {
          if (q.contains(a.name['ar']!) || q.contains(a.name['en']!.toLowerCase())) {
            contextStation = s;
            break;
          }
        }
      }
      if (contextStation != null) break;
    }

    // 2. توليد تنبيه وقت الذروة إذا كانت المحطة مزدحمة حالياً
    String peakWarning = "";
    if (contextStation != null) {
      final lineNum = int.tryParse(contextStation.lineNumber) ?? 1;
      final level = CrowdPredictionService.getCrowdLevel(hour: DateTime.now().hour, weekday: DateTime.now().weekday, lineNumber: lineNum);
      if (CrowdPredictionService.getCrowdCategory(level) == CrowdLevel.high) {
        peakWarning = isAr 
            ? '⚠️ خلي بالك: محطة ${contextStation.stationName['ar']} دلوقتي في وقت ذروة وزحمة جداً.\n' 
            : '⚠️ Note: ${contextStation.stationName['en']} station is currently in peak hour (very crowded).\n';
      }
    }

    // 3. منطق "محطات بديلة أقل ازدحاماً"
    if (q.contains('بديل') ||
        q.contains('طريق تاني') ||
        q.contains('محطة تانية') ||
        q.contains('alternative') ||
        q.contains('another way')) {
      
      // خريطة المحطات القريبة من بعضها (Alternative Pairs)
      final Map<String, List<String>> alternatives = {
        'sadat': ['nasser', 'saad_zaghloul', 'opera', 'mohammad_naguib'],
        'nasser': ['sadat', 'orabi', 'maspero', 'ataba'],
        'dokki': ['bohooth', 'opera'],
        'bohooth': ['dokki', 'giza_university'],
        'opera': ['sadat', 'dokki', 'safaa_hegazi'],
        'shuhada': ['orabi', 'ataba', 'ghamra'],
        'ataba': ['bab_el_shaariya_l3', 'nasser', 'shuhada'],
        'giza': ['omm_el_misryeen', 'giza_university'],
        'mar_girgis': ['el_zahraa', 'el_malek_el_saleh'],
      };

      if (contextStation != null && alternatives.containsKey(contextStation.stationId)) {
        final now = DateTime.now();
        final currentLine = int.tryParse(contextStation.lineNumber) ?? 1;
        final currentLevel = CrowdPredictionService.getCrowdLevel(hour: now.hour, weekday: now.weekday, lineNumber: currentLine);
        
        String? betterStation;
        double bestLevel = currentLevel;

        for (var altId in alternatives[contextStation.stationId]!) {
          final altData = TourismDatabase.findByStation(altId);
          if (altData != null) {
            final altLine = int.tryParse(altData.lineNumber) ?? 1;
            final altLevel = CrowdPredictionService.getCrowdLevel(hour: now.hour, weekday: now.weekday, lineNumber: altLine);
            
            if (altLevel < bestLevel - 0.15) { // لازم تكون أروق بنسبة ملحوظة
              bestLevel = altLevel;
              betterStation = altData.stationName[isAr ? 'ar' : 'en'];
            }
          }
        }

        if (betterStation != null) {
          return isAr 
              ? 'لو محطة ${contextStation.stationName['ar']} زحمة، أنصحك تنزل في (محطة $betterStation). هي قريبة منها والتوقعات بتقول إنها أروق دلوقتي بكتير! 🚶‍♂️🚇'
              : 'If ${contextStation.stationName['en']} is too busy, I recommend using ($betterStation Station). It\'s nearby and much less crowded right now! 🚶‍♂️🚇';
        }
      }
      return isAr ? 'حالياً دي أفضل محطة للوصول لوجهتك، مفيش بدايل أروق بفرق كبير في المنطقة دي.' : 'Currently, this is the best station for your destination. No significantly clearer alternatives nearby.';
    }

    // منطق الاستعلام عن الإنجازات والاكتشافات
    if (q.contains('اكتشفت') ||
        q.contains('إنجازاتي') ||
        q.contains('نقاطي') ||
        q.contains('كسبت كام')) {
      final count = GamificationService.discoveredPlacesCount;
      if (count == 0) {
        if (isAr) return 'لسه يا بطل مجربتش تكتشف أماكن! اركب المترو ورفيق هينبهك أول ما تقرب من محطة فيها مكان جامد.';
        if (isFr) return 'Vous n\'avez pas encore découvert de lieux ! Prenez le métro et Rafiq vous alertera près des stations intéressantes.';
        return 'You haven\'t discovered places yet! Ride the metro and I\'ll alert you near interesting stations.';
      }
      if (isAr) return 'عاش يا وحش! إنت اكتشفت $count مكان سياحي. كمل لف في المحطات عشان تلم شارات وتطلع في لوحة الشرف! 🏆';
      if (isFr) return 'Bravo ! Vous avez découvert $count lieux via le métro. Continuez à explorer les stations ! 🏆';
      return 'Great job! You discovered $count places via Metro. Keep exploring stations! 🏆';
    }

    // منطق "اركب فين" (Smart Boarding Guide)
    if (q.contains('اركب فين') ||
        q.contains('أركب فين') ||
        q.contains('أنهي عربية') ||
        q.contains('انهي عربيه') || q.contains('boarding')) {
      TouristAttraction? target;
      String? sName;
      for (var s in TourismDatabase.data) {
        for (var a in s.attractions) {
          if (q.contains(a.name['ar']!) || q.contains(a.name['en']!.toLowerCase())) {
            target = a;
            sName = s.stationName['ar'];
            break;
          }
        }
      }

      if (target != null && target.boardingHint != null) {
        if (isAr) return 'بص يا بطل، عشان تروح ${target.name['ar']} (محطة $sName) وتوصل بسرعة:\n💡 ${target.boardingHint!['ar']}';
        return isFr ? 'Pour aller à ${target.name['fr'] ?? target.name['en']} (Station $sName), montez dans le wagon indiqué pour gagner du temps.' : 'To get to ${target.name['en']} ($sName Station) quickly, follow the boarding hint.';
      } else if (target != null) {
        if (isAr) return 'عشان تروح ${target.name['ar']} (محطة $sName)، يفضل دايماً تركب في "نص القطر" عشان تكون قريب من المخرج.';
        return isFr ? 'Pour aller à ${target.name['fr'] ?? target.name['en']} ($sName), il est recommandé de monter au milieu du train.' : 'To go to ${target.name['en']} ($sName), we recommend boarding in the middle car.';
      }
      if (isAr) return 'قولي عايز تروح فين وأنا هقولك اسم المحطة وتركب في أنهي عربية بالظبط! 🚇';
      return isFr ? 'Dites-moi où vous voulez aller et je vous dirai le nom de la station et le bon wagon ! 🚇' : 'Tell me where you want to go, and I\'ll give you the station and the right car! 🚇';
    }

    // منطق "الرحلات الكاملة" والاقتراحات بناء على الوقت (كلام بلدي)
    if (q.contains('أتفسح') ||
        q.contains('اتفسح') ||
        q.contains('خروجة') ||
        q.contains('فسحة')) {
      if (q.contains('ساعتين') || q.contains('وقت قليل')) {
        return 'لو قدامك ساعتين بس، أنصحك تنزل (محطة الأوبرا). ممكن تتمشى على الكورنيش وتدخل دار الأوبرا، خروجة خفيفة ومش هتاخد وقت!';
      }
      if (q.contains('يوم') || q.contains('طويلة') || q.contains('فسحني')) {
        return 'بما إن معاك يوم كامل، خد عندك البرنامج ده:\n1. الصبح: ابدأ بـ (محطة السادات) وافطر في "فلفلة"، وبعدها ادخل المتحف المصري.\n'
            '2. الضهر: اركب المترو وانزل (محطة العتبة) وروح خان الخليلي.\n'
            '3. بليل: اختم يومك في "المعادي" (شارع 9) اختار أي مطعم عالمي هناك واتعشى وسط الهدوء.\nإيه رأيك؟';
      }
    }

    // كلمات البحث البلدي عن الكافيهات والنوادي
    if (q.contains('قهوة') ||
        q.contains('كافيه') ||
        q.contains('نادي') ||
        q.contains('جيم') ||
        q.contains('كورة')) {
      if (contextStation != null) {
        final results = contextStation.attractions
            .where(
              (a) =>
                  a.category == AttractionCategory.cafe ||
                  a.category == AttractionCategory.sport ||
                  a.category == AttractionCategory.restaurant,
            )
            .toList();

        if (results.isNotEmpty) {
          String res =
              '$peakWarningفي منطقة ${contextStation.stationName['ar']}، النوادي والكافيهات اللي حواليك اهي:\n';
          for (var item in results) {
            res +=
                '• ${item.name['ar']} ${item.emoji} - ${item.description['ar']?.split('.')[0]}.\n';
          }
          return res;
        }
      }
    }

    // منطق "أفضل وقت للزيارة" بناءً على توقعات الازدحام
    if (q.contains('أحسن وقت') ||
        q.contains('أفضل وقت') ||
        q.contains('امتى اروح') ||
        q.contains('best time') ||
        q.contains('when to visit')) {
      TouristAttraction? targetAttraction;

      if (contextStation != null) {
        for (var a in contextStation.attractions) {
          if (q.contains(a.name['ar']!) || q.contains(a.name['en']!.toLowerCase())) {
            targetAttraction = a;
            break;
          }
        }

        final lineNum = int.tryParse(contextStation.lineNumber) ?? 1;
        final now = DateTime.now();
        final bestHours = CrowdPredictionService.getBestTravelHours(
          lineNumber: lineNum,
          weekday: now.weekday,
        );

        final hoursStr = bestHours.map((h) => h > 12 ? '${h - 12} م' : (h == 0 ? '12 ص' : '$h ص')).join('، ');
        final hoursStrEn = bestHours.map((h) => h > 12 ? '${h - 12} PM' : (h == 0 ? '12 AM' : '$h AM')).join(', ');

        if (isAr) {
          return '$peakWarningعشان تروح ${targetAttraction?.name['ar'] ?? contextStation.stationName['ar']} والمترو يكون رايق، أحسن ساعات النهاردة هي: $hoursStr. دي أقل أوقات زحمة على الخط $lineNum! 🚇✨';
        }
        return '${peakWarning}To visit ${targetAttraction?.name['en'] ?? contextStation.stationName['en']} with minimum crowd, I recommend these hours: $hoursStrEn. These are the quietest times on Line $lineNum today! 🚇✨';
      }
    }

    if (q.contains('سعر') ||
        q.contains('تذكرة') || q.contains('price') || q.contains('billet') ||
        q.contains('tarif')) {
      if (isAr) return 'أسعار تذاكر المترو الجديدة 2026 كالتالي:\n• منطقة واحدة: 10 جنيه\n• منطقتين: 13 جنيه\n• 3 مناطق: 17 جنيه\n• 4 مناطق: 20 جنيه.';
      if (isFr) return 'Les tarifs 2026 sont :\n• 1 zone (1-9 stations) : 10 EGP\n• 2 zones : 13 EGP\n• 3 zones : 17 EGP\n• 4 zones : 20 EGP.';
      return '2026 Metro Fares:\n• 1 Zone (1-9 stations): 10 EGP\n• 2 Zones: 13 EGP\n• 3 Zones: 17 EGP\n• 4 Zones: 20 EGP.';
    } else if (q.contains('timing') || q.contains('horaire') || q.contains('مواعيد')) {
        if (isAr) return 'مترو القاهرة بيشتغل يومياً من الساعة 5:15 صباحاً، وآخر قطار بيوصل المحطات النهائية حوالي الساعة 1:00 بعد منتصف الليل.';
        if (isFr) return 'Le métro du Caire fonctionne tous les jours de 5h15 à environ 1h00 du matin.';
        return 'Cairo Metro operates daily from 5:15 AM until approximately 1:00 AM.';
    } else if (q.contains('أوفر') || q.contains('save') || q.contains('économie')) {
       if (isAr) return 'الاشتراك الشهري بيوفرلك أكتر من 40%! مثلاً باقة الـ 9 محطات بـ 230ج بدل 440ج.';
       if (isFr) return 'L\'abonnement mensuel permet d\'économiser plus de 40 % ! Par exemple, le forfait 1 zone est à 230 EGP au lieu de 440 EGP.';
       return 'A monthly subscription saves over 40%! For example, a 1-zone pass is 230 EGP instead of 440 EGP.';
    }

    if (q.contains('سعر') ||
        q.contains('تذكرة')) {
      return 'أسعار تذاكر المترو الجديدة 2026 كالتالي:\n• منطقة واحدة (1-9 محطات): 10 جنيه\n• منطقتين (10-16 محطة): 13 جنيه\n• 3 مناطق (17-23 محطة): 17 جنيه\n• 4 مناطق (أكثر من 23 محطة): 20 جنيه.';
    } else if (q.contains('مواعيد') ||
        q.contains('بيفتح') ||
        q.contains('بيقفل') ||
        q.contains('الساعة كام')) {
      return 'مترو القاهرة بيشتغل يومياً من الساعة 5:15 صباحاً، وآخر قطار بيوصل المحطات النهائية حوالي الساعة 1:00 بعد منتصف الليل.';
    } else if (q.contains('اشتراك') ||
        q.contains('اشتراكات') ||
        q.contains('باقات')) {
      return 'الاشتراكات الشهرية الجديدة (60 رحلة) بتوفرلك كتير:\n'
          '• منطقة واحدة (9 محطات): 230 جنيه\n'
          '• منطقتين (16 محطة): 290 جنيه\n'
          '• 3-4 مناطق: 340 جنيه\n'
          '• شامل كل المحطات: 450 جنيه\n'
          '💡 الاشتراك بيوفرلك أكتر من 40% مقارنة بالتذاكر العادية!';
    } else if (q.contains('توفير') ||
        q.contains('أوفر') ||
        q.contains('حسبة')) {
      return 'بص يا سيدي، لو بتركب المترو كل يوم (يعني حوالي 44 رحلة في الشهر):\n'
          '• الـ 9 محطات: تذاكر (440ج) vs اشتراك (230ج) ⮕ هتوفر 210ج ✅\n'
          '• الـ 16 محطة: تذاكر (572ج) vs اشتراك (290ج) ⮕ هتوفر 282ج ✅\n'
          '• الـ 23 محطة: تذاكر (748ج) vs اشتراك (340ج) ⮕ هتوفر 408ج ✅\n\n'
          '⚠️ تنبيه مهم: استهلاكك الشهري حالياً "يتخطى" سعر الاشتراك بكتير! الأفضل تطلع كارت اشتراك شهري وتوفر فلوسك.';
    }

    // استدعاء مستوى الازدحام اللحظي
    if (q.contains('زحمة') ||
        q.contains('مزدحم') ||
        q.contains('زحمه') ||
        q.contains('ضغط')) {
      final now = DateTime.now();
      int line = contextStation != null 
          ? (int.tryParse(contextStation.lineNumber) ?? 1)
          : (q.contains('تاني') || q.contains('ثاني') || q.contains('2') ? 2 
             : (q.contains('تالت') || q.contains('ثالث') || q.contains('3') ? 3 : 1));

      final level = CrowdPredictionService.getCrowdLevel(
        hour: now.hour,
        weekday: now.weekday,
        lineNumber: line,
      );
      final category = CrowdPredictionService.getCrowdCategory(level);
      final emoji = CrowdPredictionService.getCrowdEmoji(category);
      final categoryAr = category == CrowdLevel.high
          ? 'زحمة جداً ومكدس ⚠️'
          : category == CrowdLevel.moderate
          ? 'متوسط الزحمة 😐'
          : 'هادي ومريح ✅';
      
      final stationPrefix = contextStation != null 
          ? (isAr ? 'في محطة ${contextStation.stationName['ar']}: ' : 'At ${contextStation.stationName['en']}: ')
          : (isAr ? 'حالياً الخط $line: ' : 'On Line $line: ');

      return '$stationPrefix$categoryAr وتقريباً نسبة الإشغال ${(level * 100).toInt()}% $emoji.';
    }

    // أماكن الترفيه والفسح بناءً على المحطة (كلام بلدي)
    if (q.contains('ترفيه') ||
        q.contains('فسحة') ||
        q.contains('خروجة') ||
        q.contains('أماكن') ||
        q.contains('خروجه') ||
        q.contains('نادي') ||
        q.contains('رياضة') ||
        q.contains('سينما') ||
        q.contains('ترفيهية') ||
        q.contains('places') ||
        q.contains('entertainment')) {
      if (contextStation != null) {
        final entertainment = contextStation.attractions
            .where(
              (a) =>
                  a.category == AttractionCategory.entertainment ||
                  a.category == AttractionCategory.park ||
                  a.category == AttractionCategory.market ||
                  a.category == AttractionCategory.museum ||
                  a.category == AttractionCategory.sport,
            )
            .toList();

        if (entertainment.isNotEmpty) {
          String response =
              '$peakWarningبص يا سيدي، قريب من محطة ${contextStation.stationName['ar']} فيه أماكن خروجات تجنن:\n';
          for (var item in entertainment) {
            response +=
                '• ${item.name['ar']} ${item.emoji} (${item.walkingMinutes} دقايق مشي) - ${item.description['ar']?.split('.')[0]}.\n';
          }
          return response;
        }
      }
      return 'لو قولتلي إنت في محطة إيه، هقولك أحلى أماكن الترفيه والفسح اللي قريبة منك! 🎡🌳';
    }

    // البحث عن المطاعم والكافيهات (كلام بلدي)
    if (q.contains('مطعم') ||
        q.contains('أكل') ||
        q.contains('اكل') ||
        q.contains('كافيه') ||
        q.contains('قهوة') ||
        q.contains('جوعان') ||
        q.contains('food') ||
        q.contains('restaurant') ||
        q.contains('cafe')) {
      if (contextStation != null) {
        final foodPlaces = contextStation.attractions
            .where(
              (a) =>
                  a.category.toString().contains('restaurant') ||
                  a.category.toString().contains('cafe'),
            )
            .toList();

        if (foodPlaces.isNotEmpty) {
          String response =
              '$peakWarningلو بتدور على أكلة حلوة أو قعدة قهوة قريبة من محطة ${contextStation.stationName['ar']}، أرشحلك دول:\n';
          for (var item in foodPlaces) {
            response +=
                '• ${item.name['ar']} ${item.emoji} (${item.walkingMinutes} دقايق مشي) - ${item.description['ar']?.split('.')[0]}.\n';
          }
          return response;
        }
      }
      return 'قولي إنت في محطة إيه وهقولك أحلى المطاعم والكافيهات اللي حواليك! 🍔☕';
    }

    // تنبيه عام لو المحطة المذكورة في ذروة حالياً والأسئلة تانية عامة
    if (contextStation != null && peakWarning.isNotEmpty && q.length < 20) {
      return peakWarning + (isAr 
          ? 'المحطة دلوقتي زحمة جداً، لو مش مستعجل يفضل تأجل مشوارك شوية.' 
          : 'The station is currently very crowded. If you\'re not in a hurry, it\'s better to delay your trip.');
    }

    return null; // نرجع null عشان نخلي Gemini يرد لو السؤال بره البيانات دي
  }

  void _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _sendMessage(
        context.locale.languageCode == 'ar'
            ? 'أنا بعتلك صورة، تعرف عليها؟'
            : 'Recognize this landmark?',
      );
    }
  }

  /// دالة لاكتشاف المواقع (محطات أو معالم) داخل النص وإرجاع إحداثياتها
  Map<String, dynamic> _detectLocationInText(String text, bool isAr) {
    // 1. البحث في المعالم السياحية أولاً
    for (var s in TourismDatabase.data) {
      for (var a in s.attractions) {
        if (text.contains(a.name['ar']!) || (a.name['en'] != null && text.contains(a.name['en']!))) {
          return {'attraction': a, 'lat': a.lat, 'lng': a.lng, 'label': isAr ? a.name['ar'] : a.name['en']};
        }
      }
    }

    // 2. البحث في المحطات إذا لم نجد معلماً
    for (var station in MetroData.stations.values) {
      if (text.contains(station.nameAr) || text.contains(station.nameEn)) {
        return {
          'attraction': null,
          'lat': station.latitude,
          'lng': station.longitude,
          // Use the correct language for station name
          'label': isAr ? station.nameAr : station.nameEn
        };
      }
    }
    return {};
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty && _selectedImage == null) return;

    final imageToSend = _selectedImage;

    setState(() {
      _messages.insert(
        0,
        ChatMessage(text: text, isUser: true, imageFile: imageToSend),
      );
      _isTyping = true;
      _selectedImage = null; // إعادة تعيين بعد الإرسال
    });
    _textController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    // Ensure we have current location before processing, if not already fetching
    if (_currentLocation == null && !_isLocatingUser) {
      await _getUserCurrentLocation();
    }

    double? distanceToTarget;
    TouristAttraction? detectedAttraction;
    String? detectedMapLabel;

    try {
      // 1. فحص الإجابات المحلية أولاً (أسرع وأدق لمعلومات المترو الثابتة)
      final localResponse = _checkLocalKnowledge(text);
      if (localResponse != null) {
        await Future.delayed(
          const Duration(milliseconds: 600),
        ); // محاكاة التفكير لثواني عشان يبان طبيعي

        final loc = _detectLocationInText(localResponse, context.locale.languageCode == 'ar');
        if (loc.isNotEmpty && _currentLocation != null) {
          distanceToTarget = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            loc['lat'],
            loc['lng'],
          );
          detectedAttraction = loc['attraction'];
          detectedMapLabel = loc['label'];
        }
        
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.insert(
              0,
              ChatMessage(
                text: localResponse,
                isUser: false,
                featuredAttraction: detectedAttraction,
                lat: loc['lat'], // Keep original lat/lng for map button
                lng: loc['lng'],
                mapLabel: detectedMapLabel,
                distanceToUser: distanceToTarget,
              ),
            );
          });
          _scrollToBottom();
          HapticFeedback.mediumImpact();
        }
        return; // بنوقف هنا ومش بنسأل Gemini خالص
      }

      // 2. إرسال الرسالة إلى Gemini إذا لم تكن من الثوابت المحلية
      GenerateContentResponse response;
      if (imageToSend != null) {
        // البحث بالصور (Gemini Vision)
        final imageBytes = await imageToSend.readAsBytes();
        final prompt = [
          Content.multi([TextPart(text), DataPart('image/jpeg', imageBytes)]),
        ];
        response = await _model.generateContent(prompt);
      } else {
        response = await _chatSession.sendMessage(Content.text(text));
      }

      final responseText =
          response.text ?? 'عفواً، رفيق مش عارف يرد دلوقتي. 🚇';

      final loc = _detectLocationInText(responseText, context.locale.languageCode == 'ar');
      if (loc.isNotEmpty && _currentLocation != null) {
        distanceToTarget = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          loc['lat'],
          loc['lng'],
        );
        detectedAttraction = loc['attraction'];
        detectedMapLabel = loc['label'];
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: responseText,
              isUser: false,
              featuredAttraction: detectedAttraction,
              lat: loc['lat'], // Keep original lat/lng for map button
              lng: loc['lng'],
              mapLabel: detectedMapLabel,
              distanceToUser: distanceToTarget,
            ),
          );
        });
        _scrollToBottom();
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: 'عذراً، حدث خطأ في الاتصال بالخوادم. 🚇',
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  // Moved _buildMapButton outside _buildChatBubble to resolve the error
  Widget _buildMapButton(double lat, double lng, bool isAr, {bool compact = false}) {
    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: compact ? AppColors.primary : Colors.white,
          foregroundColor: compact ? Colors.white : AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          elevation: compact ? 0 : 2,
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
        icon: Icon(Icons.map_outlined, size: 14, color: compact ? Colors.white : AppColors.primary),
        label: Text(isAr ? 'فتح الخريطة' : 'Open Maps'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ai_assistant".tr(),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Always online".tr(),
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // منطقة عرض الرسائل
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == 0) {
                  return _buildTypingIndicator();
                }

                final msgIndex = _isTyping ? index - 1 : index;
                final msg = _messages[msgIndex];

                return FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: _buildChatBubble(msg, isAr),
                );
              },
            ),
          ),

          // شريط إدخال النص والصوت
          _buildInputArea(isAr),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isAr) {
    final isUser = message.isUser;
    final radius = const Radius.circular(20);

    final featuredAttraction = message.featuredAttraction;
    final hasCoordinates = message.lat != null && message.lng != null;
    final mapLat = message.lat;
    final mapLng = message.lng;
    final distance = message.distanceToUser;

    final bubbleContent = Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (message.imageFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              message.imageFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        if (distance != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              isAr ? 'تبعد عنك: ${distance.round()} متر' : 'Distance: ${distance.round()} meters',
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
        ),
        if (hasCoordinates) ...[
          const SizedBox(height: 12),
          if (featuredAttraction != null)
            // شكل كارت المعلم السياحي (صورة + زرار)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.network(
                    featuredAttraction.effectiveImageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  _buildMapButton(mapLat!, mapLng!, isAr),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        featuredAttraction.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // شكل كارت المحطة البسيط (أيقونة + زرار)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.train_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.mapLabel ?? (isAr ? 'موقع المحطة' : 'Station Location'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _buildMapButton(mapLat!, mapLng!, isAr, compact: true),
                ],
              ),
            ),
        ],
      ],
    );

    // فصلنا شكل الفقاعة في متغير عشان نقدر نضيف جنبها الزرار لو كانت من البوت
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth:
            MediaQuery.of(context).size.width *
            0.70, // قللنا العرض شوية عشان الزرار
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: (isUser && isAr) || (!isUser && !isAr)
              ? radius
              : Radius.zero,
          bottomRight: (isUser && !isAr) || (!isUser && isAr)
              ? radius
              : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: bubbleContent,
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    // لو رسالة من البوت، نحط جنبها زرار الإعادة في Row
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bubble,
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✅ Copied!".tr()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy Message'.tr(),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '🤖 يكتب الآن...',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  void _listen(bool isAr) async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (mounted) setState(() => _isListening = val == 'listening');
          },
          onError: (val) {
            if (mounted) setState(() => _isListening = false);
            if (val.errorMsg == 'error_permission') {
              _showError(isAr ? "برجاء تفعيل إذن الميكروفون" : "Please allow microphone access");
            }
          },
        );

        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) => setState(() {
              _textController.text = val.recognizedWords;
            }),
            localeId: isAr ? 'ar-EG' : 'en-US',
          );
        } else {
          _showError(isAr ? "ميزة التحدث غير متاحة على هذا الجهاز" : "Speech recognition is not available");
        }
      } on PlatformException catch (e) {
        _showError(isAr ? "عذراً، ميزة الصوت لا تعمل حالياً" : "Voice features are currently unavailable");
        debugPrint("Speech Error: ${e.code}");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _sendMessage(_textController.text);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildInputArea(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // زر الكاميرا للبحث بالصور
            IconButton(
              icon: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              onPressed: () {
                _showImagePickerOptions();
              },
            ),

            // زر الميكروفون (بالحل الجديد)
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? Colors.red : AppColors.primary,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _listen(isAr);
              },
            ),

            // حقل إدخال النص
            Expanded(
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: "Ask me anything...".tr(),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),

            // زر الإرسال
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _sendMessage(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text('gallery'.tr()),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: Text('camera'.tr()),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
