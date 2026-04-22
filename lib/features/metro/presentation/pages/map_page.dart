 import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/voice_service.dart';
import '../../../../core/utils/speech_service.dart';
import '../../domain/entities/station.dart';
import 'station_details_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  List<Station> _filteredStations = [];
  String _selectedLine = 'all'; // 'all','1','2','3'
  Station? _selectedStation;
  bool _isVoiceSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredStations = MetroData.stations.values.toList();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    SpeechService.cancelListening();
    super.dispose();
  }

  void _filter(String query) {
    final all = MetroData.stations.values.toList();
    setState(() {
      _filteredStations = all.where((s) {
        final matchLine = _selectedLine == 'all' || s.line.toString() == _selectedLine;
        final q = query.toLowerCase().trim();
        final matchName = q.isEmpty || s.nameAr.contains(q) || s.nameEn.toLowerCase().contains(q);
        return matchLine && matchName;
      }).toList();
    });
  }

  void _filterByLine(String line) {
    setState(() => _selectedLine = line);
    _filter(_searchController.text);
  }

  Future<void> _startVoiceSearch() async {
    if (_isVoiceSearching) {
      await SpeechService.cancelListening();
      setState(() => _isVoiceSearching = false);
      return;
    }
    final lang = context.locale.languageCode;
    setState(() => _isVoiceSearching = true);
    await SpeechService.startListening(
      localeId: lang == 'ar' ? 'ar-EG' : 'en-US',
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _isVoiceSearching = false;
          _searchController.text = text;
        });
        _filter(text);
        VoiceService.speak(text, lang);
      },
    );
    if (mounted) setState(() => _isVoiceSearching = false);
  }

  Color _lineColor(int line) {
    if (line == 1) return AppColors.line1;
    if (line == 2) return AppColors.line2;
    return AppColors.line3;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final lang = context.locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text('interactive_map'.tr()),
        actions: [
          // Voice search button
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _isVoiceSearching ? _pulseAnim.value : 1.0,
              child: IconButton(
                icon: Icon(
                  _isVoiceSearching ? Icons.mic : Icons.mic_none,
                  color: _isVoiceSearching ? Colors.red : null,
                ),
                tooltip: lang == 'ar' ? 'ابحث بصوتك' : 'Voice Search',
                onPressed: _startVoiceSearch,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          _buildSearchBar(context, r, lang),
          // ── Line filter tabs ────────────────────────────────────────
          _buildLineFilter(context, r, lang),
          // ── Station list / selected ─────────────────────────────────
          Expanded(
            child: _selectedStation != null
                ? _buildStationDetail(context, r, lang)
                : _buildStationList(context, r, lang),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, Responsive r, String lang) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(r.pagePadding, 0, r.pagePadding, r.pagePadding),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filter,
          decoration: InputDecoration(
            hintText: lang == 'ar' ? 'ابحث عن محطة...' : 'Search station...',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filter('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLineFilter(BuildContext context, Responsive r, String lang) {
    final filters = [
      ('all', lang == 'ar' ? 'الكل' : 'All'),
      ('1', lang == 'ar' ? 'خط 1 🔴' : 'Line 1 🔴'),
      ('2', lang == 'ar' ? 'خط 2 🟡' : 'Line 2 🟡'),
      ('3', lang == 'ar' ? 'خط 3 🟢' : 'Line 3 🟢'),
    ];
    return Container(
      height: 48,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.pagePadding, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (key, label) = filters[i];
          final selected = _selectedLine == key;
          return GestureDetector(
            onTap: () => _filterByLine(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStationList(BuildContext context, Responsive r, String lang) {
    if (_filteredStations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(lang == 'ar' ? 'لا توجد محطات' : 'No stations found',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Group by line
    final byLine = <int, List<Station>>{};
    for (final s in _filteredStations) {
      byLine.putIfAbsent(s.line, () => []).add(s);
    }
    final lines = byLine.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: r.pagePadding / 2, vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, li) {
        final line = lines[li];
        final stations = byLine[line]!;
        final color = _lineColor(line);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    lang == 'ar' ? 'الخط $line' : 'Line $line',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Text('(${stations.length})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            ...stations.asMap().entries.map((e) {
              final idx = e.key;
              final s = e.value;
              final name = lang == 'ar' ? s.nameAr : s.nameEn;
              return FadeInUp(
                delay: Duration(milliseconds: 40 * idx),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStation = s),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              if (s.isTransfer)
                                Row(
                                  children: [
                                    Icon(Icons.swap_horiz, size: 13, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      lang == 'ar' ? 'محطة تبديل' : 'Transfer Station',
                                      style: const TextStyle(fontSize: 11, color: AppColors.accent),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Live train countdown
                        _buildLiveCountdown(context, lang),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.volume_up_outlined, size: 20, color: AppColors.primary),
                          tooltip: lang == 'ar' ? 'استمع' : 'Listen',
                          onPressed: () => VoiceService.speak(name, lang),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Simulates a live "next train" countdown using current time + station offset
  Widget _buildLiveCountdown(BuildContext context, String lang) {
    final now = DateTime.now();
    // Metro operates every 3–7 minutes, simulate based on seconds
    final secondsSinceMidnight = now.hour * 3600 + now.minute * 60 + now.second;
    final interval = 5; // minutes
    final nextMin = interval - ((secondsSinceMidnight ~/ 60) % interval);
    final label = nextMin == 0 ? (lang == 'ar' ? 'الآن' : 'Now!') : '$nextMin ${lang == 'ar' ? 'د' : 'm'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: nextMin <= 1 ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.train, size: 12, color: nextMin <= 1 ? AppColors.success : AppColors.primary),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: nextMin <= 1 ? AppColors.success : AppColors.primary,
              )),
        ],
      ),
    );
  }

  Widget _buildStationDetail(BuildContext context, Responsive r, String lang) {
    final s = _selectedStation!;
    final name = lang == 'ar' ? s.nameAr : s.nameEn;
    final color = _lineColor(s.line);

    // Crowd level based on current hour
    final hour = DateTime.now().hour;
    final isRush = (hour >= 7 && hour <= 9) || (hour >= 14 && hour <= 17);
    final isMed = (hour >= 10 && hour <= 13) || (hour >= 18 && hour <= 21);
    final crowdLevel = isRush ? 'high' : isMed ? 'medium' : 'low';
    final crowdLabel = crowdLevel == 'high'
        ? (lang == 'ar' ? '😤 ازدحام شديد' : '😤 Very Crowded')
        : crowdLevel == 'medium'
            ? (lang == 'ar' ? '😐 ازدحام متوسط' : '😐 Moderate')
            : (lang == 'ar' ? '😊 هادئ' : '😊 Quiet');
    final crowdColor = crowdLevel == 'high' ? AppColors.error : crowdLevel == 'medium' ? AppColors.warning : AppColors.success;

    // Next trains
    final now = DateTime.now();
    final nextTrains = List.generate(3, (i) {
      final mins = 5 * (i + 1) - (now.minute % 5);
      return mins <= 0 ? 5 + mins : mins;
    });

    return FadeInUp(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(r.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            GestureDetector(
              onTap: () => setState(() => _selectedStation = null),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 16, color: AppColors.primary),
                  Text(
                    lang == 'ar' ? 'العودة للقائمة' : 'Back to list',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Station header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.train, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        Text(
                          lang == 'ar' ? 'الخط ${s.line}' : 'Line ${s.line}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (s.isTransfer)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lang == 'ar' ? '🔄 محطة تبديل' : '🔄 Transfer Station',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white, size: 28),
                    tooltip: lang == 'ar' ? 'استمع للاسم' : 'Listen',
                    onPressed: () => VoiceService.speak(name, lang),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Crowd meter ──────────────────────────────────────────
            _buildInfoCard(
              context,
              icon: Icons.people,
              title: lang == 'ar' ? 'مقياس الزحمة الآن' : 'Current Crowd Level',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(color: crowdColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(crowdLabel,
                          style: TextStyle(fontWeight: FontWeight.bold, color: crowdColor, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: crowdLevel == 'high' ? 0.9 : crowdLevel == 'medium' ? 0.55 : 0.2,
                      backgroundColor: crowdColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(crowdColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRush
                        ? (lang == 'ar' ? '⚡ ساعة الذروة — أفضل وقت للسفر بعد 10 ص' : '⚡ Rush hour — best after 10 AM')
                        : isMed
                            ? (lang == 'ar' ? '🟡 متوسط — مناسب نسبياً' : '🟡 Moderate — fairly okay')
                            : (lang == 'ar' ? '✅ هادئ — وقت ممتاز للسفر!' : '✅ Quiet — great time to travel!'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Next trains ──────────────────────────────────────────
            _buildInfoCard(
              context,
              icon: Icons.access_time,
              title: lang == 'ar' ? '⏱️ القطارات القادمة' : '⏱️ Upcoming Trains',
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: nextTrains.map((mins) {
                  final isNext = mins == nextTrains.first;
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isNext ? color.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: isNext ? Border.all(color: color.withValues(alpha: 0.4)) : null,
                        ),
                        child: Text(
                          mins == 0 ? (lang == 'ar' ? 'الآن!' : 'Now!') : '$mins ${lang == 'ar' ? 'دقيقة' : 'min'}',
                          style: TextStyle(
                            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                            fontSize: isNext ? 16 : 14,
                            color: isNext ? color : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isNext)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(lang == 'ar' ? 'التالي' : 'Next',
                              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Exits ────────────────────────────────────────────────
            if (s.exits.isNotEmpty)
              _buildInfoCard(
                context,
                icon: Icons.door_front_door_outlined,
                title: lang == 'ar' ? '🚪 المخارج' : '🚪 Exits',
                content: Column(
                  children: s.exits.map((e) {
                    final label = lang == 'ar' ? e['ar']! : e['en']!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),

            // ── Connected stations ────────────────────────────────────
            _buildInfoCard(
              context,
              icon: Icons.linear_scale,
              title: lang == 'ar' ? '🔗 المحطات المتصلة' : '🔗 Connected Stations',
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: s.connectedTo.map((id) {
                  final conn = MetroData.stations[id];
                  if (conn == null) return const SizedBox();
                  final connName = lang == 'ar' ? conn.nameAr : conn.nameEn;
                  final connColor = _lineColor(conn.line);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStation = conn),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: connColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: connColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(connName,
                          style: TextStyle(fontSize: 12, color: connColor, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Open full details button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: Text(lang == 'ar' ? 'تفاصيل المحطة الكاملة' : 'Full Station Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
