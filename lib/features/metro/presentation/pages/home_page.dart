import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq_metrro/features/tourism/presentation/pages/nearby_places_page.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/gamification_service.dart';
import '../../../../core/utils/dijkstra.dart';
import '../../../splash/presentation/trip_tracking_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/widgets/station_search_sheet.dart';
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
import '../widgets/tourist_translator_modal.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../trip_scheduler/presentation/pages/trip_scheduler_page.dart';
import '../../../pricing_calculator/presentation/pages/pricing_calculator_page.dart';
import '../../../voice_command/presentation/voice_command_service.dart';
import '../../../tourism/presentation/pages/tourist_attractions_page.dart';
import 'line_alerts_page.dart';
import 'train_simulator_page.dart';

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
  String? _fromStation;
  String? _toStation;
  int _metroType = 0;

  @override
  void initState() {
    super.initState();
  }

  List<Station> get _currentStations => _metroType == 0
      ? MetroData.stations.values.toList()
      : MetroData.capitalStations.values.toList();

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
      body: VoiceCommandService(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: padding,
                right: padding,
                top: padding,
                bottom: padding + 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────────────────────
                  FadeInDown(
                    child: Text(
                      "where_to_today".tr(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: r.fontSize(26),
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeInDown(
                    delay: const Duration(milliseconds: 40),
                    child: Text(
                      "trip_planner_subtitle".tr(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: r.sectionSpacing),

                  // ── BIG TRIP PLANNER card ─────────────────────────────────
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
                    // SizedBox(height: r.sectionSpacing),
                    // FadeInDown(
                    //   delay: const Duration(milliseconds: 140),
                    //   child: _buildCapitalMetroSection(context, isAr),
                    // ),
                  ],
                  SizedBox(height: r.sectionSpacing),

                  _buildNearestStationLive(context, isAr),
                  SizedBox(height: r.sectionSpacing),
                  _buildMapShortcut(context, isAr),
                  SizedBox(height: r.sectionSpacing),

                  // ✅ زرار بدل الـ Section مباشرة
                  FadeInDown(
                    delay: const Duration(milliseconds: 160),
                    child: _buildNearbyPlacesButton(context, isAr),
                  ),
                  SizedBox(height: r.sectionSpacing * 1.5),

                  // ── Feature cards ─────────────────────────────────────────
                  r.featureGridColumns == 1
                      ? _buildFeatureList(context, r)
                      : _buildFeatureGrid(context, r),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ الزرار الجديد بدل NearbyPlacesSection
  Widget _buildNearbyPlacesButton(BuildContext context, bool isAr) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NearbyPlacesPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? '📍 استكشف المناطق القريبة'
                        : '📍 Explore Nearby Places',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isAr
                        ? 'كافيهات، مطاعم وأماكن ترفيه'
                        : 'Cafes, Restaurants & Fun',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Metro Type Toggle ────────────────────────────────────────────────────
  Widget _buildMetroTypeToggle(BuildContext context, bool isAr) {
    final types = [
      {
        'label': "Cairo Metro".tr(),
        'icon': Icons.directions_subway_rounded,
        'color': AppColors.primary,
        'sub': "3 Lines • 85 Stations".tr(),
      },
      {
        'label': "Capital Metro".tr(),
        'icon': Icons.train_rounded,
        'color': const Color(0xFF9C27B0),
        'sub': "New Monorail Line".tr(),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
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
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.titleMedium?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      t['sub'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.80)
                            : Colors.grey,
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.train_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Administrative Capital Metro".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _capitalInfoRow(
                Icons.route_outlined,
                "Monorail: Adly Mansour ↔ Admin. Capital".tr(),
                isAr,
              ),
              const SizedBox(height: 8),
              _capitalInfoRow(
                Icons.access_time_rounded,
                "Journey time: ~60 minutes".tr(),
                isAr,
              ),
              const SizedBox(height: 8),
              _capitalInfoRow(
                Icons.payments_outlined,
                "Ticket price: 20-40 EGP".tr(),
                isAr,
              ),
              const SizedBox(height: 8),
              _capitalInfoRow(
                Icons.swap_horiz_rounded,
                "Transfer: from Adly Mansour Station (Line 3)".tr(),
                isAr,
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  // ── Nearest Station Live ──────────────────────────────────────────────────
  Widget _buildNearestStationLive(BuildContext context, bool isAr) {
    return BlocBuilder<NearbyStationsCubit, NearbyStationsState>(
      builder: (context, state) {
        if (state is NearbyStationsLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 12),
                Text(
                  "locating_you".tr(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        if (state is NearbyStationsError) {
          return GestureDetector(
            onTap: () =>
                context.read<NearbyStationsCubit>().getNearbyStations(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "location_unavailable".tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          "tap_to_enable_location".tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
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
              ? '${distM.round()} ${"m".tr()}'
              : '${(distM / 1000).toStringAsFixed(1)} ${"km".tr()}';

          final showWalk = distM < 10000;
          final walkMins = (distM / 83).ceil();
          final infoText = showWalk
              ? '$distLabel · ~$walkMins ${"min_walk".tr()}'
              : distLabel;

          final lineColor = s.line == 1
              ? AppColors.line1
              : s.line == 2
              ? AppColors.line2
              : AppColors.line3;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyStationsPage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lineColor.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: lineColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: lineColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: lineColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "nearest_metro_station".tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: lineColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'الخط ${s.line}' : 'Line ${s.line}',
                              style: TextStyle(
                                color: lineColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              showWalk
                                  ? Icons.directions_walk_rounded
                                  : Icons.navigation_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                infoText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Main Trip Planner ────────────────────────────────────────────────────
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
              "plan_your_trip".tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchableStationDropdown(
              context: context,
              isAr: isAr,
              label: "from_start_station".tr(),
              value: _fromStation,
              onChanged: (v) => setState(() => _fromStation = v),
            ),
            const SizedBox(height: 10),
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSearchableStationDropdown(
              context: context,
              isAr: isAr,
              label: "to_destination".tr(),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.directions_subway_rounded, size: 22),
                label: Text(
                  "find_my_route".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  if (_fromStation == null || _toStation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("select_both_stations".tr()),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    return;
                  }
                  if (_fromStation == _toStation) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("different_destination".tr()),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    return;
                  }
                  final allStationsMap = _metroType == 0
                      ? MetroData.stations
                      : MetroData.capitalStations;
                  final result = Dijkstra.findShortestPath(
                    allStationsMap,
                    _fromStation!,
                    _toStation!,
                  );
                  if (result['path'] != null) {
                    TripTrackingService.instance.startTracking(
                      result['path'] as List<Station>,
                    );
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoutePlannerPage(
                        initialFrom: _fromStation,
                        initialTo: _toStation,
                        metroType: _metroType,
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
    final stations = _currentStations;
    final selectedStation = stations.where((s) => s.id == value).firstOrNull;
    final displayName = selectedStation != null
        ? (isAr ? selectedStation.nameAr : selectedStation.nameEn)
        : label;

    return InkWell(
      onTap: () async {
        final result = await StationSearchSheet.show(
          context,
          stations,
          selectedStationId: value,
        );
        if (result != null) {
          onChanged(result);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (selectedStation != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: selectedStation.line == 1
                      ? AppColors.line1
                      : selectedStation.line == 2
                      ? AppColors.line2
                      : AppColors.line3,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedStation != null
                      ? Colors.black87
                      : Colors.grey[600],
                ),
              ),
            ),
            if (selectedStation?.isTransfer == true)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "transfer".tr(),
                  style: const TextStyle(fontSize: 9, color: AppColors.warning),
                ),
              ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ── Map shortcut ──────────────────────────────────────────────────────────
  Widget _buildMapShortcut(BuildContext context, bool isAr) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? '🗺️ خريطة خطوط المترو' : '🗺️ Metro Lines Map',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isAr
                        ? 'شوف كل الخطوط والمحطات'
                        : 'View all lines & stations',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _getRealisticLineStatus(int lineId) {
    final now = DateTime.now();
    final hour = now.hour;
    final isRushHour = (hour >= 7 && hour <= 9) || (hour >= 14 && hour <= 18);
    if (isRushHour) {
      if (lineId == 1 && now.minute % 3 == 0) return 'minor_delays'.tr();
      if (lineId == 2 && now.minute % 2 == 0) return 'minor_delays'.tr();
      if (lineId == 3 && now.minute % 7 == 0) return 'minor_delays'.tr();
    } else {
      final window = now.minute ~/ 10;
      if ((hour + lineId + window) % 9 == 0) return 'minor_delays'.tr();
    }
    return 'on_time'.tr();
  }

  // ── Single‑column list ────────────────────────────────────────────────────
  Widget _buildFeatureList(BuildContext context, Responsive r) {
    final cards = _featureConfigs(context);
    return Column(
      children: cards
          .asMap()
          .entries
          .map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: r.sectionSpacing),
              child: FadeInUp(
                delay: Duration(milliseconds: 200 * e.key),
                child: e.value,
              ),
            ),
          )
          .toList(),
    );
  }

  // ── 2‑column grid ─────────────────────────────────────────────────────────
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
          Navigator.push(
            context,
            RafiqPageRoute(page: const RoutePlannerPage()),
          );
        },
      ),
      FeatureCard(
        title: 'interactive_map'.tr(),
        subtitle: 'map_subtitle'.tr(),
        icon: Icons.map_outlined,
        color: AppColors.line3,
        onTap: () {
          speak('interactive_map'.tr());
          Navigator.push(context, RafiqPageRoute(page: const MapPage()));
        },
      ),
      FeatureCard(
        title: 'nearby_stations'.tr(),
        subtitle: 'nearby_subtitle'.tr(),
        icon: Icons.my_location,
        color: AppColors.line2,
        onTap: () {
          speak('nearby_stations'.tr());
          Navigator.push(
            context,
            RafiqPageRoute(page: const NearbyStationsPage()),
          );
        },
      ),
      FeatureCard(
        title: isAr ? "مساعد رفيق الذكي 🤖" : "AI Assistant 🤖",
        subtitle: isAr
            ? "اسألني أي شيء عن المترو"
            : "Ask me anything about metro",
        icon: Icons.smart_toy_outlined,
        color: const Color(0xFF7C3AED),
        onTap: () {
          GamificationService.recordAiQuery();
          GamificationService.unlockBadge(BadgeType.aiUser);
          Navigator.push(
            context,
            RafiqPageRoute(page: const AiAssistantPage()),
          );
        },
      ),
      FeatureCard(
        title: isAr ? "مُجدول الرحلات 📅" : "Trip Scheduler 📅",
        subtitle: isAr
            ? "رحلات متكررة مع تنبيهات ذكية"
            : "Recurring trips with reminders",
        icon: Icons.calendar_month_outlined,
        color: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            RafiqPageRoute(page: const TripSchedulerPage()),
          );
        },
      ),
      FeatureCard(
        title: isAr ? "حاسبة التكلفة 💳" : "Cost Calculator 💳",
        subtitle: isAr ? "احسب وقارن ووفر فلوسك" : "Calculate, compare & save",
        icon: Icons.calculate_outlined,
        color: Colors.green[700]!,
        onTap: () {
          Navigator.push(
            context,
            RafiqPageRoute(page: const PricingCalculatorPage()),
          );
        },
      ),
      FeatureCard(
        title: "train_simulator".tr(),
        subtitle: "train_sim_subtitle".tr(),
        icon: Icons.directions_subway_rounded,
        color: const Color(0xFF0284C7),
        onTap: () {
          Navigator.push(
            context,
            RafiqPageRoute(page: const TrainSimulatorPage()),
          );
        },
      ),
      FeatureCard(
        title: isAr ? "المعالم السياحية 🗺️" : "Tourist Attractions 🗺️",
        subtitle: isAr
            ? "اكتشف معالم مصر السياحية من أي محطة"
            : "Discover Egypt landmarks near stations",
        icon: Icons.attractions_outlined,
        color: const Color(0xFFFFB800),
        onTap: () {
          Navigator.push(
            context,
            RafiqPageRoute(page: const TouristAttractionsPage()),
          );
        },
      ),
      FeatureCard(
        title: isAr ? "تنبيهات الخطوط 🔔" : "Line Alerts 🔔",
        subtitle: isAr
            ? "تنبيهات فورية للتأخير والازدحام"
            : "Instant alerts for delays & crowd",
        icon: Icons.notifications_active_outlined,
        color: Colors.red[700]!,
        onTap: () {
          Navigator.push(context, RafiqPageRoute(page: const LineAlertsPage()));
        },
      ),
      FeatureCard(
        title: 'subscription_optimizer'.tr(),
        subtitle: isAr
            ? 'احسب ووفر اشتراكك الشهري'
            : 'Calculate & optimize subscriptions',
        icon: Icons.savings_outlined,
        color: AppColors.accent,
        onTap: () {
          Navigator.push(
            context,
            RafiqPageRoute(page: const SubscriptionOptimizerPage()),
          );
        },
      ),
      FeatureCard(
        title: 'ar_navigation'.tr(),
        subtitle: isAr
            ? 'ابحث عن المحطة عبر الكاميرا'
            : 'Find stations using AR camera',
        icon: Icons.view_in_ar,
        color: AppColors.primary,
        onTap: () {
          Navigator.push(
            context,
            RafiqPageRoute(page: const ARNavigationPage()),
          );
        },
      ),
      FeatureCard(
        title: isAr ? "آخر الأخبار 📰" : "Latest News",
        subtitle: isAr
            ? "متابعة حية ومباشرة لأخبار المترو"
            : "Live updates & news",
        icon: Icons.newspaper_outlined,
        color: AppColors.primary,
        onTap: () {
          Navigator.push(context, RafiqPageRoute(page: const NewsPage()));
        },
      ),
      FeatureCard(
        title: isAr ? "مساعد السياح 🗣️" : "Tourist Assist",
        subtitle: isAr
            ? "ترجمة صوتية فورية للغات مختلفة"
            : "Instant Voice Translation",
        icon: Icons.g_translate,
        color: AppColors.primary,
        onTap: () {
          TouristTranslatorModal.show(context);
        },
      ),
    ];
  }

  void _showLineDetailsModal(
    BuildContext context,
    String line,
    bool isOnTime,
    int lineNum,
    bool isAr,
  ) {
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
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lineNum == 1
                        ? AppColors.line1.withValues(alpha: 0.1)
                        : (lineNum == 2
                              ? AppColors.line2.withValues(alpha: 0.1)
                              : AppColors.line3.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.subway_rounded,
                    color: lineNum == 1
                        ? AppColors.line1
                        : (lineNum == 2 ? AppColors.line2 : AppColors.line3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الخط $lineNum' : 'Line $lineNum',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Current Operations Status".tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOnTime
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnTime ? ("Stable".tr()) : ("Delayed".tr()),
                    style: TextStyle(
                      color: isOnTime ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                          ? ("Trains are operating normally in both directions."
                                .tr())
                          : ("Minor technical issue, expect slight delays."
                                .tr()),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(
                  "Enable notifications for this line".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            isAr
                                ? 'تم تفعيل التنبيهات للخط $lineNum'
                                : 'Alerts enabled for Line $lineNum',
                          ),
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

  Widget _buildStatusCard(
    String line,
    String status,
    Color color,
    BuildContext context,
    Responsive r,
  ) {
    final isOnTime = status == 'on_time'.tr() || status == 'مستقر';
    final lineNum = int.tryParse(line.replaceAll(RegExp(r'\D'), '')) ?? 1;
    final stationCount = MetroData.stations.values
        .where((s) => s.line == lineNum)
        .length;
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
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: r.fontSize(14),
                      ),
                    ),
                    Text(
                      lang == 'ar'
                          ? '$stationCount محطة'
                          : '$stationCount stations',
                      style: TextStyle(
                        fontSize: r.fontSize(11),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
