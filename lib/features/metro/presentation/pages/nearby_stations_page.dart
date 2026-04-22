
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/voice_service.dart';
import '../cubits/nearby_stations_cubit.dart';
import 'station_details_page.dart';

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
    final distKm = (swd.distanceMetres / 1000).toStringAsFixed(2);
    final walkMins = (swd.distanceMetres / 80).ceil(); // ~80m/min walking

    // Next train simulated
    final now = DateTime.now();
    final nextMin = 5 - (now.minute % 5);

    // Crowd
    final hour = now.hour;
    final isRush = (hour >= 7 && hour <= 9) || (hour >= 14 && hour <= 17);
    final isMed = (hour >= 10 && hour <= 13) || (hour >= 18 && hour <= 21);
    final crowdColor = isRush ? AppColors.error : isMed ? AppColors.warning : AppColors.success;
    final crowdLabel = isRush
        ? (lang == 'ar' ? 'ازدحام شديد' : 'Very Crowded')
        : isMed
            ? (lang == 'ar' ? 'متوسط' : 'Moderate')
            : (lang == 'ar' ? 'هادئ' : 'Quiet');

    return FadeInDown(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang == 'ar' ? '📍 أقرب محطة' : '📍 Nearest Station',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(lang == 'ar' ? 'الخط ${s.line}' : 'Line ${s.line}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  onPressed: () => VoiceService.speak(name, lang),
                  tooltip: lang == 'ar' ? 'استمع' : 'Listen',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroStat(Icons.directions_walk, '$distKm كم', lang == 'ar' ? 'المسافة' : 'Distance'),
                _heroStat(Icons.timer_outlined, '~$walkMins ${lang == 'ar' ? 'د' : 'min'}', lang == 'ar' ? 'مشياً' : 'Walking'),
                _heroStat(Icons.train, '${nextMin == 0 ? 1 : nextMin} ${lang == 'ar' ? 'د' : 'min'}', lang == 'ar' ? 'القطار القادم' : 'Next Train'),
                _heroStat(Icons.people, crowdLabel, lang == 'ar' ? 'الزحمة' : 'Crowd', color: crowdColor),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline, size: 18),
                label: Text(lang == 'ar' ? 'تفاصيل المحطة' : 'Station Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StationDetailsPage(station: s)),
                ),
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
        Icon(icon, color: color ?? Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildStationCard(BuildContext context, StationWithDistance swd, String lang, Responsive r, int idx) {
    final s = swd.station;
    final name = lang == 'ar' ? s.nameAr : s.nameEn;
    final color = _lineColor(s.line);
    final distM = swd.distanceMetres;
    final distLabel = distM < 1000
        ? '${distM.round()} ${lang == 'ar' ? 'م' : 'm'}'
        : '${(distM / 1000).toStringAsFixed(1)} ${lang == 'ar' ? 'كم' : 'km'}';

    // simulated next train
    final now = DateTime.now();
    // randomize per station id hash so each shows different time
    final offset = (s.id.hashCode.abs() % 5) + 1;
    final nextMin = ((5 - (now.minute % 5)) + offset) % 6 + 1;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StationDetailsPage(station: s)),
      ),
      child: Container(
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
            // Distance + train time
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
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.train, size: 11, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        '$nextMin د',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Color _lineColor(int line) {
    if (line == 1) return AppColors.line1;
    if (line == 2) return AppColors.line2;
    return AppColors.line3;
  }
}
