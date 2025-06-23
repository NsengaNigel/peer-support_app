import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../models/post.dart';
import 'create_post_screen.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({Key? key}) : super(key: key);

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();
  
  // Mock user data - replace with actual user data later
  final List<String> _joinedCommunities = ['programming', 'university'];
  
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final posts = await _postService.getFeedForUser(_joinedCommunities);
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

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
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to create post screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
          if (result == true) {
            _loadPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
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
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join some communities or create your first post!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _posts.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return PostCard(
          post: post,
          onTap: () {
            // Navigate to post detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening post: ${post.title}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          onCommentTap: () {
            // Navigate to post detail with focus on comments
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Comments for: ${post.title}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
} 