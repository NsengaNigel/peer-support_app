import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Track community visit
  Future<void> visitCommunity(String communityId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        List<String> visitedCommunities = List<String>.from(data['visitedCommunities'] ?? []);

        // Remove if already exists to avoid duplicates
        visitedCommunities.remove(communityId);
        // Add to the end (most recent)
        visitedCommunities.add(communityId);

        // Keep only the last 50 visited communities
        if (visitedCommunities.length > 50) {
          visitedCommunities = visitedCommunities.skip(visitedCommunities.length - 50).toList();
        }

        await userRef.update({
          'visitedCommunities': visitedCommunities,
        });

        if (kDebugMode) {
          print('Community visit recorded: $communityId for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking community visit: $e');
      }
      // Don't throw error as this is not critical functionality
    }
  }

  // Clear community visit history
  Future<void> clearHistory() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'visitedCommunities': [],
      });

      if (kDebugMode) {
        print('Community visit history cleared for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing community visit history: $e');
      }
      rethrow;
    }
  }
} 