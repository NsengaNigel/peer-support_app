import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../widgets/post_card.dart';
import 'post/post_feed_screen.dart';
import 'post/create_post_screen.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import 'community_detail_screen.dart';
import 'communities_screen.dart';
import 'chat/chat_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      // Load posts from Firestore
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .limit(10) // Limit to 10 posts for home screen
          .get();

      // Convert to list and sort manually
      final posts = postsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by creation date (newest first)
      posts.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];
        
        DateTime? aDateTime;
        DateTime? bDateTime;
        
        // Handle both Timestamp and String formats
        if (aCreatedAt is Timestamp) {
          aDateTime = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          aDateTime = DateTime.tryParse(aCreatedAt);
        }
        
        if (bCreatedAt is Timestamp) {
          bDateTime = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          bDateTime = DateTime.tryParse(bCreatedAt);
        }
        
        if (aDateTime == null || bDateTime == null) return 0;
        return bDateTime.compareTo(aDateTime);
      });

      // Add dummy posts if no real posts exist
      if (posts.isEmpty) {
        posts.addAll(postsNotifier.value);
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      // Fallback to dummy posts
      if (mounted) {
        setState(() {
          _posts = postsNotifier.value;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00BCD4), // Teal
                  Color(0xFF2196F3), // Blue
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top section with title and profile
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                        Text(
                          'General page',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 2),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Main title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'PS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'peer support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Navigation icons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.groups,
                          label: 'Communities',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CommunitiesScreen()),
                          ),
                        ),
                        _buildNavItem(
                          icon: Icons.post_add,
                          label: 'Post',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreatePostScreen()),
                          ),
                        ),
                        _buildNavItem(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chats',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatListScreen()),
                          ),
                        ),
                        _buildNavItem(
                          icon: Icons.person,
                          label: 'Profile',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Content sections
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Latest Posts Section
                  _buildSectionHeader('Latest Posts', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostFeedScreen()),
                    );
                  }),
                  
                  // Highlighted post
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFE3F2FD), // Light blue
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[600]),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'is ML different from AI??',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () {
                            // Dismiss highlighted post
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // General Community Section
                  _buildSectionHeader('General Community', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostFeedScreen()),
                    );
                  }),
                  
                  // Community posts list
                  if (_isLoading)
                    Center(child: CircularProgressIndicator())
                  else if (_posts.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to share something!',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return _buildCommunityPost(post);
                      },
                    ),
                  
                  SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostScreen()),
            );
            if (result == true) {
              _loadPosts();
            }
          },
          backgroundColor: Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          icon: Icon(Icons.add),
          label: Text('Post'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPost(Map<String, dynamic> post) {
    // Sample data to match the screenshot
    final sampleAuthors = ['Nivin Ps', 'Member 3', 'Member 5', 'Member 2'];
    final sampleTitles = [
      'Is ML different from AI?',
      'I can\'t stop procrastinating',
      'how does one become a Dev?',
      'Anyone to help me with this?...'
    ];
    
    final index = _posts.indexOf(post) % sampleAuthors.length;
    final author = sampleAuthors[index];
    final title = sampleTitles[index];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '12-Jan-2025',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 