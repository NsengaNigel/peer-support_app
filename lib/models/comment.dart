import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String postId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.postId,
    required this.createdAt,
  });

  // Create Comment from Firestore doc data and doc ID
  factory Comment.fromMap(Map<String, dynamic> data, String docId) {
    return Comment(
      id: docId,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown User',
      postId: data['postId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Comment to Map (without id, since it's used as doc ID)
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 