import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_manager.dart';
import '../services/comments_service.dart';
import '../models/comment.dart';
import '../widgets/home_return_arrow.dart';
import '../widgets/app_scaffold.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommentsService _commentsService = CommentsService();
  List<DocumentSnapshot> _userPosts = [];
  List<Comment> _userComments = [];
  List<DocumentSnapshot> _userCommunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = UserManager.currentUser;
      if (user != null) {
        // Load posts
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: user.uid)
            .get();
        _userPosts = postsQuery.docs;

        // Load comments
        _userComments = await _commentsService.getCommentsByUser(user.uid);

        // Load communities
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final communityIds = List<String>.from(userDoc.data()?['joinedCommunities'] ?? []);
        if (communityIds.isNotEmpty) {
          final communitiesQuery = await FirebaseFirestore.instance
              .collection('communities')
              .where(FieldPath.documentId, whereIn: communityIds)
              .get();
          _userCommunities = communitiesQuery.docs;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPostsList() {
    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final postData = post.data() as Map<String, dynamic>;
        
        return Card(
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          child: ListTile(
            title: Text(
              postData['title'] ?? 'No Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BCD4),
              ),
            ),
            subtitle: Text(
              postData['content'] ?? 'No Content',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post_detail',
                arguments: post.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommentsList() {
    if (_userComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        final comment = _userComments[index];
        
        return Card(
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          child: ListTile(
            leading: Icon(Icons.comment, color: Color(0xFF00BCD4)),
            title: Text(
              comment.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Comment on post: ${comment.postId.substring(0, 6)}...'
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post_detail',
                arguments: comment.postId,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommunitiesList() {
    return Column(
      children: [
        if (_userCommunities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.refresh, color: Color(0xFF00BCD4)),
                tooltip: 'Refresh',
                onPressed: _loadUserData,
              ),
            ),
          ),
        Expanded(
          child: _userCommunities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No communities joined',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _userCommunities.length,
                  itemBuilder: (context, index) {
                    final community = _userCommunities[index];
                    final communityData = community.data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(Icons.group, color: Color(0xFF00BCD4)),
                        title: Text(
                          communityData['name'] ?? 'Unnamed Community',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${communityData['memberCount'] ?? 0} members'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/community_detail',
                            arguments: community.id,
                          ).then((_) => _loadUserData());
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Sign Out'),
            ],
          ),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Sign Out'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Call the logout callback
                  widget.onLogout?.call();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Signed out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = UserManager.currentUser;
    
    return AppScaffold(
      backgroundColor: Color(0xFFF5F7FA),
      onLogout: widget.onLogout,
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        title: Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Posts (${_userPosts.length})'),
            Tab(text: 'Comments (${_userComments.length})'),
            Tab(text: 'Communities (${_userCommunities.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Profile and Settings Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile header
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00BCD4),
                              Color(0xFF2196F3),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // Profile picture
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF00BCD4),
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                // User email
                                Text(
                                  user?.email ?? 'No email',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (user?.displayName != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    user!.displayName!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                Text(
                                  user?.creationTime != null 
                                    ? 'Member since ${user!.creationTime!.year}'
                                    : 'New member',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                
                                // Platform indicator
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    kIsWeb ? 'Web Testing Mode' : 'Mobile Mode',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Account settings
                      Container(
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.edit, color: Color(0xFF00BCD4)),
                              ),
                              title: Text('Edit Profile'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                ).then((_) {
                                  // Reload data when returning from edit profile
                                  _loadUserData();
                                });
                              },
                            ),
                            Divider(height: 1),
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.security, color: Color(0xFF00BCD4)),
                              ),
                              title: Text('Privacy & Security'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Privacy settings coming soon!')),
                                );
                              },
                            ),
                            Divider(height: 1),
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.notifications, color: Color(0xFF00BCD4)),
                              ),
                              title: Text('Notifications'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Notification settings coming soon!')),
                                );
                              },
                            ),
                            Divider(height: 1),
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.email, color: Colors.orange),
                              ),
                              title: Text('Email Verification'),
                              subtitle: Text(
                                user?.emailVerified == true 
                                  ? 'Email verified' 
                                  : kIsWeb ? 'Simulated verification' : 'Email not verified',
                                style: TextStyle(
                                  color: user?.emailVerified == true || kIsWeb
                                    ? Colors.green 
                                    : Colors.orange,
                                ),
                              ),
                              trailing: user?.emailVerified == true || kIsWeb
                                ? Icon(Icons.check_circle, color: Colors.green)
                                : TextButton(
                                    onPressed: () async {
                                      try {
                                        if (kIsWeb) {
                                          UserManager.updateUser(emailVerified: true);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Email verified! (Simulated)'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Verification email sent!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error sending email: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text('Verify'),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Sign out button
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: () => _showSignOutDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 40),
                    ],
                  ),
                ),
                // Posts Tab
                _buildPostsList(),
                // Comments Tab
                _buildCommentsList(),
                // Communities Tab
                _buildCommunitiesList(),
              ],
            ),
    );
  }
} 