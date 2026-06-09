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

  @override
  void initState() {
    super.initState();
    _initGemini();

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
    super.dispose();
  }

  void _initGemini() {
    // بنجرب نجيب المفتاح من الـ Environment أولاً (أكثر أماناً)
    String apiKey = const String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.isEmpty) {
      try {
        apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
      } catch (e) {
        debugPrint(
          "Rafiq AI: Dotenv not initialized. Please ensure 'await dotenv.load()' is called in main.dart",
        );
      }
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest', // حل نهائي لمشكلة v1beta not found
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
      debugPrint("Gemini Error: $e"); // هيطبعلك السبب الحقيقي في الـ Console
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: 'عذراً يا غالي، رفيق مهنج شوية في الاتصال. اتأكد إن الـ API Key شغال وإن فيه إنترنت. 🚇',
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  // Moved _buildMapButton outside _buildChatBubble to resolve the error
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
