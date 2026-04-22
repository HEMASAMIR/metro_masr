import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/gamification_service.dart';
import '../../../gamification/presentation/pages/achievements_page.dart';
import '../../../splash/presentation/onboarding_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _crowdAlerts = true;
  bool _tripReminders = true;
  String _selectedLang = 'ar';
  int _points = 0;
  int _trips = 0;
  String _level = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await GamificationService.init();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _crowdAlerts = prefs.getBool('crowd_alerts') ?? true;
      _tripReminders = prefs.getBool('trip_reminders') ?? true;
      _selectedLang = context.locale.languageCode;
      _points = GamificationService.getPoints();
      _trips = GamificationService.getTrips();
      _level = GamificationService.getCurrentLevel(_points);
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _changeLanguage(String lang) {
    context.setLocale(Locale(lang));
    setState(() => _selectedLang = lang);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final isAr = _selectedLang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile / Stats card ──────────────────────────────────────────
          _buildProfileCard(isAr),
          const SizedBox(height: 20),

          // ── Appearance ────────────────────────────────────────────────────
          _sectionLabel(isAr ? 'المظهر' : 'Appearance'),
          _buildAppearanceCard(context, isDark, isAr),
          const SizedBox(height: 20),

          // ── Language ──────────────────────────────────────────────────────
          _sectionLabel(isAr ? 'اللغة' : 'Language'),
          _buildLanguageCard(isAr),
          const SizedBox(height: 20),

          // ── Notifications ─────────────────────────────────────────────────
          _sectionLabel(isAr ? 'الإشعارات' : 'Notifications'),
          _buildNotificationsCard(isAr),
          const SizedBox(height: 20),

          // ── Account ───────────────────────────────────────────────────────
          _sectionLabel(isAr ? 'الحساب' : 'Account'),
          _buildAccountCard(isAr),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _sectionLabel(isAr ? 'عن التطبيق' : 'About'),
          _buildAboutCard(isAr),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Profile card ────────────────────────────────────────────────────────────
  Widget _buildProfileCard(bool isAr) {
    final nextPts = GamificationService.getNextLevelPoints(_points);
    final progress = (_points / nextPts).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementsPage()),
      ).then((_) => _loadSettings()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF4F8AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _level,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr ? '$_points نقطة • $_trips رحلة' : '$_points pts • $_trips trips',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isAr ? 'التقدم للمستوى التالي' : 'Progress to next level',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Appearance card ─────────────────────────────────────────────────────────
  Widget _buildAppearanceCard(BuildContext context, bool isDark, bool isAr) {
    return _card([
      _settingRow(
        icon: isDark ? Icons.dark_mode : Icons.light_mode,
        iconColor: isDark ? const Color(0xFF8899CC) : const Color(0xFFFFB800),
        title: isAr ? 'الوضع الليلي' : 'Dark Mode',
        subtitle: isDark ? (isAr ? 'مفعّل' : 'Enabled') : (isAr ? 'معطّل' : 'Disabled'),
        trailing: Switch(
          value: isDark,
          activeColor: AppColors.primary,
          onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
        ),
      ),
    ]);
  }

  // ── Language card ───────────────────────────────────────────────────────────
  Widget _buildLanguageCard(bool isAr) {
    final langs = [
      ('ar', '🇪🇬', 'العربية'),
      ('en', '🇺🇸', 'English'),
      ('fr', '🇫🇷', 'Français'),
      ('de', '🇩🇪', 'Deutsch'),
    ];

    return _card([
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: langs.map((l) {
          final isSelected = _selectedLang == l.$1;
          return GestureDetector(
            onTap: () => _changeLanguage(l.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    l.$3,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  // ── Notifications card ──────────────────────────────────────────────────────
  Widget _buildNotificationsCard(bool isAr) {
    return _card([
      _settingRow(
        icon: Icons.notifications_outlined,
        iconColor: AppColors.primary,
        title: isAr ? 'الإشعارات العامة' : 'General Notifications',
        subtitle: isAr ? 'تنبيهات التطبيق الأساسية' : 'Core app alerts',
        trailing: Switch(
          value: _notificationsEnabled,
          activeColor: AppColors.primary,
          onChanged: (v) {
            setState(() => _notificationsEnabled = v);
            _saveSetting('notifications_enabled', v);
          },
        ),
      ),
      const Divider(height: 1),
      _settingRow(
        icon: Icons.people_outline,
        iconColor: Colors.teal,
        title: isAr ? 'تنبيهات الازدحام' : 'Crowd Alerts',
        subtitle: isAr ? 'تحذير عند ازدحام شديد' : 'Alert on heavy crowd',
        trailing: Switch(
          value: _crowdAlerts && _notificationsEnabled,
          activeColor: AppColors.primary,
          onChanged: _notificationsEnabled
              ? (v) {
                  setState(() => _crowdAlerts = v);
                  _saveSetting('crowd_alerts', v);
                }
              : null,
        ),
      ),
      const Divider(height: 1),
      _settingRow(
        icon: Icons.calendar_month_outlined,
        iconColor: Colors.indigo,
        title: isAr ? 'تذكيرات الرحلات' : 'Trip Reminders',
        subtitle: isAr ? 'تذكير قبل رحلتك المجدولة' : 'Remind before scheduled trip',
        trailing: Switch(
          value: _tripReminders && _notificationsEnabled,
          activeColor: AppColors.primary,
          onChanged: _notificationsEnabled
              ? (v) {
                  setState(() => _tripReminders = v);
                  _saveSetting('trip_reminders', v);
                }
              : null,
        ),
      ),
    ]);
  }

  // ── Account card ────────────────────────────────────────────────────────────
  Widget _buildAccountCard(bool isAr) {
    return _card([
      _tileRow(
        icon: Icons.restart_alt_rounded,
        iconColor: Colors.orange,
        title: isAr ? 'إعادة تعيين الإنجازات' : 'Reset Achievements',
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isAr ? 'تأكيد الحذف' : 'Confirm Reset'),
              content: Text(isAr
                  ? 'هيتم مسح كل نقاطك وشاراتك. هل متأكد؟'
                  : 'All your points and badges will be erased. Are you sure?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'لأ' : 'Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(isAr ? 'امسح' : 'Reset', style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await GamificationService.reset();
            await _loadSettings();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isAr ? '✅ تم إعادة التعيين' : '✅ Reset done'),
            ));
          }
        },
      ),
      const Divider(height: 1),
      _tileRow(
        icon: Icons.replay_rounded,
        iconColor: Colors.blue,
        title: isAr ? 'إعادة عرض الترحيب' : 'Show Onboarding Again',
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        },
      ),
    ]);
  }

  // ── About card ──────────────────────────────────────────────────────────────
  Widget _buildAboutCard(bool isAr) {
    return _card([
      _tileRow(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primary,
        title: isAr ? 'رفيق المترو — الإصدار 2.0' : 'Rafiq Metro — Version 2.0',
        subtitle: isAr ? 'مشروع تخرج 2024' : 'Graduation Project 2024',
      ),
      const Divider(height: 1),
      _tileRow(
        icon: Icons.train_rounded,
        iconColor: AppColors.line1,
        title: isAr ? '3 خطوط • 85 محطة' : '3 Lines • 85 Stations',
        subtitle: isAr ? 'مترو أنفاق القاهرة' : 'Cairo Metro Network',
      ),
    ]);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(children: children),
      );

  Widget _settingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _tileRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _settingRow(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          trailing: onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey[400], size: 20)
              : null,
        ),
      );
}
