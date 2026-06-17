import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int arrivalNotifId = 1001;
  // صورة بديلة "شيك" في حالة فشل التحميل
  static const String _chicPlaceholder =
      "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=500";

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions explicitly for iOS
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // تعريف القنوات لضمان عمل الأصوات المخصصة والاهتزاز
    const AndroidNotificationChannel tourismChannel =
        AndroidNotificationChannel(
          'rafiq_metro_tourism',
          'Metro Tourism Alerts',
          importance: Importance.max,
        );

    const AndroidNotificationChannel sportsChannel = AndroidNotificationChannel(
      'sports_clubs_channel',
      'Sports Club Alerts',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('club_alert'),
      playSound: true,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(tourismChannel);
    await androidPlugin?.createNotificationChannel(sportsChannel);
  }

  /// تحميل الصورة وحفظها مؤقتاً لعرضها في الإشعار
  static Future<String> _downloadAndSaveFile(
    String url,
    String fileName,
  ) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) throw Exception("Failed to load image");

    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
    String? customSound,
  }) async {
    BigPictureStyleInformation? bigPictureStyleInformation;
    String? bigPicturePath;

    // تحديد الصورة المستخدمة: الأصلية أو البديلة الشيك
    String imageToUse = (imageUrl != null && imageUrl.isNotEmpty)
        ? imageUrl
        : _chicPlaceholder;

    try {
      bigPicturePath = await _downloadAndSaveFile(
        imageToUse,
        'notification_img_${imageToUse.hashCode}',
      );
      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        largeIcon: FilePathAndroidBitmap(bigPicturePath),
        contentTitle: title,
        summaryText: body,
      );
    } catch (e) {
      debugPrint("Chic Notification Image failed: $e");
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          customSound != null ? 'sports_clubs_channel' : 'rafiq_metro_tourism',
          customSound != null ? 'Sports Club Alerts' : 'Metro Tourism Alerts',
          channelDescription: 'Notifications for nearby attractions',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
          sound: customSound != null
              ? RawResourceAndroidNotificationSound(customSound)
              : null,
          playSound: true,
        );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: customSound != null ? '$customSound.wav' : null,
          attachments: bigPicturePath != null
              ? [DarwinNotificationAttachment(bigPicturePath)]
              : null,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// إرسال تنبيه بوجود تأخير في أحد الخطوط
  static Future<void> showLineDelayAlert({
    required int lineNumber,
    required int delayMinutes,
    required bool isArabic,
  }) async {
    final String title = isArabic
        ? "⚠️ تنبيه تأخير: الخط $lineNumber"
        : "⚠️ Delay Alert: Line $lineNumber";
    final String body = isArabic
        ? "يوجد تأخير متوقع حوالي $delayMinutes دقائق. نأسف للإزعاج."
        : "Expect a delay of around $delayMinutes minutes. Sorry for the inconvenience.";

    await showNotification(
      id: 200 + lineNumber,
      title: title,
      body: body,
      imageUrl:
          "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=500", // صورة رمزية للتنبيه
    );
  }
}
