import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/gamification_service.dart';
import '../../metro/presentation/pages/home_page.dart';
import '../../metro/presentation/pages/map_page.dart';
import '../../metro/presentation/pages/route_planner_page.dart';
import '../../community/presentation/pages/community_page.dart';
import '../../settings/presentation/pages/settings_page.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconAnimations;

  final _pages = const [
    HomePage(),
    RoutePlannerPage(),
    MapPage(),
    CommunityPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    GamificationService.init();
    _iconControllers = List.generate(
      5,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _iconAnimations = _iconControllers.map((c) =>
      Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: c, curve: Curves.elasticOut),
      ),
    ).toList();
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    _iconControllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _iconControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    final navItems = [
      _NavItem(icon: Icons.home_rounded, label: isAr ? 'الرئيسية' : 'Home', color: AppColors.primary),
      _NavItem(icon: Icons.route_outlined, label: isAr ? 'رحلة' : 'Route', color: AppColors.accent),
      _NavItem(icon: Icons.map_outlined, label: isAr ? 'الخريطة' : 'Map', color: AppColors.line3),
      _NavItem(icon: Icons.people_outline_rounded, label: isAr ? 'مجتمع' : 'Community', color: AppColors.line2),
      _NavItem(icon: Icons.settings_outlined, label: isAr ? 'إعدادات' : 'Settings', color: Colors.grey),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (i) {
                final item = navItems[i];
                final isSelected = i == _currentIndex;
                return GestureDetector(
                  onTap: () => _onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _iconAnimations[i],
                    builder: (_, child) => Transform.scale(
                      scale: isSelected ? _iconAnimations[i].value : 1.0,
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 18 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? item.color.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? item.color : Colors.grey,
                            size: 24,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: isSelected
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: item.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;

  _NavItem({required this.icon, required this.label, required this.color});
}
