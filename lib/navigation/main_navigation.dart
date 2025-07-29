import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/communities_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../services/chat_service.dart';
import '../models/chat_conversation.dart';
import '../widgets/app_scaffold.dart';
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
    return AppScaffold(
      onLogout: widget.onLogout,
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: StreamBuilder<List<ChatConversation>>(
        stream: _chatService.getConversationsStream(),
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? [];
          final currentUserId = _chatService.currentUserId;
          final totalUnread = currentUserId != null ? conversations.fold<int>(
            0,
            (sum, conv) => sum + conv.getUnreadCount(currentUserId),
          ) : 0;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: 'Communities',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.post_add),
                label: 'Post',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.chat_bubble_outline),
                    if (totalUnread > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            totalUnread.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
} 