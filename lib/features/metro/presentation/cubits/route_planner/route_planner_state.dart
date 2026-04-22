import 'package:equatable/equatable.dart';
import 'package:rafiq_metrro/core/utils/ai_prediction_service.dart';
import '../../../domain/entities/station.dart';

abstract class RoutePlannerState extends Equatable {
  const RoutePlannerState();

  @override
  List<Object?> get props => [];
}

class RoutePlannerInitial extends RoutePlannerState {}

class RoutePlannerLoading extends RoutePlannerState {}

class RoutePlannerLoaded extends RoutePlannerState {
  final List<Station> path;
  final int stationCount;
  final int ticketPrice;
  final int transfers;
  final AiPrediction? aiPrediction;
  final String? boardingHint;

  const RoutePlannerLoaded({
    required this.path,
    required this.stationCount,
    required this.ticketPrice,
    required this.transfers,
    this.aiPrediction,
    this.boardingHint,
  });

  @override
  List<Object?> get props => [path, stationCount, ticketPrice, transfers, aiPrediction, boardingHint];
}

class RoutePlannerError extends RoutePlannerState {
  final String message;
  const RoutePlannerError(this.message);

  @override
  List<Object?> get props => [message];
}
