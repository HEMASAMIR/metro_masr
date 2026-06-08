import 'package:shared_preferences/shared_preferences.dart';

enum BadgeType { aiUser, frequentRider, explorer, nfcPro }

class MetroBadge {
  final String icon;
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;
  final bool isUnlocked;

  MetroBadge({
    required this.icon,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    this.isUnlocked = false,
  });
}

class GamificationService {
  static Set<String> _discoveredPlaces = {};
  static int _points = 0;
  static int _trips = 0;
  static int _streak = 0;

  static const String _discoveredKey = 'discovered_places_ids';
  static const String _pointsKey = 'user_points';
  static const String _tripsKey = 'user_trips';
  static const String _streakKey = 'user_streak';

  /// جلب عدد الأماكن المكتشفة الفريدة
  static int get discoveredPlacesCount => _discoveredPlaces.length;

  static int getPoints() => _points;
  static int getTrips() => _trips;
  static int getStreak() => _streak;

  /// تهيئة الخدمة واستعادة البيانات المحفوظة
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_discoveredKey) ?? [];
    _discoveredPlaces = list.toSet();
    _points = prefs.getInt(_pointsKey) ?? 0;
    _trips = prefs.getInt(_tripsKey) ?? 0;
    _streak = prefs.getInt(_streakKey) ?? 0;
  }

  static Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// تسجيل اكتشاف مكان جديد وحفظه
  static Future<void> recordDiscovery(String id) async {
    if (!_discoveredPlaces.contains(id)) {
      _discoveredPlaces.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_discoveredKey, _discoveredPlaces.toList());
    }
  }

  static Future<void> recordTrip() async {
    _trips++;
    _points += 50; // 50 نقطة لكل رحلة
    await _saveInt(_tripsKey, _trips);
    await _saveInt(_pointsKey, _points);
  }

  static String getCurrentLevel(int pts) {
    if (pts >= 2000) return 'بلاتيني';
    if (pts >= 1000) return 'ذهبي';
    if (pts >= 500) return 'فضي';
    return 'برونزي';
  }

  static String getCurrentLevelEn(int pts) {
    if (pts >= 2000) return 'Platinum';
    if (pts >= 1000) return 'Gold';
    if (pts >= 500) return 'Silver';
    return 'Bronze';
  }

  static int getNextLevelPoints(int pts) {
    if (pts >= 2000) return 5000;
    if (pts >= 1000) return 2000;
    if (pts >= 500) return 1000;
    return 500;
  }

  static List<MetroBadge> getAllBadges() {
    return [
      MetroBadge(
        icon: '🤖',
        nameAr: 'صديق رفيق',
        nameEn: 'Rafiq Friend',
        descAr: 'سألت رفيق عن المترو لأول مرة',
        descEn: 'Asked Rafiq about metro for the first time',
        isUnlocked: _points > 10,
      ),
      MetroBadge(
        icon: '🚇',
        nameAr: 'راكب محترف',
        nameEn: 'Frequent Rider',
        descAr: 'سجلت 10 رحلات بالمترو',
        descEn: 'Recorded 10 metro trips',
        isUnlocked: _trips >= 10,
      ),
      MetroBadge(
        icon: '🗺️',
        nameAr: 'المكتشف',
        nameEn: 'The Explorer',
        descAr: 'اكتشفت 5 أماكن سياحية',
        descEn: 'Discovered 5 tourist attractions',
        isUnlocked: _discoveredPlaces.length >= 5,
      ),
      MetroBadge(
        icon: '💳',
        nameAr: 'خبير NFC',
        nameEn: 'NFC Pro',
        descAr: 'استخدمت محفظة المترو الرقمية',
        descEn: 'Used the digital metro wallet',
        isUnlocked: _points >= 150, // مثال لشرط الفتح
      ),
    ];
  }

  // دوال إضافية لمنع الأخطاء في الصفحة الرئيسية
  static Future<void> recordRoutePlan() async {
    _points += 20;
    await _saveInt(_pointsKey, _points);
  }

  static Future<void> recordAiQuery() async {
    _points += 5;
    await _saveInt(_pointsKey, _points);
  }

  static Future<void> recordNfcUse() async {
    _points += 30; // 30 نقطة لكل عملية استخدام NFC
    await _saveInt(_pointsKey, _points);
  }

  static Future<void> recordDailyOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastOpen = prefs.getString('last_open_date');

    if (lastOpen != todayStr) {
      _points += 10; // مكافأة يومية
      await prefs.setString('last_open_date', todayStr);
      await _saveInt(_pointsKey, _points);
    }
  }

  static Future<void> recordSchedule() async {
    _points += 15; // نقاط عند جدولة رحلة
    await _saveInt(_pointsKey, _points);
  }

  static void unlockBadge(BadgeType type) {
    // منطق فتح الشارات
  }

  /// إعادة تعيين كافة البيانات (تصفير النقط والإنجازات)
  static Future<void> reset() async {
    _points = 0;
    _trips = 0;
    _streak = 0;
    _discoveredPlaces = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, 0);
    await prefs.setInt(_tripsKey, 0);
    await prefs.setInt(_streakKey, 0);
    await prefs.setStringList(_discoveredKey, []);
    await prefs.remove('last_open_date');
  }
}
