import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/features/pricing_calculator/presentation/pages/pricing_calculator_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/dijkstra.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/utils/egypt_time.dart';
import '../../../metro/domain/entities/station.dart';
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
  int _selectedNetworkIndex = 0; // 0: Cairo, 1: LRT (Capital), 2: Monorail
  bool _isTyping = false;
  late AnimationController _typingController;

  static const List<String> _quickQuestions = [
    'أرخص تذكرة',
    'أقرب محطة',
    'مواعيد المترو',
    'المترو شغال؟',
    'أسرع طريق',
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
      final now = EgyptTime.getEgyptTime();
      final isOpen = CrowdPredictionService.isMetroOpen(
        hour: now.hour,
        weekday: now.weekday,
      );
      final statusEmoji = isOpen ? '🟢' : '🔴';
      final statusAr = isOpen ? 'المترو شغال دلوقتي' : 'المترو مقفل دلوقتي';
      final statusEn = isOpen
          ? 'Metro is currently running'
          : 'Metro is currently closed';
      _addBotMessage(
        context.locale.languageCode == 'ar'
            ? 'مرحباً! أنا رفيق، مساعدك الذكي لمترو القاهرة 🚇\n$statusEmoji $statusAr\nاسألني عن المحطات، الأسعار، البدائل أو أي حاجة عاوزها!'
            : 'Hello! I\'m Rafiq, your smart Cairo Metro assistant 🚇\n$statusEmoji $statusEn\nAsk me about stations, fares, routes or anything you need!',
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
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: false,
          time: EgyptTime.getEgyptTime(),
          actions: actions,
        ),
      );
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
      _messages.add(
        _ChatMessage(text: text, isUser: true, time: EgyptTime.getEgyptTime()),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final response = _generateResponse(text.toLowerCase(), isAr);
      setState(() => _isTyping = false);
      _addBotMessage(response.text, actions: response.actions);
    } catch (e) {
      setState(() => _isTyping = false);
      _addBotMessage(
        isAr
            ? "عذراً، فيه حاجة محملتش صح. جرب تسألني تاني كمان ثانية."
            : "Sorry, something isn't ready yet. Please try again in a moment.",
      );
    }
  }

  _BotResponse _generateResponse(String input, bool isAr) {
    // تخصيص السياق بناءً على الشبكة المختارة
    final networkPrefix = _selectedNetworkIndex == 1
        ? (isAr
              ? "بالنسبة لمترو العاصمة (LRT): "
              : "Regarding Capital Metro (LRT): ")
        : _selectedNetworkIndex == 2
        ? (isAr ? "بالنسبة للمونوريل: " : "Regarding the Monorail: ")
        : "";

    // ── Fare / price
    if (_contains(input, [
      'سعر',
      'تذكرة',
      'price',
      'fare',
      'ticket',
      'كلفة',
      'تكلفة',
      'جنيه',
    ])) {
      if (_selectedNetworkIndex == 1) {
        return _BotResponse(
          text: isAr
              ? "🎫 تذاكر مترو العاصمة بتبدأ من 15 جنيه لـ 3 محطات، وبتوصل لـ 25 جنيه لأكتر من 7 محطات."
              : "🎫 LRT tickets start at 15 EGP for 3 stations and go up to 25 EGP for 7+ stations.",
        );
      }
      if (_selectedNetworkIndex == 2) {
        return _BotResponse(
          text: isAr
              ? "🎫 تذاكر المونوريل متوقع تبدأ من 20 جنيه، وهتكون بنظام المناطق زي المترو بالظبط."
              : "🎫 Monorail tickets are expected to start at 20 EGP, using a zone-based system.",
        );
      }
      return _BotResponse(
        text: isAr
            ? '🎫 أسعار التذاكر والاشتراكات الجديدة 2026:\n\n'
                  '📌 التذاكر الفردية:\n'
                  '• 9 محطات: 10 جنيه\n'
                  '• 16 محطة: 13 جنيه\n'
                  '• 23 محطة: 17 جنيه\n'
                  '• +23 محطة: 20 جنيه\n\n'
                  '💳 الاشتراكات الشهرية (60 رحلة):\n'
                  '• منطقة واحدة: 230 جنيه\n'
                  '• منطقتين: 290 جنيه\n'
                  '• 3-4 مناطق: 340 جنيه\n'
                  '• كل المناطق: 450 جنيه\n\n'
                  '💡 نصيحة: لو بتركب يومياً، الاشتراك هيوفرلك مبالغ كبيرة!'
            : '🎫 Cairo Metro 2026 Fares:\n\n'
                  '📌 Single Tickets:\n'
                  '• 9 stations: 10 EGP\n'
                  '• 16 stations: 13 EGP\n'
                  '• 23 stations: 17 EGP\n'
                  '• 23+ stations: 20 EGP\n\n'
                  '💳 Monthly Subscriptions (60 trips):\n'
                  '• 1 Zone: 230 EGP\n'
                  '• 2 Zones: 290 EGP\n'
                  '• 3-4 Zones: 340 EGP\n'
                  '• All Zones: 450 EGP\n\n'
                  '💡 Tip: Subscribing saves you over 40%!',
        actions: [
          _QuickAction(
            label: "Calculate Mine".tr(),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
            ),
          ),
        ],
      );
    }

    // ── تحليل التوفير وتنبيه تخطي سعر الاشتراك
    if (_contains(input, [
      'توفير',
      'أوفر',
      'وفر',
      'أصرف',
      'بصرف',
      'save',
      'savings',
      'spend',
      'monthly cost',
    ])) {
      return _BotResponse(
        text: isAr
            ? '📊 تحليل التوفير الشهري (على أساس 22 يوم عمل):\n\n'
                  '• منطقة واحدة: تذاكر (440ج) vs اشتراك (230ج) ⮕ توفير 210ج ✅\n'
                  '• منطقتين: تذاكر (572ج) vs اشتراك (290ج) ⮕ توفير 282ج ✅\n'
                  '• 3-4 مناطق: تذاكر (748ج) vs اشتراك (340ج) ⮕ توفير 408ج ✅\n\n'
                  '⚠️ تنبيه: استهلاكك الشهري الحالي يتخطى سعر الاشتراك! الأفضل تطلع كارت اشتراك شهري فوراً.'
            : '📊 Monthly Savings Analysis (based on 22 working days):\n\n'
                  '• 1 Zone: Tickets (440) vs Sub (230) ⮕ Save 210 EGP ✅\n'
                  '• 2 Zones: Tickets (572) vs Sub (290) ⮕ Save 282 EGP ✅\n'
                  '• 3-4 Zones: Tickets (748) vs Sub (340) ⮕ Save 408 EGP ✅\n\n'
                  '⚠️ Alert: Your current monthly spend exceeds the subscription price! We recommend getting a monthly card.',
        actions: [
          _QuickAction(
            label: "Cost Calculator".tr(),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const PricingCalculatorPage()),
            ),
          ),
        ],
      );
    }

    // ── Stations count
    if (_contains(input, [
      'كم محطة',
      'عدد المحطات',
      'how many station',
      'stations count',
    ])) {
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
    if (_contains(input, [
      'مواعيد',
      'فتح',
      'غلق',
      'schedule',
      'time',
      'open',
      'close',
      'hours',
      'ساعات',
    ])) {
      return _BotResponse(
        text: isAr
            ? '🕐 مواعيد تشغيل مترو القاهرة:\n\n'
                  '• الأيام العادية: من 5:00 ص حتى 1:00 ص (بعد منتصف الليل)\n'
                  '• يوم الجمعة: من 5:00 ص حتى 2:00 ص\n\n'
                  '⚡ الكثافة الأعلى: 7–9 ص و 3–6 م\n'
                  '✅ أفضل وقت: بعد 9 صباحاً أو بعد 9 مساءً'
            : '🕐 Cairo Metro Operating Hours:\n\n'
                  '• Regular days: 5:00 AM – 1:00 AM (+1 day)\n'
                  '• Fridays: 5:00 AM – 2:00 AM (+1 day)\n\n'
                  '⚡ Peak hours: 7–9 AM & 3–6 PM\n'
                  '✅ Best time: After 9 AM or after 9 PM',
      );
    }

    // ── Is Metro Open / Status
    if (_contains(input, [
      'شغال',
      'مفتوح',
      'مقفل',
      'شغاله',
      'is open',
      'is closed',
      'operating',
      'running',
    ])) {
      final now = EgyptTime.getEgyptTime();
      final isOpen = CrowdPredictionService.isMetroOpen(
        hour: now.hour,
        weekday: now.weekday,
      );
      final closingTime = CrowdPredictionService.closingTime(now.weekday);
      final closingHour = CrowdPredictionService.getLastServiceHour(
        now.weekday,
      );
      final hoursLeft = now.hour < closingHour
          ? closingHour - now.hour
          : (24 - now.hour) + closingHour;

      return _BotResponse(
        text: isAr
            ? (isOpen
                  ? '🟢 المترو شغال دلوقتي!\n\n'
                        '• هيقفل الساعة $closingTime\n'
                        '• باقي ~$hoursLeft ساعة\n\n'
                        '💡 نصيحة: ${now.hour >= 7 && now.hour <= 9 || now.hour >= 15 && now.hour <= 18 ? "دلوقتي وقت الذروة، لو تقدر استنى شوية هيكون أحسن" : "الوقت مناسب جداً للسفر!"}'
                  : '🔴 المترو مقفل دلوقتي.\n\n'
                        '• هيفتح تاني الساعة 5:00 صباحاً\n'
                        '• ${now.weekday == DateTime.friday ? "النهارده الجمعة — هيشتغل لحد 2:00 ص" : "هيشتغل لحد $closingTime"}\n\n'
                        '💤 نصيحة: ضبط منبه آخر قطار عشان ميفوتكش!')
            : (isOpen
                  ? '🟢 Metro is running right now!\n\n'
                        '• Closes at $closingTime\n'
                        '• ~$hoursLeft hours remaining\n\n'
                        '💡 Tip: ${now.hour >= 7 && now.hour <= 9 || now.hour >= 15 && now.hour <= 18 ? "It\'s peak hours now, wait a bit if you can" : "Great time to travel!"}'
                  : '🔴 Metro is currently closed.\n\n'
                        '• Opens again at 5:00 AM\n'
                        '• ${now.weekday == DateTime.friday ? "Today is Friday — operates until 2:00 AM" : "Operates until $closingTime"}\n\n'
                        '💤 Tip: Set a Last Train alarm so you never miss it!'),
      );
    }

    // ── Nearest station
    if (_contains(input, [
      'أقرب',
      'قريب',
      'nearest',
      'nearby',
      'close',
      'موقع',
      'location',
    ])) {
      final networkName = _selectedNetworkIndex == 1
          ? "LRT"
          : _selectedNetworkIndex == 2
          ? "Monorail"
          : "Cairo Metro";
      return _BotResponse(
        text: isAr
            ? "📍 عشان أقدر أجيبلك أقرب محطة في $networkName، محتاج إذن الموقع.\nروح على صفحة المحطات القريبة وهتلاقي كل التفاصيل!"
            : "📍 To find the nearest $networkName station, I need location access.\nHead to the Nearby Stations page for full details!",
        actions: [
          _QuickAction(
            label: "Nearby Stations".tr(),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const NearbyStationsPage()),
            ),
          ),
        ],
      );
    }

    // ── Route
    if (_contains(input, [
      'روح',
      'أروح',
      'طريق',
      'مسار',
      'route',
      'go to',
      'from',
      'to',
      'من',
      'إلى',
      'الى',
      'plan',
      'عايز',
    ])) {
      // Normalize aliases
      final replacements = {
        'الزراعه': 'كلية الزراعة',
        'الزراعة': 'كلية الزراعة',
        'المعادى': 'المعادي',
        'كوبري القبه': 'كوبري القبة',
        'شبرا': 'شبرا الخيمة',
        'الجامعه': 'جامعة حلوان',
        'رمسيس': 'الشهداء',
      };
      var searchInput = input;
      replacements.forEach(
        (key, value) => searchInput = searchInput.replaceAll(key, value),
      );

      // Extract stations from the input
      List<Station> found = [];
      final allNetwork = {...MetroData.stations, ...MetroData.capitalStations};
      for (var s in allNetwork.values) {
        if (searchInput.contains(s.nameAr.toLowerCase()) ||
            searchInput.contains(s.nameEn.toLowerCase())) {
          found.add(s);
        }
      }

      if (found.length >= 2) {
        Station? src;
        Station? dest;
        for (var s in found) {
          if (searchInput.contains('من ${s.nameAr}') ||
              searchInput.contains('from ${s.nameEn.toLowerCase()}'))
            src = s;
          else if (searchInput.contains('اروح ${s.nameAr}') ||
              searchInput.contains('إلى ${s.nameAr}') ||
              searchInput.contains('الى ${s.nameAr}') ||
              searchInput.contains('to ${s.nameEn.toLowerCase()}'))
            dest = s;
        }

        if (src == null || dest == null) {
          int idx0 = searchInput.indexOf(found[0].nameAr.toLowerCase());
          if (idx0 == -1)
            idx0 = searchInput.indexOf(found[0].nameEn.toLowerCase());
          int idx1 = searchInput.indexOf(found[1].nameAr.toLowerCase());
          if (idx1 == -1)
            idx1 = searchInput.indexOf(found[1].nameEn.toLowerCase());

          if (idx0 < idx1) {
            dest = found[0];
            src = found[1];
          } else {
            dest = found[1];
            src = found[0];
          }
        }

        final res = Dijkstra.findShortestPath(allNetwork, src.id, dest.id);
        final path = res['path'] as List<Station>;
        if (path.isNotEmpty) {
          final count = path.length - 1;
          final time = count * 2;
          int price = 10;
          if (count > 23)
            price = 20;
          else if (count >= 17)
            price = 17;
          else if (count >= 10)
            price = 13;

          // إضافة نصيحة ذكية أوتوماتيكية داخل نتيجة البحث عن مسار
          final subTextAr =
              "\n\n💡 نصيحة: لو هتركب المشوار ده يومياً، الاشتراك الشهري هيوفرلك حوالي ${(price * 44) - (count >= 17 ? 340 : (count >= 10 ? 290 : 230))} جنيه!";
          final subTextEn =
              "\n\n💡 Tip: If you take this trip daily, a subscription will save you around ${(price * 44) - (count >= 17 ? 340 : (count >= 10 ? 290 : 230))} EGP!";

          return _BotResponse(
            text: isAr
                ? '✅ من عيني! هتركب من محطة **${src.nameAr}** وتوصل **${dest.nameAr}**.\n\n'
                      '• عدد المحطات: $count محطة\n'
                      '• الوقت المتوقع: حوالي $time دقيقة\n'
                      '• التذكرة: $price جنيه$subTextAr\n\n'
                      'توصل بالسلامة!'
                : '✅ Sure! You will go from **${src.nameEn}** to **${dest.nameEn}**.\n\n'
                      '• Stations: $count stops\n'
                      '• Estimated time: ~$time mins\n'
                      '• Ticket: $price EGP$subTextEn\n\n'
                      'Have a safe trip!',
            actions: [
              _QuickAction(
                label: "Route Planner".tr(),
                onTap: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
                ),
              ),
            ],
          );
        }
      }

      return _BotResponse(
        text:
            "🗺️ Want to plan your trip?\nUse the Route Planner and it will calculate:\n• Shortest route\n• Station count\n• Ticket price\n• Transfer stations"
                .tr(),
        actions: [
          _QuickAction(
            label: "Route Planner".tr(),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
            ),
          ),
        ],
      );
    }

    // ── Map
    if (_contains(input, [
      'خريطة',
      'map',
      'خطوط',
      'lines',
      'شبكة',
      'network',
    ])) {
      return _BotResponse(
        text:
            "🗺️ Here's the full interactive metro map!\nYou can see all stations and lines."
                .tr(),
        actions: [
          _QuickAction(
            label: "Open Map".tr(),
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
      final hour = EgyptTime.getEgyptTime().hour;
      final String level;
      final String advice;
      if ((hour >= 7 && hour <= 9) || (hour >= 15 && hour <= 18)) {
        level = "Very High ⚠️".tr();
        advice = "It's peak hour! Try to wait an hour if possible.".tr();
      } else if ((hour >= 10 && hour <= 14) || (hour >= 19 && hour <= 21)) {
        level = "Moderate 😐".tr();
        advice = "Acceptable, not peak hour.".tr();
      } else {
        level = "Low ✅".tr();
        advice = "Great! Metro is comfortable at this time.".tr();
      }
      return _BotResponse(
        text: isAr
            ? '📊 مستوى الزحمة دلوقتي:\n\n$level\n\n💡 $advice'
            : '📊 Current crowd level:\n\n$level\n\n💡 $advice',
      );
    }

    // ── Default
    return _BotResponse(
      text:
          "I didn't understand your question 🤔\nTry asking me about:\n• Ticket prices\n• Metro schedules\n• Your balance\n• Nearest station\n• Current crowd levels"
              .tr(),
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
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Rafiq AI".tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Always online".tr(),
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Network Selector Tabs
          _buildNetworkSelector(isAr),

          const Divider(height: 1),

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
                label: Text(
                  _quickQuestions[i],
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                labelStyle: TextStyle(color: AppColors.primary),
                onPressed: () => _sendMessage(_quickQuestions[i]),
              ),
            ),
          ),
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
                        hintText: "Ask me anything...".tr(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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

  Widget _buildNetworkSelector(bool isAr) {
    final networks = [
      {
        'name': isAr ? 'مترو القاهرة' : 'Cairo Metro',
        'icon': Icons.subway_rounded,
      },
      {
        'name': isAr ? 'مترو العاصمة' : 'Capital Metro',
        'icon': Icons.train_rounded,
      },
      {
        'name': isAr ? 'المونوريل' : 'Monorail',
        'icon': Icons.linear_scale_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Row(
        children: List.generate(networks.length, (index) {
          final isSelected = _selectedNetworkIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedNetworkIndex = index);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      networks[index]['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      networks[index]['name'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
                          0.4 +
                              0.6 *
                                  (i == 0
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
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[_buildAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: msg.isUser
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          )
                        : null,
                    color: msg.isUser
                        ? null
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: msg.isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: msg.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
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
                        label: Text(
                          a.label,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        onPressed: () => a.onTap(context),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  EgyptTime.formatTime(
                    msg.time,
                    locale: context.locale.languageCode,
                  ),
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
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: Colors.white,
      ),
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
