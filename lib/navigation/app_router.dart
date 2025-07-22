import 'package:flutter/material.dart';
import '../screens/trending_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/community_detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

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

      case '/search':
        return MaterialPageRoute(builder: (_) => SearchScreen());

      case '/admin':
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());

      case '/post':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: args?['postId'] ?? '',
          ),
        );

      case '/post_detail':
        final postId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: postId),
        );

      case '/user':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: args?['userId'] ?? '',
          ),
        );

      case '/user_profile':
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

      case '/community_detail':
        final communityId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(communityId: communityId),
        );

      case '/chat':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text('Chat with ${args?['receiverName'] ?? 'User'}'),
              backgroundColor: Color(0xFF00BCD4),
            ),
            body: Center(
              child: Text('Chat functionality coming soon!\nReceiver: ${args?['receiverName'] ?? 'Unknown'}'),
            ),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}