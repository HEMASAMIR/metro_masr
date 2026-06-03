import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/utils/metro_data.dart';

class CrowdPredictionPage extends StatefulWidget {
  const CrowdPredictionPage({super.key});

  @override
  State<CrowdPredictionPage> createState() => _CrowdPredictionPageState();
}

class _CrowdPredictionPageState extends State<CrowdPredictionPage>
    with SingleTickerProviderStateMixin {
  int _selectedLine = 1;
  late TabController _tabController;
  final ScrollController _hourScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedLine = _tabController.index + 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentHour());
  }

  void _scrollToCurrentHour() {
    final hour = DateTime.now().hour;
    if (_hourScroll.hasClients) {
      _hourScroll.animateTo(
        (hour * 72.0).clamp(0, _hourScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hourScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr  = context.locale.languageCode == 'ar';
    final now   = DateTime.now();
    final weekday     = now.weekday;
    final currentHour = now.hour;

    final isOpen = CrowdPredictionService.isMetroOpen(hour: currentHour, weekday: weekday);
    final forecast = CrowdPredictionService.getDailyForecast(
      lineNumber: _selectedLine,
      weekday: weekday,
    );
    final currentLevel = isOpen
        ? CrowdPredictionService.getCrowdLevel(
            hour: currentHour, weekday: weekday, lineNumber: _selectedLine)
        : 0.0;
    final currentCategory = CrowdPredictionService.getCrowdCategory(currentLevel);
    final bestHours = CrowdPredictionService.getBestTravelHours(
      lineNumber: _selectedLine,
      weekday: weekday,
    );

    final lineColors = [AppColors.line1, AppColors.line2, AppColors.line3];
    final lineColor  = lineColors[_selectedLine - 1];
    final stationCount = MetroData.stations.values
        .where((s) => s.line == _selectedLine)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Crowd Prediction".tr()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "Line 1".tr()),
            Tab(text: "Line 2".tr()),
            Tab(text: "Line 3".tr()),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Operating hours banner ─────────────────────────────────────
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _buildOperatingHoursBanner(isAr, weekday, isOpen, currentHour),
            ),
            const SizedBox(height: 16),

            // ── Current status card ────────────────────────────────────────
            FadeInDown(
              delay: const Duration(milliseconds: 80),
              child: _buildCurrentStatusCard(
                  isAr, isOpen, currentCategory, currentLevel, lineColor, stationCount),
            ),
            const SizedBox(height: 20),

            // ── Hourly timeline ────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 120),
              child: Text(
                "Today's Crowd Forecast".tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 160),
              child: _buildHourlyTimeline(forecast, currentHour, lineColor, isAr),
            ),
            const SizedBox(height: 20),

            // ── Best travel times ──────────────────────────────────────────
            if (isOpen || bestHours.isNotEmpty)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildBestTimesCard(isAr, bestHours, lineColor),
              ),
            const SizedBox(height: 20),

            // ── Legend ─────────────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 240),
              child: _buildLegend(isAr),
            ),
            const SizedBox(height: 20),

            // ── Tips ───────────────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 280),
              child: _buildTipsCard(isAr, isOpen, currentCategory, weekday),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Operating hours banner ───────────────────────────────────────────────
  Widget _buildOperatingHoursBanner(bool isAr, int weekday, bool isOpen, int hour) {
    final closing = CrowdPredictionService.closingTime(weekday);
    final opening = CrowdPredictionService.openingTime();
    final closingHour = CrowdPredictionService.getLastServiceHour(weekday);

    // How many hours until next event?
    String subtitle;
    if (isOpen) {
      // Count hours until closing
      int hoursLeft;
      if (hour < closingHour) {
        hoursLeft = closingHour - hour;
      } else {
        // hour >= 5 and open, closing is tomorrow after midnight
        hoursLeft = (24 - hour) + closingHour;
      }
      subtitle = isAr
          ? 'يقفل الساعة $closing — باقي تقريباً $hoursLeft ساعة'
          : 'Closes at $closing — ~$hoursLeft hrs remaining';
    } else {
      subtitle = isAr
          ? 'يعمل من $opening حتى $closing'
          : 'Runs from $opening to $closing';
    }

    final bgColor = isOpen ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? Icons.train_rounded : Icons.bedtime_rounded,
              color: bgColor, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen
                      ? (isAr ? '🟢 المترو شغال دلوقتي' : '🟢 Metro is Operating Now')
                      : (isAr ? '🔴 المترو مقفل دلوقتي' : '🔴 Metro is Closed Now'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: bgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: bgColor.withOpacity(0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Current status card ──────────────────────────────────────────────────
  Widget _buildCurrentStatusCard(
    bool isAr,
    bool isOpen,
    CrowdLevel category,
    double level,
    Color lineColor,
    int stationCount,
  ) {
    if (!isOpen) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'المترو في وضع الراحة' : 'Metro Not in Service',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'بيشتغل من ${CrowdPredictionService.openingTime()} يومياً'
                        : 'Service starts at ${CrowdPredictionService.openingTime()} daily',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final emoji = CrowdPredictionService.getCrowdEmoji(category);
    final label = isAr
        ? (category == CrowdLevel.high
            ? 'ازدحام شديد'
            : category == CrowdLevel.moderate
                ? 'ازدحام متوسط'
                : 'هادي ومريح')
        : (category == CrowdLevel.high
            ? 'Heavily Crowded'
            : category == CrowdLevel.moderate
                ? 'Moderately Busy'
                : 'Calm & Comfortable');
    final categoryColor = category == CrowdLevel.high
        ? Colors.red
        : category == CrowdLevel.moderate
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lineColor.withOpacity(0.15), lineColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Status".tr(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: categoryColor),
                    ),
                    Text(
                      isAr
                          ? 'الخط $_selectedLine — $stationCount محطة'
                          : 'Line $_selectedLine — $stationCount stations',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64, height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: level,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(categoryColor),
                    ),
                    Text(
                      '${(level * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13, color: categoryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: level,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(categoryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hourly timeline ──────────────────────────────────────────────────────
  Widget _buildHourlyTimeline(
      List<HourlyCrowd> forecast, int currentHour, Color lineColor, bool isAr) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        controller: _hourScroll,
        scrollDirection: Axis.horizontal,
        itemCount: 24,
        itemBuilder: (context, i) {
          final h      = forecast[i];
          final isNow  = h.hour == currentHour;
          final closed = h.isClosed;

          final cat = closed
              ? CrowdLevel.low
              : CrowdPredictionService.getCrowdCategory(h.level);
          final barColor = closed
              ? Colors.grey[400]!
              : (cat == CrowdLevel.high
                  ? Colors.red
                  : cat == CrowdLevel.moderate
                      ? Colors.orange
                      : Colors.green);

          return Container(
            width: 60,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isNow
                  ? lineColor.withOpacity(0.15)
                  : (closed ? Colors.grey.withOpacity(0.04) : null),
              borderRadius: BorderRadius.circular(12),
              border: isNow
                  ? Border.all(color: lineColor, width: 2)
                  : (closed
                      ? Border.all(color: Colors.grey.withOpacity(0.15))
                      : null),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isNow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (closed)
                  const Text('💤', style: TextStyle(fontSize: 10))
                else
                  const SizedBox(height: 14),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: closed
                        // Hatched/dimmed bar to show metro is closed
                        ? Container(
                            width: 28,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : Container(
                            width: 28,
                            height: (h.level * 70).clamp(4, 70),
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(isNow ? 1.0 : 0.65),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                    color: closed
                        ? Colors.grey[400]
                        : isNow
                            ? lineColor
                            : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Best travel times ────────────────────────────────────────────────────
  Widget _buildBestTimesCard(bool isAr, List<int> hours, Color lineColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                "Best Travel Times Today".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          hours.isEmpty
              ? Text(
                  isAr ? 'المترو مش شغال النهارده في أوقات هادية' : 'No quiet hours available today',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: hours.map((h) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          const Text('😊', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            '${h.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────────────────
  Widget _buildLegend(bool isAr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(Colors.green, "Low".tr(), '< 45%'),
        _legendItem(Colors.orange, "Moderate".tr(), '45–75%'),
        _legendItem(Colors.red, "High".tr(), '> 75%'),
        _legendItem(Colors.grey, isAr ? 'مغلق' : 'Closed', isAr ? '💤' : '💤'),
      ],
    );
  }

  Widget _legendItem(Color color, String label, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(range,  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  // ── Tips ─────────────────────────────────────────────────────────────────
  Widget _buildTipsCard(bool isAr, bool isOpen, CrowdLevel category, int weekday) {
    List<String> tips;
    if (!isOpen) {
      tips = isAr
          ? [
              'المترو بيقفل الساعة ${CrowdPredictionService.closingTime(weekday)} 🌙',
              'بيفتح تاني الساعة ${CrowdPredictionService.openingTime()} كل يوم',
              'فكر تخطط رحلتك الجاية في الصبح الباكر لتجنب الزحمة',
            ]
          : [
              'Metro closes at ${CrowdPredictionService.closingTime(weekday)} 🌙',
              'Service resumes at ${CrowdPredictionService.openingTime()} daily',
              'Plan your next trip in the early morning to avoid crowds',
            ];
    } else if (category == CrowdLevel.high) {
      tips = isAr
          ? ['جرب تسافر من الخط 3 لو مناسب', 'فضّل العربية التانية أو التالتة', 'استخدم المدخل البديل في المحطة']
          : ['Try Line 3 if applicable', 'Prefer the 2nd or 3rd carriage', 'Use alternative station entrance'];
    } else if (category == CrowdLevel.moderate) {
      tips = isAr
          ? ['التوقيت معقول، استعد قبل وصول القطار', 'الخط 3 أخف زحمة عموماً', 'تجنب ساعات الذروة لو ممكن']
          : ['Timing is ok, board early', 'Line 3 is generally less crowded', 'Avoid peak hours if possible'];
    } else {
      tips = isAr
          ? ['وقت ممتاز للسفر! 🎉', 'استمتع بالرحلة المريحة', 'فرصة تستكشف المحطات الجديدة']
          : ['Perfect time to travel! 🎉', 'Enjoy a comfortable ride', 'Great chance to explore new stations'];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOpen ? Icons.lightbulb_outline : Icons.nightlight_round,
                color: isOpen ? Colors.amber : Colors.blueGrey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOpen ? "Current Tips".tr() : (isAr ? 'المترو مقفل' : 'Metro Closed'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(tip, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
