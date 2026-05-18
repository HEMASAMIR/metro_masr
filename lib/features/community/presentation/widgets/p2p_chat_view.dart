import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../data/p2p_chat_service.dart';
import '../cubits/p2p_chat_cubit.dart';

class P2PChatView extends StatefulWidget {
  const P2PChatView({super.key});

  @override
  State<P2PChatView> createState() => _P2PChatViewState();
}

class _P2PChatViewState extends State<P2PChatView> {
  final _stationController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _stationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => P2PChatCubit(P2PChatService()),
      child: BlocBuilder<P2PChatCubit, P2PChatState>(
        builder: (context, state) {
          if (state is P2PChatInitial) {
            return _buildStationSelector(context);
          } else if (state is P2PChatConnecting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري الإتصال بركاب المحطة بدون إنترنت...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          } else if (state is P2PChatConnected) {
            return _buildChatInterface(context, state);
          } else if (state is P2PChatError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<P2PChatCubit>().emit(P2PChatInitial()),
                    child: const Text('رجوع'),
                  )
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStationSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 70, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'شات المترو الأوفلاين',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'اختار الخط اللي أنت فيه عشان تتواصل مع الركاب بدون إنترنت.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 30),
          _buildLineRoomButton(context, 'الخط الأول (المرج - حلوان)', AppColors.line1, 'Line_1'),
          const SizedBox(height: 12),
          _buildLineRoomButton(context, 'الخط الثاني (شبرا - المنيب)', AppColors.line2, 'Line_2'),
          const SizedBox(height: 12),
          _buildLineRoomButton(context, 'الخط الثالث (عدلي منصور - روض الفرج)', AppColors.line3, 'Line_3'),
          const SizedBox(height: 12),
          _buildLineRoomButton(context, 'القطار الخفيف والمونوريل', Colors.teal, 'Line_4'),
        ],
      ),
    );
  }

  Widget _buildLineRoomButton(BuildContext context, String title, Color color, String roomKey) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () {
          context.read<P2PChatCubit>().connectToStation(roomKey);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.train, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(BuildContext context, P2PChatConnected state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.background.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12, height: 12,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'متصل بـ ${state.connectedCount} ركاب',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final msg = state.messages[index];
              
              // Helper to generate a unique color per user
              int hash = 0;
              for (int i = 0; i < msg.senderName.length; i++) {
                hash = msg.senderName.codeUnitAt(i) + ((hash << 5) - hash);
              }
              final userColor = HSLColor.fromAHSL(1.0, (hash.abs() % 360).toDouble(), 0.7, 0.4).toColor(); // Darker color for better contrast
              
              final isMe = msg.senderName == context.read<P2PChatCubit>().state is P2PChatConnected ? context.read<P2PChatCubit>().state.props : false; // Just checking logic
              // Actually P2PChatCubit doesn't expose the current userName directly, so we just colorize the name.

              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: userColor.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: userColor.withOpacity(0.15),
                            child: Text(
                              msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                              style: TextStyle(color: userColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            msg.senderName, 
                            style: TextStyle(color: userColor, fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        msg.content, 
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white, 
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.accent),
                onPressed: () {
                  context.read<P2PChatCubit>().sendMessage(_messageController.text);
                  _messageController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
