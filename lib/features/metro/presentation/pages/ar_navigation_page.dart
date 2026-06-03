import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/metro_data.dart';
import '../../domain/entities/station.dart';

class ARNavigationPage extends StatefulWidget {
  const ARNavigationPage({super.key});

  @override
  State<ARNavigationPage> createState() => _ARNavigationPageState();
}

class _ARNavigationPageState extends State<ARNavigationPage> {
  CameraController? _controller;
  double _heading = 0.0;
  bool _isLocating = true;
  Station? _nearestStation;
  double _distanceToStation = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initSensors();
    _findNearestStation();
  }

  Future<void> _findNearestStation() async {
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
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
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
      
      if (mounted) {
        setState(() {
          _nearestStation = nearest;
          _distanceToStation = minDist;
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Camera access is required for AR Navigation.'.tr())),
           );
        } 
        return;
      }
      final cameras = await availableCameras(); 
      if (cameras.isEmpty) return;
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to initialize camera: $e'.tr())),
         );
      }
    }
  }

  void _initSensors() {
    magnetometerEvents.listen((MagnetometerEvent event) {
      // Very basic heading calculation
      double heading = math.atan2(event.y, event.x) * (180 / math.pi);
      if (mounted) setState(() => _heading = heading);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera Background
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Positioned.fill(child: Center(child: CircularProgressIndicator())),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // AR Overlay
          if (!_isLocating)
            Center(
              child: _buildAROverlay(),
            ),

          // Bottom Info
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildAROverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: (_heading * math.pi / 180),
          child: const Icon(
            Icons.navigation,
            size: 100,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _nearestStation != null 
                ? (context.locale.languageCode == 'ar' ? 'أنت متجه نحو ${_nearestStation!.nameAr}' : 'Heading to ${_nearestStation!.nameEn}')
                : 'station_found'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.location_on, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLocating 
                     ? 'finding_station'.tr() 
                     : (_nearestStation != null 
                         ? (context.locale.languageCode == 'ar' ? _nearestStation!.nameAr : _nearestStation!.nameEn) 
                         : 'No station found'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (!_isLocating && _nearestStation != null)
                  Text('${_distanceToStation.round()}m • Line ${_nearestStation!.line}', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
