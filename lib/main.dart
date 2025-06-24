import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

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