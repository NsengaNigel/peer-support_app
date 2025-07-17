import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../widgets/post_card.dart';
import 'post/post_feed_screen.dart';
import 'post/create_post_screen.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import 'community_detail_screen.dart';
import 'search_screen.dart';

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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'peer support',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(
                  Icons.search,
                  color: Color(0xFF00BCD4),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.orange,
              child: InkWell(
                onTap: () {
                  // Navigate to current user's profile
                  Navigator.pushNamed(context, '/profile');
                },
                child: Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Latest Posts Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to post feed screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostFeedScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.post_add,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No posts yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to share something!',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreatePostScreen(),
                                  ),
                                );
                                // Reload posts after creating a new one
                                if (result == true) {
                                  _loadPosts();
                                }
                              },
                              icon: Icon(Icons.add),
                              label: Text('Create First Post'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00BCD4),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return PostCard(
                              post: post,
                              onTap: () {
                                // Navigate to post detail screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(
                                      postId: post['id'] ?? 'unknown',
                                    ),
                                  ),
                                );
                              },
                              onCommentTap: () {
                                // Navigate to post detail screen focused on comments
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(
                                      postId: post['id'] ?? 'unknown',
                                    ),
                                  ),
                                );
                              },
                              onCommunityTap: () {
                                // Navigate to community detail screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommunityDetailScreen(
                                      communityId: post['communityId'] ?? 'unknown',
                                    ),
                                  ),
                                );
                              },
                              onUserTap: () {
                                // Navigate to user profile screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(
                                      userId: post['authorId'] ?? 'unknown',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to create post screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
          // Reload posts after creating a new one
          if (result == true) {
            _loadPosts();
          }
        },
        backgroundColor: Color(0xFF00BCD4),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 