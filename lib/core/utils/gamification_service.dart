import 'package:shared_preferences/shared_preferences.dart';

enum BadgeType {
  firstTrip,
  explorer10,
  explorer50,
  explorer100,
  reporter,
  scheduler,
  nightOwl,
  earlyBird,
  goldUser,
  nfcPro,
  crowdChecker,
  aiUser,
}

class MetroBadge {
  final BadgeType type;
  final String icon;
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;
  final int requiredPoints;
  bool isUnlocked;

  MetroBadge({
    required this.type,
    required this.icon,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    required this.requiredPoints,
    this.isUnlocked = false,
  });
}

class GamificationService {
  static const String _pointsKey = 'user_points';
  static const String _tripsKey = 'user_trips';
  static const String _badgesKey = 'unlocked_badges';
  static const String _streakKey = 'daily_streak';
  static const String _lastActiveKey = 'last_active_date';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Points ─────────────────────────────────────────────────────────────────

  static int getPoints() => _prefs.getInt(_pointsKey) ?? 0;
  static int getTrips() => _prefs.getInt(_tripsKey) ?? 0;
  static int getStreak() => _prefs.getInt(_streakKey) ?? 0;

  static Future<int> addPoints(int amount) async {
    final current = getPoints();
    final newTotal = current + amount;
    await _prefs.setInt(_pointsKey, newTotal);
    await _checkAndUnlockBadges();
    return newTotal;
  }

  static Future<void> recordTrip() async {
    final current = getTrips();
    await _prefs.setInt(_tripsKey, current + 1);
    await addPoints(50);
    await _updateStreak();
    await _checkAndUnlockBadges();
  }

  static Future<void> recordRoutePlan() async => addPoints(20);
  static Future<void> recordReport() async => addPoints(30);
  static Future<void> recordSchedule() async => addPoints(15);
  static Future<void> recordAiQuery() async => addPoints(5);
  static Future<void> recordCrowdCheck() async => addPoints(10);
  static Future<void> recordNfcUse() async => addPoints(25);

  // ── Streak ─────────────────────────────────────────────────────────────────

  static Future<void> _updateStreak() async {
    final lastActive = _prefs.getString(_lastActiveKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastActive == null) {
      await _prefs.setInt(_streakKey, 1);
    } else {
      final last = DateTime.parse(lastActive);
      final diff = DateTime.now().difference(last).inDays;
      if (diff == 1) {
        await _prefs.setInt(_streakKey, getStreak() + 1);
      } else if (diff > 1) {
        await _prefs.setInt(_streakKey, 1);
      }
    }
    await _prefs.setString(_lastActiveKey, today);
  }

  // ── Badges ─────────────────────────────────────────────────────────────────

  static List<MetroBadge> getAllBadges() {
    final unlocked = _prefs.getStringList(_badgesKey) ?? [];
    return _badgeDefinitions.map((b) {
      b.isUnlocked = unlocked.contains(b.type.name);
      return b;
    }).toList();
  }

  static Future<List<MetroBadge>> _checkAndUnlockBadges() async {
    final points = getPoints();
    final trips = getTrips();
    final unlocked = _prefs.getStringList(_badgesKey) ?? [];
    final newlyUnlocked = <MetroBadge>[];

    for (final badge in _badgeDefinitions) {
      if (unlocked.contains(badge.type.name)) continue;

      bool shouldUnlock = false;
      switch (badge.type) {
        case BadgeType.firstTrip:
          shouldUnlock = trips >= 1;
          break;
        case BadgeType.explorer10:
          shouldUnlock = trips >= 10;
          break;
        case BadgeType.explorer50:
          shouldUnlock = trips >= 50;
          break;
        case BadgeType.explorer100:
          shouldUnlock = trips >= 100;
          break;
        case BadgeType.goldUser:
          shouldUnlock = points >= 500;
          break;
        case BadgeType.reporter:
          shouldUnlock = points >= 100;
          break;
        default:
          break;
      }

      if (shouldUnlock) {
        unlocked.add(badge.type.name);
        badge.isUnlocked = true;
        newlyUnlocked.add(badge);
      }
    }

    await _prefs.setStringList(_badgesKey, unlocked);
    return newlyUnlocked;
  }

  static Future<void> unlockBadge(BadgeType type) async {
    final unlocked = _prefs.getStringList(_badgesKey) ?? [];
    if (!unlocked.contains(type.name)) {
      unlocked.add(type.name);
      await _prefs.setStringList(_badgesKey, unlocked);
    }
  }

  /// Clears all gamification data (points, trips, badges, streak).
  static Future<void> reset() async {
    await _prefs.remove(_pointsKey);
    await _prefs.remove(_tripsKey);
    await _prefs.remove(_badgesKey);
    await _prefs.remove(_streakKey);
    await _prefs.remove(_lastActiveKey);
  }

  static String getCurrentLevel(int points) {
    if (points >= 2000) return 'بلاتيني';
    if (points >= 500) return 'ذهبي';
    if (points >= 200) return 'فضي';
    return 'برونزي';
  }

  static String getCurrentLevelEn(int points) {
    if (points >= 2000) return 'Platinum';
    if (points >= 500) return 'Gold';
    if (points >= 200) return 'Silver';
    return 'Bronze';
  }

  static int getNextLevelPoints(int points) {
    if (points >= 2000) return 2000;
    if (points >= 500) return 2000;
    if (points >= 200) return 500;
    return 200;
  }

  static final List<MetroBadge> _badgeDefinitions = [
    MetroBadge(
      type: BadgeType.firstTrip,
      icon: '🚇',
      nameAr: 'أول رحلة',
      nameEn: 'First Ride',
      descAr: 'سجلت أول رحلة!',
      descEn: 'Recorded your first trip!',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.explorer10,
      icon: '🗺️',
      nameAr: 'مستكشف',
      nameEn: 'Explorer',
      descAr: '10 رحلات مكتملة',
      descEn: '10 trips completed',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.explorer50,
      icon: '⭐',
      nameAr: 'نجم المترو',
      nameEn: 'Metro Star',
      descAr: '50 رحلة',
      descEn: '50 trips',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.explorer100,
      icon: '👑',
      nameAr: 'ملك المترو',
      nameEn: 'Metro King',
      descAr: '100 رحلة كاملة',
      descEn: '100 trips completed',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.reporter,
      icon: '📢',
      nameAr: 'مراسل ميداني',
      nameEn: 'Field Reporter',
      descAr: 'أبلغت عن أحداث في المحطات',
      descEn: 'Reported station incidents',
      requiredPoints: 100,
    ),
    MetroBadge(
      type: BadgeType.scheduler,
      icon: '📅',
      nameAr: 'منظم محترف',
      nameEn: 'Pro Scheduler',
      descAr: 'جدولت رحلاتك الأسبوعية',
      descEn: 'Scheduled your weekly trips',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.nightOwl,
      icon: '🦉',
      nameAr: 'بومة الليل',
      nameEn: 'Night Owl',
      descAr: 'سافرت بعد منتصف الليل',
      descEn: 'Traveled after midnight',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.earlyBird,
      icon: '🌅',
      nameAr: 'الطائر المبكر',
      nameEn: 'Early Bird',
      descAr: 'ركبت المترو قبل 7 صباحاً',
      descEn: 'Rode before 7 AM',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.goldUser,
      icon: '🥇',
      nameAr: 'مستخدم ذهبي',
      nameEn: 'Gold User',
      descAr: 'جمعت 500 نقطة',
      descEn: 'Collected 500 points',
      requiredPoints: 500,
    ),
    MetroBadge(
      type: BadgeType.nfcPro,
      icon: '💳',
      nameAr: 'خبير NFC',
      nameEn: 'NFC Pro',
      descAr: 'استخدمت محفظة NFC',
      descEn: 'Used the NFC wallet',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.crowdChecker,
      icon: '📊',
      nameAr: 'محلل الازدحام',
      nameEn: 'Crowd Analyst',
      descAr: 'تحققت من توقعات الازدحام',
      descEn: 'Checked crowd predictions',
      requiredPoints: 0,
    ),
    MetroBadge(
      type: BadgeType.aiUser,
      icon: '🤖',
      nameAr: 'صديق الذكاء الاصطناعي',
      nameEn: 'AI Friend',
      descAr: 'تحدثت مع رفيق الذكي',
      descEn: 'Chatted with Rafiq AI',
      requiredPoints: 0,
    ),
  ];
}
