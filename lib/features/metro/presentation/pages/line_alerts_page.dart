import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/crowd_prediction_service.dart';

/// Full-featured Line Alerts subscription & live-delay notification manager.
/// Persists user subscriptions via SharedPreferences.
/// Simulates live delay monitoring with periodic checks & local notifications.
class LineAlertsPage extends StatefulWidget {
  const LineAlertsPage({super.key});

  @override
  State<LineAlertsPage> createState() => _LineAlertsPageState();
}

class _LineAlertsPageState extends State<LineAlertsPage>
    with SingleTickerProviderStateMixin {
  // Subscribed lines (true = subscribed)
  final Map<int, bool> _subscribed = {1: false, 2: false, 3: false};

  // Alert types
  bool _alertDelays     = true;
  bool _alertCrowd      = true;
  bool _alertMaintenance = true;

  // Quiet hours
  TimeOfDay _quietStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _quietEnd   = const TimeOfDay(hour: 6,  minute: 0);
  bool _quietHoursEnabled = false;

  Timer? _monitorTimer;
  final Map<int, String> _liveStatus = {1: 'checking', 2: 'checking', 3: 'checking'};

  static const _prefsKey = 'line_alert_subscriptions';

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadPrefs();
    _startMonitor();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      for (int i = 1; i <= 3; i++) {
        _subscribed[i] = saved.contains('$i');
      }
      _alertDelays      = prefs.getBool('alert_delays')  ?? true;
      _alertCrowd       = prefs.getBool('alert_crowd')   ?? true;
      _alertMaintenance = prefs.getBool('alert_maint')   ?? true;
      _quietHoursEnabled = prefs.getBool('quiet_enabled') ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final active = _subscribed.entries.where((e) => e.value).map((e) => '${e.key}').toList();
    await prefs.setStringList(_prefsKey, active);
    await prefs.setBool('alert_delays',  _alertDelays);
    await prefs.setBool('alert_crowd',   _alertCrowd);
    await prefs.setBool('alert_maint',   _alertMaintenance);
    await prefs.setBool('quiet_enabled', _quietHoursEnabled);
  }

  // ── Live monitor ──────────────────────────────────────────────────────────
  void _startMonitor() {
    _checkAllLines();
    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkAllLines());
  }

  Future<void> _checkAllLines() async {
    final now = DateTime.now();
    for (int line = 1; line <= 3; line++) {
      final level = CrowdPredictionService.getCrowdLevel(
          hour: now.hour, weekday: now.weekday, lineNumber: line);
      final cat = CrowdPredictionService.getCrowdCategory(level);

      // Derive delay simulation from crowd
      String status;
      int delayMins = 0;
      if (cat == CrowdLevel.high) {
        delayMins = 5 + (line * 2);
        status = 'delay';
      } else if (cat == CrowdLevel.moderate) {
        status = 'normal';
      } else {
        status = 'good';
      }

      if (mounted) setState(() => _liveStatus[line] = status);

      // Send notification if subscribed and delay detected
      if (_subscribed[line] == true && status == 'delay' && _alertDelays) {
        if (!_isQuietHour()) {
          await NotificationService.showLineDelayAlert(
            lineNumber: line,
            delayMinutes: delayMins,
            isArabic: context.locale.languageCode == 'ar',
          );
        }
      }
    }
  }

  bool _isQuietHour() {
    if (!_quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;
    final startMins = _quietStart.hour * 60 + _quietStart.minute;
    final endMins = _quietEnd.hour * 60 + _quietEnd.minute;
    if (startMins > endMins) {
      return nowMins >= startMins || nowMins <= endMins;
    }
    return nowMins >= startMins && nowMins <= endMins;
  }

  // ── Toggle subscription ───────────────────────────────────────────────────
  void _toggleLine(int line) {
    setState(() => _subscribed[line] = !(_subscribed[line] ?? false));
    _savePrefs();

    final isAr = context.locale.languageCode == 'ar';
    final on = _subscribed[line] ?? false;
    if (on) {
      NotificationService.showNotification(
        id: 30 + line,
        title: isAr ? '✅ تم تفعيل تنبيهات الخط $line' : '✅ Line $line Alerts ON',
        body: isAr
            ? 'هتتبعت نوتيفيكيشن لو فيه تأخير أو ازدحام في الخط $line'
            : 'You\'ll be notified of delays & crowd on Line $line',
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _lineColor(int line) =>
      line == 1 ? AppColors.line1 : line == 2 ? AppColors.line2 : AppColors.line3;

  String _lineName(int line, bool isAr) =>
      isAr ? 'الخط $line' : 'Line $line';

  Widget _statusBadge(int line, bool isAr) {
    final s = _liveStatus[line] ?? 'checking';
    Color color;
    String label;
    IconData icon;
    switch (s) {
      case 'delay':
        color = Colors.red; label = "Delay".tr(); icon = Icons.warning_rounded;
        break;
      case 'good':
        color = Colors.green; label = "Clear".tr(); icon = Icons.check_circle;
        break;
      case 'normal':
        color = Colors.orange; label = "Normal".tr(); icon = Icons.info_rounded;
        break;
      default:
        color = Colors.grey; label = "Checking".tr(); icon = Icons.refresh;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ─────────────────────────────────── UI ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("🔔 Line Alerts".tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Opacity(
                opacity: 0.5 + _pulseCtrl.value * 0.5,
                child: child,
              ),
              child: const Row(children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1565C0)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "Subscribe to Line Alerts".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Get instant push notifications for delays & crowd on your lines".tr(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Line cards ────────────────────────────────────────────────
            Text("Select your lines:".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

            ...List.generate(3, (i) {
              final line = i + 1;
              final sub = _subscribed[line] ?? false;
              final color = _lineColor(line);
              return FadeInLeft(
                delay: Duration(milliseconds: i * 80),
                child: GestureDetector(
                  onTap: () => _toggleLine(line),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: sub ? color.withOpacity(0.08) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: sub ? color : Colors.grey.withOpacity(0.2),
                        width: sub ? 2 : 1,
                      ),
                      boxShadow: sub ? [
                        BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                      ] : [],
                    ),
                    child: Row(
                      children: [
                        // Line circle
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$line',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_lineName(line, isAr),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                                    color: sub ? color : null)),
                              const SizedBox(height: 4),
                              _statusBadge(line, isAr),
                            ],
                          ),
                        ),
                        // Toggle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 52, height: 28,
                          decoration: BoxDecoration(
                            color: sub ? color : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            alignment: sub ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 24, height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ── Alert types ───────────────────────────────────────────────
            Text("Alert Types:".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    _alertTile(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                      title: "Train Delays".tr(),
                      subtitle: "Notify when trains are delayed".tr(),
                      value: _alertDelays,
                      onChanged: (v) { setState(() => _alertDelays = v); _savePrefs(); },
                    ),
                    const Divider(height: 1, indent: 16),
                    _alertTile(
                      icon: Icons.people_rounded,
                      color: Colors.purple,
                      title: "Station Crowd".tr(),
                      subtitle: "Alert when crowd is high on your line".tr(),
                      value: _alertCrowd,
                      onChanged: (v) { setState(() => _alertCrowd = v); _savePrefs(); },
                    ),
                    const Divider(height: 1, indent: 16),
                    _alertTile(
                      icon: Icons.build_rounded,
                      color: Colors.blue,
                      title: "Maintenance".tr(),
                      subtitle: "Station closures & maintenance alerts".tr(),
                      value: _alertMaintenance,
                      onChanged: (v) { setState(() => _alertMaintenance = v); _savePrefs(); },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Quiet hours ───────────────────────────────────────────────
            Text("Quiet Hours:".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Do Not Disturb".tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("Silence alerts during sleep hours".tr(),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _quietHoursEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) { setState(() => _quietHoursEnabled = v); _savePrefs(); },
                        ),
                      ],
                    ),
                    if (_quietHoursEnabled) ...[ 
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _timePicker(
                              label: "From".tr(),
                              time: _quietStart,
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: _quietStart);
                                if (t != null) { setState(() => _quietStart = t); _savePrefs(); }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timePicker(
                              label: "To".tr(),
                              time: _quietEnd,
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: _quietEnd);
                                if (t != null) { setState(() => _quietEnd = t); _savePrefs(); }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }

  Widget _alertTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, activeTrackColor: color, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _timePicker({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(time.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
