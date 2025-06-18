class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorUsername;
  final String communityId;
  final String communityName;
  final DateTime createdAt;
  final int commentCount;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorUsername,
    required this.communityId,
    required this.communityName,
    required this.createdAt,
    this.commentCount = 0,
  });

  // Factory constructor for creating from JSON/Map
  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? 'Unknown User',
      communityId: data['communityId'] ?? '',
      communityName: data['communityName'] ?? 'Unknown Community',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'communityId': communityId,
      'communityName': communityName,
      'createdAt': createdAt.toIso8601String(),
      'commentCount': commentCount,
    };
  }
} 