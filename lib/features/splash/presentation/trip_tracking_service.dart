import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/utils/notification_service.dart';
import 'package:rafiq_metrro/core/utils/voice_service.dart';
import 'package:rafiq_metrro/features/metro/domain/entities/station.dart';

/// خدمة تتبع الرحلة والتنبيه التلقائي قبل الوصول بمحطتين
class TripTrackingService {
  static final TripTrackingService instance = TripTrackingService._internal();
  TripTrackingService._internal();

  StreamSubscription<Position>? _positionStream;
  List<Station>? _currentPath;
  bool _hasWarnedPreArrival = false;
  bool _hasWarnedFinalArrival = false;
  Timer? _alarmTimer; // التايمر المسؤول عن "الزن"

  /// ابدأ تتبع الرحلة أوتوماتيكياً
  Future<void> startTracking(List<Station> path) async {
    if (path.length < 2) return;

    // تصحيح حالة التتبع
    _currentPath = path;
    _hasWarnedPreArrival = false;
    _hasWarnedFinalArrival = false;
    _stopAlarm();
    _stopStream();

    // إعدادات تتبع الموقع (دقة عالية لاكتشاف المحطات)
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 50, // تحديث كل 50 متر
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _checkProximity(position);
          },
        );
  }

  void _checkProximity(Position pos) {
    if (_currentPath == null || _currentPath!.isEmpty) return;

    final destination = _currentPath!.last;

    // 1. تحديد محطة التنبيه (قبل الوصول بمحطتين)
    // إذا كانت الرحلة [أ، ب، ج، د، هـ] والوصول هـ، التنبيه يكون عند "ج"
    int triggerIndex = _currentPath!.length - 3;
    if (triggerIndex < 0)
      triggerIndex = 0; // لو الرحلة قصيرة جداً نبه من أول محطة

    final triggerStation = _currentPath![triggerIndex];

    // حساب المسافة للمحطة "Trigger"
    double distanceToTrigger = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      triggerStation.latitude,
      triggerStation.longitude,
    );

    // حساب المسافة لمحطة الوصول النهائية
    double distanceToFinal = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      destination.latitude,
      destination.longitude,
    );

    // تنبيه قبل الوصول بمحطتين (لو المسافة أقل من 500 متر من محطة التنبيه)
    if (!_hasWarnedPreArrival && distanceToTrigger < 500) {
      _hasWarnedPreArrival = true;

      final voiceMsg =
          "نحن الآن في محطة ${triggerStation.nameAr}. متبقي محطتان للوصول إلى ${destination.nameAr}. استعد للنزول!";

      // تشغيل التنبيه فوراً
      _triggerPersistentAlert(voiceMsg);

      // بدأ "الزن" - تكرار التنبيه كل 10 ثواني لحد ما المستخدم يسكته
      _alarmTimer?.cancel();
      _alarmTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        // لو وصل للمحطة النهائية خلاص نوقف الزن
        if (_hasWarnedFinalArrival) {
          timer.cancel();
          return;
        }

        // لو لسه موصلش، يفضل يزن بالصوت والإشعارات
        _triggerPersistentAlert(
          "تنبيه! متبقي محطتان على ${destination.nameAr}. يرجى الاستعداد.",
        );
      });
    }

    // تنبيه الوصول النهائي
    if (!_hasWarnedFinalArrival && distanceToFinal < 300) {
      _hasWarnedFinalArrival = true;

      VoiceService.speak(
        "وصلنا إلى محطة ${destination.nameAr}. حمد الله على السلامة!",
        'ar',
      );

      NotificationService.showNotification(
        id: NotificationService.arrivalNotifId,
        title: "وصلنا بالسلامة! 🎉".tr(),
        body: "إنت دلوقتي في محطة ${destination.nameAr}. حمد الله على السلامة!",
      );
      _stopStream(); // وقف التتبع طالما وصلنا
    }
  }

  /// دالة لإرسال الإشعار وتشغيل الصوت
  void _triggerPersistentAlert(String msg) {
    VoiceService.speak(msg, 'ar');

    NotificationService.showNotification(
      id: NotificationService.arrivalNotifId,
      title: "⚠️ تنبيه اقتراب الوصول".tr(),
      body: msg,
    );
  }

  /// دالة بكلمها من الـ UI لما المستخدم يدوس "كتم التنبيه"
  void silenceAlarm() {
    _stopAlarm();
  }

  void _stopAlarm() {
    _alarmTimer?.cancel();
    _alarmTimer = null;
  }

  void _stopStream() {
    _positionStream?.cancel();
    _positionStream = null;
    _stopAlarm();
  }

  void stopTracking() => _stopStream();
}
