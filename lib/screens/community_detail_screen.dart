import 'package:flutter/material.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const CommunityDetailScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    // Fictional community data
    final communities = [
      {'id': 'community_0', 'name': 'Programming', 'description': 'A place for programmers.', 'posts': ['How to learn Python?', 'Best IDEs in 2024']},
      {'id': 'community_1', 'name': 'University Life', 'description': 'Share your campus stories.', 'posts': ['Dorm hacks', 'Best campus food']},
      {'id': 'community_2', 'name': 'Book Club', 'description': 'Discuss your favorite books.', 'posts': ['Book of the month: 1984', 'Best fantasy novels']},
      {'id': 'community_3', 'name': 'Sports Fans', 'description': 'All about sports!', 'posts': ['Champions League Final', 'Best running shoes']},
      {'id': 'community_4', 'name': 'Music Lovers', 'description': 'For those who love music.', 'posts': ['Favorite albums', 'Best concerts attended']},
    ];
    final community = communities.firstWhere((c) => c['id'] == widget.communityId, orElse: () => communities[0]);
    return Scaffold(
      appBar: AppBar(title: Text(community['name'] as String)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(community['description'] as String, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (!_joined)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _joined = true;
                    });
                  },
                  child: const Text('Join Community'),
                ),
              ),
            if (_joined) ...[
              const Text('Posts:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((community['posts'] as List).map((p) => ListTile(
                    leading: const Icon(Icons.forum),
                    title: Text(p),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/post',
                        arguments: {'postId': 'community_post_${community['id']}_${(community['posts'] as List).indexOf(p)}'},
                      );
                    },
                  ))),
            ]
          ],
        ),
      ),
    );
  }
} 