import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/p2p_chat_service.dart';

abstract class P2PChatState extends Equatable {
  const P2PChatState();
  @override
  List<Object> get props => [];
}

class P2PChatInitial extends P2PChatState {}
class P2PChatConnecting extends P2PChatState {}
class P2PChatConnected extends P2PChatState {
  final List<ChatMessage> messages;
  final int connectedCount;

  const P2PChatConnected({required this.messages, required this.connectedCount});

  @override
  List<Object> get props => [messages, connectedCount];
}
class P2PChatError extends P2PChatState {
  final String message;
  const P2PChatError(this.message);
  @override
  List<Object> get props => [message];
}

class P2PChatCubit extends Cubit<P2PChatState> {
  final P2PChatService _chatService;
  StreamSubscription? _messageSub;
  List<ChatMessage> _currentMessages = [];

  P2PChatCubit(this._chatService) : super(P2PChatInitial());

  Future<void> connectToStation(String stationName) async {
    emit(P2PChatConnecting());
    
    // Request required permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = true;
    for (var status in statuses.values) {
      if (status.isDenied || status.isPermanentlyDenied) {
        allGranted = false;
      }
    }

    if (!allGranted) {
      emit(const P2PChatError('Permissions required for offline chat are missing.'));
      return;
    }

    try {
      await _chatService.initialize(stationName);
      
      // Start both advertising and discovering for mesh network
      await _chatService.startAdvertising();
      await _chatService.startDiscovery();

      _messageSub?.cancel();
      _messageSub = _chatService.messageStream.listen((msg) {
        _currentMessages = List.from(_currentMessages)..add(msg);
        emit(P2PChatConnected(
          messages: _currentMessages, 
          connectedCount: _chatService.connectedDevices.length
        ));
      });

      // Periodically update connection count
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (isClosed) {
          timer.cancel();
          return;
        }
        if (state is P2PChatConnected) {
           emit(P2PChatConnected(
             messages: _currentMessages, 
             connectedCount: _chatService.connectedDevices.length
           ));
        }
      });

      emit(P2PChatConnected(messages: _currentMessages, connectedCount: 0));
    } catch (e) {
      emit(P2PChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _chatService.sendMessage(text);
  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    _chatService.dispose();
    return super.close();
  }
}
