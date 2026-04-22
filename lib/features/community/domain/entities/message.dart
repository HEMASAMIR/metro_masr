import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isSent;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isSent = false,
  });

  @override
  List<Object?> get props => [id, senderId, senderName, content, timestamp, isSent];
}
