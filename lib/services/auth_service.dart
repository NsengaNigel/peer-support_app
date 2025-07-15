import 'package:flutter/foundation.dart';

// AuthService placeholder - partner will implement authentication
class AuthService {
  // Placeholder methods for compatibility
  dynamic get currentUser => null;
  
  // Placeholder stream
  Stream<dynamic> get authStateChanges => Stream.value(null);
  
  // Placeholder - partner will implement authentication
  Future<dynamic> signUpWithEmailAndPassword(String email, String password) async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<dynamic> signInWithEmailAndPassword(String email, String password) async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<void> signOut() async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<void> sendPasswordResetEmail(String email) async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<void> sendEmailVerification() async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<void> reloadUser() async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    throw 'Authentication will be implemented by partner';
  }
  
  // Placeholder - partner will implement authentication
  Future<void> deleteAccount() async {
    throw 'Authentication will be implemented by partner';
  }
} 