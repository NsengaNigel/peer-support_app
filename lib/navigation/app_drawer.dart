import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/web_auth_service.dart';
import '../services/user_manager.dart';
import 'app_router.dart';

class AppDrawer extends StatelessWidget {
  final AuthService _authService = AuthService();
  final WebAuthService _webAuthService = WebAuthService();
  final VoidCallback? onLogout;

  AppDrawer({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current user email from UserManager
    final user = UserManager.currentUser;

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peer Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (user?.email != null)
                        Text(
                          user!.email,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      if (user?.displayName != null) ...[
                        SizedBox(height: 4),
                        Text(
                          user!.displayName!,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          kIsWeb ? 'Web Testing Mode' : 'Mobile Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/home');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text('Communities'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/communities');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bookmark),
                  title: Text('Saved Posts'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/saved');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/history');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/help');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSignOutDialog(context);
                  },
                ),
              ],
            ),
          ),
          // Theme toggle
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dark Mode'),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) {
                    return Switch(
                      value: mode == ThemeMode.dark,
                      onChanged: (value) {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: Color(0xFF00BCD4),
                    );
                  },
                ),
              ],
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