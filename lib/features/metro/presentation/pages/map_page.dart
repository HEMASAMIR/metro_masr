import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../domain/entities/station.dart';
import 'station_details_page.dart';

/// Metro Map using InteractiveViewer + CustomPainter
/// Does not require Google Maps API Key
class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TransformationController _transformController = TransformationController();
  
  int _selectedLineFilter = 0; // 0=All, 1/2/3=Lines, 4=Capital
  Station? _selectedStation;

  @override
  void initState() {
    super.initState();
    // Center the map initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      _transformController.value = Matrix4.identity()
        ..translate(
          -400.0 + screenSize.width / 2,
          -400.0 + screenSize.height / 2,
        );
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _recenter() {
    final screenSize = MediaQuery.of(context).size;
    _transformController.value = Matrix4.identity()
      ..translate(
        -400.0 + screenSize.width / 2,
        -400.0 + screenSize.height / 2,
      );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // light background for map
      appBar: AppBar(
        title: Text(isAr ? 'خريطة تفاعلية لخطوط المترو' : 'Interactive Metro Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: isAr ? 'توسيط الخريطة' : 'Center Map',
            onPressed: _recenter,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── The Interactive Map Area ─────────────────────────────────
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(800),
              child: Center(
                child: SizedBox(
                  width: 1200,
                  height: 1200,
                  // The CustomPaint draws lines & stations
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MetroMapPainter(
                            selectedLineFilter: _selectedLineFilter,
                          ),
                        ),
                      ),
                      // Overlay gesture detectors for stations
                      ..._buildStationTapAreas(isAr),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Line filter chips (top overlay) ──────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildLineFilterChips(isAr),
          ),

          // ── Selected station bottom sheet ─────────────────────────────
          if (_selectedStation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStationCard(context, isAr),
            ),
        ],
      ),
    );
  }

  // Generate invisible tap areas over the painted stations
  List<Widget> _buildStationTapAreas(bool isAr) {
    final List<Widget> widgets = [];
    final all = MetroData.stations.values.toList();
    final painter = MetroMapPainter(selectedLineFilter: _selectedLineFilter);

    for (var s in all) {
      if (_selectedLineFilter != 0 && s.line != _selectedLineFilter) continue;
      
      final pos = painter.getStationPosition(s.id);
      if (pos == null) continue;

      widgets.add(
        Positioned(
          left: pos.dx - 15,
          top: pos.dy - 15,
          child: GestureDetector(
            onTap: () => setState(() => _selectedStation = s),
            child: Container(
              width: 30,
              height: 30,
              color: Colors.transparent, // transparent touch target
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildLineFilterChips(bool isAr) {
    final filters = [
      (0, isAr ? 'الكل' : 'All', Colors.grey[700]!),
      (1, isAr ? 'خط 1' : 'Line 1', AppColors.line1),
      (2, isAr ? 'خط 2' : 'Line 2', AppColors.line2),
      (3, isAr ? 'خط 3' : 'Line 3', AppColors.line3),
      (4, isAr ? 'قطر العاصمة' : 'Capital Metro', const Color(0xFF9C27B0)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedLineFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLineFilter = f.$1;
                  _selectedStation = null;
                });
                _recenter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? f.$3 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  border: Border.all(color: isSelected ? f.$3 : Colors.grey.withValues(alpha: 0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f.$1 != 0)
                      Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: isSelected ? Colors.white : f.$3, shape: BoxShape.circle),
                      ),
                    Text(
                      f.$2,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStationCard(BuildContext context, bool isAr) {
    final s = _selectedStation!;
    final name = isAr ? s.nameAr : s.nameEn;
    final lineColor = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: lineColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.train_rounded, color: lineColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(isAr ? 'الخط ${s.line}' : 'Line ${s.line}', style: TextStyle(color: lineColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        if (s.isTransfer) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isAr ? '🔄 محطة تبديل' : '🔄 Transfer Station', style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => setState(() => _selectedStation = null),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lineColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  label: Text(isAr ? 'التفاصيل كاملة' : 'Full Details', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StationDetailsPage(station: s)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Custom Painter to Draw the Metro Map ────────────────────────────────────

class MetroMapPainter extends CustomPainter {
  final int selectedLineFilter;

  MetroMapPainter({required this.selectedLineFilter});

  // Base map parameters
  static const double cx = 600; // center x of the 1200x1200 canvas
  static const double cy = 600; // center y
  
  // Hardcoded rough relative coordinate mapping designed to look like a metro map
  // Not strictly geocoordinate accurate, but visually pleasant schematic map
  final Map<String, Offset> _customPositions = {
    // ---- TRANSFER STATIONS (Anchor points) ----
    'sadat': const Offset(cx, cy),
    'shohadaa': const Offset(cx + 40, cy - 120),
    'attaba': const Offset(cx + 80, cy - 60),
    'nasser': const Offset(cx + 20, cy - 60),
    'gamal_abdel_nasser': const Offset(cx + 20, cy - 60), // Alias handling

    // ---- LINE 1 (Red) - North to South roughly ----
    'marg_new': const Offset(cx + 100, cy - 350),
    'marg': const Offset(cx + 100, cy - 320),
    'ezbet_el_nakhl': const Offset(cx + 100, cy - 290),
    'ain_shams': const Offset(cx + 100, cy - 260),
    'matareyya': const Offset(cx + 90, cy - 230),
    'helmeyet_el_zaitoun': const Offset(cx + 80, cy - 200),
    'hadayeq_el_zaitoun': const Offset(cx + 70, cy - 170),
    'saray_el_qobba': const Offset(cx + 60, cy - 140),
    'hammamat_el_qobba': const Offset(cx + 50, cy - 110),
    'kobri_el_qobba': const Offset(cx + 45, cy - 80),
    'manshiet_el_sadr': const Offset(cx + 40, cy - 50),
    'el_demerdash': const Offset(cx + 30, cy - 20),
    'ghamra': const Offset(cx + 20, cy + 10),
    // shohadaa
    'urabi': const Offset(cx + 10, cy + 30),
    // nasser
    // sadat
    'saad_zaghloul': const Offset(cx - 10, cy + 30),
    'sayyeda_zeinab': const Offset(cx - 20, cy + 60),
    'el_malek_el_saleh': const Offset(cx - 30, cy + 90),
    'mar_girgis': const Offset(cx - 40, cy + 120),
    'el_zahraa': const Offset(cx - 45, cy + 150),
    'dar_el_salam': const Offset(cx - 50, cy + 180),
    'hadayeq_el_maadi': const Offset(cx - 50, cy + 210),
    'maadi': const Offset(cx - 50, cy + 240),
    'thakanat_el_maadi': const Offset(cx - 50, cy + 270),
    'tura_el_balad': const Offset(cx - 45, cy + 300),
    'kozzika': const Offset(cx - 40, cy + 330),
    'tura_el_asman': const Offset(cx - 30, cy + 360),
    'el_maasara': const Offset(cx - 20, cy + 390),
    'hadayeq_helwan': const Offset(cx - 10, cy + 420),
    'wadi_hof': const Offset(cx, cy + 450),
    'helwan_university': const Offset(cx + 10, cy + 480),
    'ain_helwan': const Offset(cx + 20, cy + 510),
    'helwan': const Offset(cx + 30, cy + 540),

    // ---- LINE 2 (Yellow) - Northwest to Southwest roughly ----
    'shubra_el_kheima': const Offset(cx - 80, cy - 300),
    'kolleyet_el_zeraa': const Offset(cx - 70, cy - 270),
    'mezallat': const Offset(cx - 60, cy - 240),
    'khalafawy': const Offset(cx - 50, cy - 210),
    'st_teresa': const Offset(cx - 40, cy - 180),
    'rod_el_farag': const Offset(cx - 30, cy - 150),
    'massara': const Offset(cx - 20, cy - 120),
    // shohadaa
    // attaba
    
    // mohamed_naguib
    'mohamed_naguib': const Offset(cx + 40, cy - 30),
    // sadat
    'opera': const Offset(cx - 40, cy + 10),
    'dokki': const Offset(cx - 80, cy + 20),
    'bohooth': const Offset(cx - 120, cy + 30),
    'cairo_university': const Offset(cx - 160, cy + 50), // Intersect line 3 future
    'faisal': const Offset(cx - 190, cy + 80),
    'giza': const Offset(cx - 220, cy + 110),
    'omm_el_misryeen': const Offset(cx - 250, cy + 140),
    'sakiat_mekki': const Offset(cx - 280, cy + 170),
    'el_mounib': const Offset(cx - 310, cy + 200),

    // ---- LINE 3 (Green) - East to West roughly ----
    'adly_mansour': const Offset(cx + 380, cy - 200),
    'el_hay_el_ العاشر': const Offset(cx + 350, cy - 190),
    'omar_ibn_el_khattab': const Offset(cx + 320, cy - 180),
    'heshem_barakat': const Offset(cx + 290, cy - 170),
    'el_nozha': const Offset(cx + 260, cy - 160),
    'nadi_el_shams': const Offset(cx + 230, cy - 150),
    'alf_maskan': const Offset(cx + 200, cy - 140),
    'heliopolis': const Offset(cx + 170, cy - 130),
    'haroun': const Offset(cx + 140, cy - 120),
    'al_ahram': const Offset(cx + 110, cy - 110),
    'koleyet_el_banat': const Offset(cx + 80, cy - 100),
    'stadium': const Offset(cx + 50, cy - 90),
    'fair_zone': const Offset(cx + 20, cy - 80),
    'abbassia': const Offset(cx - 10, cy - 70),
    'abdou_pasha': const Offset(cx - 40, cy - 65),
    'el_geish': const Offset(cx - 70, cy - 65),
    'bab_el_shaaria': const Offset(cx - 100, cy - 65),
    // attaba
    // nasser
    'maspero': const Offset(cx - 30, cy - 40),
    'safaa_hegazy': const Offset(cx - 70, cy - 30),
    'kit_kat': const Offset(cx - 110, cy - 20),
    'sudan': const Offset(cx - 140, cy - 10),
    'imbaba': const Offset(cx - 170, cy - 20),
    'bawabt_el_qahera': const Offset(cx - 200, cy - 40),
    'el_qawmia': const Offset(cx - 230, cy - 60),
    'ring_road': const Offset(cx - 260, cy - 80),
    'rod_el_farag_corr': const Offset(cx - 290, cy - 100),
    'tawfiqiya': const Offset(cx - 120, cy + 10),
    'wadi_el_nil': const Offset(cx - 100, cy + 40),
    'gamaat_el_dowal': const Offset(cx - 80, cy + 70),
    'bulaq_el_dakroor': const Offset(cx - 120, cy + 80),
    // cairo_university
  };

  Offset? getStationPosition(String id) {
    if (_customPositions.containsKey(id)) {
      return _customPositions[id];
    }
    
    // Fallback: create an arbitrary position if missing so it doesn't crash
    // but spreads them out in a circle
    final allKeys = MetroData.stations.keys.toList();
    final idx = allKeys.indexOf(id);
    if (idx != -1) {
      double angle = (idx / allKeys.length) * 3.1415 * 2;
      return Offset(cx + 400 * ui.window.devicePixelRatio * 0, cy) + 
             Offset(10 + (idx * 5) % 300, 10 + (idx * 15) % 300); 
    }
    return const Offset(cx, cy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine1 = Paint()..color = AppColors.line1..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final paintLine2 = Paint()..color = AppColors.line2..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final paintLine3 = Paint()..color = AppColors.line3..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final paintCapital = Paint()..color = const Color(0xFF9C27B0)..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;

    final all = MetroData.stations.values.toList();
    
    void drawRoute(int lineNum, Paint paint) {
      if (selectedLineFilter != 0 && selectedLineFilter != lineNum) return;
      
      final lineStations = all.where((s) => s.line == lineNum).toList();
      if (lineStations.isEmpty) return;

      // Group into continuous chunks by connectedTo relationship,
      // or simply connect sequentially based on _customPositions availability
      final path = Path();
      
      Offset? lastPos;
      
      // We will just draw lines between adjacent stations in the list for simplicity,
      // assuming MetroData.stations defines them roughly in order.
      for (var s in lineStations) {
        final pos = getStationPosition(s.id);
        if (pos == null) continue;
        
        if (lastPos == null) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
        lastPos = pos;
      }
      
      canvas.drawPath(path, paint);
    }

    // 1. Draw Lines
    drawRoute(1, paintLine1);
    drawRoute(2, paintLine2);
    drawRoute(3, paintLine3);

    // Capital Metro Monorail
    if (selectedLineFilter == 0 || selectedLineFilter == 4) {
      final path = Path();
      final start = _customPositions['adly_mansour'] ?? const Offset(cx + 380, cy - 200);
      path.moveTo(start.dx, start.dy);
      path.lineTo(start.dx + 40, start.dy - 10);
      path.lineTo(start.dx + 90, start.dy + 30);
      path.lineTo(start.dx + 160, start.dy + 80);
      path.lineTo(start.dx + 250, start.dy + 150); // New Capital
      canvas.drawPath(path, paintCapital);
      
      // Draw Capital endpoints
      final markPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final strokePaint = Paint()..color = const Color(0xFF9C27B0)..style = PaintingStyle.stroke..strokeWidth = 4;
      canvas.drawCircle(start, 7, markPaint);
      canvas.drawCircle(start, 7, strokePaint);
      final end = Offset(start.dx + 250, start.dy + 150);
      canvas.drawCircle(end, 7, markPaint);
      canvas.drawCircle(end, 7, strokePaint);
    }

    // 2. Draw Stations
    final stationFill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    for (var s in all) {
      if (selectedLineFilter != 0 && s.line != selectedLineFilter) continue;
      
      final pos = getStationPosition(s.id);
      if (pos == null) continue;

      final strokePaint = Paint()
        ..color = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.isTransfer ? 5 : 3;

      if (s.isTransfer) {
        canvas.drawCircle(pos, 10, stationFill);
        strokePaint.color = Colors.black87; // make transfers stand out
        canvas.drawCircle(pos, 10, strokePaint);
        // inner dot
        canvas.drawCircle(pos, 4, Paint()..color = Colors.black87);
      } else {
        canvas.drawCircle(pos, 7, stationFill);
        canvas.drawCircle(pos, 7, strokePaint);
      }

      // We only draw text if they are zoomed in enough, but CustomPainter
      // doesn't easily know zoom without passing it. Let's draw text for
      // transfers and terminal stations always for orientation.
      if (s.isTransfer || s.id == 'marg_new' || s.id == 'helwan' || s.id == 'shubra_el_kheima' || s.id == 'el_mounib' || s.id == 'adly_mansour' || s.id == 'kit_kat') {
        const textStyle = TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold);
        final textSpan = TextSpan(text: s.nameAr, style: textStyle);
        final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.rtl);
        textPainter.layout();
        
        // draw shadow container behind text for readability
        canvas.drawRRect(
           RRect.fromRectAndRadius(
             Rect.fromLTWH(pos.dx + 12, pos.dy - textPainter.height/2 - 2, textPainter.width + 8, textPainter.height + 4),
             const Radius.circular(4)
           ),
           Paint()..color = Colors.white.withValues(alpha: 0.8)
        );
        textPainter.paint(canvas, Offset(pos.dx + 16, pos.dy - textPainter.height/2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant MetroMapPainter oldDelegate) {
    return oldDelegate.selectedLineFilter != selectedLineFilter;
  }
}
