import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
// Firebase imports (for Android)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
// import 'services/web_auth_service.dart';
import 'services/user_manager.dart';
import 'screens/auth/login_screen.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // For web testing, use WebAuthService
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
          home: kIsWeb ? WebAuthWrapper() : FirebaseAuthWrapper(),
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
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  
  void _checkAuthState() {
    // Simple check - no user logged in initially
    setState(() {
      _isLoggedIn = false;
      _isLoading = false;
    });
  }
  
  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }
  
  void _onLogout() {
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

// Firebase auth wrapper for production (Android/iOS)
class FirebaseAuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // For now, just show the main navigation
    // Later, when Firebase is working, use FirebaseAuth.instance.authStateChanges()
    return LoginScreen();
    
    // Future Firebase implementation:
    // return StreamBuilder<User?>(
    //   stream: FirebaseAuth.instance.authStateChanges(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return Scaffold(
    //         body: Center(
    //           child: CircularProgressIndicator(
    //             color: Color(0xFF00BCD4),
    //           ),
    //         ),
    //       );
    //     }
    //     if (snapshot.hasData) {
    //       return MainNavigation();
    //     } else {
    //       return LoginScreen();
    //     }
    //   },
    // );
  }
} 