import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class PricingCalculatorPage extends StatefulWidget {
  const PricingCalculatorPage({super.key});

  @override
  State<PricingCalculatorPage> createState() => _PricingCalculatorPageState();
}

class _PricingCalculatorPageState extends State<PricingCalculatorPage> {
  // Inputs
  double _tripsPerDay = 2;
  double _stationsPerTrip = 10;
  double _workingDays = 22; // per month
  String _zone = 'zone2'; // zone1: <=9, zone2: 10-16, zone3: 17-23, zone4: >23

  // Single trip fare by zones (EGP 2024)
  static const Map<String, double> _zoneFares = {
    'zone1': 8.0,
    'zone2': 10.0,
    'zone3': 15.0,
    'zone4': 20.0,
  };

  // Monthly subscription options
  static const Map<String, double> _subscriptions = {
    'unlimited': 350.0,
    'zone1_2': 200.0,
    'zone1_3': 280.0,
  };

  double get _singleFare => _zoneFares[_zone] ?? 10.0;
  double get _monthlySpend => _singleFare * _tripsPerDay * _workingDays;
  double get _bestSubscription {
    final unlimited = _subscriptions['unlimited']!;
    final savings = _monthlySpend - unlimited;
    if (_monthlySpend >= unlimited) return unlimited;
    return _monthlySpend; // No sub needed
  }

  String get _recommendation {
    final isAr = context.locale.languageCode == 'ar';
    if (_monthlySpend >= _subscriptions['unlimited']!) {
      return isAr
          ? 'الاشتراك الشهري غير المحدود (350 جنيه) يوفر عليك ${(_monthlySpend - 350).toStringAsFixed(0)} جنيه!'
          : 'Unlimited monthly sub (350 EGP) saves you ${(_monthlySpend - 350).toStringAsFixed(0)} EGP!';
    } else if (_monthlySpend >= _subscriptions['zone1_2']!) {
      return isAr
          ? 'باقة المنطقتين (200 جنيه) قد توفر عليك!'
          : 'The Zone 1+2 package (200 EGP) may save you money!';
    } else {
      return isAr
          ? 'التذاكر الفردية أوفر لاستخدامك الحالي — استمر!'
          : 'Single tickets are cheaper for your usage — keep it up!';
    }
  }

  Color get _recommendationColor {
    if (_monthlySpend >= _subscriptions['unlimited']!) return Colors.green;
    if (_monthlySpend >= _subscriptions['zone1_2']!) return Colors.orange;
    return Colors.blue;
  }

  void _updateZone() {
    final stations = _stationsPerTrip.round();
    if (stations <= 9) {
      _zone = 'zone1';
    } else if (stations <= 16) {
      _zone = 'zone2';
    } else if (stations <= 23) {
      _zone = 'zone3';
    } else {
      _zone = 'zone4';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final savings = (_monthlySpend - 350).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'حاسبة التكاليف الذكية' : 'Smart Pricing Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inputs card
            _buildInputsCard(isAr),
            const SizedBox(height: 16),

            // Results card
            _buildResultsCard(isAr, savings),
            const SizedBox(height: 16),

            // Comparison table
            _buildComparisonCard(isAr),
            const SizedBox(height: 16),

            // Recommendation card
            _buildRecommendationCard(isAr),
            const SizedBox(height: 16),

            // Fare reference
            _buildFareTable(isAr),
          ],
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
              Text(isAr ? 'ضبط العادات' : 'Adjust Your Habits',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),

          _sliderField(
            label: isAr ? 'عدد الرحلات يومياً' : 'Trips per Day',
            value: _tripsPerDay,
            min: 1,
            max: 8,
            divisions: 7,
            displayValue: '${_tripsPerDay.round()}',
            onChanged: (v) => setState(() => _tripsPerDay = v),
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),

          _sliderField(
            label: isAr ? 'عدد المحطات في الرحلة' : 'Stations per Trip',
            value: _stationsPerTrip,
            min: 2,
            max: 35,
            divisions: 33,
            displayValue: '${_stationsPerTrip.round()}',
            onChanged: (v) => setState(() {
              _stationsPerTrip = v;
              _updateZone();
            }),
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),

          _sliderField(
            label: isAr ? 'أيام العمل شهرياً' : 'Working Days / Month',
            value: _workingDays,
            min: 15,
            max: 30,
            divisions: 15,
            displayValue: '${_workingDays.round()}',
            onChanged: (v) => setState(() => _workingDays = v),
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

  Widget _buildResultsCard(bool isAr, double savings) {
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
                isAr ? 'تذكرة واحدة' : 'Single Fare',
                '${_singleFare.toStringAsFixed(0)} ${isAr ? 'ج' : 'EGP'}',
                AppColors.primary,
                Icons.confirmation_number_outlined,
              ),
              const SizedBox(width: 12),
              _resultBubble(
                isAr ? 'مصروف شهري' : 'Monthly Spend',
                '${_monthlySpend.toStringAsFixed(0)} ${isAr ? 'ج' : 'EGP'}',
                Colors.orange,
                Icons.calendar_month,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _resultBubble(
                isAr ? 'توفير محتمل' : 'Potential Savings',
                savings > 0 ? '${savings.toStringAsFixed(0)} ${isAr ? 'ج' : 'EGP'}' : (isAr ? 'لا شيء' : 'None'),
                Colors.green,
                Icons.savings_outlined,
              ),
              const SizedBox(width: 12),
              _resultBubble(
                isAr ? 'المنطقة السعرية' : 'Price Zone',
                isAr
                    ? (_zone == 'zone1' ? 'منطقة 1' : _zone == 'zone2' ? 'منطقة 2' : _zone == 'zone3' ? 'منطقة 3' : 'منطقة 4')
                    : (_zone == 'zone1' ? 'Zone 1' : _zone == 'zone2' ? 'Zone 2' : _zone == 'zone3' ? 'Zone 3' : 'Zone 4'),
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

  Widget _buildComparisonCard(bool isAr) {
    final options = [
      (isAr ? 'تذاكر فردية' : 'Single Tickets', _monthlySpend, AppColors.primary),
      (isAr ? 'باقة منطقتين' : 'Zone 1+2 Package', 200.0, AppColors.line2),
      (isAr ? 'باقة 3 مناطق' : 'Zone 1+3 Package', 280.0, AppColors.line3),
      (isAr ? 'غير محدود' : 'Unlimited', 350.0, Colors.purple),
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
              Text(isAr ? 'مقارنة الخيارات' : 'Options Comparison',
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
                              child: Text(isAr ? 'الأوفر' : 'Best',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${opt.$2.toStringAsFixed(0)} ${isAr ? 'ج/شهر' : 'EGP/mo'}',
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

  Widget _buildRecommendationCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _recommendationColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _recommendationColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: _recommendationColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'توصية رفيق' : 'Rafiq Recommends',
                  style: TextStyle(
                    color: _recommendationColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_recommendation, style: const TextStyle(fontSize: 13, height: 1.5)),
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
          Text(isAr ? 'جدول الأسعار 2024' : 'Fare Schedule 2024',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey[200]!, borderRadius: BorderRadius.circular(8)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
                children: [
                  _tableCell(isAr ? 'المحطات' : 'Stations', isHeader: true),
                  _tableCell(isAr ? 'السعر' : 'Fare', isHeader: true),
                  _tableCell(isAr ? 'المنطقة' : 'Zone', isHeader: true),
                ],
              ),
              _tableRow('1 – 9', '8 ${isAr ? 'ج' : 'EGP'}', isAr ? 'منطقة 1' : 'Zone 1'),
              _tableRow('10 – 16', '10 ${isAr ? 'ج' : 'EGP'}', isAr ? 'منطقة 2' : 'Zone 2'),
              _tableRow('17 – 23', '15 ${isAr ? 'ج' : 'EGP'}', isAr ? 'منطقة 3' : 'Zone 3'),
              _tableRow('24+', '20 ${isAr ? 'ج' : 'EGP'}', isAr ? 'منطقة 4' : 'Zone 4'),
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
