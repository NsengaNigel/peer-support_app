import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/chat_user.dart';
import '../services/user_manager.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  CollectionReference get _conversationsCollection => _firestore.collection('conversations');
  CollectionReference get _usersCollection => _firestore.collection('chat_users');

  // Current user ID from Firebase Auth
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // Initialize with Firebase user
  Future<void> initializeWithFirebaseUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (kDebugMode) {
          print('No Firebase user found during chat initialization');
        }
        return;
      }

      _currentUserId = firebaseUser.uid;
      
      // Get or create chat user
      await getOrCreateUser(
        firebaseUser.uid,
        firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      );

      // Update online status
      await updateUserStatus(firebaseUser.uid, isOnline: true);

      if (kDebugMode) {
        print('Chat service initialized for user: ${firebaseUser.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing chat service: $e');
      }
      rethrow;
    }
  }

  // Sync all Firebase Auth users to chat users collection
  Future<void> syncFirebaseUsersToChat() async {
    try {
      if (kDebugMode) {
        print('Starting Firebase users sync to chat...');
      }
      
      // Get all users from the main users collection (from posts/communities) with timeout
      final usersSnapshot = await _firestore.collection('users').get().timeout(
        Duration(seconds: 8),
        onTimeout: () {
          if (kDebugMode) {
            print('Warning: Users collection query timed out');
          }
          throw TimeoutException('Users collection query timed out');
        },
      );
      
      if (kDebugMode) {
        print('Found ${usersSnapshot.docs.length} users to sync');
      }
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data();
          final chatUser = ChatUser(
            id: userDoc.id,
            name: userData['displayName'] ?? userData['email']?.split('@')[0] ?? 'Unknown',
            email: userData['email'] ?? '',
            isOnline: false, // Default to offline
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
          );
          
          // Update chat user document (merge to avoid overwriting) with timeout
          await _usersCollection.doc(userDoc.id).set(chatUser.toMap(), SetOptions(merge: true)).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              if (kDebugMode) {
                print('Warning: Chat user update timed out for user: ${userDoc.id}');
              }
              throw TimeoutException('Chat user update timed out');
            },
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing individual user ${userDoc.id}: $e');
          }
          // Continue with other users even if one fails
        }
      }
      
      if (kDebugMode) {
        print('Synced ${usersSnapshot.docs.length} users to chat collection');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing users to chat: $e');
      }
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) {
      throw Exception('User not logged in. Please log in first.');
    }

    try {
      // Get sender info
      final senderDoc = await _usersCollection.doc(senderId).get();
      final senderName = senderDoc.exists 
          ? (senderDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';

      // Create conversation ID
      final conversationId = ChatConversation.createConversationId(senderId, receiverId);

      // Create message
      final messageId = _messagesCollection.doc().id;
      final message = ChatMessage(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        conversationId: conversationId,
        content: content,
        timestamp: DateTime.now(),
        type: type,
      );

      // Send message to Firestore
      await _messagesCollection.doc(messageId).set(message.toMap());

      // Update or create conversation
      await _updateConversation(
        conversationId: conversationId,
        participants: [senderId, receiverId],
        lastMessage: content,
        lastMessageSenderId: senderId,
        lastMessageTimestamp: message.timestamp,
      );

      if (kDebugMode) {
        print('Message sent: $content to $receiverId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      rethrow;
    }
  }

  // Get messages for a conversation with real-time updates
  Stream<List<ChatMessage>> getMessagesStream(String otherUserId) {
    final currentUser = currentUserId;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final conversationId = ChatConversation.createConversationId(currentUser, otherUserId);
    
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) {
            return ChatMessage.fromSnapshot(doc);
          }).toList();
          
          // Sort in memory to avoid composite index requirement
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  // Get user's conversations with real-time updates
  Stream<List<ChatConversation>> getConversationsStream() {
    final currentUser = currentUserId;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _conversationsCollection
        .where('participants', arrayContains: currentUser)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs.map((doc) {
            return ChatConversation.fromSnapshot(doc);
          }).toList();
          
          // Sort in memory to avoid composite index requirement
          conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return conversations;
        });
  }

  // Search users for starting new conversations
  Future<List<ChatUser>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Search by name (case-insensitive)
      final nameQuery = await _usersCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      // Search by email
      final emailQuery = await _usersCollection
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      // Combine results and remove duplicates
      final users = <ChatUser>[];
      final seenIds = <String>{};

      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        final user = ChatUser.fromSnapshot(doc);
        if (!seenIds.contains(user.id) && user.id != currentUserId) {
          users.add(user);
          seenIds.add(user.id);
        }
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching users: $e');
      }
      return [];
    }
  }

  // Get all users (for production use)
  Future<List<ChatUser>> getAllUsers() async {
    try {
      // Only get users that have been properly registered through Firebase Auth
      final snapshot = await _usersCollection
          .where('isRegistered', isEqualTo: true) // Only get real registered users
          .orderBy('displayName') // Sort by display name
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => ChatUser.fromSnapshot(doc))
          .where((user) => 
            user.id != currentUserId && // Don't include current user
            user.id.isNotEmpty && // Ensure valid user ID
            user.displayName.isNotEmpty // Ensure valid display name
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }

  // Mark messages as read (privacy-focused - only updates unread count)
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUser = currentUserId;
    if (currentUser == null) return;

    try {
      final conversationId = ChatConversation.createConversationId(currentUser, otherUserId);
      
      // Only update conversation unread count for privacy
      // We don't track individual message read status
      await _conversationsCollection.doc(conversationId).update({
        'unreadCounts.$currentUser': 0,
      });

      if (kDebugMode) {
        print('Cleared unread count for conversation with $otherUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing unread count: $e');
      }
    }
  }

  // Update or create conversation
  Future<void> _updateConversation({
    required String conversationId,
    required List<String> participants,
    required String lastMessage,
    required String lastMessageSenderId,
    required DateTime lastMessageTimestamp,
  }) async {
    try {
      final conversationRef = _conversationsCollection.doc(conversationId);
      final conversationDoc = await conversationRef.get();

      if (conversationDoc.exists) {
        // Update existing conversation
        final currentData = conversationDoc.data() as Map<String, dynamic>;
        final currentUnreadCounts = Map<String, int>.from(currentData['unreadCounts'] ?? {});
        
        // Increment unread count for receiver
        final receiverId = participants.firstWhere((id) => id != lastMessageSenderId);
        currentUnreadCounts[receiverId] = (currentUnreadCounts[receiverId] ?? 0) + 1;

        await conversationRef.update({
          'lastMessage': lastMessage,
          'lastMessageSenderId': lastMessageSenderId,
          'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
          'unreadCounts': currentUnreadCounts,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Create new conversation
        final participantNames = <String, String>{};
        for (final participantId in participants) {
          final userDoc = await _usersCollection.doc(participantId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            participantNames[participantId] = userData['name'] ?? 'Unknown';
          }
        }

        final receiverId = participants.firstWhere((id) => id != lastMessageSenderId);
        final unreadCounts = {receiverId: 1};

        final conversation = ChatConversation(
          id: conversationId,
          participants: participants,
          participantNames: participantNames,
          lastMessage: lastMessage,
          lastMessageSenderId: lastMessageSenderId,
          lastMessageTimestamp: lastMessageTimestamp,
          unreadCounts: unreadCounts,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await conversationRef.set(conversation.toMap());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating conversation: $e');
      }
      rethrow;
    }
  }

  // Create some test users (for development)
  // Future<void> createTestUsers() async {
  //   final testUsers = [
  //     ChatUser.createTempUser('user1', 'Alice Johnson'),
  //     ChatUser.createTempUser('user2', 'Bob Smith'),
  //     ChatUser.createTempUser('user3', 'Charlie Brown'),
  //     ChatUser.createTempUser('user4', 'Diana Prince'),
  //     ChatUser.createTempUser('user5', 'Eve Wilson'),
  //   ];

  //   for (final user in testUsers) {
  //     await _usersCollection.doc(user.id).set(user.toMap());
  //   }

  //   if (kDebugMode) {
  //     print('Created ${testUsers.length} test users');
  //   }
  // }

  // Create a new chat user from Firebase user data
  Future<ChatUser> createChatUser(String userId, String name, String email) async {
    final user = ChatUser(
      id: userId,
      name: name,
      email: email,
      createdAt: DateTime.now(),
      isRegistered: true, // Mark as registered since coming from Firebase
    );

    await _usersCollection.doc(userId).set(user.toMap());
    return user;
  }

  // Get user by ID
  Future<ChatUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return ChatUser.fromSnapshot(doc);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by ID: $e');
      }
      return null;
    }
  }

  // Update user's online status
  Future<void> updateUserStatus(String userId, {required bool isOnline}) async {
    try {
      await _usersCollection.doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
    }
  }

  // Clean up resources
  void dispose() {
    // Update user status to offline
    if (_currentUserId != null) {
      updateUserStatus(_currentUserId!, isOnline: false);
    }
  }

  // Create a new chat user from Firebase user data
  Future<ChatUser> _createUserFromFirebase(String userId, String name) async {
    final user = await createChatUser(
      userId,
      name,
      '$userId@firebase.com', // Temporary email, will be updated with real email
    );
    return user;
  }

  // Get or create user by ID
  Future<ChatUser> getOrCreateUser(String userId, String name) async {
    try {
      final existingUser = await getUserById(userId);
      if (existingUser != null) {
        return existingUser;
      }
      
      // Create new user if doesn't exist
      return await _createUserFromFirebase(userId, name);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting or creating user: $e');
      }
      rethrow;
    }
  }
} 