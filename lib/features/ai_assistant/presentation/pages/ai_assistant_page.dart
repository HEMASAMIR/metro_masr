import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/offline_storage.dart';
import '../../../metro/presentation/pages/route_planner_page.dart';
import '../../../metro/presentation/pages/nearby_stations_page.dart';
import '../../../metro/presentation/pages/map_page.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingController;

  static const List<String> _quickQuestions = [
    'أرخص تذكرة',
    'أقرب محطة',
    'مواعيد المترو',
    'رصيد كارتي',
    'أكتر خط مزدحم',
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage(
        context.locale.languageCode == 'ar'
            ? 'مرحباً! أنا رفيق، مساعدك الذكي لمترو القاهرة 🚇\nاسألني عن المحطات، الأسعار، البدائل أو أي حاجة عاوزها!'
            : 'Hello! I\'m Rafiq, your smart Cairo Metro assistant 🚇\nAsk me about stations, fares, routes or anything you need!',
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {List<_QuickAction>? actions}) {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: false,
        time: DateTime.now(),
        actions: actions,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    final isAr = context.locale.languageCode == 'ar';

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    final response = _generateResponse(text.toLowerCase(), isAr);
    setState(() => _isTyping = false);
    _addBotMessage(response.text, actions: response.actions);
  }

  _BotResponse _generateResponse(String input, bool isAr) {
    // ── Fare / price
    if (_contains(input, ['سعر', 'تذكرة', 'price', 'fare', 'ticket', 'كلفة', 'تكلفة', 'جنيه'])) {
      return _BotResponse(
        text: isAr
            ? '🎫 أسعار تذاكر مترو القاهرة 2024:\n\n'
                '• حتى 9 محطات → 8 جنيه\n'
                '• 10–16 محطة → 10 جنيه\n'
                '• 17–23 محطة → 15 جنيه\n'
                '• أكتر من 23 محطة → 20 جنيه\n\n'
                '💡 نصيحة: الاشتراك الشهري يوفر عليك ما يصل إلى 40%!'
            : '🎫 Cairo Metro 2024 Fares:\n\n'
                '• Up to 9 stations → 8 EGP\n'
                '• 10–16 stations → 10 EGP\n'
                '• 17–23 stations → 15 EGP\n'
                '• 23+ stations → 20 EGP\n\n'
                '💡 Tip: Monthly subscription saves you up to 40%!',
        actions: [
          _QuickAction(
            label: isAr ? 'احسب تذكرتي' : 'Calculate Mine',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
            ),
          ),
        ],
      );
    }

    // ── Stations count
    if (_contains(input, ['كم محطة', 'عدد المحطات', 'how many station', 'stations count'])) {
      final total = MetroData.stations.length;
      final l1 = MetroData.stations.values.where((s) => s.line == 1).length;
      final l2 = MetroData.stations.values.where((s) => s.line == 2).length;
      final l3 = MetroData.stations.values.where((s) => s.line == 3).length;
      return _BotResponse(
        text: isAr
            ? '🚉 شبكة مترو القاهرة:\n\n'
                '• إجمالي: $total محطة\n'
                '• الخط الأول: $l1 محطة\n'
                '• الخط الثاني: $l2 محطة\n'
                '• الخط الثالث: $l3 محطة'
            : '🚉 Cairo Metro Network:\n\n'
                '• Total: $total stations\n'
                '• Line 1: $l1 stations\n'
                '• Line 2: $l2 stations\n'
                '• Line 3: $l3 stations',
      );
    }

    // ── Timing / schedule
    if (_contains(input, ['مواعيد', 'فتح', 'غلق', 'schedule', 'time', 'open', 'close', 'hours', 'ساعات', 'عمل'])) {
      return _BotResponse(
        text: isAr
            ? '🕐 مواعيد تشغيل مترو القاهرة:\n\n'
                '• الأيام العادية: من 5:00 ص حتى 12:00 م\n'
                '• رمضان: من 6:00 ص حتى 1:00 ص\n'
                '• الجمعة: من 6:00 ص حتى 1:00 ص\n\n'
                '⚡ الكثافة الأعلى: 7–9 ص و 3–6 م\n'
                '✅ أفضل وقت: بعد 9 صباحاً أو قبل 3 مساءً'
            : '🕐 Cairo Metro Operating Hours:\n\n'
                '• Weekdays: 5:00 AM – 12:00 AM\n'
                '• Ramadan: 6:00 AM – 1:00 AM\n'
                '• Fridays: 6:00 AM – 1:00 AM\n\n'
                '⚡ Peak hours: 7–9 AM & 3–6 PM\n'
                '✅ Best time: After 9 AM or before 3 PM',
      );
    }

    // ── Balance / wallet
    if (_contains(input, ['رصيد', 'كارت', 'balance', 'wallet', 'card', 'فلوس'])) {
      final balance = OfflineStorage.getBalance();
      return _BotResponse(
        text: isAr
            ? '💳 رصيدك الحالي في محفظة رفيق:\n\n'
                '${balance.toStringAsFixed(1)} جنيه\n\n'
                'تقدر تشحن أكتر من مطبق رفيق مباشرةً!'
            : '💳 Your current Rafiq wallet balance:\n\n'
                '${balance.toStringAsFixed(1)} EGP\n\n'
                'You can top up directly from the Rafiq app!',
      );
    }

    // ── Nearest station
    if (_contains(input, ['أقرب', 'قريب', 'nearest', 'nearby', 'close', 'موقع', 'location'])) {
      return _BotResponse(
        text: isAr
            ? '📍 عشان أقدر أجيبلك أقرب محطة، محتاج إذن الموقع.\nروح على صفحة المحطات القريبة وهتلاقي كل التفاصيل!'
            : '📍 To find the nearest station, I need location access.\nHead to the Nearby Stations page for full details!',
        actions: [
          _QuickAction(
            label: isAr ? 'المحطات القريبة' : 'Nearby Stations',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const NearbyStationsPage()),
            ),
          ),
        ],
      );
    }

    // ── Route
    if (_contains(input, ['روح', 'أروح', 'طريق', 'مسار', 'route', 'go to', 'from', 'to', 'من', 'إلى', 'الى', 'plan'])) {
      return _BotResponse(
        text: isAr
            ? '🗺️ عاوز تخطط رحلتك؟\nاستخدم مخطط الرحلات وهيحسبلك:\n• أقصر مسار\n• عدد المحطات\n• سعر التذكرة\n• محطات التحويل'
            : '🗺️ Want to plan your trip?\nUse the Route Planner and it will calculate:\n• Shortest route\n• Station count\n• Ticket price\n• Transfer stations',
        actions: [
          _QuickAction(
            label: isAr ? 'مخطط الرحلة' : 'Route Planner',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
            ),
          ),
        ],
      );
    }

    // ── Map
    if (_contains(input, ['خريطة', 'map', 'خطوط', 'lines', 'شبكة', 'network'])) {
      return _BotResponse(
        text: isAr
            ? '🗺️ هنا خريطة المترو التفاعلية الكاملة!\nتقدر تشوف كل المحطات والخطوط.'
            : '🗺️ Here\'s the full interactive metro map!\nYou can see all stations and lines.',
        actions: [
          _QuickAction(
            label: isAr ? 'افتح الخريطة' : 'Open Map',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const MapPage()),
            ),
          ),
        ],
      );
    }

    // ── Crowded / busy
    if (_contains(input, ['زحمة', 'مزدحم', 'crowd', 'busy', 'ازدحام', 'ضغط'])) {
      final hour = DateTime.now().hour;
      final String level;
      final String advice;
      if ((hour >= 7 && hour <= 9) || (hour >= 15 && hour <= 18)) {
        level = isAr ? 'عالي جداً ⚠️' : 'Very High ⚠️';
        advice = isAr ? 'دلوقتي وقت الذروة! لو ممكن تأجل لبعد ساعة.' : 'It\'s peak hour! Try to wait an hour if possible.';
      } else if ((hour >= 10 && hour <= 14) || (hour >= 19 && hour <= 21)) {
        level = isAr ? 'متوسط 😐' : 'Moderate 😐';
        advice = isAr ? 'مقبول، مش وقت ذروة.' : 'Acceptable, not peak hour.';
      } else {
        level = isAr ? 'منخفض ✅' : 'Low ✅';
        advice = isAr ? 'ممتاز! الوقت دا المترو فيه راحة.' : 'Great! Metro is comfortable at this time.';
      }
      return _BotResponse(
        text: isAr
            ? '📊 مستوى الزحمة دلوقتي:\n\n$level\n\n💡 $advice'
            : '📊 Current crowd level:\n\n$level\n\n💡 $advice',
      );
    }

    // ── Points / gamification
    if (_contains(input, ['نقاط', 'points', 'رحلات', 'trips', 'مكافآت', 'rewards', 'achievements'])) {
      final points = OfflineStorage.getPoints();
      final trips = OfflineStorage.getTrips();
      return _BotResponse(
        text: isAr
            ? '🏆 إحصائياتك:\n\n'
                '• نقاطك: $points نقطة\n'
                '• رحلاتك: $trips رحلة\n\n'
                '${points >= 500 ? "🥇 أنت مستخدم ذهبي! شكراً على ولاءك." : "جمّع 500 نقطة وترقى لمستوى ذهبي 🌟"}'
            : '🏆 Your Stats:\n\n'
                '• Points: $points pts\n'
                '• Trips: $trips trips\n\n'
                '${points >= 500 ? "🥇 You\'re a Gold user! Thanks for your loyalty." : "Collect 500 points to reach Gold level 🌟"}',
      );
    }



    // ── Default
    return _BotResponse(
      text: isAr
          ? 'مش فاهم سؤالك كويس 🤔\nجرب تسألني عن:\n• أسعار التذاكر\n• مواعيد المترو\n• رصيدك\n• أقرب محطة\n• الازدحام دلوقتي'
          : 'I didn\'t understand your question 🤔\nTry asking me about:\n• Ticket prices\n• Metro schedules\n• Your balance\n• Nearest station\n• Current crowd levels',
    );
  }

  bool _contains(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'رفيق الذكي' : 'Rafiq AI',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  isAr ? 'متصل دائماً' : 'Always online',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick questions bar
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(
                label: Text(_quickQuestions[i], style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                labelStyle: TextStyle(color: AppColors.primary),
                onPressed: () => _sendMessage(_quickQuestions[i]),
              ),
            ),
          ),
          const Divider(height: 1),
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isAr ? 'اسألني أي سؤال...' : 'Ask me anything...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (_, __) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(
                          0.4 + 0.6 * (i == 0
                              ? _typingController.value
                              : i == 1
                                  ? (1 - _typingController.value)
                                  : _typingController.value),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[_buildAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: msg.isUser
                        ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
                        : null,
                    color: msg.isUser
                        ? null
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: msg.isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                if (msg.actions != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: msg.actions!.map((a) {
                      return ActionChip(
                        label: Text(a.label, style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                        onPressed: () => a.onTap(context),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<_QuickAction>? actions;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.actions,
  });
}

class _QuickAction {
  final String label;
  final void Function(BuildContext) onTap;
  _QuickAction({required this.label, required this.onTap});
}

class _BotResponse {
  final String text;
  final List<_QuickAction>? actions;
  _BotResponse({required this.text, this.actions});
}
