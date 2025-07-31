import '../models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new post to Firestore
  Future<void> addPost(Post post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toMap());
  }

  /// Get posts for a specific community
  Future<List<Post>> getPostsForCommunity(String communityId) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList();
  }

  /// Get feed for user's joined communities
  Future<List<Post>> getFeedForUser(List<String> joinedCommunities) async {
    if (joinedCommunities.isEmpty) return [];

    final snapshot = await _firestore
        .collection('posts')
        .where('communityId', whereIn: joinedCommunities)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList();
  }

  /// Get all posts (for global feed)
  Future<List<Post>> getAllPosts() async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList();
  }  /// Delete a post by ID
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }
}
