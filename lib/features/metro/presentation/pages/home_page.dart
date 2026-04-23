import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/gamification_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/voice_service.dart';
import '../cubits/nearby_stations_cubit.dart';
import '../widgets/feature_card.dart';
import '../../domain/entities/station.dart';
import 'route_planner_page.dart';
import 'map_page.dart';
import 'nearby_stations_page.dart';
import 'subscription_optimizer_page.dart';
import 'ar_navigation_page.dart';
import '../../../community/presentation/pages/community_page.dart';
import 'nfc_wallet_page.dart';
import '../widgets/tourist_translator_modal.dart';

import '../../../community/presentation/pages/lost_and_found_page.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../crowd_prediction/presentation/pages/crowd_prediction_page.dart';
import '../../../gamification/presentation/pages/achievements_page.dart';
import '../../../trip_scheduler/presentation/pages/trip_scheduler_page.dart';
import '../../../pricing_calculator/presentation/pages/pricing_calculator_page.dart';

import '../../../voice_command/presentation/voice_command_service.dart';
import '../../../impact/presentation/pages/impact_dashboard_page.dart';
import '../../../tourism/presentation/pages/tourist_attractions_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NearbyStationsCubit>()..getNearbyStations(),
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePageView> {
  // ── Quick trip planner – uses ALL stations (user picks line automatically) ─
  String? _fromStation;
  String? _toStation;

  // ── Metro type toggle (for info section only) ────────────────────────────
  int _metroType = 0; // 0 = Cairo Metro, 1 = Capital Metro

  @override
  void initState() {
    super.initState();
  }

  List<Station> get _allStations => MetroData.stations.values.toList();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final padding = r.pagePadding;
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (Locale locale) => context.setLocale(locale),
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('English')),
              const PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
              const PopupMenuItem(value: Locale('fr'), child: Text('Français')),
              const PopupMenuItem(value: Locale('de'), child: Text('Deutsch')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final svc = VoiceCommandService.of(context);
          if (svc != null) {
            svc.startListening();
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _VoiceCommandSheet(isAr: isAr),
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.mic, color: Colors.white),
        tooltip: 'Voice Command',
      ),
      body: VoiceCommandService(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────────────────────
                  FadeInDown(
                    child: Text(
                      isAr ? 'رايح فين النهاردة؟ 🚇' : 'Where to today? 🚇',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: r.fontSize(26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeInDown(
                    delay: const Duration(milliseconds: 40),
                    child: Text(
                      isAr ? 'اكتب محطة البداية والنهاية وهنوريلك الطريق' : "Enter your start & destination – we'll find the way",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                  SizedBox(height: r.sectionSpacing),

                  // ── BIG TRIP PLANNER card (all stations) ─────────────────
                  FadeInDown(
                    delay: const Duration(milliseconds: 80),
                    child: _buildMainTripPlanner(context, isAr),
                  ),
                  SizedBox(height: r.sectionSpacing),

                  // ── Metro type info toggle ────────────────────────────────
                  FadeInDown(
                    delay: const Duration(milliseconds: 120),
                    child: _buildMetroTypeToggle(context, isAr),
                  ),
                  if (_metroType == 1) ...[
                    SizedBox(height: r.sectionSpacing),
                    FadeInDown(
                      delay: const Duration(milliseconds: 140),
                      child: _buildCapitalMetroSection(context, isAr),
                    ),
                  ],
                  SizedBox(height: r.sectionSpacing),

                  // ── Nearest Station (GPS-based, real-time) ────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: _buildNearestStationLive(context, isAr),
                  ),
                  SizedBox(height: r.sectionSpacing * 1.5),

                  // ── Feature cards ─────────────────────────────────────────
                  r.featureGridColumns == 1
                      ? _buildFeatureList(context, r)
                      : _buildFeatureGrid(context, r),

                  SizedBox(height: r.sectionSpacing * 2),

                  Text(
                    'line_status'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: r.fontSize(20),
                    ),
                  ),
                  SizedBox(height: r.sectionSpacing * 0.75),

                  r.useSideBySideLayout
                      ? Row(
                          children: [
                            Expanded(child: _buildStatusCard('Line 1', _getRealisticLineStatus(1), AppColors.line1, context, r)),
                            SizedBox(width: r.sectionSpacing * 0.75),
                            Expanded(child: _buildStatusCard('Line 2', _getRealisticLineStatus(2), AppColors.line2, context, r)),
                            SizedBox(width: r.sectionSpacing * 0.75),
                            Expanded(child: _buildStatusCard('Line 3', _getRealisticLineStatus(3), AppColors.line3, context, r)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildStatusCard('Line 1', _getRealisticLineStatus(1), AppColors.line1, context, r),
                            _buildStatusCard('Line 2', _getRealisticLineStatus(2), AppColors.line2, context, r),
                            _buildStatusCard('Line 3', _getRealisticLineStatus(3), AppColors.line3, context, r),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Nearest Station Live (GPS-based) ─────────────────────────────────────
  Widget _buildNearestStationLive(BuildContext context, bool isAr) {
    return BlocBuilder<NearbyStationsCubit, NearbyStationsState>(
      builder: (context, state) {
        if (state is NearbyStationsLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 12),
                Text(isAr ? 'جاري تحديد موقعك...' : 'Locating you...', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        if (state is NearbyStationsError) {
          return GestureDetector(
            onTap: () => context.read<NearbyStationsCubit>().getNearbyStations(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded, color: AppColors.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'تعذّر تحديد موقعك' : 'Location unavailable', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                        Text(isAr ? 'اضغط هنا لتفعيل الموقع' : 'Tap to enable location', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.refresh_rounded, color: AppColors.error, size: 20),
                ],
              ),
            ),
          );
        }
        if (state is NearbyStationsLoaded && state.stations.isNotEmpty) {
          final nearest = state.stations.first;
          final s = nearest.station;
          final name = isAr ? s.nameAr : s.nameEn;
          final distM = nearest.distanceMetres;
          final distLabel = distM < 1000
              ? '${distM.round()} ${isAr ? 'م' : 'm'}'
              : '${(distM / 1000).toStringAsFixed(1)} ${isAr ? 'كم' : 'km'}';
          final walkMins = (distM / 83).ceil();
          final lineColor = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyStationsPage())),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lineColor.withValues(alpha: 0.25)),
                boxShadow: [BoxShadow(color: lineColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: lineColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.location_on_rounded, color: lineColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? '📍 أقرب محطة مترو' : '📍 Nearest Metro Station', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(isAr ? 'الخط ${s.line}' : 'Line ${s.line}', style: TextStyle(color: lineColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            const Icon(Icons.directions_walk_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text('$distLabel · ~$walkMins ${isAr ? 'د مشياً' : 'min walk'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Main Trip Planner (all stations, no line filter) ──────────────────────
  Widget _buildMainTripPlanner(BuildContext context, bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? '🗺️ خطط رحلتك' : '🗺️ Plan Your Trip',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            // FROM
            _buildSearchableStationDropdown(
              context: context,
              isAr: isAr,
              label: isAr ? '📍 من (محطة البداية)' : '📍 From (Start Station)',
              value: _fromStation,
              onChanged: (v) => setState(() => _fromStation = v),
            ),
            const SizedBox(height: 10),

            // Swap button
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  final tmp = _fromStation;
                  _fromStation = _toStation;
                  _toStation = tmp;
                }),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // TO
            _buildSearchableStationDropdown(
              context: context,
              isAr: isAr,
              label: isAr ? '🏁 إلى (محطة الوصول)' : '🏁 To (Destination)',
              value: _toStation,
              onChanged: (v) => setState(() => _toStation = v),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.directions_subway_rounded, size: 22),
                label: Text(
                  isAr ? 'ابحث عن رحلتي' : 'Find My Route',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  if (_fromStation == null || _toStation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isAr ? 'اختار محطة البداية والوصول الأول' : 'Please select both stations first'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                    return;
                  }
                  if (_fromStation == _toStation) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isAr ? '⚠️ اختار محطة وصول مختلفة!' : '⚠️ Choose a different destination!'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoutePlannerPage(
                        initialFrom: _fromStation,
                        initialTo: _toStation,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchableStationDropdown({
    required BuildContext context,
    required bool isAr,
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final stations = _allStations;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          dropdownColor: Colors.white,
          items: stations.map((s) {
            final lineColor = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;
            return DropdownMenuItem(
              value: s.id,
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr ? s.nameAr : s.nameEn,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  if (s.isTransfer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(isAr ? 'تحويل' : 'transfer', style: const TextStyle(fontSize: 9, color: AppColors.warning)),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────────────
  // ── Metro Type Toggle (مترو القاهرة / قطر العاصمة) ─────────────────────
  Widget _buildMetroTypeToggle(BuildContext context, bool isAr) {
    final types = [
      {
        'label': isAr ? 'مترو القاهرة' : 'Cairo Metro',
        'icon': Icons.directions_subway_rounded,
        'color': AppColors.primary,
        'sub': isAr ? '3 خطوط • 85 محطة' : '3 Lines • 85 Stations',
      },
      {
        'label': isAr ? 'قطر العاصمة' : 'Capital Metro',
        'icon': Icons.train_rounded,
        'color': const Color(0xFF9C27B0),
        'sub': isAr ? 'خط المونوريل الجديد' : 'New Monorail Line',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: List.generate(types.length, (i) {
          final t = types[i];
          final isSelected = i == _metroType;
          final color = t['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _metroType = i;
                _fromStation = null;
                _toStation = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      t['sub'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.80) : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── Capital Metro info card ──────────────────────────────────────────────
  Widget _buildCapitalMetroSection(BuildContext context, bool isAr) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.train_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'قطر العاصمة الإدارية' : 'Administrative Capital Metro',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _capitalInfoRow(Icons.route_outlined, isAr ? 'خط المونوريل: عدلي منصور ↔ العاصمة الإدارية' : 'Monorail: Adly Mansour ↔ Admin. Capital', isAr),
              const SizedBox(height: 8),
              _capitalInfoRow(Icons.access_time_rounded, isAr ? 'مدة الرحلة: ~60 دقيقة' : 'Journey time: ~60 minutes', isAr),
              const SizedBox(height: 8),
              _capitalInfoRow(Icons.payments_outlined, isAr ? 'سعر التذكرة: 20-40 جنيه' : 'Ticket price: 20-40 EGP', isAr),
              const SizedBox(height: 8),
              _capitalInfoRow(Icons.swap_horiz_rounded, isAr ? 'التحويل: من محطة عدلي منصور (خط 3)' : 'Transfer: from Adly Mansour Station (Line 3)', isAr),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF9C27B0), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'للسفر لمترو القاهرة (خطوط 1 و2 و3) اختار "مترو القاهرة" من فوق'
                      : 'To use Cairo Metro (Lines 1, 2 & 3) switch to "Cairo Metro" above',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _capitalInfoRow(IconData icon, String text, bool isAr) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
      ],
    );
  }



  String _getRealisticLineStatus(int lineId) {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Rush hours: 7-9 AM, 14-18 PM
    final isRushHour = (hour >= 7 && hour <= 9) || (hour >= 14 && hour <= 18);
    
    if (isRushHour) {
      if (lineId == 1 && now.minute % 3 == 0) return 'minor_delays'.tr();
      if (lineId == 2 && now.minute % 2 == 0) return 'minor_delays'.tr(); // Line 2 is notoriously more crowded
      if (lineId == 3 && now.minute % 7 == 0) return 'minor_delays'.tr();
    } else {
      // 10% chance of random delay outside rush hours based on current 10-minute window
      final window = now.minute ~/ 10; 
      if ((hour + lineId + window) % 9 == 0) return 'minor_delays'.tr();
    }
    
    return 'on_time'.tr();
  }

  Widget _buildHeroBanner(BuildContext context, Responsive r) {
    final isAr = context.locale.languageCode == 'ar';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF0A2E6E)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_subway_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'مترو مصر' : 'Cairo Metro',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        isAr ? '٣ خطوط • ٨٥ محطة' : '3 Lines • 85 Stations',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? 'يعمل' : 'Active',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isAr ? 'اخطط رحلتك الآن' : 'Plan Your Trip Now',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? 'اكتشف أسرع طريق بين أي محطتين في مصر' : 'Find the fastest route between any stations in Egypt',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_outlined, color: Color(0xFF1565C0), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'ابدأ التخطيط ←' : 'Start Planning →',
                    style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ── Single‑column list (phone portrait) ──────────────────────────────────
  Widget _buildFeatureList(BuildContext context, Responsive r) {
    final cards = _featureConfigs(context);
    return Column(
      children: cards
          .asMap()
          .entries
          .map((e) => Padding(
                padding: EdgeInsets.only(bottom: r.sectionSpacing),
                child: FadeInUp(
                  delay: Duration(milliseconds: 200 * e.key),
                  child: e.value,
                ),
              ))
          .toList(),
    );
  }

  // ── 2‑column grid (tablet / landscape) ───────────────────────────────────
  Widget _buildFeatureGrid(BuildContext context, Responsive r) {
    final cards = _featureConfigs(context);
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      final hasSecond = i + 1 < cards.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: r.sectionSpacing),
          child: Row(
            children: [
              Expanded(
                child: FadeInUp(
                  delay: Duration(milliseconds: 150 * i),
                  child: cards[i],
                ),
              ),
              if (hasSecond) ...[
                SizedBox(width: r.sectionSpacing),
                Expanded(
                  child: FadeInUp(
                    delay: Duration(milliseconds: 150 * (i + 1)),
                    child: cards[i + 1],
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  List<Widget> _featureConfigs(BuildContext context) {
    final lang = context.locale.languageCode;
    final isAr = lang == 'ar';
    void speak(String text) => VoiceService.speak(text, lang);

    return [
      FeatureCard(
        title: 'route_planner'.tr(),
        subtitle: 'route_subtitle'.tr(),
        icon: Icons.route_outlined,
        color: AppColors.primary,
        onTap: () {
          speak('route_planner'.tr());
          GamificationService.recordRoutePlan();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutePlannerPage()));
        },
      ),
      FeatureCard(
        title: 'interactive_map'.tr(),
        subtitle: 'map_subtitle'.tr(),
        icon: Icons.map_outlined,
        color: AppColors.line3,
        onTap: () {
          speak('interactive_map'.tr());
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
        },
      ),
      FeatureCard(
        title: 'nearby_stations'.tr(),
        subtitle: 'nearby_subtitle'.tr(),
        icon: Icons.my_location,
        color: AppColors.line2,
        onTap: () {
          speak('nearby_stations'.tr());
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyStationsPage()));
        },
      ),
      // ── NEW FEATURE 1: AI Trip Assistant ──────────────────────────────────
      FeatureCard(
        title: isAr ? 'رفيق الذكي 🤖' : 'AI Assistant 🤖',
        subtitle: isAr ? 'اسألني أي سؤال عن المترو' : 'Ask me anything about metro',
        icon: Icons.smart_toy_outlined,
        color: const Color(0xFF7C3AED),
        onTap: () {
          GamificationService.recordAiQuery();
          GamificationService.unlockBadge(BadgeType.aiUser);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantPage()));
        },
      ),
      // ── NEW FEATURE 2: Crowd Prediction ──────────────────────────────────
      FeatureCard(
        title: isAr ? 'توقع الازدحام 📊' : 'Crowd Forecast 📊',
        subtitle: isAr ? 'اعرف الزحمة قبل ما تمشي' : 'Know the crowd before you go',
        icon: Icons.people_outline,
        color: Colors.teal,
        onTap: () {
          GamificationService.recordCrowdCheck();
          GamificationService.unlockBadge(BadgeType.crowdChecker);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CrowdPredictionPage()));
        },
      ),
      // ── NEW FEATURE 3: Gamification ───────────────────────────────────────
      FeatureCard(
        title: isAr ? 'إنجازاتي 🏆' : 'My Achievements 🏆',
        subtitle: isAr ? 'نقاطك وشاراتك ومستواك' : 'Your points, badges & level',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFD97706),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage()));
        },
      ),
      // ── NEW FEATURE 4: Trip Scheduler ─────────────────────────────────────
      FeatureCard(
        title: isAr ? 'جداول الرحلات 📅' : 'Trip Scheduler 📅',
        subtitle: isAr ? 'رحلاتك المتكررة بإشعارات' : 'Recurring trips with reminders',
        icon: Icons.calendar_month_outlined,
        color: Colors.indigo,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripSchedulerPage()));
        },
      ),
      // ── NEW FEATURE 5: Pricing Calculator ─────────────────────────────────
      FeatureCard(
        title: isAr ? 'حاسبة التكلفة 💳' : 'Cost Calculator 💳',
        subtitle: isAr ? 'احسب وقارن وفر فلوسك' : 'Calculate, compare & save',
        icon: Icons.calculate_outlined,
        color: Colors.green[700]!,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingCalculatorPage()));
        },
      ),

      // Tourist Attractions
      FeatureCard(
        title: isAr ? 'الأماكن السياحية 🗺️' : 'Tourist Attractions 🗺️',
        subtitle: isAr ? 'اكتشف مزارات مصر من أي محطة • 4 لغات' : 'Discover Egypt landmarks from any station • 4 languages',
        icon: Icons.attractions_outlined,
        color: const Color(0xFFFFB800),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TouristAttractionsPage()));
        },
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactDashboardPage()));
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Text('🇪🇬', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'رفيق خدم مصر كلها' : 'Rafiq Served All of Egypt',
                          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr ? '85 محطة • 3 خطوط • 3.5M راكب يومياً' : '85 stations • 3 lines • 3.5M riders',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
      FeatureCard(
        title: 'subscription_optimizer'.tr(),
        subtitle: '',
        icon: Icons.savings_outlined,
        color: AppColors.accent,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionOptimizerPage()));
        },
      ),
      FeatureCard(
        title: 'ar_navigation'.tr(),
        subtitle: '',
        icon: Icons.view_in_ar,
        color: AppColors.primary,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ARNavigationPage()));
        },
      ),
      FeatureCard(
        title: 'community'.tr(),
        subtitle: 'community_subtitle'.tr(),
        icon: Icons.account_tree_outlined,
        color: AppColors.line2,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPage()));
        },
      ),
      FeatureCard(
        title: isAr ? 'أخبار حصرية' : 'Latest News',
        subtitle: isAr ? 'مصر والعالم لحظة بلحظة' : 'Live updates',
        icon: Icons.newspaper_outlined,
        color: AppColors.primary,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
        },
      ),
      FeatureCard(
        title: 'nfc_wallet'.tr(),
        subtitle: isAr ? 'شحن ومتابعة رصيد الكارت' : 'Manage your metro card',
        icon: Icons.contactless_outlined,
        color: AppColors.line3,
        onTap: () {
          GamificationService.recordNfcUse();
          GamificationService.unlockBadge(BadgeType.nfcPro);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NfcWalletPage()));
        },
      ),
      FeatureCard(
        title: isAr ? 'المترجم السياحي' : 'Tourist Assist',
        subtitle: isAr ? 'ترجمة فورية بالصوت' : 'Instant Voice Translation',
        icon: Icons.g_translate,
        color: AppColors.primary,
        onTap: () {
          TouristTranslatorModal.show(context);
        },
      ),
      FeatureCard(
        title: isAr ? 'شبكة المفقودات' : 'Lost & Found',
        subtitle: isAr ? 'أبلغ عن المفقودات والمعثورات' : 'Report & Find lost items',
        icon: Icons.travel_explore,
        color: AppColors.line2,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LostAndFoundPage()));
        },
      ),
    ];
  }

  void _showLineDetailsModal(BuildContext context, String line, bool isOnTime, int lineNum, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                     color: lineNum == 1 ? AppColors.line1.withValues(alpha: 0.1) : (lineNum == 2 ? AppColors.line2.withValues(alpha: 0.1) : AppColors.line3.withValues(alpha: 0.1)),
                     borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.subway_rounded, color: lineNum == 1 ? AppColors.line1 : (lineNum == 2 ? AppColors.line2 : AppColors.line3)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAr ? 'الخط $lineNum' : 'Line $lineNum', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(isAr ? 'حالة التشغيل الحالية' : 'Current Operations Status', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnTime ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnTime ? (isAr ? 'مستقر' : 'Stable') : (isAr ? 'يوجد تأخير' : 'Delayed'),
                    style: TextStyle(color: isOnTime ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isOnTime 
                        ? (isAr ? 'تعمل حركة القطارات بصورة طبيعية ومنتظمة في كلا الاتجاهين.' : 'Trains are operating normally in both directions.')
                        : (isAr ? 'يوجد عطل فني بسيط وجاري العمل على حله، يرجى توقع تأخيرات طفيفة.' : 'Minor technical issue, expect slight delays.'),
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(isAr ? 'تفعيل إشعارات هذا الخط' : 'Enable notifications for this line', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  // Mock activation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(isAr ? 'تم تفعيل التنبيهات للخط $lineNum' : 'Alerts enabled for Line $lineNum'),
                        ],
                      ),
                      backgroundColor: Colors.black87,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String line, String status, Color color, BuildContext context, Responsive r) {
    final isOnTime = status == 'on_time'.tr() || status == 'مستقر';
    final lineNum = int.tryParse(line.replaceAll(RegExp(r'\D'), '')) ?? 1;
    final stationCount = MetroData.stations.values.where((s) => s.line == lineNum).length;
    final lang = context.locale.languageCode;
    final isAr = lang == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(r.cardRadius),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(r.cardRadius),
          onTap: () {
            HapticFeedback.selectionClick();
            _showLineDetailsModal(context, line, isOnTime, lineNum, isAr);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Line colour indicator
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                // Line name + station count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line, style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.fontSize(14))),
                    Text(
                      lang == 'ar' ? '$stationCount محطة' : '$stationCount stations',
                      style: TextStyle(fontSize: r.fontSize(11), color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnTime
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isOnTime ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: r.fontSize(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fallback Voice Command Sheet ─────────────────────────────────────────────
class _VoiceCommandSheet extends StatelessWidget {
  final bool isAr;
  const _VoiceCommandSheet({required this.isAr});

  void _navigate(BuildContext context, String cmd) {
    Navigator.pop(context);
    final lower = cmd.toLowerCase();
    Widget? dest;
    if (lower.contains('خريطة') || lower.contains('map')) {
      dest = const MapPage();
    } else if (lower.contains('مخطط') || lower.contains('route') || lower.contains('رحلة') || lower.contains('plan')) {
      dest = const RoutePlannerPage();
    } else if (lower.contains('قريب') || lower.contains('nearby')) {
      dest = const NearbyStationsPage();
    } else if (lower.contains('مجتمع') || lower.contains('community')) {
      dest = const CommunityPage();
    } else if (lower.contains('أخبار') || lower.contains('news')) {
      dest = const NewsPage();
    } else if (lower.contains('ازدحام') || lower.contains('crowd')) {
      dest = const CrowdPredictionPage();
    } else if (lower.contains('إنجاز') || lower.contains('achievement') || lower.contains('نقاط') || lower.contains('points')) {
      dest = const AchievementsPage();
    } else if (lower.contains('جدول') || lower.contains('schedule')) {
      dest = const TripSchedulerPage();
    } else if (lower.contains('تكلفة') || lower.contains('price') || lower.contains('حاسبة') || lower.contains('calculator')) {
      dest = const PricingCalculatorPage();
    } else if (lower.contains('ذكاء') || lower.contains('ai') || lower.contains('مساعد') || lower.contains('assistant')) {
      dest = const AiAssistantPage();
    }
    if (dest != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => dest!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickCmds = isAr
        ? ['الخريطة', 'مخطط الرحلة', 'الازدحام', 'الطوارئ', 'إنجازاتي', 'الذكاء الاصطناعي']
        : ['Map', 'Route Planner', 'Crowd', 'Emergency', 'Achievements', 'AI Assistant'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'اكتب أمرك...' : 'Type your command...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: isAr ? 'مثلاً: افتح الخريطة' : 'e.g: Open map',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.keyboard_voice),
              ),
              onSubmitted: (v) => _navigate(context, v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: quickCmds.map((cmd) => ActionChip(
                label: Text(cmd, style: const TextStyle(fontSize: 12)),
                onPressed: () => _navigate(context, cmd),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}



