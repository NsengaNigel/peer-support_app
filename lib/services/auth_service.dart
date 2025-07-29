import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'user_manager.dart';
import 'chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

  /// Sign in user with email and password
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

  /// Sign out user with proper cleanup
  Future<void> signOut() async {
    try {
      // Get current user before signing out
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Update user status to offline in chat service
        try {
          await ChatService().updateUserStatus(currentUser.uid, isOnline: false);
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Failed to update chat user status: $e');
          }
        }
      }
      
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Clear user manager state
      UserManager.clearUser();
      
      if (kDebugMode) {
        print('User signed out successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth error during sign out: $e');
      }
      // Still clear local state even if Firebase sign out fails
      UserManager.clearUser();
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign out: $e');
      }
      // Still clear local state even if sign out fails
      UserManager.clearUser();
      rethrow;
    }
  }

  /// Comprehensive logout with all cleanup tasks
  Future<void> logoutWithCleanup() async {
    try {
      if (kDebugMode) {
        print('Starting comprehensive logout process...');
      }
      
      // Get current user before signing out
      final currentUser = _auth.currentUser;
      
      // Start all cleanup tasks concurrently for better performance
      final cleanupTasks = <Future<void>>[];
      
      if (currentUser != null) {
        // 1. Update chat service status (non-blocking)
        cleanupTasks.add(
          ChatService().updateUserStatus(currentUser.uid, isOnline: false)
              .catchError((e) {
            if (kDebugMode) {
              print('Warning: Failed to update chat user status: $e');
            }
          })
        );
        
        // 2. Update last login time in Firestore (non-blocking)
        cleanupTasks.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'lastLoginTime': FieldValue.serverTimestamp(),
          }).catchError((e) {
            if (kDebugMode) {
              print('Warning: Failed to update last login time: $e');
            }
          })
        );
      }
      
      // 3. Sign out from Firebase Auth (blocking - must complete)
      await _auth.signOut();
      if (kDebugMode) {
        print('Signed out from Firebase Auth');
      }
      
      // 4. Clear user manager state immediately
      UserManager.clearUser();
      if (kDebugMode) {
        print('Cleared user manager state');
      }
      
      // 5. Wait for cleanup tasks to complete (with timeout)
      if (cleanupTasks.isNotEmpty) {
        try {
          await Future.wait(cleanupTasks).timeout(
            Duration(seconds: 3),
          );
        } on TimeoutException {
          if (kDebugMode) {
            print('Warning: Some cleanup tasks timed out');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Some cleanup tasks failed: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('Comprehensive logout completed successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth error during logout: $e');
      }
      // Still clear local state even if Firebase sign out fails
      UserManager.clearUser();
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during logout: $e');
      }
      // Still clear local state even if logout fails
      UserManager.clearUser();
      rethrow;
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

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
