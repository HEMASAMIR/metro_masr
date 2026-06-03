import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';


class StationSearchSheet extends StatefulWidget {
  final List<dynamic> stations; // Can be List<Station>
  final String? selectedStationId;

  const StationSearchSheet({
    super.key,
    required this.stations,
    this.selectedStationId,
  });

  static Future<String?> show(
    BuildContext context,
    List<dynamic> stations, {
    String? selectedStationId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StationSearchSheet(
        stations: stations,
        selectedStationId: selectedStationId,
      ),
    );
  }

  @override
  State<StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<StationSearchSheet>
    with SingleTickerProviderStateMixin {
  late List<dynamic> _filtered;
  final TextEditingController _ctrl = TextEditingController();
  late TabController _tabController;
  late List<Map<String, dynamic>> _tabsData;

  @override
  void initState() {
    super.initState();
    _filtered = widget.stations;
    _buildTabs();
    _tabController = TabController(length: _tabsData.length, vsync: this);
  }

  void _buildTabs() {
    _tabsData = [];

    // 0. "All" Tab
    _tabsData.add({
      'line': 0,
      'titleEn': 'All',
      'titleAr': 'الكل',
      'color': AppColors.primary,
      'icon': Icons.apps_rounded,
    });

    if (widget.stations.any((s) => s.line == 1)) {
      _tabsData.add({
        'line': 1,
        'titleEn': 'Line 1',
        'titleAr': 'خط 1',
        'color': AppColors.line1,
        'icon': Icons.train_rounded,
      });
    }
    if (widget.stations.any((s) => s.line == 2)) {
      _tabsData.add({
        'line': 2,
        'titleEn': 'Line 2',
        'titleAr': 'خط 2',
        'color': AppColors.line2,
        'icon': Icons.train_rounded,
      });
    }
    if (widget.stations.any((s) => s.line == 3)) {
      _tabsData.add({
        'line': 3,
        'titleEn': 'Line 3',
        'titleAr': 'خط 3',
        'color': AppColors.line3,
        'icon': Icons.train_rounded,
      });
    }
    if (widget.stations.any((s) => s.line == 4)) {
      _tabsData.add({
        'line': 4,
        'titleEn': 'LRT',
        'titleAr': 'LRT',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.directions_railway_filled_rounded,
      });
    }
    if (widget.stations.any((s) => s.line == 5)) {
      _tabsData.add({
        'line': 5,
        'titleEn': 'Mono',
        'titleAr': 'مونوريل',
        'color': const Color(0xFF06B6D4),
        'icon': Icons.directions_transit_filled_rounded,
      });
    }
  }

  List<dynamic> _getStationsForTab(int tabIndex) {
    final tab = _tabsData[tabIndex];
    final line = tab['line'] as int;
    if (line == 0) return _filtered;
    return _filtered.where((s) => s.line == line).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Color _getLineColor(int line) {
    switch (line) {
      case 1:
        return AppColors.line1;
      case 2:
        return AppColors.line2;
      case 3:
        return AppColors.line3;
      case 4:
        return const Color(0xFF8B5CF6);
      case 5:
        return const Color(0xFF06B6D4);
      default:
        return AppColors.primary;
    }
  }

  String _getLineText(int line, bool isAr) {
    if (line == 4) return isAr ? "LRT" : "LRT";
    if (line == 5) return isAr ? "المونوريل" : "Monorail";
    return isAr ? "الخط $line" : "Line $line";
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTabColor =
        _tabsData[_tabController.index]['color'] as Color? ?? AppColors.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82 + keyboardHeight,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: activeTabColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Select Station".tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Search Field ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search station...".tr(),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (val) {
                final query = val.toLowerCase().trim();
                setState(() {
                  if (query.isEmpty) {
                    _filtered = widget.stations;
                  } else {
                    _filtered = widget.stations.where((s) {
                      return s.nameAr.toLowerCase().contains(query) ||
                          s.nameEn.toLowerCase().contains(query);
                    }).toList();
                    if (_tabController.index != 0) {
                      _tabController.animateTo(0);
                    }
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── TabBar ───────────────────────────────────────────────────
          _StyledTabBar(
            controller: _tabController,
            tabsData: _tabsData,
            isAr: isAr,
            isDark: isDark,
            filtered: _filtered,
            onTabTap: (_) => setState(() {}),
          ),

          // ── Divider ──────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),

          // ── Station Lists (TabBarView) ────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabsData.length, (tabIdx) {
                final stations = _getStationsForTab(tabIdx);
                if (stations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          "No stations found".tr(),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: stations.length,
                  itemBuilder: (context, i) {
                    final s = stations[i];
                    final name = isAr ? s.nameAr : s.nameEn;
                    final lineColor = _getLineColor(s.line);
                    final isSelected = s.id == widget.selectedStationId;

                    return InkWell(
                      onTap: () => Navigator.pop(context, s.id),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? lineColor.withValues(
                                  alpha: isDark ? 0.18 : 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? lineColor.withValues(alpha: 0.35)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Line color dot + icon
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: lineColor.withValues(alpha: 0.13),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.train_rounded,
                                  size: 20, color: lineColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 15,
                                      color: isSelected
                                          ? lineColor
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getLineText(s.line, isAr),
                                    style: TextStyle(
                                        color: lineColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (s.isTransfer) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "transfer".tr(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: lineColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled TabBar Widget
// ─────────────────────────────────────────────────────────────────────────────
class _StyledTabBar extends StatefulWidget {
  final TabController controller;
  final List<Map<String, dynamic>> tabsData;
  final bool isAr;
  final bool isDark;
  final List<dynamic> filtered;
  final ValueChanged<int> onTabTap;

  const _StyledTabBar({
    required this.controller,
    required this.tabsData,
    required this.isAr,
    required this.isDark,
    required this.filtered,
    required this.onTabTap,
  });

  @override
  State<_StyledTabBar> createState() => _StyledTabBarState();
}

class _StyledTabBarState extends State<_StyledTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (widget.controller.indexIsChanging || !widget.controller.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChange);
    super.dispose();
  }

  int _countForTab(int tabIndex) {
    final tab = widget.tabsData[tabIndex];
    final line = tab['line'] as int;
    if (line == 0) return widget.filtered.length;
    return widget.filtered.where((s) => s.line == line).length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TabBar(
        controller: widget.controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.tabsData[widget.controller.index]['color'] as Color,
          boxShadow: [
            BoxShadow(
              color: (widget.tabsData[widget.controller.index]['color'] as Color)
                  .withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        dividerColor: Colors.transparent,
        onTap: (i) {
          widget.onTabTap(i);
          setState(() {});
        },
        tabs: List.generate(widget.tabsData.length, (i) {
          final tab = widget.tabsData[i];
          final isActive = widget.controller.index == i;
          final color = tab['color'] as Color;
          final label =
              widget.isAr ? tab['titleAr'] as String : tab['titleEn'] as String;
          final count = _countForTab(i);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? null
                  : Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (widget.isDark ? Colors.white70 : Colors.black54),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
