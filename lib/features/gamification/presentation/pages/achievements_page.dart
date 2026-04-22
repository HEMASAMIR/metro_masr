import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/gamification_service.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final points = GamificationService.getPoints();
    final trips = GamificationService.getTrips();
    final streak = GamificationService.getStreak();
    final badges = GamificationService.getAllBadges();
    final unlockedCount = badges.where((b) => b.isUnlocked).length;
    final level = isAr
        ? GamificationService.getCurrentLevel(points)
        : GamificationService.getCurrentLevelEn(points);
    final nextLevelPts = GamificationService.getNextLevelPoints(points);
    final progress = (points / nextLevelPts).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إنجازاتي' : 'My Achievements'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level card
            _buildLevelCard(isAr, points, level, progress, nextLevelPts),
            const SizedBox(height: 16),

            // Stats row
            _buildStatsRow(isAr, points, trips, streak, unlockedCount, badges.length),
            const SizedBox(height: 24),

            // Badges section
            Text(
              isAr ? 'الشارات والجوائز' : 'Badges & Awards',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isAr
                  ? '$unlockedCount من ${badges.length} شارة مفتوحة'
                  : '$unlockedCount of ${badges.length} badges unlocked',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: badges.length,
              itemBuilder: (context, i) => _buildBadgeCard(badges[i], isAr),
            ),
            const SizedBox(height: 24),

            // How to earn points
            _buildEarnPointsCard(isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(bool isAr, int points, String level, double progress, int nextPts) {
    final levelColors = {
      'برونزي': [const Color(0xFFCD7F32), const Color(0xFFB8693A)],
      'فضي': [const Color(0xFFC0C0C0), const Color(0xFF9A9A9A)],
      'ذهبي': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      'بلاتيني': [const Color(0xFFE5E4E2), const Color(0xFF9B9B9B)],
      'Bronze': [const Color(0xFFCD7F32), const Color(0xFFB8693A)],
      'Silver': [const Color(0xFFC0C0C0), const Color(0xFF9A9A9A)],
      'Gold': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      'Platinum': [const Color(0xFFE5E4E2), const Color(0xFF9B9B9B)],
    };
    final colors = levelColors[level] ?? [AppColors.primary, AppColors.accent];
    final levelEmoji = level.contains('بلاتيني') || level == 'Platinum'
        ? '💎'
        : level.contains('ذهبي') || level == 'Gold'
            ? '🥇'
            : level.contains('فضي') || level == 'Silver'
                ? '🥈'
                : '🥉';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors.map((c) => c.withOpacity(0.2)).toList()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[0].withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(levelEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مستواك' : 'Your Level',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = LinearGradient(colors: colors)
                              .createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                      ),
                    ),
                    Text(
                      isAr ? '$points نقطة' : '$points pts',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(colors[0]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$nextPts pts',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isAr, int points, int trips, int streak, int badges, int total) {
    return Row(
      children: [
        _statCard(isAr ? 'نقاط' : 'Points', '$points', '⭐', AppColors.primary),
        const SizedBox(width: 8),
        _statCard(isAr ? 'رحلات' : 'Trips', '$trips', '🚇', AppColors.line2),
        const SizedBox(width: 8),
        _statCard(isAr ? 'يوم متتالي' : 'Day Streak', '$streak', '🔥', Colors.orange),
        const SizedBox(width: 8),
        _statCard(isAr ? 'شارات' : 'Badges', '$badges/$total', '🏅', Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, String emoji, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(MetroBadge badge, bool isAr) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, isAr),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isUnlocked
                ? AppColors.primary.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            width: badge.isUnlocked ? 1.5 : 1,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: badge.isUnlocked ? null : Colors.grey,
                  ),
                ),
                if (!badge.isUnlocked)
                  Text('🔒',
                      style: TextStyle(
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 4)
                          ])),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? badge.nameAr : badge.nameEn,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked ? null : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(MetroBadge badge, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              isAr ? badge.nameAr : badge.nameEn,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? badge.descAr : badge.descEn,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.isUnlocked
                    ? (isAr ? '✅ مفتوحة!' : '✅ Unlocked!')
                    : (isAr ? '🔒 لم تُفتح بعد' : '🔒 Not yet unlocked'),
                style: TextStyle(
                  color: badge.isUnlocked ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnPointsCard(bool isAr) {
    final items = isAr
        ? [
            ('🚇', 'سجّل رحلة', '+50 نقطة'),
            ('🗺️', 'خطط مسار', '+20 نقطة'),
            ('📢', 'أبلغ عن حادثة', '+30 نقطة'),
            ('📅', 'جدول رحلة', '+15 نقطة'),
            ('🤖', 'اسأل الذكاء الاصطناعي', '+5 نقاط'),
            ('📊', 'تحقق من الازدحام', '+10 نقاط'),
            ('💳', 'استخدم محفظة NFC', '+25 نقطة'),
          ]
        : [
            ('🚇', 'Record a trip', '+50 pts'),
            ('🗺️', 'Plan a route', '+20 pts'),
            ('📢', 'Report an incident', '+30 pts'),
            ('📅', 'Schedule a trip', '+15 pts'),
            ('🤖', 'Ask AI', '+5 pts'),
            ('📊', 'Check crowd levels', '+10 pts'),
            ('💳', 'Use NFC wallet', '+25 pts'),
          ];

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
              const Icon(Icons.stars, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'كيف تكسب نقاطاً' : 'How to Earn Points',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.$2, style: const TextStyle(fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.$3,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
