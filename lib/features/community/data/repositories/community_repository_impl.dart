import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:rafiq_metrro/features/community/domain/entities/message.dart';
import 'package:rafiq_metrro/features/community/domain/entities/report.dart';
import 'package:rafiq_metrro/features/community/domain/entities/reward.dart';
import 'package:rafiq_metrro/features/community/domain/repositories/community_repository.dart';
import 'package:rafiq_metrro/core/utils/offline_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  // Simulated local offline storage
  final List<Message> _localMessages = [];

  @override
  Future<Either<Failure, void>> saveReport(Report report) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Report>>> getReports() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> sendMessage(Message message) async {
    // Save message locally. Real offline-first mesh would auto-send via Bluetooth here.
    _localMessages.add(message);

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages() async {
    return Right(_localMessages);
  }

  @override
  Future<Either<Failure, void>> addTripPoint() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Reward>> getRewardProfile() async {
    return Right(
      Reward(id: 'user_reward_empty', currentPoints: 0, totalTrips: 0),
    );
  }

  @override
  Future<Either<Failure, void>> deleteReport(String id) async {
    return const Right(null);
  }
}
