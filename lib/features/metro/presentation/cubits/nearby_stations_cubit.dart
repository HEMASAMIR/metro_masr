import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rafiq_metrro/features/metro/domain/entities/station.dart';
import 'package:rafiq_metrro/features/metro/domain/repositories/metro_repository.dart';
import '../../../../core/utils/location_utils.dart';

// ── States ──────────────────────────────────────────────────────────────────
abstract class NearbyStationsState extends Equatable {
  const NearbyStationsState();
  @override
  List<Object?> get props => [];
}

class NearbyStationsInitial extends NearbyStationsState {}

class NearbyStationsLoading extends NearbyStationsState {}

class NearbyStationsLoaded extends NearbyStationsState {
  /// All stations sorted by distance (closest first)
  final List<StationWithDistance> stations;
  final bool isMockedForDemo;
  const NearbyStationsLoaded(this.stations, {this.isMockedForDemo = false});
  @override
  List<Object?> get props => [stations, isMockedForDemo];
}

class NearbyStationsError extends NearbyStationsState {
  final String message;
  const NearbyStationsError(this.message);
  @override
  List<Object?> get props => [message];
}

/// A station paired with its distance in metres from the user
class StationWithDistance {
  final Station station;

  /// Distance in metres from the user's current position
  final double distanceMetres;

  /// Estimated walking time in minutes (avg 80 m/min)
  int get walkingMinutes => (distanceMetres / 80).ceil();

  /// Human-readable distance label
  String get distanceLabel {
    if (distanceMetres < 1000) return '${distanceMetres.round()} م';
    return '${(distanceMetres / 1000).toStringAsFixed(1)} كم';
  }

  const StationWithDistance(this.station, this.distanceMetres);
}

// ── Cubit ────────────────────────────────────────────────────────────────────
class NearbyStationsCubit extends Cubit<NearbyStationsState> {
  final MetroRepository repository;

  /// Max radius to show stations (metres). Stations further than this are hidden.
  static const double _maxRadiusMetres = 10000; // 10 km

  /// Last known user position (kept for refresh)
  double? _lastLat;
  double? _lastLng;
  bool _isMocked = false;

  NearbyStationsCubit(this.repository) : super(NearbyStationsInitial());

  Future<void> getNearbyStations() async {
    emit(NearbyStationsLoading());

    try {
      // ── 1. Check / request location permission ───────────────────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const NearbyStationsError('تم رفض إذن الموقع'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const NearbyStationsError(
            'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من الإعدادات.'));
        return;
      }

      // ── 2. Get high-accuracy position ───────────────────────────────────
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );

      double lat = position.latitude;
      double lng = position.longitude;
      _isMocked = false;

      // Smart Emulator/Remote Dev Mode: if the distance from Cairo is > 200 km,
      // mock it to Downtown Cairo (Sadat Station) so that the app displays beautifully
      final distanceToCairo = LocationUtils.calculateDistance(lat, lng, 30.0444, 31.2357);
      if (distanceToCairo > 200000) { // > 200 km
        lat = 30.0444; // Sadat Station
        lng = 31.2357;
        _isMocked = true;
      }

      _lastLat = lat;
      _lastLng = lng;

      await _computeAndEmit(lat, lng);
    } on Exception catch (e) {
      emit(NearbyStationsError(e.toString()));
    }
  }

  /// Re-compute using last known position (fast refresh, no GPS call)
  Future<void> refreshWithLastPosition() async {
    if (_lastLat == null || _lastLng == null) {
      await getNearbyStations();
      return;
    }
    await _computeAndEmit(_lastLat!, _lastLng!);
  }

  Future<void> _computeAndEmit(double userLat, double userLng) async {
    final allStationsResult = await repository.getAllStations();

    allStationsResult.fold(
      (failure) => emit(NearbyStationsError(failure.message)),
      (stations) {
        // Calculate distance for every station
        final withDist = stations.map((s) {
          final dist = LocationUtils.calculateDistance(
            userLat, userLng,
            s.latitude, s.longitude,
          );
          return StationWithDistance(s, dist);
        }).toList();

        // Sort by distance ascending
        withDist.sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));

        // ── FILTER: only keep stations within radius ──────────────────────
        final nearby = withDist
            .where((s) => s.distanceMetres <= _maxRadiusMetres)
            .toList();

        // If nothing within radius, show 5 closest regardless
        final result = nearby.isNotEmpty ? nearby : withDist.take(5).toList();

        emit(NearbyStationsLoaded(result, isMockedForDemo: _isMocked));
      },
    );
  }

  // Keep backwards-compat alias
  Future<void> getNearestStation() => getNearbyStations();
}
