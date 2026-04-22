import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class SubscriptionOptimizerPage extends StatefulWidget {
  const SubscriptionOptimizerPage({super.key});

  @override
  State<SubscriptionOptimizerPage> createState() => _SubscriptionOptimizerPageState();
}

class _SubscriptionOptimizerPageState extends State<SubscriptionOptimizerPage> {
  int _tripsPerWeek = 10;
  int _stationsCount = 5;
  String _recommendation = "";
  String _ticketColor = "";
  double _singlePrice = 0.0;
  double _subscriptionPrice = 0.0;

  void _calculate() {
    // Prices effective 27 March 2026 (official Ministry of Transport rates)
    if (_stationsCount <= 9) {
      _singlePrice = 10;
      _ticketColor = 'أصفر (Yellow)';
      _subscriptionPrice = 350;
    } else if (_stationsCount <= 16) {
      _singlePrice = 12;
      _ticketColor = 'أخضر (Green)';
      _subscriptionPrice = 450;
    } else if (_stationsCount <= 23) {
      _singlePrice = 15;
      _ticketColor = 'وردي (Pink)';
      _subscriptionPrice = 550;
    } else {
      _singlePrice = 20;
      _ticketColor = 'أحمر (Red)';
      _subscriptionPrice = 650;
    }

    double weeklyCost = _singlePrice * _tripsPerWeek;
    double monthlyCost = weeklyCost * 4.3;

    if (monthlyCost > _subscriptionPrice) {
      _recommendation =
          'الاشتراك الشهري أوفر! هتوفر ${(monthlyCost - _subscriptionPrice).round()} جنيه شهرياً.';
    } else {
      _recommendation = 'شراء التذاكر الفردية أوفر لك حالياً.';
    }
    setState(() {});
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
          if (_recommendation.isNotEmpty) ...[
            SizedBox(height: r.sectionSpacing),
            FadeInUp(child: _buildResultCard(context, r)),
          ],
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
          if (_recommendation.isNotEmpty) ...[
            SizedBox(width: r.pagePadding),
            Expanded(
              child: FadeInUp(child: _buildResultCard(context, r)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, Responsive r) {
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
          Text(
            'trips_per_week'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(15)),
          ),
          Slider(
            value: _tripsPerWeek.toDouble(),
            min: 1,
            max: 28,
            divisions: 27,
            label: _tripsPerWeek.toString(),
            onChanged: (val) => setState(() => _tripsPerWeek = val.round()),
          ),
          SizedBox(height: r.sectionSpacing),
          Text(
            'stations_count'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(15)),
          ),
          Slider(
            value: _stationsCount.toDouble(),
            min: 1,
            max: 39,
            divisions: 38,
            label: _stationsCount.toString(),
            activeColor: AppColors.line3,
            onChanged: (val) => setState(() => _stationsCount = val.round()),
          ),
          SizedBox(height: r.sectionSpacing * 1.5),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: r.isTablet ? 20 : 16),
                textStyle: TextStyle(fontSize: r.fontSize(15)),
              ),
              onPressed: _calculate,
              child: Text('calculate'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Responsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.pagePadding),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r.cardRadius),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.stars, color: AppColors.success, size: r.iconSize(40)),
          SizedBox(height: r.sectionSpacing * 0.75),
          Text(
            'التذكرة المناسبة: $_ticketColor\nالسعر الفردي: $_singlePrice جنيه',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: r.fontSize(15),
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: r.sectionSpacing * 0.75),
          Text(
            _recommendation,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: r.fontSize(15), color: AppColors.success, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
