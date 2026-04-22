import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    // Scroll to current hour after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentHour());
  }

  void _scrollToCurrentHour() {
    final hour = DateTime.now().hour;
    if (_hourScroll.hasClients) {
      _hourScroll.animateTo(
        (hour * 68.0).clamp(0, _hourScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
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
    final isAr = context.locale.languageCode == 'ar';
    final now = DateTime.now();
    final weekday = now.weekday;
    final currentHour = now.hour;
    final forecast = CrowdPredictionService.getDailyForecast(
      lineNumber: _selectedLine,
      weekday: weekday,
    );
    final currentLevel = CrowdPredictionService.getCrowdLevel(
      hour: currentHour,
      weekday: weekday,
      lineNumber: _selectedLine,
    );
    final currentCategory = CrowdPredictionService.getCrowdCategory(currentLevel);
    final bestHours = CrowdPredictionService.getBestTravelHours(
      lineNumber: _selectedLine,
      weekday: weekday,
    );

    final lineColors = [AppColors.line1, AppColors.line2, AppColors.line3];
    final lineColor = lineColors[_selectedLine - 1];
    final stationCount = MetroData.stations.values
        .where((s) => s.line == _selectedLine)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'توقع الازدحام' : 'Crowd Prediction'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: isAr ? 'الخط الأول' : 'Line 1'),
            Tab(text: isAr ? 'الخط الثاني' : 'Line 2'),
            Tab(text: isAr ? 'الخط الثالث' : 'Line 3'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status card
            _buildCurrentStatusCard(isAr, currentCategory, currentLevel, lineColor, stationCount),
            const SizedBox(height: 20),

            // Hourly timeline
            Text(
              isAr ? 'توقع الازدحام خلال اليوم' : "Today's Crowd Forecast",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHourlyTimeline(forecast, currentHour, lineColor),
            const SizedBox(height: 20),

            // Best travel times
            _buildBestTimesCard(isAr, bestHours, lineColor),
            const SizedBox(height: 20),

            // Crowd level legend
            _buildLegend(isAr),
            const SizedBox(height: 20),

            // Tips
            _buildTipsCard(isAr, currentCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(
    bool isAr,
    CrowdLevel category,
    double level,
    Color lineColor,
    int stationCount,
  ) {
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
                      isAr ? 'الحالة الآن' : 'Current Status',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
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
              // Circular level indicator
              SizedBox(
                width: 64,
                height: 64,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: categoryColor,
                      ),
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

  Widget _buildHourlyTimeline(List<HourlyCrowd> forecast, int currentHour, Color lineColor) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: _hourScroll,
        scrollDirection: Axis.horizontal,
        itemCount: 24,
        itemBuilder: (context, i) {
          final h = forecast[i];
          final isNow = h.hour == currentHour;
          final cat = CrowdPredictionService.getCrowdCategory(h.level);
          final barColor = cat == CrowdLevel.high
              ? Colors.red
              : cat == CrowdLevel.moderate
                  ? Colors.orange
                  : Colors.green;

          return Container(
            width: 56,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isNow ? lineColor.withOpacity(0.15) : null,
              borderRadius: BorderRadius.circular(12),
              border: isNow ? Border.all(color: lineColor, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isNow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 28,
                      height: (h.level * 70).clamp(4, 70),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(isNow ? 1.0 : 0.6),
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
                    color: isNow ? lineColor : Colors.grey[600],
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
                isAr ? 'أفضل أوقات السفر اليوم' : 'Best Travel Times Today',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
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

  Widget _buildLegend(bool isAr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(Colors.green, isAr ? 'هادي' : 'Low', isAr ? '< 45%' : '< 45%'),
        _legendItem(Colors.orange, isAr ? 'متوسط' : 'Moderate', '45–75%'),
        _legendItem(Colors.red, isAr ? 'مزدحم' : 'High', '> 75%'),
      ],
    );
  }

  Widget _legendItem(Color color, String label, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(range, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  Widget _buildTipsCard(bool isAr, CrowdLevel category) {
    final tips = category == CrowdLevel.high
        ? (isAr
            ? ['جرب تسافر من الخط 3 لو مناسب', 'فضّل العربية التانية أو التالتة', 'استخدم المدخل البديل في المحطة']
            : ['Try Line 3 if applicable', 'Prefer the 2nd or 3rd carriage', 'Use alternative station entrance'])
        : category == CrowdLevel.moderate
            ? (isAr
                ? ['التوقيت معقول، استعد قبل وصول القطار', 'الخط 3 أخف زحمة عموماً', 'تجنب ساعات الذروة لو ممكن']
                : ['Timing is ok, board early', 'Line 3 is generally less crowded', 'Avoid peak hours if possible'])
            : (isAr
                ? ['وقت ممتاز للسفر! 🎉', 'استمتع بالرحلة المريحة', 'فرصة تستكشف المحطات الجديدة']
                : ['Perfect time to travel! 🎉', 'Enjoy a comfortable ride', 'Great chance to explore new stations']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'نصائح الآن' : 'Current Tips',
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
                    Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
