import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/auth_cubit.dart';

// ── Login Page – تصميم مطابق لموقع QuickIn ────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── QuickIn colour palette ────────────────────────────────────────────────
  static const Color _maroon = Color(0xFF5B0F16);
  static const Color _cream = Color(0xFFF7F3F0);
  static const Color _divider = Color(0xFFD4C9BE);
  static const Color _textDim = Color(0xFF666666);
  static const Color _textDark = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _toast(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: isError ? _maroon : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _googleSignIn() async {
    await context.read<AuthCubit>().signInWithGoogle();
  }

  Future<void> _emailLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _toast('من فضلك أدخل البريد وكلمة المرور');
      return;
    }
    await context.read<AuthCubit>().signInWithEmail(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthSuccess) {
          _toast('أهلاً ${state.displayName ?? ''}! تم تسجيل الدخول ✓',
              isError: false);
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          _toast(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: _cream,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SafeArea(
              child: Column(
                children: [
                  // ── Close button ──────────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: _CloseButton(onTap: () => Navigator.pop(context)),
                    ),
                  ),

                  // ── Scrollable form ───────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Title
                          Text('تسجيل الدخول',
                              style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark)),
                          const SizedBox(height: 6),
                          Text('مرحباً بعودتك',
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: _textDim)),
                          const SizedBox(height: 28),

                          // ── Google button ─────────────────────────────────
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (ctx, state) {
                              final loading = state is AuthLoading;
                              return _SocialBtn(
                                onTap: loading ? null : _googleSignIn,
                                loading: loading,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!loading) ...[
                                      const _GoogleLogo(),
                                      const SizedBox(width: 12),
                                    ],
                                    if (loading)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: _maroon),
                                      )
                                    else
                                      Text('متابعة بجوجل',
                                          style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _textDark)),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Apple button ──────────────────────────────────
                          _SocialBtn(
                            onTap: () {},
                            loading: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.apple,
                                    size: 22, color: _textDark),
                                const SizedBox(width: 12),
                                Text('متابعة بـ Apple',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),

                          // ── OR divider ────────────────────────────────────
                          Row(children: [
                            const Expanded(
                                child: Divider(color: _divider)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('أو',
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: _maroon,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const Expanded(
                                child: Divider(color: _divider)),
                          ]),
                          const SizedBox(height: 22),

                          // ── Email field ───────────────────────────────────
                          _Label('البريد الإلكتروني'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _emailCtrl,
                            hint: 'example@email.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // ── Password field ────────────────────────────────
                          Row(children: [
                            Expanded(child: _Label('كلمة المرور')),
                            GestureDetector(
                              onTap: () {},
                              child: Text('نسيت كلمة المرور؟',
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: _maroon,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _passwordCtrl,
                            hint: '••••••••',
                            obscure: _obscure,
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF888888),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // ── Login button ──────────────────────────────────
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (ctx, state) {
                              final loading = state is AuthLoading;
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: loading ? null : _emailLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _maroon,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        _maroon.withValues(alpha: 0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white),
                                        )
                                      : Text('تسجيل الدخول',
                                          style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700)),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 22),

                          // ── Sign-up link ──────────────────────────────────
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(
                                    fontSize: 14, color: const Color(0xFF555555)),
                                children: [
                                  const TextSpan(text: 'ليس لديك حساب؟ '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text('إنشاء حساب',
                                          style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: _maroon,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: const Icon(Icons.close, size: 18, color: Color(0xFF333333)),
        ),
      );
}

class _SocialBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final Widget child;
  const _SocialBtn(
      {required this.onTap, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.65 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFD4C9BE), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: child,
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A)));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        textDirection: TextDirection.ltr,
        style: GoogleFonts.outfit(
            fontSize: 15, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
              color: const Color(0xFFAAAAAA),
              fontSize: obscure ? 20 : 14),
          filled: true,
          fillColor: const Color(0xFFF0EBE5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFD4C9BE), width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF5B0F16), width: 1.5)),
        ),
      );
}

// ── Google Logo (painted circles – no assets needed) ─────────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(22, 22), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size sz) {
    final cx = sz.width / 2;
    final cy = sz.height / 2;
    final r = sz.width / 2;

    // Background circle
    canvas.drawCircle(
        Offset(cx, cy), r, Paint()..color = Colors.white);

    // Red arc
    _arc(canvas, cx, cy, r - 2, -1.1, 1.75, const Color(0xFFEA4335));
    // Yellow arc
    _arc(canvas, cx, cy, r - 2, 0.65, 1.1, const Color(0xFFFBBC05));
    // Green arc
    _arc(canvas, cx, cy, r - 2, 1.75, 1.1, const Color(0xFF34A853));
    // Blue arc
    _arc(canvas, cx, cy, r - 2, 2.85, 2.4, const Color(0xFF4285F4));

    // White center + horizontal bar (the "G" cutout)
    canvas.drawCircle(
        Offset(cx, cy), r * 0.45, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - 2.5, cx + r, cy + 2.5),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawCircle(
        Offset(cx, cy), r * 0.30, Paint()..color = Colors.white);
  }

  void _arc(Canvas c, double cx, double cy, double r, double start,
      double sweep, Color color) {
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      start,
      sweep,
      true,
      Paint()..color = color,
    );
    c.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
