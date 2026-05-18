
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_schedule_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/voice_service.dart';
import '../cubits/nearby_stations_cubit.dart';
class NearbyStationsPage extends StatelessWidget {
  const NearbyStationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NearbyStationsCubit>()..getNearbyStations(),
      child: const _NearbyStationsView(),
    );
  }
}

class _NearbyStationsView extends StatelessWidget {
  const _NearbyStationsView();

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text('nearby_stations'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: lang == 'ar' ? 'تحديث' : 'Refresh',
            onPressed: () => context.read<NearbyStationsCubit>().getNearbyStations(),
          ),
        ],
      ),
      body: BlocBuilder<NearbyStationsCubit, NearbyStationsState>(
        builder: (context, state) {
          if (state is NearbyStationsLoading) {
            return _buildLoading(context, lang);
          } else if (state is NearbyStationsLoaded) {
            return _buildList(context, state, lang);
          } else if (state is NearbyStationsError) {
            return _buildError(context, state.message, lang);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            lang == 'ar' ? 'جاري تحديد موقعك...' : 'Locating you...',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              lang == 'ar' ? 'تعذّر تحديد موقعك' : 'Could not get your location',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(lang == 'ar' ? 'حاول مجدداً' : 'Try Again'),
              onPressed: () => context.read<NearbyStationsCubit>().getNearbyStations(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, NearbyStationsLoaded state, String lang) {
    final r = context.responsive;
    final nearest = state.stations.isNotEmpty ? state.stations.first : null;

    return ListView(
      padding: EdgeInsets.all(r.pagePadding),
      children: [
        // ── Nearest station hero card ────────────────────────────────
        if (nearest != null) _buildHeroCard(context, nearest, lang, r),
        const SizedBox(height: 20),

        // ── Section header ───────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.list_alt, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              lang == 'ar' ? 'كل المحطات القريبة' : 'All Nearby Stations',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.stations.length}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Station cards ────────────────────────────────────────────
        ...state.stations.asMap().entries.map((e) {
          final idx = e.key;
          final swd = e.value;
          if (idx == 0) return const SizedBox(); // already shown above
          return FadeInUp(
            delay: Duration(milliseconds: 50 * idx.clamp(0, 10)),
            child: _buildStationCard(context, swd, lang, r, idx),
          );
        }),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, StationWithDistance swd, String lang, Responsive r) {
    final s = swd.station;
    final name = lang == 'ar' ? s.nameAr : s.nameEn;
    final color = _lineColor(s.line);
    final distLabel = swd.distanceLabel;
    final walkMins = swd.walkingMinutes;
    final walkDisplay = walkMins <= 30
        ? '~$walkMins ${lang == 'ar' ? 'د' : 'min'}'
        : (lang == 'ar' ? 'استخدم مواصلة' : 'Take transit');

    // ── Real train schedule (based on published Cairo Metro headways) ────────────
    final schedule = MetroSchedule.getNextTrain(lineNumber: s.line);


    return FadeInDown(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 10)),
            const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Icon(Icons.my_location_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang == 'ar' ? 'أقرب محطة ليك' : 'Nearest Station',
                          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(lang == 'ar' ? 'الخط ${s.line}' : 'Line ${s.line}',
                              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
                  onPressed: () => VoiceService.speak(name, lang),
                  tooltip: lang == 'ar' ? 'استمع' : 'Listen',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _heroStat(Icons.directions_walk_rounded, distLabel, lang == 'ar' ? 'المسافة' : 'Distance'),
                  Container(width: 1, height: 40, color: Colors.white12),
                  _heroStat(Icons.timer_outlined, walkDisplay, lang == 'ar' ? 'مشياً' : 'Walking'),
                  Container(width: 1, height: 40, color: Colors.white12),
                  _heroStat(
                    Icons.train_rounded,
                    schedule.waitLabel(lang),
                    lang == 'ar' ? 'القطار القادم' : 'Next Train',
                    color: _waitColor(schedule.waitLevel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.info_outline_rounded, size: 20, color: color),
                label: Text(
                  lang == 'ar' ? 'عرض تفاصيل المحطة' : 'View Station Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildStationCard(BuildContext context, StationWithDistance swd, String lang, Responsive r, int idx) {
    final s = swd.station;
    final name = lang == 'ar' ? s.nameAr : s.nameEn;
    final color = _lineColor(s.line);
    final distLabel = swd.distanceLabel;

    // Real schedule for this line
    final schedule = MetroSchedule.getNextTrain(lineNumber: s.line);

    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(
                child: Text('$idx', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lang == 'ar' ? 'الخط ${s.line}' : 'Line ${s.line}',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (s.isTransfer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lang == 'ar' ? 'تبديل' : 'Transfer',
                            style: const TextStyle(color: AppColors.accent, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Distance + real next train badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_walk, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text(distLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _waitColor(schedule.waitLevel).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.train, size: 11, color: _waitColor(schedule.waitLevel)),
                      const SizedBox(width: 3),
                      Text(
                        schedule.waitLabel(lang),
                        style: TextStyle(
                          fontSize: 11,
                          color: _waitColor(schedule.waitLevel),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      );
  }

  Color _lineColor(int line) {
    if (line == 1) return AppColors.line1;
    if (line == 2) return AppColors.line2;
    return AppColors.line3;
  }

  /// Maps wait level to a traffic-light color for the badge
  Color _waitColor(TrainWaitLevel level) {
    switch (level) {
      case TrainWaitLevel.now:    return const Color(0xFF00C853); // green
      case TrainWaitLevel.soon:   return const Color(0xFF69F0AE); // light green
      case TrainWaitLevel.coming: return const Color(0xFFFFAB00); // amber
      case TrainWaitLevel.later:  return const Color(0xFF78909C); // grey-blue
      case TrainWaitLevel.closed: return const Color(0xFFEF5350); // red
    }
  }
}
