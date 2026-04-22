import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../domain/entities/message.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatView extends StatelessWidget {
  final List<Message> messages;

  const ChatView({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    // Mock station groups
    final groups = [
      {'name': 'جروب محطة الشهداء', 'line': 'الخط الأول والثاني', 'online': 120, 'color': AppColors.primary},
      {'name': 'جروب خط حلوان', 'line': 'الخط الأول', 'online': 340, 'color': AppColors.line1},
      {'name': 'جروب محطة العتبة', 'line': 'الخط الثاني والثالث', 'online': 85, 'color': AppColors.line3},
      {'name': 'جروب خط المطار (قريباً)', 'line': 'الخط الثالث', 'online': 42, 'color': AppColors.line3},
    ];

    final isAr = context.locale.languageCode == 'ar';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.groups, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'تواصل مع الركاب في نفس محطتك و مسارك 💬' : 'Connect with passengers in your station!',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: GestureDetector(
                  onTap: () {
                    // Open Chat Modal mockup
                    _openChatRoom(context, group['name'] as String, group['color'] as Color);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                      border: Border.all(color: (group['color'] as Color).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: (group['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.forum, color: group['color'] as Color, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['name'] as String,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                group['line'] as String,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, color: AppColors.success, size: 8),
                                  const SizedBox(width: 4),
                                  Text('${group['online']}', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openChatRoom(BuildContext context, String roomName, Color themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  Text(roomName, style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text('الدردشة الحية لـ $roomName ستظهر هنا.', style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
