import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';

class CommentsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new comment to a post
  Future<void> addComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    final commentId = _firestore.collection('comments').doc().id;
    final comment = Comment(
      id: commentId,
      content: content,
      authorId: authorId,
      authorName: authorName,
      postId: postId,
      createdAt: DateTime.now(),
    );

    // Add comment to Firestore
    await _firestore.collection('comments').doc(commentId).set(comment.toMap());

    // Update post's comment count
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  // Get comments for a specific post
  Future<List<Comment>> getCommentsForPost(String postId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    // Sort in memory to avoid composite index requirement
    final comments = snapshot.docs.map((doc) => Comment.fromMap(doc.data(), doc.id)).toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  // Get comments by a specific user
  Future<List<Comment>> getCommentsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('authorId', isEqualTo: userId)
        .get();

    // Get comments and sort in memory to avoid composite index requirement
    final comments = snapshot.docs.map((doc) => Comment.fromMap(doc.data(), doc.id)).toList();
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return comments;
  }

  // Get comments stream for real-time updates
  Stream<List<Comment>> getCommentsStreamForPost(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs.map((doc) => Comment.fromMap(doc.data(), doc.id)).toList();
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String postId) async {
    // Delete comment from Firestore
    await _firestore.collection('comments').doc(commentId).delete();

    // Update post's comment count
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  // Update a comment
  Future<void> updateComment(String commentId, String newContent) async {
    await _firestore.collection('comments').doc(commentId).update({
      'content': newContent,
    });
  }
} 