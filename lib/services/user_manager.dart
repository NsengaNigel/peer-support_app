import 'package:flutter/foundation.dart';

// Simple user data model
class AppUser {
  final String uid;
  final String email;
  final bool emailVerified;
  final DateTime? creationTime;
  final String? displayName;

  AppUser({
    required this.uid,
    required this.email,
    this.emailVerified = false,
    this.creationTime,
    this.displayName,
  });
}

// User manager for both web and mobile
class UserManager {
  static AppUser? _currentUser;
  
  // Get current user
  static AppUser? get currentUser => _currentUser;
  
  // Set user (for web testing)
  static void setUser({
    required String email,
    String? displayName,
    bool emailVerified = false,
  }) {
    _currentUser = AppUser(
      uid: kIsWeb ? 'web_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}' : 'mobile_user',
      email: email,
      emailVerified: emailVerified,
      creationTime: DateTime.now(),
      displayName: displayName ?? email.split('@')[0],
    );
  }
  
  // Set Firebase user (for mobile)
  static void setFirebaseUser(dynamic firebaseUser) {
    if (firebaseUser != null) {
      _currentUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        emailVerified: firebaseUser.emailVerified ?? false,
        creationTime: firebaseUser.metadata?.creationTime,
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0],
      );
    } else {
      _currentUser = null;
    }
  }
  
  // Clear user
  static void clearUser() {
    _currentUser = null;
  }
  
  // Update user info
  static void updateUser({
    String? displayName,
    String? email,
    bool? emailVerified,
  }) {
    if (_currentUser != null) {
      _currentUser = AppUser(
        uid: _currentUser!.uid,
        email: email ?? _currentUser!.email,
        emailVerified: emailVerified ?? _currentUser!.emailVerified,
        creationTime: _currentUser!.creationTime,
        displayName: displayName ?? _currentUser!.displayName,
      );
    }
  }
} 