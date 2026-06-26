import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rafiq_metrro/core/utils/ad_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tourism_data.dart';
import '../../../../core/utils/osm_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../metro/domain/entities/station.dart';
import 'package:url_launcher/url_launcher.dart';
import 'attraction_detail_page.dart';
import 'tourism_map_page.dart';

enum SortOption {
  recommended,
  priceLowToHigh,
  priceHighToLow,
  highestRated,
  newest,
}

class TouristAttractionsPage extends StatefulWidget {
  /// If provided, pre-selects this station on open
  final String? preselectedStation;

  const TouristAttractionsPage({super.key, this.preselectedStation});

  @override
  State<TouristAttractionsPage> createState() => _TouristAttractionsPageState();
}

class _TouristAttractionsPageState extends State<TouristAttractionsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _tabBarAnimCtrl;
  late Animation<double> _tabBarFade;
  late Animation<Offset> _tabBarSlide;

  final _searchCtrl = TextEditingController();
  String _selectedStation = '';
  AttractionCategory? _selectedCategory;
  List<TouristAttraction> _currentAttractions = [];
  StationAttractions? _currentStationData;
  bool _showAllMode = true; // true = show all top picks, false = station mode
  SortOption _selectedSort = SortOption.recommended;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  bool _isLoadingOsm = false;
  late ScrollController _scrollController;
  bool _isCollapsed = false;

  // Threshold in minutes: attractions ≤ this are "Near Station"
  static const int _nearThreshold = 15;

  List<TouristAttraction> get _nearAttractions => _currentAttractions
      .where((a) => (int.tryParse(a.walkingMinutes.split('-').first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) <= _nearThreshold)
      .toList();

  List<TouristAttraction> get _farAttractions => _currentAttractions
      .where((a) => (int.tryParse(a.walkingMinutes.split('-').first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) > _nearThreshold)
      .toList();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final isCollapsed = _scrollController.hasClients && _scrollController.offset > 80;
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    });
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isAdLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabBarAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _tabBarFade = CurvedAnimation(parent: _tabBarAnimCtrl, curve: Curves.easeOut);
    _tabBarSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tabBarAnimCtrl, curve: Curves.easeOutCubic));

    if (widget.preselectedStation != null) {
      _selectStationByName(widget.preselectedStation!);
    } else {
      _loadAllTopPicks();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAd?.dispose();
    _tabController.dispose();
    _tabBarAnimCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadAllTopPicks() {
    _tabBarAnimCtrl.reverse();
    setState(() {
      _showAllMode = true;
      _currentAttractions = TourismDatabase.getAllAttractions();
      _currentStationData = null;
    });
  }

  Station? _findStation(String query) {
    final clean = query.trim().toLowerCase()
        .replaceAll('el ', '')
        .replaceAll('al ', '')
        .replaceAll('el-', '')
        .replaceAll('es ', '')
        .replaceAll(' ', '');

    final all = {...MetroData.stations, ...MetroData.capitalStations}.values;
    for (final st in all) {
      final sEn = st.nameEn.toLowerCase()
          .replaceAll('el ', '')
          .replaceAll('al ', '')
          .replaceAll('el-', '')
          .replaceAll('es ', '')
          .replaceAll(' ', '');
      final sAr = st.nameAr.toLowerCase().replaceAll(' ', '');

      if (st.id == query || sEn == clean || sAr == clean) {
        return st;
      }
    }
    return null;
  }

  Future<void> _selectStation(Station station) async {
    setState(() {
      _selectedStation = Localizations.localeOf(context).languageCode == 'ar'
          ? station.nameAr
          : station.nameEn;
      _showAllMode = false;
      _isLoadingOsm = true;
      _selectedCategory = null;
      _tabController.index = 0;
    });

    _tabBarAnimCtrl.forward(from: 0);

    // Merge static database with dynamic OSM database
    List<TouristAttraction> combined = [];

    // Check if there is curated local data
    final localData = TourismDatabase.findByStation(station.id) ??
                      TourismDatabase.findByStation(station.nameEn);
    if (localData != null) {
      combined.addAll(localData.attractions);
    }

    try {
      final osmPlaces = await OsmService.fetchNearbyAmenities(
        station.latitude,
        station.longitude
      );

      for (final place in osmPlaces) {
        final duplicate = combined.any((a) =>
          a.name['en']?.toLowerCase() == place.name['en']?.toLowerCase() ||
          a.name['ar'] == place.name['ar']
        );
        if (!duplicate) {
          combined.add(place);
        }
      }
    } catch (e) {
      debugPrint("OSM dynamic fetch error: $e");
    }

    if (mounted) {
      setState(() {
        _currentStationData = StationAttractions(
          stationId: station.id,
          lineNumber: station.line.toString(),
          stationName: {'ar': station.nameAr, 'en': station.nameEn},
          attractions: combined,
        );
        _currentAttractions = combined;
        _isLoadingOsm = false;
      });
    }
  }

  void _selectStationByName(String name) {
    final station = _findStation(name);
    if (station != null) {
      _selectStation(station);
    } else {
      // Fallback to static lookup if no match in MetroData
      final found = TourismDatabase.findByStation(name);
      setState(() {
        _selectedStation = name;
        _showAllMode = false;
        if (found != null) {
          _currentStationData = found;
          _currentAttractions = found.attractions;
          _selectedCategory = null;
          _tabController.index = 0;
        } else {
          _currentStationData = null;
          _currentAttractions = [];
        }
      });
      if (found != null) {
        _tabBarAnimCtrl.forward(from: 0);
      } else {
        _tabBarAnimCtrl.reverse();
      }
    }
  }

  List<TouristAttraction> get _filteredAttractions {
    var list = _currentAttractions;
    if (_selectedCategory != null) {
      list = list.where((a) => a.category == _selectedCategory).toList();
    }

    List<TouristAttraction> sorted = List.from(list);
    switch (_selectedSort) {
      case SortOption.recommended:
        // No explicit sort, use default order
        break;
      case SortOption.priceLowToHigh:
        sorted.sort(
          (a, b) => _extractPrice(
            a.admissionEGP,
          ).compareTo(_extractPrice(b.admissionEGP)),
        );
        break;
      case SortOption.priceHighToLow:
        sorted.sort(
          (a, b) => _extractPrice(
            b.admissionEGP,
          ).compareTo(_extractPrice(a.admissionEGP)),
        );
        break;
      case SortOption.highestRated:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.newest:
        // No date field, fallback to default order
        break;
    }
    return sorted;
  }

  double _extractPrice(String priceStr) {
    if (priceStr.toLowerCase().contains('free')) return 0.0;
    if (priceStr.contains('مجانا')) return 0.0;
    final match = RegExp(r'\d+').firstMatch(priceStr);
    if (match != null) {
      return double.parse(match.group(0)!);
    }
    return 0.0;
  }

  String _lang(BuildContext context) => context.locale.languageCode == 'ar'
      ? 'ar'
      : context.locale.languageCode == 'fr'
      ? 'fr'
      : context.locale.languageCode == 'de'
      ? 'de'
      : 'en';

  @override
  Widget build(BuildContext context) {
    final lang = _lang(context);
    final isAr = lang == 'ar';
    final filtered = _filteredAttractions;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (_, __) => [
          // ── App bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            iconTheme: Theme.of(context).iconTheme,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildHeader(isAr),
            ),
            title: AnimatedOpacity(
              opacity: _isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                isAr ? '🗺️ المعالم السياحية' : "🗺️ Tourist Attractions",
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
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

            // ── Animated Proximity Tab Bar (station mode only) ────────────────
            if (!_showAllMode && _currentStationData != null)
              _buildProximityTabBar(isAr),

            // ── Sorting Row (only in all-mode or when tabs not shown) ─────────
            if (_showAllMode)
              _buildSortRow(
                isAr,
                lang,
                filtered.length,
                _currentAttractions.length,
              ),

            // ── Content Area ──────────────────────────────────────────────────
            Expanded(
              child: _isLoadingOsm
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _showAllMode
                      // ── ALL MODE: single flat list ────────────────────────────
                      ? (filtered.isEmpty
                          ? _buildEmptyState(isAr)
                          : _buildAttractionsList(filtered, lang, isAr))
                      // ── STATION MODE: TabBarView with near/far split ───────────
                      : _currentStationData == null
                          ? _buildEmptyState(isAr)
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 0 — Near Station
                                _buildTabContent(
                                  _applyFiltersAndSort(_nearAttractions),
                                  lang,
                                  isAr,
                                  emptyMsg: isAr
                                      ? '🚶 لا توجد أماكن قريبة جداً من المحطة'
                                      : '🚶 No places within walking distance',
                                ),
                                // Tab 1 — Farther Away
                                _buildTabContent(
                                  _applyFiltersAndSort(_farAttractions),
                                  lang,
                                  isAr,
                                  emptyMsg: isAr
                                      ? '🗺️ لا توجد أماكن بعيدة مسجلة لهذه المحطة'
                                      : '🗺️ No farther places listed for this station',
                                ),
                              ],
                            ),
            ),
            // ── Ad Banner ────────────────────────────────────────────────────
            if (_bannerAd != null && _isAdLoaded)
              SafeArea(
                top: false,
                child: Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                  ),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'station_picker_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.train_rounded),
        label: Text(isAr ? 'اختر محطة' : "Pick Station"),
        onPressed: () => _showStationPicker(context, isAr),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isAr) {
    final double topPadding = MediaQuery.of(context).padding.top + 16;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedOpacity(
        opacity: _isCollapsed ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? '🌍 اكتشف مصر بالمترو' : "🌍 Discover Egypt by Metro",
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'معالم عند كل محطة • ٤ لغات • مرشد ذكي'
                    : "Landmarks at every station • 4 languages • Smart guide",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isAr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: isAr
              ? 'ابحث عن محطة (مثل الأوبرا)'
              : "Search station (e.g. Opera)",
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadAllTopPicks();
                  },
                )
              : const Icon(Icons.search, color: Colors.grey),
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
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: _selectedCategory == null
                    ? AppColors.primary
                    : Colors.grey,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedCategory == null
                    ? AppColors.primary
                    : Colors.grey.withValues(alpha: 0.2),
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
                backgroundColor: Theme.of(context).cardColor,
                selectedColor: color.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected
                      ? color
                      : Colors.grey.withValues(alpha: 0.2),
                ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                  st.stationName["en".tr()] ?? '',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleSmall?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isAr ? '$count مكان سياحي قريب' : '$count nearby attractions',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 14),
            label: Text(isAr ? 'الكل' : "All"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
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

  // ── Sorting Row ────────────────────────────────────────────────────────────
  Widget _buildSortRow(
    bool isAr,
    String lang,
    int visibleCount,
    int totalCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              isAr
                  ? 'عرض $visibleCount من $totalCount'
                  : 'Showing $visibleCount of $totalCount',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TourismMapPage(
                        attractions: _filteredAttractions,
                        initialStationId: _currentStationData?.stationId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 14),
                label: Text(
                  isAr ? 'خريطة' : 'Map',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SortOption>(
                    value: _selectedSort,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 11,
                    ),
                    alignment: AlignmentDirectional.centerEnd,
                    onChanged: (SortOption? newValue) {
                      if (newValue != null)
                        setState(() => _selectedSort = newValue);
                    },
                    items: [
                      DropdownMenuItem(
                        value: SortOption.recommended,
                        child: Text(isAr ? 'موصى به' : 'Rec'),
                      ),
                      DropdownMenuItem(
                        value: SortOption.priceLowToHigh,
                        child: Text(isAr ? 'السعر (أقل)' : 'Low Price'),
                      ),
                      DropdownMenuItem(
                        value: SortOption.priceHighToLow,
                        child: Text(isAr ? 'السعر (أعلى)' : 'High Price'),
                      ),
                      DropdownMenuItem(
                        value: SortOption.highestRated,
                        child: Text(isAr ? 'تقييم' : 'Rated'),
                      ),
                      DropdownMenuItem(
                        value: SortOption.newest,
                        child: Text(isAr ? 'الأحدث' : 'New'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    final catLabel =
        TourismDatabase.categoryLabel[attraction.category]?[lang] ?? '';

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
                  : (_currentStationData?.stationName["en".tr()] ?? ''),
            ),
            transitionDuration: const Duration(milliseconds: 650),
            transitionsBuilder: (_, anim, __, child) {
              // Premium 3D perspective unfold transition from right edge
              final double rotationAngle =
                  (1.0 - anim.value) *
                  (3.141592653589793 / 4); // Rotates from 45 degrees
              final double translationX =
                  (1.0 - anim.value) * 160.0; // Slides in slightly
              final double scale = 0.88 + (anim.value * 0.12);
              final double opacity = anim.value.clamp(0.0, 1.0);

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015) // Deep 3D perspective
                  ..rotateY(rotationAngle)
                  ..translate(translationX, 0.0, 0.0),
                alignment: Alignment.centerRight,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: opacity, child: child),
                ),
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Gradient ─────────────────────────────────────────
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: isAr ? null : -20,
                    left: isAr ? -20 : null,
                    bottom: -20,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Text(
                        attraction.emoji,
                        style: TextStyle(
                          fontSize: 100,
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            catLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                attraction.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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

            // ── Content ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Action Row ──────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _modernPill(
                        Icons.directions_walk_rounded,
                        '${attraction.walkingMinutes} ${isAr ? 'دقيقة' : 'min'}',
                        Colors.blue,
                        isAr,
                      ),
                      _modernPill(
                        attraction.isFree
                            ? Icons.check_circle_rounded
                            : Icons.confirmation_number_rounded,
                        attraction.isFree
                            ? (isAr ? 'مجاناً' : 'Free')
                            : attraction.admissionEGP,
                        attraction.isFree ? Colors.green : Colors.orange,
                        isAr,
                        forceLtr:
                            true, // Fixes LTR english string alignment inside RTL
                      ),
                      _modernPill(
                        Icons.access_time_rounded,
                        attraction.openHours,
                        Colors.purple,
                        isAr,
                        forceLtr: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Web View Link
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.language, size: 16),
                      label: Text(
                        isAr ? 'عرض في جوجل' : "View in Web",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final query = Uri.encodeComponent('$name Cairo');
                        final url = Uri.parse(
                          'https://www.google.com/search?q=$query',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.inAppWebView);
                        }
                      },
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

  Widget _modernPill(
    IconData icon,
    String text,
    Color color,
    bool isAr, {
    bool forceLtr = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Directionality(
            textDirection: forceLtr
                ? ui.TextDirection.ltr
                : (isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Proximity Tab Bar (Near / Far) ─────────────────────────────────────────
  Widget _buildProximityTabBar(bool isAr) {
    final nearCount = _applyFiltersAndSort(_nearAttractions).length;
    final farCount = _applyFiltersAndSort(_farAttractions).length;

    return SlideTransition(
      position: _tabBarSlide,
      child: FadeTransition(
        opacity: _tabBarFade,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF7B5EA7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚶', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isAr ? 'قريب من المحطة' : 'Near Station',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$nearCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isAr ? 'بعيد بعض الشيء' : 'Farther Away',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$farCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Apply category filter + sort to a sub-list ──────────────────────────────
  List<TouristAttraction> _applyFiltersAndSort(List<TouristAttraction> source) {
    var list = source;
    if (_selectedCategory != null) {
      list = list.where((a) => a.category == _selectedCategory).toList();
    }
    List<TouristAttraction> sorted = List.from(list);
    switch (_selectedSort) {
      case SortOption.recommended:
        break;
      case SortOption.priceLowToHigh:
        sorted.sort((a, b) => _extractPrice(a.admissionEGP).compareTo(_extractPrice(b.admissionEGP)));
        break;
      case SortOption.priceHighToLow:
        sorted.sort((a, b) => _extractPrice(b.admissionEGP).compareTo(_extractPrice(a.admissionEGP)));
        break;
      case SortOption.highestRated:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.newest:
        break;
    }
    return sorted;
  }

  // ── Tab content page ────────────────────────────────────────────────────────
  Widget _buildTabContent(
    List<TouristAttraction> items,
    String lang,
    bool isAr, {
    required String emptyMsg,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text(emptyMsg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return _buildAttractionsList(items, lang, isAr);
  }

  // ── Responsive attractions list/grid ────────────────────────────────────────
  Widget _buildAttractionsList(
    List<TouristAttraction> items,
    String lang,
    bool isAr,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int count = constraints.maxWidth > 1300
            ? 4
            : constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 650
                    ? 2
                    : 1;
        final stationName = _currentStationData?.stationName["en".tr()] ?? '';
        if (count == 1) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildAttractionCard(items[i], lang, isAr, i, stationName: stationName),
          );
        }
        final double spacing = 16.0;
        final double width = (constraints.maxWidth - spacing * (count + 1)) / count;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(
              items.length,
              (i) => SizedBox(
                width: width,
                child: _buildAttractionCard(items[i], lang, isAr, i, stationName: stationName),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isAr) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔍', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 12),
        Text(
          isAr ? 'لا توجد أماكن في هذا التصنيف' : "No places in this category",
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    ),
  );

  // ── Station picker ─────────────────────────────────────────────────────────
  void _showStationPicker(BuildContext context, bool isAr) {
    final searchCtrl = TextEditingController();
    final allStations = {...MetroData.stations, ...MetroData.capitalStations}.values.toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = allStations
              .where(
                (s) =>
                    query.isEmpty ||
                    s.nameAr.toLowerCase().contains(query) ||
                    s.nameEn.toLowerCase().contains(query),
              )
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  isAr ? '🚇 اختر محطة' : "🚇 Select a Station",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'اختر أي محطة في المترو لعرض المعالم القريبة منها'
                      : "Choose any metro station to view nearby landmarks",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: isAr ? 'بحث عن محطة...' : "Search station...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (_) => setLocalState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final st = filtered[i];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.train_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isAr ? st.nameAr : st.nameEn,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.titleMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isAr ? 'الخط ${st.line}' : 'Line ${st.line}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _selectStation(st);
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
