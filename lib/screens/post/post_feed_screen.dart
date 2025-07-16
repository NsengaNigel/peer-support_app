import 'package:flutter/material.dart';
import '../../main.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';

class PostFeedScreen extends StatelessWidget {
  const PostFeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UniReddit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: postsNotifier,
        builder: (context, posts, _) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No posts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join some communities or create your first post!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              // Ensure post contains communityId
              final communityId = post['communityId'];
              if (communityId == null) {
                return const SizedBox(); // Skip this post if invalid
              }

              return PostCard(
                post: post,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/post',
                    arguments: {
                      'postId': post['id'],
                      'communityId': communityId,
                    },
                  );
                },
                onCommentTap: () {
                  Navigator.pushNamed(
                    context,
                    '/post',
                    arguments: {
                      'postId': post['id'],
                      'communityId': communityId,
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
          // ValueNotifier should auto-update
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
