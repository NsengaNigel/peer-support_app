import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_manager.dart';
import '../services/comments_service.dart';
import '../models/comment.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _userPostsCount = 0;
  int _userCommentsCount = 0;
  int _userCommunitiesCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final user = UserManager.currentUser;
      if (user != null) {
        // Get user's posts count (simpler query without orderBy)
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: user.uid)
            .get();
        
        // Get user's comments count (would need to implement comments collection)
        // For now, we'll use a placeholder
        
        // Get user's communities count
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = userDoc.data();
        final joinedCommunities = userData?['joinedCommunities'] as List? ?? [];
        
        if (mounted) {
          setState(() {
            _userPostsCount = postsQuery.docs.length;
            _userCommentsCount = 0; // Placeholder for now
            _userCommunitiesCount = joinedCommunities.length;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user data from UserManager
    final user = UserManager.currentUser;
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
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
                      SizedBox(height: 8),
                      
                      // Display name or username
                      if (user?.displayName != null) ...[
                        Text(
                          user!.displayName!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                      
                      // Member since
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
            
            // Profile stats
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
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
              child: _isLoadingStats
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00BCD4),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Posts', 
                          _userPostsCount.toString(), 
                          Icons.post_add,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyPostsScreen()),
                          ),
                        ),
                        _buildStatItem(
                          'Communities', 
                          _userCommunitiesCount.toString(), 
                          Icons.group,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyCommunitiesScreen()),
                          ),
                        ),
                        _buildStatItem(
                          'Comments', 
                          _userCommentsCount.toString(), 
                          Icons.comment,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyCommentsScreen()),
                          ),
                        ),
                      ],
                    ),
            ),
            
            // Account settings
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
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
                        // Reload stats when returning from edit profile
                        _loadUserStats();
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
                              // Simulate email verification for web testing
                              if (kIsWeb) {
                                UserManager.updateUser(emailVerified: true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Email verified! (Simulated)'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                // For Firebase, would need to call sendEmailVerification
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
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Color(0xFF00BCD4),
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BCD4),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
}

// Updated MyPostsScreen to fetch real user posts
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late Future<List<DocumentSnapshot>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchUserPosts();
  }

  Future<List<DocumentSnapshot>> _fetchUserPosts() async {
    final user = UserManager.currentUser;
    if (user == null) {
      return [];
    }
    
    // Simpler query without orderBy
    final postsQuery = await FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: user.uid)
        .get();
        
    // Sort manually
    final posts = postsQuery.docs;
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
    
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Posts'),
        backgroundColor: Color(0xFF00BCD4),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('You have not created any posts.'));
          }

          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
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
                    // Navigate to post detail screen
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
        },
      ),
    );
  }
}

// Updated MyCommentsScreen to fetch real user comments
class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({super.key});

  @override
  _MyCommentsScreenState createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  final CommentsService _commentsService = CommentsService();
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchUserComments();
  }

  Future<List<Comment>> _fetchUserComments() async {
    final user = UserManager.currentUser;
    if (user == null) {
      return [];
    }
    
    final comments = await _commentsService.getCommentsByUser(user.uid);
    
    // Sort manually
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return comments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Comments'),
        backgroundColor: Color(0xFF00BCD4),
      ),
      body: FutureBuilder<List<Comment>>(
        future: _commentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('You have not made any comments.'));
          }

          final comments = snapshot.data!;
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              
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
                    // Navigate to post detail screen to see the comment in context
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
        },
      ),
    );
  }
}

class MyCommunitiesScreen extends StatefulWidget {
  const MyCommunitiesScreen({super.key});

  @override
  _MyCommunitiesScreenState createState() => _MyCommunitiesScreenState();
}

class _MyCommunitiesScreenState extends State<MyCommunitiesScreen> {
  late Future<List<DocumentSnapshot>> _communitiesFuture;

  @override
  void initState() {
    super.initState();
    _communitiesFuture = _fetchUserCommunities();
  }

  Future<List<DocumentSnapshot>> _fetchUserCommunities() async {
    final user = UserManager.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final communityIds = List<String>.from(userDoc.data()?['joinedCommunities'] ?? []);
    
    if (communityIds.isEmpty) return [];

    final communitiesQuery = await FirebaseFirestore.instance
        .collection('communities')
        .where(FieldPath.documentId, whereIn: communityIds)
        .get();
        
    return communitiesQuery.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Communities'),
        backgroundColor: Color(0xFF00BCD4),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _communitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have not joined any communities.'));
          }

          final communities = snapshot.data!;
          return ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              final communityData = community.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.group, color: Color(0xFF00BCD4)),
                  title: Text(
                    communityData['name'] ?? 'Unnamed Community',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${communityData['memberCount'] ?? 0} members',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/community_detail',
                      arguments: community.id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // For now, we'll show an empty state since saved posts functionality needs to be implemented
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: const Text('Saved Posts'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No saved posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Save posts to read them later!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              icon: Icon(Icons.explore),
              label: Text('Explore Posts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 