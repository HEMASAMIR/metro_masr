import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq_metrro/core/utils/ai_prediction_service.dart';
import '../../../domain/entities/station.dart';
import '../../../domain/repositories/metro_repository.dart';
import 'route_planner_state.dart';

class RoutePlannerCubit extends Cubit<RoutePlannerState> {
  final MetroRepository repository;

  RoutePlannerCubit(this.repository) : super(RoutePlannerInitial());

  Future<void> findPath(String startId, String endId) async {
    emit(RoutePlannerLoading());

    final failureOrPath = await repository.getShortestPath(startId, endId);

    failureOrPath.fold(
      (failure) => emit(RoutePlannerError(failure.message)),
      (result) async {
        final path = result['path'];
        final transfers = result['transfers'];
        final stationCount = path.length;

        final failureOrPrice = await repository.calculateTicketPrice(stationCount);
        
        final prediction = AiPredictionService.predict(List<Station>.from(path), DateTime.now());
        
        String? boardingHint;
        if (transfers > 0) {
          final transferStations = List<Station>.from(path).where((s) => s.isTransfer).toList();
          if (transferStations.isNotEmpty) {
            String ts = transferStations.first.id;
            if (ts.contains('sadat')) boardingHint = 'hint_sadat';
            else if (ts.contains('shohadaa')) boardingHint = 'hint_shohadaa';
            else if (ts.contains('attaba') || ts.contains('nasser')) boardingHint = 'hint_attaba_nasser';
            else boardingHint = 'hint_general_transfer';
          }
        }

        failureOrPrice.fold(
          (failure) => emit(RoutePlannerError(failure.message)),
          (price) => emit(RoutePlannerLoaded(
            path: path,
            stationCount: stationCount,
            ticketPrice: price,
            transfers: transfers,
            aiPrediction: prediction,
            boardingHint: boardingHint,
          )),
        );
      },
    );
  }
}
