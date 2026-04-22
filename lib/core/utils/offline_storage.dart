import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Wallet Data ---
  static double getBalance() {
    return _prefs.getDouble('wallet_balance') ?? 45.0; // Default 45 EGP
  }

  static Future<void> setBalance(double value) async {
    await _prefs.setDouble('wallet_balance', value);
  }

  static Future<void> addBalance(double amount) async {
    final current = getBalance();
    await setBalance(current + amount);
  }

  // --- Gamification Data ---
  static int getPoints() {
    return _prefs.getInt('user_points') ?? 0;
  }

  static Future<void> setPoints(int value) async {
    await _prefs.setInt('user_points', value);
  }
  
  static Future<void> addPoints(int amount) async {
    final current = getPoints();
    await setPoints(current + amount);
  }

  static int getTrips() {
    return _prefs.getInt('user_trips') ?? 0;
  }

  static Future<void> addTrip() async {
    final current = getTrips();
    await _prefs.setInt('user_trips', current + 1);
  }
}
