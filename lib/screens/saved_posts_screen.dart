import 'package:flutter/material.dart';
import '../services/saved_posts_service.dart';
import '../services/user_manager.dart';
import '../widgets/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final SavedPostsService _savedPostsService = SavedPostsService();
  List<Map<String, dynamic>> _savedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final savedPosts = await _savedPostsService.getSavedPosts();
      setState(() {
        _savedPosts = savedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading saved posts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unsavePost(String postId) async {
    try {
      await _savedPostsService.unsavePost(postId);
      // Refresh user model to update saved posts
      await UserManager.refreshUserModel();
      // Reload saved posts
      await _loadSavedPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post removed from saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Saved Posts'),
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          if (_savedPosts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadSavedPosts,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No saved posts',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Posts you save will appear here',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.explore),
                        label: Text('Explore Posts'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedPosts,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: _savedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _savedPosts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            PostCard(
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
                                // Refresh saved posts when admin deletes a post
                                _loadSavedPosts();
                              },
                            ),
                            // Add unsave button
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Saved on ${_formatSaveDate(post)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _unsavePost(post['id']),
                                    icon: Icon(Icons.bookmark_remove, size: 16),
                                    label: Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatSaveDate(Map<String, dynamic> post) {
    // Since we don't have save date, use post creation date
    final createdAt = post['createdAt'];
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } else if (createdAt is String) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return 'Unknown';
  }
} 