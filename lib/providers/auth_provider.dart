import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _sub = _authService.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  User? _user;
  User? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setError(null);
    _setLoading(true);
    try {
      final credential = await _authService.signInWithEmail(email, password);

      // Check if email is verified
      if (credential.user != null && !credential.user!.emailVerified) {
        await _authService.signOut();
        _setError(
          'Please verify your email before signing in. Check your inbox.',
        );
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_humanizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_humanizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_humanizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() => _authService.signOut();

  String _humanizeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'Account disabled';
      case 'user-not-found':
        return 'No user found with that email';
      case 'wrong-password':
        return 'Invalid credentials';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password too weak (min 6 characters)';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return e.message ?? 'Authentication error';
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
