import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _lastSignInWasNewUser = false;

  AuthProvider(this._authService) {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userDisplayName => _authService.userDisplayName;
  String? get userEmail => _authService.userEmail;
  String? get userPhotoUrl => _authService.userPhotoUrl;
  String? get userId => _authService.userId;
  bool get lastSignInWasNewUser => _lastSignInWasNewUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        _lastSignInWasNewUser = false;
        _setLoading(false);
        _setError('Sign-in was cancelled. Please try again.');
        return false;
      }
      _lastSignInWasNewUser = result.additionalUserInfo?.isNewUser ?? false;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _lastSignInWasNewUser = false;
      _setLoading(false);
      _setError(_mapAuthError(e));
      return false;
    } catch (e) {
      _lastSignInWasNewUser = false;
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _lastSignInWasNewUser = false;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      case 'invalid-credential':
      case 'user-token-expired':
      case 'credential-too-old-login-again':
        return 'Your session expired. Please sign in again.';
      case 'network-request-failed':
        return 'Network unavailable. Check your internet connection.';
      case 'unsupported-platform':
        return 'Google sign-in is not supported on this platform.';
      case 'google-sign-in-failed':
        return error.message ?? 'Google sign-in failed. Please try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
