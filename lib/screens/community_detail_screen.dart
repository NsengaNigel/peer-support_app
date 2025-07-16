import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const CommunityDetailScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool _joined = false;
  String _communityName = '';
  String _communityDescription = '';
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunityDetails();
  }

  Future<void> _loadCommunityDetails() async {
    try {
      final communityDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .get();

      if (!communityDoc.exists) {
        throw Exception('Community not found');
      }

      final communityData = communityDoc.data()!;

      // 🔧 CHANGED: Fetch posts from flat 'posts' collection instead of nested under community
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('communityId', isEqualTo: widget.communityId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _communityName = communityData['name'] ?? '';
        _communityDescription = communityData['description'] ?? '';
        _posts = postsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'content': data['content'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading community: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_communityName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_communityDescription, style: const TextStyle(fontSize: 16)),
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
              const SizedBox(height: 16),
              const Text('Posts:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No posts yet in this community.'),
                ),
              ..._posts.map(
                    (post) => ListTile(
                  leading: const Icon(Icons.forum),
                  title: Text(post['title']),
                  subtitle: Text(
                    post['content'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/post',
                      arguments: {
                        'postId': post['id'],
                        // 🟨 Removed 'communityId' from arguments since it's no longer needed in PostDetailScreen
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}