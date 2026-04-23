import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/speech_service.dart';
import '../../metro/presentation/pages/route_planner_page.dart';
import '../../metro/presentation/pages/nearby_stations_page.dart';
import '../../metro/presentation/pages/map_page.dart';
import '../../metro/presentation/pages/subscription_optimizer_page.dart';
import '../../community/presentation/pages/community_page.dart';
import '../../news/presentation/pages/news_page.dart';
import '../../metro/presentation/pages/nfc_wallet_page.dart';
import '../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../crowd_prediction/presentation/pages/crowd_prediction_page.dart';
import '../../gamification/presentation/pages/achievements_page.dart';
import '../../trip_scheduler/presentation/pages/trip_scheduler_page.dart';
import '../../pricing_calculator/presentation/pages/pricing_calculator_page.dart';



enum VoiceCommandState { idle, listening, processing, done }

class VoiceCommandService extends StatefulWidget {
  final Widget child;
  const VoiceCommandService({super.key, required this.child});

  @override
  State<VoiceCommandService> createState() => VoiceCommandServiceState();

  static VoiceCommandServiceState? of(BuildContext context) {
    return context.findAncestorStateOfType<VoiceCommandServiceState>();
  }
}

class VoiceCommandServiceState extends State<VoiceCommandService>
    with TickerProviderStateMixin {
  VoiceCommandState _commandState = VoiceCommandState.idle;
  String _recognizedText = '';
  late AnimationController _micController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _micAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _micController.dispose();
    super.dispose();
  }

  Future<void> startListening() async {
    final isAr = context.locale.languageCode == 'ar';
    setState(() {
      _commandState = VoiceCommandState.listening;
      _recognizedText = '';
    });

    // Simulate recognition (SpeechService integration point)
    await Future.delayed(const Duration(seconds: 2));

    // In a real app this would come from speech_to_text plugin
    // For demo we show the dialog with manual input
    if (mounted) {
      setState(() => _commandState = VoiceCommandState.processing);
      _showCommandDialog(isAr);
    }
  }

  void _showCommandDialog(bool isAr) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _micAnimation,
                builder: (_, child) => Transform.scale(
                  scale: _commandState == VoiceCommandState.listening
                      ? _micAnimation.value
                      : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'قل أمرك...' : 'Say your command...',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'مثال: "افتح الخريطة" أو "روح للمجتمع"'
                    : 'e.g: "Open map" or "Go to community"',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب الأمر هنا...' : 'Type command here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.keyboard_voice),
                ),
                onSubmitted: (v) {
                  Navigator.pop(ctx);
                  _executeCommand(v, isAr);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: (isAr
                        ? ['الخريطة', 'مخطط الرحلة', 'المجتمع', 'إنجازاتي', 'المفقودات']
                        : ['Map', 'Route Planner', 'Community', 'Achievements', 'Lost & Found'])

                    .map(
                      (cmd) => ActionChip(
                        label: Text(cmd, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _executeCommand(cmd, isAr);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    setState(() => _commandState = VoiceCommandState.idle);
  }

  void _executeCommand(String command, bool isAr) {
    final cmd = command.toLowerCase();
    setState(() {
      _recognizedText = command;
      _commandState = VoiceCommandState.done;
    });

    Widget? destination;

    if (_has(cmd, ['خريطة', 'map', 'خرائط'])) {
      destination = const MapPage();
    } else if (_has(cmd, ['مخطط', 'رحلة', 'route', 'plan', 'طريق'])) {
      destination = const RoutePlannerPage();
    } else if (_has(cmd, ['قريب', 'nearby', 'محطات قريبة'])) {
      destination = const NearbyStationsPage();
    } else if (_has(cmd, ['مجتمع', 'community'])) {
      destination = const CommunityPage();
    } else if (_has(cmd, ['أخبار', 'news'])) {
      destination = const NewsPage();
    } else if (_has(cmd, ['nfc', 'محفظة', 'wallet', 'كارت'])) {
      destination = const NfcWalletPage();
    } else if (_has(cmd, ['اشتراك', 'subscription', 'optimize'])) {
      destination = const SubscriptionOptimizerPage();
    } else if (_has(cmd, ['ذكاء', 'ai', 'مساعد', 'assistant', 'رفيق'])) {
      destination = const AiAssistantPage();
    } else if (_has(cmd, ['ازدحام', 'زحمة', 'crowd'])) {
      destination = const CrowdPredictionPage();
    } else if (_has(cmd, ['إنجاز', 'نقاط', 'شارات', 'achievement', 'badge', 'points'])) {
      destination = const AchievementsPage();
    } else if (_has(cmd, ['جدول', 'schedule', 'مجدل'])) {
      destination = const TripSchedulerPage();
    } else if (_has(cmd, ['تكلفة', 'سعر', 'price', 'calculator', 'حاسبة'])) {
      destination = const PricingCalculatorPage();

    }

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _commandState = VoiceCommandState.idle);
    });

    if (destination != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '✅ فهمت: "$command"' : '✅ Got it: "$command"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ));
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '🤔 لم أفهم الأمر، جرب مرة أخرى' : '🤔 Command not recognized, try again'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  bool _has(String cmd, List<String> keywords) =>
      keywords.any((k) => cmd.contains(k));

  @override
  Widget build(BuildContext context) => widget.child;
}
