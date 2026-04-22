import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/station.dart';
import '../widgets/indoor_map_widget.dart';
import '../widgets/station_marketplace_widget.dart';

class StationDetailsPage extends StatelessWidget {
  final Station station;

  const StationDetailsPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final name = context.locale.languageCode == 'ar' ? station.nameAr : station.nameEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: _getLineColor(station.line),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(r.pagePadding),
            child: r.useSideBySideLayout
                ? _buildWideLayout(context, r)
                : _buildNarrowLayout(context, r),
          ),
        ),
      ),
    );
  }

  // ── Narrow layout (phone portrait) ────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _contentSections(context, r),
    );
  }

  // ── Wide layout (tablet / landscape) ─────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, Responsive r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: header + facilities
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(child: _buildHeader(context, r)),
              SizedBox(height: r.sectionSpacing),
              if (station.hasElevator || station.hasRamp) ...[
                FadeInUp(delay: const Duration(milliseconds: 150), child: _buildAccessibilitySection(context, r)),
                SizedBox(height: r.sectionSpacing),
              ],
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildSectionTitle('facilities'.tr(), r),
              ),
              SizedBox(height: r.sectionSpacing * 0.75),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _buildFacilitiesGrid(context, r),
              ),
            ],
          ),
        ),
        SizedBox(width: r.pagePadding),
        // Right: exits + report
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildSectionTitle('exit_guide'.tr(), r),
              ),
              SizedBox(height: r.sectionSpacing * 0.75),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _buildExitsList(context, r),
              ),
              SizedBox(height: r.sectionSpacing),
              FadeInUp(
                delay: const Duration(milliseconds: 550),
                child: StationMarketplaceWidget(stationName: context.locale.languageCode == 'ar' ? station.nameAr : station.nameEn),
              ),
              SizedBox(height: r.sectionSpacing),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: _buildReportButton(context, r),
              ),
              SizedBox(height: r.sectionSpacing),
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: _buildSectionTitle('indoor_map'.tr(), r),
              ),
              SizedBox(height: r.sectionSpacing * 0.75),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: IndoorMapWidget(station: station),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _contentSections(BuildContext context, Responsive r) {
    return [
      FadeInDown(child: _buildHeader(context, r)),
      SizedBox(height: r.sectionSpacing),
      if (station.hasElevator || station.hasRamp) ...[
        FadeInUp(delay: const Duration(milliseconds: 150), child: _buildAccessibilitySection(context, r)),
        SizedBox(height: r.sectionSpacing),
      ],
      FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: _buildSectionTitle('facilities'.tr(), r),
      ),
      SizedBox(height: r.sectionSpacing * 0.75),
      FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: _buildFacilitiesGrid(context, r),
      ),
      SizedBox(height: r.sectionSpacing),
      FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: _buildSectionTitle('exit_guide'.tr(), r),
      ),
      SizedBox(height: r.sectionSpacing * 0.75),
      FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: _buildExitsList(context, r),
      ),
      SizedBox(height: r.sectionSpacing),
      FadeInUp(
        delay: const Duration(milliseconds: 550),
        child: StationMarketplaceWidget(stationName: context.locale.languageCode == 'ar' ? station.nameAr : station.nameEn),
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 600),
        child: _buildReportButton(context, r),
      ),
      SizedBox(height: r.sectionSpacing),
      FadeInUp(
        delay: const Duration(milliseconds: 700),
        child: _buildSectionTitle('indoor_map'.tr(), r),
      ),
      SizedBox(height: r.sectionSpacing * 0.75),
      FadeInUp(
        delay: const Duration(milliseconds: 800),
        child: IndoorMapWidget(station: station),
      ),
    ];
  }

  Widget _buildHeader(BuildContext context, Responsive r) {
    final lineColor = _getLineColor(station.line);
    return Container(
      padding: EdgeInsets.all(r.pagePadding * 0.8),
      decoration: BoxDecoration(
        color: lineColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r.cardRadius),
        border: Border.all(color: lineColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: lineColor,
            radius: r.isTablet ? 38 : 30,
            child: Icon(Icons.train, color: Colors.white, size: r.iconSize(28)),
          ),
          SizedBox(width: r.sectionSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'line'.tr(args: [station.line.toString()]),
                  style: TextStyle(
                    color: lineColor,
                    fontWeight: FontWeight.bold,
                    fontSize: r.fontSize(17),
                  ),
                ),
                Text(
                  station.isTransfer ? 'transfer_station'.tr() : 'regular_station'.tr(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: r.fontSize(13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Responsive r) {
    return Text(
      title,
      style: TextStyle(fontSize: r.fontSize(19), fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAccessibilitySection(BuildContext context, Responsive r) {
    if (!station.hasElevator && !station.hasRamp) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context.locale.languageCode == 'ar' ? 'تجهيزات ذوي الهمم ♿' : 'Accessibility ♿', r),
        SizedBox(height: r.sectionSpacing * 0.75),
        Row(
          children: [
            if (station.hasElevator)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.elevator, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.locale.languageCode == 'ar' ? 'مصعد متوفر' : 'Elevator', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
                    ],
                  ),
                ),
              ),
            if (station.hasRamp)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.accessible, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.locale.languageCode == 'ar' ? 'رامب متحرك' : 'Ramp Access', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilitiesGrid(BuildContext context, Responsive r) {
    if (station.facilities.isEmpty) {
      return Text('no_facilities'.tr(), style: const TextStyle(color: AppColors.textSecondary));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: r.gridColumns < 2 ? 2 : r.gridColumns,
        childAspectRatio: r.isTablet ? 3.5 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: station.facilities.length,
      itemBuilder: (context, index) {
        final facility = station.facilities[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
            ],
          ),
          child: Row(
            children: [
              Icon(_getFacilityIcon(facility), size: r.iconSize(18), color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(facility.tr(), style: TextStyle(fontSize: r.fontSize(13))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExitsList(BuildContext context, Responsive r) {
    if (station.exits.isEmpty) {
      return Text('no_exits'.tr(), style: const TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      children: station.exits.map((exit) {
        final exitName = context.locale.languageCode == 'ar' ? exit['ar'] : exit['en'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(r.isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(r.cardRadius),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.door_front_door_outlined, color: AppColors.accent, size: r.iconSize(22)),
              const SizedBox(width: 16),
              Expanded(child: Text(exitName ?? '', style: TextStyle(fontSize: r.fontSize(14)))),
              Icon(Icons.chevron_right, color: Colors.grey, size: r.iconSize(22)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportButton(BuildContext context, Responsive r) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.report_problem_outlined, size: r.iconSize(20)),
        label: Text('report_status'.tr(), style: TextStyle(fontSize: r.fontSize(14))),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: r.isTablet ? 20 : 16),
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _showReportBottomSheet(context, r),
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context, Responsive r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(r.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('report_status'.tr(),
                  style: TextStyle(fontSize: r.fontSize(17), fontWeight: FontWeight.bold)),
              SizedBox(height: r.sectionSpacing),
              _buildReportOption(context, Icons.people, 'crowded'.tr(), AppColors.accent),
              _buildReportOption(context, Icons.timer, 'delay'.tr(), AppColors.warning),
              _buildReportOption(context, Icons.handyman, 'elevator_broken'.tr(), Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(BuildContext context, IconData icon, String label, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('report_received'.tr()), backgroundColor: AppColors.success),
        );
      },
    );
  }

  Color _getLineColor(int line) {
    switch (line) {
      case 1: return AppColors.line1;
      case 2: return AppColors.line2;
      case 3: return AppColors.line3;
      default: return AppColors.primary;
    }
  }

  IconData _getFacilityIcon(String facility) {
    switch (facility) {
      case 'atm': return Icons.atm;
      case 'wc': return Icons.wc;
      case 'elevator': return Icons.elevator;
      case 'ticket_office': return Icons.confirmation_number_outlined;
      case 'police_station': return Icons.local_police_outlined;
      default: return Icons.info_outline;
    }
  }
}
