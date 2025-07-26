import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/user_manager.dart';
import '../models/user_model.dart';

class AdminCommentActions extends StatefulWidget {
  final String commentId;
  final String postId;
  final String authorId;
  final VoidCallback? onDeleted;

  const AdminCommentActions({
    super.key,
    required this.commentId,
    required this.postId,
    required this.authorId,
    this.onDeleted,
  });

  @override
  State<AdminCommentActions> createState() => _AdminCommentActionsState();
}

class _AdminCommentActionsState extends State<AdminCommentActions> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final currentUser = UserManager.currentUserModel;
    if (currentUser == null || !currentUser.role.canDeleteComments()) {
      return SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.admin_panel_settings, color: Colors.red.shade600, size: 18),
      tooltip: 'Moderator Actions',
      onSelected: (value) async {
        switch (value) {
          case 'delete':
            await _deleteComment();
            break;
          case 'ban_user':
            await _showBanUserDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text('Delete Comment'),
            ],
          ),
        ),
        if (currentUser.role.canBanUsers())
          PopupMenuItem(
            value: 'ban_user',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text('Ban User'),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _deleteComment() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _adminService.adminDeleteComment(widget.commentId, widget.postId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onDeleted?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBanUserDialog() async {
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
          userId: widget.authorId,
          reason: reasonController.text.trim(),
          expiresAt: isPermanent ? null : expiryDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User banned successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error banning user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}

class AdminPostActions extends StatefulWidget {
  final String postId;
  final String authorId;
  final VoidCallback? onDeleted;

  const AdminPostActions({
    super.key,
    required this.postId,
    required this.authorId,
    this.onDeleted,
  });

  @override
  State<AdminPostActions> createState() => _AdminPostActionsState();
}

class _AdminPostActionsState extends State<AdminPostActions> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final currentUser = UserManager.currentUserModel;
    if (currentUser == null || !currentUser.role.canDeletePosts()) {
      return SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.admin_panel_settings, color: Colors.red.shade600, size: 20),
      tooltip: 'Admin Actions',
      onSelected: (value) async {
        switch (value) {
          case 'delete':
            await _deletePost();
            break;
          case 'ban_user':
            await _showBanUserDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text('Delete Post'),
            ],
          ),
        ),
        if (currentUser.role.canBanUsers())
          PopupMenuItem(
            value: 'ban_user',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text('Ban User'),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _deletePost() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post and all its comments? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _adminService.adminDeletePost(widget.postId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onDeleted?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBanUserDialog() async {
    // Same implementation as in AdminCommentActions
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
          userId: widget.authorId,
          reason: reasonController.text.trim(),
          expiresAt: isPermanent ? null : expiryDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User banned successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error banning user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}

class AdminCommunityActions extends StatefulWidget {
  final String communityId;
  final String communityName;
  final VoidCallback? onDeleted;

  const AdminCommunityActions({
    super.key,
    required this.communityId,
    required this.communityName,
    this.onDeleted,
  });

  @override
  State<AdminCommunityActions> createState() => _AdminCommunityActionsState();
}

class _AdminCommunityActionsState extends State<AdminCommunityActions> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final currentUser = UserManager.currentUserModel;
    if (currentUser == null || !currentUser.isSuperAdmin) {
      return SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.admin_panel_settings, color: Colors.red.shade600, size: 20),
      tooltip: 'Super Admin Actions',
      onSelected: (value) async {
        switch (value) {
          case 'delete_community':
            await _deleteCommunity();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete_community',
          child: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text('Delete Community', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCommunity() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Community'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to delete "${widget.communityName}"?'),
              SizedBox(height: 8),
              Text(
                'This action will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Delete all posts in this community'),
              Text('• Delete all comments in this community'),
              Text('• Remove community from all members'),
              Text('• Remove moderator privileges'),
              SizedBox(height: 8),
              Text(
                'THIS ACTION CANNOT BE UNDONE!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
              child: Text('DELETE COMMUNITY', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting community...'),
              ],
            ),
          ),
        );

        await _adminService.adminDeleteCommunity(widget.communityId);
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Community "${widget.communityName}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onDeleted?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Role badge to display user roles
class UserRoleBadge extends StatelessWidget {
  final UserRole role;
  final double? fontSize;

  const UserRoleBadge({
    super.key,
    required this.role,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.user) return SizedBox.shrink();

    Color color;
    IconData icon;
    
    switch (role) {
      case UserRole.moderator:
        color = Colors.green;
        icon = Icons.shield;
        break;
      case UserRole.admin:
        color = Colors.orange;
        icon = Icons.admin_panel_settings;
        break;
      case UserRole.superAdmin:
        color = Colors.purple;
        icon = Icons.verified_user;
        break;
      default:
        return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: (fontSize ?? 10) + 2, color: color),
          SizedBox(width: 4),
          Text(
            role.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 