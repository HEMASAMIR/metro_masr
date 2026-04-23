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
  final List<Report> _localReports = [];
  final List<Message> _localMessages = [];
  int _points = 0;
  int _trips = 0;

  @override
  Future<Either<Failure, void>> saveReport(Report report) async {
    final reports = OfflineStorage.getReports();
    reports.insert(0, report.copyWith(isSynced: false)); // newest first
    await OfflineStorage.saveReports(reports);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Report>>> getReports() async {
    // Return all local reports from persistent storage
    final reports = OfflineStorage.getReports();
    
    // Seed one starter item if completely empty to guide users
    if (reports.isEmpty) {
      final initial = Report(
        id: const Uuid().v4(),
        title: 'تم العثور على محفظة',
        description: 'لقيت محفظة سوداء عند محطة السادات، سلمتها لمكتب الأمن.',
        location: 'محطة السادات',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        category: 'Wallet',
      );
      await saveReport(initial);
      return Right([initial]);
    }
    
    return Right(reports);
  }

  @override
  Future<Either<Failure, void>> sendMessage(Message message) async {
    // Save message locally. Real offline-first mesh would auto-send via Bluetooth here.
    _localMessages.add(message);

    // Simulate auto-reply for demo purposes
    Future.delayed(const Duration(seconds: 2), () {
      _localMessages.add(
        Message(
          id: const Uuid().v4(),
          senderId: 'bot_id',
          senderName: 'Passenger #394',
          content: 'شفت المترو الجاي، لسه واصل المحطة اللي فاتت.',
          timestamp: DateTime.now(),
          isSent: true,
        ),
      );
    });

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages() async {
    return Right(_localMessages);
  }

  @override
  Future<Either<Failure, void>> addTripPoint() async {
    _points += 10; // 10 points per trip
    _trips += 1;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Reward>> getRewardProfile() async {
    return Right(
      Reward(id: 'user_reward_1', currentPoints: _points, totalTrips: _trips),
    );
  }
}
