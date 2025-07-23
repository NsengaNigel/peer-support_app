import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTimestamp;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTimestamp,
    Map<String, int>? unreadCounts,
    required this.createdAt,
    required this.updatedAt,
  }) : unreadCounts = unreadCounts ?? {};

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': lastMessageTimestamp != null 
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? (map['lastMessageTimestamp'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory ChatConversation.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ChatConversation.fromMap(data);
  }

  // Get the other participant's ID (for 1-on-1 chats)
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Get the other participant's name (for 1-on-1 chats)
  String getOtherParticipantName(String currentUserId) {
    final otherParticipantId = getOtherParticipantId(currentUserId);
    return participantNames[otherParticipantId] ?? 'Unknown User';
  }

  // Get unread count for specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  // Copy with method for updates
  ChatConversation copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTimestamp,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create conversation ID from two user IDs (deterministic)
  static String createConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
} 