import 'package:flutter/material.dart';
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
    String summaryText = 'Rafiq Metro',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF1565C0), // App primary color
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: '<b>$title</b>',
        htmlFormatContentTitle: true,
        summaryText: summaryText,
      ),
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
    final title = isArabic ? '📍 اقتربت من محطتك!' : '📍 Almost There!';
    final body  = isArabic
        ? 'أنت على وشك الوصول إلى <b>$stationNameAr</b>.<br>استعد للنزول وتأكد من اصطحاب كافة أغراضك، نتمنى لك يوماً سعيداً! ✨'
        : 'You are approaching <b>$stationNameEn</b>.<br>Please get ready to leave the train and ensure you have all your belongings. Have a great day! ✨';

    await showNotification(
      id: arrivalNotifId,
      title: title,
      body: body,
      channelId: _arrivalChannelId,
      channelName: 'Arrival Alarm',
      importance: Importance.max,
      priority: Priority.high,
      summaryText: isArabic ? 'تنبيه الوصول' : 'Arrival Alert',
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
        ? '⚠️ تحديث حركة الخط $lineNumber'
        : '⚠️ Line $lineNumber Status Update';
    final body = isArabic
        ? 'نأسف لإبلاغك بوجود تأخير يقدر بحوالي <b>$delayMinutes دقيقة</b> في حركة الخط $lineNumber.<br>يرجى ترتيب مواعيدك أو استخدام بدائل النقل المتاحة عبر التطبيق.'
        : 'We regret to inform you of an estimated <b>$delayMinutes-minute</b> delay on Line $lineNumber.<br>Please adjust your schedule or check the app for alternative routes.';

    await showNotification(
      id: notifId,
      title: title,
      body: body,
      channelId: _delayChannelId,
      channelName: 'Line Delay Alerts',
      importance: Importance.high,
      priority: Priority.high,
      summaryText: isArabic ? 'تحديثات الحركة' : 'Status Update',
    );
  }

  // ── Crowd alert ───────────────────────────────────────────────────────────
  static Future<void> showCrowdAlert({
    required String stationName,
    required String crowdLevel,
    bool isArabic = true,
  }) async {
    final emoji = crowdLevel == 'high' ? '🔴' : '🟡';
    final title = isArabic ? '$emoji تنبيه الازدحام: $stationName' : '$emoji Crowd Alert: $stationName';
    final body  = isArabic
        ? 'الزحمة في محطة <b>$stationName</b> حالياً ${crowdLevel == 'high' ? 'شديدة جداً' : 'متوسطة'}.<br>لرحلة أكثر راحة، ننصحك بتأجيل رحلتك قليلاً أو تجنب أوقات الذروة.'
        : 'The crowd at <b>$stationName</b> is currently ${crowdLevel == 'high' ? 'very heavy' : 'moderate'}.<br>For a more comfortable trip, consider delaying your journey slightly.';

    await showNotification(
      id: generalId,
      title: title,
      body: body,
      channelId: _generalChannelId,
      channelName: 'Metro Notifications',
      summaryText: isArabic ? 'حالة الزحام' : 'Crowd Status',
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async => _plugin.cancelAll();
  static Future<void> cancel(int id) async => _plugin.cancel(id);
}
