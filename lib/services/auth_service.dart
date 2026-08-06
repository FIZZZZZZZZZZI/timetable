import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown by [AuthService.signInWithGoogle] for any failure that should be
/// shown to the user, with a message that's already safe to display as-is.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the user backs out of the sign-in flow themselves — not a
/// real error, so callers should treat it as a silent no-op rather than
/// showing an error message.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Thin wrapper around Firebase Auth + Google Sign-In. Pure service layer:
/// no BuildContext. Screens react to [authStateChanges] to decide between
/// the login screen and the main app, and catch [AuthException] /
/// [AuthCancelledException] from [signInWithGoogle].
///
/// Auth only — this never touches Hive. All existing local data (activity
/// slots, completions, XP/streaks, prayer cache, themes) is untouched by
/// signing in or out.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithGoogle() async {
    await init();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      throw AuthException(_messageForGoogleSignInError(e));
    } catch (_) {
      throw const AuthException(
        'Could not reach Google. Check your internet connection and try again.',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return a valid sign-in token. Please try again.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    try {
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Firebase sign-in failed. Please try again.');
    } catch (_) {
      throw const AuthException(
        'Could not sign in. Check your internet connection and try again.',
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait<void>([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _messageForGoogleSignInError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return "Google Sign-In isn't configured correctly for this app yet.";
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
      case GoogleSignInExceptionCode.canceled:
        return "Sign-in didn't complete. Check your internet connection and try again.";
    }
  }
}
