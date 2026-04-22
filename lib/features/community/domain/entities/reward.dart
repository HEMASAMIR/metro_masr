import 'package:equatable/equatable.dart';

class Reward extends Equatable {
  final String id;
  final int currentPoints;
  final int totalTrips;

  const Reward({
    required this.id,
    required this.currentPoints,
    required this.totalTrips,
  });

  @override
  List<Object?> get props => [id, currentPoints, totalTrips];
}
