import '../models/post.dart';

class PostService {
  // Mock data for testing without Firebase
  static List<Post> _mockPosts = [
    Post(
      id: '1',
      title: 'Welcome to UniReddit!',
      content: 'This is our new university social platform. Share your thoughts, ask questions, and connect with fellow students!',
      authorId: 'user1',
      authorUsername: 'john_doe',
      communityId: 'university',
      communityName: 'University',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      commentCount: 5,
    ),
    Post(
      id: '2',
      title: 'Flutter Development Tips',
      content: 'Working on a Flutter project? Here are some beginner-friendly tips that helped me get started with mobile development.',
      authorId: 'user2',
      authorUsername: 'flutter_dev',
      communityId: 'programming',
      communityName: 'Programming',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      commentCount: 12,
    ),
    Post(
      id: '3',
      title: 'Study Group for Finals',
      content: 'Anyone interested in forming a study group for upcoming finals? Looking for people taking CS courses.',
      authorId: 'user3',
      authorUsername: 'study_buddy',
      communityId: 'university',
      communityName: 'University',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      commentCount: 8,
    ),
    Post(
      id: '4',
      title: 'Best Programming Languages to Learn in 2024',
      content: 'What programming languages should a computer science student focus on? Looking for career advice from experienced developers.',
      authorId: 'user4',
      authorUsername: 'cs_student',
      communityId: 'programming',
      communityName: 'Programming',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      commentCount: 15,
    ),
    Post(
      id: '5',
      title: 'Campus Event This Weekend',
      content: 'There\'s a tech meetup happening this Saturday at the student center. Great networking opportunity!',
      authorId: 'user5',
      authorUsername: 'event_organizer',
      communityId: 'university',
      communityName: 'University',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      commentCount: 3,
    ),
  ];

  // Get posts for specific community
  Future<List<Post>> getPostsForCommunity(String? communityId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (communityId == null) {
      return _mockPosts;
    }
    
    return _mockPosts.where((post) => post.communityId == communityId).toList();
  }

  // Get posts for user's joined communities
  Future<List<Post>> getFeedForUser(List<String> joinedCommunities) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (joinedCommunities.isEmpty) {
      return [];
    }

    return _mockPosts
        .where((post) => joinedCommunities.contains(post.communityId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get all posts (for testing)
  Future<List<Post>> getAllPosts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockPosts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Add a new post (for testing create functionality)
  Future<void> addPost(Post post) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _mockPosts.add(post);
  }
} 