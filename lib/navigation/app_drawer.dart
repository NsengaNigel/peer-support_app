import 'package:flutter/material.dart';
import '../main.dart';
import 'app_router.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.school, size: 35, color: Colors.orange),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'UniReddit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'University Community',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.trending_up,
                  title: 'Trending',
                  onTap: () => Navigator.pushNamed(context, '/trending'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bookmark_outline,
                  title: 'Saved Posts',
                  onTap: () => Navigator.pushNamed(context, '/saved'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'History',
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
                Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Feedback',
                  onTap: () => Navigator.pushNamed(context, '/help'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
                Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode'),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) {
                    return Switch(
                      value: mode == ThemeMode.dark,
                      onChanged: (val) {
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                // Add logout logic here
                Navigator.of(context).pop();
                // Navigate to login screen
              },
            ),
          ],
        );
      },
    );
  }
} 