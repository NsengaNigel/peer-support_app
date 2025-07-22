import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  moderator,
  admin,
  superAdmin,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }

  // Check if user has permission for specific actions
  bool canDeleteComments() {
    return this == UserRole.moderator || 
           this == UserRole.admin || 
           this == UserRole.superAdmin;
  }

  bool canDeletePosts() {
    return this == UserRole.admin || this == UserRole.superAdmin;
  }

  bool canRemoveMembers() {
    return this == UserRole.admin || this == UserRole.superAdmin;
  }

  bool canManageRoles() {
    return this == UserRole.superAdmin;
  }

  bool canBanUsers() {
    return this == UserRole.admin || this == UserRole.superAdmin;
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final bool emailVerified;
  final DateTime? creationTime;
  final DateTime? lastLoginTime;
  final UserRole role;
  final List<String> joinedCommunities;
  final List<String> moderatedCommunities; // Communities where user is moderator
  final List<String> savedPosts; // Saved post IDs
  final List<String> visitedCommunities; // Recently visited community IDs
  final bool isActive;
  final bool isBanned;
  final String? banReason;
  final DateTime? banExpiresAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.emailVerified = false,
    this.creationTime,
    this.lastLoginTime,
    this.role = UserRole.user,
    this.joinedCommunities = const [],
    this.moderatedCommunities = const [],
    this.savedPosts = const [],
    this.visitedCommunities = const [],
    this.isActive = true,
    this.isBanned = false,
    this.banReason,
    this.banExpiresAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'emailVerified': emailVerified,
      'creationTime': creationTime != null ? Timestamp.fromDate(creationTime!) : null,
      'lastLoginTime': lastLoginTime != null ? Timestamp.fromDate(lastLoginTime!) : null,
      'role': role.name,
      'joinedCommunities': joinedCommunities,
      'moderatedCommunities': moderatedCommunities,
      'savedPosts': savedPosts,
      'visitedCommunities': visitedCommunities,
      'isActive': isActive,
      'isBanned': isBanned,
      'banReason': banReason,
      'banExpiresAt': banExpiresAt != null ? Timestamp.fromDate(banExpiresAt!) : null,
    };
  }

  // Create from Map (Firestore data)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      creationTime: map['creationTime'] != null 
          ? (map['creationTime'] as Timestamp).toDate() 
          : null,
      lastLoginTime: map['lastLoginTime'] != null 
          ? (map['lastLoginTime'] as Timestamp).toDate() 
          : null,
      role: UserRoleExtension.fromString(map['role'] ?? 'user'),
      joinedCommunities: List<String>.from(map['joinedCommunities'] ?? []),
      moderatedCommunities: List<String>.from(map['moderatedCommunities'] ?? []),
      savedPosts: List<String>.from(map['savedPosts'] ?? []),
      visitedCommunities: List<String>.from(map['visitedCommunities'] ?? []),
      isActive: map['isActive'] ?? true,
      isBanned: map['isBanned'] ?? false,
      banReason: map['banReason'],
      banExpiresAt: map['banExpiresAt'] != null 
          ? (map['banExpiresAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Create from DocumentSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    // Add the document ID as the UID
    data['uid'] = snapshot.id;
    return UserModel.fromMap(data);
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? emailVerified,
    DateTime? creationTime,
    DateTime? lastLoginTime,
    UserRole? role,
    List<String>? joinedCommunities,
    List<String>? moderatedCommunities,
    List<String>? savedPosts,
    List<String>? visitedCommunities,
    bool? isActive,
    bool? isBanned,
    String? banReason,
    DateTime? banExpiresAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      creationTime: creationTime ?? this.creationTime,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      role: role ?? this.role,
      joinedCommunities: joinedCommunities ?? this.joinedCommunities,
      moderatedCommunities: moderatedCommunities ?? this.moderatedCommunities,
      savedPosts: savedPosts ?? this.savedPosts,
      visitedCommunities: visitedCommunities ?? this.visitedCommunities,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      banExpiresAt: banExpiresAt ?? this.banExpiresAt,
    );
  }

  // Check if user is an admin (admin or super admin)
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  // Check if user is a moderator (any role above user)
  bool get isModerator => role != UserRole.user;

  // Check if user is super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  // Check if user can moderate a specific community
  bool canModerateCommunity(String communityId) {
    return isAdmin || moderatedCommunities.contains(communityId);
  }

  // Get role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  // Check if ban is still active
  bool get isBanActive {
    if (!isBanned) return false;
    if (banExpiresAt == null) return true; // Permanent ban
    return DateTime.now().isBefore(banExpiresAt!);
  }
} 