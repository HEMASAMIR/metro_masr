import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/crowd_prediction_service.dart';
import '../../../../core/utils/egypt_time.dart';

class LastTrainAlarmPage extends StatefulWidget {
  const LastTrainAlarmPage({super.key});

  @override
  State<LastTrainAlarmPage> createState() => _LastTrainAlarmPageState();
}

class _LastTrainAlarmPageState extends State<LastTrainAlarmPage>
    with SingleTickerProviderStateMixin {
  String? _selectedStationId;
  bool _isAlarmSet = false;
  int _reminderMinutes = 30;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setAlarm() {
    if (_selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locale.languageCode == 'ar' ? 'اختار المحطة أولاً' : 'Please choose a station first'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isAlarmSet = true);
    _pulseController.repeat(reverse: true);

    // Simulate scheduling a notification
    Future.delayed(Duration(seconds: _reminderMinutes == 30 ? 10 : 5), () {
      final station = MetroData.stations[_selectedStationId];
      final isAr = context.locale.languageCode == 'ar';
      final sName = isAr ? station?.nameAr : station?.nameEn;

      NotificationService.showNotification(
        id: 99,
        title: '⏰ Last Train Alert!'.tr(),
        body: isAr
            ? 'آخر قطار هيتحرك من محطة $sName كمان $_reminderMinutes دقيقة. اتحرك فوراً!'
            : 'The last train leaves $sName in $_reminderMinutes mins. Move now!',
      );

      if (mounted) {
        _pulseController.stop();
        setState(() => _isAlarmSet = false);
      }
    });

    final isAr = context.locale.languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(isAr
                  ? 'تم ضبط المنبه! هننبهك قبل آخر قطار بـ $_reminderMinutes دقيقة'
                  : 'Alarm set! We\'ll remind you $_reminderMinutes min before last train'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isAr = context.locale.languageCode == 'ar';
    final stations = MetroData.stations.values.toList();
    final now = EgyptTime.getEgyptTime();
    final weekday = now.weekday;
    final hour = now.hour;
    final isOpen = CrowdPredictionService.isMetroOpen(hour: hour, weekday: weekday);
    final closingTime = CrowdPredictionService.closingTime(weekday);
    final closingHour = CrowdPredictionService.getLastServiceHour(weekday);

    // Calculate hours left until close
    int hoursLeft = 0;
    if (isOpen) {
      hoursLeft = hour < closingHour ? closingHour - hour : (24 - hour) + closingHour;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Last Train Alarm ⏰'.tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.pagePadding),
        child: Column(
          children: [
            // ── Status Banner ──────────────────────────────────────────────
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOpen
                        ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                        : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isOpen ? Icons.train_rounded : Icons.nightlight_round,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOpen
                                ? (isAr ? '🟢 المترو شغال دلوقتي' : '🟢 Metro is Running')
                                : (isAr ? '🔴 المترو مقفل' : '🔴 Metro is Closed'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOpen
                                ? (isAr
                                    ? 'يقفل الساعة $closingTime — باقي ~$hoursLeft ساعة'
                                    : 'Closes at $closingTime — ~$hoursLeft hrs left')
                                : (isAr
                                    ? 'يفتح تاني الساعة 5:00 ص'
                                    : 'Opens again at 5:00 AM'),
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Alarm Icon ─────────────────────────────────────────────────
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _isAlarmSet ? 1.0 + 0.1 * _pulseController.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isAlarmSet
                              ? [Colors.red, Colors.redAccent]
                              : [AppColors.primary, const Color(0xFF42A5F5)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isAlarmSet ? Colors.red : AppColors.primary).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: _isAlarmSet ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isAlarmSet ? Icons.alarm_on : Icons.alarm_add_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            FadeInUp(
              child: Text(
                "Don't miss the last train!".tr(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Text(
                isAr
                    ? 'اختار محطتك وهننبهك قبل آخر قطار بالوقت اللي تحدده'
                    : 'Select your station and we\'ll remind you before the last train',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // ── Config Card ────────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station selector
                    Text(
                      isAr ? '🚇 محطة المغادرة' : '🚇 Departure Station',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.primary.withOpacity(0.04),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStationId,
                          hint: Text(isAr ? 'اختار المحطة...' : 'Select station...'),
                          isExpanded: true,
                          items: stations.map((s) {
                            final lineColor = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isAr ? s.nameAr : s.nameEn),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isAlarmSet ? null : (v) => setState(() => _selectedStationId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reminder time selector
                    Text(
                      isAr ? '⏱ نبهني قبل آخر قطار بـ' : '⏱ Remind me before last train',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [15, 30, 45, 60].map((mins) {
                        final selected = _reminderMinutes == mins;
                        return Expanded(
                          child: GestureDetector(
                            onTap: _isAlarmSet ? null : () {
                              HapticFeedback.selectionClick();
                              setState(() => _reminderMinutes = mins);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$mins',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: selected ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    isAr ? 'دقيقة' : 'min',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: selected ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Set / Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAlarmSet ? AppColors.error : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: _isAlarmSet ? 0 : 2,
                        ),
                        icon: Icon(_isAlarmSet ? Icons.cancel_rounded : Icons.alarm_add_rounded),
                        label: Text(
                          _isAlarmSet
                              ? (isAr ? 'إلغاء المنبه' : 'Cancel Alarm')
                              : (isAr ? 'ضبط المنبه' : 'Set Alarm'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (_isAlarmSet) {
                            HapticFeedback.lightImpact();
                            _pulseController.stop();
                            setState(() => _isAlarmSet = false);
                          } else {
                            _setAlarm();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Info card ──────────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'معلومة مهمة' : 'Good to Know',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? '• المترو بيشتغل من 5:00 ص لحد $closingTime\n'
                            '• يوم الجمعة بيقفل الساعة 2:00 ص\n'
                            '• آخر قطار بيتحرك قبل الإغلاق بحوالي 30 دقيقة'
                          : '• Metro operates from 5:00 AM to $closingTime\n'
                            '• On Fridays, closes at 2:00 AM\n'
                            '• Last train departs ~30 min before closing',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
