import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/community_cubit.dart';
import '../cubits/community_state.dart';
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
    final now = DateTime.now();
    final random = Random(now.hour);

    final groups = [
      {'name': 'جروب محطة الشهداء', 'line': 'الخط الأول والثاني', 'online': random.nextInt(300) + 100, 'color': AppColors.primary},
      {'name': 'جروب خط حلوان', 'line': 'الخط الأول', 'online': random.nextInt(200) + 50, 'color': AppColors.line1},
      {'name': 'جروب محطة العتبة', 'line': 'الخط الثاني والثالث', 'online': random.nextInt(400) + 150, 'color': AppColors.line3},
      {'name': 'جروب خط المطار', 'line': 'الخط الثالث', 'online': random.nextInt(100) + 20, 'color': AppColors.line3},
    ];

    final isAr = context.locale.languageCode == 'ar';

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0088cc), Color(0xFF00aaff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0088cc).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Color(0xFF0088cc), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'جروب رفيق عالتليجرام 🚀' : 'Rafiq Telegram Group 🚀',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? 'انضم لأكثر من 50,000 راكب لمتابعة حركة المترو والزحمة لحظة بلحظة!' : 'Join 50k+ riders for live crowd & delay updates!',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0088cc),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(isAr ? 'جاري تحويلك لجروب التليجرام الرسمي...' : 'Redirecting to Official Telegram...'))
                   );
                },
                child: Text(isAr ? 'انضم' : 'Join', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    final textCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocBuilder<CommunityCubit, CommunityState>(
          bloc: context.read<CommunityCubit>(), // Bind to existing cubit
          builder: (context, state) {
            List<Message> currentMessages = messages; // fallback
            if (state is CommunityLoaded) {
              currentMessages = state.messages;
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // App Bar Modal Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        Expanded(
                          child: Text(
                            roomName,
                            style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: AppColors.success, size: 8),
                              SizedBox(width: 4),
                              Text('Live', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // Chat Message Area
                  Expanded(
                    child: currentMessages.isEmpty
                        ? Center(child: Text('ابدأ الدردشة في $roomName...', style: const TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: currentMessages.length,
                            reverse: false,
                            itemBuilder: (context, index) {
                              final msg = currentMessages[index];
                              final isMe = msg.senderId == 'me';
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? themeColor : Colors.white,
                                    boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isMe ? const Radius.circular(0) : null,
                                      bottomLeft: !isMe ? const Radius.circular(0) : null,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            msg.senderName,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeColor),
                                          ),
                                        ),
                                      Text(
                                        msg.content,
                                        style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white70 : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Input Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textCtrl,
                            decoration: InputDecoration(
                              hintText: 'اكتب لتسأل مجتمع المحطة...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              fillColor: Colors.grey[100],
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                context.read<CommunityCubit>().sendMessage(val.trim());
                                textCtrl.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: themeColor,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              if (textCtrl.text.trim().isNotEmpty) {
                                context.read<CommunityCubit>().sendMessage(textCtrl.text.trim());
                                textCtrl.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
