import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/tourism_data.dart';
import 'attraction_detail_page.dart';
import '../../../../core/utils/osm_service.dart';
import '../widgets/place_image_widget.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/utils/ad_service.dart';

class NearbyPlacesPage extends StatefulWidget {
  const NearbyPlacesPage({super.key});

  @override
  State<NearbyPlacesPage> createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends State<NearbyPlacesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _tabBarAnimCtrl;
  late Animation<double> _tabBarFade;
  late Animation<Offset> _tabBarSlide;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  static const int _nearThreshold = 15;
  String? _selectedStationId = '_current_location';
  AttractionCategory? _selectedCategory; // null means "All"
  bool _isAutoLocating = false;
  bool _isLoadingOsm = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  Position? _userPosition;
  List<TouristAttraction> _osmAttractions = [];

  @override
  void initState() {
    super.initState();
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
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabBarAnimCtrl.dispose();
    _searchCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _findAndSetNearestStation();
    await _fetchOsmData();
  }

  Future<void> _findAndSetNearestStation() async {
    setState(() => _isAutoLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        _userPosition = position;
        if (mounted) {
          setState(() {
            _selectedStationId = '_current_location';
          });
          _tabBarAnimCtrl.reverse();
        }
      }
    } catch (e) {
      debugPrint("Auto-locate error: $e");
    } finally {
      if (mounted) setState(() => _isAutoLocating = false);
    }
  }

  Future<void> _fetchOsmData() async {
    if (_selectedStationId == null || !mounted) return;

    setState(() => _isLoadingOsm = true);
    try {
      double lat;
      double lng;

      if (_selectedStationId == '_current_location') {
        if (_userPosition == null) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
          _userPosition = position;
        }
        if (_userPosition != null) {
          lat = _userPosition!.latitude;
          lng = _userPosition!.longitude;
        } else {
          throw Exception("Location permission or services disabled");
        }
      } else {
        final allMap = {...MetroData.stations, ...MetroData.capitalStations};
        final station = allMap.values.firstWhere(
          (s) =>
              s.id == _selectedStationId || s.id.endsWith('_$_selectedStationId'),
          orElse: () => allMap.values.first,
        );
        lat = station.latitude;
        lng = station.longitude;
      }

      final osmData = await OsmService.fetchNearbyAmenities(
        lat,
        lng,
        radius: 1500,
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _osmAttractions = osmData;
        });
      }
    } catch (e) {
      debugPrint("OSM fetch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.locale.languageCode == 'ar'
                  ? 'فشل جلب البيانات. تأكد من تفعيل خدمة الموقع والإنترنت.'
                  : 'Failed to fetch places. Please check location services and internet.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingOsm = false);
    }
  }

  bool _isOpenNow(String openHours) {
    if (openHours.toLowerCase().contains('always open')) return true;
    final hour = DateTime.now().hour;
    return (hour >= 9 && hour <= 23);
  }

  Future<void> _openInMaps(String name) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}",
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final stationData = TourismDatabase.findByStation(_selectedStationId ?? '');

    // دمج البيانات المحلية المختارة مع بيانات OSM الشاملة
    List<TouristAttraction> list = [
      if (stationData != null) ...stationData.attractions,
      ..._osmAttractions,
    ];

    // منطق التصفية والبحث
    if (_selectedCategory != null) {
      list = list.where((a) => a.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (a) =>
                (a.name['ar'] ?? "").contains(_searchQuery) ||
                (a.name['en'] ?? "").toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? "استكشف حول المحطة" : "Explore Nearby"),
        actions: [
          if (_isAutoLocating || _isLoadingOsm)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _findAndSetNearestStation,
              icon: const Icon(Icons.my_location),
            ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          _buildHeader(isAr),
          _buildCategoryFilters(isAr),
          // ── Animated Proximity Tab Bar (station mode only) ───────────────
          if (_selectedStationId != '_current_location')
            _buildProximityTabBar(isAr, list),
          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _selectedStationId != '_current_location'
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_nearOf(list), isAr),
                      _buildList(_farOf(list), isAr),
                    ],
                  )
                : _buildList(list, isAr),
          ),
          if (_bannerAd != null && _isAdLoaded)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStationId,
                      isExpanded: true,
                      onChanged: (v) {
                        setState(() {
                          _selectedStationId = v;
                          _tabController.index = 0;
                        });
                        _fetchOsmData();
                        if (v != '_current_location') {
                          _tabBarAnimCtrl.forward(from: 0);
                        } else {
                          _tabBarAnimCtrl.reverse();
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: '_current_location',
                          child: Text(
                            isAr ? '📍 موقعي الحالي (كل العالم)' : '📍 My Current Location (Global)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ...{...MetroData.stations, ...MetroData.capitalStations}.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  isAr ? s.nameAr : s.nameEn,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: isAr
                  ? "ابحث عن مطعم، كافيه..."
                  : "Search for restaurant, cafe...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(bool isAr) {
    final cats = [
      {'label': isAr ? "الكل" : "All", 'cat': null, 'emoji': "📍"},
      {
        'label': isAr ? "مطاعم" : "Restaurants",
        'cat': AttractionCategory.restaurant,
        'emoji': "🍔",
      },
      {
        'label': isAr ? "كافيهات" : "Cafes",
        'cat': AttractionCategory.cafe,
        'emoji': "☕",
      },
      {
        'label': isAr ? "نوادي" : "Clubs",
        'cat': AttractionCategory.sport,
        'emoji': "🏆",
      },
      {
        'label': isAr ? "ترفيه" : "Fun",
        'cat': AttractionCategory.entertainment,
        'emoji': "🎭",
      },
      {
        'label': isAr ? "متاحف" : "Museums",
        'cat': AttractionCategory.museum,
        'emoji': "🏛️",
      },
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedCategory == cats[i]['cat'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cats[i]['cat'] as AttractionCategory?;
              });
              _fetchOsmData(); // جلب البيانات فور تغيير الفئة
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(cats[i]['emoji'] as String),
                  const SizedBox(width: 6),
                  Text(
                    cats[i]['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Near / Far helpers ────────────────────────────────────────────────────
  List<TouristAttraction> _nearOf(List<TouristAttraction> src) => src
      .where((a) => (int.tryParse(a.walkingMinutes.split('-').first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) <= _nearThreshold)
      .toList();

  List<TouristAttraction> _farOf(List<TouristAttraction> src) => src
      .where((a) => (int.tryParse(a.walkingMinutes.split('-').first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99) > _nearThreshold)
      .toList();

  // ── Animated Proximity Tab Bar ────────────────────────────────────────────
  Widget _buildProximityTabBar(bool isAr, List<TouristAttraction> list) {
    final nearCount = _nearOf(list).length;
    final farCount = _farOf(list).length;
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
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
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
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$nearCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$farCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildList(List<TouristAttraction> list, bool isAr) {
    if (_isLoadingOsm && list.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, _) => _buildShimmerCard(),
      );
    }

    if (list.isEmpty) return _buildEmptyState(isAr);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => FadeInUp(
        delay: Duration(milliseconds: index * 30),
        child: _buildLargePlaceCard(list[index], isAr),
      ),
    );
  }

  Widget _buildLargePlaceCard(TouristAttraction place, bool isAr) {
    final isOpen = _isOpenNow(place.openHours);
    final name = place.name[isAr ? 'ar' : 'en']!;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttractionDetailPage(
            attraction: place,
            lang: isAr ? 'ar' : 'en',
            stationName: _selectedStationId == '_current_location'
                ? (isAr ? "موقعي الحالي" : "My Location")
                : (() {
                    final all = {...MetroData.stations, ...MetroData.capitalStations};
                    final st = all[_selectedStationId];
                    if (st != null) {
                      return isAr ? st.nameAr : st.nameEn;
                    }
                    return TourismDatabase.findByStation(_selectedStationId!)
                            ?.stationName[isAr ? 'ar' : 'en'] ?? "";
                  })(),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: PlaceImageWidget(
                    place: place,
                    height: 180,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      isOpen
                          ? (isAr ? "مفتوح" : "Open")
                          : (isAr ? "مغلق" : "Closed"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.description[isAr ? 'ar' : 'en']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: _buildIconLabel(
                          Icons.directions_walk,
                          "${place.walkingMinutes} ${isAr ? "دقائق" : "min"}",
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIconLabel(
                          Icons.payments_outlined,
                          place.admissionEGP,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _openInMaps(name),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.near_me_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? "لا توجد نتائج مطابقة لبحثك" : "No matching results",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20, width: 150, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(height: 14, width: 200, color: Colors.white),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(child: Container(height: 16, width: 80, color: Colors.white)),
                      const SizedBox(width: 16),
                      Expanded(child: Container(height: 16, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
