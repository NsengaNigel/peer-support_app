import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';
import '../search_screen.dart';
import '../../services/user_manager.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({Key? key}) : super(key: key);

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
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
      appBar: AppBar(
        title: const Text(
          'UniReddit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadPosts();
            },
          ),
        ],
      ),
      body: _isLoading
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
                        'Join some communities or create your first post!',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];

                      return PostCard(
                        post: post,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/post_detail',
                            arguments: post['id'],
                          );
                        },
                        onCommentTap: () {
                          Navigator.pushNamed(
                            context,
                            '/post_detail',
                            arguments: post['id'],
                          );
                        },
                        onPostDeleted: () {
                          // Refresh posts when admin deletes a post
                          _loadPosts();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
