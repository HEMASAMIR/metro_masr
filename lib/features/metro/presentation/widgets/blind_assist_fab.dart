import 'package:flutter/material.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../../../core/utils/voice_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';

class BlindAssistFab extends StatefulWidget {
  const BlindAssistFab({super.key});

  @override
  State<BlindAssistFab> createState() => _BlindAssistFabState();
}

class _BlindAssistFabState extends State<BlindAssistFab> {
  bool _isActive = false;

  void _toggleBlindMode() {
    setState(() => _isActive = !_isActive);
    final isAr = context.locale.languageCode == 'ar';
    if (_isActive) {
      VoiceService.speak(isAr ? 'تم تفعيل العصا الذكية للمكفوفين. سأقوم بتوجيهك، المحطة القادمة هي المرج' : 'Blind Assist enabled. I will guide you verbally. Next stop is El Marg.', isAr ? 'ar-EG' : 'en-US');
    } else {
      VoiceService.speak(isAr ? 'تم إيقاف وضع العصا الذكية.' : 'Blind Assist disabled.', isAr ? 'ar-EG' : 'en-US');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pulse heavily if active
    final child = FloatingActionButton(
      heroTag: 'blindAssist',
      backgroundColor: _isActive ? const Color(0xFF00BFFF) : Colors.white,
      foregroundColor: _isActive ? Colors.white : AppColors.primary,
      onPressed: _toggleBlindMode,
      child: Icon(_isActive ? Icons.record_voice_over : Icons.accessibility_new),
    );

    return _isActive ? Pulse(infinite: true, child: child) : child;
  }
}
