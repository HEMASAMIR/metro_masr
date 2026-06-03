import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/metro_data.dart';
import '../../domain/entities/station.dart';
import '../cubits/route_planner/route_planner_cubit.dart';
import '../cubits/route_planner/route_planner_state.dart';

class SubscriptionOptimizerPage extends StatelessWidget {
  const SubscriptionOptimizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RoutePlannerCubit>(),
      child: const _SubscriptionOptimizerView(),
    );
  }
}

class _SubscriptionOptimizerView extends StatefulWidget {
  const _SubscriptionOptimizerView();

  @override
  State<_SubscriptionOptimizerView> createState() => _SubscriptionOptimizerViewState();
}

class _SubscriptionOptimizerViewState extends State<_SubscriptionOptimizerView> {
  int _tripsPerWeek = 10;
  int _passengerCount = 1;
  String? _fromId;
  String? _toId;

  List<Station> get _allStations => MetroData.stations.values.toList();

  void _calculate() {
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start and destination stations'.tr()), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select different stations'.tr()), backgroundColor: AppColors.error),
      );
      return;
    }
    context.read<RoutePlannerCubit>().findPath(_fromId!, _toId!);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Text('subscription_optimizer'.tr()),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.maxContentWidth),
          child: r.useSideBySideLayout
              ? _buildWideLayout(context, r)
              : _buildNarrowLayout(context, r),
        ),
      ),
    );
  }

  // ── Narrow layout (single column) ─────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, Responsive r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        children: [
          FadeInDown(child: _buildInputCard(context, r)),
          SizedBox(height: r.sectionSpacing),
          FadeInUp(child: _buildResultCard(context, r)),
        ],
      ),
    );
  }

  // ── Wide layout (side-by-side) ────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, Responsive r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FadeInDown(child: _buildInputCard(context, r)),
          ),
          SizedBox(width: r.pagePadding),
          Expanded(
            child: FadeInUp(child: _buildResultCard(context, r)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, Responsive r) {
    final isAr = context.locale.languageCode == 'ar';
    return Container(
      padding: EdgeInsets.all(r.pagePadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(r.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Route ──
          Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.primary, size: r.fontSize(20)),
              const SizedBox(width: 8),
              Text(
                isAr ? 'مسار الرحلة' : 'Your Route',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(16)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStationPicker(
            context: context,
            isAr: isAr,
            hint: isAr ? "محطة الانطلاق" : "Start Station",
            icon: Icons.radio_button_checked,
            iconColor: AppColors.success,
            value: _fromId,
            onChanged: (v) => setState(() => _fromId = v),
          ),
          const SizedBox(height: 12),
          _buildStationPicker(
            context: context,
            isAr: isAr,
            hint: isAr ? "محطة الوصول" : "Destination Station",
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            value: _toId,
            onChanged: (v) => setState(() => _toId = v),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
          ),

          // ── Section: Passengers ──
          Row(
            children: [
              Icon(Icons.people_alt_outlined, color: AppColors.line2, size: r.fontSize(20)),
              const SizedBox(width: 8),
              Text(
                isAr ? 'عدد الأفراد' : 'Number of Passengers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(15)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.line2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_passengerCount',
                  style: TextStyle(
                    color: AppColors.line2,
                    fontWeight: FontWeight.w900,
                    fontSize: r.fontSize(15),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _passengerCount.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _passengerCount.toString(),
            activeColor: AppColors.line2,
            onChanged: (val) => setState(() => _passengerCount = val.round()),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
          ),

          // ── Section: Trips ──
          Row(
            children: [
              Icon(Icons.repeat_rounded, color: AppColors.primary, size: r.fontSize(20)),
              const SizedBox(width: 8),
              Text(
                'trips_per_week'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(15)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_tripsPerWeek',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: r.fontSize(15),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _tripsPerWeek.toDouble(),
            min: 1,
            max: 28,
            divisions: 27,
            label: _tripsPerWeek.toString(),
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _tripsPerWeek = val.round()),
          ),

          const SizedBox(height: 12),

          // ── Calculate Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: r.isTablet ? 20 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: TextStyle(fontSize: r.fontSize(15), fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.calculate_rounded, size: 22),
              onPressed: _calculate,
              label: Text('calculate'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationPicker({
    required BuildContext context,
    required bool isAr,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final selected = value != null
        ? _allStations.firstWhere((s) => s.id == value, orElse: () => _allStations.first)
        : null;
    final lineColor = selected == null
        ? Colors.grey
        : selected.line == 1
            ? AppColors.line1
            : selected.line == 2
                ? AppColors.line2
                : AppColors.line3;

    return GestureDetector(
      onTap: () => _showStationPicker(context, isAr, onChanged, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected != null
                ? lineColor.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.3),
            width: selected != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: selected != null ? lineColor.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected != null ? lineColor : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: selected == null
                  ? Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 14))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? selected.nameAr : selected.nameEn,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          isAr ? 'الخط ${selected.line}' : 'Line ${selected.line}',
                          style: TextStyle(fontSize: 11, color: lineColor),
                        ),
                      ],
                    ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: selected != null ? lineColor : Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showStationPicker(
    BuildContext context,
    bool isAr,
    ValueChanged<String?> onChanged,
    String? currentValue,
  ) {
    final searchCtrl = TextEditingController();
    final line1 = _allStations.where((s) => s.line == 1).toList();
    final line2 = _allStations.where((s) => s.line == 2).toList();
    final line3 = _allStations.where((s) => s.line == 3).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = searchCtrl.text.trim().toLowerCase();
          bool matches(s) {
            final n = (isAr ? s.nameAr : s.nameEn).toLowerCase();
            return q.isEmpty || n.contains(q);
          }
          final f1 = line1.where(matches).toList();
          final f2 = line2.where(matches).toList();
          final f3 = line3.where(matches).toList();
          final hasResults = f1.isNotEmpty || f2.isNotEmpty || f3.isNotEmpty;

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.4,
            maxChildSize: 0.94,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.train_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'اختر المحطة' : 'Select Station',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    // ── Search box ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        onChanged: (_) => setSheet(() {}),
                        decoration: InputDecoration(
                          hintText: isAr ? 'ابحث عن محطة...' : 'Search station...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          suffixIcon: searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setSheet(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Scrollable list
                    Expanded(
                      child: hasResults
                          ? ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 24),
                              children: [
                                if (f1.isNotEmpty) ..._buildGroupSection(
                                  isAr ? 'الخط الأول' : 'Line 1', AppColors.line1,
                                  f1, isAr, currentValue, onChanged, context, false,
                                ),
                                if (f2.isNotEmpty) ..._buildGroupSection(
                                  isAr ? 'الخط الثاني' : 'Line 2', AppColors.line2,
                                  f2, isAr, currentValue, onChanged, context, f1.isNotEmpty,
                                ),
                                if (f3.isNotEmpty) ..._buildGroupSection(
                                  isAr ? 'الخط الثالث' : 'Line 3', AppColors.line3,
                                  f3, isAr, currentValue, onChanged, context,
                                  f1.isNotEmpty || f2.isNotEmpty,
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded, color: Colors.grey, size: 44),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAr ? 'لا توجد نتائج' : 'No results found',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupSection(
    String title,
    Color color,
    List<Station> stations,
    bool isAr,
    String? currentValue,
    ValueChanged<String?> onChanged,
    BuildContext context,
    bool showTopDivider,
  ) {
    return [
      if (showTopDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(
          children: [
            Container(width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.w900,
                    fontSize: 13, letterSpacing: 0.3)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${stations.length}',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      ...stations.map((s) {
        final isSelected = s.id == currentValue;
        return InkWell(
          onTap: () {
            onChanged(s.id);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    isAr ? s.nameAr : s.nameEn,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (s.isTransfer)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('transfer'.tr(),
                        style: const TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
              ],
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildLineHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineDivider(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
        _buildLineHeader(title, color),
      ],
    );
  }

  List<Widget> _buildStationItems(
    List<Station> stations,
    bool isAr,
    String? currentValue,
    ValueChanged<String?> onChanged,
    Color lineColor,
    BuildContext context,
  ) {
    return stations.map((s) {
      final isSelected = s.id == currentValue;
      return InkWell(
        onTap: () {
          onChanged(s.id);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          color: isSelected ? lineColor.withValues(alpha: 0.1) : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(
                  color: isSelected ? lineColor : lineColor.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  isAr ? s.nameAr : s.nameEn,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? lineColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: lineColor, size: 18),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultCard(BuildContext context, Responsive r) {
    return BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
      builder: (context, state) {
        if (state is RoutePlannerLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        if (state is RoutePlannerError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(state.message, style: const TextStyle(color: Colors.red))),
              ],
            ),
          );
        }
        if (state is RoutePlannerLoaded) {
          final singleFare = state.ticketPrice.toDouble() * _passengerCount;
          final isAr = context.locale.languageCode == 'ar';
          
          double subPrice = 0;
          String tColor = '';
          Color ticketColor = Colors.grey;
          if (state.stationCount <= 9) {
            tColor = isAr ? 'أصفر (Yellow)' : 'Yellow';
            subPrice = 350;
            ticketColor = const Color(0xFFF59E0B);
          } else if (state.stationCount <= 16) {
            tColor = isAr ? 'أخضر (Green)' : 'Green';
            subPrice = 450;
            ticketColor = const Color(0xFF10B981);
          } else if (state.stationCount <= 23) {
            tColor = isAr ? 'وردي (Pink)' : 'Pink';
            subPrice = 550;
            ticketColor = const Color(0xFFEC4899);
          } else {
            tColor = isAr ? 'أحمر (Red)' : 'Red';
            subPrice = 650;
            ticketColor = const Color(0xFFEF4444);
          }

          double totalSubPrice = subPrice * _passengerCount;
          double weeklyCost = singleFare * _tripsPerWeek;
          double monthlyCost = weeklyCost * 4.3; // avg weeks per month

          final isSavings = monthlyCost > totalSubPrice;
          String recommendation = '';
          if (isSavings) {
            recommendation = isAr
                ? 'الاشتراك الشهري أوفر! هتوفر ${(monthlyCost - totalSubPrice).round()} جنيه شهرياً.'
                : 'Monthly sub is cheaper! You will save ${(monthlyCost - totalSubPrice).round()} EGP monthly.';
          } else {
            recommendation = isAr ? 'شراء التذاكر الفردية أوفر لك حالياً.' : 'Buying single tickets is cheaper for you.';
          }

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(r.cardRadius),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                // ── Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(r.cardRadius)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        isAr ? 'نتيجة التحليل' : 'Analysis Result',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: r.fontSize(16)),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(r.pagePadding),
                  child: Column(
                    children: [
                      // ── Stats Row ──
                      Row(
                        children: [
                          // Stations count
                          Expanded(
                            child: _buildStatItem(
                              context,
                              r,
                              icon: Icons.stairs_outlined,
                              color: AppColors.primary,
                              label: isAr ? 'عدد المحطات' : 'Stations',
                              value: '${state.stationCount}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Ticket color
                          Expanded(
                            child: _buildStatItem(
                              context,
                              r,
                              icon: Icons.confirmation_number_outlined,
                              color: ticketColor,
                              label: isAr ? 'لون التذكرة' : 'Ticket',
                              value: tColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // Fare
                          Expanded(
                            child: _buildStatItem(
                              context,
                              r,
                              icon: Icons.payments_outlined,
                              color: AppColors.line2,
                              label: isAr ? 'سعر التذكرة' : 'Fare',
                              value: isAr ? '$singleFare جنيه' : '$singleFare EGP',
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Subscription
                          Expanded(
                            child: _buildStatItem(
                              context,
                              r,
                              icon: Icons.card_membership_outlined,
                              color: AppColors.line3,
                              label: isAr ? 'الاشتراك الشهري' : 'Monthly Sub',
                              value: isAr ? '${totalSubPrice.round()} جنيه' : '${totalSubPrice.round()} EGP',
                            ),
                          ),
                        ],
                      ),

                      // ── Divider ──
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
                      ),

                      // ── Recommendation ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isSavings ? AppColors.success : AppColors.primary).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isSavings ? AppColors.success : AppColors.primary).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSavings ? Icons.savings_outlined : Icons.info_outline_rounded,
                              color: isSavings ? AppColors.success : AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recommendation,
                                style: TextStyle(
                                  fontSize: r.fontSize(14),
                                  color: isSavings ? AppColors.success : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    Responsive r, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: r.fontSize(15),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: r.fontSize(11)),
          ),
        ],
      ),
    );
  }
}
