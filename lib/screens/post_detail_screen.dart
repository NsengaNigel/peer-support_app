import 'package:flutter/material.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> _comments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add({
          'author': 'You',
          'text': _commentController.text.trim(),
        });
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fictional posts data
    final posts = [
      {
        'id': 'post_0',
        'title': 'Welcome to UniReddit!',
        'author': 'Admin',
        'body': 'This is the first post in the community. Feel free to share your thoughts!',
        'comments': [
          {'author': 'Alice', 'text': 'Excited to be here!'},
          {'author': 'Bob', 'text': 'Looking forward to great discussions.'},
        ],
      },
      {
        'id': 'post_1',
        'title': 'Study Tips for Finals',
        'author': 'Student123',
        'body': 'Here are some tips to ace your finals: stay organized, take breaks, and ask for help when needed.',
        'comments': [
          {'author': 'Charlie', 'text': 'Thanks for the tips!'},
        ],
      },
      {
        'id': 'post_2',
        'title': 'Favorite Campus Spots',
        'author': 'JaneDoe',
        'body': 'What are your favorite places to relax on campus?',
        'comments': [
          {'author': 'Diana', 'text': 'I love the library garden.'},
        ],
      },
    ];
    final post = posts.firstWhere(
      (p) => p['id'] == widget.postId,
      orElse: () => posts[0],
    );
    
    // Combine original comments with new comments
    final allComments = [...(post['comments'] as List), ..._comments];
    
    return Scaffold(
      appBar: AppBar(title: Text(post['title'] as String)),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('By ${post['author']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(post['body'] as String),
                  const SizedBox(height: 24),
                  const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allComments.length,
                      itemBuilder: (context, index) {
                        final comment = allComments[index];
                        return ListTile(
                          leading: const Icon(Icons.comment),
                          title: Text((comment as Map)['author']),
                          subtitle: Text((comment as Map)['text']),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addComment,
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