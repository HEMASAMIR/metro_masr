import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/community_repository.dart';
import '../../../../core/utils/offline_storage.dart';
import 'community_state.dart';

class CommunityCubit extends Cubit<CommunityState> {
  final CommunityRepository repository;

  CommunityCubit(this.repository) : super(CommunityInitial());

  Future<void> loadCommunityData() async {
    emit(CommunityLoading());

    final reportsResult = await repository.getReports();
    final messagesResult = await repository.getMessages();
    final rewardResult = await repository.getRewardProfile();

    reportsResult.fold(
      (failure) => emit(CommunityError(failure.message)),
      (reports) {
        messagesResult.fold(
          (failure) => emit(CommunityError(failure.message)),
          (messages) {
            rewardResult.fold(
              (failure) => emit(CommunityError(failure.message)),
              (reward) {
                final localReward = Reward(
                  id: reward.id,
                  currentPoints: OfflineStorage.getPoints(),
                  totalTrips: OfflineStorage.getTrips(),
                );
                emit(CommunityLoaded(
                  reports: reports,
                  messages: messages,
                  reward: localReward,
                ));
              },
            );
          },
        );
      },
    );
  }

  Future<void> addReport(String title, String description, String category) async {
    final report = Report(
      id: const Uuid().v4(),
      title: title,
      description: description,
      location: 'Current Location',
      timestamp: DateTime.now(),
      category: category,
    );

    // Save offline
    await repository.saveReport(report);
    // Reload state seamlessly
    loadCommunityData();
  }

  Future<void> sendMessage(String text) async {
    final message = Message(
      id: const Uuid().v4(),
      senderId: 'me',
      senderName: 'أنا',
      content: text,
      timestamp: DateTime.now(),
      isSent: true,
    );

    // Send it to the local mesh/db
    await repository.sendMessage(message);
    loadCommunityData();
    
    // Simulate refreshing again after 2 seconds to see the auto-reply
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) loadCommunityData();
    });
  }

  Future<void> collectTripPoints() async {
    await OfflineStorage.addPoints(50);
    await OfflineStorage.addTrip();
    await repository.addTripPoint();
    loadCommunityData();
  }

  void redeemPoints(int cost) {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;
      if (currentState.reward.currentPoints >= cost) {
         OfflineStorage.addPoints(-cost);
         final newReward = Reward(
           id: currentState.reward.id,
           currentPoints: currentState.reward.currentPoints - cost,
           totalTrips: currentState.reward.totalTrips,
         );
         emit(CommunityLoaded(
           reports: currentState.reports,
           messages: currentState.messages,
           reward: newReward,
         ));
      }
    }
  }
}
