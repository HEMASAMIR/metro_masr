import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq_metrro/features/auth/cubit/auth_cubit.dart';
import 'chat_screen.dart';

class MetroGroupsScreen extends StatefulWidget {
  const MetroGroupsScreen({Key? key}) : super(key: key);

  @override
  State<MetroGroupsScreen> createState() => _MetroGroupsScreenState();
}

class _MetroGroupsScreenState extends State<MetroGroupsScreen> {
  final List<Map<String, dynamic>> groups = [
    {
      'id': 'line_1_chat',
      'name': 'الخط الأول\n(حلوان - المرج)',
      'icon': Icons.train,
      'color': Colors.blue,
    },
    {
      'id': 'line_2_chat',
      'name': 'الخط الثاني\n(شبرا - المنيب)',
      'icon': Icons.subway,
      'color': Colors.red,
    },
    {
      'id': 'line_3_chat',
      'name': 'الخط الثالث\n(عدلي منصور - روض الفرج)',
      'icon': Icons.directions_transit,
      'color': Colors.green,
    },
    {
      'id': 'lost_and_found',
      'name': 'المفقودات\n(لقيت/ضيعت حاجة)',
      'icon': Icons.search_rounded,
      'color': Colors.deepPurple,
    },
    {
      'id': 'general_chat',
      'name': 'دردشة عامة\nأسئلة ومساعدات',
      'icon': Icons.forum,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // استدعاء اسم المستخدم الحقيقي من AuthCubit
        String currentUserName = 'راكب';
        if (authState is AuthSuccess && authState.displayName != null && authState.displayName!.isNotEmpty) {
          currentUserName = authState.displayName!;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: const Color(0xFFF3F4F6),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: const Text(
                    'اختر المحطة أو الخط:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: const Text(
                    'تحدث مع الركاب لمعرفة الزحام والمشاكل في وقتها الفعلي.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildGroupCard(context, group, currentUserName),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, Map<String, dynamic> group, String currentUserName) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MetroChatScreen(
              roomId: group['id'],
              roomName: group['name'].replaceAll('\n', ' '),
              userName: currentUserName, // تم ربط الاسم الحقيقي هنا
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: group['color'].withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: group['color'].withOpacity(0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: group['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(group['icon'], size: 36, color: group['color']),
            ),
            const SizedBox(height: 16),
            Text(
              group['name'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: group['color'],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
