import '../models/community.dart';

class CommunityService {
  // Mock communities for testing
  static final List<Community> _mockCommunities = [
    Community(
      id: 'university',
      name: 'University',
      description: 'General university discussions and announcements',
      memberCount: 1250,
    ),
    Community(
      id: 'programming',
      name: 'Programming',
      description: 'Programming tips, tutorials, and discussions',
      memberCount: 890,
    ),
    Community(
      id: 'study_groups',
      name: 'Study Groups',
      description: 'Find and create study groups for your courses',
      memberCount: 456,
    ),
    Community(
      id: 'events',
      name: 'Events',
      description: 'Campus events and activities',
      memberCount: 678,
    ),
    Community(
      id: 'career',
      name: 'Career',
      description: 'Job opportunities and career advice',
      memberCount: 334,
    ),
  ];

  // Get user's joined communities
  Future<List<Community>> getUserCommunities() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: user is part of first 3 communities
    return _mockCommunities.take(3).toList();
  }

  // Get all available communities
  Future<List<Community>> getAllCommunities() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockCommunities);
  }
} 