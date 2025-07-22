import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comments_service.dart';
import '../services/user_manager.dart';
import '../models/comment.dart';
import '../widgets/admin_actions.dart';
import '../main.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
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
        setState(() {
          _post = postData;
          _comments = comments;
          _isLoading = false;
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
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: Text(_post?['title'] ?? 'Post'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Save Post'),
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
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${value} functionality coming soon!')),
              );
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
    );
  }
}