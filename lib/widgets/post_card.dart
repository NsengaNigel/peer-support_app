import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/saved_posts_service.dart';
import '../services/user_manager.dart';
import '../models/user_model.dart';
import '../widgets/admin_actions.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onCommunityTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onPostDeleted; // Callback for when post is deleted

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onCommentTap,
    this.onCommunityTap,
    this.onUserTap,
    this.onPostDeleted,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final SavedPostsService _savedPostsService = SavedPostsService();
  bool _isLoadingSave = false;

  bool get _isPostSaved {
    final postId = widget.post['id'] ?? '';
    final currentUser = UserManager.currentUserModel;
    return _savedPostsService.isPostSaved(postId, currentUser);
  }

  Future<void> _toggleSavePost() async {
    if (_isLoadingSave) return;
    final postId = widget.post['id'];
    if (postId == null || postId.isEmpty) {
      print('[SAVE ERROR] Post ID is null or empty. Post: \\${widget.post}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot save: Post ID not available (diagnostic)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoadingSave = true);
    bool wasSaved = _isPostSaved;
    try {
      if (wasSaved) {
        print('[SAVE ACTION] Unsaving post: $postId');
        await _savedPostsService.unsavePost(postId);
      } else {
        print('[SAVE ACTION] Saving post: $postId');
        await _savedPostsService.savePost(postId);
      }
      // Optimistically update UI
      setState(() {});
      // Refresh user model in background
      UserManager.refreshUserModel().then((_) {
        print('[SAVE ACTION] User model refreshed after save/unsave.');
        if (mounted) setState(() {});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSaved ? 'Post unsaved' : 'Post saved!'),
          backgroundColor: wasSaved ? null : Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSave = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityName = widget.post['communityName'] ?? '';
    final authorUsername = widget.post['author'] ?? widget.post['authorUsername'] ?? 'user';
    final createdAt = widget.post['createdAt'] is DateTime
        ? widget.post['createdAt']
        : DateTime.now();
    final title = widget.post['title'] ?? '';
    final content = widget.post['body'] ?? widget.post['content'] ?? '';
    final commentCount = (widget.post['comments'] is List) ? widget.post['comments'].length : (widget.post['commentCount'] ?? 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community info and admin actions
              Row(
                children: [
                  // Community name
                  GestureDetector(
                    onTap: widget.onCommunityTap,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        communityName.isNotEmpty 
                            ? communityName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Community name text
                  GestureDetector(
                    onTap: widget.onCommunityTap,
                    child: Text(
                      'r/$communityName',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Admin actions for admins/moderators
                  if (UserManager.currentUserModel?.role.canDeletePosts() == true && widget.post['id'] != null)
                    AdminPostActions(
                      postId: widget.post['id'],
                      authorId: widget.post['authorId'] ?? '',
                      onDeleted: widget.onPostDeleted,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Post title and content
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Post content preview
              if (content.isNotEmpty)
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  InkWell(
                    onTap: widget.onCommentTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$commentCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _toggleSavePost,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLoadingSave 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isPostSaved ? Icons.bookmark : Icons.bookmark_border,
                                size: 16,
                                color: _isPostSaved ? Colors.orange : Colors.grey[600],
                              ),
                          const SizedBox(width: 4),
                          Text(
                            _isPostSaved ? 'Saved' : 'Save',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPostSaved ? Colors.orange : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      // Share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share feature coming soon!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 