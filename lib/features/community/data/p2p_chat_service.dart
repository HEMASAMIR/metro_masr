import 'dart:async';
import 'dart:math';

class ChatMessage {
  final String senderName;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderName: map['senderName'],
      content: map['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

/// Simulated P2P chat service (no native dependencies).
/// Uses an in-memory broadcast stream to simulate nearby device communication.
class P2PChatService {
  final String userName = 'Passenger_${Random().nextInt(1000)}';

  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  // Simulated connected "devices" (passengers at same station)
  final Set<String> connectedDevices = {'sim_device_1', 'sim_device_2'};
  final Set<String> bannedDevices = {};

  String _currentStation = 'default';

  final List<String> _badWords = [
    'حمار',
    'غبي',
    'كلب',
    'حيوان',
    'زفت',
    'قذر',
  ];

  // Simulated bot replies for demo mode
  static const List<String> _simulatedReplies = [
    'هو المترو وصل؟ 🚇',
    'عندي تأخير في الخط الأول',
    'في زحمة جامدة عند رمسيس!',
    'الخط الثالث منتظم النهارده 👍',
    'محتاج حد يساعدني في محطة الشهداء',
    'القطر جاي بعد دقيقتين',
  ];

  Future<void> initialize(String stationName) async {
    _currentStation = stationName.replaceAll(' ', '_');
    connectedDevices.clear();
    // Simulate discovering nearby passengers
    connectedDevices.addAll(['sim_${_currentStation}_1', 'sim_${_currentStation}_2']);
  }

  Future<void> startAdvertising() async {
    // No-op in simulation mode
  }

  Future<void> startDiscovery() async {
    // No-op in simulation mode
  }

  Future<void> sendMessage(String text) async {
    if (_messageController.isClosed) return;

    // Profanity check
    for (final word in _badWords) {
      if (text.contains(word)) {
        // Silently drop the message
        return;
      }
    }

    // Add own message to stream
    _messageController.add(ChatMessage(
      senderName: userName,
      content: text,
      timestamp: DateTime.now(),
    ));

    // Simulate a random reply after a short delay
    if (connectedDevices.isNotEmpty && Random().nextBool()) {
      await Future.delayed(Duration(seconds: 1 + Random().nextInt(3)));
      if (!_messageController.isClosed) {
        final reply = _simulatedReplies[Random().nextInt(_simulatedReplies.length)];
        _messageController.add(ChatMessage(
          senderName: 'راكب_${Random().nextInt(999)}',
          content: reply,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<void> dispose() async {
    connectedDevices.clear();
    await _messageController.close();
  }
}
