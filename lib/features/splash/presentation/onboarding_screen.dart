import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../metro/presentation/pages/home_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _pages = [
    _OnboardingData(
      illustration: _TrainIllustration(),
      titleAr: 'رحلتك أسهل وأذكى',
      titleEn: 'Smarter Metro Journeys',
      subtitleAr:
          'خطط رحلاتك باستخدام خوارزمية أقصر مسار، وتابع حالة الخطوط لحظة بلحظة عبر مترو القاهرة بالكامل.',
      subtitleEn:
          'Plan trips with shortest-path routing and track line status in real time across all Cairo Metro lines.',
      gradient: [Color(0xFF1A56DB), Color(0xFF0A0E27)],
      accentColor: Color(0xFF4F8AFF),
    ),
    _OnboardingData(
      illustration: _CommunityIllustration(),
      titleAr: 'مجتمع متصل',
      titleEn: 'Connected Community',
      subtitleAr:
          'أبلغ عن أحداث المحطات، شارك في الدردشة الحية، تتبع الزحمة، واكسب نقاطاً على كل مشاركة.',
      subtitleEn:
          'Report station incidents, join live chat, track crowd levels, and earn points for every contribution.',
      gradient: [Color(0xFF0F5132), Color(0xFF0A0E27)],
      accentColor: Color(0xFF20C997),
    ),
    _OnboardingData(
      illustration: _AIIllustration(),
      titleAr: 'ذكاء اصطناعي في خدمتك',
      titleEn: 'AI at Your Service',
      subtitleAr:
          'اسأل رفيق الذكي عن الأسعار والمواعيد، وتحقق من توقعات الازدحام، وجدول رحلاتك بذكاء.',
      subtitleEn:
          'Ask Rafiq AI about fares and schedules, check crowd forecasts, and schedule your commute smartly.',
      gradient: [Color(0xFF5A189A), Color(0xFF0A0E27)],
      accentColor: Color(0xFFBF5AF2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Illustration
                              SizedBox(
                                height: size.height * 0.30,
                                child: p.illustration,
                              ),
                              const SizedBox(height: 36),

                              // Title
                              Text(
                                p.titleAr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: p.accentColor.withOpacity(0.6),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.titleEn,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withOpacity(0.45),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Subtitle
                              Text(
                                p.subtitleAr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.75),
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Dots + button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot indicators
                    Row(
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? page.accentColor
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Next / Start button
                    GestureDetector(
                      onTap: () {
                        if (isLast) {
                          _finish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isLast ? 140 : 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: page.accentColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: page.accentColor.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: isLast
                              ? const Text(
                                  'ابدأ الآن!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 24),
                        ),
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
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _OnboardingData {
  final Widget illustration;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final List<Color> gradient;
  final Color accentColor;

  const _OnboardingData({
    required this.illustration,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.gradient,
    required this.accentColor,
  });
}

// ── Illustration 1: Animated Train ─────────────────────────────────────────
class _TrainIllustration extends StatefulWidget {
  const _TrainIllustration();

  @override
  State<_TrainIllustration> createState() => _TrainIllustrationState();
}

class _TrainIllustrationState extends State<_TrainIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _trainX;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _trainX = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _bounce = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _OnboardingTrainPainter(
          trainX: _trainX.value,
          bounceY: _bounce.value,
        ),
      ),
    );
  }
}

class _OnboardingTrainPainter extends CustomPainter {
  final double trainX;
  final double bounceY;

  _OnboardingTrainPainter({required this.trainX, required this.bounceY});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + trainX;
    final cy = size.height / 2 + bounceY;

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4F8AFF).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 260, height: 40),
      glowPaint,
    );

    // Track
    _drawTrack(canvas, size, cx, cy);
    // Train body
    _drawTrain(canvas, cx, cy);
    // Speed lines
    _drawSpeedLines(canvas, cx, cy);
  }

  void _drawTrack(Canvas canvas, Size size, double cx, double cy) {
    final railPaint = Paint()
      ..color = const Color(0xFF4F8AFF).withOpacity(0.5)
      ..strokeWidth = 2;
    final trackY = cy + 36.0;
    canvas.drawLine(Offset(cx - 140, trackY), Offset(cx + 140, trackY), railPaint);
    canvas.drawLine(Offset(cx - 140, trackY + 10), Offset(cx + 140, trackY + 10), railPaint);
    for (int i = -7; i <= 7; i++) {
      canvas.drawLine(
        Offset(cx + i * 18.0, trackY - 2),
        Offset(cx + i * 18.0, trackY + 12),
        Paint()
          ..color = const Color(0xFF334066)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawTrain(Canvas canvas, double cx, double cy) {
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A56DB), Color(0xFF4F8AFF)],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 240, height: 60));

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 220, height: 52),
        const Radius.circular(14),
      ),
      bodyPaint,
    );

    // Stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 110, cy + 22, 220, 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF00D4FF),
    );

    // Windows
    final wPaint = Paint()..color = const Color(0xFFD4EAFF);
    for (int i = -2; i <= 2; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + i * 38.0, cy + 2), width: 28, height: 18),
          const Radius.circular(4),
        ),
        wPaint,
      );
    }

    // Wheels
    for (final wx in [-75.0, -25.0, 25.0, 75.0]) {
      canvas.drawCircle(
        Offset(cx + wx, cy + 34),
        8,
        Paint()..color = const Color(0xFF222840),
      );
      canvas.drawCircle(
        Offset(cx + wx, cy + 34),
        3.5,
        Paint()..color = const Color(0xFF556080),
      );
    }
  }

  void _drawSpeedLines(Canvas canvas, double cx, double cy) {
    final linePaint = Paint()
      ..color = const Color(0xFF4F8AFF).withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final dy in [-12.0, 0.0, 12.0]) {
      canvas.drawLine(
        Offset(cx - 160, cy + dy),
        Offset(cx - 120, cy + dy),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingTrainPainter old) =>
      old.trainX != trainX || old.bounceY != bounceY;
}

// ── Illustration 2: Community Icons ──────────────────────────────────────────
class _CommunityIllustration extends StatefulWidget {
  const _CommunityIllustration();

  @override
  State<_CommunityIllustration> createState() => _CommunityIllustrationState();
}

class _CommunityIllustrationState extends State<_CommunityIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring pulse
              Container(
                width: 180 + _ctrl.value * 20,
                height: 180 + _ctrl.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF20C997).withOpacity(0.2 - _ctrl.value * 0.15),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF20C997).withOpacity(0.12),
                  border: Border.all(
                    color: const Color(0xFF20C997).withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
              ),
              // Center icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F5132), Color(0xFF20C997)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF20C997).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 38),
              ),
              // Orbit icons
              ..._buildOrbitIcons(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitIcons() {
    final items = [
      (Icons.report_outlined, const Color(0xFFFF6B6B), -90.0),
      (Icons.emoji_events_outlined, const Color(0xFFFFD700), 30.0),
      (Icons.chat_bubble_outline, const Color(0xFF4F8AFF), 150.0),
    ];
    return items.map((item) {
      return Transform.translate(
        offset: Offset(
          90 * _cosApprox(item.$3 * 3.14159 / 180),
          90 * _sinApprox(item.$3 * 3.14159 / 180),
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.$2.withOpacity(0.15),
            border: Border.all(color: item.$2.withOpacity(0.5)),
          ),
          child: Icon(item.$1, color: item.$2, size: 18),
        ),
      );
    }).toList();
  }

  double _cosApprox(double a) => a == -1.5708 ? 0 : a < 1 ? 0.87 : -0.87;
  double _sinApprox(double a) => a == -1.5708 ? -1 : 0.5;
}

// ── Illustration 3: AI Brain ──────────────────────────────────────────────────
class _AIIllustration extends StatefulWidget {
  const _AIIllustration();

  @override
  State<_AIIllustration> createState() => _AIIllustrationState();
}

class _AIIllustrationState extends State<_AIIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse rings
              for (int i = 3; i >= 1; i--)
                Container(
                  width: 60.0 + i * 45 + _ctrl.value * 12,
                  height: 60.0 + i * 45 + _ctrl.value * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBF5AF2).withOpacity(0.1 * (4 - i) * (1 - _ctrl.value * 0.3)),
                      width: 1.5,
                    ),
                  ),
                ),
              // Center AI icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A189A), Color(0xFFBF5AF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBF5AF2).withOpacity(0.5 + _ctrl.value * 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 50),
              ),
              // Floating feature pills
              ..._buildPills(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPills() {
    final pills = [
      ('AI Chat', const Color(0xFFBF5AF2), const Offset(0, -110)),
      ('📊 توقع', const Color(0xFF4F8AFF), const Offset(105, 30)),
      ('🏆 نقاط', const Color(0xFFFFD700), const Offset(-105, 30)),
    ];
    return pills.map((p) => Transform.translate(
      offset: Offset(
        p.$3.dx,
        p.$3.dy + (p.$3.dy < 0 ? -_ctrl.value * 5 : _ctrl.value * 5),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: p.$2.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.$2.withOpacity(0.5)),
        ),
        child: Text(p.$1, style: TextStyle(color: p.$2, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    )).toList();
  }
}
