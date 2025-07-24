import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/communities_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../services/chat_service.dart';
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

  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.groups_outlined),
      activeIcon: Icon(Icons.groups),
      label: 'Communities',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      activeIcon: Icon(Icons.add_circle),
      label: 'Create',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      activeIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
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
        backgroundColor: Color(0xFF00BCD4),
        elevation: 0,
        title: Text(
          _getPageTitle(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Search icon
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          // Profile icon
          Container(
            margin: EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orange,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Text(
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
        items: _navItems,
      ),
    );
  }
} 