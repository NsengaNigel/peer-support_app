import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'John Doe',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('Computer Science Student'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: const [
                        Text('150', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Posts'),
                      ],
                    ),
                    Column(
                      children: const [
                        Text('1.2K', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Karma'),
                      ],
                    ),
                    Column(
                      children: const [
                        Text('2y', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Reddit Age'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('My Posts'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('My Comments'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCommentsScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Saved'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedScreen()),
                    );
                  },
                ),
                const Divider(),
                const ListTile(
                  title: Text('Joined Communities', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: const Text('Programming'),
                  subtitle: const Text('1.2K members'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/community',
                      arguments: {'communityId': 'community_0'},
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: const Text('University Life'),
                  subtitle: const Text('850 members'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/community',
                      arguments: {'communityId': 'community_1'},
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final posts = [
      'My first post',
      'Another day at university',
      'Flutter is awesome!',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('My Posts')),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.article),
          title: Text(posts[index]),
        ),
      ),
    );
  }
}

class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final comments = [
      'Great post!',
      'I totally agree with you.',
      'Thanks for sharing!',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('My Comments')),
      body: ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.comment),
          title: Text(comments[index]),
        ),
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final saved = [
      'Saved post 1',
      'Saved post 2',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ListView.builder(
        itemCount: saved.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(saved[index]),
        ),
      ),
    );
  }
} 