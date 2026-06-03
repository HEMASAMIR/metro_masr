import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rafiq_metrro/features/auth/cubit/auth_cubit.dart';
import 'chat_screen.dart';

class MetroGroupsScreen extends StatefulWidget {
  const MetroGroupsScreen({Key? key}) : super(key: key);

  @override
  State<MetroGroupsScreen> createState() => _MetroGroupsScreenState();
}

class _MetroGroupsScreenState extends State<MetroGroupsScreen> {
  final List<Map<String, dynamic>> cairoGroups = [
    {
      'id': 'line_1_chat',
      'name': 'الخط الأول\n(حلوان - المرج)',
      'icon': Icons.train,
      'color': Colors.blue,
      'whatsappUrl': 'https://chat.whatsapp.com/KZVd2XZlk3T1cpixHHdsRw',
    },
    {
      'id': 'line_2_chat',
      'name': 'الخط الثاني\n(شبرا - المنيب)',
      'icon': Icons.subway,
      'color': Colors.red,
      'whatsappUrl': 'https://chat.whatsapp.com/Kv2QlA9n0JsIQrDtZb8K9O',
    },
    {
      'id': 'line_3_chat',
      'name': 'الخط الثالث\n(عدلي منصور - روض الفرج)',
      'icon': Icons.directions_transit,
      'color': Colors.green,
      'whatsappUrl': 'https://chat.whatsapp.com/LyUcMlUwJZFH88kGwUlXXD',
    },
  ];

  final List<Map<String, dynamic>> capitalGroups = [
    {
      'id': 'monorail_chat',
      'name': 'العاصمة الإدارية\n(المونوريل)',
      'icon': Icons.electric_rickshaw,
      'color': Colors.teal,
      'whatsappUrl': 'https://chat.whatsapp.com/D0aPIabfKMX3Impqgcq5mW',
    },
  ];

  Future<void> _openWhatsApp(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تأكد إن الواتساب مثبت على الجهاز 📱'),
          backgroundColor: Color(0xFF25D366),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String currentUserName = 'راكب';
        if (authState is AuthSuccess &&
            authState.displayName != null &&
            authState.displayName!.isNotEmpty) {
          currentUserName = authState.displayName!;
        }

        return DefaultTabController(
          length: 2,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              color: const Color(0xFFF3F4F6),
              padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  const Text(
                    'اختر الشبكة أو الخط:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Subtitle ──
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF25D366),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'الخطوط مرتبطة بجروبات واتساب رسمية — اضغط للانضمام مباشرة',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ── Tabs ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'مترو القاهرة'),
                        Tab(text: 'مترو العاصمة'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Tab Views ──
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGroupGrid(cairoGroups, currentUserName),
                        _buildGroupGrid(capitalGroups, currentUserName),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupGrid(List<Map<String, dynamic>> groupsList, String currentUserName) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.80,
      ),
      itemCount: groupsList.length,
      itemBuilder: (context, index) {
        final group = groupsList[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 150)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: _buildGroupCard(context, group, currentUserName),
        );
      },
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    Map<String, dynamic> group,
    String currentUserName,
  ) {
    final String? waUrl = group['whatsappUrl'] as String?;
    final bool hasWhatsApp = waUrl != null;
    final Color color = group['color'] as Color;

    return InkWell(
      onTap: () {
        if (hasWhatsApp) {
          _openWhatsApp(context, waUrl!);
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (ctx, anim, _) => MetroChatScreen(
                roomId: group['id'] as String,
                roomName: (group['name'] as String).replaceAll('\n', ' '),
                userName: currentUserName,
              ),
              transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // ── Card body ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.2), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(group['icon'] as IconData, size: 30, color: color),
                ),
                const SizedBox(height: 8),
                // Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    group['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),                // Badge: WhatsApp or Internal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasWhatsApp
                        ? const Color(0xFF25D366).withOpacity(0.12)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasWhatsApp
                          ? const Color(0xFF25D366).withOpacity(0.4)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasWhatsApp ? Icons.chat_bubble_rounded : Icons.chat_outlined,
                        color: hasWhatsApp ? const Color(0xFF25D366) : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasWhatsApp ? 'جروب واتساب' : 'شات داخلي',
                        style: TextStyle(
                          color: hasWhatsApp ? const Color(0xFF25D366) : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── WhatsApp open-indicator badge ──
          if (hasWhatsApp)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
