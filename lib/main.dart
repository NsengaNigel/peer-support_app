import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
// Firebase imports (for Authentication and Firestore chat)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/user_manager.dart';
import 'services/chat_service.dart';
import 'screens/auth/login_screen.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';
import 'services/auth_service.dart'; // Added import for AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for Authentication and Firestore chat functionality
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBuo5IiMFJcW0zc1h2TqDHvbJp2XW7HnAE",
        authDomain: "peer-support-app-2cf36.firebaseapp.com",
        projectId: "peer-support-app-2cf36",
        storageBucket: "peer-support-app-2cf36.appspot.com",
        messagingSenderId: "159520444669",
        appId: "1:159520444669:web:90af5cd56d2d53d9326e94",
        measurementId: "G-C773M6XLEK",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Skip chat service initialization in debug mode if needed
  const bool skipChatInit = true; // Set to true to skip chat initialization
  
  if (!skipChatInit) {
    // Initialize chat service and sync users
    final chatService = ChatService();
    try {
      // Add timeout to prevent hanging
      await chatService.syncFirebaseUsersToChat().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Warning: Chat service sync timed out, continuing anyway...');
        },
      );
    } catch (e) {
      print('Warning: Chat service sync failed: $e, continuing anyway...');
      // App can still function without chat service sync
    }
  } else {
    print('Debug: Skipping chat service initialization');
  }

  // Initialize super admin (run once) - Change this email to your admin email
  // Uncomment and change the email below to create your first super admin
  // await UserManager.initializeSuperAdmin('donlechero5@yahoo.com');

  runApp(UniversityRedditApp());
}

// Theme notifier for dark/light mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Posts notifier for managing posts data
final ValueNotifier<List<Map<String, dynamic>>> postsNotifier = ValueNotifier([
  {
    'id': 'post_0',
    'title': 'Welcome to Peer Support!',
    'author': 'Admin',
    'body': 'This is the first post in the community. Feel free to share your thoughts and support each other!',
    'comments': [
      {'author': 'Alice', 'text': 'Excited to be here!'},
      {'author': 'Bob', 'text': 'Looking forward to great discussions.'},
    ],
  },
  {
    'id': 'post_1',
    'title': 'Study Tips for Finals',
    'author': 'Student123',
    'body': 'Here are some tips to ace your finals: stay organized, take breaks, and ask for help when needed.',
    'comments': [
      {'author': 'Charlie', 'text': 'Thanks for the tips!'},
    ],
  },
  {
    'id': 'post_2',
    'title': 'Mental Health Resources',
    'author': 'Counselor',
    'body': 'Remember to take care of your mental health. Here are some resources that might help.',
    'comments': [
      {'author': 'Diana', 'text': 'These resources are really helpful.'},
    ],
  },
]);

class UniversityRedditApp extends StatelessWidget {
  const UniversityRedditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'UniReddit',
          theme: ThemeData(
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.orange,
            scaffoldBackgroundColor: Colors.grey[900],
          ),
          themeMode: mode,
          home: WebAuthWrapper(),
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}

// Web auth wrapper for testing
class WebAuthWrapper extends StatefulWidget {
  const WebAuthWrapper({super.key});

  @override
  _WebAuthWrapperState createState() => _WebAuthWrapperState();
}

class _WebAuthWrapperState extends State<WebAuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  StreamSubscription<User?>? _authStateSubscription;
  
  @override
  void initState() {
    super.initState();
    _setupAuthStateListener();
  }
  
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
  
  void _setupAuthStateListener() {
    _authStateSubscription = _authService.authStateChanges.listen((User? user) {
      if (mounted) {
        final wasLoggedIn = _isLoggedIn;
        final newLoggedInState = user != null;
        
        // Only update state if it actually changed
        if (wasLoggedIn != newLoggedInState) {
          setState(() {
            _isLoggedIn = newLoggedInState;
            _isLoading = false;
          });
          
          if (newLoggedInState) {
            // User signed in - handle asynchronously without blocking UI
            _handleUserSignIn(user!);
          } else {
            // User signed out - clear state immediately
            UserManager.clearUser();
          }
        } else if (_isLoading) {
          // If still loading, just update loading state
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }
  
  void _handleUserSignIn(User user) async {
    final startTime = DateTime.now();
    try {
      // Set user immediately for UI responsiveness
      UserManager.setFirebaseUser(user);
      
      if (kDebugMode) {
        final duration = DateTime.now().difference(startTime);
        print('User sign in completed in ${duration.inMilliseconds}ms');
      }
      
      // Initialize chat service in background without blocking UI
      _initializeChatServiceInBackground();
    } catch (e) {
      if (kDebugMode) {
        print('Error handling user sign in: $e');
      }
    }
  }
  
  void _initializeChatServiceInBackground() async {
    try {
      const bool skipChatInit = true; // Skip for performance
      
      if (!skipChatInit) {
        await _chatService.initializeWithFirebaseUser().timeout(
          Duration(seconds: 5), // Reduced timeout
          onTimeout: () {
            if (kDebugMode) {
              print('Chat service initialization timed out, continuing...');
            }
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Chat service initialization failed: $e');
      }
    }
  }
  
  void _onLoginSuccess() async {
    // Login success is handled by auth state listener
    // This method is kept for backward compatibility
    setState(() {
      _isLoggedIn = true;
    });
  }
  
  void _onLogout() async {
    final startTime = DateTime.now();
    try {
      // Use the comprehensive logout method for proper cleanup
      await _authService.logoutWithCleanup();
      
      if (kDebugMode) {
        final duration = DateTime.now().difference(startTime);
        print('Logout completed in ${duration.inMilliseconds}ms');
      }
      
      // State will be updated by auth state listener
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
      // Force state update even if logout fails
      setState(() {
        _isLoggedIn = false;
      });
    }
  }
  
  Future<void> _initializeUser(User user) async {
    try {
      await UserManager.setFirebaseUser(user);
      
      // Skip chat service initialization in debug mode if needed
      const bool skipChatInit = true; // Set to true to skip chat initialization
      
      if (!skipChatInit) {
        // Initialize chat service with shorter timeout
        try {
          await _chatService.initializeWithFirebaseUser().timeout(
            Duration(seconds: 5),
            onTimeout: () {
              print('Warning: Chat service initialization timed out, continuing anyway...');
            },
          );
        } catch (e) {
          print('Warning: Chat service initialization failed: $e, continuing anyway...');
        }
      } else {
        print('Debug: Skipping chat service initialization in auth check');
      }
    } catch (e) {
      print('Error initializing user: $e');
    }
  }
  
  Future<void> _cleanupUser() async {
    try {
      UserManager.clearUser();
      // Add any additional cleanup needed
    } catch (e) {
      print('Error cleaning up user: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF00BCD4),
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Only show loading indicator for initial connection
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00BCD4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final user = snapshot.data;
        if (user != null) {
          // Initialize user data when auth state changes to logged in
          // Use Future.microtask to avoid blocking the UI
          Future.microtask(() => _initializeUser(user));
          return MainNavigation(onLogout: _onLogout);
        } else {
          // Clean up when logged out
          Future.microtask(() => _cleanupUser());
          return LoginScreen(onLoginSuccess: () {});
        }
      },
    );
  }
}

// Firebase auth wrapper removed - partner will handle authentication 