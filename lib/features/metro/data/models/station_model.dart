
import 'package:rafiq_metrro/features/metro/domain/entities/station.dart';

class StationModel extends Station {
  const StationModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.line,
    required super.latitude,
    required super.longitude,
    required super.isTransfer,
    required super.connectedTo,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'],
      nameEn: json['nameEn'],
      nameAr: json['nameAr'],
      line: json['line'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isTransfer: json['isTransfer'] ?? false,
      connectedTo: List<String>.from(json['connectedTo'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'line': line,
      'latitude': latitude,
      'longitude': longitude,
      'isTransfer': isTransfer,
      'connectedTo': connectedTo,
    };
  }

  factory StationModel.fromEntity(Station station) {
    return StationModel(
      id: station.id,
      nameEn: station.nameEn,
      nameAr: station.nameAr,
      line: station.line,
      latitude: station.latitude,
      longitude: station.longitude,
      isTransfer: station.isTransfer,
      connectedTo: station.connectedTo,
    );
  }
}
