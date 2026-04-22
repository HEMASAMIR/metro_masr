import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import 'onboarding_screen.dart';
import '../../metro/presentation/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Train animation
  late AnimationController _trainController;
  late Animation<double> _trainPosition;

  // Logo + text fade
  late AnimationController _logoController;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _subtitleOpacity;

  // Track pulse
  late AnimationController _trackController;
  late Animation<double> _trackOpacity;

  // Particles
  late AnimationController _particleController;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  // Loading bar
  late AnimationController _loadingController;
  late Animation<double> _loadingProgress;

  @override
  void initState() {
    super.initState();

    // Spawn particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 2 + _rng.nextDouble() * 4,
        speed: 0.003 + _rng.nextDouble() * 0.007,
        opacity: 0.3 + _rng.nextDouble() * 0.7,
      ));
    }

    // Track pulse
    _trackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _trackOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _trackController, curve: Curves.easeInOut),
    );

    // Train slides from left (off screen) to center
    _trainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _trainPosition = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _trainController, curve: Curves.easeOutCubic),
    );

    // Logo fade + scale
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    // Particles drift
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Loading bar
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _loadingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _trainController.forward();
    _loadingController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            seenOnboarding ? const HomePage() : const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _trainController.dispose();
    _logoController.dispose();
    _trackController.dispose();
    _particleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF1A2050),
                  Color(0xFF0A0E27),
                ],
              ),
            ),
          ),

          // ── Floating particles ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // ── Track lines ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: size.height * 0.52,
            child: AnimatedBuilder(
              animation: _trackOpacity,
              builder: (_, __) => Opacity(
                opacity: _trackOpacity.value,
                child: CustomPaint(
                  size: Size(size.width, 40),
                  painter: _TrackPainter(),
                ),
              ),
            ),
          ),

          // ── Train (slides in from left) ──────────────────────────────────
          AnimatedBuilder(
            animation: _trainPosition,
            builder: (_, __) {
              final dx = _trainPosition.value * size.width * 1.2;
              return Positioned(
                left: size.width * 0.08 + dx,
                top: size.height * 0.44,
                child: const _MetroTrain(),
              );
            },
          ),

          // ── Logo + text ──────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 0),
                // Push content up a bit above the train
                Transform.translate(
                  offset: const Offset(0, -80),
                  child: AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Column(
                          children: [
                            // Icon glow
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4F8AFF), Color(0xFF1A56DB)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F8AFF).withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.train_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // App name
                            ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                colors: [Color(0xFF4F8AFF), Color(0xFF00D4FF)],
                              ).createShader(rect),
                              child: const Text(
                                'رفيق المترو',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedBuilder(
                              animation: _subtitleOpacity,
                              builder: (_, __) => Opacity(
                                opacity: _subtitleOpacity.value,
                                child: const Text(
                                  'Cairo Metro Master',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8899CC),
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading bar at bottom ────────────────────────────────────────
          Positioned(
            left: 40,
            right: 40,
            bottom: 60,
            child: AnimatedBuilder(
              animation: _loadingProgress,
              builder: (_, __) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _loadingProgress.value,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF4F8AFF)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingProgress.value < 0.4
                        ? 'تحميل البيانات...'
                        : _loadingProgress.value < 0.8
                            ? 'جاهز للانطلاق...'
                            : 'يلا نطير! 🚇',
                    style: const TextStyle(
                      color: Color(0xFF8899CC),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Line dots (decorative) ───────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _lineDot(AppColors.line1),
                const SizedBox(width: 8),
                _lineDot(AppColors.line2),
                const SizedBox(width: 8),
                _lineDot(AppColors.line3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.6), blurRadius: 6, spreadRadius: 2),
          ],
        ),
      );
}

// ── Metro Train Widget ────────────────────────────────────────────────────────
class _MetroTrain extends StatelessWidget {
  const _MetroTrain();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 70,
      child: CustomPaint(painter: _TrainPainter()),
    );
  }
}

class _TrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A56DB), Color(0xFF4F8AFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final windowPaint = Paint()..color = const Color(0xFFD4EAFF).withOpacity(0.85);
    final wheelPaint = Paint()..color = const Color(0xFF333D5E);
    final glowPaint = Paint()
      ..color = const Color(0xFF4F8AFF).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final stripePaint = Paint()..color = const Color(0xFF00D4FF);
    final reflectPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Glow underneath train
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-8, 8, size.width + 16, size.height + 6),
        const Radius.circular(14),
      ),
      glowPaint,
    );

    // Train body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, size.width, size.height - 18),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Blue accent stripe along the bottom of body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - 26, size.width, 5),
        const Radius.circular(2),
      ),
      stripePaint..color = const Color(0xFF00D4FF),
    );

    // Light reflection on top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 7, size.width - 16, 10),
        const Radius.circular(6),
      ),
      reflectPaint,
    );

    // Windows
    const windowW = 34.0;
    const windowH = 20.0;
    const windowY = 14.0;
    for (int i = 0; i < 5; i++) {
      final wx = 16.0 + i * (windowW + 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, windowY, windowW, windowH),
          const Radius.circular(5),
        ),
        windowPaint,
      );
      // Window reflection
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx + 3, windowY + 3, 8, 6),
          const Radius.circular(2),
        ),
        reflectPaint,
      );
    }

    // Front face (right side)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(size.width - 22, 4, 22, size.height - 18),
        topRight: const Radius.circular(12),
        bottomRight: const Radius.circular(8),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2264E5), Color(0xFF1A56DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(size.width - 22, 0, 22, size.height)),
    );

    // Headlight glow
    final headlightPaint = Paint()
      ..color = const Color(0xFFFFFFAA).withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.width - 10, size.height - 22), 4, headlightPaint);

    // Wheels
    final wheelPositions = [30.0, 80.0, 140.0, 220.0, size.width - 30];
    for (final wx in wheelPositions) {
      // Wheel shadow
      canvas.drawCircle(
        Offset(wx, size.height - 8),
        9,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(wx, size.height - 9), 8, wheelPaint);
      canvas.drawCircle(
        Offset(wx, size.height - 9),
        4,
        Paint()..color = const Color(0xFF556080),
      );
      canvas.drawCircle(
        Offset(wx, size.height - 9),
        1.5,
        Paint()..color = const Color(0xFF8899CC),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Railway Track Painter ─────────────────────────────────────────────────────
class _TrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = const Color(0xFF4F8AFF).withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final tiePaint = Paint()
      ..color = const Color(0xFF334066)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Two rails
    canvas.drawLine(Offset(0, 10), Offset(size.width, 10), railPaint);
    canvas.drawLine(Offset(0, 26), Offset(size.width, 26), railPaint);

    // Ties (sleepers)
    for (int i = 0; i < 20; i++) {
      final x = i * (size.width / 18);
      canvas.drawLine(
        Offset(x, 6),
        Offset(x, 30),
        tiePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Particles ─────────────────────────────────────────────────────────────────
class _Particle {
  double x, y, size, speed, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed * 20) % 1.0;
      final paint = Paint()
        ..color = const Color(0xFF4F8AFF).withOpacity(p.opacity * 0.5);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
