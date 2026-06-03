/// Crowd prediction service using time-of-day + day-of-week heuristics.
///
/// Operating hours based on official Cairo Metro schedule:
///   Regular days (Sat–Thu): 05:00 – 01:00 (next day)
///   Friday only:            05:00 – 02:00 (next day)
class CrowdPredictionService {

  // ── Operating hours ──────────────────────────────────────────────────────

  /// Last service hour (inclusive) for the given weekday.
  static int getLastServiceHour(int weekday) {
    if (weekday == 5) return 2; // Friday: closes 02:00 AM (next day)
    return 1;                   // All others: closes 01:00 AM (next day)
  }

  /// Is the metro currently running for a given [hour] and [weekday]?
  /// Metro is CLOSED from the closing hour until 05:00 AM.
  static bool isMetroOpen({required int hour, required int weekday}) {
    final closingHour = getLastServiceHour(weekday);
    // e.g. regular day: closingHour=1 → closed when hour ∈ {1,2,3,4}
    if (hour >= closingHour && hour < 5) return false;
    return true;
  }

  /// Human-readable opening time.
  static String openingTime() => '05:00 ص';

  /// Human-readable closing time for a given weekday.
  static String closingTime(int weekday) {
    return weekday == 5 ? '02:00 ص (بعد منتصف الليل)' : '01:00 ص (بعد منتصف الليل)';
  }

  // ── Crowd level ──────────────────────────────────────────────────────────

  /// Returns 0.0–1.0 crowd level, or -1.0 if metro is closed.
  static double getCrowdLevel({
    required int hour,
    required int weekday, // 1=Mon … 7=Sun
    required int lineNumber,
  }) {
    if (!isMetroOpen(hour: hour, weekday: weekday)) return -1.0;
    final base       = _getHourlyBase(hour);
    final dayFactor  = _getDayFactor(weekday);
    final lineFactor = _getLineFactor(lineNumber);
    return (base * dayFactor * lineFactor).clamp(0.0, 1.0);
  }

  static double _getHourlyBase(int hour) {
    if (hour == 5) return 0.25;                                           // Opening ramp-up
    if (hour == 6) return 0.40;
    if (hour >= 7  && hour <= 9)  return 0.85 + (0.15 * ((hour - 7) / 2)); // Morning peak
    if (hour >= 10 && hour <= 12) return 0.55;                             // Mid-morning
    if (hour >= 13 && hour <= 14) return 0.65;                             // Midday
    if (hour >= 15 && hour <= 18) return 0.80 + (0.15 * ((hour - 15) / 3)); // Afternoon peak
    if (hour >= 19 && hour <= 21) return 0.50;                             // Evening wind-down
    if (hour == 22 || hour == 23 || hour == 0) return 0.20;               // Late night (still open)
    return 0.10; // Fallback for any closed-hour leakage
  }

  static double _getDayFactor(int weekday) {
    if (weekday == DateTime.thursday) return 1.3;  // Thursday: busiest day
    if (weekday == DateTime.friday) return 0.6;    // Friday: quieter
    if (weekday == DateTime.saturday) return 0.75; // Saturday: moderate
    return 1.0;                                    // Mon–Wed: standard
  }

  static double _getLineFactor(int line) {
    if (line == 2) return 1.15; // Line 2 (Shubra–Giza): most crowded
    if (line == 1) return 1.05; // Line 1: slightly above average
    return 0.90;                // Line 3 (newest): least crowded
  }

  static CrowdLevel getCrowdCategory(double level) {
    if (level >= 0.75) return CrowdLevel.high;
    if (level >= 0.45) return CrowdLevel.moderate;
    return CrowdLevel.low;
  }

  /// Returns crowd data for all 24 hours.
  /// Closed hours have [HourlyCrowd.isClosed] = true and level = 0.
  static List<HourlyCrowd> getDailyForecast({
    required int lineNumber,
    required int weekday,
  }) {
    return List.generate(24, (hour) {
      final closed = !isMetroOpen(hour: hour, weekday: weekday);
      final level  = closed ? 0.0 : getCrowdLevel(hour: hour, weekday: weekday, lineNumber: lineNumber);
      return HourlyCrowd(hour: hour, level: level, isClosed: closed);
    });
  }

  /// Best travel times: top 3 low-crowd hours WITHIN operating hours only.
  static List<int> getBestTravelHours({
    required int lineNumber,
    required int weekday,
  }) {
    final forecast = getDailyForecast(lineNumber: lineNumber, weekday: weekday)
        .where((h) => !h.isClosed)
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return forecast.take(3).map((h) => h.hour).toList();
  }

  static String getCrowdEmoji(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.high:     return '😤';
      case CrowdLevel.moderate: return '😐';
      case CrowdLevel.low:      return '😊';
    }
  }
}

enum CrowdLevel { low, moderate, high }

class HourlyCrowd {
  final int hour;
  final double level;
  final bool isClosed;
  HourlyCrowd({required this.hour, required this.level, this.isClosed = false});
}
