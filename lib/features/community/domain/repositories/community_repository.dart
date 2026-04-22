import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/report.dart';
import '../entities/message.dart';
import '../entities/reward.dart';

abstract class CommunityRepository {
  Future<Either<Failure, void>> saveReport(Report report);
  Future<Either<Failure, List<Report>>> getReports();
  
  Future<Either<Failure, void>> sendMessage(Message message);
  Future<Either<Failure, List<Message>>> getMessages();
  
  Future<Either<Failure, void>> addTripPoint();
  Future<Either<Failure, Reward>> getRewardProfile();
}
