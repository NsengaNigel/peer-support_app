import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/chat_user.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  CollectionReference get _conversationsCollection => _firestore.collection('conversations');
  CollectionReference get _usersCollection => _firestore.collection('chat_users');

  // Current user ID (temporary - will be replaced with actual auth)
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // Initialize with temporary user
  Future<void> initializeTempUser(String userId, String name) async {
    _currentUserId = userId;
    
    // Create or update user in Firestore
    final user = ChatUser.createTempUser(userId, name);
    await _usersCollection.doc(userId).set(user.toMap());
    
    if (kDebugMode) {
      print('Chat service initialized for user: $userId ($name)');
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not initialized. Call initializeTempUser first.');
    }

    try {
      // Get sender info
      final senderDoc = await _usersCollection.doc(_currentUserId).get();
      final senderName = senderDoc.exists 
          ? (senderDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';

      // Create conversation ID
      final conversationId = ChatConversation.createConversationId(_currentUserId!, receiverId);

      // Create message
      final messageId = _messagesCollection.doc().id;
      final message = ChatMessage(
        id: messageId,
        senderId: _currentUserId!,
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
        participants: [_currentUserId!, receiverId],
        lastMessage: content,
        lastMessageSenderId: _currentUserId!,
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
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    final conversationId = ChatConversation.createConversationId(_currentUserId!, otherUserId);
    
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromSnapshot(doc);
          }).toList();
        });
  }

  // Get user's conversations with real-time updates
  Stream<List<ChatConversation>> getConversationsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _conversationsCollection
        .where('participants', arrayContains: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatConversation.fromSnapshot(doc);
          }).toList();
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
          .where('name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // Search by email
      final emailQuery = await _usersCollection
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // Combine results and remove duplicates
      final users = <ChatUser>[];
      final seenIds = <String>{};

      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        final user = ChatUser.fromSnapshot(doc);
        if (!seenIds.contains(user.id) && user.id != _currentUserId) {
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

  // Get all users (for testing - remove in production)
  Future<List<ChatUser>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.limit(50).get();
      return snapshot.docs.map((doc) => ChatUser.fromSnapshot(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }

  // Mark messages as read (privacy-focused - only updates unread count)
  Future<void> markMessagesAsRead(String otherUserId) async {
    if (_currentUserId == null) return;

    try {
      final conversationId = ChatConversation.createConversationId(_currentUserId!, otherUserId);
      
      // Only update conversation unread count for privacy
      // We don't track individual message read status
      await _conversationsCollection.doc(conversationId).update({
        'unreadCounts.$_currentUserId': 0,
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
  Future<void> createTestUsers() async {
    final testUsers = [
      ChatUser.createTempUser('user1', 'Alice Johnson'),
      ChatUser.createTempUser('user2', 'Bob Smith'),
      ChatUser.createTempUser('user3', 'Charlie Brown'),
      ChatUser.createTempUser('user4', 'Diana Prince'),
      ChatUser.createTempUser('user5', 'Eve Wilson'),
    ];

    for (final user in testUsers) {
      await _usersCollection.doc(user.id).set(user.toMap());
    }

    if (kDebugMode) {
      print('Created ${testUsers.length} test users');
    }
  }

  // Get user by ID
  Future<ChatUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return ChatUser.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user: $e');
      }
      return null;
    }
  }

  // Clean up resources
  void dispose() {
    // Clean up any subscriptions if needed
  }
} 