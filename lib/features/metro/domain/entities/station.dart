import 'package:equatable/equatable.dart';

class Station extends Equatable {
  final String id;
  final String nameEn;
  final String nameAr;
  final int line;
  final double latitude;
  final double longitude;
  final bool isTransfer;
  final List<String> connectedTo; // List of connected station IDs
  final List<String> facilities; // e.g., ['atm', 'wc', 'elevator']
  final List<Map<String, String>> exits; // e.g., [{'ar': 'مخرج 1', 'en': 'Exit 1'}]
  final bool hasElevator;
  final bool hasRamp;

  const Station({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.line,
    required this.latitude,
    required this.longitude,
    this.isTransfer = false,
    required this.connectedTo,
    this.facilities = const [],
    this.exits = const [],
    this.hasElevator = false,
    this.hasRamp = false,
  });

  @override
  List<Object?> get props => [id, nameEn, nameAr, line, latitude, longitude, isTransfer, connectedTo, facilities, exits, hasElevator, hasRamp];
}
