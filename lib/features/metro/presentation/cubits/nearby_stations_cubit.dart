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
  const NearbyStationsLoaded(this.stations);
  @override
  List<Object?> get props => [stations];
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

      _lastLat = position.latitude;
      _lastLng = position.longitude;

      await _computeAndEmit(position.latitude, position.longitude);
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

        emit(NearbyStationsLoaded(result));
      },
    );
  }

  // Keep backwards-compat alias
  Future<void> getNearestStation() => getNearbyStations();
}
