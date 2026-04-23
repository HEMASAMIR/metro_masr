import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/station.dart';
import '../cubits/route_planner/route_planner_cubit.dart';
import '../cubits/route_planner/route_planner_state.dart';

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

  List<Station> get _allStations => MetroData.stations.values.toList();

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final r = context.responsive;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isAr ? 'سعر تذكرة المترو' : 'Ticket Price Calculator'),
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
                    isAr ? 'احسب سعر مشوارك' : 'Calculate Your Trip Cost',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'اختار محطة البداية والوصول وهنحسبلك السعر والوقت'
                        : "Select start & end stations — we'll calculate price & time",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(r.pagePadding),
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
                            hint: isAr ? 'محطة البداية' : 'Start Station',
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
                            hint: isAr ? 'محطة الوصول' : 'Destination Station',
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.error,
                            value: _toId,
                            onChanged: (v) => setState(() => _toId = v),
                          ),

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
                                isAr ? 'احسب' : 'Calculate',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              onPressed: () {
                                if (_fromId == null || _toId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(isAr ? 'اختار محطة البداية والوصول أولاً' : 'Please select both stations first'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                  return;
                                }
                                if (_fromId == _toId) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(isAr ? '⚠️ اختار محطة وصول مختلفة!' : '⚠️ Choose a different destination!'),
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
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
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

  Widget _buildStationPicker({
    required BuildContext context,
    required bool isAr,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _allStations.map((s) {
                  final lineColor = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;
                  return DropdownMenuItem(
                    value: s.id,
                    child: Row(
                      children: [
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr ? s.nameAr : s.nameEn,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (s.isTransfer)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAr ? 'تبديل' : 'transfer',
                              style: const TextStyle(fontSize: 9, color: AppColors.accent),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, bool isAr, RoutePlannerLoaded state, int mins) {
    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isAr ? 'المبلغ اللي هتدفع' : 'Amount to Pay',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? '${state.ticketPrice} جنيه' : 'EGP ${state.ticketPrice}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 42,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultStat(
                  icon: Icons.stairs_outlined,
                  value: '${state.stationCount}',
                  label: isAr ? 'محطات' : 'Stations',
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _resultStat(
                  icon: Icons.timer_outlined,
                  value: '$mins',
                  label: isAr ? 'دقيقة' : 'Minutes',
                ),
                if (state.transfers > 0) ...[
                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                  _resultStat(
                    icon: Icons.swap_horiz_rounded,
                    value: '${state.transfers}',
                    label: isAr ? 'تحويل' : 'Transfer',
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
    // Official Cairo Metro ticket prices (as of 2024)
    final prices = [
      (isAr ? '1 – 9 محطات' : '1–9 Stations', isAr ? '8 جنيه' : 'EGP 8'),
      (isAr ? '10 – 16 محطة' : '10–16 Stations', isAr ? '10 جنيه' : 'EGP 10'),
      (isAr ? '17 – 23 محطة' : '17–23 Stations', isAr ? '15 جنيه' : 'EGP 15'),
      (isAr ? '24+ محطة' : '24+ Stations', isAr ? '20 جنيه' : 'EGP 20'),
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
                isAr ? 'جدول أسعار التذاكر' : 'Official Ticket Price Guide',
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
                    isAr
                        ? 'الأسعار دي للتذكرة العادية. تذكرة الاشتراك الشهري بسعر مختلف.'
                        : 'These are single-trip prices. Monthly subscription cards differ.',
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
