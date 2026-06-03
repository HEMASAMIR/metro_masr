import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/widgets/station_search_sheet.dart';
import '../../../metro/domain/entities/station.dart';
import '../../../metro/presentation/cubits/route_planner/route_planner_cubit.dart';
import '../../../metro/presentation/cubits/route_planner/route_planner_state.dart';

class PricingCalculatorPage extends StatelessWidget {
  const PricingCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RoutePlannerCubit>(),
      child: const _PricingCalculatorView(),
    );
  }
}

class _PricingCalculatorView extends StatefulWidget {
  const _PricingCalculatorView();

  @override
  State<_PricingCalculatorView> createState() => _PricingCalculatorViewState();
}

class _PricingCalculatorViewState extends State<_PricingCalculatorView> {
  // Inputs
  String? _fromId;
  String? _toId;
  double _tripsPerDay = 2;
  double _workingDays = 22; // per month

  List<Station> get _allStations => MetroData.stations.values.toList();

  // Monthly subscription options
  static const Map<String, double> _subscriptions = {
    'zone1': 350.0,
    'zone2': 450.0,
    'zone3': 550.0,
    'unlimited': 650.0,
  };

  double _getMonthlySpend(double singleFare) => singleFare * _tripsPerDay * _workingDays;

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'حاسبة التذاكر الذكية' : "Smart Pricing Calculator"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commute Route Selector
            _buildRouteSelector(isAr),
            const SizedBox(height: 16),

            // Commute Habits
            _buildInputsCard(isAr),
            const SizedBox(height: 16),

            // Dynamic Results
            BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
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
                    color: Colors.red.withOpacity(0.1),
                    child: Text(state.message, style: const TextStyle(color: Colors.red)),
                  );
                }
                if (state is RoutePlannerLoaded) {
                  final singleFare = state.ticketPrice.toDouble();
                  final spend = _getMonthlySpend(singleFare);
                  String zone = 'zone4';
                  double applicableSub = _subscriptions['unlimited']!;
                  if (state.stationCount <= 9) {
                    zone = 'zone1';
                    applicableSub = _subscriptions['zone1']!;
                  } else if (state.stationCount <= 16) {
                    zone = 'zone2';
                    applicableSub = _subscriptions['zone2']!;
                  } else if (state.stationCount <= 23) {
                    zone = 'zone3';
                    applicableSub = _subscriptions['zone3']!;
                  }
                  
                  final savings = (spend - applicableSub).clamp(0.0, double.infinity);

                  return Column(
                    children: [
                      _buildResultsCard(isAr, singleFare, spend, savings, zone),
                      const SizedBox(height: 16),
                      _buildComparisonCard(isAr, spend),
                      const SizedBox(height: 16),
                      _buildRecommendationCard(isAr, spend),
                    ],
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(child: Text(isAr ? 'اختار محطات رحلتك اليومية واضغط احسب عشان تشوف التوفير المتوقع!' : "Select your daily commute stations and tap Calculate to see your smart subscription savings!")),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFareTable(isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSelector(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(isAr ? 'مسار رحلتك' : "Your Daily Commute",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStationPicker(
            isAr: isAr,
            hint: isAr ? 'محطة البداية' : "Start Station",
            icon: Icons.radio_button_checked,
            iconColor: AppColors.success,
            value: _fromId,
            onChanged: (v) => setState(() => _fromId = v),
          ),
          const SizedBox(height: 12),
          _buildStationPicker(
            isAr: isAr,
            hint: isAr ? 'محطة الوصول' : "Destination Station",
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            value: _toId,
            onChanged: (v) => setState(() => _toId = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.calculate, size: 20),
              label: Text(isAr ? 'احسب التوفير' : "Calculate Subscription Savings", style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (_fromId == null || _toId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'برجاء اختيار المحطات أولاً' : "Please select stations")));
                  return;
                }
                if (_fromId == _toId) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'برجاء اختيار محطتين مختلفتين' : "Please select different stations")));
                  return;
                }
                context.read<RoutePlannerCubit>().findPath(_fromId!, _toId!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationPicker({
    required bool isAr,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedStation = _allStations.where((s) => s.id == value).firstOrNull;
    final displayName = selectedStation != null ? (isAr ? selectedStation.nameAr : selectedStation.nameEn) : hint;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await StationSearchSheet.show(context, _allStations);
          if (result != null) {
            onChanged(result);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              if (selectedStation != null) ...[
                 Container(
                   width: 10, height: 10,
                   decoration: BoxDecoration(
                     color: selectedStation.line == 1 ? AppColors.line1 : selectedStation.line == 2 ? AppColors.line2 : AppColors.line3,
                     shape: BoxShape.circle,
                   )
                 ),
                 const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedStation != null ? null : Colors.grey[600],
                    fontWeight: selectedStation != null ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputsCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(isAr ? 'عادات الاستخدام' : "Commute Habits",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),

          _sliderField(
            label: isAr ? 'الرحلات يومياً' : "Trips per Day",
            value: _tripsPerDay,
            min: 1,
            max: 8,
            divisions: 7,
            displayValue: '${_tripsPerDay.round()}',
            onChanged: (v) {
              setState(() => _tripsPerDay = v);
              if (context.read<RoutePlannerCubit>().state is RoutePlannerLoaded) {
                 context.read<RoutePlannerCubit>().findPath(_fromId!, _toId!);
              }
            },
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),

          _sliderField(
            label: isAr ? 'أيام العمل / الشهر' : "Working Days / Month",
            value: _workingDays,
            min: 15,
            max: 30,
            divisions: 15,
            displayValue: '${_workingDays.round()}',
            onChanged: (v) {
              setState(() => _workingDays = v);
              if (context.read<RoutePlannerCubit>().state is RoutePlannerLoaded) {
                 context.read<RoutePlannerCubit>().findPath(_fromId!, _toId!);
              }
            },
            color: AppColors.line3,
          ),
        ],
      ),
    );
  }

  Widget _sliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(displayValue,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            overlayColor: color.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCard(bool isAr, double singleFare, double spend, double savings, String zone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _resultBubble(
                isAr ? 'سعر التذكرة' : "Single Fare",
                '${singleFare.toStringAsFixed(0)} ${isAr ? 'جنيه' : "EGP"}',
                AppColors.primary,
                Icons.confirmation_number_outlined,
              ),
              const SizedBox(width: 12),
              _resultBubble(
                isAr ? 'التكلفة الشهرية' : "Monthly Spend",
                '${spend.toStringAsFixed(0)} ${isAr ? 'جنيه' : "EGP"}',
                Colors.orange,
                Icons.calendar_month,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _resultBubble(
                isAr ? 'التوفير المتوقع' : "Potential Savings",
                savings > 0 ? '${savings.toStringAsFixed(0)} ${isAr ? 'جنيه' : "EGP"}' : (isAr ? 'لا يوجد' : "None"),
                Colors.green,
                Icons.savings_outlined,
              ),
              const SizedBox(width: 12),
              _resultBubble(
                isAr ? 'المنطقة' : "Price Zone",
                isAr
                    ? (zone == 'zone1' ? 'منطقة 1' : zone == 'zone2' ? 'منطقة 2' : zone == 'zone3' ? 'منطقة 3' : 'منطقة 4')
                    : (zone == 'zone1' ? 'Zone 1' : zone == 'zone2' ? 'Zone 2' : zone == 'zone3' ? 'Zone 3' : 'Zone 4'),
                Colors.purple,
                Icons.map_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultBubble(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(bool isAr, double spend) {
    final options = [
      (isAr ? 'تذاكر عادية' : "Single Tickets", spend, AppColors.primary),
      (isAr ? 'اشتراك منطقة (9 محطات)' : "1 Zone Package", _subscriptions['zone1']!, AppColors.line1),
      (isAr ? 'اشتراك منطقتين (16 محطة)' : "2 Zones Package", _subscriptions['zone2']!, AppColors.line2),
      (isAr ? 'اشتراك 3-4 مناطق' : "3-4 Zones Package", _subscriptions['zone3']!, AppColors.line3),
      (isAr ? 'غير محدود (5-6 مناطق)' : "Unlimited", _subscriptions['unlimited']!, Colors.purple),
    ];
    final minCost = options.map((o) => o.$2).reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(isAr ? 'مقارنة الخيارات' : "Options Comparison",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final isBest = opt.$2 == minCost;
            final percentage = opt.$2 / options.map((o) => o.$2).reduce((a, b) => a > b ? a : b);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(opt.$1, style: TextStyle(fontSize: 13, fontWeight: isBest ? FontWeight.bold : FontWeight.normal)),
                          if (isBest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(isAr ? 'الأفضل' : "Best",
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${opt.$2.toStringAsFixed(0)} ${isAr ? 'جنيه/شهر' : "EGP/mo"}',
                        style: TextStyle(
                          color: opt.$3,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: opt.$3.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(
                        isBest ? Colors.green : opt.$3.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(bool isAr, double spend) {
    Color color;
    String text;
    if (spend >= _subscriptions['unlimited']!) {
      color = Colors.green;
      text = isAr
          ? 'الاشتراك الشهري غير المحدود (650 جنيه) يوفر عليك ${(spend - 650).toStringAsFixed(0)} جنيه!'
          : 'Unlimited monthly sub (650 EGP) saves you ${(spend - 650).toStringAsFixed(0)} EGP!';
    } else if (spend >= _subscriptions['zone2']!) {
      color = Colors.orange;
      text = isAr ? 'اشتراك المنطقتين (450 جنيه) هيكون أوفر ليك للرحلات المتوسطة!' : "The 2 Zones package (450 EGP) may save you money!";
    } else if (spend >= _subscriptions['zone1']!) {
      color = Colors.orange;
      text = isAr ? 'اشتراك المنطقة الواحدة (350 جنيه) مناسب لمشوارك!' : "The 1 Zone package (350 EGP) is perfect for you!";
    } else {
      color = Colors.blue;
      text = isAr ? 'شراء التذاكر العادية أرخص ليك، استمر!' : "Single tickets are cheaper for your usage — keep it up!";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'رفيق ينصح' : "Rafiq Recommends",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareTable(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'أسعار التذاكر 2026' : "Fare Schedule 2026",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey[200]!, borderRadius: BorderRadius.circular(8)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
                children: [
                  _tableCell(isAr ? 'المحطات' : "Stations", isHeader: true),
                  _tableCell(isAr ? 'السعر' : "Fare", isHeader: true),
                  _tableCell(isAr ? 'المنطقة' : "Zone", isHeader: true),
                ],
              ),
              _tableRow('1 – 9', '8 ${isAr ? 'جنيه' : "EGP"}', isAr ? 'منطقة 1' : "Zone 1"),
              _tableRow('10 – 16', '10 ${isAr ? 'جنيه' : "EGP"}', isAr ? 'منطقة 2' : "Zone 2"),
              _tableRow('17 – 23', '15 ${isAr ? 'جنيه' : "EGP"}', isAr ? 'منطقة 3' : "Zone 3"),
              _tableRow('24+', '20 ${isAr ? 'جنيه' : "EGP"}', isAr ? 'منطقة 4' : "Zone 4"),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String col1, String col2, String col3) {
    return TableRow(children: [
      _tableCell(col1),
      _tableCell(col2),
      _tableCell(col3),
    ]);
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 13 : 12,
        ),
      ),
    );
  }
}
