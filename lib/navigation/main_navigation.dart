import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/communities_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../services/chat_service.dart';
import '../models/chat_conversation.dart';
import 'app_drawer.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const MainNavigation({super.key, this.onLogout});
  
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _initializeChatService();
  }

  void _initializeChatService() async {
    // Initialize with Firebase Auth user
    await _chatService.initializeWithFirebaseUser();
  }

  List<Widget> get _screens => [
    HomeScreen(),
    CommunitiesScreen(),
    CreatePostScreen(),
    ChatListScreen(),
    ProfileScreen(onLogout: widget.onLogout),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onLogout: widget.onLogout),
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
} 