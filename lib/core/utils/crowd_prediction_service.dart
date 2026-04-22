import 'dart:math';

/// Crowd prediction service using time-of-day + day-of-week heuristics.
class CrowdPredictionService {
  // Returns 0.0 (empty) to 1.0 (jam-packed) crowd level
  static double getCrowdLevel({
    required int hour,
    required int weekday, // 1=Mon, 7=Sun
    required int lineNumber,
  }) {
    double base = _getHourlyBase(hour);
    double dayFactor = _getDayFactor(weekday);
    double lineFactor = _getLineFactor(lineNumber);
    return (base * dayFactor * lineFactor).clamp(0.0, 1.0);
  }

  static double _getHourlyBase(int hour) {
    // Peaks: 7–9 AM and 3–6 PM
    if (hour >= 7 && hour <= 9) return 0.85 + (0.15 * ((hour - 7) / 2));
    if (hour >= 10 && hour <= 12) return 0.55;
    if (hour >= 13 && hour <= 14) return 0.65;
    if (hour >= 15 && hour <= 18) return 0.80 + (0.15 * ((hour - 15) / 3));
    if (hour >= 19 && hour <= 21) return 0.50;
    if (hour >= 22 || hour <= 4) return 0.15;
    return 0.30; // Early morning 5–6 AM
  }

  static double _getDayFactor(int weekday) {
    if (weekday == 5) return 1.3; // Thursday highest
    if (weekday == 6) return 0.6; // Friday lower
    if (weekday == 7) return 0.75; // Saturday moderate
    return 1.0; // Mon–Wed standard
  }

  static double _getLineFactor(int line) {
    if (line == 2) return 1.15; // Line 2 most crowded (Shubra-Giza)
    if (line == 1) return 1.05; // Line 1 slightly above average
    return 0.90; // Line 3 newer, less crowded
  }

  static CrowdLevel getCrowdCategory(double level) {
    if (level >= 0.75) return CrowdLevel.high;
    if (level >= 0.45) return CrowdLevel.moderate;
    return CrowdLevel.low;
  }

  /// Returns crowd data for all hours of today for a given station line
  static List<HourlyCrowd> getDailyForecast({
    required int lineNumber,
    required int weekday,
  }) {
    return List.generate(24, (hour) {
      final level = getCrowdLevel(hour: hour, weekday: weekday, lineNumber: lineNumber);
      return HourlyCrowd(hour: hour, level: level);
    });
  }

  /// Best travel times (top 3 low-crowd hours in reasonable range 5 AM–11 PM)
  static List<int> getBestTravelHours({required int lineNumber, required int weekday}) {
    final forecast = getDailyForecast(lineNumber: lineNumber, weekday: weekday)
        .where((h) => h.hour >= 5 && h.hour <= 23)
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return forecast.take(3).map((h) => h.hour).toList();
  }

  static String getCrowdEmoji(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.high:
        return '😤';
      case CrowdLevel.moderate:
        return '😐';
      case CrowdLevel.low:
        return '😊';
    }
  }
}

enum CrowdLevel { low, moderate, high }

class HourlyCrowd {
  final int hour;
  final double level;
  HourlyCrowd({required this.hour, required this.level});
}
