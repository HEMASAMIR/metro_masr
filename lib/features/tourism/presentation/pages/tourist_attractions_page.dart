import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tourism_data.dart';
import 'attraction_detail_page.dart';

class TouristAttractionsPage extends StatefulWidget {
  /// If provided, pre-selects this station on open
  final String? preselectedStation;

  const TouristAttractionsPage({super.key, this.preselectedStation});

  @override
  State<TouristAttractionsPage> createState() => _TouristAttractionsPageState();
}

class _TouristAttractionsPageState extends State<TouristAttractionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _selectedStation = '';
  AttractionCategory? _selectedCategory;
  List<TouristAttraction> _currentAttractions = [];
  StationAttractions? _currentStationData;
  bool _showAllMode = true; // true = show all top picks, false = station mode



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.preselectedStation != null) {
      _selectStationByName(widget.preselectedStation!);
    } else {
      _loadAllTopPicks();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadAllTopPicks() {
    setState(() {
      _showAllMode = true;
      _currentAttractions = TourismDatabase.getAllAttractions();
      _currentStationData = null;
    });
  }

  void _selectStationByName(String name) {
    final found = TourismDatabase.findByStation(name);
    setState(() {
      _selectedStation = name;
      _showAllMode = false;
      if (found != null) {
        _currentStationData = found;
        _currentAttractions = found.attractions;
        _selectedCategory = null;
      } else {
        _currentStationData = null;
        _currentAttractions = [];
      }
    });
  }

  List<TouristAttraction> get _filteredAttractions {
    var list = _currentAttractions;
    if (_selectedCategory != null) {
      list = list.where((a) => a.category == _selectedCategory).toList();
    }
    return list;
  }

  String _lang(BuildContext context) =>
      context.locale.languageCode == 'ar' ? 'ar'
      : context.locale.languageCode == 'fr' ? 'fr'
      : context.locale.languageCode == 'de' ? 'de'
      : 'en';

  @override
  Widget build(BuildContext context) {
    final lang = _lang(context);
    final isAr = lang == 'ar';
    final filtered = _filteredAttractions;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── App bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0A0E27),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildHeader(isAr),
            ),
            title: Text(
              isAr ? '🗺️ الأماكن السياحية' : '🗺️ Tourist Attractions',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildSearchBar(isAr),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Category filter chips ─────────────────────────────────────────
            _buildCategoryChips(lang),
            // ── Station info banner ───────────────────────────────────────────
            if (_currentStationData != null) _buildStationBanner(isAr),
            if (!_showAllMode && _currentStationData == null)
              _buildNoResultsBanner(isAr),
            // ── Attractions list ──────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(isAr)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildAttractionCard(
                        filtered[i], lang, isAr, i,
                        stationName: _currentStationData?.stationName[isAr ? 'ar' : 'en'] ?? '',
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB: Browse all stations ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.train_rounded),
        label: Text(isAr ? 'اختر محطة' : 'Pick Station'),
        onPressed: () => _showStationPicker(context, isAr),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2A6C), Color(0xFF0A0E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFFF6B6B)],
                ).createShader(r),
                child: Text(
                  isAr
                    ? '🌍 اكتشف مصر من المترو'
                    : '🌍 Discover Egypt by Metro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                  ? 'مزارات في كل محطة • 4 لغات • دليل ذكي'
                  : 'Landmarks at every station • 4 languages • Smart guide',
                style: const TextStyle(color: Color(0xFF8899CC), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        decoration: InputDecoration(
          hintText: isAr ? '🔍 ابحث عن محطة أو مكان...' : '🔍 Search station or place...',
          hintStyle: const TextStyle(color: Color(0xFF556080)),
          filled: true,
          fillColor: const Color(0xFF0D1530),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E2D5A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E2D5A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadAllTopPicks();
                  },
                )
              : const Icon(Icons.search, color: Color(0xFF556080)),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) _selectStationByName(v.trim());
        },
        onChanged: (v) {
          if (v.isEmpty) _loadAllTopPicks();
        },
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────
  Widget _buildCategoryChips(String lang) {
    final categories = AttractionCategory.values;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _selectedCategory == null,
              label: Text(lang == 'ar' ? 'الكل' : 'All'),
              onSelected: (_) => setState(() => _selectedCategory = null),
              backgroundColor: const Color(0xFF0D1530),
              selectedColor: AppColors.primary.withOpacity(0.3),
              labelStyle: TextStyle(
                color: _selectedCategory == null ? AppColors.primary : Colors.white70,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedCategory == null ? AppColors.primary : const Color(0xFF1E2D5A),
              ),
            ),
          ),
          ...categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            final color = Color(TourismDatabase.categoryColor[cat]!);
            final label = TourismDatabase.categoryLabel[cat]?[lang] ?? cat.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text('${TourismDatabase.categoryEmoji[cat]} $label'),
                onSelected: (_) => setState(() {
                  _selectedCategory = isSelected ? null : cat;
                }),
                backgroundColor: const Color(0xFF0D1530),
                selectedColor: color.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSelected ? color : const Color(0xFF1E2D5A)),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Station banner ─────────────────────────────────────────────────────────
  Widget _buildStationBanner(bool isAr) {
    final st = _currentStationData!;
    final count = _currentAttractions.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A6C), Color(0xFF0D1530)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.train_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  st.stationName[isAr ? 'ar' : 'en'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  isAr
                    ? '$count مكان سياحي قريب'
                    : '$count nearby attractions',
                  style: const TextStyle(color: Color(0xFF8899CC), fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 14),
            label: Text(isAr ? 'الكل' : 'All'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              textStyle: const TextStyle(fontSize: 11),
            ),
            onPressed: _loadAllTopPicks,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsBanner(bool isAr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                ? '"$_selectedStation" — لا توجد بيانات سياحية بعد لهذه المحطة'
                : '"$_selectedStation" — No tourism data yet for this station',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attraction card ────────────────────────────────────────────────────────
  Widget _buildAttractionCard(
    TouristAttraction attraction,
    String lang,
    bool isAr,
    int index, {
    String stationName = '',
  }) {
    final color = Color(TourismDatabase.categoryColor[attraction.category]!);
    final name = attraction.name[lang] ?? attraction.name['en']!;
    final desc = attraction.description[lang] ?? attraction.description['en']!;
    final catLabel = TourismDatabase.categoryLabel[attraction.category]?[lang] ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AttractionDetailPage(
              attraction: attraction,
              lang: lang,
              stationName: stationName.isNotEmpty
                  ? stationName
                  : (_currentStationData?.stationName[isAr ? 'ar' : 'en'] ?? ''),
            ),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0), end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1530),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 16, spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Illustration header ─────────────────────────────────────────
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Big emoji background
                  Positioned(
                    right: -10, bottom: -10,
                    child: Text(
                      attraction.emoji,
                      style: TextStyle(
                        fontSize: 90,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withOpacity(0.4)),
                              ),
                              child: Text(
                                '${TourismDatabase.categoryEmoji[attraction.category]} $catLabel',
                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            // Rating
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    attraction.rating.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          attraction.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF8899CC), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  // Info pills row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoPill(Icons.directions_walk_rounded,
                          '${attraction.walkingMinutes} min', Colors.blue),
                      _infoPill(
                        attraction.isFree ? Icons.check_circle_rounded : Icons.paid_rounded,
                        attraction.admissionEGP,
                        attraction.isFree ? Colors.green : Colors.orange,
                      ),
                      _infoPill(Icons.access_time_rounded, attraction.openHours, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  Wrap(
                    spacing: 6,
                    children: attraction.tags.take(3).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$t', style: const TextStyle(color: Color(0xFF556080), fontSize: 10)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildEmptyState(bool isAr) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔍', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 12),
        Text(
          isAr ? 'لا توجد أماكن في هذه الفئة' : 'No places in this category',
          style: const TextStyle(color: Color(0xFF8899CC), fontSize: 14),
        ),
      ],
    ),
  );

  // ── Station picker ─────────────────────────────────────────────────────────
  void _showStationPicker(BuildContext context, bool isAr) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          final query = searchCtrl.text.toLowerCase();
          // Show stations that have data + filter by search
          final withData = TourismDatabase.data
              .where((s) =>
                  query.isEmpty ||
                  (s.stationName['ar'] ?? '').toLowerCase().contains(query) ||
                  (s.stationName['en'] ?? '').toLowerCase().contains(query))
              .toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF0D1530),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                // Title
                Text(
                  isAr ? '🚇 اختر محطة' : '🚇 Select a Station',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                    ? 'المحطات التالية بها بيانات سياحية'
                    : 'Stations with tourism data',
                  style: const TextStyle(color: Color(0xFF8899CC), fontSize: 12),
                ),
                const SizedBox(height: 12),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isAr ? 'ابحث...' : 'Search...',
                      hintStyle: const TextStyle(color: Color(0xFF556080)),
                      filled: true,
                      fillColor: const Color(0xFF1A2A6C).withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF556080)),
                    ),
                    onChanged: (_) => setLocalState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: withData.length,
                    itemBuilder: (_, i) {
                      final st = withData[i];
                      final count = st.attractions.length;
                      return ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.train_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          st.stationName[isAr ? 'ar' : 'en'] ?? '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isAr ? '$count أماكن سياحية' : '$count attractions',
                          style: const TextStyle(color: Color(0xFF8899CC), fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                        onTap: () {
                          Navigator.pop(context);
                          _selectStationByName(st.stationName['en']!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
