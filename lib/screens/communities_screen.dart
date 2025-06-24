import 'package:flutter/material.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> communities = [
      {'id': 'community_0', 'name': 'Programming', 'members': 1200},
      {'id': 'community_1', 'name': 'University Life', 'members': 850},
      {'id': 'community_2', 'name': 'Book Club', 'members': 430},
      {'id': 'community_3', 'name': 'Sports Fans', 'members': 670},
      {'id': 'community_4', 'name': 'Music Lovers', 'members': 520},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: ListView.separated(
        itemCount: communities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final community = communities[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(community['name']),
            subtitle: Text('${community['members']} members'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/community',
                arguments: {'communityId': community['id']},
              );
            },
          );
        },
      ),
    );
  }
} 