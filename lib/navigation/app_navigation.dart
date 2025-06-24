import 'package:flutter/material.dart';
import '../screens/post/create_post_screen.dart';

class AppNavigation {
  static const String home = '/';
  static const String createPost = '/create-post';
  static const String postFeed = '/post-feed';
  static const String userProfile = '/user-profile';
  static const String communityList = '/community-list';
  static const String login = '/login';
  static const String register = '/register';
  static const String supportChat = '/support-chat';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Add your routes here
    };
  }
} 