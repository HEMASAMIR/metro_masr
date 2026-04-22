import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/gamification_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/voice_service.dart';
import '../widgets/feature_card.dart';
import 'route_planner_page.dart';
import 'map_page.dart';
import 'nearby_stations_page.dart';
import 'subscription_optimizer_page.dart';
import 'ar_navigation_page.dart';
import '../../../community/presentation/pages/community_page.dart';
import 'nfc_wallet_page.dart';
import '../widgets/tourist_translator_modal.dart';
import '../widgets/live_radar_widget.dart';
import '../../../community/presentation/pages/lost_and_found_page.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../crowd_prediction/presentation/pages/crowd_prediction_page.dart';
import '../../../gamification/presentation/pages/achievements_page.dart';
import '../../../trip_scheduler/presentation/pages/trip_scheduler_page.dart';
import '../../../pricing_calculator/presentation/pages/pricing_calculator_page.dart';
import '../../../emergency/presentation/pages/emergency_page.dart';
import '../../../voice_command/presentation/voice_command_service.dart';
import '../../../impact/presentation/pages/impact_dashboard_page.dart';
import '../../../tourism/presentation/pages/tourist_attractions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _points = 0;
  int _trips = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await GamificationService.init();
    setState(() {
      _points = GamificationService.getPoints();
      _trips = GamificationService.getTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final padding = r.pagePadding;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Offline First', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (Locale locale) {
              context.setLocale(locale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('English')),
              const PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
              const PopupMenuItem(value: Locale('fr'), child: Text('Français')),
              const PopupMenuItem(value: Locale('de'), child: Text('Deutsch')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final svc = VoiceCommandService.of(context);
          if (svc != null) {
            svc.startListening();
          } else {
            // fallback: show directly
            final isAr = context.locale.languageCode == 'ar';
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _VoiceCommandSheet(isAr: isAr),
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.mic, color: Colors.white),
        tooltip: 'Voice Command',
      ),
      body: VoiceCommandService(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Text(
                      'welcome_msg'.tr(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: r.fontSize(24),
                      ),
                    ),
                  ),
                  SizedBox(height: r.sectionSpacing * 0.5),

                  // Gamification banner
                  FadeInDown(
                    delay: const Duration(milliseconds: 50),
                    child: _buildGamificationBanner(context, r),
                  ),
                  SizedBox(height: r.sectionSpacing * 0.5),

                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: const LiveRadarWidget(),
                  ),
                  SizedBox(height: r.sectionSpacing),

                  // ── Feature cards: single column on phone‑portrait,
                  //    2‑column grid on tablet / landscape ─────────────────
                  r.featureGridColumns == 1
                      ? _buildFeatureList(context, r)
                      : _buildFeatureGrid(context, r),

                  SizedBox(height: r.sectionSpacing * 2),

                  Text(
                    'line_status'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: r.fontSize(20),
                    ),
                  ),
                  SizedBox(height: r.sectionSpacing * 0.75),

                  // Line status – wrap in a grid on wide screens
                  r.useSideBySideLayout
                      ? Row(
                          children: [
                            Expanded(child: _buildStatusCard('Line 1', 'on_time'.tr(), AppColors.line1, context, r)),
                            SizedBox(width: r.sectionSpacing * 0.75),
                            Expanded(child: _buildStatusCard('Line 2', 'minor_delays'.tr(), AppColors.line2, context, r)),
                            SizedBox(width: r.sectionSpacing * 0.75),
                            Expanded(child: _buildStatusCard('Line 3', 'on_time'.tr(), AppColors.line3, context, r)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildStatusCard('Line 1', 'on_time'.tr(), AppColors.line1, context, r),
                            _buildStatusCard('Line 2', 'minor_delays'.tr(), AppColors.line2, context, r),
                            _buildStatusCard('Line 3', 'on_time'.tr(), AppColors.line3, context, r),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGamificationBanner(BuildContext context, Responsive r) {
    final isAr = context.locale.languageCode == 'ar';
    final level = isAr
        ? GamificationService.getCurrentLevel(_points)
        : GamificationService.getCurrentLevelEn(_points);
    final nextPts = GamificationService.getNextLevelPoints(_points);
    final progress = (_points / nextPts).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementsPage()),
      ).then((_) => _loadStats()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? '$level • $_points نقطة • $_trips رحلة' : '$level • $_points pts • $_trips trips',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Single‑column list (phone portrait) ──────────────────────────────────
  Widget _buildFeatureList(BuildContext context, Responsive r) {
    final cards = _featureConfigs(context);
    return Column(
      children: cards
          .asMap()
          .entries
          .map((e) => Padding(
                padding: EdgeInsets.only(bottom: r.sectionSpacing),
                child: FadeInUp(
                  delay: Duration(milliseconds: 200 * e.key),
                  child: e.value,
                ),
              ))
          .toList(),
    );
  }

  // ── 2‑column grid (tablet / landscape) ───────────────────────────────────
  Widget _buildFeatureGrid(BuildContext context, Responsive r) {
    final cards = _featureConfigs(context);
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      final hasSecond = i + 1 < cards.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: r.sectionSpacing),
          child: Row(
            children: [
              Expanded(
                child: FadeInUp(
                  delay: Duration(milliseconds: 150 * i),
                  child: cards[i],
                ),
              ),
              if (hasSecond) ...[
                SizedBox(width: r.sectionSpacing),
                Expanded(
                  child: FadeInUp(
                    delay: Duration(milliseconds: 150 * (i + 1)),
                    child: cards[i + 1],
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  List<Widget> _featureConfigs(BuildContext context) {
    final lang = context.locale.languageCode;
    final isAr = lang == 'ar';
    void speak(String text) => VoiceService.speak(text, lang);

    return [
      FeatureCard(
        title: 'route_planner'.tr(),
        subtitle: 'route_subtitle'.tr(),
        icon: Icons.route_outlined,
        color: AppColors.primary,
        onTap: () {
          speak('route_planner'.tr());
          GamificationService.recordRoutePlan();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutePlannerPage()));
        },
      ),
      FeatureCard(
        title: 'interactive_map'.tr(),
        subtitle: 'map_subtitle'.tr(),
        icon: Icons.map_outlined,
        color: AppColors.line3,
        onTap: () {
          speak('interactive_map'.tr());
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
        },
      ),
      FeatureCard(
        title: 'nearby_stations'.tr(),
        subtitle: 'nearby_subtitle'.tr(),
        icon: Icons.my_location,
        color: AppColors.line2,
        onTap: () {
          speak('nearby_stations'.tr());
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyStationsPage()));
        },
      ),
      // ── NEW FEATURE 1: AI Trip Assistant ──────────────────────────────────
      FeatureCard(
        title: isAr ? 'رفيق الذكي 🤖' : 'AI Assistant 🤖',
        subtitle: isAr ? 'اسألني أي سؤال عن المترو' : 'Ask me anything about metro',
        icon: Icons.smart_toy_outlined,
        color: const Color(0xFF7C3AED),
        onTap: () {
          GamificationService.recordAiQuery();
          GamificationService.unlockBadge(BadgeType.aiUser);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantPage()))
              .then((_) => _loadStats());
        },
      ),
      // ── NEW FEATURE 2: Crowd Prediction ──────────────────────────────────
      FeatureCard(
        title: isAr ? 'توقع الازدحام 📊' : 'Crowd Forecast 📊',
        subtitle: isAr ? 'اعرف الزحمة قبل ما تمشي' : 'Know the crowd before you go',
        icon: Icons.people_outline,
        color: Colors.teal,
        onTap: () {
          GamificationService.recordCrowdCheck();
          GamificationService.unlockBadge(BadgeType.crowdChecker);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CrowdPredictionPage()))
              .then((_) => _loadStats());
        },
      ),
      // ── NEW FEATURE 3: Gamification ───────────────────────────────────────
      FeatureCard(
        title: isAr ? 'إنجازاتي 🏆' : 'My Achievements 🏆',
        subtitle: isAr ? 'نقاطك وشاراتك ومستواك' : 'Your points, badges & level',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFD97706),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage()))
              .then((_) => _loadStats());
        },
      ),
      // ── NEW FEATURE 4: Trip Scheduler ─────────────────────────────────────
      FeatureCard(
        title: isAr ? 'جداول الرحلات 📅' : 'Trip Scheduler 📅',
        subtitle: isAr ? 'رحلاتك المتكررة بإشعارات' : 'Recurring trips with reminders',
        icon: Icons.calendar_month_outlined,
        color: Colors.indigo,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripSchedulerPage()));
        },
      ),
      // ── NEW FEATURE 5: Pricing Calculator ─────────────────────────────────
      FeatureCard(
        title: isAr ? 'حاسبة التكلفة 💳' : 'Cost Calculator 💳',
        subtitle: isAr ? 'احسب وقارن وفر فلوسك' : 'Calculate, compare & save',
        icon: Icons.calculate_outlined,
        color: Colors.green[700]!,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingCalculatorPage()));
        },
      ),
      // ── NEW FEATURE 6: Emergency Services ─────────────────────────────────
      FeatureCard(
        title: isAr ? 'خدمات الطوارئ 🆘' : 'Emergency Services 🆘',
        subtitle: isAr ? 'SOS سريع وأرقام طوارئ' : 'Quick SOS & emergency numbers',
        icon: Icons.emergency_outlined,
        color: Colors.red[700]!,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyPage()));
        },
      ),
      // Tourist Attractions
      FeatureCard(
        title: isAr ? 'الأماكن السياحية 🗺️' : 'Tourist Attractions 🗺️',
        subtitle: isAr ? 'اكتشف مزارات مصر من أي محطة • 4 لغات' : 'Discover Egypt landmarks from any station • 4 languages',
        icon: Icons.attractions_outlined,
        color: const Color(0xFFFFB800),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TouristAttractionsPage()));
        },
      ),
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2A6C), Color(0xFF0A0E27)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCE1126).withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCE1126).withOpacity(0.2),
              blurRadius: 20, spreadRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactDashboardPage()))
                  .then((_) => _loadStats());
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Text('🇪🇬', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'رفيق خدم مصر كلها' : 'Rafiq Served All of Egypt',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr ? '85 محطة • 3 خطوط • 3.5M راكب يومياً' : '85 stations • 3 lines • 3.5M riders',
                          style: const TextStyle(color: Color(0xFF8899CC), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF4F8AFF)),
                ],
              ),
            ),
          ),
        ),
      ),
      FeatureCard(
        title: 'subscription_optimizer'.tr(),
        subtitle: '',
        icon: Icons.savings_outlined,
        color: AppColors.accent,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionOptimizerPage()));
        },
      ),
      FeatureCard(
        title: 'ar_navigation'.tr(),
        subtitle: '',
        icon: Icons.view_in_ar,
        color: AppColors.primary,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ARNavigationPage()));
        },
      ),
      FeatureCard(
        title: 'community'.tr(),
        subtitle: 'community_subtitle'.tr(),
        icon: Icons.account_tree_outlined,
        color: AppColors.line2,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPage()));
        },
      ),
      FeatureCard(
        title: isAr ? 'أخبار حصرية' : 'Latest News',
        subtitle: isAr ? 'مصر والعالم لحظة بلحظة' : 'Live updates',
        icon: Icons.newspaper_outlined,
        color: AppColors.primary,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
        },
      ),
      FeatureCard(
        title: 'nfc_wallet'.tr(),
        subtitle: isAr ? 'شحن ومتابعة رصيد الكارت' : 'Manage your metro card',
        icon: Icons.contactless_outlined,
        color: AppColors.line3,
        onTap: () {
          GamificationService.recordNfcUse();
          GamificationService.unlockBadge(BadgeType.nfcPro);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NfcWalletPage()))
              .then((_) => _loadStats());
        },
      ),
      FeatureCard(
        title: isAr ? 'المترجم السياحي' : 'Tourist Assist',
        subtitle: isAr ? 'ترجمة فورية بالصوت' : 'Instant Voice Translation',
        icon: Icons.g_translate,
        color: AppColors.primary,
        onTap: () {
          TouristTranslatorModal.show(context);
        },
      ),
      FeatureCard(
        title: isAr ? 'شبكة المفقودات' : 'Lost & Found',
        subtitle: isAr ? 'أبلغ عن المفقودات والمعثورات' : 'Report & Find lost items',
        icon: Icons.travel_explore,
        color: AppColors.line2,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LostAndFoundPage()));
        },
      ),
    ];
  }

  Widget _buildStatusCard(String line, String status, Color color, BuildContext context, Responsive r) {
    final isOnTime = status == 'on_time'.tr() || status == 'مستقر';
    final lineNum = int.tryParse(line.replaceAll(RegExp(r'\D'), '')) ?? 1;
    final stationCount = MetroData.stations.values.where((s) => s.line == lineNum).length;
    final lang = context.locale.languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(r.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Line colour indicator
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          // Line name + station count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line, style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(14))),
              Text(
                lang == 'ar' ? '$stationCount محطة' : '$stationCount stations',
                style: TextStyle(fontSize: r.fontSize(11), color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnTime
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isOnTime ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.bold,
                fontSize: r.fontSize(12),
              ),
            ),
          ),
          // 🔔 Notify me button
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              icon: Icon(
                isOnTime ? Icons.notifications_none : Icons.notifications_active,
                size: r.iconSize(20),
                color: isOnTime ? AppColors.textSecondary : AppColors.warning,
              ),
              tooltip: lang == 'ar' ? 'تفعيل إشعار التأخير' : 'Alert me about delays',
              onPressed: () async {
                HapticFeedback.lightImpact();
                if (!isOnTime) {
                  await NotificationService.showLineDelayAlert(
                    lineNumber: lineNum,
                    delayMinutes: 8,
                    isArabic: lang == 'ar',
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'ar'
                            ? isOnTime
                                ? '✅ هتتنبك لو في تأخير في الخط $lineNum'
                                : '⚠️ يوجد تأخير في الخط $lineNum — تم الإشعار!'
                            : isOnTime
                                ? '✅ You will be notified of delays on Line $lineNum'
                                : '⚠️ Delay on Line $lineNum — notification sent!',
                      ),
                      backgroundColor: isOnTime ? AppColors.success : AppColors.warning,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback Voice Command Sheet ─────────────────────────────────────────────
class _VoiceCommandSheet extends StatelessWidget {
  final bool isAr;
  const _VoiceCommandSheet({required this.isAr});

  void _navigate(BuildContext context, String cmd) {
    Navigator.pop(context);
    final lower = cmd.toLowerCase();
    Widget? dest;
    if (lower.contains('خريطة') || lower.contains('map')) {
      dest = const MapPage();
    } else if (lower.contains('مخطط') || lower.contains('route') || lower.contains('رحلة') || lower.contains('plan')) {
      dest = const RoutePlannerPage();
    } else if (lower.contains('قريب') || lower.contains('nearby')) {
      dest = const NearbyStationsPage();
    } else if (lower.contains('مجتمع') || lower.contains('community')) {
      dest = const CommunityPage();
    } else if (lower.contains('أخبار') || lower.contains('news')) {
      dest = const NewsPage();
    } else if (lower.contains('طوارئ') || lower.contains('emergency') || lower.contains('sos')) {
      dest = const EmergencyPage();
    } else if (lower.contains('ازدحام') || lower.contains('crowd')) {
      dest = const CrowdPredictionPage();
    } else if (lower.contains('إنجاز') || lower.contains('achievement') || lower.contains('نقاط') || lower.contains('points')) {
      dest = const AchievementsPage();
    } else if (lower.contains('جدول') || lower.contains('schedule')) {
      dest = const TripSchedulerPage();
    } else if (lower.contains('تكلفة') || lower.contains('price') || lower.contains('حاسبة') || lower.contains('calculator')) {
      dest = const PricingCalculatorPage();
    } else if (lower.contains('ذكاء') || lower.contains('ai') || lower.contains('مساعد') || lower.contains('assistant')) {
      dest = const AiAssistantPage();
    }
    if (dest != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => dest!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickCmds = isAr
        ? ['الخريطة', 'مخطط الرحلة', 'الازدحام', 'الطوارئ', 'إنجازاتي', 'الذكاء الاصطناعي']
        : ['Map', 'Route Planner', 'Crowd', 'Emergency', 'Achievements', 'AI Assistant'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'اكتب أمرك...' : 'Type your command...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: isAr ? 'مثلاً: افتح الخريطة' : 'e.g: Open map',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.keyboard_voice),
              ),
              onSubmitted: (v) => _navigate(context, v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: quickCmds.map((cmd) => ActionChip(
                label: Text(cmd, style: const TextStyle(fontSize: 12)),
                onPressed: () => _navigate(context, cmd),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}



