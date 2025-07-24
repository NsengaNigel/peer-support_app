import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../services/auth_service.dart';
// import '../services/web_auth_service.dart';
import '../services/user_manager.dart';
import '../widgets/admin_actions.dart';
import 'app_router.dart';
import 'main_navigation.dart';
import '../screens/communities_screen.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback? onLogout;

  const AppDrawer({super.key, this.onLogout});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();

  // Force refresh the drawer to pick up user role changes
  void _refreshUserRole() async {
    await UserManager.refreshUserModel();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Refresh user role when drawer is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserRole();
    });
  }

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
                      Row(
                        children: [
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
                          SizedBox(width: 8),
                          if (UserManager.currentUserModel != null)
                            UserRoleBadge(
                              role: UserManager.currentUserModel!.role,
                              fontSize: 8,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate back to main navigation home tab by replacing the entire stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainNavigation(onLogout: widget.onLogout)),
                      (route) => false,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text('Communities'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to communities screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CommunitiesScreen()),
                    );
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
                // Admin dashboard (only for admins)
                if (UserManager.isCurrentUserAdmin) ...[
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings, color: Colors.red.shade600),
                    title: Text(
                      'Admin Dashboard',
                      style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin');
                    },
                  ),
                ],
                // Debug: Force refresh user role (remove this in production)
                if (kDebugMode) ...[
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.refresh, color: Colors.blue),
                    title: Text('Debug: Refresh Role', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      await UserManager.refreshUserModel();
                      if (mounted) setState(() {}); // Trigger rebuild
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Role refreshed: ${UserManager.currentUserRoleDisplay} - Admin: ${UserManager.isCurrentUserAdmin}'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.blue),
                    title: Text('Debug Info', style: TextStyle(fontSize: 12)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user?.email ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
                        Text('Role: ${UserManager.currentUserRoleDisplay}', style: TextStyle(fontSize: 10)),
                        Text('IsAdmin: ${UserManager.isCurrentUserAdmin}', style: TextStyle(fontSize: 10)),
                        Text('Model: ${UserManager.currentUserModel != null}', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
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