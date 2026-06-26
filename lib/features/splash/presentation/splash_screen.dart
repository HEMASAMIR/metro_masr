import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/offline_storage.dart';
import '../../metro/presentation/pages/home_page.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF0A1628);   // deep navy
const _kMid     = Color(0xFF112244);   // mid navy
const _kAccent  = Color(0xFF3B82F6);   // electric blue
const _kGlow    = Color(0xFF60A5FA);   // soft glow blue
const _kLine1   = Color(0xFFEF4444);   // red  – Line 1
const _kLine2   = Color(0xFF3B82F6);   // blue – Line 2
const _kLine3   = Color(0xFF22C55E);   // green– Line 3

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ─────────────────────────────────────────────────────────
  late AnimationController _logoCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _linesCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _trainCtrl;
  late AnimationController _topBarCtrl;
  late AnimationController _botBarCtrl;

  // ── Animations ───────────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _linesOpacity;
  late Animation<double> _progress;
  late Animation<double> _trainX;
  late Animation<double> _topBarSlide;
  late Animation<double> _botBarSlide;

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:            Colors.transparent,
      statusBarIconBrightness:   Brightness.light,
      systemNavigationBarColor:  _kBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Particles
    for (int i = 0; i < 22; i++) {
      _particles.add(_Particle(
        x:       _rng.nextDouble(),
        y:       _rng.nextDouble(),
        size:    1.0 + _rng.nextDouble() * 2.5,
        speed:   0.003 + _rng.nextDouble() * 0.006,
        opacity: 0.06 + _rng.nextDouble() * 0.15,
      ));
    }

    // Top bar
    _topBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _topBarSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
        CurvedAnimation(parent: _topBarCtrl, curve: Curves.easeOutCubic));

    // Bottom bar
    _botBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _botBarSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _botBarCtrl, curve: Curves.easeOutCubic));

    // Logo
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale   = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // Title
    _titleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));

    // Lines
    _linesCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _linesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _linesCtrl, curve: Curves.easeOut));

    // Progress
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));

    // Pulse glow
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    // Particles
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();

    // Train
    _trainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _trainX = Tween<double>(begin: -1.5, end: 0.0).animate(
        CurvedAnimation(parent: _trainCtrl, curve: Curves.easeOutCubic));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _topBarCtrl.forward();
    _botBarCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 550));
    _titleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _trainCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _linesCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    await OfflineStorage.init();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const HomePage(),
      transitionDuration: const Duration(milliseconds: 800),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
        child: child,
      ),
    ));
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _titleCtrl.dispose();
    _linesCtrl.dispose();
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _trainCtrl.dispose();
    _topBarCtrl.dispose();
    _botBarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [_kMid, _kBg],
              ),
            ),
          ),

          // ── Subtle grid overlay ──────────────────────────────────────────
          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          // ── Floating particles ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleCtrl.value,
              ),
            ),
          ),

          // ── TOP STATUS BAR ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _topBarSlide,
            builder: (_, __) => Positioned(
              top: _topBarSlide.value * 80,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),
          ),

          // ── BOTTOM STATUS BAR ────────────────────────────────────────────
          AnimatedBuilder(
            animation: _botBarSlide,
            builder: (_, __) => Positioned(
              bottom: _botBarSlide.value * 80,
              left: 0,
              right: 0,
              child: _buildBottomBar(size),
            ),
          ),

          // ── CENTER CONTENT ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _buildLogo(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, __) => SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: _buildTitle(),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Metro Line indicators
                AnimatedBuilder(
                  animation: _linesOpacity,
                  builder: (_, __) => Opacity(
                    opacity: _linesOpacity.value,
                    child: _buildLineIndicators(),
                  ),
                ),

                const SizedBox(height: 40),

                // Progress
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => _buildProgress(size),
                ),
              ],
            ),
          ),

          // ── TRAIN (decorative) ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _trainX,
            builder: (_, __) {
              final dx = _trainX.value * size.width * 1.4;
              return Positioned(
                left: size.width * 0.05 + dx,
                bottom: 130,
                child: const _TrainWidget(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 24,
            right: 24,
            bottom: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(color: _kAccent.withOpacity(0.15), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo mark
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAccent, _kGlow],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_subway_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'مترو مصر بدون انترنت',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Version badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent.withOpacity(0.3), width: 0.5),
                ),
                child: const Text(
                  'v2.0',
                  style: TextStyle(color: _kGlow, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar(Size size) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 14,
            top: 14,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            border: Border(
              top: BorderSide(color: _kAccent.withOpacity(0.15), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Track line decorations
              _buildTrackDot(_kLine1),
              _buildTrackLine(),
              _buildTrackDot(_kLine2),
              _buildTrackLine(),
              _buildTrackDot(_kLine3),
              const SizedBox(width: 16),
              Text(
                'Cairo Metro • 3 Lines • 85 Stations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackDot(Color color) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
    ),
  );

  Widget _buildTrackLine() => Container(
    width: 20, height: 1.5,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.white.withOpacity(0.15),
  );

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final pulse = _pulseCtrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 140 + pulse * 8,
              height: 140 + pulse * 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent.withOpacity(0.04 + pulse * 0.04),
              ),
            ),
            // Inner ring
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent.withOpacity(0.08 + pulse * 0.05),
                border: Border.all(
                  color: _kAccent.withOpacity(0.2 + pulse * 0.15),
                  width: 1,
                ),
              ),
            ),
            // Main circle
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(const Color(0xFF1E4080), const Color(0xFF2563EB), pulse * 0.5)!,
                    Color.lerp(const Color(0xFF1E3A5F), const Color(0xFF1D4ED8), pulse * 0.3)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.3 + pulse * 0.2),
                    blurRadius: 30 + pulse * 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shine
                  Positioned(
                    top: 14,
                    left: 18,
                    child: Container(
                      width: 28,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.12 + pulse * 0.06),
                      ),
                    ),
                  ),
                  const Icon(Icons.directions_subway_rounded, color: Colors.white, size: 46),
                  // Bottom line stripes
                  Positioned(
                    bottom: 16,
                    left: 18,
                    right: 18,
                    child: Column(
                      children: [
                        _buildIconStripe(_kLine1),
                        const SizedBox(height: 2),
                        _buildIconStripe(_kLine2),
                        const SizedBox(height: 2),
                        _buildIconStripe(_kLine3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconStripe(Color c) => Container(
    height: 2.5,
    decoration: BoxDecoration(
      color: c.withOpacity(0.85),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  // ── Title ──────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Colors.white, _kGlow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: const Text(
            'مترو مصر بدون انترنت',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _kAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kAccent.withOpacity(0.25), width: 0.8),
          ),
          child: Text(
            'CAIRO METRO GUIDE',
            style: TextStyle(
              fontSize: 11,
              color: _kGlow.withOpacity(0.9),
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Line indicators ────────────────────────────────────────────────────────
  Widget _buildLineIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLineChip(_kLine1, 'الخط الأول'),
        const SizedBox(width: 12),
        _buildLineChip(_kLine2, 'الخط الثاني'),
        const SizedBox(width: 12),
        _buildLineChip(_kLine3, 'الخط الثالث'),
      ],
    );
  }

  Widget _buildLineChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress ───────────────────────────────────────────────────────────────
  Widget _buildProgress(Size size) {
    final labels = ['جاري التحميل...', 'تجهيز البيانات...', 'يلا نطير! 🚇'];
    final label = _progress.value < 0.4 ? labels[0]
        : _progress.value < 0.85 ? labels[1]
        : labels[2];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.15),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: _progress.value,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(
                  Color.lerp(_kAccent, _kGlow, _progress.value)!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Train ─────────────────────────────────────────────────────────────────────
class _TrainWidget extends StatelessWidget {
  const _TrainWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 240, height: 54, child: CustomPaint(painter: _TrainPainter()));
  }
}

class _TrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-4, 8, s.width + 8, s.height - 8), const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF3B82F6).withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Body
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, s.width, s.height - 18), const Radius.circular(9));
    canvas.drawRRect(body, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // Highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(6, 4, s.width - 12, 6), const Radius.circular(4)),
      Paint()..color = Colors.white.withOpacity(0.20),
    );
    // Windows
    for (int i = 0; i < 5; i++) {
      final wx = 12.0 + i * 44.0;
      if (wx + 30 > s.width - 12) break;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(wx, 9, 30, 16), const Radius.circular(3)),
        Paint()..color = const Color(0xFFBFDBFE).withOpacity(0.85),
      );
    }
    // Accent stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, s.height - 20, s.width, 3), const Radius.circular(2)),
      Paint()..color = const Color(0xFF3B82F6).withOpacity(0.8),
    );
    // Wheels
    for (final wx in [26.0, 86.0, 154.0, 214.0]) {
      if (wx > s.width - 16) break;
      canvas.drawCircle(Offset(wx, s.height - 7), 6.5, Paint()..color = const Color(0xFF1E3A5F));
      canvas.drawCircle(Offset(wx, s.height - 7), 3.0, Paint()..color = const Color(0xFF60A5FA));
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Grid painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.035)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Particle system ───────────────────────────────────────────────────────────
class _Particle {
  double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed * 14) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        Paint()..color = const Color(0xFF60A5FA).withOpacity(p.opacity),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
