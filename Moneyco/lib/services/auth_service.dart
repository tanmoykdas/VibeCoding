import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const _defaultWebClientId =
      '486434722661-vpmlr6loobt8g5mnnthb3rhrfemlrrah.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn != null) return _googleSignIn!;

    if (!kIsWeb) {
      final unsupported =
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows;
      if (unsupported) {
        throw FirebaseAuthException(
          code: 'unsupported-platform',
          message:
              'Google sign-in is supported on Android, iOS, macOS, and Web.',
        );
      }
    }

    if (kIsWeb) {
      _googleSignIn = GoogleSignIn();
    } else {
      const dartDefinedClientId = String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
      );
      final webClientId = dartDefinedClientId.isEmpty
          ? _defaultWebClientId
          : dartDefinedClientId;

      _googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: webClientId,
      );
    }

    return _googleSignIn!;
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        return await _auth.signInWithPopup(provider);
      }

      final googleSignIn = _getGoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
      await _googleSignIn!.disconnect().catchError((_) => null);
    }
  }

  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoUrl => _auth.currentUser?.photoURL;
  String? get userId => _auth.currentUser?.uid;
}
