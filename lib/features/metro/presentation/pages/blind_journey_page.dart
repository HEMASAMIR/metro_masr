import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/voice_service.dart';
import '../../domain/entities/station.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-screen, high-contrast, TTS-guided journey mode for blind/visually impaired users.
/// Each step is spoken on entry; large buttons; haptic pulse on advance.
class BlindJourneyPage extends StatefulWidget {
  final List<Station> path;          // ordered list from start → destination
  final int ticketPrice;

  const BlindJourneyPage({
    super.key,
    required this.path,
    required this.ticketPrice,
  });

  @override
  State<BlindJourneyPage> createState() => _BlindJourneyPageState();
}

class _BlindJourneyPageState extends State<BlindJourneyPage>
    with TickerProviderStateMixin {
  int _currentStep = 0;          // index within widget.path
  bool _isAnnouncing = false;
  bool _isArabic = true;

  late AnimationController _pulseCtrl;
  late AnimationController _stepCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _stepAnim;

  // ─────────────────────────────────── lifecycle ───────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stepAnim = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutBack);

    // auto-announce on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceStep());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _stepCtrl.dispose();
    VoiceService.stop();
    super.dispose();
  }

  // ─────────────────────────────────── helpers ─────────────────────────────
  Station get _currentStation => widget.path[_currentStep];
  bool   get _isFirst        => _currentStep == 0;
  bool   get _isLast         => _currentStep == widget.path.length - 1;
  int    get _remaining      => widget.path.length - 1 - _currentStep;

  Color get _lineColor {
    switch (_currentStation.line) {
      case 1: return AppColors.line1;
      case 2: return AppColors.line2;
      default: return AppColors.line3;
    }
  }

  String _buildAnnouncement() {
    final name = _isArabic ? _currentStation.nameAr : _currentStation.nameEn;
    if (_isFirst) {
      final dest = _isArabic
          ? widget.path.last.nameAr
          : widget.path.last.nameEn;
      return _isArabic
          ? 'وضع المكفوفين مفعّل. رحلتك من $name إلى $dest. '
            'المحطات المتبقية: ${widget.path.length - 1}. '
            'استقل الخط ${_currentStation.line}.'
          : 'Blind mode active. Trip from $name to $dest. '
            '${widget.path.length - 1} stops ahead. '
            'Take Line ${_currentStation.line}.';
    }
    if (_isLast) {
      return _isArabic
          ? 'وصلت! هذه محطة الوصول: $name. أهلاً وسهلاً. اضغط زر الإنهاء.'
          : 'You have arrived at $name. Your destination! Press Exit.';
    }
    if (_currentStation.isTransfer) {
      final nextStation = widget.path[_currentStep + 1];
      final nextLine = nextStation.line;
      return _isArabic
          ? 'محطة تبديل: $name. غيّر للخط $nextLine الآن. '
            'باقي $_remaining محطة.'
          : 'Transfer station: $name. Switch to Line $nextLine now. '
            '$_remaining stops remaining.';
    }
    return _isArabic
        ? 'المحطة الحالية: $name. باقي $_remaining محطة حتى وصولك.'
        : 'Current station: $name. $_remaining stops to go.';
  }

  Future<void> _announceStep() async {
    if (_isAnnouncing || !mounted) return;
    setState(() => _isAnnouncing = true);
    _stepCtrl.reset();
    _stepCtrl.forward();

    final lang = _isArabic ? 'ar-EG' : 'en-US';
    await VoiceService.speak(_buildAnnouncement(), lang);

    if (mounted) setState(() => _isAnnouncing = false);
  }

  Future<void> _repeatAnnouncement() async {
    await HapticFeedback.lightImpact();
    await _announceStep();
  }

  Future<void> _nextStep() async {
    if (_isLast || _isAnnouncing) return;
    await HapticFeedback.heavyImpact();
    setState(() => _currentStep++);
    await _announceStep();
  }

  Future<void> _prevStep() async {
    if (_isFirst || _isAnnouncing) return;
    await HapticFeedback.mediumImpact();
    setState(() => _currentStep--);
    await _announceStep();
  }

  void _showPanicDialog() {
    HapticFeedback.vibrate();
    VoiceService.speak(
      _isArabic
          ? 'تم الضغط على زر الطوارئ. أرجوك انتظر المساعدة.'
          : 'Emergency button pressed. Please wait for assistance.',
      _isArabic ? 'ar-EG' : 'en-US',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Text(
          '🆘 طوارئ / Emergency',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ابق مكانك وانتظر الموظف\nStay where you are — staff notified',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _isArabic
                        ? 'محطتك الحالية:'
                        : 'Your current station:',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isArabic ? _currentStation.nameAr : _currentStation.nameEn,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _isArabic ? 'الخط ${_currentStation.line}' : 'Line ${_currentStation.line}',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق / Close',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────── UI ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / widget.path.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(progress),
            Expanded(child: _buildMainContent()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '♿ وضع المكفوفين',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Blind Assist Mode',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          // Language toggle
          GestureDetector(
            onTap: () async {
              setState(() => _isArabic = !_isArabic);
              await _announceStep();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _isArabic ? 'EN' : 'عربي',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Emergency
          GestureDetector(
            onTap: _showPanicDialog,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: const Icon(Icons.sos_rounded, color: Colors.red, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────
  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isArabic
                    ? 'المحطة ${_currentStep + 1} من ${widget.path.length}'
                    : 'Stop ${_currentStep + 1} of ${widget.path.length}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              Text(
                _isArabic
                    ? '${(progress * 100).toInt()}% مكتمل'
                    : '${(progress * 100).toInt()}% done',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(_lineColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildMainContent() {
    return ScaleTransition(
      scale: _stepAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Line badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _lineColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _lineColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: _lineColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? 'الخط ${_currentStation.line}' : 'Line ${_currentStation.line}',
                    style: TextStyle(
                        color: _lineColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Station icon (pulsing)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: _isLast ? _pulseAnim.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _lineColor,
                      _lineColor.withOpacity(0.5),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _lineColor.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _isFirst
                      ? Icons.trip_origin_rounded
                      : _isLast
                          ? Icons.location_on_rounded
                          : _currentStation.isTransfer
                              ? Icons.swap_horiz_rounded
                              : Icons.train_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Station name (LARGE)
            Text(
              _isArabic
                  ? _currentStation.nameAr
                  : _currentStation.nameEn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Step label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isFirst
                    ? Colors.green.withOpacity(0.2)
                    : _isLast
                        ? Colors.amber.withOpacity(0.2)
                        : _currentStation.isTransfer
                            ? Colors.purple.withOpacity(0.2)
                            : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFirst
                      ? Colors.green.withOpacity(0.5)
                      : _isLast
                          ? Colors.amber.withOpacity(0.5)
                          : _currentStation.isTransfer
                              ? Colors.purple.withOpacity(0.5)
                              : Colors.white12,
                ),
              ),
              child: Text(
                _isFirst
                    ? (_isArabic ? '🟢 محطة البداية' : '🟢 Start Station')
                    : _isLast
                        ? (_isArabic ? '🏁 وصلت! هذه وجهتك' : '🏁 You arrived!')
                        : _currentStation.isTransfer
                            ? (_isArabic
                                ? '🔄 محطة تبديل — غيّر الخط'
                                : '🔄 Transfer — Change Line')
                            : (_isArabic
                                ? '⬛ باقي $_remaining محطة'
                                : '⬛ $_remaining stops left'),
                style: TextStyle(
                  color: _isFirst
                      ? Colors.green
                      : _isLast
                          ? Colors.amber
                          : _currentStation.isTransfer
                              ? Colors.purple.shade200
                              : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Repeat button
            GestureDetector(
              onTap: _repeatAnnouncement,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: _isAnnouncing
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAnnouncing
                          ? Icons.volume_up_rounded
                          : Icons.replay_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isAnnouncing
                          ? (_isArabic ? '🔊 جاري الإعلان...' : '🔊 Announcing...')
                          : (_isArabic ? 'تكرار الإعلان' : 'Repeat Announcement'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom controls ───────────────────────────────────────────────────────
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: _BigButton(
              label: _isArabic ? 'السابق' : 'Previous',
              icon: Icons.arrow_back_ios_new_rounded,
              color: Colors.white24,
              textColor: Colors.white,
              disabled: _isFirst || _isAnnouncing,
              onTap: _prevStep,
            ),
          ),
          const SizedBox(width: 12),

          // Next / Done
          Expanded(
            flex: 2,
            child: _BigButton(
              label: _isLast
                  ? (_isArabic ? '🏁 إنهاء الرحلة' : '🏁 End Journey')
                  : (_isArabic ? 'التالي ← ' : 'Next →'),
              icon: _isLast ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: _isLast ? Colors.amber : _lineColor,
              textColor: Colors.white,
              disabled: _isAnnouncing,
              onTap: _isLast ? () => Navigator.pop(context) : _nextStep,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable big accessible button ──────────────────────────────────────────
class _BigButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool disabled;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _tapAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _tapAnim = Tween<double>(begin: 1, end: 0.95)
        .animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.disabled ? null : (_) => _tapCtrl.forward(),
      onTapUp: widget.disabled
          ? null
          : (_) {
              _tapCtrl.reverse();
              widget.onTap();
            },
      onTapCancel: () => _tapCtrl.reverse(),
      child: ScaleTransition(
        scale: _tapAnim,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.disabled ? 0.35 : 1.0,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: widget.disabled
                  ? []
                  : [
                      BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.textColor, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
