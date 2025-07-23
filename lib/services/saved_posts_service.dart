import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class SavedPostsService {
  static final SavedPostsService _instance = SavedPostsService._internal();
  factory SavedPostsService() => _instance;
  SavedPostsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _postsCollection => _firestore.collection('posts');

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save a post
  Future<void> savePost(String postId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to save posts');
    }

    try {
      await _usersCollection.doc(userId).update({
        'savedPosts': FieldValue.arrayUnion([postId]),
      });

      if (kDebugMode) {
        print('Saved post $postId for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving post: $e');
      }
      rethrow;
    }
  }

  // Unsave a post
  Future<void> unsavePost(String postId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to unsave posts');
    }

    try {
      await _usersCollection.doc(userId).update({
        'savedPosts': FieldValue.arrayRemove([postId]),
      });

      if (kDebugMode) {
        print('Unsaved post $postId for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsaving post: $e');
      }
      rethrow;
    }
  }

  // Check if a post is saved by current user
  bool isPostSaved(String postId, UserModel? currentUserModel) {
    if (currentUserModel == null) return false;
    return currentUserModel.savedPosts.contains(postId);
  }

  // Get all saved posts for current user
  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to view saved posts');
    }

    try {
      // Get user's saved post IDs
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> savedPostIds = List<String>.from(userData['savedPosts'] ?? []);

      if (savedPostIds.isEmpty) return [];

      // Get the actual posts
      final savedPosts = <Map<String, dynamic>>[];
      
      // Firestore 'in' queries have a limit of 10, so we need to batch them
      for (int i = 0; i < savedPostIds.length; i += 10) {
        final batch = savedPostIds.skip(i).take(10).toList();
        final postsQuery = await _postsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in postsQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          savedPosts.add(data);
        }
      }

      // Sort by creation date (newest first)
      savedPosts.sort((a, b) {
        final aDate = (a['createdAt'] is Timestamp) 
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
        final bDate = (b['createdAt'] is Timestamp) 
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      return savedPosts;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved posts: $e');
      }
      return [];
    }
  }

  // Get saved posts count for current user
  Future<int> getSavedPostsCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> savedPostIds = List<String>.from(userData['savedPosts'] ?? []);
      return savedPostIds.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved posts count: $e');
      }
      return 0;
    }
  }
} 