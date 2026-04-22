import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import '../../features/metro/domain/entities/station.dart';

class AiPrediction {
  final String crowdLevel; // 'low', 'medium', 'high'
  final int expectedDelayMinutes;
  final DateTime bestTravelTime;
  final int savedMinutes;
  final String recommendationAr;
  final String recommendationEn;

  AiPrediction({
    required this.crowdLevel,
    required this.expectedDelayMinutes,
    required this.bestTravelTime,
    required this.savedMinutes,
    required this.recommendationAr,
    required this.recommendationEn,
  });
}

class AiPredictionService {
  static AiPrediction predict(List<Station> path, DateTime travelTime) {
    if (path.isEmpty) {
      return AiPrediction(
        crowdLevel: 'low',
        expectedDelayMinutes: 0,
        bestTravelTime: travelTime,
        savedMinutes: 0,
        recommendationAr: 'سافر الآن، الطريق مفتوح!',
        recommendationEn: 'Travel now, the route is clear!',
      );
    }

    // Evaluate delay and crowd level for a given time
    _PredictionData evalTime(DateTime time) {
      final isWeekend = time.weekday == DateTime.friday || time.weekday == DateTime.saturday;
      final hour = time.hour;

      bool isMorningRush = hour >= 7 && hour <= 9;
      bool isAfternoonRush = hour >= 14 && hour <= 17;
      bool isRushHour = !isWeekend && (isMorningRush || isAfternoonRush);

      int stationMultiplier = path.length < 5 ? 1 : (path.length ~/ 5);
      
      if (isRushHour) {
        return _PredictionData('high', 10 + (stationMultiplier * 3));
      } else if ((hour >= 10 && hour <= 13) || (hour >= 18 && hour <= 21)) {
        return _PredictionData('medium', 2 + (stationMultiplier * 1));
      } else {
        return _PredictionData('low', 0); // No significant delay
      }
    }

    final currentData = evalTime(travelTime);
    
    // Find optimal time within the next 3 hours
    DateTime optimalTime = travelTime;
    _PredictionData optimalData = currentData;

    for (int i = 1; i <= 6; i++) {
      // Check every 30 minutes for the next 3 hours
      final futureTime = travelTime.add(Duration(minutes: 30 * i));
      if (futureTime.hour >= 24) break; // Midnight
      
      final futureData = evalTime(futureTime);
      if (futureData.delay < optimalData.delay) {
        optimalData = futureData;
        optimalTime = futureTime;
      }
      if (optimalData.delay == 0) break; // Found best possible time
    }

    int saved = currentData.delay - optimalData.delay;
    String recAr;
    String recEn;
    
    if (saved > 0) {
      final tFormat = DateFormat('hh:mm a');
      final recTime = tFormat.format(optimalTime);
      final nowTime = tFormat.format(travelTime);
      recAr = 'سافر $recTime مش $nowTime هتوفر $saved دقيقة';
      recEn = 'Travel at $recTime not $nowTime, you will save $saved minutes';
    } else {
      recAr = 'الوقت الحالي ممتاز جداً للسفر!';
      recEn = 'Current time is excellent for traveling!';
    }

    return AiPrediction(
      crowdLevel: currentData.crowdLevel,
      expectedDelayMinutes: currentData.delay + Random().nextInt(3),
      bestTravelTime: optimalTime,
      savedMinutes: saved > 0 ? saved : 0,
      recommendationAr: recAr,
      recommendationEn: recEn,
    );
  }
}

class _PredictionData {
  final String crowdLevel;
  final int delay;
  _PredictionData(this.crowdLevel, this.delay);
}
