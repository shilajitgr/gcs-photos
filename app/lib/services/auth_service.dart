import 'package:firebase_auth/firebase_auth.dart';

/// Wrapper around [FirebaseAuth] for sign-in / sign-out operations.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google via popup/redirect.
  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    return _auth.signInWithProvider(provider);
  }

  /// Sign in with Apple.
  Future<UserCredential> signInWithApple() async {
    final provider = AppleAuthProvider();
    return _auth.signInWithProvider(provider);
  }

  /// Get the current Firebase ID token for API authorization.
  Future<String?> getIdToken() {
    return currentUser?.getIdToken() ?? Future.value(null);
  }

  /// Sign out of all providers.
  Future<void> signOut() => _auth.signOut();
}
