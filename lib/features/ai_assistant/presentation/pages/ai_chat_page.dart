import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rafiq_metrro/core/utils/gamification_service.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/utils/tourism_data.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/utils/ad_service.dart';

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
  final String? initialMessage;
  const AiChatPage({super.key, this.initialMessage});

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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isAdLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      // لو فيه رسالة جاية من الهوم، رفيق هيرد عليها فوراً أول ما يفتح
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    } else {
      // لو داخل عادي، هيطلعله رسالة الترحيب
      _messages.add(
        ChatMessage(
          text:
              'أهلاً بيك يا غالي! أنا "رفيق" صاحبك الذكي. 🤖\nاسألني في أي حاجة تيجي على بالك (مترو، كورة، طبخ، تاريخ، أو حتى فضفضة).. أنا معاك وسامعك!',
          isUser: false,
        ),
      );
    }
    _getUserCurrentLocation(); // Fetch initial location
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _initGemini() {
    String apiKey = GeminiAiService.apiKey;

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'إنت "رفيق"، عبقري الـ AI اللي ملوش حدود وصاحب جدع (ChatGPT Style). '
        '1. جاوب على أي سؤال في الكون (علوم، كورة، طبخ، برمجة، فضفضة) بذكاء خارق. '
        '2. اللغة: رد دايماً بنفس اللغة اللي المستخدم بيكلمك بيها (عربي، إنجليزي، فرنساوي.. إلخ). '
        '3. الروح المصرية: لو الكلام عربي، قلب "ابن بلد" واستخدم (يسطا، يا ريس، يا باشا، يا زميلي، عيوني ليك). '
        '4. المترو: إنت خبير فيه بس متحشرش المترو في الإجابة لو السؤال ملوش علاقة بيه. '
        'خلي ردودك ذكية، ممتعة، ومختصرة جداً.',
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
        debugPrint(
          "User location fetched: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}",
        );
      } else {
        _currentLocation = null; // Clear if permission denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permission denied. Cannot calculate distance.'.tr(),
              ),
            ),
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
        if (text.contains(a.name['ar']!) ||
            (a.name['en'] != null && text.contains(a.name['en']!))) {
          return {
            'attraction': a,
            'lat': a.lat,
            'lng': a.lng,
            'label': isAr ? a.name['ar'] : a.name['en'],
          };
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
          'label': isAr ? station.nameAr : station.nameEn,
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

    if (ConnectivityService.instance.isOffline) {
      final responseText = _generateLocalOfflineResponse(text, context.locale.languageCode == 'ar');
      
      final loc = _detectLocationInText(
        responseText,
        context.locale.languageCode == 'ar',
      );
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

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: responseText,
              isUser: false,
              featuredAttraction: detectedAttraction,
              lat: loc['lat'],
              lng: loc['lng'],
              mapLabel: detectedMapLabel,
              distanceToUser: distanceToTarget,
            ),
          );
        });
        _scrollToBottom();
        HapticFeedback.mediumImpact();
      }
      return;
    }

    try {
      // إرسال الرسالة مباشرة لـ Gemini لضمان ذكاء كامل (ChatGPT style)
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

      final loc = _detectLocationInText(
        responseText,
        context.locale.languageCode == 'ar',
      );
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
      debugPrint("Gemini Error: $e");
      if (mounted) {
        final isAr = context.locale.languageCode == 'ar';
        final localText = _generateLocalOfflineResponse(text, isAr);
        final responseText = isAr
            ? '⚠️ تم الرد محلياً لعدم استقرار اتصال الذكاء الاصطناعي:\n\n$localText'
            : '⚠️ Replied locally due to AI connection instability:\n\n$localText';

        final loc = _detectLocationInText(
          localText,
          isAr,
        );
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

        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: responseText,
              isUser: false,
              featuredAttraction: detectedAttraction,
              lat: loc['lat'],
              lng: loc['lng'],
              mapLabel: detectedMapLabel,
              distanceToUser: distanceToTarget,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }
  // Moved _buildMapButton outside _buildChatBubble to resolve the error
  String _generateLocalOfflineResponse(String text, bool isAr) {
    final q = text.toLowerCase().trim();
    if (isAr) {
      if (q.contains('تذكر') || q.contains('سعر') || q.contains('بكام') || q.contains('اسعار')) {
        return "💸 أسعار التذاكر الحالية يسطا:\n"
            "• حتى 9 محطات: 8 جنيه (التذكرة الصفراء)\n"
            "• من 10 إلى 16 محطة: 10 جنيه (التذكرة الخضراء)\n"
            "• من 17 إلى 23 محطة: 15 جنيه (التذكرة الحمراء)\n"
            "• أكثر من 23 محطة: 20 جنيه (التذكرة البنفسجية)\n\n"
            "💡 كبار السن فوق الـ 60 والـ 70 والطلاب ليهم اشتراكات وتذاكر مخفضة جداً في شباك التذاكر يا باشا!";
      }
      if (q.contains('خط') || q.contains('خطوط') || q.contains('محطة') || q.contains('محطات')) {
        return "🚇 خطوط المترو العاملة حالياً:\n"
            "• الخط الأول (حلوان - المرج الجديدة): 35 محطة، يربط أقصى الجنوب بأقصى الشمال الشرقي.\n"
            "• الخط الثاني (شبرا الخيمة - المنيب): 20 محطة، يربط شبرا بالجيزة وهو شريان رئيسي.\n"
            "• الخط الثالث (عدلي منصور - روض الفرج / جامعة القاهرة): خط ذكي مكيف ومصمم بأعلى المعايير العالمية.";
      }
      if (q.contains('خروج') || q.contains('فسح') || q.contains('مكان') || q.contains('اماكن') || q.contains('سياح') || q.contains('متحف')) {
        return "✨ اقتراحات لأماكن خروج مميزة جنب محطات المترو يسطا:\n"
            "• محطة الأوبرا: دار الأوبرا المصرية 🎭 وبرج القاهرة 🗼 وممشى أهل مصر\n"
            "• محطة السادات: المتحف المصري بالتحرير 🏛️ وميدان التحرير ووسط البلد\n"
            "• محطة مارجرجس: مجمع الأديان، الكنيسة المعلقة ⛪، جامع عمرو بن العاص، والمتحف القبطي\n"
            "• محطة باب الشعرية: شارع المعز، الحسين، وخان الخليلي 🕌 والجمالية";
      }
      if (q.contains('اروح ازاي') || q.contains('طريقة') || q.contains('أروح') || q.contains('اوصل')) {
        return "🗺️ عشان تخطط لرحلتك وتعرف هتركب إيه وتحول فين، ارجع لـ 'مخطط الرحلة' (Route Planner) في الصفحة الرئيسية للتطبيق. شغال أوفلاين 100% وهيجيبلك المسار والتكلفة والزمن بالتفصيل بدون نت!";
      }
      if (q.contains('نكت') || q.contains('نكته') || q.contains('ضحك') || q.contains('هزار')) {
        final jokes = [
          "مرة واحد صعيدي نزل محطة السادات لقى المترو زحمة موت، قالهم: وسعوا يا رجالة عشان نازل المحطة الجاية! 🚂",
          "مرة كمسري اتجوز كمسرية، كتبوا الكتاب في دفتر الغرامات والتحصيلات! 😂",
          "مرة واحد سأل كمسري المترو: هو القطر ده بيوقف في كل المحطات؟ الكمسري قاله: لا، بيوقف بس لما تفتح الباب وتنط! 🏃‍♂️",
          "واحد ركب المترو ولقى كل الناس نايمة، قالهم: جماعة حد يصحيني لما نوصل التحرير. صحي لقى نفسه في ورشة حلوان! 😴"
        ];
        return "😂 خد النكتة دي يا ريس:\n\n${jokes[math.Random().nextInt(jokes.length)]}";
      }
      return "📴 يا باشا، أنا شغال حالياً في 'وضع رفيق الأوفلاين' عشان مفيش إنترنت دلوقتي.\n"
          "أول ما الشبكة ترجع هكون معاك بكامل ذكائي وهرد على أي سؤال في الكوكب!\n\n"
          "💡 تقدر تسألني دلوقتي عن أسعار التذاكر، خطوط المترو، أماكن خروج، أو قولي 'احكيلي نكتة'!";
    } else {
      if (q.contains('ticket') || q.contains('price') || q.contains('cost') || q.contains('fare')) {
        return "💸 Current Cairo Metro Ticket Prices:\n"
            "• Up to 9 stations: 8 EGP (Yellow ticket)\n"
            "• 10 to 16 stations: 10 EGP (Green ticket)\n"
            "• 17 to 23 stations: 15 EGP (Red ticket)\n"
            "• More than 23 stations: 20 EGP (Purple ticket)\n\n"
            "💡 Discounts apply for seniors and students at any ticket office!";
      }
      if (q.contains('line') || q.contains('lines') || q.contains('station') || q.contains('stations')) {
        return "🚇 Current Cairo Metro Lines:\n"
            "• Line 1 (Helwan - El Marg): 35 stations connecting South and North-East Cairo.\n"
            "• Line 2 (Shubra El Kheima - El Mounib): 20 stations connecting Giza and Cairo.\n"
            "• Line 3 (Adly Mansour - Rod El Farag / Cairo University): Modern, air-conditioned smart line.";
      }
      if (q.contains('place') || q.contains('tourist') || q.contains('visit') || q.contains('museum') || q.contains('attraction')) {
        return "✨ Top sights near Metro Stations:\n"
            "• Opera Station: Cairo Opera House 🎭 & Cairo Tower 🗼\n"
            "• Sadat Station: The Egyptian Museum 🏛️ & Tahrir Square\n"
            "• Mar Girgis Station: The Hanging Church ⛪ & Coptic Museum\n"
            "• Bab El Shaariya Station: Al-Muizz Street & Khan El Khalili 🕌";
      }
      if (q.contains('go') || q.contains('route') || q.contains('navigate') || q.contains('how to')) {
        return "🗺️ To navigate and plan your metro trips offline, use the 'Route Planner' on the homepage. It works 100% offline and provides exact stations, transfers, duration, and ticket price!";
      }
      if (q.contains('joke') || q.contains('laugh')) {
        return "😂 Here is a metro joke for you:\n\n"
            "A passenger asked the conductor: 'Does this train stop at Sadat station?'\n"
            "The conductor replied: 'Only if you jump out of the window when we pass by!' 🏃‍♂️";
      }
      return "📴 I am currently running in 'Offline Mode' because there is no internet connection.\n"
          "Once you are online, I will be back with full Generative AI capabilities!\n\n"
          "💡 You can ask me now about ticket prices, metro lines, top tourist sights, or ask for a joke!";
    }
  }

  Widget _buildMapButton(
    double lat,
    double lng,
    bool isAr, {
    bool compact = false,
  }) {
    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: compact ? AppColors.primary : Colors.white,
          foregroundColor: compact ? Colors.white : AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          elevation: compact ? 0 : 2,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final url =
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
        },
        icon: Icon(
          Icons.map_outlined,
          size: 14,
          color: compact ? Colors.white : AppColors.primary,
        ),
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
          const OfflineBanner(),
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
          if (_bannerAd != null)
            SafeArea(
              top: false,
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
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
              isAr
                  ? 'تبعد عنك: ${distance.round()} متر'
                  : 'Distance: ${distance.round()} meters',
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.train_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.mapLabel ??
                          (isAr ? 'موقع المحطة' : 'Station Location'),
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
              _showError(
                isAr
                    ? "برجاء تفعيل إذن الميكروفون"
                    : "Please allow microphone access",
              );
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
          _showError(
            isAr
                ? "ميزة التحدث غير متاحة على هذا الجهاز"
                : "Speech recognition is not available",
          );
        }
      } on PlatformException catch (e) {
        _showError(
          isAr
              ? "عذراً، ميزة الصوت لا تعمل حالياً"
              : "Voice features are currently unavailable",
        );
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
