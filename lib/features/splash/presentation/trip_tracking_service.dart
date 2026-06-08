import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/utils/notification_service.dart';
import 'package:rafiq_metrro/core/utils/voice_service.dart';
import 'package:rafiq_metrro/core/utils/tourism_data.dart';
import 'package:rafiq_metrro/core/utils/gamification_service.dart';
import 'package:rafiq_metrro/features/metro/domain/entities/station.dart';

/// خدمة تتبع الرحلة والتنبيه التلقائي قبل الوصول بمحطتين
class TripTrackingService {
  static final TripTrackingService instance = TripTrackingService._internal();
  TripTrackingService._internal();

  StreamSubscription<Position>? _positionStream;
  List<Station>? _currentPath;
  bool _hasWarnedPreArrival = false;
  bool _hasWarnedFinalArrival = false;
  final Set<String> _notifiedTourismStations =
      {}; // لمنع تكرار التنبيه لنفس المحطة في نفس الرحلة
  Timer? _alarmTimer; // التايمر المسؤول عن "الزن"

  /// ابدأ تتبع الرحلة أوتوماتيكياً
  Future<void> startTracking(List<Station> path) async {
    try {
      if (path.length < 2) return;

      // التحقق من صلاحيات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;
    } catch (e) {
      return;
    }

    // تصحيح حالة التتبع
    _currentPath = path;
    _hasWarnedPreArrival = false;
    _hasWarnedFinalArrival = false;
    _notifiedTourismStations.clear();
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

    // أولاً: فحص الأماكن السياحية القريبة في كل المحطات اللي بنعدي عليها
    _checkNearbyAttractions(pos);

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

  /// فحص إذا كان المستخدم يقترب من محطة بها معالم سياحية
  void _checkNearbyAttractions(Position pos) {
    if (_currentPath == null) return;

    for (var station in _currentPath!) {
      // لو نبهنا عنها قبل كدة في الرحلة دي خلاص
      if (_notifiedTourismStations.contains(station.id)) continue;

      double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        station.latitude,
        station.longitude,
      );

      final tourismData = TourismDatabase.findByStation(station.id);
      if (tourismData == null || tourismData.attractions.isEmpty) continue;

      // تحديد مسافة التنبيه: 1 كم لو فيه نادي رياضي، و 400 متر لأي حاجة تانية
      bool hasSport = tourismData.attractions.any(
        (a) => a.category == AttractionCategory.sport,
      );
      double alertThreshold = hasSport ? 1000.0 : 400.0;

      // لو المسافة أقل من الحد المسموح، نبه المستخدم
      if (distance < alertThreshold) {
        _notifiedTourismStations.add(station.id);

        // تسجيل كل المعالم في المحطة كأماكن مكتشفة في نظام الجوائز
        for (var attraction in tourismData.attractions) {
          GamificationService.recordDiscovery(attraction.id);
        }

        // البحث عن أول نادي رياضي (Sport) في المعالم القريبة من هذه المحطة
        final featured = tourismData.attractions.firstWhere(
          (a) => a.category == AttractionCategory.sport,
          orElse: () => tourismData.attractions.first,
        );

        final isSport = featured.category == AttractionCategory.sport;
        final msg = isSport
            ? "يا بطل، إنت دلوقتي عند محطة ${station.nameAr}. عارف إنك قريب من ${featured.name['ar']} ${featured.emoji}؟ لو حابب تروح النادي، ده أنسب وقت!"
            : "يا بطل، إنت دلوقتي عند محطة ${station.nameAr}. عارف إن فيه هنا ${featured.name['ar']} ${featured.emoji}؟ ده على بعد ${featured.walkingMinutes} دقايق بس.";

        NotificationService.showNotification(
          id: station.id.hashCode, // ID فريد لكل محطة
          title: isSport ? "🏆 نادي رياضي قريب" : "💡 معلومة سياحية سريعة",
          body: msg,
          imageUrl: featured.effectiveImageUrl, // إظهار صورة المعلم في الإشعار
          customSound: isSport ? 'club_alert' : null, // تشغيل صوت خاص بالنوادي
        );

        // اهتزاز مخصص للنوادي الرياضية (نبضتين قويتين)
        if (isSport) {
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
        }

        VoiceService.speak(msg, 'ar');
      }
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
