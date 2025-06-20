// auth.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Currently signed-in user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Register with email/password.
  ///
  /// Throws [FirebaseAuthException] with code:
  /// - 'email-already-in-use' if the email exists.
  /// - 'invalid-email' if the email format is bad.
  /// - etc.
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email/password.
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Trigger Google Sign-In flow & authenticate with Firebase.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Sign out from both Google and Firebase.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  /// Send a verification email to the currently signed-in user.
  Future<void> sendEmailVerification() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Cannot send email verification: no user is signed in.',
      );
    }
    return user.sendEmailVerification();
  }

  /// Change password, re-authenticating with the current credentials first.
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Cannot change password: no user is signed in.',
      );
    }
    // Re-authenticate
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    // Update
    await user.updatePassword(newPassword);
  }

  /// Update display name and/or photoURL for the current user.
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Cannot update profile: no user is signed in.',
      );
    }
    return user.updateDisplayName(displayName).then((_) {
      if (photoURL != null) {
        return user.updatePhotoURL(photoURL);
      }
    });
  }
}
