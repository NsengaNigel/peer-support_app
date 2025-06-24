import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final postsNotifier = ValueNotifier<List<Map<String, dynamic>>>([
  {
    'id': 'post_0',
    'title': 'Welcome to UniReddit!',
    'author': 'Admin',
    'body': 'This is the first post in the community. Feel free to share your thoughts!',
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
    'title': 'Favorite Campus Spots',
    'author': 'JaneDoe',
    'body': 'What are your favorite places to relax on campus?',
    'comments': [
      {'author': 'Diana', 'text': 'I love the library garden.'},
    ],
  },
]);

void main() {
  runApp(UniversityRedditApp());
}

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
          home: MainNavigation(),
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
} 