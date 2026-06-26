import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubits/arrival_alarm/arrival_alarm_cubit.dart';
import '../../../../core/utils/voice_service.dart';
import '../../../../core/utils/speech_service.dart';
import '../cubits/route_planner/route_planner_cubit.dart';
import '../cubits/route_planner/route_planner_state.dart';
import '../../domain/entities/station.dart';

import 'blind_journey_page.dart';
import '../../../../core/widgets/station_search_sheet.dart';
import '../widgets/nearby_osm_places_widget.dart';

class RoutePlannerPage extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  final int metroType;
  const RoutePlannerPage({super.key, this.initialFrom, this.initialTo, this.metroType = 0});

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  String? _startStationId;
  String? _endStationId;

  // Which field is currently being listened to: 'from', 'to', or null
  String? _listeningField;

  int _selectedStationsEarly = 1;

  @override
  void initState() {
    super.initState();
    _startStationId = widget.initialFrom;
    _endStationId = widget.initialTo;

    if (_startStationId != null && _endStationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RoutePlannerCubit>().findPath(_startStationId!, _endStationId!);
      });
    }
  }

  @override
  void dispose() {
    SpeechService.cancelListening();
    super.dispose();
  }

  Future<void> _startVoiceSearch(String field) async {
    if (_listeningField != null) {
      await SpeechService.cancelListening();
      setState(() => _listeningField = null);
      return;
    }

    final langCode = context.locale.languageCode;
    final localeId = langCode == 'ar'
        ? 'ar-EG'
        : langCode == 'fr'
            ? 'fr-FR'
            : langCode == 'de'
                ? 'de-DE'
                : 'en-US';

    setState(() => _listeningField = field);

    final allStations = widget.metroType == 0 
        ? MetroData.stations.values.toList() 
        : MetroData.capitalStations.values.toList();

    await SpeechService.startListening(
      localeId: localeId,
      onResult: (text) async {
        if (!mounted) return;
        setState(() => _listeningField = null);

        // Find best matching station
        final lower = text.toLowerCase().trim();
        dynamic best;
        int bestScore = 0;

        for (final s in allStations) {
          for (final name in [s.nameAr, s.nameEn]) {
            final candidate = name.toLowerCase().trim();
            int score = 0;
            if (candidate == lower) {
              score = 100;
            } else if (candidate.contains(lower) || lower.contains(candidate)) {
              score = 80;
            } else if (SpeechService.fuzzyMatch(lower, candidate)) {
              score = 60;
            }
            if (score > bestScore) {
              bestScore = score;
              best = s;
            }
          }
        }

        if (best != null && bestScore >= 60) {
          setState(() {
            if (field == 'from') {
              _startStationId = best.id;
            } else {
              _endStationId = best.id;
            }
          });

          final stationName =
              langCode == 'ar' ? best.nameAr : best.nameEn;

          // TTS confirmation
          await VoiceService.speak(stationName, langCode);
        } else {
          // Not found
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('لم يتم التعرف على محطة: "$text"'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final allStations = widget.metroType == 0 
        ? MetroData.stations.values.toList() 
        : MetroData.capitalStations.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('route_planner'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: context.locale.languageCode == 'ar' ? 'شير الرحلة' : 'Share Trip',
            onPressed: () {
               if (_startStationId != null && _endStationId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.rocket_launch, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(context.locale.languageCode == 'ar' ? 'تم نسخ رابط الرحلة للمشاركة! 🚀' : 'Trip link copied! 🚀')),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
               }
            },
          ),
        ],
      ),
      body: r.useSideBySideLayout
          ? _buildWideLayout(context, r, allStations)
          : _buildNarrowLayout(context, r, allStations),
    );
  }

  // ── Narrow layout (phone portrait) ────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, Responsive r, List allStations) {
    return Column(
      children: [
        _buildSearchPanel(context, r, allStations),
        Expanded(child: _buildStateArea(context)),
      ],
    );
  }

  // ── Wide layout (tablet / landscape) ─────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, Responsive r, List allStations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: r.screenWidth * 0.40,
          child: SingleChildScrollView(
            child: _buildSearchPanel(context, r, allStations),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildStateArea(context)),
      ],
    );
  }

  // ── Shared search panel ────────────────────────────────────────────────────
  Widget _buildSearchPanel(BuildContext context, Responsive r, List allStations) {
    return Container(
      padding: EdgeInsets.all(r.pagePadding),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          _buildStationSelector(
            label: 'from'.tr(),
            field: 'from',
            value: _startStationId,
            stations: allStations,
            onChanged: (val) => setState(() => _startStationId = val),
            context: context,
            r: r,
          ),
          SizedBox(height: r.sectionSpacing),
          _buildStationSelector(
            label: 'to'.tr(),
            field: 'to',
            value: _endStationId,
            stations: allStations,
            onChanged: (val) => setState(() => _endStationId = val),
            context: context,
            r: r,
          ),
          SizedBox(height: r.sectionSpacing * 1.25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final isAr = context.locale.languageCode == 'ar';
                if (_startStationId == null || _endStationId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Please select both stations".tr()),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                  return;
                }
                if (_startStationId == _endStationId) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("⚠️ Choose a different destination station!".tr()),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                  return;
                }
                context.read<RoutePlannerCubit>().findPath(_startStationId!, _endStationId!);
              },
              child: Text(
                'search_route'.tr(),
                style: TextStyle(fontSize: r.fontSize(15), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── State area (initial / loading / result / error) ──────────────────────
  Widget _buildStateArea(BuildContext context) {
    return BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
      builder: (context, state) {
        if (state is RoutePlannerInitial) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_subway_outlined,
                    size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text('select_path'.tr()),
              ],
            ),
          );
        } else if (state is RoutePlannerLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: 4,
            itemBuilder: (ctx, i) => Shimmer.fromColors(
              baseColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
              highlightColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(width: 20, height: 20, decoration: BoxDecoration(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 20, decoration: BoxDecoration(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(4))),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is RoutePlannerLoaded) {
          return _buildPathResult(state);
        } else if (state is RoutePlannerError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStationSelector({
    required String label,
    required String field,
    required String? value,
    required List<dynamic> stations,
    required ValueChanged<String?> onChanged,
    required BuildContext context,
    Responsive? r,
  }) {
    final isListeningThisField = _listeningField == field;
    final micSize = r != null ? r.iconSize(22.0) : 22.0;
    final btnSize = r != null ? (r.isTablet ? 56.0 : 48.0) : 48.0;

    final selectedStation = stations.where((s) => s.id == value).firstOrNull;
    final isAr = context.locale.languageCode == 'ar';
    final displayName = selectedStation != null ? (isAr ? selectedStation.nameAr : selectedStation.nameEn) : label;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final result = await StationSearchSheet.show(context, stations);
              if (result != null) {
                onChanged(result);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  if (selectedStation != null) ...[
                    _getLineIndicator(selectedStation.line),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selectedStation != null ? FontWeight.bold : FontWeight.normal,
                        color: selectedStation != null ? null : Colors.grey[600],
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
        ),
        const SizedBox(width: 8),
        // Microphone button
        GestureDetector(
          onTap: () => _startVoiceSearch(field),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: isListeningThisField
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isListeningThisField
                      ? Colors.red.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: isListeningThisField ? 12 : 4,
                  spreadRadius: isListeningThisField ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              isListeningThisField ? Icons.mic : Icons.mic_none,
              color: isListeningThisField ? Colors.white : AppColors.primary,
              size: micSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getLineIndicator(int line) {
    Color color = line == 1
        ? AppColors.line1
        : line == 2
            ? AppColors.line2
            : line == 3
                ? AppColors.line3
                : line == 4
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF06B6D4);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPathResult(RoutePlannerLoaded state) {
    return FadeInUp(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoTag(
                  Icons.timer_outlined,
                  'estimated'.tr(),
                  '${(state.stationCount * 2.5 + state.transfers * 3).round()} ${'min_short'.tr()}',
                ),
                _buildInfoTag(Icons.stairs_outlined, 'stations_count'.tr(args: [state.stationCount.toString()]), ''),
                _buildInfoTag(Icons.payments_outlined, 'ticket_price'.tr(args: [state.ticketPrice.toString()]), ''),
              ],
            ),
            const SizedBox(height: 24),
            
            // ── Journey Details (Moved to Top) ─────────────────────────
            Text(
              'journey_details'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.path.length,
                itemBuilder: (context, index) {
                  final station = state.path[index];
                  final name = context.locale.languageCode == 'ar' ? station.nameAr : station.nameEn;
                  bool isLast = index == state.path.length - 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _getStationColor(station.line),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 48,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: (index == 0 || isLast)
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: (index == 0 || isLast) ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        VoiceService.speak(name, context.locale.languageCode);
                                      },
                                    ),
                                  ],
                                ),
                                if (station.isTransfer)
                                   Text(
                                     'transfer_station'.tr(),
                                     style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                                   ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // ── Warnings & Hints ─────────────────────────────────────────
            if (state.transfers > 0)
               Padding(
                 padding: const EdgeInsets.only(bottom: 12.0),
                 child: Text(
                   'journey_transfers'.tr(args: [state.transfers.toString()]),
                   style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                 ),
               ),
            if (state.boardingHint != null)
               Padding(
                 padding: const EdgeInsets.only(bottom: 16.0),
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: AppColors.line2.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: AppColors.line2.withValues(alpha: 0.3)),
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.directions_walk, color: AppColors.line2, size: 28),
                       const SizedBox(width: 12),
                       Expanded(child: Text(state.boardingHint!.tr(), style: const TextStyle(color: AppColors.line2, fontWeight: FontWeight.bold, fontSize: 13))),
                     ],
                   ),
                 ),
               ),
            
            // ── Additional Services ──────────────────────────────────────
            _buildSmartAlarm(context, state.path),
            const SizedBox(height: 16),
            _buildBlindAssistButton(context, state.path, state.ticketPrice),
            const SizedBox(height: 24),
            
            // ── OSM Nearby Places ──────────────────────────────────────────
            const NearbyOsmPlacesWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getStationColor(int line) {
    return line == 1
        ? AppColors.line1
        : line == 2
            ? AppColors.line2
            : line == 3
                ? AppColors.line3
                : line == 4
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF06B6D4);
  }

  // ── Blind Assist Mode launcher ────────────────────────────────────────────
  Widget _buildBlindAssistButton(
      BuildContext context, List<dynamic> path, int price) {
    final isAr = context.locale.languageCode == 'ar';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlindJourneyPage(
            path: path.cast<Station>(),
            ticketPrice: price,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A0D1A), Color(0xFF1A2040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: const Icon(Icons.accessibility_new_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "blind_assist_mode".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "blind_assist_subtitle".tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF0A0D1A), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }



  Widget _buildTimingChip(BuildContext context, int stations, String label, bool isAlarmActive, List<dynamic> path) {
    final isSelected = _selectedStationsEarly == stations;
    final activeColor = isAlarmActive ? AppColors.success : AppColors.primary;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStationsEarly = stations;
          });
          if (isAlarmActive) {
            context.read<ArrivalAlarmCubit>().startAlarm(
              path.cast<Station>(),
              stationsEarly: stations,
              lang: context.locale.languageCode,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : Colors.grey.withValues(alpha: 0.25),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected && isAlarmActive
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.15), blurRadius: 8)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartAlarm(BuildContext context, List<dynamic> path) {
    if (path.isEmpty) return const SizedBox();
    return BlocBuilder<ArrivalAlarmCubit, ArrivalAlarmState>(
      builder: (context, alarmState) {
        final isAlarmTriggered = alarmState is ArrivalAlarmTriggered;
        
        if (alarmState is ArrivalAlarmActive) {
          _selectedStationsEarly = alarmState.stationsEarly;
        }
        
        final isAlarmActive = alarmState is ArrivalAlarmActive &&
            alarmState.destination.id == path.last.id;
        final lang = context.locale.languageCode;
            
        if (isAlarmTriggered) {
          return Pulse(
            infinite: true,
            duration: const Duration(seconds: 2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alarm_on,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == 'ar' ? '🚨 اصحى! اقتربنا من محطتك' : '🚨 Wake Up! Approaching station',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang == 'ar'
                                  ? 'استعد للنزول فوراً'
                                  : 'Please prepare to leave the train',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.read<ArrivalAlarmCubit>().stopAlarm();
                      },
                      icon: const Icon(Icons.volume_off_rounded),
                      label: Text(
                        lang == 'ar' ? '🔕 كتم التنبيه' : '🔕 Silence Alarm',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAlarmActive
                  ? [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.05)]
                  : [Theme.of(context).cardColor, Theme.of(context).cardColor],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAlarmActive ? AppColors.success.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.1),
            ),
            boxShadow: isAlarmActive ? [
              BoxShadow(color: AppColors.success.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1)
            ] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAlarmActive ? AppColors.success.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAlarmActive ? Icons.notifications_active : Icons.notifications_none,
                      color: isAlarmActive ? AppColors.success : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAlarmActive
                              ? (_selectedStationsEarly == 2
                                  ? (lang == 'ar' ? 'منبه نشط (قبلها بمحطتين) ⏰' : 'Alarm Active (2 stops early) ⏰')
                                  : (lang == 'ar' ? 'منبه نشط (قبلها بمحطة) ⏰' : 'Alarm Active (1 stop early) ⏰'))
                              : (lang == 'ar' ? 'منبه الوصول الذكي' : 'Smart Arrival Alarm'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isAlarmActive ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang == 'ar'
                              ? 'بينبهك قبل الوصول بالمسافة اللي تختارها'
                              : 'Alerts you before arrival by your chosen stops',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isAlarmActive,
                    activeTrackColor: AppColors.success,
                    onChanged: (val) {
                      if (val) {
                        context.read<ArrivalAlarmCubit>().startAlarm(
                          path.cast<Station>(),
                          stationsEarly: _selectedStationsEarly,
                          lang: lang,
                        );
                      } else {
                        context.read<ArrivalAlarmCubit>().stopAlarm();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              Text(
                lang == 'ar' ? 'وقت التنبيه:' : 'Alert timing:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimingChip(context, 1, lang == 'ar' ? 'قبلها بمحطة 📍' : '1 station early 📍', isAlarmActive, path),
                  const SizedBox(width: 10),
                  _buildTimingChip(context, 2, lang == 'ar' ? 'قبلها بمحطتين 📍📍' : '2 stations early 📍📍', isAlarmActive, path),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
