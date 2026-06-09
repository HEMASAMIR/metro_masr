import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/tourism_data.dart';
import 'attraction_detail_page.dart';
import '../../../../core/utils/osm_service.dart';

class NearbyPlacesPage extends StatefulWidget {
  const NearbyPlacesPage({super.key});

  @override
  State<NearbyPlacesPage> createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends State<NearbyPlacesPage> {
  String? _selectedStationId = 'sadat';
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
    _initialize();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
            accuracy: LocationAccuracy.low,
          ),
        );
        _userPosition = position;

        String? nearestId;
        double minDistance = double.infinity;
        final stationsWithData = TourismDatabase.data
            .map((s) => s.stationId)
            .toSet();

        for (var entry in MetroData.stations.entries) {
          // نحدد المعرف القصير المطابق من قاعدة بيانات السياحة
          final matchedShortId = stationsWithData.cast<String?>().firstWhere(
            (id) => entry.key == id || entry.key.endsWith('_$id'),
            orElse: () => null,
          );

          if (matchedShortId != null) {
            final station = entry.value;
            double distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              station.latitude,
              station.longitude,
            );
            if (distance < minDistance) {
              minDistance = distance;
              nearestId =
                  matchedShortId; // نستخدم المعرف القصير ليتوافق مع الـ Dropdown
            }
          }
        }
        if (nearestId != null && mounted)
          setState(() => _selectedStationId = nearestId);
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
      // البحث عن كائن المحطة الصحيح من MetroData باستخدام الـ ID المختار لجلب الإحداثيات
      final station = MetroData.stations.values.firstWhere(
        (s) =>
            s.id == _selectedStationId || s.id.endsWith('_$_selectedStationId'),
        orElse: () => MetroData.stations.values.first,
      );

      final osmData = await OsmService.fetchNearbyAmenities(
        station.latitude,
        station.longitude,
        radius: 1200,
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _osmAttractions = osmData;
        });
      }
    } catch (e) {
      debugPrint("OSM fetch error: $e");
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
          _buildHeader(isAr),
          _buildCategoryFilters(isAr),
          Expanded(
            child: _buildList(list, isAr),
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
                        setState(() => _selectedStationId = v);
                        _fetchOsmData(); // جلب البيانات فور تغيير المحطة
                      },
                      items: TourismDatabase.data
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.stationId,
                              child: Text(
                                s.stationName[isAr ? 'ar' : 'en']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
            stationName:
                TourismDatabase.findByStation(
                  _selectedStationId!,
                )?.stationName[isAr ? 'ar' : 'en'] ??
                "",
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
                  child: CachedNetworkImage(
                    imageUrl:
                        place.imageUrl ??
                        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 500),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
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
