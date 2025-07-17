import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_manager.dart';
import '../models/community.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';
import 'community_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _posts = [];
  List<Community> _communities = [];
  List<Map<String, dynamic>> _users = [];
  
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _posts = [];
        _communities = [];
        _users = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query.trim();
    });

    try {
      final queryLower = query.toLowerCase();

      // Search posts - get all posts and filter in memory for better results
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .limit(50)
          .get();

      final postsFiltered = postsQuery.docs.where((doc) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final content = (data['content'] ?? '').toString().toLowerCase();
        return title.contains(queryLower) || content.contains(queryLower);
      }).take(20).toList();

      // Search communities - get all communities and filter in memory
      final communitiesQuery = await FirebaseFirestore.instance
          .collection('communities')
          .limit(50)
          .get();

      final communitiesFiltered = communitiesQuery.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        return name.contains(queryLower) || description.contains(queryLower);
      }).take(20).toList();

      // Search users - get all users and filter in memory
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .limit(50)
          .get();

      final usersFiltered = usersQuery.docs.where((doc) {
        final data = doc.data();
        final displayName = (data['displayName'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        return displayName.contains(queryLower) || email.contains(queryLower);
      }).take(20).toList();

      setState(() {
        _posts = postsFiltered.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }).toList();

        _communities = communitiesFiltered.map((doc) => 
          Community.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList();

        _users = usersFiltered.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search posts, communities, users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          style: TextStyle(color: Colors.white),
          onChanged: _performSearch,
          autofocus: true,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Posts (${_posts.length})'),
            Tab(text: 'Communities (${_communities.length})'),
            Tab(text: 'Users (${_users.length})'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : _searchQuery.isEmpty
              ? _buildInitialState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(),
                    _buildCommunitiesTab(),
                    _buildUsersTab(),
                  ],
                ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Search for anything',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find posts, communities, and users',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return _buildEmptyState('No posts found', Icons.post_add);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return PostCard(
          post: post,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(postId: post['id']),
              ),
            );
          },
          onCommentTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(postId: post['id']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommunitiesTab() {
    if (_communities.isEmpty) {
      return _buildEmptyState('No communities found', Icons.group);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _communities.length,
      itemBuilder: (context, index) {
        final community = _communities[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF00BCD4),
              child: Text(
                community.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              community.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              community.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${community.memberCount} members',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityDetailScreen(
                    communityId: community.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return _buildEmptyState('No users found', Icons.person);
    }
    
    final currentUserId = UserManager.currentUser?.uid;

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isCurrentUser = user['id'] == currentUserId;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF00BCD4),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              user['displayName'] ?? 'No Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user['email'] ?? 'No Email'),
            trailing: isCurrentUser 
              ? Text('You', style: TextStyle(color: Colors.grey))
              : Icon(Icons.arrow_forward_ios),
            onTap: isCurrentUser
              ? null // Disable tapping on self
              : () {
                  // Navigate to user profile
                  Navigator.pushNamed(
                    context,
                    '/user_profile',
                    arguments: {
                      'userId': user['id'],
                      'userName': user['displayName'] ?? 'User',
                    },
                  );
                },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 