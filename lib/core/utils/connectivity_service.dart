import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();

  ConnectivityService._internal() {
    _startMonitoring();
  }

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  Timer? _timer;

  // Multiple hosts to try — if ANY succeeds, we're online
  static const List<String> _hosts = [
    'google.com',
    '8.8.8.8',     // Google DNS
    'cloudflare.com',
    'microsoft.com',
  ];

  void _startMonitoring() {
    _checkStatus(); // immediate check on start
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final previous = _isOffline;
    bool reachable = false;

    for (final host in _hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          reachable = true;
          break; // one success is enough
        }
      } catch (_) {
        // try next host
      }
    }

    _isOffline = !reachable;

    if (previous != _isOffline) {
      notifyListeners();
    }
  }

  /// Force a connectivity check right now and return the result
  Future<bool> checkNow() async {
    await _checkStatus();
    return !_isOffline;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
