import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/community/domain/entities/report.dart';

/// Central storage service for the entire app.
/// Initialise once in [main] via [AppStorage.init()].
/// Never call [SharedPreferences.getInstance()] anywhere else.
class AppStorage {
  static late SharedPreferences _prefs;

  // ── Key constants ──────────────────────────────────────────────────────────
  // Wallet
  static const _kWalletBalance = 'wallet_balance';

  // Theme
  static const _kThemeMode = 'theme_mode'; // 'light' | 'dark'

  // Onboarding
  static const _kOnboardingSeen = 'onboarding_seen';

  // Language
  static const _kLanguage = 'app_language';

  // Notifications
  static const _kNotifications = 'notifications_enabled';
  static const _kCrowdAlerts = 'crowd_alerts';
  static const _kTripReminders = 'trip_reminders';

  // Favorite stations
  static const _kFavorites = 'favorite_stations';

  // Last route planner selection
  static const _kLastFrom = 'last_from_station';
  static const _kLastTo = 'last_to_station';

  // Community reports
  static const _kCommunityReports = 'community_reports';

  // Scheduled trips (kept same key as before for backwards-compat)
  static const _kScheduledTrips = 'scheduled_trips_v2';

  // ── Init ───────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Wallet ─────────────────────────────────────────────────────────────────

  static double getBalance() => _prefs.getDouble(_kWalletBalance) ?? 45.0;

  static Future<void> setBalance(double value) =>
      _prefs.setDouble(_kWalletBalance, value);

  static Future<void> addBalance(double amount) =>
      setBalance(getBalance() + amount);

  // ── Theme ──────────────────────────────────────────────────────────────────

  static ThemeMode getThemeMode() {
    final saved = _prefs.getString(_kThemeMode);
    if (saved == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  static Future<void> saveThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');

  // ── Onboarding ─────────────────────────────────────────────────────────────

  static bool hasSeenOnboarding() =>
      _prefs.getBool(_kOnboardingSeen) ?? false;

  static Future<void> setOnboardingSeen() =>
      _prefs.setBool(_kOnboardingSeen, true);

  // ── Language ───────────────────────────────────────────────────────────────

  static String getLanguage() => _prefs.getString(_kLanguage) ?? 'ar';

  static Future<void> saveLanguage(String langCode) =>
      _prefs.setString(_kLanguage, langCode);

  // ── Notifications ──────────────────────────────────────────────────────────

  static bool getNotificationsEnabled() =>
      _prefs.getBool(_kNotifications) ?? true;

  static Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotifications, value);

  static bool getCrowdAlerts() => _prefs.getBool(_kCrowdAlerts) ?? true;

  static Future<void> setCrowdAlerts(bool value) =>
      _prefs.setBool(_kCrowdAlerts, value);

  static bool getTripReminders() => _prefs.getBool(_kTripReminders) ?? true;

  static Future<void> setTripReminders(bool value) =>
      _prefs.setBool(_kTripReminders, value);

  // ── Favorite Stations ──────────────────────────────────────────────────────

  static List<String> getFavoriteStations() =>
      _prefs.getStringList(_kFavorites) ?? [];

  static bool isFavorite(String stationId) =>
      getFavoriteStations().contains(stationId);

  static Future<void> toggleFavorite(String stationId) async {
    final favs = getFavoriteStations();
    if (favs.contains(stationId)) {
      favs.remove(stationId);
    } else {
      favs.add(stationId);
    }
    await _prefs.setStringList(_kFavorites, favs);
  }

  static Future<void> addFavorite(String stationId) async {
    final favs = getFavoriteStations();
    if (!favs.contains(stationId)) {
      favs.add(stationId);
      await _prefs.setStringList(_kFavorites, favs);
    }
  }

  static Future<void> removeFavorite(String stationId) async {
    final favs = getFavoriteStations()..remove(stationId);
    await _prefs.setStringList(_kFavorites, favs);
  }

  // ── Last Route ─────────────────────────────────────────────────────────────

  static String? getLastFromStation() => _prefs.getString(_kLastFrom);

  static String? getLastToStation() => _prefs.getString(_kLastTo);

  static Future<void> saveLastRoute(String from, String to) async {
    await _prefs.setString(_kLastFrom, from);
    await _prefs.setString(_kLastTo, to);
  }

  // ── Community Reports ──────────────────────────────────────────────────────

  static List<Report> getReports() {
    final lists = _prefs.getStringList(_kCommunityReports) ?? [];
    return lists.map((e) => Report.fromJson(e)).toList();
  }

  static Future<void> saveReports(List<Report> reports) {
    final encoded = reports.map((e) => e.toJson()).toList();
    return _prefs.setStringList(_kCommunityReports, encoded);
  }

  // ── Scheduled Trips ────────────────────────────────────────────────────────

  static List<String> getRawScheduledTrips() =>
      _prefs.getStringList(_kScheduledTrips) ?? [];

  static Future<void> saveRawScheduledTrips(List<String> trips) =>
      _prefs.setStringList(_kScheduledTrips, trips);

  // ── Clear All ──────────────────────────────────────────────────────────────

  /// Clears everything EXCEPT theme and language preferences.
  static Future<void> clearUserData() async {
    await _prefs.remove(_kWalletBalance);
    await _prefs.remove(_kFavorites);
    await _prefs.remove(_kLastFrom);
    await _prefs.remove(_kLastTo);
    await _prefs.remove(_kCommunityReports);
    await _prefs.remove(_kScheduledTrips);
  }
}
