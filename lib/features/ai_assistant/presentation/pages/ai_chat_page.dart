import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/theme/app_colors.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser})
    : timestamp = DateTime.now();
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
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final List<ChatMessage> _messages = [];
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isTyping = false;

  late AnimationController _micPulseController;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initSpeech();
    _initTts();
    _initGemini();

    // رسالة ترحيبية أولية
    _messages.add(
      ChatMessage(
        text:
            'أهلاً بيك في رفيق الذكي! 🤖\nأنا هنا عشان أساعدك في أي حاجة تخص مترو القاهرة (مسارات، تذاكر، محطات زحمة). اسألني كتابة أو بالصوت!',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    _micPulseController.dispose();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("ar-EG");
    await _flutterTts.setSpeechRate(0.5); // سرعة النطق
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'أنت "رفيق"، المساعد الذكي لتطبيق مترو القاهرة. '
        'أجب بشكل ودود ومختصر ومفيد، تحدث باللهجة المصرية أحياناً. '
        'تجنب استخدام تنسيقات Markdown المعقدة لتسهيل قراءة النص صوتياً.',
      ),
    );
    _chatSession = _model.startChat(); // حفظ سياق الشات
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
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

  void _speak(String text) async {
    final isAr = context.locale.languageCode == 'ar';
    await _flutterTts.setLanguage(isAr ? "ar-EG" : "en-US");
    // إزالة الإيموجي والرموز عشان الصوت يطلع طبيعي
    final cleanText = text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF.,!?]'), '');
    await _flutterTts.speak(cleanText);
  }

  // دالة لفحص البيانات المحلية قبل سؤال الذكاء الاصطناعي
  String? _checkLocalKnowledge(String query) {
    final q = query.toLowerCase();

    if (q.contains('سعر') ||
        q.contains('تذكرة') ||
        q.contains('بكام') ||
        q.contains('أسعار') ||
        q.contains('تذاكر')) {
      return 'أسعار تذاكر المترو الحالية كالتالي:\n• منطقة واحدة (1-9 محطات): 8 جنيه\n• منطقتين (10-16 محطة): 10 جنيه\n• 3 مناطق (17-23 محطة): 15 جنيه\n• 4 مناطق (أكثر من 23 محطة): 20 جنيه.';
    } else if (q.contains('مواعيد') ||
        q.contains('بيفتح') ||
        q.contains('بيقفل') ||
        q.contains('الساعة كام')) {
      return 'مترو القاهرة بيشتغل يومياً من الساعة 5:15 صباحاً، وآخر قطار بيوصل المحطات النهائية حوالي الساعة 1:00 بعد منتصف الليل.';
    } else if (q.contains('اشتراك') ||
        q.contains('اشتراكات') ||
        q.contains('باقات')) {
      return 'الاشتراكات الشهرية بتوفرلك أكتر من 40% من فلوسك! 💳 تقدر تستخدم "حاسبة التكلفة" في التطبيق عشان تحسب أوفر باقة ليك.';
    }

    // استدعاء مستوى الازدحام اللحظي
    if (q.contains('زحمة') ||
        q.contains('مزدحم') ||
        q.contains('زحمه') ||
        q.contains('ضغط')) {
      final now = DateTime.now();
      int line = 1; // الافتراضي الخط الأول

      if (q.contains('تاني') || q.contains('ثاني') || q.contains('2')) {
        line = 2;
      } else if (q.contains('تالت') || q.contains('ثالث') || q.contains('3')) {
        line = 3;
      }

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

      return 'حالياً الخط $line $categoryAr وتقريباً نسبة الإشغال ${(level * 100).toInt()}% $emoji.';
    }

    return null; // نرجع null عشان نخلي Gemini يرد لو السؤال بره البيانات دي
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await _flutterTts
        .stop(); // لو اليوزر بعت رسالة جديدة أو اتكلم، وقف النطق الحالي

    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      // 1. فحص الإجابات المحلية أولاً (أسرع وأدق لمعلومات المترو الثابتة)
      final localResponse = _checkLocalKnowledge(text);
      if (localResponse != null) {
        await Future.delayed(
          const Duration(milliseconds: 600),
        ); // محاكاة التفكير لثواني عشان يبان طبيعي
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.insert(
              0,
              ChatMessage(text: localResponse, isUser: false),
            );
          });
          _scrollToBottom();
          HapticFeedback.mediumImpact();
          _speak(localResponse);
        }
        return; // بنوقف هنا ومش بنسأل Gemini خالص
      }

      // 2. إرسال الرسالة إلى Gemini إذا لم تكن من الثوابت المحلية
      final response = await _chatSession.sendMessage(Content.text(text));
      final responseText = response.text ?? 'عفواً، لم أتمكن من الرد.';

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(0, ChatMessage(text: responseText, isUser: false));
        });
        _scrollToBottom();
        HapticFeedback.mediumImpact();
        _speak(responseText); // نطق الرد
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

  void _toggleVoiceListening() async {
    HapticFeedback.mediumImpact();

    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (_speechEnabled) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
            // الإرسال التلقائي لما يخلص كلام
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              setState(() => _isListening = false);
              _sendMessage(result.recognizedWords);
            }
          },
          localeId: context.locale.languageCode == 'ar' ? 'ar_EG' : 'en_US',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى إعطاء صلاحية المايكروفون أولاً'.tr())),
        );
      }
    }
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isUser
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
          height: 1.4,
        ),
      ),
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
                    Icons.volume_up_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => _speak(message.text), // إعادة تشغيل النطق
                  tooltip: 'إعادة النطق'.tr(),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
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

  Widget _buildInputArea(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // زر المايكروفون (الاستماع)
            AnimatedBuilder(
              animation: _micPulseController,
              builder: (context, child) {
                return Container(
                  decoration: _isListening
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(
                                _micPulseController.value * 0.5,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        )
                      : null,
                  child: FloatingActionButton(
                    elevation: _isListening ? 8 : 0,
                    mini: true,
                    backgroundColor: _isListening
                        ? Colors.redAccent
                        : AppColors.primary.withOpacity(0.1),
                    foregroundColor: _isListening
                        ? Colors.white
                        : AppColors.primary,
                    onPressed: _toggleVoiceListening,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // حقل إدخال النص
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !_isListening,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: _isListening
                      ? "جاري الاستماع..."
                      : "Ask me anything...".tr(),
                  hintStyle: TextStyle(
                    color: _isListening ? Colors.redAccent : Colors.grey,
                  ),
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
}
