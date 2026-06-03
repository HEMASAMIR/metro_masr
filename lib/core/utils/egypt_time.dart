import 'package:easy_localization/easy_localization.dart';

class EgyptTime {
  /// Returns the current date/time adjusted to Egypt local time (GMT+2 / GMT+3 DST).
  static DateTime getEgyptTime() {
    final now = DateTime.now();
    final utc = now.toUtc();
    
    // Standard Egypt offset is +2.
    // DST offset is +3.
    // Egypt DST starts on the last Friday of April and ends on the last Thursday of October.
    bool isDst = false;
    final year = utc.year;
    
    if (utc.month > 4 && utc.month < 10) {
      isDst = true;
    } else if (utc.month == 4) {
      // Find the last Friday of April
      int lastFriday = 30;
      while (DateTime(year, 4, lastFriday).weekday != DateTime.friday) {
        lastFriday--;
      }
      if (utc.day > lastFriday || (utc.day == lastFriday && utc.hour >= 0)) {
        isDst = true;
      }
    } else if (utc.month == 10) {
      // Find the last Thursday of October
      int lastThursday = 31;
      while (DateTime(year, 10, lastThursday).weekday != DateTime.thursday) {
        lastThursday--;
      }
      if (utc.day < lastThursday || (utc.day == lastThursday && utc.hour < 23)) {
        isDst = true;
      }
    }
    
    final offset = isDst ? 3 : 2;
    return utc.add(Duration(hours: offset));
  }

  /// Formats Egypt time beautifully (12-hour AM/PM format)
  static String formatTime(DateTime dateTime, {String locale = 'ar'}) {
    return DateFormat('hh:mm a', locale).format(dateTime);
  }
}
