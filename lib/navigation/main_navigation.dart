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

  List<BottomNavigationBarItem> _buildNavItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_outlined),
        activeIcon: Icon(Icons.groups),
        label: 'Communities',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Create',
      ),
      BottomNavigationBarItem(
        icon: StreamBuilder<List<ChatConversation>>(
          stream: _chatService.getConversationsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Icon(Icons.chat_bubble_outline);
            
            final conversations = snapshot.data ?? [];
            final currentUserId = _chatService.currentUserId;
            if (currentUserId == null) return const Icon(Icons.chat_bubble_outline);
            
            final totalUnread = conversations.fold<int>(
              0,
              (sum, conv) => sum + conv.getUnreadCount(currentUserId),
            );
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (totalUnread > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        totalUnread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        activeIcon: StreamBuilder<List<ChatConversation>>(
          stream: _chatService.getConversationsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Icon(Icons.chat_bubble);
            
            final conversations = snapshot.data ?? [];
            final currentUserId = _chatService.currentUserId;
            if (currentUserId == null) return const Icon(Icons.chat_bubble);
            
            final totalUnread = conversations.fold<int>(
              0,
              (sum, conv) => sum + conv.getUnreadCount(currentUserId),
            );
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble),
                if (totalUnread > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        totalUnread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        label: 'Chat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

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

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Peer Support';
      case 1:
        return 'Communities';
      case 2:
        return 'Create Post';
      case 3:
        return 'Chat';
      case 4:
        return 'Profile';
      default:
        return 'Peer Support';
    }
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 0,
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Search icon
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          // Profile icon
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orange,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: const Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 8,
        items: _buildNavItems(),
      ),
    );
  }
} 