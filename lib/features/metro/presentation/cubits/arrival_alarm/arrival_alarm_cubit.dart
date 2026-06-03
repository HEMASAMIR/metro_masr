import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rafiq_metrro/core/utils/location_utils.dart';
import 'package:rafiq_metrro/core/utils/notification_service.dart';
import 'package:rafiq_metrro/core/utils/voice_service.dart';
import 'package:vibration/vibration.dart';

import '../../../domain/entities/station.dart';

abstract class ArrivalAlarmState extends Equatable {
  const ArrivalAlarmState();
  @override
  List<Object?> get props => [];
}

class ArrivalAlarmInitial extends ArrivalAlarmState {}

class ArrivalAlarmActive extends ArrivalAlarmState {
  final Station destination;
  final Station alertStation;
  final int stationsEarly;
  final String lang;
  const ArrivalAlarmActive(
    this.destination,
    this.alertStation, {
    this.stationsEarly = 1,
    this.lang = 'ar',
  });
  @override
  List<Object?> get props => [destination, alertStation, stationsEarly, lang];
}

class ArrivalAlarmTriggered extends ArrivalAlarmState {
  final Station destination;
  const ArrivalAlarmTriggered(this.destination);
  @override
  List<Object?> get props => [destination];
}

class ArrivalAlarmCubit extends Cubit<ArrivalAlarmState> {
  ArrivalAlarmCubit() : super(ArrivalAlarmInitial());

  StreamSubscription<Position>? _positionStream;
  Timer? _alarmTimer;

  /// Starts the alarm based on the user's computed route.
  /// It identifies the station before the destination based on stationsEarly setting to alert the user.
  void startAlarm(
    List<Station> path, {
    int stationsEarly = 1,
    String lang = 'ar',
  }) {
    if (path.isEmpty) return;

    final destination = path.last;
    // Calculate the alert station index based on preference
    int alertIndex = path.length - 1 - stationsEarly;
    if (alertIndex < 0)
      alertIndex = 0; // fallback if path is shorter than chosen stops

    final alertStation = path[alertIndex];

    emit(
      ArrivalAlarmActive(
        destination,
        alertStation,
        stationsEarly: stationsEarly,
        lang: lang,
      ),
    );

    _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((position) {
          final distanceToAlertStation = LocationUtils.calculateDistance(
            position.latitude,
            position.longitude,
            alertStation.latitude,
            alertStation.longitude,
          );

          // Trigger if we are within 500 meters of the ALERT station.
          if (distanceToAlertStation < 500) {
            _triggerAlarm(path, destination, alertStation, stationsEarly, lang);
          }
        });
  }

  void _triggerAlarm(
    List<Station> path,
    Station destination,
    Station alertStation,
    int stationsEarly,
    String lang,
  ) {
    // Cancel location tracking once triggered
    _positionStream?.cancel();
    _positionStream = null;

    final int alertIndex = path.indexOf(alertStation);
    final int remaining = alertIndex != -1
        ? (path.length - 1 - alertIndex)
        : stationsEarly;
    final Station? nextStation =
        (alertIndex != -1 && alertIndex < path.length - 1)
        ? path[alertIndex + 1]
        : null;

    // Create the alert title & body
    final String title;
    final String body;

    if (lang == 'ar') {
      final String remainingStr = remaining == 1
          ? 'محطة واحدة'
          : remaining == 2
          ? 'محطتان'
          : '$remaining محطات';

      final String nextStr = nextStation != null
          ? 'المحطة القادمة هي ${nextStation.nameAr}.'
          : '';

      title = '⏰ تنبيه اقتراب الوصول!';
      body =
          'اصحى! متبقي $remainingStr للوصول إلى محطة ${destination.nameAr}. $nextStr استعد للنزول.';
    } else {
      final String remainingStr = remaining == 1
          ? '1 station'
          : '$remaining stations';
      final String nextStr = nextStation != null
          ? 'The next station is ${nextStation.nameEn}.'
          : '';

      title = '⏰ Arrival Alert!';
      body =
          'Wake up! $remainingStr left to reach ${destination.nameEn}. $nextStr Please prepare to get off.';
    }

    emit(ArrivalAlarmTriggered(destination));

    // Show initial notification
    NotificationService.showNotification(id: 1, title: title, body: body);

    // Speak and vibrate immediately
    _playVibrationAndVoice(body, lang);

    // Set up periodic timer to repeat every 8 seconds until silenced
    _alarmTimer?.cancel();
    _alarmTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      NotificationService.showNotification(id: 1, title: title, body: body);
      _playVibrationAndVoice(body, lang);
    });
  }

  void _playVibrationAndVoice(String message, String lang) {
    // TTS-only: speak the message first
    VoiceService.speak(message, lang);

    // Extremely strong hardware vibration pattern to wake user up
    Vibration.hasCustomVibrationsSupport().then((hasCustom) {
      if (hasCustom == true) {
        Vibration.vibrate(
          pattern: [0, 1500, 500, 1500, 500, 1500, 500, 2000],
          intensities: [0, 255, 0, 255, 0, 255, 0, 255],
        );
      } else {
        Vibration.vibrate(duration: 5000);
      }
    });
  }

  void stopAlarm() {
    _positionStream?.cancel();
    _positionStream = null;
    _alarmTimer?.cancel();
    _alarmTimer = null;
    VoiceService.stop();
    emit(ArrivalAlarmInitial());
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    _alarmTimer?.cancel();
    return super.close();
  }
}
