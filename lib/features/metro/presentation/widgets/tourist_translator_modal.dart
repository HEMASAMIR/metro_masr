import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../../../core/utils/voice_service.dart';

class TouristTranslatorModal extends StatelessWidget {
  const TouristTranslatorModal({super.key});

  static void show(BuildContext context) {
    VoiceService.speak('Welcome to Cairo Metro Tourist Assist mode. Please speak your query.', 'en-US');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TouristTranslatorModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 24),
          const Icon(Icons.g_translate, color: AppColors.accent, size: 64),
          const SizedBox(height: 12),
          const Text('Tourist Translator 🌍', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Instant real-time translation from English to Arabic.\nSpeak clearly...', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          
          Expanded(
            child: Center(
              child: Pulse(
                infinite: true,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 64, color: AppColors.accent),
                ),
              ),
            ),
          ),
          
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
             ),
             child: const Column(
               children: [
                 Text('"Where is the ticket office?"', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                 SizedBox(height: 12),
                 Icon(Icons.arrow_downward, color: Colors.grey),
                 SizedBox(height: 12),
                 Text('أين مكتب التذاكر؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
               ]
             )
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
