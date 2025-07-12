// Firebase Auth Service (for Android/iOS)
// Commented out for web testing - uncomment when using on Android/iOS

// import 'package:firebase_auth/firebase_auth.dart';

// Placeholder AuthService for web compatibility
class AuthService {
  // This is a placeholder service for web testing
  // When using on Android/iOS, uncomment the Firebase imports above
  // and implement the real Firebase authentication methods
  
  dynamic get currentUser => null;
  
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    throw 'Use WebAuthService for web testing';
  }
  
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    throw 'Use WebAuthService for web testing';
  }
  
  Future<void> signOut() async {
    throw 'Use WebAuthService for web testing';
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    throw 'Use WebAuthService for web testing';
  }
} 