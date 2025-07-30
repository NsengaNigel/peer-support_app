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

  void _showCommunitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Select Community',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingCommunities
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _communities.length,
                      itemBuilder: (context, index) {
                        final community = _communities[index];
                        return ListTile(
                          title: Text(
                            community.name,
                            style: TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            '${community.memberCount} members',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCommunity = community;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: Color(0xFFF5F7FA), // Light background to match other pages
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1E3A8A), // Dark blue
                Color(0xFF0D9488), // Teal
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
            title: Text(
              'Create a post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // Show options menu
                },
              ),
            ],
          ),
        ),
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
                    // Main content area with white background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // White background
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Select Community Button
                          GestureDetector(
                            onTap: () {
                              _showCommunitySelector(context);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Color(0xFF00BCD4), // Teal color to match app theme
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _selectedCommunity?.name ?? 'Select Community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title Label
                          Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Title Input Field
                          TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Enter your title...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                              contentPadding: EdgeInsets.all(16),
                              filled: true,
                              fillColor: Colors.white,
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
                          
                          // Body Label
                          Text(
                            'Body',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Body Input Field
                          TextFormField(
                            controller: _contentController,
                            focusNode: _contentFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Enter your content...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.black, width: 2),
                              ),
                              contentPadding: EdgeInsets.all(16),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.white,
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
                  ],
                ),
              ),
            ),
            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pushReplacementNamed('/');
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00BCD4), // Teal color to match app theme
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
