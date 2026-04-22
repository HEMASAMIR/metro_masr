import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/station.dart';

abstract class MetroRepository {
  Future<Either<Failure, Map<String, dynamic>>> getShortestPath(String startId, String endId);
  Future<Either<Failure, List<Station>>> getAllStations();
  Future<Either<Failure, int>> calculateTicketPrice(int stationCount);
}
