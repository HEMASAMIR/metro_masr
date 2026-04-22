import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../domain/entities/reward.dart';
import '../cubits/community_cubit.dart';

class RewardsView extends StatelessWidget {
  final Reward reward;

  const RewardsView({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    // Current points calculate tier:
    final int pts = reward.currentPoints;
    final String tier = pts >= 5000 ? 'ذهبي' : pts >= 2000 ? 'فضي' : 'برونزي';
    final Color tierColor = pts >= 5000 ? const Color(0xFFFFD700) : pts >= 2000 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32);
    final isAr = context.locale.languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Points Glowing Ring Header ────────────────────────
          Center(
            child: ZoomIn(
              child: Container(
                margin: const EdgeInsets.only(top: 16, bottom: 30),
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [tierColor.withValues(alpha: 0.2), Theme.of(context).cardColor],
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(color: tierColor.withValues(alpha: 0.5), width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'مستواك: $tier' : 'Tier: $tier',
                        style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${reward.currentPoints}',
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1.1),
                      ),
                      Text(
                        isAr ? 'نقطة متوفرة' : 'Available Points',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Earn Points Action ────────────────────────────────
          Center(
            child: FadeInUp(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  context.read<CommunityCubit>().collectTripPoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? '🎉 مبروك! كسبت نقاط رحلة جديدة!' : '🎉 Congrats! Earned new trip points!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.confirmation_number),
                label: Text(
                  isAr ? 'تسجيل رحلة واستلام نقاط' : 'Record Trip & Earn Points',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Daily Challenges ──────────────────────────────────
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: Text(
              isAr ? '🏆 تحديات اليوم' : '🏆 Daily Challenges',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            delay: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_train, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'كابتن المترو الأسبوعي' : 'Weekly Metro Captain',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isAr ? 'اركب المترو 5 مرات هذا الأسبوع واكسب تذكرة مجانية!' : 'Ride 5 times this week to win a free ticket!',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (reward.totalTrips % 5) / 5.0,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${reward.totalTrips % 5}/5',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Redeem Store ──────────────────────────────────────
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              isAr ? '🎁 استبدال النقاط' : '🎁 Redeem Points',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRedeemCard(context, isAr ? 'تذكرة 9 محطات' : '9 Stations Ticket', 500, AppColors.line1, isAr),
                _buildRedeemCard(context, isAr ? 'تذكرة 16 محطة' : '16 Stations Ticket', 800, AppColors.line2, isAr),
                _buildRedeemCard(context, isAr ? 'تذكرة 23 محطة' : '23 Stations Ticket', 1200, AppColors.line3, isAr),
                _buildRedeemCard(context, isAr ? 'تذكرة اليوم الكامل' : 'Full Day Ticket', 2000, AppColors.accent, isAr),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRedeemCard(BuildContext context, String title, int cost, Color color, bool isAr) {
    return FadeInUp(
      delay: const Duration(milliseconds: 250),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.confirmation_number_outlined, color: color, size: 36),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '$cost ${isAr ? 'نقطة' : 'pts'}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () {
                  if (reward.currentPoints >= cost) {
                    context.read<CommunityCubit>().redeemPoints(cost);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم استبدال $title بنجاح!' : 'Successfully redeemed $title!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'نقاطك لا تكفي!' : 'Not enough points!'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Text(isAr ? 'استبدال' : 'Redeem'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

