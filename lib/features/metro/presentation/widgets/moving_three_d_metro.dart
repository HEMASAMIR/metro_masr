import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class MovingThreeDMetro extends StatefulWidget {
  final int metroType; // 0 = Cairo Metro, 1 = Capital Transport
  const MovingThreeDMetro({super.key, required this.metroType});

  @override
  State<MovingThreeDMetro> createState() => _MovingThreeDMetroState();
}

class _MovingThreeDMetroState extends State<MovingThreeDMetro>
    with TickerProviderStateMixin {
  late AnimationController _cruiseController;
  late AnimationController _boostController;
  late AnimationController _hornController;

  bool _isHornActive = false;
  int _sparkCount = 0;
  final List<math.Point<double>> _sparks = [];

  @override
  void initState() {
    super.initState();

    _cruiseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _boostController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _hornController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _hornController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isHornActive = false);
      }
    });
  }

  @override
  void dispose() {
    _cruiseController.dispose();
    _boostController.dispose();
    _hornController.dispose();
    super.dispose();
  }

  void _onTapTrain() {
    HapticFeedback.heavyImpact();
    
    // Trigger boost animation
    if (!_boostController.isAnimating) {
      _boostController.forward(from: 0.0);
    }

    // Trigger horn bubble
    setState(() {
      _isHornActive = true;
      _sparkCount = 8 + math.Random().nextInt(8);
      _sparks.clear();
      // Generate random sparks
      final r = math.Random();
      for (int i = 0; i < _sparkCount; i++) {
        _sparks.add(math.Point(
          -0.5 + r.nextDouble() * 1.0,
          0.8 + r.nextDouble() * 0.4,
        ));
      }
    });
    _hornController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return GestureDetector(
      onTap: _onTapTrain,
      child: AnimatedBuilder(
        animation: Listenable.merge([_cruiseController, _boostController, _hornController]),
        builder: (context, child) {
          // Cruise loop progress [0..1]
          final double cruiseProgress = _cruiseController.value;

          // Boost curve: rises to 1.0 quickly, then decays back to 0.0
          double boostVal = 0.0;
          if (_boostController.isAnimating) {
            final t = _boostController.value;
            if (t < 0.25) {
              boostVal = (t / 0.25); // quick rise
            } else {
              boostVal = 1.0 - ((t - 0.25) / 0.75); // slow decay
            }
          }

          // Gentle bobbing up/down (simulating track suspension)
          // Bob frequency increases when boosted
          final double bobSpeed = 1.0 + (boostVal * 2.0);
          final double bobOffset = math.sin(cruiseProgress * 2 * math.pi * bobSpeed) * 0.04;

          // Pitch tilt: when train accelerates, it tilts slightly backward
          final double tiltOffset = boostVal * -0.06;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 3D Canvas
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.metroType == 0
                        ? [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B),
                          ]
                        : [
                            const Color(0xFF1E1B4B),
                            const Color(0xFF312E81),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.metroType == 0
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : const Color(0xFF818CF8).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.metroType == 0
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CustomPaint(
                    painter: _ThreeDMetroPainter(
                      metroType: widget.metroType,
                      cruiseProgress: cruiseProgress,
                      boostProgress: boostVal,
                      bobOffset: bobOffset,
                      tiltOffset: tiltOffset,
                      sparks: _sparks,
                    ),
                  ),
                ),
              ),

              // Interactive Visual Overlay (Toot Toot!)
              if (_isHornActive)
                Positioned(
                  top: -24,
                  left: 48,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _hornController,
                      curve: Curves.elasticOut,
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                        CurvedAnimation(
                          parent: _hornController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                              color: widget.metroType == 0
                                  ? AppColors.primary
                                  : const Color(0xFF818CF8),
                              width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? "طوط طوط! 🚇🔊" : "TOOT TOOT! 🚇🔊",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: widget.metroType == 0
                                    ? AppColors.primary
                                    : const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Micro-hint badge
              Positioned(
                bottom: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? "المس المترو للتسريع!" : "Tap train to accelerate!",
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThreeDMetroPainter extends CustomPainter {
  final int metroType;
  final double cruiseProgress;
  final double boostProgress;
  final double bobOffset;
  final double tiltOffset;
  final List<math.Point<double>> sparks;

  _ThreeDMetroPainter({
    required this.metroType,
    required this.cruiseProgress,
    required this.boostProgress,
    required this.bobOffset,
    required this.tiltOffset,
    required this.sparks,
  });

  // 3D Camera coordinates (Looking at the train from 3/4 front-left angle)
  final double cameraX = -1.35;
  final double cameraY = -0.55;

  // Simple 3D to 2D projection function
  Offset project(double x, double y, double z, Size size) {
    // Apply Bobbing (vertical suspension movement)
    double yc = y - cameraY + bobOffset;

    // Apply Pitch/Tilt during acceleration
    // Vertices at the front (lower Z) tilt more than the back
    double zFactor = (8.0 - z) / 6.0; // 0.0 at back, 1.0 at front
    double zc = z + (tiltOffset * zFactor);
    double xc = x - cameraX;

    // Projection scale factors
    double scale = 220.0;
    double screenX = size.width / 2 + xc * scale / zc;
    double screenY = size.height / 2 + yc * scale / zc;
    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ── 1. DRAW BACKGROUND SPEED LINES (Parallax high-speed feel) ──
    final Paint speedLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12 + (boostProgress * 0.15))
      ..strokeWidth = 1.5 + (boostProgress * 2.0)
      ..strokeCap = StrokeCap.round;

    final double speedFactor = 1.0 + (boostProgress * 3.0);
    final random = math.Random(12345); // Seeded random for consistent lines
    for (int i = 0; i < 5; i++) {
      double lineY = size.height * (0.15 + (i * 0.15));
      double length = 40 + random.nextDouble() * 60;
      double speed = (150 + random.nextDouble() * 100) * speedFactor;
      double startX =
          (size.width + length) - ((cruiseProgress * speed) % (size.width + length));

      canvas.drawLine(
        Offset(startX, lineY),
        Offset(startX - length, lineY),
        speedLinePaint,
      );
    }

    // ── 2. DRAW TRACKS OR MONORAIL BEAM (BASED ON TYPE) ──
    if (metroType == 0) {
      // Cairo Metro: Two rails with sleepers in perspective
      final Paint railPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Colors.grey, Color(0xFF334155)],
        ).createShader(rect)
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      final Path leftRail = Path();
      final Path rightRail = Path();

      // Plot rails in perspective
      leftRail.moveTo(project(-1.3, 1.1, 1.0, size).dx, project(-1.3, 1.1, 1.0, size).dy);
      rightRail.moveTo(project(1.3, 1.1, 1.0, size).dx, project(1.3, 1.1, 1.0, size).dy);

      for (double z = 1.2; z <= 10.0; z += 0.5) {
        final pL = project(-1.3, 1.1, z, size);
        final pR = project(1.3, 1.1, z, size);
        leftRail.lineTo(pL.dx, pL.dy);
        rightRail.lineTo(pR.dx, pR.dy);
      }
      canvas.drawPath(leftRail, railPaint);
      canvas.drawPath(rightRail, railPaint);

      // Sleepers (horizontal ties connecting the rails)
      final Paint sleeperPaint = Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      // Sliding offset for sleeper movement
      double sleeperStep = 1.0;
      double offset = (cruiseProgress * speedFactor) % sleeperStep;
      for (double z = 1.0 + offset; z <= 10.0; z += sleeperStep) {
        final pL = project(-1.4, 1.1, z, size);
        final pR = project(1.4, 1.1, z, size);
        canvas.drawLine(pL, pR, sleeperPaint);
      }
    } else {
      // Capital Transport: Elevated modern concrete Monorail beam
      final Paint beamTopPaint = Paint()
        ..color = const Color(0xFF64748B);
      final Paint beamRightPaint = Paint()
        ..color = const Color(0xFF475569);

      // Top surface of the concrete beam
      final Path beamTop = Path();
      final Offset btl1 = project(-0.4, 1.1, 1.0, size);
      final Offset btr1 = project(0.4, 1.1, 1.0, size);
      final Offset btr2 = project(0.4, 1.1, 10.0, size);
      final Offset btl2 = project(-0.4, 1.1, 10.0, size);

      beamTop.moveTo(btl1.dx, btl1.dy);
      beamTop.lineTo(btr1.dx, btr1.dy);
      beamTop.lineTo(btr2.dx, btr2.dy);
      beamTop.lineTo(btl2.dx, btl2.dy);
      beamTop.close();
      canvas.drawPath(beamTop, beamTopPaint);

      // Right side surface of the concrete beam (facing the camera somewhat)
      final Path beamRight = Path();
      final Offset br1 = project(0.4, 1.1, 1.0, size);
      final Offset br2 = project(0.4, 1.8, 1.0, size);
      final Offset br3 = project(0.4, 1.8, 10.0, size);
      final Offset br4 = project(0.4, 1.1, 10.0, size);

      beamRight.moveTo(br1.dx, br1.dy);
      beamRight.lineTo(br2.dx, br2.dy);
      beamRight.lineTo(br3.dx, br3.dy);
      beamRight.lineTo(br4.dx, br4.dy);
      beamRight.close();
      canvas.drawPath(beamRight, beamRightPaint);

      // Glowing center track stripe (neon indigo/blue)
      final Paint neonTrackPaint = Paint()
        ..color = const Color(0xFF818CF8)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      final Path trackLine = Path();
      trackLine.moveTo(project(0.0, 1.1, 1.0, size).dx, project(0.0, 1.1, 1.0, size).dy);
      for (double z = 1.5; z <= 10.0; z += 1.0) {
        final p = project(0.0, 1.1, z, size);
        trackLine.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(trackLine, neonTrackPaint);
    }

    // ── 3. DRAW HEADLIGHTS GLOW CONE (CAST ON TRACKS) ──
    final Paint headlightGlowPaint = Paint()
      ..shader = LinearGradient(
        colors: metroType == 0
            ? [
                Colors.yellow.withValues(alpha: 0.45 + (boostProgress * 0.25)),
                Colors.yellow.withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFF67E8F9).withValues(alpha: 0.5),
                const Color(0xFF67E8F9).withValues(alpha: 0.0),
              ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    final Path glowCone = Path();
    final Offset frontLeftLight = project(-0.4, 0.4, 2.2, size);
    final Offset frontRightLight = project(0.4, 0.4, 2.2, size);
    final Offset bottomGlowLeft = project(-1.8, 1.2, 0.8, size);
    final Offset bottomGlowRight = project(1.8, 1.2, 0.8, size);

    glowCone.moveTo(frontLeftLight.dx, frontLeftLight.dy);
    glowCone.lineTo(frontRightLight.dx, frontRightLight.dy);
    glowCone.lineTo(bottomGlowRight.dx, bottomGlowRight.dy);
    glowCone.lineTo(bottomGlowLeft.dx, bottomGlowLeft.dy);
    glowCone.close();
    canvas.drawPath(glowCone, headlightGlowPaint);

    // ── 4. DRAW CABIN SHADOW (Underneath the train) ──
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final Path shadowPath = Path();
    shadowPath.moveTo(project(-0.8, 0.9, 1.8, size).dx, project(-0.8, 0.9, 1.8, size).dy);
    shadowPath.lineTo(project(0.8, 0.9, 1.8, size).dx, project(0.8, 0.9, 1.8, size).dy);
    shadowPath.lineTo(project(0.8, 1.0, 8.0, size).dx, project(0.8, 1.0, 8.0, size).dy);
    shadowPath.lineTo(project(-0.8, 1.0, 8.0, size).dx, project(-0.8, 1.0, 8.0, size).dy);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // ── 5. DEFINE 3D VERTS OF THE AERODYNAMIC CABIN ──
    final double w = 0.65; // Half width
    final double hBot = 0.85; // Floor Y
    final double hTop = -0.55; // Roof Y

    // Front Nose/Cabin coordinates (aerodynamically sloped)
    final Offset pRoofFrontL = project(-w, hTop, 2.4, size);
    final Offset pRoofFrontR = project(w, hTop, 2.4, size);
    final Offset pRoofBackL = project(-w, hTop, 8.0, size);
    final Offset pRoofBackR = project(w, hTop, 8.0, size);

    final Offset pFloorFrontL = project(-w, hBot, 2.1, size);
    final Offset pFloorFrontR = project(w, hBot, 2.1, size);
    final Offset pFloorBackL = project(-w, hBot, 8.0, size);
    final Offset pFloorBackR = project(w, hBot, 8.0, size);

    // Slanted Front Nose Tip
    final Offset pNoseTopL = project(-w, 0.0, 1.8, size);
    final Offset pNoseTopR = project(w, 0.0, 1.8, size);
    final Offset pNoseBumperCenter = project(0.0, 0.7, 1.6, size);

    // ── 6. DRAW 3D ROOF TOP FACE ──
    final Paint roofPaint = Paint()
      ..color = metroType == 0 ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
    final Path roofPath = Path();
    roofPath.moveTo(pRoofFrontL.dx, pRoofFrontL.dy);
    roofPath.lineTo(pRoofFrontR.dx, pRoofFrontR.dy);
    roofPath.lineTo(pRoofBackR.dx, pRoofBackR.dy);
    roofPath.lineTo(pRoofBackL.dx, pRoofBackL.dy);
    roofPath.close();
    canvas.drawPath(roofPath, roofPaint);

    // ── 7. DRAW 3D RIGHT SIDE PANEL (Extends in perspective) ──
    final Paint sidePaint = Paint()
      ..color = metroType == 0 ? Colors.white : const Color(0xFF312E81);
    final Path sidePath = Path();
    sidePath.moveTo(pRoofFrontR.dx, pRoofFrontR.dy);
    sidePath.lineTo(pRoofBackR.dx, pRoofBackR.dy);
    sidePath.lineTo(pFloorBackR.dx, pFloorBackR.dy);
    sidePath.lineTo(pFloorFrontR.dx, pFloorFrontR.dy);
    sidePath.close();
    canvas.drawPath(sidePath, sidePaint);

    // Draw Right Side Windows & Line Stripes
    // Accents & Window outlines
    final Paint stripePaint = Paint()
      ..color = metroType == 0
          ? AppColors.primary // Cairo Metro blue-red stripe
          : const Color(0xFFEC4899); // Monorail pink accent
    final Path stripePath = Path();
    stripePath.moveTo(project(w + 0.01, 0.3, 2.3, size).dx, project(w + 0.01, 0.3, 2.3, size).dy);
    stripePath.lineTo(project(w + 0.01, 0.3, 8.0, size).dx, project(w + 0.01, 0.3, 8.0, size).dy);
    stripePath.lineTo(project(w + 0.01, 0.45, 8.0, size).dx, project(w + 0.01, 0.45, 8.0, size).dy);
    stripePath.lineTo(project(w + 0.01, 0.45, 2.3, size).dx, project(w + 0.01, 0.45, 2.3, size).dy);
    stripePath.close();
    canvas.drawPath(stripePath, stripePaint);

    // Dynamic Cairo second orange/yellow stripe
    if (metroType == 0) {
      final Paint secondaryStripe = Paint()..color = const Color(0xFFFFB800);
      final Path stripePath2 = Path();
      stripePath2.moveTo(project(w + 0.015, 0.46, 2.3, size).dx, project(w + 0.015, 0.46, 2.3, size).dy);
      stripePath2.lineTo(project(w + 0.015, 0.46, 8.0, size).dx, project(w + 0.015, 0.46, 8.0, size).dy);
      stripePath2.lineTo(project(w + 0.015, 0.52, 8.0, size).dx, project(w + 0.015, 0.52, 8.0, size).dy);
      stripePath2.lineTo(project(w + 0.015, 0.52, 2.3, size).dx, project(w + 0.015, 0.52, 2.3, size).dy);
      stripePath2.close();
      canvas.drawPath(stripePath2, secondaryStripe);
    }

    // Glowing windows along the side (yellow glow for passengers)
    final Paint windowPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);

    for (double zw = 3.0; zw < 8.0; zw += 1.4) {
      final Path window = Path();
      final Offset wl1 = project(w + 0.01, -0.2, zw, size);
      final Offset wl2 = project(w + 0.01, -0.2, zw + 0.8, size);
      final Offset wl3 = project(w + 0.01, 0.15, zw + 0.8, size);
      final Offset wl4 = project(w + 0.01, 0.15, zw, size);

      window.moveTo(wl1.dx, wl1.dy);
      window.lineTo(wl2.dx, wl2.dy);
      window.lineTo(wl3.dx, wl3.dy);
      window.lineTo(wl4.dx, wl4.dy);
      window.close();
      canvas.drawPath(window, windowPaint);
    }

    // ── 8. DRAW FRONT WINDSHIELD (Slanted cockpit glass) ──
    final Paint windshieldPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.95),
          const Color(0xFF0F172A).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    final Path cockpit = Path();
    cockpit.moveTo(pRoofFrontL.dx, pRoofFrontL.dy);
    cockpit.lineTo(pRoofFrontR.dx, pRoofFrontR.dy);
    cockpit.lineTo(pNoseTopR.dx, pNoseTopR.dy);
    cockpit.lineTo(pNoseTopL.dx, pNoseTopL.dy);
    cockpit.close();
    canvas.drawPath(cockpit, windshieldPaint);

    // Glass glare reflection (white sleek stripe)
    final Paint glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25);
    final Path glare = Path();
    glare.moveTo(pRoofFrontL.dx, pRoofFrontL.dy);
    glare.lineTo(pRoofFrontL.dx + (pRoofFrontR.dx - pRoofFrontL.dx) * 0.4, pRoofFrontL.dy);
    glare.lineTo(pNoseTopL.dx + (pNoseTopR.dx - pNoseTopL.dx) * 0.2, pNoseTopL.dy);
    glare.lineTo(pNoseTopL.dx, pNoseTopL.dy);
    glare.close();
    canvas.drawPath(glare, glarePaint);

    // ── 9. DRAW FRONT BUMPER / BULB NOSE (Cairo Metro has signature rounded nose, LRT has sleek pointed) ──
    final Paint nosePaint = Paint()
      ..color = metroType == 0 ? const Color(0xFFE2E8F0) : const Color(0xFF4F46E5);
    final Path nosePath = Path();
    nosePath.moveTo(pNoseTopL.dx, pNoseTopL.dy);
    nosePath.lineTo(pNoseTopR.dx, pNoseTopR.dy);
    nosePath.lineTo(pFloorFrontR.dx, pFloorFrontR.dy);
    nosePath.lineTo(pNoseBumperCenter.dx, pNoseBumperCenter.dy);
    nosePath.lineTo(pFloorFrontL.dx, pFloorFrontL.dy);
    nosePath.close();
    canvas.drawPath(nosePath, nosePaint);

    // Draw nose accent colors
    final Paint noseAccent = Paint()
      ..color = metroType == 0 ? AppColors.primary : const Color(0xFF06B6D4);
    final Path noseAccentPath = Path();
    noseAccentPath.moveTo(pNoseBumperCenter.dx - 12, pNoseBumperCenter.dy - 8);
    noseAccentPath.lineTo(pNoseBumperCenter.dx + 12, pNoseBumperCenter.dy - 8);
    noseAccentPath.lineTo(pNoseBumperCenter.dx, pNoseBumperCenter.dy + 8);
    noseAccentPath.close();
    canvas.drawPath(noseAccentPath, noseAccent);

    // ── 10. DRAW GLOWING HEADLIGHT BULBS ──
    final double lightSize = 5.0 + (boostProgress * 3.0);

    // Draw active glowing halo first
    final Paint headlightHaloPaint = Paint()
      ..color = metroType == 0 ? Colors.yellow : const Color(0xFF22D3EE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(frontLeftLight, lightSize * 2.0, headlightHaloPaint);
    canvas.drawCircle(frontRightLight, lightSize * 2.0, headlightHaloPaint);

    // Draw bright white center bulb on top
    final Paint headlightBulbPaint = Paint()
      ..color = Colors.white;
    canvas.drawCircle(frontLeftLight, lightSize, headlightBulbPaint);
    canvas.drawCircle(frontRightLight, lightSize, headlightBulbPaint);

    // Draw active sparks on boost tap!
    if (boostProgress > 0 && sparks.isNotEmpty) {
      final Paint sparkPaint = Paint()
        ..color = metroType == 0 ? Colors.orangeAccent : const Color(0xFF06B6D4)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (var spark in sparks) {
        // Project sparks moving away from wheel area
        final double sparkZ = 2.2 + (boostProgress * 2.0);
        final double sparkY = spark.y + (boostProgress * 0.4);
        final double sparkX = spark.x + (boostProgress * (spark.x < 0 ? -1.0 : 1.0) * 0.8);
        final Offset sparkPos = project(sparkX, sparkY, sparkZ, size);

        // draw tiny spark trails
        canvas.drawCircle(sparkPos, 2.0, sparkPaint);
        canvas.drawLine(
          sparkPos,
          Offset(sparkPos.dx - (spark.x < 0 ? -6 : 6), sparkPos.dy - 4),
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeDMetroPainter oldDelegate) {
    return oldDelegate.cruiseProgress != cruiseProgress ||
        oldDelegate.boostProgress != boostProgress ||
        oldDelegate.bobOffset != bobOffset ||
        oldDelegate.tiltOffset != tiltOffset ||
        oldDelegate.sparks != sparks;
  }
}
