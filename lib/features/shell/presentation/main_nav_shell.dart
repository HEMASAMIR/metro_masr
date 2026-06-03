import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/gamification_service.dart';
import '../../metro/presentation/pages/home_page.dart';
import '../../metro/presentation/pages/map_page.dart';
import '../../metro/presentation/pages/ticket_price_page.dart';
import '../../community/presentation/pages/community_page.dart';
import '../../settings/presentation/pages/settings_page.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    TicketPricePage(),
    MapPage(),
    CommunityPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initGamification();
  }

  Future<void> _initGamification() async {
    await GamificationService.init();
    await GamificationService.recordDailyOpen();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: "Home".tr(),
        color: AppColors.primary,
      ),
      _NavItem(
        icon: Icons.confirmation_number_outlined,
        activeIcon: Icons.confirmation_number_rounded,
        label: "Ticket Price".tr(),
        color: const Color(0xFF1565C0),
      ),
      _NavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: "Metro Lines".tr(),
        color: AppColors.line3,
      ),
      _NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: "Community".tr(),
        color: AppColors.line2,
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: "Settings".tr(),
        color: Colors.grey,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 100, // accommodate the margin and the rising icon
          padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Glassmorphic background
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Layout constraints to handle the sliding blob and icons properly
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 75,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / navItems.length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Sliding Background Blob
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          left: _currentIndex * itemWidth + (itemWidth - 55) / 2,
                          top: 10,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: navItems[_currentIndex].color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        
                        // Icons and Labels
                        SizedBox(
                          height: 75,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(navItems.length, (i) {
                              final item = navItems[i];
                              final isSelected = i == _currentIndex;

                              return GestureDetector(
                                onTap: () => _onTap(i),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: itemWidth,
                                  height: 75,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // The label fades in and slides up
                                      Positioned(
                                        bottom: 12,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 300),
                                            opacity: isSelected ? 1.0 : 0.0,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 400),
                                              curve: Curves.easeOutQuart,
                                              transform: Matrix4.translationValues(
                                                  0, isSelected ? 0 : 10, 0),
                                              child: Text(
                                                item.label,
                                                style: TextStyle(
                                                  color: item.color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // The icon pops up out of the bar
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 450),
                                        curve: Curves.elasticOut,
                                        top: isSelected ? -24 : 24,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            padding: EdgeInsets.all(isSelected ? 14 : 0),
                                            decoration: BoxDecoration(
                                              color: isSelected ? item.color : Colors.transparent,
                                              shape: BoxShape.circle,
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: item.color.withValues(alpha: 0.4),
                                                        blurRadius: 15,
                                                        offset: const Offset(0, 8),
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: Icon(
                                              isSelected ? item.activeIcon : item.icon,
                                              color: isSelected 
                                                  ? Colors.white 
                                                  : (isDark ? Colors.white54 : Colors.black54),
                                              size: isSelected ? 28 : 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
