import 'package:flutter/material.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> people = [
      {
        'name': 'Alice Johnson',
        'message': 'Hey! Are you coming to the study group?',
        'avatar': 'A',
      },
      {
        'name': 'Bob Smith',
        'message': "Don't forget the assignment due tomorrow.",
        'avatar': 'B',
      },
      {
        'name': 'Charlie Lee',
        'message': "Let's catch up after class!",
        'avatar': 'C',
      },
      {
        'name': 'Diana Prince',
        'message': 'Thanks for your help!',
        'avatar': 'D',
      },
      {
        'name': 'Ethan Brown',
        'message': 'See you at the event tonight.',
        'avatar': 'E',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: ListView.separated(
        itemCount: people.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final person = people[index];
          return ListTile(
            leading: CircleAvatar(child: Text(person['avatar']!)),
            title: Text(person['name']!),
            subtitle: Text(person['message']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(personName: person['name']!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String personName;
  const ChatScreen({Key? key, required this.personName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'from': 'You', 'text': 'Hi! How are you?'},
    {'from': 'Them', 'text': 'Doing well, thanks!'},
    {'from': 'You', 'text': 'Glad to hear!'},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'from': 'You',
          'text': _messageController.text.trim(),
        });
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.personName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['from'] == 'You';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.orange[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 