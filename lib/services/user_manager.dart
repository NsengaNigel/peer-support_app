import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'admin_service.dart';
import 'chat_service.dart';

// Simple user data model for backward compatibility
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

// User manager for both web and mobile with admin support
class UserManager {
  static AppUser? _currentUser;
  static UserModel? _currentUserModel;
  static final AdminService _adminService = AdminService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user (backward compatibility)
  static AppUser? get currentUser => _currentUser;
  
  // Get current user with admin roles
  static UserModel? get currentUserModel => _currentUserModel;
  
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
    
    // Also create/update UserModel for admin system
    _currentUserModel = UserModel(
      uid: _currentUser!.uid,
      email: email,
      displayName: displayName ?? email.split('@')[0],
      emailVerified: emailVerified,
      creationTime: DateTime.now(),
    );
  }
  
  // Set Firebase user (for mobile) with admin support
  static Future<void> setFirebaseUser(dynamic firebaseUser) async {
    if (firebaseUser != null) {
      // Set basic user info immediately for UI responsiveness
      _currentUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        emailVerified: firebaseUser.emailVerified ?? false,
        creationTime: firebaseUser.metadata?.creationTime,
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0],
      );
      
      // Load user model in background without blocking UI
      _loadUserModelInBackground(firebaseUser);
      
      // Ensure user is also in chat_users collection (non-blocking)
      _ensureChatUserExists(firebaseUser);
    } else {
      _currentUser = null;
      _currentUserModel = null;
    }
  }
  
  // Load user model from Firestore or create new one (background task)
  static Future<void> _loadUserModelInBackground(User firebaseUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists) {
        // User exists, load their data
        _currentUserModel = UserModel.fromSnapshot(userDoc);
        
        if (kDebugMode) {
          print('Loaded user model for: ${firebaseUser.email}');
          print('User role: ${_currentUserModel!.role.name}');
          print('Is admin: ${_currentUserModel!.isAdmin}');
          print('Is super admin: ${_currentUserModel!.isSuperAdmin}');
        }
        
        // Update last login time (non-blocking)
        _firestore.collection('users').doc(firebaseUser.uid).update({
          'lastLoginTime': Timestamp.fromDate(DateTime.now()),
        }).catchError((e) {
          if (kDebugMode) {
            print('Warning: Failed to update last login time: $e');
          }
        });
      } else {
        // New user, create default UserModel
        _currentUserModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          emailVerified: firebaseUser.emailVerified,
          creationTime: firebaseUser.metadata.creationTime,
          lastLoginTime: DateTime.now(),
        );
        
        // Save to Firestore (non-blocking)
        _firestore.collection('users').doc(firebaseUser.uid).set(_currentUserModel!.toMap())
            .catchError((e) {
          if (kDebugMode) {
            print('Warning: Failed to save user model: $e');
          }
        });
        
        if (kDebugMode) {
          print('Created new user profile for: ${firebaseUser.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user model: $e');
      }
      // Fallback to basic user model
      _currentUserModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        emailVerified: firebaseUser.emailVerified,
        creationTime: firebaseUser.metadata.creationTime,
        lastLoginTime: DateTime.now(),
      );
    }
  }
  
  // Ensure chat user exists (non-blocking)
  static Future<void> _ensureChatUserExists(User firebaseUser) async {
    try {
      await ChatService().getOrCreateUser(
        firebaseUser.uid,
        firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to ensure chat user exists: $e');
      }
    }
  }
  
  // Clear user
  static void clearUser() {
    _currentUser = null;
    _currentUserModel = null;
    
    if (kDebugMode) {
      print('UserManager: User state cleared');
    }
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
    
    if (_currentUserModel != null) {
      _currentUserModel = _currentUserModel!.copyWith(
        displayName: displayName,
        email: email,
        emailVerified: emailVerified,
      );
    }
  }
  
  // Refresh current user model from Firestore
  static Future<void> refreshUserModel() async {
    if (_currentUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          _currentUserModel = UserModel.fromSnapshot(userDoc);
          
          if (kDebugMode) {
            print('UserManager: User model refreshed from Firestore');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing user model: $e');
        }
      }
    }
  }
  
  // Check if current user is admin
  static bool get isCurrentUserAdmin => _currentUserModel?.isAdmin ?? false;
  
  // Check if current user is moderator  
  static bool get isCurrentUserModerator => _currentUserModel?.isModerator ?? false;
  
  // Check if current user is super admin
  static bool get isCurrentUserSuperAdmin => _currentUserModel?.isSuperAdmin ?? false;
  
  // Check if current user can moderate a community
  static bool canModerateCommunity(String communityId) {
    return _currentUserModel?.canModerateCommunity(communityId) ?? false;
  }
  
  // Initialize super admin (call once with your email)
  static Future<void> initializeSuperAdmin(String email) async {
    await _adminService.initializeSuperAdmin(email);
    
    // Refresh current user if they're the one being made super admin
    if (_currentUser?.email.toLowerCase() == email.toLowerCase()) {
      await refreshUserModel();
    }
  }
  
  // Get user role display name
  static String get currentUserRoleDisplay {
    if (_currentUserModel == null) return 'User';
    return _currentUserModel!.role.name;
  }
  
  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;
  
  // Get current user email
  static String? get currentUserEmail => _currentUser?.email;
  
  // Get current user display name
  static String? get currentUserDisplayName => _currentUser?.displayName;
} 