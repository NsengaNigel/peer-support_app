import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Register a new user with email and password
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'This email is already in use.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is not valid.';
      } else if (e.code == 'weak-password') {
        throw 'The password is too weak.';
      } else {
        throw 'Error: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is not valid.';
      } else {
        throw 'Failed to send password reset email: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// (Optional for future use) Sign in user
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw 'Incorrect email or password.';
      } else {
        throw 'Login failed: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }
}
