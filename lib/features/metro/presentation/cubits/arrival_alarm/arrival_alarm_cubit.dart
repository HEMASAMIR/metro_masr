import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rafiq_metrro/core/utils/location_utils.dart';
import 'package:rafiq_metrro/core/utils/notification_service.dart';
import 'package:rafiq_metrro/core/utils/voice_service.dart';

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
  const ArrivalAlarmActive(this.destination, this.alertStation);
  @override
  List<Object?> get props => [destination, alertStation];
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

  /// Starts the alarm based on the user's computed route.
  /// It identifies the station *before* the destination to alert the user early.
  void startAlarm(List<Station> path) {
    if (path.isEmpty) return;
    
    final destination = path.last;
    // The station immediately before the destination (or destination if only 1 station)
    final alertStation = path.length > 1 ? path[path.length - 2] : destination;

    emit(ArrivalAlarmActive(destination, alertStation));

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
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

      // Trigger if we are within 500 meters of the ALERT station, which is ONE station before destination.
      if (distanceToAlertStation < 500) { 
        _triggerAlarm(destination, alertStation);
      }
    });
  }

  void _triggerAlarm(Station destination, Station alertStation) {
    // We can infer language from context in UI, but here we'll use tr() keys.
    // If the alertStation is the destination itself, text varies.
    final bool isSame = destination.id == alertStation.id;
    
    final title = isSame ? 'وصول وشيك!' : 'تنبيه ذكي: المحطة القادمة هي وجهتك!';
    final body = isSame 
        ? 'لقد اقتربت من محطة ${destination.nameAr}'
        : 'استعد! محطتك (${destination.nameAr}) هي المحطة التالية بعد ${alertStation.nameAr}.';

    NotificationService.showNotification(
      id: 1,
      title: title,
      body: body,
    );
    // Voice prompt
    VoiceService.speak(body, 'ar'); // Fallback to ar, ideally we'd pass locale

    emit(ArrivalAlarmTriggered(destination));
    stopAlarm();
  }

  void stopAlarm() {
    _positionStream?.cancel();
    _positionStream = null;
    emit(ArrivalAlarmInitial());
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}
