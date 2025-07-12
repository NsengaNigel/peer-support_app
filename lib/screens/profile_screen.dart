import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/web_auth_service.dart';
import '../services/user_manager.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  
  const ProfileScreen({super.key, this.onLogout});

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Posts', '12', Icons.post_add),
                  _buildStatItem('Communities', '5', Icons.group),
                  _buildStatItem('Karma', '234', Icons.thumb_up),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit Profile coming soon!')),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
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
                  onLogout?.call();
                  
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

// Keep the existing screens with minor styling updates
class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final posts = [
      'My first post',
      'Another day at university',
      'Flutter is awesome!',
    ];
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: const Text('My Posts'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) => Container(
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
          child: Row(
            children: [
              Icon(Icons.article, color: Color(0xFF00BCD4)),
              SizedBox(width: 12),
              Text(posts[index]),
            ],
          ),
        ),
      ),
    );
  }
}

class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final comments = [
      'Great post!',
      'I totally agree with you.',
      'Thanks for sharing!',
    ];
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: const Text('My Comments'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: comments.length,
        itemBuilder: (context, index) => Container(
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
          child: Row(
            children: [
              Icon(Icons.comment, color: Color(0xFF00BCD4)),
              SizedBox(width: 12),
              Text(comments[index]),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final saved = [
      'Saved post 1',
      'Saved post 2',
    ];
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: const Text('Saved'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: saved.length,
        itemBuilder: (context, index) => Container(
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
          child: Row(
            children: [
              Icon(Icons.bookmark, color: Color(0xFF00BCD4)),
              SizedBox(width: 12),
              Text(saved[index]),
            ],
          ),
        ),
      ),
    );
  }
} 