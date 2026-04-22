import 'package:geolocator/geolocator.dart';
import '../../features/metro/domain/entities/station.dart';

class LocationUtils {
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static Station? findNearestStation(double userLat, double userLon, List<Station> stations) {
    if (stations.isEmpty) return null;

    Station nearest = stations.first;
    double minDistance = calculateDistance(userLat, userLon, nearest.latitude, nearest.longitude);

    for (var station in stations) {
      double distance = calculateDistance(userLat, userLon, station.latitude, station.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }
    return nearest;
  }
}
