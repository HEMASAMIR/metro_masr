import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../metro/domain/entities/station.dart';

class AiStationAnnouncerPage extends StatefulWidget {
  const AiStationAnnouncerPage({super.key});

  @override
  State<AiStationAnnouncerPage> createState() => _AiStationAnnouncerPageState();
}

class _AiStationAnnouncerPageState extends State<AiStationAnnouncerPage>
    with SingleTickerProviderStateMixin {
  late FlutterTts _flutterTts;
  Station? _selectedStation;
  String _announcementType = 'next';
  String _languageCode = 'ar';
  double _pitch = 0.95;
  double _rate = 0.45;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;

  String _announcementText = '';
  final TextEditingController _customTextController = TextEditingController();

  final List<Station> _allStations = [];
  
  // GPS Auto mode state
  bool _isAutoMode = false;
  StreamSubscription<Position>? _positionSubscription;
  double? _nearestStationDistance;
  String? _lastAnnouncedStationId;
  
  // Wave animation
  late AnimationController _waveController;
  final List<double> _waveHeights = List.filled(8, 10.0);
  Timer? _waveTimer;

  // Tab & Simulation state
  int _activeTab = 0; // 0: Auto/GPS, 1: Manual
  bool _isSimulating = false;
  Timer? _simulationTimer;
  int _simulationIndex = 0;
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _allStations.addAll(MetroData.stations.values);
    _initTts();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(() {
      setState(() {
        _isPlaying = true;
      });
      _startWaveAnimation();
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
      });
      _stopWaveAnimation();
    });
    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isPlaying = false;
        _errorMessage = "خطأ في تشغيل الصوت الصوتي";
      });
      _stopWaveAnimation();
    });
  }

  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 10 + (25 * (i % 2 == 0 ? 0.3 : 0.8) * (1 + (timer.tick % 4 == 0 ? 0.2 : 0.5)));
        }
      });
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    setState(() {
      _waveHeights.fillRange(0, _waveHeights.length, 10.0);
    });
  }

  Future<void> _generateText(bool isAr) async {
    if (_selectedStation == null && (_announcementType == 'next' || _announcementType == 'transfer')) {
      setState(() {
        _errorMessage = isAr ? "اختار المحطة الأول يا كبير! 🚇" : "Select station first! 🚇";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_announcementType == 'custom') {
        final rawText = _customTextController.text.trim();
        if (rawText.isEmpty) {
          throw Exception(isAr ? "اكتب رسالة الإعلان المخصصة أولاً!" : "Type the custom announcement text!");
        }

        if (ConnectivityService.instance.isOffline) {
          setState(() {
            _isLoading = false;
            _announcementText = isAr 
                ? "انتباه من رفيق: $rawText. نتمنى لكم رحلة سعيدة." 
                : "Attention passengers: $rawText. Wish you a happy journey.";
          });
          return;
        }

        final model = GeminiAiService.getModel();
        final prompt = 
            "You are 'Rafiq' Cairo Metro AI Voice Announcer. Rewrite this raw custom text into a formal, highly authentic Cairo Metro train platform announcement style. Include sound cues like 'Attention passengers' or 'تنبيه من مترو القاهرة'.\n"
            "Raw Text: $rawText\n"
            "Return ONLY a raw JSON response. Do not use markdown enclosures. The JSON structure MUST be exactly:\n"
            "{\n"
            "  \"announcementAr\": \"الصيغة الرسمية بالعربية الكلاسيكية ونبرة المترو\",\n"
            "  \"announcementEn\": \"Official spoken format in English\"\n"
            "}";

        final response = await model.generateContent([Content.text(prompt)]);
        final cleanText = response.text?.trim() ?? '';
        
        String cleanJson = cleanText;
        if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
        }

        final Map<String, dynamic> data = json.decode(cleanJson);
        setState(() {
          _isLoading = false;
          _announcementText = (_languageCode == 'ar' ? data['announcementAr'] : data['announcementEn']) ?? '';
        });
      } else {
        String generated = '';
        final stationName = _languageCode == 'ar' ? _selectedStation!.nameAr : _selectedStation!.nameEn;

        if (_announcementType == 'next') {
          generated = _languageCode == 'ar' 
              ? "المحطة القادمة هي، $stationName. الرجاء الانتباه للفراغ بين القطار والرصيف."
              : "The next station is, $stationName. Please mind the gap between the train and the platform.";
        } else if (_announcementType == 'transfer') {
          generated = _languageCode == 'ar' 
              ? "المحطة القادمة هي، $stationName. محطة تبادلية للخطوط الأخرى. الرجاء الاستعداد لمغادرة القطار."
              : "The next station is, $stationName. This is a transfer station for other metro lines. Please prepare to exit the train.";
        } else if (_announcementType == 'safety') {
          generated = _languageCode == 'ar' 
              ? "تنبيه من رفيق مترو القاهرة: يرجى الوقوف خلف خط الأمان الأصفر على الرصيف وعدم الاقتراب من القطار أثناء دخوله."
              : "Attention Cairo Metro passengers: Please stand behind the yellow safety line on the platform and stay clear of the tracks.";
        }

        setState(() {
          _isLoading = false;
          _announcementText = generated;
        });
      }
    } catch (e) {
      debugPrint("❌ Station Announcer Error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains("Exception") 
            ? e.toString().replaceAll("Exception:", "")
            : (isAr ? "حصل خطأ في صياغة الإعلان." : "An error occurred generating script.");
      });
    }
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
      _stopWaveAnimation();
      return;
    }

    if (_announcementText.isEmpty) {
      await _generateText(context.locale.languageCode == 'ar');
    }

    if (_announcementText.isNotEmpty) {
      await _flutterTts.setLanguage(_languageCode == 'ar' ? 'ar-EG' : 'en-US');
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_rate);
      await _flutterTts.speak(_announcementText);
    }
  }

  // --- GPS Auto Announcer Core Logic ---

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = context.locale.languageCode == 'ar' 
            ? "خدمات الموقع الجغرافي (GPS) مغلقة. يرجى تفعيلها."
            : "Location services are disabled. Please enable them.";
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = context.locale.languageCode == 'ar'
              ? "تم رفض صلاحية الوصول للموقع الجغرافي."
              : "Location permissions are denied.";
        });
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = context.locale.languageCode == 'ar'
            ? "صلاحية الموقع مرفوضة دائماً. يرجى تفعيلها من إعدادات الهاتف."
            : "Location permissions are permanently denied. Please enable them in settings.";
      });
      return false;
    }

    return true;
  }

  Future<void> _toggleAutoMode(bool value) async {
    if (value) {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return;
      
      setState(() {
        _isAutoMode = true;
        _isSimulating = false;
        _errorMessage = null;
      });
      _simulationTimer?.cancel();

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _handlePositionUpdate(position);
      } catch (e) {
        debugPrint("Error getting initial position: $e");
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _handlePositionUpdate(position);
      }, onError: (err) {
        setState(() {
          _errorMessage = "خطأ في تتبع الموقع: $err";
          _isAutoMode = false;
        });
        _positionSubscription?.cancel();
      });
    } else {
      _positionSubscription?.cancel();
      setState(() {
        _isAutoMode = false;
        _nearestStationDistance = null;
      });
    }
  }

  void _handlePositionUpdate(Position position) {
    if (!mounted) return;

    List<Station> candidates = [];
    if (_selectedStation != null) {
      candidates = _allStations.where((s) => s.line == _selectedStation!.line).toList();
    }
    if (candidates.isEmpty) {
      candidates = _allStations;
    }

    double minDistance = double.infinity;
    Station? nearest;

    for (var station in candidates) {
      double dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        station.latitude,
        station.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = station;
      }
    }

    if (nearest != null) {
      final nearestStation = nearest; // non-null local
      setState(() {
        _nearestStationDistance = minDistance;
      });

      // Arrival threshold: 300 meters
      if (minDistance < 300) {
        if (_lastAnnouncedStationId != nearestStation.id) {
          _lastAnnouncedStationId = nearestStation.id;
          
          setState(() {
            _selectedStation = nearestStation;
            _announcementType = nearestStation.isTransfer ? 'transfer' : 'next';
          });

          // Auto scroll to timeline node
          final lineStations = MetroData.stations.values.where((s) => s.line == nearestStation.line).toList();
          final idx = lineStations.indexWhere((s) => s.id == nearestStation.id);
          if (idx != -1) {
            _scrollToStationIndex(idx);
          }

          _triggerAutoAnnouncement(nearestStation);
        }
      }
    }
  }

  // --- Simulation Mode Logic ---

  void _toggleSimulationMode() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() {
        _isSimulating = false;
        _nearestStationDistance = null;
      });
    } else {
      if (_selectedStation == null) {
        setState(() {
          _selectedStation = _allStations.firstWhere(
            (s) => s.id == 'l1_helwan',
            orElse: () => _allStations.first,
          );
        });
      }
      
      final lineStations = MetroData.stations.values.where((s) => s.line == _selectedStation!.line).toList();
      int startIndex = lineStations.indexWhere((s) => s.id == _selectedStation!.id);
      if (startIndex == -1) startIndex = 0;

      setState(() {
        _isSimulating = true;
        _isAutoMode = false;
        _errorMessage = null;
        _simulationIndex = startIndex;
        _nearestStationDistance = 15.0; // Simulated inside station
      });
      _positionSubscription?.cancel();

      // Announce the first station immediately
      final currentStation = lineStations[_simulationIndex];
      _scrollToStationIndex(_simulationIndex);
      _triggerAutoAnnouncement(currentStation);

      _simulationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
        if (!mounted || !_isSimulating) {
          timer.cancel();
          return;
        }

        _simulationIndex++;
        if (_simulationIndex >= lineStations.length) {
          setState(() {
            _isSimulating = false;
            _nearestStationDistance = null;
          });
          timer.cancel();
          return;
        }

        final nextStation = lineStations[_simulationIndex];
        setState(() {
          _selectedStation = nextStation;
          _nearestStationDistance = 15.0;
        });

        _scrollToStationIndex(_simulationIndex);
        _triggerAutoAnnouncement(nextStation);
      });
    }
  }

  void _scrollToStationIndex(int index) {
    if (_timelineScrollController.hasClients) {
      _timelineScrollController.animateTo(
        index * 120.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _triggerAutoAnnouncement(Station station) async {
    final isAr = _languageCode == 'ar';
    final stationName = isAr ? station.nameAr : station.nameEn;
    String generated = '';

    if (station.isTransfer) {
      generated = isAr 
          ? "المحطة القادمة هي، $stationName. محطة تبادلية للخطوط الأخرى. الرجاء الاستعداد لمغادرة القطار."
          : "The next station is, $stationName. This is a transfer station for other metro lines. Please prepare to exit the train.";
    } else {
      generated = isAr 
          ? "المحطة القادمة هي، $stationName. الرجاء الانتباه للفراغ بين القطار والرصيف."
          : "The next station is, $stationName. Please mind the gap between the train and the platform.";
    }

    setState(() {
      _isLoading = false;
      _announcementText = generated;
    });

    // Start wave animation & visual indicator
    _startWaveAnimation();

    // Trigger Local Notification
    try {
      final notifTitle = isAr ? "محطة مترو قادمة 🚇" : "Upcoming Metro Station 🚇";
      final notifBody = isAr 
          ? "يقترب القطار الآن من محطة $stationName." 
          : "The train is now approaching $stationName station.";
      
      await NotificationService.showNotification(
        id: NotificationService.arrivalNotifId,
        title: notifTitle,
        body: notifBody,
      );
    } catch (e) {
      debugPrint("Failed to show local notification: $e");
    }

    // Speak announcement
    await _flutterTts.stop();
    await _flutterTts.setLanguage(_languageCode == 'ar' ? 'ar-EG' : 'en-US');
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.speak(generated);
  }

  Color getLineColor(int line) {
    switch (line) {
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

  @override
  void dispose() {
    _flutterTts.stop();
    _customTextController.dispose();
    _waveController.dispose();
    _waveTimer?.cancel();
    _simulationTimer?.cancel();
    _positionSubscription?.cancel();
    _timelineScrollController.dispose();
    super.dispose();
  }

  Widget _buildTimeline(BuildContext context) {
    if (_selectedStation == null) return const SizedBox.shrink();

    final isAr = context.locale.languageCode == 'ar';
    final currentLine = _selectedStation!.line;
    final lineStations = MetroData.stations.values.where((s) => s.line == currentLine).toList();
    final currentIndex = lineStations.indexWhere((s) => s.id == _selectedStation!.id);
    final lineColor = getLineColor(currentLine);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? "مسار الرحلة (الخط $currentLine) 📍" : "Trip Route (Line $currentLine) 📍",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lineColor.withOpacity(0.3)),
                ),
                child: Text(
                  isAr 
                      ? "إجمالي: ${lineStations.length} محطة" 
                      : "Total: ${lineStations.length} Stations",
                  style: TextStyle(color: lineColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            controller: _timelineScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: lineStations.length,
            itemBuilder: (context, index) {
              final station = lineStations[index];
              final isCurrent = index == currentIndex;
              final isPassed = index < currentIndex;
              final stationName = isAr ? station.nameAr : station.nameEn;

              return Container(
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Horizontal Connecting Line
                    Positioned(
                      left: index == 0 ? 60 : 0,
                      right: index == lineStations.length - 1 ? 60 : 0,
                      top: 35,
                      child: Container(
                        height: 4,
                        color: isPassed ? Colors.grey[300] : lineColor.withOpacity(0.5),
                      ),
                    ),
                    
                    // Node dot & labels
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Circle Indicator
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStation = station;
                              _announcementText = '';
                              _lastAnnouncedStationId = station.id;
                              if (_isSimulating) {
                                _toggleSimulationMode(); // Stop
                                _toggleSimulationMode(); // Restart from here
                              }
                            });
                            _scrollToStationIndex(index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isCurrent ? 36 : 24,
                            height: isCurrent ? 36 : 24,
                            decoration: BoxDecoration(
                              color: isCurrent 
                                  ? lineColor 
                                  : (isPassed ? Colors.grey[400] : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCurrent ? Colors.white : lineColor,
                                width: isCurrent ? 3 : 2,
                              ),
                              boxShadow: isCurrent ? [
                                BoxShadow(
                                  color: lineColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                )
                              ] : null,
                            ),
                            child: Center(
                              child: isCurrent
                                  ? const Icon(Icons.directions_subway, size: 16, color: Colors.white)
                                  : (isPassed 
                                      ? const Icon(Icons.check, size: 12, color: Colors.white) 
                                      : null),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Station Name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            stationName,
                            style: TextStyle(
                              fontSize: isCurrent ? 12 : 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent 
                                  ? AppColors.primary 
                                  : (isPassed ? Colors.grey[500] : Colors.grey[700]),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Transfer badge
                        if (station.isTransfer) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAr ? "تبادلية" : "Transfer",
                              style: const TextStyle(fontSize: 8, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutoTrackingTab(BuildContext context, bool isAr, List<Station> sortedStations) {
    final lineColor = _selectedStation != null ? getLineColor(_selectedStation!.line) : AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Route Selector Card
        Card(
          elevation: 0,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? "محطة البداية / تحديد المسار 📍" : "Starting Station / Line Select 📍",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Station>(
                  value: _selectedStation,
                  decoration: InputDecoration(
                    labelText: isAr ? "اختر محطة الانطلاق" : "Select Starting Station",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: sortedStations.map((station) {
                    return DropdownMenuItem<Station>(
                      value: station,
                      child: Text(isAr ? station.nameAr : station.nameEn),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStation = val;
                      _announcementText = '';
                      _lastAnnouncedStationId = null;
                      if (_isSimulating) {
                        _toggleSimulationMode(); // Stop current simulation
                        _toggleSimulationMode(); // Start with new line
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // GPS Toggle Card
        Card(
          elevation: 0,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? "الوضع التلقائي بموقع الـ GPS" : "GPS Auto Announcer Mode",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr 
                                ? "المذيع يشتغل تلقائياً عند الاقتراب من أي محطة على الخط"
                                : "Announce automatically as the train approaches stations",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isAutoMode,
                      activeColor: AppColors.primary,
                      onChanged: _isSimulating ? null : (val) => _toggleAutoMode(val),
                    ),
                  ],
                ),
                
                if (_isAutoMode) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      _buildPulsingDot(),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? "جاري التتبع الحي لموقعك الحالي..." : "Live tracking your current location...",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Simulation Card
        Card(
          elevation: 0,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? "محاكاة الرحلة تلقائياً 🚄" : "Simulate Subway Trip 🚄",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? "لمحاكاة حركة القطار وتجربة المذيع محطة بمحطة تلقائياً"
                                : "Simulate train movement & voice alerts station by station",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSimulating ? Colors.redAccent : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isAutoMode ? null : _toggleSimulationMode,
                      child: Text(
                        _isSimulating 
                            ? (isAr ? "إيقاف المحاكاة" : "Stop")
                            : (isAr ? "بدء المحاكاة" : "Start"),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        if (_selectedStation != null) ...[
          const SizedBox(height: 20),
          _buildTimeline(context),
          const SizedBox(height: 20),
          
          // Current status card
          Card(
            elevation: 0,
            color: lineColor.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: lineColor.withOpacity(0.25), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? "المحطة الحالية" : "Current Station",
                        style: TextStyle(fontWeight: FontWeight.bold, color: lineColor, fontSize: 13),
                      ),
                      if (_nearestStationDistance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _nearestStationDistance! < 300 
                                ? Colors.green.withOpacity(0.15) 
                                : Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _nearestStationDistance! < 300
                                ? (isAr ? "داخل نطاق المحطة" : "Inside Station")
                                : (isAr ? "جاري الاقتراب..." : "Approaching..."),
                            style: TextStyle(
                              color: _nearestStationDistance! < 300 ? Colors.green : Colors.amber[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? _selectedStation!.nameAr : _selectedStation!.nameEn,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Icon(Icons.train, color: lineColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isAr 
                            ? "الخط ${_selectedStation!.line} - ${_selectedStation!.isTransfer ? 'محطة تبادلية' : 'محطة عادية'}"
                            : "Line ${_selectedStation!.line} - ${_selectedStation!.isTransfer ? 'Transfer Station' : 'Regular Station'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  if (_nearestStationDistance != null) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? "المسافة التقريبية للمحطة:" : "Approximate distance to station:",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          isAr 
                              ? "${_nearestStationDistance!.toStringAsFixed(0)} متر" 
                              : "${_nearestStationDistance!.toStringAsFixed(0)} meters",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPulsingDot() {
    return _PulsingDot();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final sortedStations = List<Station>.from(_allStations);
    sortedStations.sort((a, b) => (isAr ? a.nameAr : a.nameEn).compareTo(isAr ? b.nameAr : b.nameEn));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(isAr ? "مذيع محطة المترو 🔊" : "Metro Voice Announcer 🔊"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                const SizedBox(height: 10),

                // 🌟 LED Station Display Board (Cairo Metro Look)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F11),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.circle, color: Colors.red, size: 8),
                          Text(
                            isAr ? "شاشة الرصيف الرقمية" : "PLATFORM BOARD",
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const Icon(Icons.circle, color: Colors.red, size: 8),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      
                      // Marquee Text Display
                      Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Color(0xFFFBBF24))
                            : Text(
                                _announcementText.isEmpty 
                                    ? (isAr ? "اختر محطة واضغط على تشغيل..." : "Select station and play...")
                                    : _announcementText,
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Soundwave Visualizer Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_waveHeights.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 4,
                            height: _waveHeights[index],
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Beautiful Custom Tab Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _activeTab == 0 ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                isAr ? "تتبع تلقائي (GPS) 📡" : "Auto Tracking (GPS) 📡",
                                style: TextStyle(
                                  color: _activeTab == 0 ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _activeTab == 1 ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                isAr ? "تحكم يدوي بالـ AI 📢" : "Manual AI Controls 📢",
                                style: TextStyle(
                                  color: _activeTab == 1 ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Render Active Tab Content
                if (_activeTab == 0) ...[
                  _buildAutoTrackingTab(context, isAr, sortedStations),
                ] else ...[
                  // Config panel card for Manual Settings
                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? "إعدادات المذيع بالـ AI" : "AI Announcer Settings",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Language Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAr ? "لغة الإعلان" : "Announcement Language", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ToggleButtons(
                                borderRadius: BorderRadius.circular(10),
                                selectedColor: Colors.white,
                                fillColor: AppColors.primary,
                                constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
                                isSelected: [_languageCode == 'ar', _languageCode == 'en'],
                                onPressed: (index) {
                                  setState(() {
                                    _languageCode = index == 0 ? 'ar' : 'en';
                                    _announcementText = ''; // regenerate
                                  });
                                },
                                children: const [
                                  Text("العربية"),
                                  Text("English"),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Announcement Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _announcementType,
                            decoration: InputDecoration(
                              labelText: isAr ? "نوع الإعلان 📢" : "Announcement Type 📢",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(value: 'next', child: Text(isAr ? "المحطة القادمة 🚇" : "Next Station")),
                              DropdownMenuItem(value: 'transfer', child: Text(isAr ? "محطة تبادلية 🔁" : "Transfer Station")),
                              DropdownMenuItem(value: 'safety', child: Text(isAr ? "تحذير سلامة ⚠️" : "Safety Warning")),
                              DropdownMenuItem(value: 'custom', child: Text(isAr ? "إعلان مخصص بالـ AI ✨" : "Custom AI Message")),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _announcementType = val;
                                  _announcementText = '';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Station dropdown (if next or transfer selected)
                          if (_announcementType == 'next' || _announcementType == 'transfer')
                            DropdownButtonFormField<Station>(
                              value: _selectedStation,
                              decoration: InputDecoration(
                                labelText: isAr ? "اختار المحطة" : "Select Station",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: sortedStations.map((station) {
                                return DropdownMenuItem<Station>(
                                  value: station,
                                  child: Text(isAr ? station.nameAr : station.nameEn),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedStation = val;
                                  _announcementText = '';
                                });
                              },
                            ),

                          // Custom Text Field (if custom selected)
                          if (_announcementType == 'custom')
                            TextField(
                              controller: _customTextController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: isAr ? "اكتب اللي عايز المذيع يقوله" : "Write announcement prompt",
                                hintText: isAr 
                                    ? "مثال: رحب بركاب الخط الثالث وتمنى لهم عطلة سعيدة..."
                                    : "e.g., Welcome passengers to Line 3...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (_) => setState(() => _announcementText = ''),
                            ),

                          const Divider(height: 24),

                          // Voice settings sliders (Pitch & Rate)
                          Text(
                            '${isAr ? "درجة الصوت (مؤثر الصدى)" : "Echo/Voice Pitch"}: ${_pitch.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Slider(
                            value: _pitch,
                            min: 0.5,
                            max: 1.5,
                            divisions: 10,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _pitch = val;
                                if (_isPlaying) _speak();
                              });
                            },
                          ),

                          Text(
                            '${isAr ? "سرعة إلقاء المذيع" : "Speaker Rate"}: ${_rate.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Slider(
                            value: _rate,
                            min: 0.2,
                            max: 0.8,
                            divisions: 12,
                            activeColor: Colors.blue,
                            onChanged: (val) {
                              setState(() {
                                _rate = val;
                                if (_isPlaying) _speak();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Play Button Card
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        backgroundColor: _isPlaying ? Colors.redAccent : const Color(0xFFFBBF24),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: (_isPlaying ? Colors.red : const Color(0xFFFBBF24)).withOpacity(0.35),
                      ),
                      onPressed: _isLoading ? null : _speak,
                      child: Icon(
                        _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _isPlaying 
                          ? (isAr ? "اضغط للإيقاف" : "Tap to Stop")
                          : (isAr ? "تشغيل إعلان المحطة" : "Play Announcement"),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                ],

                // Error alert
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  FadeInUp(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  __PulsingDotState createState() => __PulsingDotState();
}

class __PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(_controller.value * 0.7 + 0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: _controller.value * 8 + 2,
                spreadRadius: _controller.value * 2,
              )
            ],
          ),
        );
      },
    );
  }
}

