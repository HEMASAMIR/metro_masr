import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class LiveTrainTracker extends StatefulWidget {
  const LiveTrainTracker({super.key});

  @override
  State<LiveTrainTracker> createState() => _LiveTrainTrackerState();
}

class _LiveTrainTrackerState extends State<LiveTrainTracker> {
  // Simulating dummy train data (derived from crowdsourced user GPS)
  double _train1Position = 0.2; // 0.0 to 1.0 along the line
  double _train2Position = 0.7;

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _train1Position += 0.02;
        if (_train1Position > 1.0) _train1Position = 0.0;

        _train2Position += 0.015;
        if (_train2Position > 1.0) _train2Position = 0.0;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.radar, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'live_train_info'.tr(),
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('الخط الأول (المرج - حلوان)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildTrainLine(AppColors.line1, _train1Position, 'زحام شديد'),
              const SizedBox(height: 32),
              const Text('الخط الثاني (شبرا - المنيب)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildTrainLine(AppColors.line2, _train2Position, 'طبيعي'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainLine(Color lineColor, double trainPos, String crowdStatus) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Line Path
          Container(
            height: 4,
            width: double.infinity,
            color: lineColor.withValues(alpha: 0.3),
          ),
          // Stations (dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: lineColor, width: 3),
                ),
              );
            }),
          ),
          // Flowing Train
          Positioned(
            left: (MediaQuery.of(context).size.width - 80) * trainPos,
            child: FadeIn(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: crowdStatus == 'زحام شديد' ? AppColors.error : AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(crowdStatus, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.train, color: lineColor, size: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
