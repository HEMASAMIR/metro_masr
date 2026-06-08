import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../domain/entities/station.dart';
import 'map_page.dart';

class ARNavigationPage extends StatefulWidget {
  const ARNavigationPage({super.key});

  @override
  State<ARNavigationPage> createState() => _ARNavigationPageState();
}

class _ARNavigationPageState extends State<ARNavigationPage> with TickerProviderStateMixin {
  CameraController? _controller;
  double _heading = 0.0;
  bool _isLocating = true;
  Station? _nearestStation;
  double _distanceToStation = 0.0;
  double _bearingToStation = 0.0;
  bool _cameraPermissionDenied = false;

  // Sensors subscription
  StreamSubscription? _sensorsSubscription;
  StreamSubscription<Position>? _gpsSubscription;

  // Custom animation controllers for the radar glow
  late AnimationController _glowController;

  // Inside metro threshold: 2.0 km (2000m)
  static const double _insideMetroThreshold = 2000.0;

  // Terminals dictionary for lines
  static const Map<int, Map<String, String>> _lineTerminals = {
    1: {'start_ar': 'حلوان', 'start_en': 'Helwan', 'end_ar': 'المرج الجديدة', 'end_en': 'El Marg El Gedida'},
    2: {'start_ar': 'شبرا الخيمة', 'start_en': 'Shubra El-Kheima', 'end_ar': 'المنيب', 'end_en': 'El Mounib'},
    3: {'start_ar': 'عدلي منصور', 'start_en': 'Adly Mansour', 'end_ar': 'جامعة القاهرة', 'end_en': 'Cairo University'},
  };

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initSensors();
    _findNearestStation();
  }

  Future<void> _findNearestStation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLocating = false);
          return;
        }
      }

      // ── Get Initial Location ───────────────────────────────────────────────
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      _processLocationUpdate(position);

      // ── Subscribe to GPS updates ──────────────────────────────────────────
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 10,
        ),
      ).listen((Position pos) {
        _processLocationUpdate(pos);
      });

    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _processLocationUpdate(Position position) {
    Station? nearest;
    double minDist = double.infinity;

    for (var s in MetroData.stations.values) {
      double dist = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        s.latitude, s.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = s;
      }
    }

    double bearing = 0.0;
    if (nearest != null) {
      bearing = Geolocator.bearingBetween(
        position.latitude, position.longitude,
        nearest.latitude, nearest.longitude,
      );
    }

    if (mounted) {
      setState(() {
        _nearestStation = nearest;
        _distanceToStation = minDist;
        _bearingToStation = bearing;
        _isLocating = false;
      });

      // If user is inside metro, initialize camera feed if not already initialized
      if (_distanceToStation <= _insideMetroThreshold && _controller == null) {
        _initCamera();
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _cameraPermissionDenied = true;
          });
        }
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera init failed: $e");
    }
  }

  void _initSensors() {
    _sensorsSubscription = magnetometerEventStream().listen((MagnetometerEvent event) {
      // Basic heading calculation
      double heading = math.atan2(event.y, event.x) * (180 / math.pi);
      if (mounted) {
        setState(() {
          _heading = heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _sensorsSubscription?.cancel();
    _gpsSubscription?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  bool get _isOutsideMetro => _nearestStation != null && _distanceToStation > _insideMetroThreshold;

  Color _getLineColor() {
    if (_nearestStation == null) return AppColors.primary;
    switch (_nearestStation!.line) {
      case 1: return AppColors.line1;
      case 2: return AppColors.line2;
      case 3: return AppColors.line3;
      default: return AppColors.primary;
    }
  }

  String _getDirectionName(bool isAr) {
    final bearing = _bearingToStation;
    if (bearing >= -22.5 && bearing < 22.5) return isAr ? 'شمال ⬆️' : 'North ⬆️';
    if (bearing >= 22.5 && bearing < 67.5) return isAr ? 'شمال شرق ↗️' : 'NE ↗️';
    if (bearing >= 67.5 && bearing < 112.5) return isAr ? 'شرق ➡️' : 'East ➡️';
    if (bearing >= 112.5 && bearing < 157.5) return isAr ? 'جنوب شرق ↘️' : 'SE ↘️';
    if (bearing >= 157.5 || bearing < -157.5) return isAr ? 'جنوب ⬇️' : 'South ⬇️';
    if (bearing >= -157.5 && bearing < -112.5) return isAr ? 'جنوب غرب ↙️' : 'SW ↙️';
    if (bearing >= -112.5 && bearing < -67.5) return isAr ? 'غرب ⬅️' : 'West ⬅️';
    return isAr ? 'شمال غرب ↖️' : 'NW ↖️';
  }

  Map<String, String> _getPlatformDirections(bool isAr) {
    if (_nearestStation == null) return {};
    final line = _nearestStation!.line;
    final terminals = _lineTerminals[line];
    if (terminals == null) return {};

    final startName = isAr ? terminals['start_ar']! : terminals['start_en']!;
    final endName = isAr ? terminals['end_ar']! : terminals['end_en']!;

    return {
      'platform_a': isAr ? 'رصيف اتجاه $startName' : 'Platform to $startName',
      'platform_b': isAr ? 'رصيف اتجاه $endName' : 'Platform to $endName',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      body: Stack(
        children: [
          // ── Main UI branch based on GPS Location status ─────────────────────
          if (_isLocating)
            _buildLoadingView(isAr)
          else if (_isOutsideMetro)
            _buildOutsideMetroView(isAr)
          else
            _buildInsideMetroARView(isAr),

          // ── Top Navigation / Back button ───────────────────────────────────
          Positioned(
            top: 50,
            left: isAr ? null : 20,
            right: isAr ? 20 : null,
            child: FadeInLeft(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(
                    isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. LOADING VIEW ────────────────────────────────────────────────────────
  Widget _buildLoadingView(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15 + (_glowController.value * 25),
                        spreadRadius: 2 + (_glowController.value * 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            FadeInUp(
              child: Text(
                isAr ? 'جاري تحديد موقعك بدقة...' : 'Locating you with high precision...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. OUTSIDE METRO VIEW (FIXED OVERFLOW BY INTRODUCING SCROLLVIEW) ───────
  Widget _buildOutsideMetroView(bool isAr) {
    final distKm = (_distanceToStation / 1000).toStringAsFixed(1);
    final stationName = isAr ? _nearestStation!.nameAr : _nearestStation!.nameEn;
    final lineColor = _getLineColor();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF090D16), Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Holographic Radar/Compass Animation
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsing Glow
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.withValues(alpha: 0.03),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.15 * (1.0 - _glowController.value)),
                                width: 3,
                              ),
                            ),
                          );
                        },
                      ),
                      // Second Ring
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          double scale = (_glowController.value + 0.5) % 1.0;
                          return Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.deepOrangeAccent.withValues(alpha: 0.2 * (1.0 - scale)),
                                width: 2.0,
                              ),
                            ),
                          );
                        },
                      ),
                      // Hologram Compass Hub
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade700, Colors.deepOrange.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore_off_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Glassmorphic Alert Box
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'أنت خارج نطاق المترو يا فنان! 😎' : 'You are outside the metro, buddy! 😎',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr
                              ? 'عشان نقدر نحدد اتجاهك بالظبط ونعرفك تمشي في أنهي رصيف، لازم تكون واقف داخل محطة المترو أو قريب جداً منها.'
                              : 'To determine your exact direction and guide you to the correct platform, you must be inside or very close to a metro station.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70.withValues(alpha: 0.85),
                            fontSize: 14.5,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nearest Station Info Card
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: lineColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lineColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: lineColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'أقرب محطة ليك حالياً' : 'Nearest Station Right Now',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stationName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    isAr ? 'الخط ${nearestStationLine(isAr)}' : 'Line ${nearestStationLine(isAr)}',
                                    style: TextStyle(color: lineColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.straighten_rounded, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$distKm ${isAr ? "كم" : "km"}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Quick Actions Buttons
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MapPage()),
                            );
                          },
                          icon: const Icon(Icons.map_rounded, size: 20),
                          label: Text(isAr ? 'خريطة المترو' : 'Metro Map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _findNearestStation,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(isAr ? 'تحديث الموقع' : 'Refresh GPS'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String nearestStationLine(bool isAr) {
    if (_nearestStation == null) return '';
    return _nearestStation!.line.toString();
  }

  // ── 3. INSIDE METRO LIVE AR VIEW (WITH COMPASS & DIRECTIONS) ───────────────
  Widget _buildInsideMetroARView(bool isAr) {
    final stationName = isAr ? _nearestStation!.nameAr : _nearestStation!.nameEn;
    final lineColor = _getLineColor();
    final platformDirs = _getPlatformDirections(isAr);
    final distanceLabel = _distanceToStation < 1000
        ? '${_distanceToStation.round()} ${isAr ? "م" : "m"}'
        : '${(_distanceToStation / 1000).toStringAsFixed(1)} ${isAr ? "كم" : "km"}';

    return Stack(
      children: [
        // Camera Live Feed background
        if (_controller != null && _controller!.value.isInitialized)
          Positioned.fill(child: CameraPreview(_controller!))
        else if (_cameraPermissionDenied)
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: Text(
                  isAr ? 'يرجى إعطاء صلاحية الكاميرا لمشاهدة الواقع المعزز.' : 'Please allow camera permission to use AR view.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          )
        else
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),

        // Dark dim overlay for better UI readability
        Positioned.fill(
          child: Container(
            color: Colors.black26,
          ),
        ),

        // Holographic Arrow overlay in the center
        Center(
          child: FadeIn(
            duration: const Duration(seconds: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Compass Pointer
                Transform.rotate(
                  angle: (_bearingToStation - _heading) * math.pi / 180,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: lineColor.withValues(alpha: 0.5),
                          blurRadius: 35,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.navigation_rounded,
                      size: 110,
                      color: lineColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Glowing badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Text(
                    isAr
                        ? 'اتجاه المحطة: ${_getDirectionName(isAr)}'
                        : 'Station Direction: ${_getDirectionName(isAr)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Dashboard Card (Platform Guidance)
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: FadeInUp(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: lineColor.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: lineColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active Station Header
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: lineColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr ? 'محطة $stationName' : '$stationName Station',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lineColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr ? 'مسافة: $distanceLabel' : 'Dist: $distanceLabel',
                          style: TextStyle(
                            color: lineColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),

                  // Platform Guidance info
                  if (platformDirs.isNotEmpty) ...[
                    Text(
                      isAr ? '🧭 الدليل الصحيح لاتجاه الرصيف:' : '🧭 Correct Platform Guide:',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _platformInfoBadge(
                            label: isAr ? 'رصيف ١' : 'Platform 1',
                            direction: platformDirs['platform_a'] ?? '',
                            color: lineColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _platformInfoBadge(
                            label: isAr ? 'رصيف ٢' : 'Platform 2',
                            direction: platformDirs['platform_b'] ?? '',
                            color: lineColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _platformInfoBadge({required String label, required String direction, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            direction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}