import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/user_manager.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_actions.dart';
import '../../widgets/home_return_arrow.dart';
import 'admin_user_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    if (!UserManager.isCurrentUserAdmin) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access denied: Admin privileges required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _adminService.getAllUsers(limit: 100);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      await _loadUsers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.searchUsers(query);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeReturnAppBar(
        title: 'Admin Dashboard',
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Users'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by email or name...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadUsers();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _searchUsers,
          ),
        ),
        
        // Users list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserListItem(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(UserModel user) {
    final currentUser = UserManager.currentUserModel!;
    final canManageRoles = currentUser.isSuperAdmin;
    final canBanUsers = currentUser.role.canBanUsers();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isBanActive ? Colors.red : Colors.blue,
          child: Text(
            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: user.isBanActive ? Colors.red : null,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            UserRoleBadge(role: user.role, fontSize: 10),
          ],
        ),
        onTap: () {
          // Navigate to user details screen for admin management
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUserDetailScreen(user: user),
            ),
          );
        },
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.isBanActive) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BANNED: ${user.banReason ?? 'No reason provided'}',
                  style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                ),
              ),
            ],
            SizedBox(height: 4),
            Text(
              'Joined: ${user.creationTime?.day}/${user.creationTime?.month}/${user.creationTime?.year} • ${user.joinedCommunities.length} communities',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(user, value),
          itemBuilder: (context) => [
            if (canManageRoles && user.uid != currentUser.uid)
              PopupMenuItem(
                value: 'change_role',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 16),
                    SizedBox(width: 8),
                    Text('Change Role'),
                  ],
                ),
              ),
            if (canBanUsers && user.uid != currentUser.uid)
              PopupMenuItem(
                value: user.isBanActive ? 'unban' : 'ban',
                child: Row(
                  children: [
                    Icon(user.isBanActive ? Icons.check_circle : Icons.block, size: 16),
                    SizedBox(width: 8),
                    Text(user.isBanActive ? 'Unban User' : 'Ban User'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserAction(UserModel user, String action) async {
    switch (action) {
      case 'change_role':
        await _showChangeRoleDialog(user);
        break;
      case 'ban':
        await _showBanUserDialog(user);
        break;
      case 'unban':
        await _unbanUser(user);
        break;
    }
  }

  Future<void> _showChangeRoleDialog(UserModel user) async {
    UserRole? selectedRole = user.role;

    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${user.displayName} (${user.email})'),
              SizedBox(height: 16),
              ...UserRole.values.map((role) => RadioListTile<UserRole>(
                title: Text(role.name),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value;
                  });
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedRole != user.role
                  ? () => Navigator.pop(context, selectedRole)
                  : null,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await _adminService.updateUserRole(user.uid, result);
        await _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBanUserDialog(UserModel user) async {
    final TextEditingController reasonController = TextEditingController();
    bool isPermanent = true;
    DateTime? expiryDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Ban User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${user.displayName} (${user.email})'),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for ban',
                  hintText: 'Enter reason...',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: isPermanent,
                    onChanged: (value) {
                      setDialogState(() {
                        isPermanent = value ?? true;
                        if (isPermanent) expiryDate = null;
                      });
                    },
                  ),
                  Text('Permanent ban'),
                ],
              ),
              if (!isPermanent) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(Duration(days: 7)),
                      firstDate: DateTime.now().add(Duration(days: 1)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        expiryDate = date;
                      });
                    }
                  },
                  child: Text(expiryDate != null 
                      ? 'Ban until: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                      : 'Select expiry date'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: reasonController.text.trim().isEmpty || (!isPermanent && expiryDate == null)
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text('Ban User', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _adminService.banUser(
          userId: user.uid,
          reason: reasonController.text.trim(),
          expiresAt: isPermanent ? null : expiryDate,
        );
        await _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User banned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error banning user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    reasonController.dispose();
  }

  Future<void> _unbanUser(UserModel user) async {
    try {
      await _adminService.unbanUser(user.uid);
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User unbanned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unbanning user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildSettingsTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          child:           ListTile(
            leading: Icon(Icons.supervisor_account),
            title: Text('Initialize Super Admin'),
            subtitle: Text('Set the first super admin for the app'),
            onTap: UserManager.isCurrentUserSuperAdmin ? null : () => _showInitializeSuperAdminDialog(),
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.info),
            title: Text('Current User Info'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role: ${UserManager.currentUserRoleDisplay}'),
                Text('Email: ${UserManager.currentUser?.email ?? 'Unknown'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showInitializeSuperAdminDialog() async {
    final TextEditingController emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Initialize Super Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the email address of the user to make super admin:'),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'admin@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: Text('Initialize'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await UserManager.initializeSuperAdmin(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Super admin initialized for $result'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing super admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    emailController.dispose();
  }
} 