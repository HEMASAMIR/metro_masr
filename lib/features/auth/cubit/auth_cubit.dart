import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_service.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String userId;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  AuthSuccess({
    required this.userId,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [userId, displayName, email, photoUrl];
}

class AuthSignedOut extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class AuthCubit extends Cubit<AuthState> {
  final AuthService _auth;

  AuthCubit(this._auth) : super(AuthInitial()) {
    _restoreSession();
  }

  void _restoreSession() {
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthSuccess(
        userId: user.id,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoUrl,
      ));
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        emit(AuthSuccess(
          userId: user.id,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoUrl,
        ));
      } else {
        emit(AuthInitial()); // user cancelled – no error
      }
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول بجوجل'));
    }
  }

  // ── Email / Password ────────────────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _auth.signInWithEmail(email, password);
      if (user != null) {
        emit(AuthSuccess(
          userId: user.id,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoUrl,
        ));
      } else {
        emit(AuthError('بريد إلكتروني أو كلمة مرور خاطئة'));
      }
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول'));
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    emit(AuthSignedOut());
  }
}
