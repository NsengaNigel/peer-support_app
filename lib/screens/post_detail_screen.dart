import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comments_service.dart';
import '../services/saved_posts_service.dart';
import '../services/user_manager.dart';
import '../services/user_manager.dart';
import '../models/comment.dart';
import '../widgets/admin_actions.dart';
import '../widgets/home_return_arrow.dart';
import '../main.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final SavedPostsService _savedPostsService = SavedPostsService();
  bool _isSaved = false;
  bool _isSaving = false;
  final TextEditingController _commentController = TextEditingController();
  final CommentsService _commentsService = CommentsService();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _post;

  @override
  void initState() {
    super.initState();
    _loadPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostAndComments() async {
    try {
      Map<String, dynamic>? postData;
      
      // First try to find the post in the local posts notifier
      final localPosts = postsNotifier.value;
      final localPost = localPosts.firstWhere(
        (post) => post['id'] == widget.postId,
        orElse: () => {},
      );
      
      if (localPost.isNotEmpty) {
        // Found in local posts
        postData = localPost;
      } else {
        // Try to load from Firestore
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .get();

        if (postDoc.exists) {
          postData = postDoc.data()!;
        }
      }

      if (postData == null) {
        throw Exception('Post not found');
      }
      
      // Load comments using the new comments service
      final comments = await _commentsService.getCommentsForPost(widget.postId);

      if (mounted) {
        final currentUser = UserManager.currentUserModel;
        final postId = postData['id'] ?? widget.postId;
        final isSaved = _savedPostsService.isPostSaved(postId, currentUser);
        setState(() {
          _post = postData;
          _comments = comments;
          _isLoading = false;
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = UserManager.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to comment');
      }

      await _commentsService.addComment(
        postId: widget.postId,
        content: content,
        authorId: user.uid,
        authorName: user.displayName ?? user.email.split('@')[0],
      );

      _commentController.clear();
      await _loadPostAndComments(); // Refresh comments

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: HomeReturnAppBar(
        title: _post?['title'] ?? 'Post',
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save_unsave',
                child: Row(
                  children: [
                    Icon(_isSaved ? Icons.bookmark : Icons.bookmark_outline, size: 16),
                    SizedBox(width: 8),
                    Text(_isSaved ? 'Unsave Post' : 'Save Post'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 16),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'share') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share functionality coming soon!')),
                );
              } else if (value == 'save_unsave') {
                if (_isSaving) return;
                setState(() => _isSaving = true);
                final postId = _post?['id'] ?? widget.postId;
                try {
                  if (_isSaved) {
                    await _savedPostsService.unsavePost(postId);
                    await UserManager.refreshUserModel();
                    setState(() => _isSaved = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post unsaved.'), backgroundColor: Colors.orange),
                    );
                  } else {
                    await _savedPostsService.savePost(postId);
                    await UserManager.refreshUserModel();
                    setState(() => _isSaved = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post saved!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  setState(() => _isSaving = false);
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Post not found'))
              : Column(
                  children: [
                    // Post content
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post header
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xFF00BCD4),
                                child: Text(
                                  (_post!['authorUsername'] ?? _post!['author'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _post!['authorUsername'] ?? _post!['author'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'r/${_post!['communityName'] ?? 'general'}',
                                      style: TextStyle(
                                        color: Color(0xFF00BCD4),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Admin actions for post
                              AdminPostActions(
                                postId: widget.postId,
                                authorId: _post!['authorId'] ?? '',
                                onDeleted: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Post title
                          Text(
                            _post!['title'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          // Post content
                          Text(
                            _post!['content'] ?? _post!['body'] ?? 'No Content',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 16),
                          // Post stats
                          Row(
                            children: [
                              Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                '${_comments.length} comments',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Comments section
                    Expanded(
                      child: _comments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Be the first to comment!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.orange,
                                            child: Text(
                                              comment.authorName[0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comment.authorName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  '${DateTime.now().difference(comment.createdAt).inHours}h ago',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Admin actions for comment
                                          AdminCommentActions(
                                            commentId: comment.id,
                                            postId: widget.postId,
                                            authorId: comment.authorId,
                                            onDeleted: () {
                                              _loadPostAndComments();
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        comment.content,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      // Comment input
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Color(0xFF00BCD4)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              SizedBox(width: 12),
              _isSubmitting
                  ? CircularProgressIndicator(
                      color: Color(0xFF00BCD4),
                    )
                  : IconButton(
                      onPressed: _addComment,
                      icon: Icon(
                        Icons.send,
                        color: Color(0xFF00BCD4),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: HomeReturnArrow(
        isFloating: true,
        backgroundColor: Color(0xFF00BCD4),
        iconColor: Colors.white,
        size: 48,
        margin: EdgeInsets.only(bottom: 80), // Position above the comment input
      ),
    );
  }
}