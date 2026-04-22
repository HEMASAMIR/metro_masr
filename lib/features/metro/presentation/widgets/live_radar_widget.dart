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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeIn(
                child: const Icon(Icons.radar, color: AppColors.success),
              ),
              const SizedBox(width: 8),
              Text(
                isAr ? 'الرادار المباشر (Simulation)' : 'Live Train Radar',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2 * _pulseController.value + 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        const Text('LIVE', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildRadarLine('Line 1', AppColors.line1, 0.2, 0.7),
          const SizedBox(height: 20),
          _buildRadarLine('Line 2', AppColors.line2, 0.4, 0.9),
          const SizedBox(height: 20),
          _buildRadarLine('Line 3', AppColors.line3, 0.1, 0.5),
        ],
      ),
    );
  }

  Widget _buildRadarLine(String name, Color color, double train1Pos, double train2Pos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // The track line
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Moving train 1
              _buildPulseTrain(color, train1Pos),
              // Moving train 2
              _buildPulseTrain(color, train2Pos),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulseTrain(Color color, double progress) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.7 * progress, // scaled to container approx
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 14 + (4 * _pulseController.value),
            height: 14 + (4 * _pulseController.value),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5 * _pulseController.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
