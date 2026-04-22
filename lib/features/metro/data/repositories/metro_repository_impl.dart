import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/dijkstra.dart';
import '../../../../core/utils/metro_data.dart';
import '../../domain/entities/station.dart';
import '../../domain/repositories/metro_repository.dart';

class MetroRepositoryImpl implements MetroRepository {
  @override
  Future<Either<Failure, Map<String, dynamic>>> getShortestPath(
      String startId, String endId) async {
    try {
      final result = Dijkstra.findShortestPath(MetroData.stations, startId, endId);
      if (result['path'].isEmpty) {
        return const Left(ServerFailure('No path found between these stations'));
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Station>>> getAllStations() async {
    try {
      return Right(MetroData.stations.values.toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> calculateTicketPrice(int stationCount) async {
    // Cairo Metro Pricing — official 2026 rates (effective 27 March 2026):
    // ≤  9 stations : 10 EGP  (was 8 EGP)
    // ≤ 16 stations : 12 EGP  (was 10 EGP)
    // ≤ 23 stations : 15 EGP  (unchanged)
    // ≤ 39 stations : 20 EGP  (unchanged)
    try {
      return Right(MetroData.calculateTicketPrice(stationCount));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
