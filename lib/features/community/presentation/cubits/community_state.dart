import 'package:equatable/equatable.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/reward.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<Report> reports;
  final List<Message> messages;
  final Reward reward;

  const CommunityLoaded({
    required this.reports,
    required this.messages,
    required this.reward,
  });

  @override
  List<Object?> get props => [reports, messages, reward];
}

class CommunityError extends CommunityState {
  final String message;
  const CommunityError(this.message);

  @override
  List<Object?> get props => [message];
}
