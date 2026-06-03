import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../domain/entities/station.dart';

class MapPage extends StatefulWidget {
  final List<String>? highlightedRoute;
  
  const MapPage({super.key, this.highlightedRoute});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  
  int _selectedLineFilter = 0;
  bool _isDark = true;
  Station? _selectedStation;
  
  // Cairo Tahrir Square as default center
  static const LatLng _initialCenter = LatLng(30.0444, 31.2357);

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final hasRoute = widget.highlightedRoute != null && widget.highlightedRoute!.length > 1;

    // Tile layers (Light/Dark OSM alternative or default OSM)
    // Dark mode requires a dark tile server, CartoDB Dark Matter is commonly used for free dark maps.
    // For simplicity, we can use CartoDB Positron for Light and CartoDB Dark Matter for Dark.
    final tileUrl = _isDark 
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

    return Scaffold(
      appBar: AppBar(
        title: Text("Real Metro Map".tr()),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, color: Colors.white),
            onPressed: () => setState(() => _isDark = !_isDark),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
              minZoom: 10,
              maxZoom: 18,
              onTap: (_, __) {
                if (_selectedStation != null) {
                  setState(() => _selectedStation = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.rafiq_metrro',
              ),
              PolylineLayer(
                polylines: _buildPolylines(),
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          
          if (hasRoute)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildRouteBanner(isAr),
            ),
            
          if (_selectedStation != null)
             Positioned(
               bottom: Navigator.canPop(context) ? 24 : 110,
               left: 16,
               right: 16,
               child: _buildStationCard(context, isAr),
             ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final Map<String, Station> allStations = MetroData.stations;
    final List<Marker> markers = [];
    
    for (var station in allStations.values) {
      if (_selectedLineFilter != 0 && station.line != _selectedLineFilter) continue;
      
      final bool isOnRoute = widget.highlightedRoute?.contains(station.id) ?? false;
      final Color markerColor = isOnRoute 
          ? Colors.amber 
          : (station.line == 1 ? AppColors.line1 : (station.line == 2 ? AppColors.line2 : AppColors.line3));
          
      markers.add(
        Marker(
          point: LatLng(station.latitude, station.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
               setState(() => _selectedStation = station);
               _mapController.move(LatLng(station.latitude, station.longitude), 15.0);
            },
            child: Container(
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: const Icon(Icons.train_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<Polyline> _buildPolylines() {
    final Map<String, Station> allStations = MetroData.stations;
    final List<Polyline> polylines = [];
    
    // Line 1
    if (_selectedLineFilter == 0 || _selectedLineFilter == 1) {
      polylines.add(_createPolyline(AppColors.line1, _getLine1Stations(allStations)));
    }
    // Line 2
    if (_selectedLineFilter == 0 || _selectedLineFilter == 2) {
      polylines.add(_createPolyline(AppColors.line2, _getLine2Stations(allStations)));
    }
    // Line 3
    if (_selectedLineFilter == 0 || _selectedLineFilter == 3) {
      polylines.add(_createPolyline(AppColors.line3, _getLine3Stations(allStations)));
    }
    
    // Highlighted Route Polyline
    if (widget.highlightedRoute != null && widget.highlightedRoute!.isNotEmpty) {
      List<LatLng> routePoints = [];
      for (var id in widget.highlightedRoute!) {
        final s = allStations[id];
        if (s != null) {
          routePoints.add(LatLng(s.latitude, s.longitude));
        }
      }
      polylines.add(
        Polyline(
          points: routePoints,
          color: Colors.amber,
          strokeWidth: 6,
        ),
      );
    }
    return polylines;
  }
  
  Polyline _createPolyline(Color color, List<Station> stations) {
    return Polyline(
      points: stations.map((s) => LatLng(s.latitude, s.longitude)).toList(),
      color: color,
      strokeWidth: 4,
    );
  }

  List<Station> _getLine1Stations(Map<String, Station> all) {
    var lineSt = all.values.where((s) => s.line == 1).toList();
    lineSt.sort((a, b) => b.latitude.compareTo(a.latitude)); 
    return lineSt;
  }
  
  List<Station> _getLine2Stations(Map<String, Station> all) {
    var lineSt = all.values.where((s) => s.line == 2).toList();
    lineSt.sort((a, b) => b.latitude.compareTo(a.latitude));
    return lineSt;
  }
  
  List<Station> _getLine3Stations(Map<String, Station> all) {
    var lineSt = all.values.where((s) => s.line == 3).toList();
    lineSt.sort((a, b) => a.longitude.compareTo(b.longitude)); 
    return lineSt;
  }

  Widget _buildRouteBanner(bool isAr) {
    final route = widget.highlightedRoute!;
    final fromStation = MetroData.stations[route.first];
    final toStation = MetroData.stations[route.last];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAr
                  ? 'مسارك: ${fromStation?.nameAr ?? ''} ← ${toStation?.nameAr ?? ''} (${route.length} محطة)'
                  : 'Route: ${fromStation?.nameEn ?? ''} → ${toStation?.nameEn ?? ''} (${route.length} stops)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(BuildContext context, bool isAr) {
    final s = _selectedStation!;
    final color = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.train_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? s.nameAr : s.nameEn,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  isAr ? 'الخط ${s.line}' : 'Line ${s.line}',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
