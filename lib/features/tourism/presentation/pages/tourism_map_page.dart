import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tourism_data.dart';
import '../../../../core/utils/metro_data.dart';
import 'attraction_detail_page.dart';

class TourismMapPage extends StatefulWidget {
  final List<TouristAttraction> attractions;
  final String? initialStationId;

  const TourismMapPage({
    super.key,
    required this.attractions,
    this.initialStationId,
  });

  @override
  State<TourismMapPage> createState() => _TourismMapPageState();
}

class _TourismMapPageState extends State<TourismMapPage> {
  final MapController _mapController = MapController();
  bool _isDark = true;
  TouristAttraction? _selectedAttraction;
  AttractionCategory? _selectedCategory;
  final double _cairoLat = 30.0444;
  final double _cairoLng = 31.2357;

  @override
  void initState() {
    super.initState();
    // Center map on initial station if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialStationId != null) {
        final station = MetroData.stations[widget.initialStationId!];
        if (station != null) {
          _mapController.move(LatLng(station.latitude, station.longitude), 14.5);
        }
      }
    });
  }

  LatLng _getAttractionLatLng(TouristAttraction attraction) {
    // Find the station this attraction belongs to
    for (final sa in TourismDatabase.data) {
      if (sa.attractions.any((a) => a.id == attraction.id)) {
        final station = MetroData.stations[sa.stationId];
        if (station != null) {
          // Add a tiny, deterministic offset based on attraction ID hash to prevent overlapping markers
          final hash = attraction.id.hashCode.abs();
          final offsetLat = ((hash % 10) - 5) * 0.0007;
          final offsetLng = (((hash ~/ 10) % 10) - 5) * 0.0007;
          return LatLng(station.latitude + offsetLat, station.longitude + offsetLng);
        }
      }
    }
    return LatLng(_cairoLat, _cairoLng);
  }

  String _lang(BuildContext context) =>
      context.locale.languageCode == 'ar' ? 'ar' : 'en';

  @override
  Widget build(BuildContext context) {
    final lang = _lang(context);
    final isAr = lang == 'ar';

    // Filter attractions by category
    final filteredAttractions = widget.attractions.where((a) {
      return _selectedCategory == null || a.category == _selectedCategory;
    }).toList();

    final tileUrl = _isDark
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'خريطة المعالم السياحية' : 'Tourism Map'),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
            onPressed: () => setState(() => _isDark = !_isDark),
            tooltip: "Toggle Map Theme",
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_cairoLat, _cairoLng),
              initialZoom: 13.0,
              minZoom: 10,
              maxZoom: 18,
              onTap: (_, __) {
                if (_selectedAttraction != null) {
                  setState(() => _selectedAttraction = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.rafiq_metrro',
              ),
              MarkerLayer(
                markers: filteredAttractions.map((attraction) {
                  final latLng = _getAttractionLatLng(attraction);
                  final color = Color(TourismDatabase.categoryColor[attraction.category]!);
                  final isSelected = _selectedAttraction?.id == attraction.id;

                  return Marker(
                    point: latLng,
                    width: isSelected ? 50 : 42,
                    height: isSelected ? 50 : 42,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedAttraction = attraction);
                        _mapController.move(latLng, 15.0);
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.amber : Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              attraction.emoji,
                              style: TextStyle(fontSize: isSelected ? 24 : 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Category Filters horizontal scroll ──────────────────────────────
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedCategory = null),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == null
                            ? AppColors.primary
                            : (Theme.of(context).cardColor).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedCategory == null
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        isAr ? 'الكل' : 'All',
                        style: TextStyle(
                          color: _selectedCategory == null ? Colors.white : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  ...AttractionCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final color = Color(TourismDatabase.categoryColor[cat]!);
                    final label = TourismDatabase.categoryLabel[cat]?[lang] ?? cat.name;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (Theme.of(context).cardColor).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(TourismDatabase.categoryEmoji[cat] ?? ''),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Floating selected card pop-up ──────────────────────────────────
          if (_selectedAttraction != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildAttractionPopUpCard(context, _selectedAttraction!, lang, isAr),
            ),
        ],
      ),
    );
  }

  Widget _buildAttractionPopUpCard(
    BuildContext context,
    TouristAttraction attraction,
    String lang,
    bool isAr,
  ) {
    final color = Color(TourismDatabase.categoryColor[attraction.category]!);
    final name = attraction.name[lang] ?? attraction.name['en']!;
    final catLabel = TourismDatabase.categoryLabel[attraction.category]?[lang] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    attraction.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        catLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _selectedAttraction = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk_rounded, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${attraction.walkingMinutes} ${isAr ? 'دقيقة' : 'min'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    attraction.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    attraction.isFree ? Icons.check_circle_rounded : Icons.confirmation_number_rounded,
                    color: attraction.isFree ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attraction.isFree ? (isAr ? 'مجاناً' : 'Free') : attraction.admissionEGP,
                    style: TextStyle(
                      color: attraction.isFree ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: Text(
              isAr ? 'عرض التفاصيل والاتجاهات' : 'View Details & Directions',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttractionDetailPage(
                    attraction: attraction,
                    lang: lang,
                    stationName: '',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
