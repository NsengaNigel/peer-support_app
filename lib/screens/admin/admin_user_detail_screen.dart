import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_actions.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userComments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading data for user: ${widget.user.uid} (${widget.user.email})');
      
      // Load user's posts
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: widget.user.uid)
          .get();

      print('Found ${postsQuery.docs.length} posts for user ${widget.user.uid}');

      _userPosts = postsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort posts by creation date
      _userPosts.sort((a, b) {
        final aDate = (a['createdAt'] is Timestamp) 
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
        final bDate = (b['createdAt'] is Timestamp) 
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      // Load user's comments
      final commentsQuery = await FirebaseFirestore.instance
          .collection('comments')
          .where('authorId', isEqualTo: widget.user.uid)
          .get();

      print('Found ${commentsQuery.docs.length} comments for user ${widget.user.uid}');

      _userComments = commentsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort comments by creation date
      _userComments.sort((a, b) {
        final aDate = (a['createdAt'] is Timestamp) 
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
        final bDate = (b['createdAt'] is Timestamp) 
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.displayName}'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Posts (${_userPosts.length})'),
            Tab(text: 'Comments (${_userComments.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // User info header
          Container(
            color: Colors.grey.shade100,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: widget.user.isBanActive ? Colors.red : Colors.blue,
                  child: Text(
                    widget.user.displayName.isNotEmpty ? widget.user.displayName[0].toUpperCase() : 'U',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.user.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.user.isBanActive ? Colors.red : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          UserRoleBadge(role: widget.user.role),
                        ],
                      ),
                      Text(
                        widget.user.email,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        'Joined: ${widget.user.creationTime?.day}/${widget.user.creationTime?.month}/${widget.user.creationTime?.year}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      if (widget.user.isBanActive) ...[
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BANNED: ${widget.user.banReason ?? 'No reason provided'}',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsTab(),
                      _buildCommentsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final createdAt = (post['createdAt'] is Timestamp) 
            ? (post['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(post['createdAt'].toString()) ?? DateTime.now();

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post_detail',
                arguments: post['id'],
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post['title'] ?? 'No title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AdminPostActions(
                        postId: post['id'],
                        authorId: widget.user.uid,
                        onDeleted: () {
                          _loadUserData(); // Refresh the list
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    post['content'] ?? 'No content',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.comment, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${post['commentCount'] ?? 0} comments',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.touch_app, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Tap to view',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    if (_userComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No comments found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        final comment = _userComments[index];
        final createdAt = (comment['createdAt'] is Timestamp) 
            ? (comment['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(comment['createdAt'].toString()) ?? DateTime.now();

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              if (comment['postId'] != null && comment['postId'].isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/post_detail',
                  arguments: comment['postId'],
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot navigate: Post ID not available'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment['content'] ?? 'No content',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      AdminCommentActions(
                        commentId: comment['id'],
                        postId: comment['postId'] ?? '',
                        authorId: widget.user.uid,
                        onDeleted: () {
                          _loadUserData(); // Refresh the list
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.post_add, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Post ID: ${comment['postId'] != null ? (comment['postId'].length > 8 ? comment['postId'].substring(0, 8) + '...' : comment['postId']) : 'Unknown'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.touch_app, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Tap to view post',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 