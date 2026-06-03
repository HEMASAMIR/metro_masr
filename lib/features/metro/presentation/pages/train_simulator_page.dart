import 'dart:async';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import 'package:geolocator/geolocator.dart';

class TrainSimulatorPage extends StatefulWidget {
  const TrainSimulatorPage({super.key});

  @override
  State<TrainSimulatorPage> createState() => _TrainSimulatorPageState();
}

class _TrainSimulatorPageState extends State<TrainSimulatorPage> with TickerProviderStateMixin {
  int _selectedLine = 1; // 1, 2, 3
  
  // Simulation variables
  double _speed = 0.0;
  String _status = "status_boarding"; // boarding, departing, cruising, braking
  int _countdownSeconds = 15;
  int _currentStationIndex = 0;
  double _trainPositionPercent = 0.0; // 0.0 to 1.0 between stations
  
  bool _liveRideMode = true;
  StreamSubscription<Position>? _gpsSubscription;
  String _liveGpsStatus = "";
  
  // 3D Camera Angles
  double _yaw = -0.6;   // Camera rotation around Y axis
  double _pitch = 0.25; // Camera rotation around X axis
  bool _show3dView = false; // Toggle between Track and 3D View

  Timer? _simulationTimer;
  late AnimationController _announcementController;
  late AnimationController _gridAnimationController;

  // Station definitions for the 3 main metro lines
  final Map<int, List<Map<String, String>>> _lineStations = {
    1: [
      {"nameEn": "Helwan", "nameAr": "حلوان"},
      {"nameEn": "Maadi", "nameAr": "المعادي"},
      {"nameEn": "Sayeda Zeinab", "nameAr": "السيدة زينب"},
      {"nameEn": "Sadat", "nameAr": "السادات"},
      {"nameEn": "Ramses (Shohadaa)", "nameAr": "الشهداء"},
      {"nameEn": "Heliopolis", "nameAr": "مصر الجديدة"},
      {"nameEn": "El-Marg", "nameAr": "المرج"}
    ],
    2: [
      {"nameEn": "El-Mounib", "nameAr": "المنيب"},
      {"nameEn": "Giza", "nameAr": "الجيزة"},
      {"nameEn": "Dokki", "nameAr": "الدقي"},
      {"nameEn": "Sadat", "nameAr": "السادات"},
      {"nameEn": "Attaba", "nameAr": "العتبة"},
      {"nameEn": "Ramses (Shohadaa)", "nameAr": "الشهداء"},
      {"nameEn": "Shubra El-Kheima", "nameAr": "شبرا الخيمة"}
    ],
    3: [
      {"nameEn": "Imbaba", "nameAr": "إمبابة"},
      {"nameEn": "Kit Kat", "nameAr": "الكيت كات"},
      {"nameEn": "Nasser", "nameAr": "ناصر"},
      {"nameEn": "Attaba", "nameAr": "العتبة"},
      {"nameEn": "Abbassia", "nameAr": "العباسية"},
      {"nameEn": "Heliopolis", "nameAr": "مصر الجديدة"},
      {"nameEn": "Adly Mansour", "nameAr": "عدلي منصور"}
    ]
  };

  List<Map<String, String>> get _currentStations => _lineStations[_selectedLine] ?? [];

  @override
  void initState() {
    super.initState();
    _announcementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Start with live GPS mode to avoid confusing users at home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toggleLiveRideMode(true);
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _gpsSubscription?.cancel();
    _announcementController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  void _toggleLiveRideMode(bool value) async {
    setState(() {
      _liveRideMode = value;
    });

    if (_liveRideMode) {
      _simulationTimer?.cancel();
      
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() {
            _liveRideMode = false;
            _liveGpsStatus = "Permission Denied";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.locale.languageCode == 'ar' ? "برجاء تفعيل إذن الموقع" : "Please enable location permission"))
          );
          _startSimulation();
          return;
        }

        // Start listening to geolocator position stream
        _gpsSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (!mounted || !_liveRideMode) return;
          _updateLiveLocation(position);
        }, onError: (e) {
          _handleGpsLost();
        });
        
        final initialPos = await Geolocator.getCurrentPosition();
        _updateLiveLocation(initialPos);

      } catch (e) {
        _handleGpsLost();
      }
    } else {
      _gpsSubscription?.cancel();
      _gpsSubscription = null;
      _startSimulation();
    }
  }

  void _updateLiveLocation(Position position) {
    int bestLine = _selectedLine;
    int nearestIndex = 0;
    double minDistance = double.infinity;
    
    for (int line in _lineStations.keys) {
      final stationsList = _lineStations[line]!;
      for (int i = 0; i < stationsList.length; i++) {
        final sName = stationsList[i]["nameEn"];
        final stationEntity = MetroData.stations.values.firstWhere(
          (st) => st.nameEn.toLowerCase() == sName?.toLowerCase(),
          orElse: () => MetroData.stations.values.first,
        );
        
        final dist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          stationEntity.latitude,
          stationEntity.longitude,
        );
        
        if (dist < minDistance) {
          minDistance = dist;
          nearestIndex = i;
          bestLine = line;
        }
      }
    }
    
    setState(() {
      if (_selectedLine != bestLine) {
        _selectedLine = bestLine;
      }
      _currentStationIndex = nearestIndex;
      _speed = position.speed * 3.6; // Convert m/s to km/h
      
      final now = DateTime.now();
      final isClosed = now.hour >= 1 && now.hour < 5;
      
      if (isClosed) {
        _status = "status_boarding";
        _trainPositionPercent = 0.0;
        _countdownSeconds = 0;
        _speed = 0.0;
        _liveGpsStatus = context.locale.languageCode == 'ar' 
            ? "🌙 المترو مغلق الآن (العمل 5:15 ص - 1:00 ص)" 
            : "🌙 Metro closed (5:15 AM - 1:00 AM)";
      } else if (minDistance > 2000) {
        _status = "status_boarding";
        _trainPositionPercent = 0.0;
        _countdownSeconds = 0;
        _speed = 0.0; // Force speed to 0 when far
        _liveGpsStatus = context.locale.languageCode == 'ar' ? "🏠 أنت خارج نطاق المترو" : "🏠 Out of metro range";
      } else if (minDistance < 300) {
        _status = "status_boarding";
        _trainPositionPercent = 0.0;
        _countdownSeconds = 20;
        _liveGpsStatus = context.locale.languageCode == 'ar' ? "📍 متوقف في المحطة" : "📍 Stopped at station";
      } else {
        _status = "status_cruising";
        _trainPositionPercent = 0.5; // halfway to next
        _countdownSeconds = 120; // 2 minutes estimated
        _liveGpsStatus = context.locale.languageCode == 'ar' ? "🚇 جاري التحرك بين المحطات" : "🚇 Moving between stations";
      }
    });
  }

  void _handleGpsLost() {
    if (!mounted) return;
    setState(() {
      _liveGpsStatus = context.locale.languageCode == 'ar' ? "📡 نفق تحت الأرض (حساب زمني)" : "📡 Underground (Estimated)";
      _status = "status_cruising";
      _speed = 65.0; // standard metro speed underground
    });
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    if (_liveRideMode) return;
    
    final now = DateTime.now();
    final isClosed = now.hour >= 1 && now.hour < 5;
    if (isClosed) {
      setState(() {
        _currentStationIndex = 0;
        _trainPositionPercent = 0.0;
        _speed = 0.0;
        _status = "status_boarding";
        _countdownSeconds = 0;
        _liveGpsStatus = context.locale.languageCode == 'ar' 
            ? "🌙 المترو مغلق الآن (العمل 5:15 ص - 1:00 ص)" 
            : "🌙 Metro closed (5:15 AM - 1:00 AM)";
      });
      return;
    }

    _currentStationIndex = 0;
    _trainPositionPercent = 0.0;
    _speed = 0.0;
    _status = "status_boarding";
    _countdownSeconds = 12;
    _liveGpsStatus = "";

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        final stationsCount = _currentStations.length;
        if (_currentStationIndex >= stationsCount - 1) {
          // Terminal reached, loop back
          _currentStationIndex = 0;
          _trainPositionPercent = 0.0;
          _status = "status_boarding";
          _countdownSeconds = 12;
          _speed = 0.0;
          return;
        }

        if (_status == "status_boarding") {
          _countdownSeconds--;
          _speed = 0.0;
          if (_countdownSeconds <= 0) {
            _status = "status_departing";
            _countdownSeconds = 5;
            HapticFeedback.mediumImpact();
            _announcementController.forward(from: 0.0);
          }
        } else if (_status == "status_departing") {
          _countdownSeconds--;
          // Accelerating
          _speed = (_speed + 25.0).clamp(0.0, 80.0);
          if (_countdownSeconds <= 0) {
            _status = "status_cruising";
            _countdownSeconds = 15;
          }
        } else if (_status == "status_cruising") {
          _countdownSeconds--;
          // Fluctuate speed slightly around 80 km/h
          _speed = 78.0 + (3.0 * (timer.tick % 3 - 1));
          _trainPositionPercent = (_trainPositionPercent + 0.05).clamp(0.0, 1.0);

          if (_countdownSeconds <= 0) {
            _status = "status_braking";
            _countdownSeconds = 8;
          }
        } else if (_status == "status_braking") {
          _countdownSeconds--;
          // Decelerating to stop
          _speed = (_speed - 12.0).clamp(0.0, 80.0);
          _trainPositionPercent = (_trainPositionPercent + 0.03).clamp(0.0, 1.0);

          if (_countdownSeconds <= 0) {
            _currentStationIndex++;
            _trainPositionPercent = 0.0;
            _status = "status_boarding";
            _countdownSeconds = 12;
            _speed = 0.0;
            HapticFeedback.lightImpact();
          }
        }
      });
    });
  }

  Color _getLineColor() {
    switch (_selectedLine) {
      case 1:
        return AppColors.line1;
      case 2:
        return AppColors.line2;
      case 3:
        return AppColors.line3;
      default:
        return AppColors.primary;
    }
  }

  String _getAnnouncement() {
    final isAr = context.locale.languageCode == 'ar';
    if (_status == "status_boarding") {
      final s = _currentStations[_currentStationIndex];
      final name = isAr ? s["nameAr"] : s["nameEn"];
      return isAr 
          ? "الآن في محطة $name. صعود ونزول الركاب." 
          : "Now boarding at $name station.";
    } else {
      final s = _currentStations[(_currentStationIndex + 1).clamp(0, _currentStations.length - 1)];
      final name = isAr ? s["nameAr"] : s["nameEn"];
      return isAr 
          ? "المحطة القادمة هي $name. برجاء الانتباه للأبواب." 
          : "Next station is $name. Please stay clear of the doors.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final lineColor = _getLineColor();
    final currentAnnouncement = _getAnnouncement();

    return Scaffold(
      appBar: AppBar(
        title: Text("train_simulator".tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _startSimulation,
            tooltip: "Restart Simulation",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── LINE SELECTOR TABS ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3].map((lineNum) {
                  final isSelected = _selectedLine == lineNum;
                  final c = lineNum == 1 ? AppColors.line1 : lineNum == 2 ? AppColors.line2 : AppColors.line3;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLine = lineNum;
                      });
                      _startSimulation();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? c : c.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? c : c.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isAr ? "الخط $lineNum" : "Line $lineNum",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : c,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── LIVE RIDE MODE SWITCH ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _liveRideMode ? lineColor.withOpacity(0.08) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _liveRideMode ? lineColor.withOpacity(0.4) : Colors.grey.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _liveRideMode ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                    color: _liveRideMode ? lineColor : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? "وضع الركوب الفعلي (ذكي)" : "Live Ride Mode (GPS + Smart)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _liveRideMode 
                              ? (_liveGpsStatus.isNotEmpty ? _liveGpsStatus : (isAr ? "جاري تعقب رحلتك الحالية..." : "Tracking your active ride..."))
                              : (isAr ? "تتبع تلقائي للرحلة أثناء ركوبك المترو" : "Auto-track your ride while inside the metro"),
                          style: TextStyle(
                            color: _liveRideMode ? lineColor : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: _liveRideMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _liveRideMode,
                    activeColor: lineColor,
                    onChanged: _toggleLiveRideMode,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── MAIN TELEMETRY DASHBOARD ──
                  FadeInDown(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "speed".tr().toUpperCase(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${_speed.round()} km/h",
                                    style: TextStyle(
                                      color: lineColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: lineColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _status.tr(),
                                  style: TextStyle(
                                    color: lineColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "next_station".tr().toUpperCase(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr 
                                        ? (_currentStations[(_currentStationIndex + 1).clamp(0, _currentStations.length - 1)]["nameAr"] ?? "")
                                        : (_currentStations[(_currentStationIndex + 1).clamp(0, _currentStations.length - 1)]["nameEn"] ?? ""),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "estimated_arrival".tr().toUpperCase(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "0${_countdownSeconds ~/ 60}:${_countdownSeconds % 60 < 10 ? '0' : ''}${_countdownSeconds % 60}",
                                    style: TextStyle(
                                      color: lineColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ANNOUNCEMENT SPEECH BUBBLE ──
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: _announcementController, curve: Curves.easeOut)),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lineColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: lineColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.volume_up_rounded, color: lineColor, size: 26),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                currentAnnouncement,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── VIEW TOGGLER (TRACK VS 3D VIEW) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildViewToggleButton(
                        label: isAr ? "تتبع المسار" : "Track View",
                        icon: Icons.alt_route_rounded,
                        isActive: !_show3dView,
                        onTap: () => setState(() => _show3dView = false),
                      ),
                      const SizedBox(width: 12),
                      _buildViewToggleButton(
                        label: isAr ? "عرض ثلاثي الأبعاد" : "3D Cabin View",
                        icon: Icons.threed_rotation_rounded,
                        isActive: _show3dView,
                        onTap: () => setState(() => _show3dView = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── TABS RENDERING (LIVE TRACK / INTERACTIVE 3D MODEL) ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _show3dView 
                        ? _buildInteractive3DModel(lineColor)
                        : _buildLiveTrack(isAr, lineColor),
                  ),
                  const SizedBox(height: 24),

                  // ── REMAINING STATIONS LIST ──
                  FadeInUp(
                    delay: const Duration(milliseconds: 350),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? "جدول المحطات المتبقية" : "Remaining Stations Schedule",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 14),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _currentStations.length - _currentStationIndex,
                            itemBuilder: (ctx, i) {
                              final idx = _currentStationIndex + i;
                              final station = _currentStations[idx];
                              final isTerminus = idx == _currentStations.length - 1;
                              final name = isAr ? station["nameAr"] : station["nameEn"];
                              final arrivalMinutes = i * 3; // Mocking 3 mins per station

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: i == 0 ? lineColor : Colors.grey.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        name ?? "",
                                        style: TextStyle(
                                          fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      i == 0 
                                          ? "now".tr()
                                          : (isTerminus ? "+$arrivalMinutes min (Terminus)" : "+$arrivalMinutes min"),
                                      style: TextStyle(
                                        color: i == 0 ? lineColor : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = _getLineColor();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrack(bool isAr, Color lineColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final trackWidth = max(screenWidth - 72, 500.0);

    return FadeInUp(
      key: const ValueKey("live_track"),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: trackWidth,
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Railway Line Track
                Positioned(
                  left: 20, right: 20,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Completed route overlay
                Positioned(
                  left: 20,
                  width: (trackWidth - 40) * 
                      ((_currentStationIndex + _trainPositionPercent) / (_currentStations.length - 1)),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Glowing Station Dots Along Track
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_currentStations.length, (idx) {
                    final isPassed = idx <= _currentStationIndex;
                    final isCurrent = idx == _currentStationIndex && _trainPositionPercent == 0.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: isCurrent ? 18 : 12,
                          height: isCurrent ? 18 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed ? lineColor : Theme.of(context).scaffoldBackgroundColor,
                            border: Border.all(
                              color: isPassed ? lineColor : Colors.grey.withOpacity(0.4),
                              width: 2.5,
                            ),
                            boxShadow: isPassed
                                ? [BoxShadow(color: lineColor.withOpacity(0.4), blurRadius: 6)]
                                : [],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            isAr ? (_currentStations[idx]["nameAr"] ?? "") : (_currentStations[idx]["nameEn"] ?? ""),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? lineColor : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    );
                  }),
                ),
                // Train Car Icon sliding on track
                Positioned(
                  left: 20 + (trackWidth - 40) * 
                      ((_currentStationIndex + _trainPositionPercent) / (_currentStations.length - 1)) - 14,
                  top: 40,
                  child: Pulse(
                    infinite: _speed > 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: lineColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: lineColor.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: const Icon(
                        Icons.directions_subway_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 2. INTERACTIVE 3D MODEL VIEW ──
  Widget _buildInteractive3DModel(Color lineColor) {
    return FadeInUp(
      key: const ValueKey("3d_model"),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _yaw += details.delta.dx * 0.012;
            _pitch = (_pitch + details.delta.dy * 0.012).clamp(-0.4, 0.8);
          });
        },
        child: Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF070B19), // Futuristic dark space
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: lineColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: lineColor.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              // Real-time 3D CustomPaint
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _gridAnimationController,
                  builder: (context, child) => CustomPaint(
                    painter: _Train3DPainter(
                      yaw: _yaw,
                      pitch: _pitch,
                      speed: _speed,
                      lineColor: lineColor,
                      animTime: _gridAnimationController.value * 10.0,
                    ),
                  ),
                ),
              ),
              // Drag Indicator overlay
              Positioned(
                bottom: 12, left: 16, right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swipe_outlined, color: Colors.white60, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Swipe to spin 360°".tr(),
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    if (_speed > 0)
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text("3D Grid Active", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      )
                  ],
                ),
              ),
              // Glowing cabin headlights indicator
              Positioned(
                top: 14, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _speed > 0 ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: _speed > 0 ? Colors.amber : Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _speed > 0 ? "Headlights ON" : "Headlights OFF",
                        style: TextStyle(color: _speed > 0 ? Colors.amber : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3D VECTOR GRAPHICS ENGINE (CUSTOM PAINTER) ──
class _Point3D {
  final double x, y, z;
  _Point3D(this.x, this.y, this.z);
}

class _Train3DPainter extends CustomPainter {
  final double yaw;
  final double pitch;
  final double speed;
  final Color lineColor;
  final double animTime;

  _Train3DPainter({
    required this.yaw,
    required this.pitch,
    required this.speed,
    required this.lineColor,
    required this.animTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 10;
    const double dist = 160.0; // Camera distance
    const double fov = 280.0;  // Perspective focal length

    final cosY = cos(yaw);
    final sinY = sin(yaw);
    final cosX = cos(pitch);
    final sinX = sin(pitch);

    // 3D Point projection math
    Offset project(_Point3D p) {
      // Rotation around Y-axis (Yaw)
      double rx = p.x * cosY - p.z * sinY;
      double rz = p.x * sinY + p.z * cosY;

      // Rotation around X-axis (Pitch)
      double ry = p.y * cosX - rz * sinX;
      double rz2 = p.y * sinX + rz * cosX;

      // Translate along camera Z
      double finalZ = rz2 + dist;

      // Perspective divide
      double sx = centerX + (rx * fov) / finalZ;
      double sy = centerY + (ry * fov) / finalZ;
      return Offset(sx, sy);
    }

    // 1. Draw glowing background grid
    final gridPaint = Paint()
      ..color = lineColor.withOpacity(0.08)
      ..strokeWidth = 1.0;

    // Draw 3D parallel rail track lines
    final railLeftStart = project(_Point3D(-38, 30, -200));
    final railLeftEnd = project(_Point3D(-38, 30, 200));
    canvas.drawLine(railLeftStart, railLeftEnd, Paint()..color = lineColor.withOpacity(0.3)..strokeWidth = 2.0);
    
    final railRightStart = project(_Point3D(38, 30, -200));
    final railRightEnd = project(_Point3D(38, 30, 200));
    canvas.drawLine(railRightStart, railRightEnd, Paint()..color = lineColor.withOpacity(0.3)..strokeWidth = 2.0);

    // Draw moving cross sleepers
    const double zSpacing = 40.0;
    final double offset = -(animTime * (speed + 20) * 0.15) % zSpacing;
    for (double z = -200; z <= 200; z += zSpacing) {
      final currentZ = z + offset;
      final leftPt = project(_Point3D(-42, 30, currentZ));
      final rightPt = project(_Point3D(42, 30, currentZ));
      canvas.drawLine(leftPt, rightPt, gridPaint);
    }

    // 2. Define train coordinates (aerodynamic cabin model)
    const double w = 24.0; // width
    const double h = 20.0; // height
    const double l = 60.0; // length

    final allPoints = [
      _Point3D(-w, -h, -l), // 0: Back-Top-Left
      _Point3D(w, -h, -l),  // 1: Back-Top-Right
      _Point3D(w, h, -l),   // 2: Back-Bottom-Right
      _Point3D(-w, h, -l),  // 3: Back-Bottom-Left
      _Point3D(-w, -h, l),  // 4: Front-Top-Left
      _Point3D(w, -h, l),   // 5: Front-Top-Right
      _Point3D(w, h, l),    // 6: Front-Bottom-Right
      _Point3D(-w, h, l),   // 7: Front-Bottom-Left

      // Front nose points (shorter, slanted engine)
      _Point3D(-16, -10, l + 14), // 8: Nose-Top-Left
      _Point3D(16, -10, l + 14),  // 9: Nose-Top-Right
      _Point3D(16, h, l + 14),    // 10: Nose-Bottom-Right
      _Point3D(-16, h, l + 14),   // 11: Nose-Bottom-Left
    ];

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    // Helper to draw projected quad face
    void drawQuad(int a, int b, int c, int d) {
      final p1 = project(allPoints[a]);
      final p2 = project(allPoints[b]);
      final p3 = project(allPoints[c]);
      final p4 = project(allPoints[d]);
      
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, paint);
    }

    // Draw main cabin sides and faces
    drawQuad(0, 1, 2, 3); // Back end
    drawQuad(0, 3, 7, 4); // Left side
    drawQuad(1, 2, 6, 5); // Right side
    drawQuad(0, 1, 5, 4); // Roof
    drawQuad(2, 3, 7, 6); // Floor

    // Draw slanted cockpit (front nose)
    drawQuad(8, 9, 10, 11); // Front nose windshield tip
    drawQuad(4, 5, 9, 8);   // Slanted top glass
    drawQuad(6, 7, 11, 10); // Slanted bottom nose
    drawQuad(4, 7, 11, 8);  // Slanted left glass transition
    drawQuad(5, 6, 10, 9);  // Slanted right glass transition

    // Draw cabin windows (side window lines)
    final windowPaint = Paint()
      ..color = lineColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left side windows (side coordinates)
    for (double i = -0.7; i < 0.7; i += 0.4) {
      final wZStart = l * i;
      final wZEnd = l * (i + 0.2);
      final p1 = project(_Point3D(-w, -h + 4, wZStart));
      final p2 = project(_Point3D(-w, -h + 4, wZEnd));
      final p3 = project(_Point3D(-w, 2, wZEnd));
      final p4 = project(_Point3D(-w, 2, wZStart));
      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy)..close(), windowPaint);
    }

    // Right side windows
    for (double i = -0.7; i < 0.7; i += 0.4) {
      final wZStart = l * i;
      final wZEnd = l * (i + 0.2);
      final p1 = project(_Point3D(w, -h + 4, wZStart));
      final p2 = project(_Point3D(w, -h + 4, wZEnd));
      final p3 = project(_Point3D(w, 2, wZEnd));
      final p4 = project(_Point3D(w, 2, wZStart));
      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy)..close(), windowPaint);
    }

    // 3. Draw cabin wheels under train floor (drawn as projected 3D disks)
    final wheelPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final wheelLeftFront = project(_Point3D(-w + 4, h + 5, l - 15));
    final wheelRightFront = project(_Point3D(w - 4, h + 5, l - 15));
    final wheelLeftBack = project(_Point3D(-w + 4, h + 5, -l + 15));
    final wheelRightBack = project(_Point3D(w - 4, h + 5, -l + 15));

    canvas.drawCircle(wheelLeftFront, 5.0, wheelPaint);
    canvas.drawCircle(wheelRightFront, 5.0, wheelPaint);
    canvas.drawCircle(wheelLeftBack, 5.0, wheelPaint);
    canvas.drawCircle(wheelRightBack, 5.0, wheelPaint);

    // 4. Draw glowing headlights & light cones if speed is > 0 (Accelerating/Cruising)
    if (speed > 0) {
      final pLeft = project(allPoints[10]);
      final pRight = project(allPoints[11]);
      
      // Far light endpoints projected forward in 3D
      final lightLeftEnd = project(_Point3D(16, h + 4, l + 55));
      final lightRightEnd = project(_Point3D(-16, h + 4, l + 55));

      final headlightPaint = Paint()
        ..color = Colors.amber.withOpacity(0.12)
        ..style = PaintingStyle.fill;

      // Draw light beams
      final leftBeam = Path()
        ..moveTo(pLeft.dx, pLeft.dy)
        ..lineTo(lightLeftEnd.dx, lightLeftEnd.dy)
        ..lineTo(lightLeftEnd.dx - 20, lightLeftEnd.dy + 15)
        ..close();

      final rightBeam = Path()
        ..moveTo(pRight.dx, pRight.dy)
        ..lineTo(lightRightEnd.dx, lightRightEnd.dy)
        ..lineTo(lightRightEnd.dx + 20, lightRightEnd.dy + 15)
        ..close();

      canvas.drawPath(leftBeam, headlightPaint);
      canvas.drawPath(rightBeam, headlightPaint);

      // Glowing headlights yellow bulbs
      final bulbPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pLeft, 3.5, bulbPaint);
      canvas.drawCircle(pRight, 3.5, bulbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Train3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.speed != speed ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.animTime != animTime;
  }
}
