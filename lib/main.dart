import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';

void main() {
  runApp(UniversityRedditApp());
}

class UniversityRedditApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      home: MainNavigation(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
} 