import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/utils/egypt_time.dart';

/// Feature #2: Smart Dashboard — shows metro open/closed, crowd level, per-line bars
class SmartDashboardCard extends StatelessWidget {
  const SmartDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = EgyptTime.getEgyptTime();
    final weekday = now.weekday;
    final hour = now.hour;
    final isAr = context.locale.languageCode == 'ar';
    final isOpen = CrowdPredictionService.isMetroOpen(hour: hour, weekday: weekday);

    // Get crowd for all 3 lines, pick max for general indicator
    double maxCrowd = 0;
    if (isOpen) {
      final c1 = CrowdPredictionService.getCrowdLevel(hour: hour, weekday: weekday, lineNumber: 1);
      final c2 = CrowdPredictionService.getCrowdLevel(hour: hour, weekday: weekday, lineNumber: 2);
      final c3 = CrowdPredictionService.getCrowdLevel(hour: hour, weekday: weekday, lineNumber: 3);
      maxCrowd = [c1, c2, c3].reduce((a, b) => a > b ? a : b);
    }
    final crowdCat = CrowdPredictionService.getCrowdCategory(maxCrowd);
    final crowdEmoji = CrowdPredictionService.getCrowdEmoji(crowdCat);
    final crowdColor = crowdCat == CrowdLevel.high
        ? Colors.red
        : crowdCat == CrowdLevel.moderate
            ? Colors.orange
            : Colors.green;
    final crowdLabel = isAr
        ? (crowdCat == CrowdLevel.high ? 'زحمة شديدة' : crowdCat == CrowdLevel.moderate ? 'متوسط' : 'هادي')
        : (crowdCat == CrowdLevel.high ? 'Crowded' : crowdCat == CrowdLevel.moderate ? 'Moderate' : 'Calm');

    final closingHour = CrowdPredictionService.getLastServiceHour(weekday);
    int hoursLeft = 0;
    if (isOpen) {
      hoursLeft = hour < closingHour ? closingHour - hour : (24 - hour) + closingHour;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [const Color(0xFF0D47A1), const Color(0xFF1565C0)]
              : [const Color(0xFF37474F), const Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? const Color(0xFF1565C0) : Colors.grey).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Metro status icon
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isOpen ? Icons.train_rounded : Icons.bedtime_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.greenAccent : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen
                              ? (isAr ? 'المترو شغال' : 'Metro Operating')
                              : (isAr ? 'المترو مقفل' : 'Metro Closed'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOpen
                          ? (isAr ? 'باقي ~$hoursLeft ساعة للإغلاق' : '~$hoursLeft hrs until close')
                          : (isAr ? 'يفتح الساعة 5:00 ص' : 'Opens at 5:00 AM'),
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Crowd mini-badge
              if (isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: crowdColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: crowdColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(crowdEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        crowdLabel,
                        style: TextStyle(color: crowdColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isOpen) ...[
            const SizedBox(height: 14),
            // Per-line crowd bars
            Row(
              children: List.generate(3, (i) {
                final lineNum = i + 1;
                final level = CrowdPredictionService.getCrowdLevel(
                  hour: hour, weekday: weekday, lineNumber: lineNum,
                );
                final cat = CrowdPredictionService.getCrowdCategory(level);
                final c = cat == CrowdLevel.high
                    ? Colors.redAccent
                    : cat == CrowdLevel.moderate
                        ? Colors.orangeAccent
                        : Colors.greenAccent;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'خط $lineNum' : 'L$lineNum',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(level * 100).toInt()}%',
                              style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: level.clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(c),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
