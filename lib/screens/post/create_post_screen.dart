import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post.dart';
import '../../models/community.dart';
import '../../services/post_service.dart';
import '../../services/community_service.dart';
import '../../widgets/community_selector.dart';
import '../../widgets/home_return_arrow.dart';
import '../../main.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  final PostService _postService = PostService();
  final CommunityService _communityService = CommunityService();

  Community? _selectedCommunity;
  List<Community> _communities = [];
  bool _isLoadingCommunities = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _communities = [];
            _isLoadingCommunities = false;
          });
        }
        return;
      }
      final communities =
          await _communityService.getUserCommunities(userId: user.uid);
      if (mounted) {
        setState(() {
          _communities = communities;
          _isLoadingCommunities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCommunities = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load communities'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCommunity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a community'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to post.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user.uid,
        authorUsername: user.displayName ?? user.email ?? 'Anonymous',
        communityId: _selectedCommunity!.id,
        communityName: _selectedCommunity!.name,
        createdAt: DateTime.now(),
        commentCount: 0,
      );

      await _postService.addPost(newPost);

      // Add to global postsNotifier
      postsNotifier.value = [
        ...postsNotifier.value,
        {
          'id': newPost.id,
          'title': newPost.title,
          'author': newPost.authorUsername,
          'body': newPost.content,
          'comments': [],
        }
      ];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to the community screen with the selected community id
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/community',
          (route) => false,
          arguments: {'communityId': _selectedCommunity!.id},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeReturnAppBar(
        title: 'Create Post',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue, // Light blue background
                foregroundColor: Colors.white, // White text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'POST',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a community',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CommunitySelector(
                      selectedCommunity: _selectedCommunity,
                      communities: _communities,
                      onCommunitySelected: (Community? community) {
                        setState(() {
                          _selectedCommunity = community;
                        });
                      },
                      isLoading: _isLoadingCommunities,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'An interesting title...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLength: 300,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _contentFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'What are your thoughts?',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      maxLength: 10000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter some content';
                        }
                        if (value.trim().length < 10) {
                          return 'Content must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPost,
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Posting...'),
                              ],
                            )
                          : const Text(
                              'Create Post',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
