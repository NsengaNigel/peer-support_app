import 'package:flutter/material.dart';
import '../../models/chat_user.dart';
import '../../services/chat_service.dart';
import '../../navigation/app_drawer.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _searchResults = [];
  List<ChatUser> _allUsers = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _chatService.getAllUsers();
      setState(() {
        _allUsers = users;
        _searchResults = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allUsers;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Query Firestore for users whose displayName contains the query
      final results = await _chatService.searchUsersByName(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startChatWithUser(ChatUser user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: user.id,
          otherUserName: user.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onLogout: null), // Pass null since this is not the main navigation
      appBar: AppBar(
        title: const Text('Search Users'),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new user functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add user functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _searchUsers,
            ),
          ),
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF26A69A),
                    ),
                  )
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasSearched ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _hasSearched ? 'No users found' : 'No registered users available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasSearched 
                ? 'Try a different name'
                : 'Users will appear here once they register',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final currentUserId = _chatService.currentUserId;

        // Don't show current user
        if (user.id == currentUserId) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF26A69A).withOpacity(0.2),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF26A69A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.chat,
              color: Color(0xFF26A69A),
            ),
            onTap: () => _startChatWithUser(user),
          ),
        );
      },
    );
  }
} 