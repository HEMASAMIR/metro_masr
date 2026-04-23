import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/gamification_service.dart';

// ─── Main Page ────────────────────────────────────────────────────────────────
class ImpactDashboardPage extends StatefulWidget {
  const ImpactDashboardPage({super.key});

  @override
  State<ImpactDashboardPage> createState() => _ImpactDashboardPageState();
}

class _ImpactDashboardPageState extends State<ImpactDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _counterController;
  late AnimationController _networkController;
  late AnimationController _cardController;

  // Live user stats
  int _userPoints = 0;
  int _userTrips = 0;
  int _userBadges = 0;
  double _userSavings = 0;

  // Egypt metro network data (real)
  static const _networkStats = [
    _StatData('85',  'محطة',          'Stations',       Icons.place_rounded,         Color(0xFF4F8AFF)),
    _StatData('3',   'خطوط',           'Lines',          Icons.linear_scale_rounded,  Color(0xFF20C997)),
    _StatData('120', 'كيلومتر',        'Kilometers',     Icons.straighten_rounded,    Color(0xFFFFB800)),
    _StatData('3.5M','راكب يومياً',    'Daily Riders',   Icons.people_rounded,        Color(0xFFFF6B6B)),
    _StatData('1987','سنة التأسيس',    'Founded',        Icons.history_rounded,       Color(0xFFBF5AF2)),
    _StatData('19',  'محطة تبادل',     'Transfer Hubs',  Icons.swap_horiz_rounded,    Color(0xFF00D4FF)),
  ];

  static const _appFeatures = [
    ('🗺️', 'خريطة تفاعلية',      'Interactive Map'),
    ('🤖', 'مساعد ذكاء اصطناعي','AI Assistant'),
    ('📊', 'توقع الازدحام',      'Crowd Forecast'),
    ('🏆', 'نظام الإنجازات',     'Gamification'),
    ('📅', 'جداول الرحلات',      'Trip Scheduler'),
    ('💳', 'حاسبة التكلفة',      'Cost Calculator'),
    ('🆘', 'خدمات الطوارئ',      'Emergency SOS'),
    ('🎙️', 'تحكم صوتي',         'Voice Commands'),
    ('📡', 'المجتمع الحي',       'Live Community'),
    ('💡', 'مفقودات المترو',     'Lost & Found'),
    ('🔔', 'إنذار الوصول',       'Arrival Alarm'),
    ('🌐', '4 لغات',             '4 Languages'),
  ];

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
    _counterController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2500));
    _networkController = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))..repeat();
    _cardController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));

    _loadStats();
    _startAnimSequence();
  }

  Future<void> _loadStats() async {
    await GamificationService.init();
    final badges = GamificationService.getAllBadges()
        .where((b) => b.isUnlocked)
        .length;
    final trips = GamificationService.getTrips();
    final points = GamificationService.getPoints();
    // Estimate savings: avg 10 EGP / trip * 0.4 hypothetical subscription saving
    final savings = trips * 4.0;
    setState(() {
      _userPoints  = points;
      _userTrips   = trips;
      _userBadges  = badges;
      _userSavings = savings;
    });
  }

  Future<void> _startAnimSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _heroController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _counterController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _cardController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _counterController.dispose();
    _networkController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E27),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(isAr, size),
            ),
            title: AnimatedBuilder(
              animation: _heroController,
              builder: (_, __) => Opacity(
                opacity: _heroController.value,
                child: Text(
                  isAr ? 'رفيق خدم مصر 🇪🇬' : 'Rafiq Served Egypt 🇪🇬',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Network stats grid ──────────────────────────────────────
                _buildSectionTitle(isAr ? '🚇 شبكة مترو القاهرة' : '🚇 Cairo Metro Network', isAr),
                _buildNetworkGrid(isAr),

                // ── Live Egypt metro map ─────────────────────────────────────
                _buildSectionTitle(isAr ? '🗺️ خريطة الشبكة الحية' : '🗺️ Live Network Map', isAr),
                _buildMetroMap(size),

                // ── Your personal impact ─────────────────────────────────────
                _buildSectionTitle(isAr ? '⭐ أثرك الشخصي' : '⭐ Your Personal Impact', isAr),
                _buildPersonalImpact(isAr),

                // ── Features showcase ────────────────────────────────────────
                _buildSectionTitle(isAr ? '💡 ${_appFeatures.length} ميزة واحدة تخدم الجميع' : '💡 ${_appFeatures.length} Features, One Mission', isAr),
                _buildFeaturesGrid(isAr),

                // ── Vision card ──────────────────────────────────────────────
                _buildVisionCard(isAr),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // ── Share FAB ─────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F8AFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.share_rounded),
        label: Text(isAr ? 'شارك مع العالم' : 'Share Impact'),
        onPressed: () => _shareImpact(isAr),
      ),
    );
  }

  // ── Hero section ────────────────────────────────────────────────────────────
  Widget _buildHero(bool isAr, Size size) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [Color(0xFF1A2A6C), Color(0xFF0A0E27)],
            ),
          ),
        ),

        // Animated rotating rings
        AnimatedBuilder(
          animation: _networkController,
          builder: (_, __) => CustomPaint(
            painter: _HeroRingPainter(progress: _networkController.value),
          ),
        ),

        // Egypt flag stripe (subtle)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFCE1126), Color(0xFFFFFFFF), Color(0xFFCE1126)],
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: AnimatedBuilder(
            animation: _heroController,
            builder: (_, __) {
              final v = _heroController.value;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Flag + icon
                  Transform.scale(
                    scale: 0.5 + v * 0.5,
                    child: Opacity(
                      opacity: v,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A56DB), Color(0xFF00D4FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F8AFF).withOpacity(0.6),
                              blurRadius: 30, spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.train_rounded, color: Colors.white, size: 46),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: v,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Color(0xFF4F8AFF), Color(0xFF00D4FF), Color(0xFFFFFFFF)],
                      ).createShader(rect),
                      child: Text(
                        isAr ? 'رفيق خدم مصر كلها 🇪🇬' : 'Rafiq Served All of Egypt 🇪🇬',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: (v * 2 - 1).clamp(0.0, 1.0),
                    child: Text(
                      'Cairo Metro Master • مشروع تخرج ${DateTime.now().year}',
                      style: const TextStyle(
                        color: Color(0xFF8899CC), fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Network stats grid ───────────────────────────────────────────────────────
  Widget _buildNetworkGrid(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: _networkStats.asMap().entries.map((e) {
          final delay = e.key * 0.15;
          return AnimatedBuilder(
            animation: _counterController,
            builder: (_, __) {
              final t = ((_counterController.value - delay) / (1.0 - delay))
                  .clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - t)),
                  child: _NetworkStatCard(stat: e.value, isAr: isAr, progress: t),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Metro map ────────────────────────────────────────────────────────────────
  Widget _buildMetroMap(Size size) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1530),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2D5A)),
      ),
      child: AnimatedBuilder(
        animation: _networkController,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: _MetroNetworkPainter(progress: _networkController.value),
          ),
        ),
      ),
    );
  }

  // ── Personal impact ──────────────────────────────────────────────────────────
  Widget _buildPersonalImpact(bool isAr) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (_, __) {
        final t = _cardController.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2A6C), Color(0xFF0D1530)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E2D5A)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _impactStat(
                        isAr ? 'رحلاتك' : 'Your Trips',
                        _userTrips.toString(),
                        '🚇',
                        const Color(0xFF4F8AFF),
                      ),
                      _impactStat(
                        isAr ? 'نقاطك' : 'Your Points',
                        _userPoints.toString(),
                        '⭐',
                        const Color(0xFFFFB800),
                      ),
                      _impactStat(
                        isAr ? 'شاراتك' : 'Badges',
                        _userBadges.toString(),
                        '🏆',
                        const Color(0xFF20C997),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'التوفير المحتمل هذا الشهر' : 'Potential Monthly Savings',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                              Text(
                                '${_userSavings.toStringAsFixed(0)} ${isAr ? 'جنيه' : 'EGP'}',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAr ? 'بالذكاء الاصطناعي' : 'AI Optimized',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _impactStat(String label, String value, String emoji, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _counterController,
            builder: (_, __) {
              final t = _counterController.value;
              final numVal = int.tryParse(value) ?? 0;
              final display = (numVal * t).round();
              return Text(
                numVal > 0 ? display.toString() : value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              );
            },
          ),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }

  // ── Features grid ─────────────────────────────────────────────────────────────
  Widget _buildFeaturesGrid(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _appFeatures.asMap().entries.map((e) {
          final delay = e.key * 0.08;
          return AnimatedBuilder(
            animation: _cardController,
            builder: (_, __) {
              final t = ((_cardController.value - delay) / (1.0 - delay))
                  .clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.7 + 0.3 * t,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1530),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2D5A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value.$1, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? e.value.$2 : e.value.$3,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Vision card ───────────────────────────────────────────────────────────────
  Widget _buildVisionCard(bool isAr) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFCE1126).withOpacity(0.15),
            const Color(0xFF0A0E27),
            const Color(0xFFCE1126).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCE1126).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('🇪🇬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            isAr ? 'رؤية رفيق' : 'Rafiq Vision',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'رفيق المترو مش بس تطبيق — هو مساعد ذكي يخدم أكتر من 3.5 مليون راكب يومياً، بيحسّن رحلاتهم، بيوفّر وقتهم، وبيربط مجتمع متكامل وراء كل رحلة.\n\nمصر بتتحرك... ورفيق بيمشي معاها. 🚇'
                : 'Rafiq Metro is more than an app — it\'s an intelligent companion serving 3.5M+ daily commuters, optimizing journeys, saving time, and connecting a full community behind every single trip.\n\nEgypt moves forward... and Rafiq moves with it. 🚇',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8899CC),
              fontSize: 14,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          // Line colors legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _lineBadge('الخط الأول', AppColors.line1),
              const SizedBox(width: 12),
              _lineBadge('الخط الثاني', AppColors.line2),
              const SizedBox(width: 12),
              _lineBadge('الخط الثالث', AppColors.line3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildSectionTitle(String title, bool isAr) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(
          color: const Color(0xFF4F8AFF),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        )),
      ],
    ),
  );

  void _shareImpact(bool isAr) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🇪🇬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'شارك إنجازك مع العالم!'
                  : 'Share your achievement with the world!',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'رفيق المترو — $_userTrips رحلة • $_userPoints نقطة • $_userBadges شارة'
                  : 'Rafiq Metro — $_userTrips trips • $_userPoints pts • $_userBadges badges',
              style: const TextStyle(color: Color(0xFF8899CC), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(isAr ? 'نسخ الرسالة' : 'Copy Message'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: isAr
                            ? '🚇 أنا بستخدم رفيق المترو — التطبيق الذكي لمترو القاهرة!\n'
                              'رحلاتي: $_userTrips • نقاطي: $_userPoints • شاراتي: $_userBadges 🏆\n'
                              'حمّل رفيق المترو دلوقتي! #رفيق_المترو #مترو_القاهرة 🇪🇬'
                            : '🚇 I use Rafiq Metro — the smart Cairo Metro app!\n'
                              'My trips: $_userTrips • Points: $_userPoints • Badges: $_userBadges 🏆\n'
                              'Download Rafiq Metro now! #RafiqMetro #CairoMetro 🇪🇬',
                      ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isAr ? '✅ تم النسخ!' : '✅ Copied!'),
                        backgroundColor: Colors.green,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────
class _StatData {
  final String value;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final Color color;
  const _StatData(this.value, this.labelAr, this.labelEn, this.icon, this.color);
}

// ─── Network Stat Card ────────────────────────────────────────────────────────
class _NetworkStatCard extends StatelessWidget {
  final _StatData stat;
  final bool isAr;
  final double progress;

  const _NetworkStatCard({required this.stat, required this.isAr, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1530),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(height: 8),
          // Animated counter for numeric values
          Builder(builder: (_) {
            final numVal = double.tryParse(stat.value.replaceAll('M', '').replaceAll('+', ''));
            if (numVal != null && !stat.value.contains('M')) {
              return Text(
                '${(numVal * progress).round()}${stat.value.contains('+') ? '+' : ''}',
                style: TextStyle(color: stat.color, fontWeight: FontWeight.w900, fontSize: 20),
              );
            }
            return Text(
              stat.value,
              style: TextStyle(color: stat.color, fontWeight: FontWeight.w900, fontSize: 18),
            );
          }),
          const SizedBox(height: 4),
          Text(
            isAr ? stat.labelAr : stat.labelEn,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Hero Ring Painter ────────────────────────────────────────────────────────
class _HeroRingPainter extends CustomPainter {
  final double progress;
  _HeroRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 1; i <= 4; i++) {
      final r = 40.0 * i + sin(progress * 2 * pi + i) * 8;
      final opacity = (0.08 - i * 0.015).clamp(0.01, 0.08);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = const Color(0xFF4F8AFF).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Rotating dots
    for (int i = 0; i < 8; i++) {
      final angle = (progress * 2 * pi) + (i * pi / 4);
      final r = 90.0;
      canvas.drawCircle(
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        2,
        Paint()..color = const Color(0xFF4F8AFF).withOpacity(0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroRingPainter old) => old.progress != progress;
}

// ─── Metro Network Painter ────────────────────────────────────────────────────
class _MetroNetworkPainter extends CustomPainter {
  final double progress;
  _MetroNetworkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background grid
    _drawGrid(canvas, size);

    // Line 1 (Red) — Helwan to New El-Marg (diagonal)
    _drawLine(canvas,
      [Offset(w * 0.1, h * 0.85), Offset(w * 0.3, h * 0.6), Offset(w * 0.5, h * 0.4), Offset(w * 0.7, h * 0.25), Offset(w * 0.9, h * 0.1)],
      AppColors.line1, progress,
    );

    // Line 2 (Yellow) — Shobra to Monib (horizontal-ish)
    _drawLine(canvas,
      [Offset(w * 0.05, h * 0.2), Offset(w * 0.25, h * 0.3), Offset(w * 0.5, h * 0.45), Offset(w * 0.75, h * 0.55), Offset(w * 0.95, h * 0.65)],
      AppColors.line2, progress,
    );

    // Line 3 (Blue) — Adly Mansour to Kitkat
    _drawLine(canvas,
      [Offset(w * 0.9, h * 0.15), Offset(w * 0.7, h * 0.35), Offset(w * 0.5, h * 0.45), Offset(w * 0.3, h * 0.55), Offset(w * 0.1, h * 0.75)],
      AppColors.line3, progress,
    );

    // Draw stations (intersections)
    final stations = [
      (Offset(w * 0.5, h * 0.42), const Color(0xFFFFFFFF)), // Attaba/Transfer
      (Offset(w * 0.3, h * 0.6), AppColors.line1),
      (Offset(w * 0.7, h * 0.25), AppColors.line1),
      (Offset(w * 0.25, h * 0.3), AppColors.line2),
      (Offset(w * 0.75, h * 0.55), AppColors.line2),
      (Offset(w * 0.7, h * 0.35), AppColors.line3),
      (Offset(w * 0.3, h * 0.55), AppColors.line3),
    ];

    for (final st in stations) {
      _drawStation(canvas, st.$1, st.$2, progress);
    }

    // Animated train on line 1
    final t1 = progress % 1.0;
    final trainX = w * 0.1 + (w * 0.8) * t1;
    final trainY = h * 0.85 - (h * 0.75) * t1;
    _drawTrain(canvas, Offset(trainX, trainY), AppColors.line1);

    // Animated train on line 2
    final t2 = (progress + 0.33) % 1.0;
    final train2X = w * 0.05 + (w * 0.9) * t2;
    final train2Y = h * 0.2 + (h * 0.45) * t2;
    _drawTrain(canvas, Offset(train2X, train2Y), AppColors.line2);

    // Animated train on line 3
    final t3 = (progress + 0.66) % 1.0;
    final train3X = w * 0.9 - (w * 0.8) * t3;
    final train3Y = h * 0.15 + (h * 0.6) * t3;
    _drawTrain(canvas, Offset(train3X, train3Y), AppColors.line3);

    // Labels
    _drawLabel(canvas, Offset(w * 0.08, h * 0.92), 'الخط الأول', AppColors.line1);
    _drawLabel(canvas, Offset(w * 0.08, h * 0.12), 'الخط الثاني', AppColors.line2);
    _drawLabel(canvas, Offset(w * 0.5, h * 0.06), 'الخط الثالث', AppColors.line3);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D5A).withOpacity(0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(Offset(size.width * i / 10, 0), Offset(size.width * i / 10, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i / 10), Offset(size.width, size.height * i / 10), paint);
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color, double progress) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final pt in points.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _drawStation(Canvas canvas, Offset pos, Color color, double progress) {
    final pulse = sin(progress * 2 * pi) * 3;
    canvas.drawCircle(pos, 8 + pulse, Paint()..color = color.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(pos, 5, Paint()..color = color);
    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
  }

  void _drawTrain(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(pos, 6, Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(pos, 4, Paint()..color = color);
    canvas.drawCircle(pos, 2, Paint()..color = Colors.white);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color.withOpacity(0.8), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _MetroNetworkPainter old) => old.progress != progress;
}
