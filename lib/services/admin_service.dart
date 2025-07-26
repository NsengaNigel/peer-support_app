import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _communitiesCollection => _firestore.collection('communities');
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _commentsCollection => _firestore.collection('comments');

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user's role and permissions
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      } else {
        // Create default user if doesn't exist
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          emailVerified: user.emailVerified,
          creationTime: user.metadata.creationTime,
          lastLoginTime: DateTime.now(),
        );
        await _usersCollection.doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return null;
    }
  }

  // Check if current user has admin permissions
  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  // Check if current user has moderator permissions
  Future<bool> isCurrentUserModerator() async {
    final user = await getCurrentUser();
    return user?.isModerator ?? false;
  }

  // Check if current user can moderate a specific community
  Future<bool> canCurrentUserModerateCommunity(String communityId) async {
    final user = await getCurrentUser();
    return user?.canModerateCommunity(communityId) ?? false;
  }

  // Update user role (only super admins can do this)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.isSuperAdmin) {
      throw Exception('Permission denied: Only super admins can change user roles');
    }

    await _usersCollection.doc(userId).update({
      'role': newRole.name,
    });

    if (kDebugMode) {
      print('Updated user $userId role to ${newRole.name}');
    }
  }

  // Add user as community moderator
  Future<void> addCommunityModerator(String userId, String communityId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.isAdmin) {
      throw Exception('Permission denied: Only admins can assign community moderators');
    }

    await _usersCollection.doc(userId).update({
      'moderatedCommunities': FieldValue.arrayUnion([communityId])
    });

    if (kDebugMode) {
      print('Added user $userId as moderator for community $communityId');
    }
  }

  // Remove user as community moderator
  Future<void> removeCommunityModerator(String userId, String communityId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.isAdmin) {
      throw Exception('Permission denied: Only admins can remove community moderators');
    }

    await _usersCollection.doc(userId).update({
      'moderatedCommunities': FieldValue.arrayRemove([communityId])
    });

    if (kDebugMode) {
      print('Removed user $userId as moderator for community $communityId');
    }
  }

  // Ban a user
  Future<void> banUser({
    required String userId,
    required String reason,
    DateTime? expiresAt, // null for permanent ban
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.role.canBanUsers()) {
      throw Exception('Permission denied: Only admins can ban users');
    }

    await _usersCollection.doc(userId).update({
      'isBanned': true,
      'banReason': reason,
      'banExpiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
    });

    if (kDebugMode) {
      print('Banned user $userId: $reason');
    }
  }

  // Unban a user
  Future<void> unbanUser(String userId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.role.canBanUsers()) {
      throw Exception('Permission denied: Only admins can unban users');
    }

    await _usersCollection.doc(userId).update({
      'isBanned': false,
      'banReason': null,
      'banExpiresAt': null,
    });

    if (kDebugMode) {
      print('Unbanned user $userId');
    }
  }

  // Admin delete comment
  Future<void> adminDeleteComment(String commentId, String postId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.role.canDeleteComments()) {
      throw Exception('Permission denied: Insufficient privileges to delete comments');
    }

    // Delete comment from Firestore
    await _commentsCollection.doc(commentId).delete();

    // Update post's comment count
    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });

    if (kDebugMode) {
      print('Admin deleted comment $commentId from post $postId');
    }
  }

  // Admin delete post
  Future<void> adminDeletePost(String postId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.role.canDeletePosts()) {
      throw Exception('Permission denied: Insufficient privileges to delete posts');
    }

    // Delete all comments for the post first
    final commentsQuery = await _commentsCollection
        .where('postId', isEqualTo: postId)
        .get();

    final batch = _firestore.batch();
    for (final doc in commentsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete the post
    batch.delete(_postsCollection.doc(postId));
    
    await batch.commit();

    if (kDebugMode) {
      print('Admin deleted post $postId and its comments');
    }
  }

  // Remove user from community
  Future<void> removeUserFromCommunity({
    required String userId,
    required String communityId,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.role.canRemoveMembers()) {
      throw Exception('Permission denied: Insufficient privileges to remove members');
    }

    final batch = _firestore.batch();

    // Remove user from community members
    batch.update(_usersCollection.doc(userId), {
      'joinedCommunities': FieldValue.arrayRemove([communityId]),
    });

    // Decrement community member count
    batch.update(_communitiesCollection.doc(communityId), {
      'memberCount': FieldValue.increment(-1),
    });

    await batch.commit();

    if (kDebugMode) {
      print('Admin removed user $userId from community $communityId');
    }
  }

  // Get all users (for admin management)
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.isAdmin) {
      throw Exception('Permission denied: Only admins can view user list');
    }

    try {
      final snapshot = await _usersCollection.limit(limit).get();
      return snapshot.docs
          .map((doc) => UserModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users: $e');
      }
      return [];
    }
  }

  // Search users by email or display name
  Future<List<UserModel>> searchUsers(String query) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.isAdmin) {
      throw Exception('Permission denied: Only admins can search users');
    }

    try {
      // Search by email
      final emailQuery = await _usersCollection
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      // Search by display name
      final nameQuery = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      final users = <UserModel>[];
      final seenIds = <String>{};

      for (final doc in [...emailQuery.docs, ...nameQuery.docs]) {
        final user = UserModel.fromSnapshot(doc);
        if (!seenIds.contains(user.uid)) {
          users.add(user);
          seenIds.add(user.uid);
        }
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching users: $e');
      }
      return [];
    }
  }

  // Get community members (for admin management)
  Future<List<UserModel>> getCommunityMembers(String communityId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.canModerateCommunity(communityId)) {
      throw Exception('Permission denied: Cannot view community members');
    }

    try {
      final snapshot = await _usersCollection
          .where('joinedCommunities', arrayContains: communityId)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting community members: $e');
      }
      return [];
    }
  }

  // Admin delete community (only super admin can do this)
  Future<void> adminDeleteCommunity(String communityId) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || !currentUser.isSuperAdmin) {
      throw Exception('Permission denied: Only super admins can delete communities');
    }

    try {
      // Get community data first to show it in logs
      final communityDoc = await _communitiesCollection.doc(communityId).get();
      if (!communityDoc.exists) {
        throw Exception('Community not found');
      }

      final communityData = communityDoc.data() as Map<String, dynamic>;
      final communityName = communityData['name'] ?? 'Unknown Community';

      // Use a batch for atomic operations
      final batch = _firestore.batch();

      // 1. Delete all posts in this community
      final postsQuery = await _postsCollection
          .where('communityId', isEqualTo: communityId)
          .get();

      for (final postDoc in postsQuery.docs) {
        final postId = postDoc.id;
        
        // Delete all comments for each post
        final commentsQuery = await _commentsCollection
            .where('postId', isEqualTo: postId)
            .get();
        
        for (final commentDoc in commentsQuery.docs) {
          batch.delete(commentDoc.reference);
        }
        
        // Delete the post
        batch.delete(postDoc.reference);
      }

      // 2. Remove community from all users' joinedCommunities
      final usersQuery = await _usersCollection
          .where('joinedCommunities', arrayContains: communityId)
          .get();

      for (final userDoc in usersQuery.docs) {
        batch.update(userDoc.reference, {
          'joinedCommunities': FieldValue.arrayRemove([communityId]),
        });
      }

      // 3. Remove community from all users' moderatedCommunities
      final moderatorsQuery = await _usersCollection
          .where('moderatedCommunities', arrayContains: communityId)
          .get();

      for (final userDoc in moderatorsQuery.docs) {
        batch.update(userDoc.reference, {
          'moderatedCommunities': FieldValue.arrayRemove([communityId]),
        });
      }

      // 4. Delete the community itself
      batch.delete(_communitiesCollection.doc(communityId));

      // Execute all operations atomically
      await batch.commit();

      if (kDebugMode) {
        print('Super admin deleted community "$communityName" ($communityId) with ${postsQuery.docs.length} posts and cleaned up user associations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting community: $e');
      }
      rethrow;
    }
  }

  // Initialize the first super admin (run once)
  Future<void> initializeSuperAdmin(String email) async {
    try {
      final usersQuery = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userDoc = usersQuery.docs.first;
        await userDoc.reference.update({'role': UserRole.superAdmin.name});
        
        if (kDebugMode) {
          print('Initialized super admin for $email');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing super admin: $e');
      }
    }
  }
} 