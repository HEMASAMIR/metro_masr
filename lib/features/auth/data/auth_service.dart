import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ────────────────────────────────────────────────────────────────────────────
// AuthUser – simple model; NO Firebase dependency whatsoever
// ────────────────────────────────────────────────────────────────────────────
class AuthUser {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AuthUser({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// AuthService – Google Sign-In via google_sign_in ONLY (no Firebase)
//
// Android setup (one-time, Google Cloud Console – NOT Firebase):
//   1. console.cloud.google.com → New Project → Enable "Google Identity" API
//   2. Credentials → Create Credentials → OAuth 2.0 Client ID
//      • Application type: Android
//      • Package name: com.example.rafiq_metrro   (your package)
//      • SHA-1: run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey`
//   3. Also create a "Web application" OAuth Client ID and paste it below
//      as `serverClientId` (needed to get the idToken).
//   4. No google-services.json required!
// ────────────────────────────────────────────────────────────────────────────
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Replace with your Web client ID from Google Cloud Console ──────────────
  static const String _webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId is required to receive an idToken on Android/iOS
    serverClientId: _webClientId == 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
        ? null   // skip when placeholder not replaced yet
        : _webClientId,
  );

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  // ── Restore session persisted from last launch ──────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('auth_user_id');
    if (id != null) {
      _currentUser = AuthUser(
        id: id,
        displayName: prefs.getString('auth_display_name'),
        email: prefs.getString('auth_email'),
        photoUrl: prefs.getString('auth_photo_url'),
      );
    }
  }

  // ── Google Sign-In (no Firebase) ────────────────────────────────────────────
  Future<AuthUser?> signInWithGoogle() async {
    // Try silent sign-in first (returns null if no prior session)
    GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn(); // interactive prompt

    if (account == null) return null; // user cancelled

    _currentUser = AuthUser(
      id: account.id,
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );
    await _persist(_currentUser!);
    return _currentUser;
  }

  // ── Email/Password (local – swap for your backend if needed) ───────────────
  Future<AuthUser?> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.length < 6) return null;

    _currentUser = AuthUser(
      id: 'email_${email.hashCode}',
      displayName: email.split('@').first,
      email: email,
    );
    await _persist(_currentUser!);
    return _currentUser;
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_display_name');
    await prefs.remove('auth_email');
    await prefs.remove('auth_photo_url');
  }

  // ── Persist session ─────────────────────────────────────────────────────────
  Future<void> _persist(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_id', user.id);
    if (user.displayName != null) {
      await prefs.setString('auth_display_name', user.displayName!);
    }
    if (user.email != null) await prefs.setString('auth_email', user.email!);
    if (user.photoUrl != null) {
      await prefs.setString('auth_photo_url', user.photoUrl!);
    }
  }
}
