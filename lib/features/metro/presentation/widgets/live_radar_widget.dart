import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class LiveRadarWidget extends StatefulWidget {
  const LiveRadarWidget({super.key});

  @override
  State<LiveRadarWidget> createState() => _LiveRadarWidgetState();
}

class _LiveRadarWidgetState extends State<LiveRadarWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeIn(
                child: const Icon(Icons.location_on, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                isAr ? 'أقرب محطة لك' : 'Nearest Station',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2 * _pulseController.value + 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(isAr ? 'مباشر' : 'LIVE', style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          // Station Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isAr ? 'السادات (تحرير)' : 'Sadat (Tahrir)',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                isAr ? 'يبعد ٤٠٠ متر' : '400m away',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Departures list
          _buildDepartureRow(isAr ? 'الخط الأول' : 'Line 1', AppColors.line1, isAr ? 'اتجاه حلوان' : 'To Helwan', '2', isAr),
          const Divider(color: Colors.white12, height: 24),
          _buildDepartureRow(isAr ? 'الخط الأول' : 'Line 1', AppColors.line1, isAr ? 'اتجاه المرج' : 'To El Marg', '4', isAr),
          const Divider(color: Colors.white12, height: 24),
          _buildDepartureRow(isAr ? 'الخط الثاني' : 'Line 2', AppColors.line2, isAr ? 'اتجاه المنيب' : 'To Mounib', '1', isAr),
        ],
      ),
    );
  }

  Widget _buildDepartureRow(String lineName, Color color, String direction, String mins, bool isAr) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lineName, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(direction, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: mins, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextSpan(text: isAr ? ' د' : ' m', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

