import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Leaderboard Data
    final topThree = [
      {'name': 'أحمد حسن', 'points': 8400, 'avatar': '👨'},
      {'name': 'سلمى فريد', 'points': 9200, 'avatar': '👧'}, // #1
      {'name': 'عمر خالد', 'points': 7800, 'avatar': '👦'},
    ];
    final others = [
      {'rank': 4, 'name': 'منى ياسر', 'points': 7100, 'avatar': '👩'},
      {'rank': 5, 'name': 'كريم شوقي', 'points': 6500, 'avatar': '🧑'},
      {'rank': 6, 'name': 'ياسين علي', 'points': 5900, 'avatar': '👨'},
      {'rank': 7, 'name': 'أنت', 'points': 5400, 'avatar': '😎', 'isMe': true},
      {'rank': 8, 'name': 'هدى محمود', 'points': 4800, 'avatar': '👧'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Podium ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPodiumUser(topThree[0], 2, 100, const Color(0xFFC0C0C0)), // Silver
                  _buildPodiumUser(topThree[1], 1, 140, const Color(0xFFFFD700), isFirst: true), // Gold
                  _buildPodiumUser(topThree[2], 3, 80, const Color(0xFFCD7F32)), // Bronze
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Today's Challenge Banner ────────────────────────────
            FadeInUp(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: AppColors.accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.locale.languageCode == 'ar' ? 'ينقصك 500 نقطة لتصل للفضية 🚀' : '500 points to reach Silver 🚀',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── List ────────────────────────────────────────────────
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: others.length,
              itemBuilder: (context, index) {
                final user = others[index];
                final isMe = user['isMe'] == true;
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.accent.withValues(alpha: 0.15) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? Border.all(color: AppColors.accent) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${user['rank']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isMe ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          child: Text(user['avatar'] as String, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            user['name'] as String,
                            style: TextStyle(
                              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${user['points']} نقطة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMe ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumUser(Map<String, dynamic> user, int rank, double height, Color medalColor, {bool isFirst = false}) {
    return FadeInUp(
      delay: Duration(milliseconds: 200 * rank),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFirst)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 40),
            ),
          CircleAvatar(
            radius: isFirst ? 36 : 28,
            backgroundColor: medalColor,
            child: CircleAvatar(
              radius: isFirst ? 32 : 25,
              backgroundColor: Colors.white,
              child: Text(user['avatar'], style: TextStyle(fontSize: isFirst ? 32 : 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            '${user['points']}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
