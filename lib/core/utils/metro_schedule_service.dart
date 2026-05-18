// Cairo Metro Train Schedule Service
// Based on official Cairo Metro operating data:
//   - Operating hours: 05:00 – 00:00 (midnight)
//   - Rush hours: 07:00–09:00 & 14:00–18:00 (weekdays)
//   - Friday/Saturday: slightly less frequent (prayer + weekend)
//
// Since there is no public real-time API yet, we use the published
// headway (interval between trains) to calculate the expected next
// departure from any station.


class MetroSchedule {
  // ── Operating window ──────────────────────────────────────────────────────
  static const int _openHour = 5;   // 05:00
  static const int _closeHour = 0;  // 00:00 (midnight)  → treated as 24

  // ── Headways in minutes (average interval between trains) ─────────────────
  // Source: Cairo Metro Authority published timetables & field observations
  static const Map<int, _LineHeadway> _headways = {
    1: _LineHeadway(rushMin: 3, peakMin: 5, offPeakMin: 7, lateMin: 10),
    2: _LineHeadway(rushMin: 4, peakMin: 6, offPeakMin: 8, lateMin: 12),
    3: _LineHeadway(rushMin: 5, peakMin: 7, offPeakMin: 9, lateMin: 14),
  };

  // ─────────────────────────────────────────────────────────────────────────
  /// Returns the result for [lineNumber] at the given [now] time.
  static MetroTrainResult getNextTrain({
    required int lineNumber,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final h = _LineHeadway._for(lineNumber);

    // ── Check operating hours ─────────────────────────────────────────────
    if (!_isOperating(t)) {
      final opensAt = _nextOpenTime(t);
      return MetroTrainResult.closed(opensAt: opensAt);
    }

    // ── Determine headway ─────────────────────────────────────────────────
    final headwayMins = _headwayFor(t, h, lineNumber);

    // ── Calculate minutes to next train ───────────────────────────────────
    // We treat trains as running on a fixed headway clock starting from
    // the opening hour, so the next departure is deterministic (no random).
    final minutesSinceOpen = _minutesSinceOpen(t);
    final waitMins = headwayMins - (minutesSinceOpen % headwayMins);
    // Clamp: if waitMins == headwayMins it means we just left → 0 shows as headway
    final displayWait = waitMins == headwayMins ? 1 : waitMins;

    final nextDeparture = t.add(Duration(minutes: displayWait));

    return MetroTrainResult.arriving(
      waitMinutes: displayWait,
      headwayMinutes: headwayMins,
      nextDeparture: nextDeparture,
      periodLabel: _periodLabel(t, lineNumber),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _isOperating(DateTime t) {
    final h = t.hour;
    // Closes at midnight (0), opens at 5
    if (h >= _openHour) return true;      // 05:00 – 23:59
    if (h < _closeHour) return false;     // 00:00 – 04:59 → closed
    return h == _closeHour;               // exactly midnight → still open (last train)
  }

  static DateTime _nextOpenTime(DateTime t) {
    // If it's before 05:00 → same day at 05:00
    // If it's after midnight closing → next day at 05:00
    final candidate = DateTime(t.year, t.month, t.day, _openHour);
    if (candidate.isAfter(t)) return candidate;
    return candidate.add(const Duration(days: 1));
  }

  static int _minutesSinceOpen(DateTime t) {
    final open = DateTime(t.year, t.month, t.day, _openHour);
    return t.difference(open).inMinutes.clamp(0, 1140); // max 19 hrs
  }

  static int _headwayFor(DateTime t, _LineHeadway h, int line) {
    final hour = t.hour;
    final isWeekend = t.weekday == DateTime.friday || t.weekday == DateTime.saturday;

    // Rush hours (weekdays only)
    final isRush = !isWeekend &&
        ((hour >= 7 && hour <= 9) || (hour >= 14 && hour <= 18));

    // Morning / afternoon peak (still busy but not rush)
    final isPeak = (hour >= 10 && hour <= 13) || (hour >= 19 && hour <= 21);

    // Late night (22:00 – midnight)
    final isLate = hour >= 22;

    if (isRush) return isWeekend ? h.peakMin : h.rushMin;
    if (isPeak) return h.peakMin;
    if (isLate) return h.lateMin;
    return h.offPeakMin;
  }

  static String _periodLabel(DateTime t, int line) {
    final h = t.hour;
    final isWeekend = t.weekday == DateTime.friday || t.weekday == DateTime.saturday;
    if ((h >= 7 && h <= 9 || h >= 14 && h <= 18) && !isWeekend) return 'rush';
    if ((h >= 10 && h <= 13) || (h >= 19 && h <= 21)) return 'peak';
    if (h >= 22) return 'late';
    return 'offPeak';
  }
}

// ── Internal headway model ────────────────────────────────────────────────────
class _LineHeadway {
  final int rushMin;      // Rush hour interval (minutes)
  final int peakMin;      // Peak (busy but not rush)
  final int offPeakMin;   // Normal off-peak
  final int lateMin;      // Late night (fewer trains)

  const _LineHeadway({
    required this.rushMin,
    required this.peakMin,
    required this.offPeakMin,
    required this.lateMin,
  });

  static _LineHeadway _for(int line) {
    return MetroSchedule._headways[line] ??
        const _LineHeadway(rushMin: 5, peakMin: 7, offPeakMin: 9, lateMin: 14);
  }
}

// ── Result model ──────────────────────────────────────────────────────────────
class MetroTrainResult {
  final bool isOperating;

  /// Minutes until the next train (null if closed)
  final int? waitMinutes;

  /// Interval between trains for this period
  final int? headwayMinutes;

  /// Actual clock time of next departure
  final DateTime? nextDeparture;

  /// 'rush' | 'peak' | 'offPeak' | 'late' | 'closed'
  final String periodLabel;

  /// Time metro opens next (only when closed)
  final DateTime? opensAt;

  const MetroTrainResult._({
    required this.isOperating,
    this.waitMinutes,
    this.headwayMinutes,
    this.nextDeparture,
    required this.periodLabel,
    this.opensAt,
  });

  factory MetroTrainResult.arriving({
    required int waitMinutes,
    required int headwayMinutes,
    required DateTime nextDeparture,
    required String periodLabel,
  }) =>
      MetroTrainResult._(
        isOperating: true,
        waitMinutes: waitMinutes,
        headwayMinutes: headwayMinutes,
        nextDeparture: nextDeparture,
        periodLabel: periodLabel,
      );

  factory MetroTrainResult.closed({required DateTime opensAt}) =>
      MetroTrainResult._(
        isOperating: false,
        periodLabel: 'closed',
        opensAt: opensAt,
      );

  // ── Display helpers ───────────────────────────────────────────────────────

  /// Short Arabic/English wait label shown on cards
  String waitLabel(String lang) {
    if (!isOperating) {
      final h = opensAt!.hour.toString().padLeft(2, '0');
      final m = opensAt!.minute.toString().padLeft(2, '0');
      return lang == 'ar' ? 'يفتح $h:$m' : 'Opens $h:$m';
    }
    final w = waitMinutes!;
    if (w <= 1) return lang == 'ar' ? 'الآن 🟢' : 'Now 🟢';
    return lang == 'ar' ? '~$w د' : '~$w min';
  }

  /// Color hint for the wait badge
  TrainWaitLevel get waitLevel {
    if (!isOperating) return TrainWaitLevel.closed;
    final w = waitMinutes ?? 99;
    if (w <= 2) return TrainWaitLevel.now;
    if (w <= 5) return TrainWaitLevel.soon;
    if (w <= 10) return TrainWaitLevel.coming;
    return TrainWaitLevel.later;
  }

  /// Human-readable period (Arabic / English)
  String periodDisplay(String lang) {
    switch (periodLabel) {
      case 'rush':
        return lang == 'ar' ? '⚡ ساعة الذروة' : '⚡ Rush Hour';
      case 'peak':
        return lang == 'ar' ? '🔶 وقت مزدحم' : '🔶 Busy Period';
      case 'late':
        return lang == 'ar' ? '🌙 آخر الليل' : '🌙 Late Night';
      case 'closed':
        return lang == 'ar' ? '🔴 خارج الخدمة' : '🔴 Out of Service';
      default:
        return lang == 'ar' ? '🟢 تشغيل عادي' : '🟢 Normal Service';
    }
  }

  /// Headway description (e.g. "كل 4 دقايق")
  String headwayDisplay(String lang) {
    if (!isOperating || headwayMinutes == null) return '';
    return lang == 'ar'
        ? 'قطار كل ${headwayMinutes!} د'
        : 'Train every ${headwayMinutes!} min';
  }
}

enum TrainWaitLevel { now, soon, coming, later, closed }
