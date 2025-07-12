import 'package:flutter/foundation.dart';

// Simple user storage for web testing
class UserRegistry {
  static final Map<String, String> _registeredUsers = {};
  
  // Pre-registered test users
  static void _initializeTestUsers() {
    if (_registeredUsers.isEmpty) {
      _registeredUsers.addAll({
        'test@example.com': 'password123',
        'demo@demo.com': 'demo123',
        'admin@test.com': 'admin123',
      });
    }
  }
  
  // Register a new user
  static bool registerUser(String email, String password) {
    _initializeTestUsers();
    
    if (_registeredUsers.containsKey(email.toLowerCase())) {
      return false; // User already exists
    }
    
    _registeredUsers[email.toLowerCase()] = password;
    return true; // Successfully registered
  }
  
  // Check if user exists and password is correct
  static bool authenticateUser(String email, String password) {
    _initializeTestUsers();
    
    final storedPassword = _registeredUsers[email.toLowerCase()];
    return storedPassword != null && storedPassword == password;
  }
  
  // Check if user exists (for checking duplicates)
  static bool userExists(String email) {
    _initializeTestUsers();
    return _registeredUsers.containsKey(email.toLowerCase());
  }
  
  // Get all registered users (for debugging)
  static List<String> getAllRegisteredEmails() {
    _initializeTestUsers();
    return _registeredUsers.keys.toList();
  }
  
  // Clear all users (for testing)
  static void clearAllUsers() {
    _registeredUsers.clear();
  }
} 