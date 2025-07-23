import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication package
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess; // Callback to notify when login succeeds

  const LoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to get user input from text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // For form validation
  bool _isLoading = false; // Tracks loading state to disable buttons and show spinner
  String? _error; // Holds error message to display to user
  String _loadingMessage = 'Logging in...'; // Loading message to show user

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // Firebase Auth instance

  @override
  void dispose() {
    // Dispose controllers when screen is removed from widget tree
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Method called when user presses "Login" button
  /// Attempts Firebase Authentication with email and password
  void _login() async {
    if (!_formKey.currentState!.validate()) return; // Form must be valid

    setState(() {
      _isLoading = true;
      _error = null;
      _loadingMessage = 'Authenticating...';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sign in with Firebase using email and password
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() {
          _loadingMessage = 'Initializing app...';
        });
      }

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // If email not verified, send verification email
        await userCredential.user!.sendEmailVerification();

        if (mounted) {
          // Show warning SnackBar to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email not verified! Verification email sent. Please check your inbox.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Note: You can decide here if you want to block login until verified
      } else {
        // Email verified or verification not required, login successful
        if (mounted) {
          // Show success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back!'),
              backgroundColor: Colors.green,
            ),
          );

          // Call optional success callback (e.g., to navigate away)
          widget.onLoginSuccess?.call();
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle common Firebase auth errors with user-friendly messages
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      if (mounted) {
        setState(() {
          _error = message;
        });
      }
    } catch (e) {
      // Handle any other errors
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred. Please try again.';
        });
      }
    } finally {
      // Reset loading state to re-enable UI
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Method called when user taps "Forgot Password?"
  /// Sends Firebase password reset email
  void _forgotPassword() async {
    final email = _emailController.text.trim();

    // Validate email before attempting reset
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Send password reset email via Firebase
      await _firebaseAuth.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error if sending reset email fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Simple email validation regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient decoration
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey, // Form key for validation
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large welcome text at the top
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black26,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 60),

                      // White container holding the login form
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20.0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email input field
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!_isValidEmail(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),

                            // Password input field
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                obscureText: true, // Hide password input
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 12),

                            // "Forgot Password?" link aligned right
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF00BCD4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),

                            // Error message container if any error occurs
                            if (_error != null) ...[
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                            ],

                            // Login button with loading spinner
                            Container(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login, // Disable button when loading
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF00BCD4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            _loadingMessage,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),

                      // Bottom buttons for switching between Login and Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Disabled User login button (already on login screen)
                          Container(
                            width: 120,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF00BCD4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                'User Login',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),

                          // Button to navigate to Register screen (SignUpScreen)
                          Container(
                            width: 120,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => SignUpScreen(onSignUpSuccess: widget.onLoginSuccess),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                foregroundColor: Color(0xFF00BCD4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
