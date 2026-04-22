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
  final double distanceMetres;
  const StationWithDistance(this.station, this.distanceMetres);
}

// ── Cubit ────────────────────────────────────────────────────────────────────
class NearbyStationsCubit extends Cubit<NearbyStationsState> {
  final MetroRepository repository;

  NearbyStationsCubit(this.repository) : super(NearbyStationsInitial());

  Future<void> getNearbyStations() async {
    emit(NearbyStationsLoading());

    try {
      // Check / request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const NearbyStationsError('Location permissions are denied'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const NearbyStationsError(
            'Location permissions are permanently denied. Please enable them in settings.'));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final allStationsResult = await repository.getAllStations();

      allStationsResult.fold(
        (failure) => emit(NearbyStationsError(failure.message)),
        (stations) {
          // Calculate distance for every station and sort ascending
          final withDist = stations.map((s) {
            final dist = LocationUtils.calculateDistance(
              position.latitude,
              position.longitude,
              s.latitude,
              s.longitude,
            );
            return StationWithDistance(s, dist);
          }).toList()
            ..sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));

          emit(NearbyStationsLoaded(withDist));
        },
      );
    } catch (e) {
      emit(NearbyStationsError(e.toString()));
    }
  }

  // Keep backwards-compat alias
  Future<void> getNearestStation() => getNearbyStations();
}
