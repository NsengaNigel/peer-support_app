import 'package:flutter/material.dart';
import '../screens/trending_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/help_screen.dart';
import '../screens/about_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/community_detail_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/trending':
        return MaterialPageRoute(builder: (_) => TrendingScreen());
      case '/saved':
        return MaterialPageRoute(builder: (_) => SavedPostsScreen());
      case '/history':
        return MaterialPageRoute(builder: (_) => HistoryScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case '/help':
        return MaterialPageRoute(builder: (_) => HelpScreen());
      case '/about':
        return MaterialPageRoute(builder: (_) => AboutScreen());
      case '/post':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: args?['postId'] ?? '',
          ),
        );
      case '/user':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: args?['userId'] ?? '',
          ),
        );
      case '/community':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(
            communityId: args?['communityId'] ?? '',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
} 