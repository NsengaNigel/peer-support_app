import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
// Firebase imports (for Authentication and Firestore chat)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/user_manager.dart';
import 'services/chat_service.dart';
import 'screens/auth/login_screen.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';

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
  const bool SKIP_CHAT_INIT = true; // Set to true to skip chat initialization
  
  if (!SKIP_CHAT_INIT) {
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
  @override
  _WebAuthWrapperState createState() => _WebAuthWrapperState();
}

class _WebAuthWrapperState extends State<WebAuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  
  void _checkAuthState() async {
    // Wait a bit to ensure Firebase is fully initialized
    await Future.delayed(Duration(milliseconds: 100));
    
    try {
      // Check if user is already logged in with Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, sync with UserManager and ChatService
        UserManager.setFirebaseUser(user);
        
        // Skip chat service initialization in debug mode if needed
        const bool SKIP_CHAT_INIT = true; // Set to true to skip chat initialization
        
        if (!SKIP_CHAT_INIT) {
          // Initialize chat service with timeout
          try {
            await ChatService().initializeWithFirebaseUser().timeout(
              Duration(seconds: 10),
              onTimeout: () {
                print('Warning: Chat service initialization timed out during auth check, continuing anyway...');
              },
            );
          } catch (e) {
            print('Warning: Chat service initialization failed during auth check: $e, continuing anyway...');
          }
        } else {
          print('Debug: Skipping chat service initialization in auth check');
        }
        
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
        }
      } else {
        // No user logged in
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error during auth state check: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }
  
  void _onLoginSuccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserManager.setFirebaseUser(user);
      
      // Skip chat service initialization in debug mode if needed
      const bool SKIP_CHAT_INIT = true; // Set to true to skip chat initialization
      
      if (!SKIP_CHAT_INIT) {
        // Initialize chat service with Firebase user with timeout
        try {
          await ChatService().initializeWithFirebaseUser().timeout(
            Duration(seconds: 10),
            onTimeout: () {
              print('Warning: Chat service initialization timed out, continuing anyway...');
            },
          );
        } catch (e) {
          print('Warning: Chat service initialization failed: $e, continuing anyway...');
        }
      } else {
        print('Debug: Skipping chat service initialization in login success');
      }
    }
    
    setState(() {
      _isLoggedIn = true;
    });
  }
  
  void _onLogout() async {
    await FirebaseAuth.instance.signOut();
    UserManager.clearUser();
    setState(() {
      _isLoggedIn = false;
    });
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
    
    if (_isLoggedIn) {
      return MainNavigation(onLogout: _onLogout);
    } else {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }
  }
}

// Firebase auth wrapper removed - partner will handle authentication 