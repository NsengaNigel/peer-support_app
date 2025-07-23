import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all available communities from Firestore
  Future<List<Community>> getAllCommunities() async {
    final snapshot = await _firestore.collection('communities').get();
    return snapshot.docs
        .map((doc) => Community.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get user's joined communities
  Future<List<Community>> getUserCommunities({required String userId}) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    final List<dynamic> joinedCommunityIds =
        userDoc.data()?['joinedCommunities'] ?? [];

    if (joinedCommunityIds.isEmpty) return [];

    final snapshot = await _firestore
        .collection('communities')
        .where(FieldPath.documentId, whereIn: joinedCommunityIds)
        .get();

    return snapshot.docs
        .map((doc) => Community.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Create a new community
  Future<Community> createCommunity({
    required String name,
    required String description,
    required String userId,
  }) async {
    // Create new community doc with auto ID
    final newCommunityRef = _firestore.collection('communities').doc();

    final communityData = {
      'name': name,
      'description': description,
      'creatorId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 1, // initial member count (creator)
    };

    // Save community to Firestore
    await newCommunityRef.set(communityData);

    // Reference to user doc
    final userRef = _firestore.collection('users').doc(userId);
    final userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      await userRef.update({
        'joinedCommunities': FieldValue.arrayUnion([newCommunityRef.id]),
      });
    } else {
      await userRef.set({
        'joinedCommunities': [newCommunityRef.id],
      });
    }

    // Fetch the created community data
    final communitySnapshot = await newCommunityRef.get();

    return Community.fromMap(communitySnapshot.data()!, communitySnapshot.id);
  }

  // Join a community
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    // Add user to community members
    final userRef = _firestore.collection('users').doc(userId);
    final userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      batch.update(userRef, {
        'joinedCommunities': FieldValue.arrayUnion([communityId]),
      });
    } else {
      batch.set(userRef, {
        'joinedCommunities': [communityId],
      });
    }

    // Increment community member count
    final communityRef = _firestore.collection('communities').doc(communityId);
    batch.update(communityRef, {
      'memberCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Leave a community
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    // Remove user from community members
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'joinedCommunities': FieldValue.arrayRemove([communityId]),
    });

    // Decrement community member count
    final communityRef = _firestore.collection('communities').doc(communityId);
    batch.update(communityRef, {
      'memberCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }
}
