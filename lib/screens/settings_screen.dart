import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_manager.dart';
import '../models/user_model.dart';
import '../widgets/admin_actions.dart';
import '../main.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = UserManager.currentUser;
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Account Settings Section
          _buildSectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFF00BCD4),
                    child: Text(
                      (user?.displayName?.isNotEmpty == true 
                          ? user!.displayName![0].toUpperCase() 
                          : user?.email[0].toUpperCase()) ?? 'U',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user?.displayName ?? user?.email ?? 'Unknown User'),
                  subtitle: Text(user?.email ?? ''),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user, color: Colors.green),
                  title: Text('Email Verification'),
                  subtitle: Text(
                    user?.emailVerified == true ? 'Verified' : 'Not verified',
                  ),
                  trailing: user?.emailVerified != true 
                      ? TextButton(
                          onPressed: _sendVerificationEmail,
                          child: Text('Verify'),
                        )
                      : Icon(Icons.check, color: Colors.green),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock, color: Colors.orange),
                  title: Text('Change Password'),
                  subtitle: Text('Update your account password'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // App Preferences Section
          _buildSectionHeader('Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.dark_mode),
                  title: Text('Dark Mode'),
                  subtitle: Text('Toggle app theme'),
                  trailing: ValueListenableBuilder<ThemeMode>(
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
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.blue),
                  title: Text('Notifications'),
                  subtitle: Text('Manage notification preferences'),
                  trailing: Switch(
                    value: true, // This would be linked to user preferences
                    onChanged: (value) {
                      // Handle notification preference change
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notification settings updated')),
                      );
                    },
                    activeColor: Color(0xFF00BCD4),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Privacy & Security Section
          _buildSectionHeader('Privacy & Security'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Colors.purple),
                  title: Text('Privacy Policy'),
                  subtitle: Text('Read our privacy policy'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privacy policy coming soon')),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.security, color: Colors.green),
                  title: Text('Account Security'),
                  subtitle: Text('Two-factor authentication and more'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Security settings coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // User Role Info (if admin/moderator)
          if (UserManager.currentUserModel?.role != UserRole.user) ...[
            _buildSectionHeader('Role Information'),
            Card(
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings, color: Colors.red),
                title: Text('Current Role'),
                subtitle: Text(UserManager.currentUserRoleDisplay),
                trailing: UserRoleBadge(role: UserManager.currentUserModel!.role),
              ),
            ),
            SizedBox(height: 24),
          ],
          
          // Account Actions Section
          _buildSectionHeader('Account Actions'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Account'),
                  subtitle: Text('Permanently delete your account'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 40),
          
          // App Version
          Center(
            child: Text(
              'Peer Support App v1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                hintText: 'Enter current password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm new password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Change Password'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      try {
        // Re-authenticate user first
        final credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: currentPasswordController.text,
        );
        await _auth.currentUser!.reauthenticateWithCredential(credential);
        
        // Update password
        await _auth.currentUser!.updatePassword(newPasswordController.text);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your posts, comments, and data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account deletion feature coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
} 