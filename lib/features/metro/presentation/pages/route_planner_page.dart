import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'station_details_page.dart';
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
import '../../../../core/utils/ai_prediction_service.dart';
import '../../domain/entities/station.dart';

import '../widgets/trip_rating_dialog.dart';
import '../widgets/blind_assist_fab.dart';
import '../widgets/last_mile_transit_widget.dart';

class RoutePlannerPage extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  const RoutePlannerPage({super.key, this.initialFrom, this.initialTo});

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  String? _startStationId;
  String? _endStationId;

  // Which field is currently being listened to: 'from', 'to', or null
  String? _listeningField;

  @override
  void initState() {
    super.initState();
    _startStationId = widget.initialFrom;
    _endStationId = widget.initialTo;
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

    final allStations = MetroData.stations.values.toList();

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
    final allStations = MetroData.stations.values.toList();

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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'rateBtn',
            backgroundColor: AppColors.primary,
            onPressed: () => TripRatingDialog.show(context),
            icon: const Icon(Icons.star, color: Colors.white),
            label: Text(context.locale.languageCode == 'ar' ? 'تقييم القطار' : 'Rate Train', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const BlindAssistFab(),
        ],
      ),
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
                    content: Text(isAr ? 'من فضلك اختار محطة البداية والنهاية' : 'Please select both stations'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                  return;
                }
                if (_startStationId == _endStationId) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isAr ? '⚠️ اختار محطة وصول مختلفة عن محطة البداية!' : '⚠️ Choose a different destination station!'),
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
                const Text('Select your path to continue'),
              ],
            ),
          );
        } else if (state is RoutePlannerLoading) {
          return const Center(child: CircularProgressIndicator());
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

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(label),
                isExpanded: true,
                dropdownColor: Theme.of(context).cardColor,
                items: stations.map((s) {
                  final name = context.locale.languageCode == 'ar' ? s.nameAr : s.nameEn;
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Row(
                      children: [
                        _getLineIndicator(s.line),
                        const SizedBox(width: 8),
                        Text(name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
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
            : AppColors.line3;
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
                  '${(state.stationCount * 2.5 + state.transfers * 3).round()} min',
                ),
                _buildInfoTag(Icons.stairs_outlined, 'stations_count'.tr(args: [state.stationCount.toString()]), ''),
                _buildInfoTag(Icons.payments_outlined, 'ticket_price'.tr(args: [state.ticketPrice.toString()]), ''),
              ],
            ),
            const SizedBox(height: 16),
            if (state.aiPrediction != null) ...[
              _buildModernAiPrediction(context, state.aiPrediction!),
              const SizedBox(height: 16),
            ],
            _buildSmartAlarm(context, state.path),
            const SizedBox(height: 16),
            LastMileTransitWidget(destination: state.path.last),
            if (state.transfers > 0)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text(
                   '⚠️ This journey has ${state.transfers} transfer(s)',
                   style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                 ),
               ),
            if (state.boardingHint != null)
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
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
                       Expanded(child: Text(state.boardingHint!, style: const TextStyle(color: AppColors.line2, fontWeight: FontWeight.bold, fontSize: 13))),
                     ],
                   ),
                 ),
               ),
            const SizedBox(height: 20),
            Text(
              'journey_details'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.path.length,
              itemBuilder: (context, index) {
                final station = state.path[index];
                final name = context.locale.languageCode == 'ar' ? station.nameAr : station.nameEn;
                bool isLast = index == state.path.length - 1;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StationDetailsPage(station: station),
                      ),
                    );
                  },
                  child: Padding(
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
                  ),
                );
              },
            ),
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
            : AppColors.line3;
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

  Widget _buildModernAiPrediction(BuildContext context, AiPrediction ai) {
    final lang = context.locale.languageCode;
    final isHigh = ai.crowdLevel == 'high';
    final isMed = ai.crowdLevel == 'medium';
    final color = isHigh ? AppColors.error : isMed ? AppColors.warning : AppColors.success;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.auto_awesome, size: 100, color: color.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.psychology, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == 'ar' ? 'المستشار الذكي للسفر' : 'Smart Travel Advisor',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                            ),
                            Text(
                              lang == 'ar' ? 'توقع الزحمة بالذكاء الاصطناعي' : 'AI Crowd Prediction',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassCard(
                          icon: Icons.groups_outlined,
                          title: 'crowd_level'.tr(),
                          value: ai.crowdLevel.toUpperCase(),
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassCard(
                          icon: Icons.hourglass_empty,
                          title: 'delay'.tr(),
                          value: '+${ai.expectedDelayMinutes} min',
                          color: ai.expectedDelayMinutes > 5 ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: AppColors.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == 'ar' ? 'أحسن وقت سفر 💡' : 'Best Time to Travel 💡',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'ar' ? ai.recommendationAr : ai.recommendationEn,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildGlassCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _buildSmartAlarm(BuildContext context, List<dynamic> path) {
    if (path.isEmpty) return const SizedBox();
    return BlocBuilder<ArrivalAlarmCubit, ArrivalAlarmState>(
      builder: (context, alarmState) {
        final isAlarmActive = alarmState is ArrivalAlarmActive &&
            alarmState.destination.id == path.last.id;
        final lang = context.locale.languageCode;
            
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
          child: Row(
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
                      lang == 'ar' ? 'تنبيه ذكي (قبل محطتك)' : 'Smart Alarm (1 stop early)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isAlarmActive ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang == 'ar' ? 'بينبهك قبل محطتك بمحطة عشان تقوم' : 'Alerts you 1 station before destination',
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
                    context.read<ArrivalAlarmCubit>().startAlarm(path.cast<Station>());
                  } else {
                    context.read<ArrivalAlarmCubit>().stopAlarm();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
