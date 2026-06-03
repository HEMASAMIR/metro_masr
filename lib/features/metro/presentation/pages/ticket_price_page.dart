import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/station.dart';
import '../cubits/route_planner/route_planner_cubit.dart';
import '../cubits/route_planner/route_planner_state.dart';
import '../../../../core/widgets/station_search_sheet.dart';

/// Ticket Price Calculator – production-grade, uses real RoutePlannerCubit
class TicketPricePage extends StatelessWidget {
  const TicketPricePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RoutePlannerCubit>(),
      child: const _TicketPriceView(),
    );
  }
}

class _TicketPriceView extends StatefulWidget {
  const _TicketPriceView();
  @override
  State<_TicketPriceView> createState() => _TicketPriceViewState();
}

class _TicketPriceViewState extends State<_TicketPriceView> {
  String? _fromId;
  String? _toId;
  int _passengerCount = 1;

  List<Station> get _allStations => MetroData.stations.values.toList();

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final r = context.responsive;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Ticket Price Calculator".tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header gradient ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(r.pagePadding, 20, r.pagePadding, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    "Calculate Your Trip Cost".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select start & end stations — we'll calculate price & time".tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: r.pagePadding,
                right: r.pagePadding,
                top: r.pagePadding,
                bottom: r.pagePadding + 100, // Extra bottom padding for the floating navigation bar!
              ),
              child: Column(
                children: [
                  // ── Form card ─────────────────────────────────────────
                  FadeInDown(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // FROM station
                          _buildStationPicker(
                            context: context,
                            isAr: isAr,
                            hint: "Start Station".tr(),
                            icon: Icons.radio_button_checked,
                            iconColor: AppColors.success,
                            value: _fromId,
                            onChanged: (v) {
                              setState(() => _fromId = v);
                              // Reset result when changing stations
                            },
                          ),

                          // Divider with swap button
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.25))),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    final tmp = _fromId;
                                    _fromId = _toId;
                                    _toId = tmp;
                                  }),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.25))),
                              ],
                            ),
                          ),

                          // TO station
                          _buildStationPicker(
                            context: context,
                            isAr: isAr,
                            hint: "Destination Station".tr(),
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.error,
                            value: _toId,
                            onChanged: (v) => setState(() => _toId = v),
                          ),

                          const SizedBox(height: 16),

                          // Passenger count
                          _buildPassengerPicker(context, isAr),

                          const SizedBox(height: 20),

                          // Calculate button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                              ),
                              icon: const Icon(Icons.calculate_rounded, size: 22),
                              label: Text(
                                "Calculate".tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              onPressed: () {
                                if (_fromId == null || _toId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("Please select both stations first".tr()),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                  return;
                                }
                                if (_fromId == _toId) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("⚠️ Choose a different destination!".tr()),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                  return;
                                }
                                context.read<RoutePlannerCubit>().findPath(_fromId!, _toId!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Result area ───────────────────────────────────────
                  BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
                    builder: (context, state) {
                      if (state is RoutePlannerLoading) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Shimmer.fromColors(
                          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                          child: Container(
                            height: 180,
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }
                      if (state is RoutePlannerError) {
                        return FadeInUp(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error),
                                const SizedBox(width: 12),
                                Expanded(child: Text(state.message, style: const TextStyle(color: AppColors.error))),
                              ],
                            ),
                          ),
                        );
                      }
                      if (state is RoutePlannerLoaded) {
                        final estimatedMins = (state.stationCount * 2.5 + state.transfers * 3).round();
                        return _buildResultCard(context, isAr, state, estimatedMins);
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // ── Price guide card ──────────────────────────────────
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildPriceGuide(context, isAr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Passenger picker ─────────────────────────────────────────────────────
  Widget _buildPassengerPicker(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Number of Passengers".tr(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          // Minus button
          GestureDetector(
            onTap: () {
              if (_passengerCount > 1) setState(() => _passengerCount--);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _passengerCount > 1
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _passengerCount > 1
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.remove_rounded,
                size: 20,
                color: _passengerCount > 1 ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Count display
          SizedBox(
            width: 32,
            child: Text(
              '$_passengerCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Plus button
          GestureDetector(
            onTap: () {
              if (_passengerCount < 20) setState(() => _passengerCount++);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
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
      onTap: () async {
        final result = await StationSearchSheet.show(
          context,
          _allStations,
          selectedStationId: value,
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected != null ? lineColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.25),
            width: selected != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: selected != null ? lineColor.withValues(alpha: 0.04) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected != null ? lineColor : iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: selected == null
                  ? Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 14))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? selected.nameAr : selected.nameEn,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        Row(
                          children: [
                            Container(width: 8, height: 8,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle)),
                            Text(
                              isAr ? 'الخط ${selected.line}' : 'Line ${selected.line}',
                              style: TextStyle(fontSize: 11, color: lineColor, fontWeight: FontWeight.w600),
                            ),
                            if (selected.isTransfer) ...
                              [
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text("transfer".tr(),
                                      style: const TextStyle(fontSize: 9, color: AppColors.accent)),
                                ),
                              ],
                          ],
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


  Widget _buildResultCard(BuildContext context, bool isAr, RoutePlannerLoaded state, int mins) {
    final perPersonPrice = state.ticketPrice;
    final totalPrice = perPersonPrice * _passengerCount;
    final showTotal = _passengerCount > 1;

    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Price display
            if (showTotal) ...[
              Text(
                "Per Person".tr(),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                isAr ? '$perPersonPrice جنيه' : 'EGP $perPersonPrice',
                style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_alt_outlined, color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? '$_passengerCount أفراد' : '$_passengerCount people',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ] else ...[
              Text(
                "Amount to Pay".tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
            ],

            Text(
              isAr ? '$totalPrice جنيه' : 'EGP $totalPrice',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 46,
              ),
            ),

            if (showTotal)
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAr ? 'الإجمالي لـ $_passengerCount أفراد' : 'Total for $_passengerCount passengers',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultStat(
                  icon: Icons.stairs_outlined,
                  value: '${state.stationCount}',
                  label: "Stations".tr(),
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _resultStat(
                  icon: Icons.timer_outlined,
                  value: '$mins',
                  label: "Minutes".tr(),
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _resultStat(
                  icon: Icons.people_alt_outlined,
                  value: '$_passengerCount',
                  label: "People".tr(),
                ),
                if (state.transfers > 0) ...[
                  Container(width: 1, height: 40, color: Colors.white30),
                  _resultStat(
                    icon: Icons.swap_horiz_rounded,
                    value: '${state.transfers}',
                    label: "Transfer".tr(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultStat({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPriceGuide(BuildContext context, bool isAr) {
    // Official Cairo Metro ticket prices (as of 2026)
    final prices = [
      ("1–9 Stations".tr(), "ticket_price".tr(args: ["10"])),
      ("10–16 Stations".tr(), "ticket_price".tr(args: ["12"])),
      ("17–23 Stations".tr(), "ticket_price".tr(args: ["15"])),
      ("24+ Stations".tr(), "ticket_price".tr(args: ["20"])),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Official Ticket Price Guide".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...prices.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.$1, style: const TextStyle(fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.$2,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "These are single-trip prices. Monthly subscription cards differ.".tr(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
