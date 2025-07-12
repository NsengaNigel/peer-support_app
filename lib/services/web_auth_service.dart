import 'dart:async';

// Simulated User class for web testing
class WebUser {
  final String uid;
  final String? email;
  final bool emailVerified;
  final DateTime? creationTime;

  WebUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.creationTime,
  });
}

// Web-compatible auth service for testing
class WebAuthService {
  static WebUser? _currentUser;
  static late final StreamController<WebUser?> _authStateController;
  static bool _initialized = false;

  // Initialize the service
  static void initialize() {
    if (!_initialized) {
      _authStateController = StreamController<WebUser?>.broadcast();
      _currentUser = null;
      _initialized = true;
      
      // Immediately emit the initial state (no user logged in)
      Future.microtask(() {
        _authStateController.add(null);
      });
    }
  }

  // Get current user
  WebUser? get currentUser => _currentUser;

  // Auth state changes stream
  Stream<WebUser?> get authStateChanges {
    if (!_initialized) {
      initialize();
    }
    return _authStateController.stream;
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    // Simulate validation
    if (!isValidEmail(email)) {
      throw 'Please enter a valid email address.';
    }
    if (password.length < 6) {
      throw 'Password must be at least 6 characters long';
    }
    
    // Check if user already exists (simulate)
    final existingUsers = ['test@example.com', 'admin@test.com'];
    if (existingUsers.contains(email.toLowerCase())) {
      throw 'An account already exists with this email address.';
    }
    
    // Create new user
    _currentUser = WebUser(
      uid: 'web_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      emailVerified: false,
      creationTime: DateTime.now(),
    );
    
    _authStateController.add(_currentUser);
    
    // Simulate sending verification email
    print('📧 Verification email sent to $email (simulated)');
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    // Simulate validation
    if (!isValidEmail(email)) {
      throw 'Please enter a valid email address.';
    }
    if (password.isEmpty) {
      throw 'Please enter your password';
    }
    
    // Simulate login validation
    if (email.toLowerCase() == 'test@example.com' && password == 'password123') {
      _currentUser = WebUser(
        uid: 'web_test_user',
        email: email,
        emailVerified: true,
        creationTime: DateTime.now().subtract(Duration(days: 30)),
      );
    } else if (email.toLowerCase() == 'demo@demo.com' && password == 'demo123') {
      _currentUser = WebUser(
        uid: 'web_demo_user',
        email: email,
        emailVerified: true,
        creationTime: DateTime.now().subtract(Duration(days: 60)),
      );
    } else {
      // For any other email/password combination, create a user (for testing)
      _currentUser = WebUser(
        uid: 'web_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
        email: email,
        emailVerified: false,
        creationTime: DateTime.now(),
      );
    }
    
    _authStateController.add(_currentUser);
  }

  // Sign out
  Future<void> signOut() async {
    await Future.delayed(Duration(milliseconds: 300)); // Simulate network delay
    _currentUser = null;
    _authStateController.add(null);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    if (!isValidEmail(email)) {
      throw 'Please enter a valid email address.';
    }
    
    print('📧 Password reset email sent to $email (simulated)');
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    if (_currentUser != null) {
      print('📧 Verification email sent to ${_currentUser!.email} (simulated)');
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }
} 