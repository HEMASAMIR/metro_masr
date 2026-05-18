import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/responsive.dart';

class LastTrainAlarmPage extends StatefulWidget {
  const LastTrainAlarmPage({super.key});

  @override
  State<LastTrainAlarmPage> createState() => _LastTrainAlarmPageState();
}

class _LastTrainAlarmPageState extends State<LastTrainAlarmPage> {
  String? _selectedStationId;
  bool _isAlarmSet = false;

  void _setAlarm() {
    if (_selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locale.languageCode == 'ar' ? 'اختار المحطة أولاً' : 'Please choose a station first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isAlarmSet = true);

    // Simulate scheduling a notification (10 seconds for demo)
    Future.delayed(const Duration(seconds: 10), () {
      final station = MetroData.stations[_selectedStationId];
      final isAr = context.locale.languageCode == 'ar';
      final sName = isAr ? station?.nameAr : station?.nameEn;

      NotificationService.showNotification(
        id: 99,
        title: '⏰ Last Train Alert!'.tr(),
        body: isAr 
            ? 'آخر قطار هيتحرك من محطة $sName كمان 30 دقيقة. اتحرك فوراً!'
            : 'The last train leaves $sName in 30 mins. Move now!',
      );

      if (mounted) {
        setState(() => _isAlarmSet = false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(context.locale.languageCode == 'ar' ? 'تم ضبط المنبه! (للتجربة هيضرب بعد 10 ثواني)' : 'Alarm set! (Will ring in 10s for testing)')),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isAr = context.locale.languageCode == 'ar';
    final stations = MetroData.stations.values.toList();

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
            FadeInDown(
              child: Image.network(
                'https://cdn3d.iconscout.com/3d/premium/thumb/alarm-clock-4996135-4161049.png',
                height: 150,
                errorBuilder: (context, _, __) => const Icon(Icons.alarm, size: 100, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              child: Text(
                "Don't miss the last train!".tr(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Select your departure station and we will remind you 30 minutes before it closes.'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Station?'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStationId,
                          hint: Text('Select station...'.tr()),
                          isExpanded: true,
                          items: stations.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(isAr ? s.nameAr : s.nameEn),
                            );
                          }).toList(),
                          onChanged: _isAlarmSet ? null : (v) => setState(() => _selectedStationId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAlarmSet ? AppColors.error : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(_isAlarmSet ? Icons.cancel : Icons.alarm_add),
                        label: Text(
                          _isAlarmSet 
                              ? ('Cancel Alarm'.tr())
                              : ('Set Alarm'.tr()),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (_isAlarmSet) {
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
          ],
        ),
      ),
    );
  }
}
