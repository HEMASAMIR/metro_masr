import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Enhanced NotificationService for Cairo Metro Master.
/// Supports: arrival alarms, line-delay alerts, general metro notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _arrivalChannelId   = 'arrival_alarm_channel';
  static const String _delayChannelId     = 'delay_alert_channel';
  static const String _generalChannelId   = 'general_metro_channel';

  // Notification IDs (stable, reusable)
  static const int arrivalNotifId  = 1;
  static const int delayLine1Id    = 10;
  static const int delayLine2Id    = 11;
  static const int delayLine3Id    = 12;
  static const int generalId       = 20;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  // ── Generic show ──────────────────────────────────────────────────────────
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = _generalChannelId,
    String channelName = 'Metro Notifications',
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(id, title, body, NotificationDetails(android: androidDetails));
  }

  // ── Arrival alarm ─────────────────────────────────────────────────────────
  /// Fires when user is approaching their destination station.
  static Future<void> showArrivalAlarm({
    required String stationNameAr,
    required String stationNameEn,
    bool isArabic = true,
  }) async {
    final title = isArabic ? '🚇 اقتربت من محطتك!' : '🚇 Almost There!';
    final body  = isArabic
        ? 'أنت على وشك الوصول إلى $stationNameAr — استعد للنزول!'
        : 'You are approaching $stationNameEn — get ready!';

    await showNotification(
      id: arrivalNotifId,
      title: title,
      body: body,
      channelId: _arrivalChannelId,
      channelName: 'Arrival Alarm',
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  // ── Line delay alert ──────────────────────────────────────────────────────
  /// Fires when a delay is detected on a metro line.
  static Future<void> showLineDelayAlert({
    required int lineNumber,
    required int delayMinutes,
    bool isArabic = true,
  }) async {
    final notifId = lineNumber == 1 ? delayLine1Id
                  : lineNumber == 2 ? delayLine2Id
                  : delayLine3Id;

    final title = isArabic
        ? '⚠️ تأخير في الخط $lineNumber'
        : '⚠️ Line $lineNumber Delay';
    final body = isArabic
        ? 'يوجد تأخير $delayMinutes دقيقة في الخط $lineNumber. فكّر في مسار بديل.'
        : 'There is a $delayMinutes-minute delay on Line $lineNumber. Consider an alternative route.';

    await showNotification(
      id: notifId,
      title: title,
      body: body,
      channelId: _delayChannelId,
      channelName: 'Line Delay Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  // ── Crowd alert ───────────────────────────────────────────────────────────
  static Future<void> showCrowdAlert({
    required String stationName,
    required String crowdLevel,
    bool isArabic = true,
  }) async {
    final emoji = crowdLevel == 'high' ? '😤' : '😐';
    final title = isArabic ? '$emoji ازدحام في $stationName' : '$emoji Crowd at $stationName';
    final body  = isArabic
        ? 'الزحمة حالياً ${crowdLevel == 'high' ? 'شديدة' : 'متوسطة'}. أفضل وقت للسفر بعد ساعة.'
        : 'Current crowd is ${crowdLevel == 'high' ? 'high' : 'moderate'}. Best time is in ~1 hour.';

    await showNotification(
      id: generalId,
      title: title,
      body: body,
      channelId: _generalChannelId,
      channelName: 'Metro Notifications',
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async => _plugin.cancelAll();
  static Future<void> cancel(int id) async => _plugin.cancel(id);
}
