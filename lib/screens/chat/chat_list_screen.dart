import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import '../../widgets/home_return_arrow.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import '../../navigation/app_drawer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Chats'),
        actions: [
          StreamBuilder<List<ChatConversation>>(
            stream: _chatService.getConversationsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final conversations = snapshot.data ?? [];
              final currentUserId = _chatService.currentUserId;
              if (currentUserId == null) return const SizedBox.shrink();
              
              final totalUnread = conversations.fold<int>(
                0,
                (sum, conv) => sum + conv.getUnreadCount(currentUserId),
              );
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.chat),
                  if (totalUnread > 0)
                    Positioned(
                      top: 8,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalUnread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Read/Unread filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showUnreadOnly = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showUnreadOnly ? Colors.blue : Colors.grey[200],
                      foregroundColor: !_showUnreadOnly ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Read'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showUnreadOnly = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showUnreadOnly ? Colors.blue : Colors.grey[200],
                      foregroundColor: _showUnreadOnly ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Unread'),
                  ),
                ),
              ],
            ),
          ),
          // Conversations list
          Expanded(
            child: StreamBuilder<List<ChatConversation>>(
              stream: _chatService.getConversationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF26A69A),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chats',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final conversations = snapshot.data ?? [];
                final filteredConversations = _showUnreadOnly
                    ? conversations.where((conv) {
                        final currentUserId = _chatService.currentUserId;
                        return conv.getUnreadCount(currentUserId ?? '') > 0;
                      }).toList()
                    : conversations;

                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showUnreadOnly ? 'No unread messages' : 'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    final currentUserId = _chatService.currentUserId;
                    if (currentUserId == null) return const SizedBox.shrink();

                    final otherParticipantId = conversation.getOtherParticipantId(currentUserId);
                    final otherParticipantName = conversation.getOtherParticipantName(currentUserId);
                    final unreadCount = conversation.getUnreadCount(currentUserId);
                    final isRead = unreadCount == 0;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              otherUserId: otherParticipantId,
                              otherUserName: otherParticipantName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF26A69A).withOpacity(0.2),
                              child: Text(
                                otherParticipantName.isNotEmpty
                                    ? otherParticipantName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF26A69A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherParticipantName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    conversation.lastMessage ?? 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (conversation.lastMessageTimestamp != null)
                                  Text(
                                    timeago.format(conversation.lastMessageTimestamp!),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  isRead ? 'Read' : 'Unread',
                                  style: TextStyle(
                                    color: isRead ? Colors.grey[500] : Colors.blue,
                                    fontSize: 12,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSearchScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 
