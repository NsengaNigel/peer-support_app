import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community.dart';
import '../services/community_service.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({Key? key}) : super(key: key);

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final CommunityService _communityService = CommunityService();
  List<Community> _communities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _communities = [];
          _isLoading = false;
        });
        return;
      }
      final communities =
      await _communityService.getUserCommunities(userId: user.uid);
      setState(() {
        _communities = communities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load communities')),
      );
    }
  }

  Future<void> _showCreateCommunityDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Community'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                  const InputDecoration(labelText: 'Community Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  if (name.isEmpty || description.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  setState(() => isSubmitting = true);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) throw Exception('You must be logged in');

                    final newCommunity = await _communityService.createCommunity(
                      name: name,
                      description: description,
                      userId: user.uid,
                    );

                    setState(() => isSubmitting = false);
                    Navigator.of(context).pop();

                    // Add new community to the list
                    setState(() {
                      _communities.add(newCommunity);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Community created!')),
                    );
                  } catch (e) {
                    setState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create'),
              ),
            ],
          );
        });
      },
    );
  }

  void _onCommunityTap(Community community) {
    Navigator.pushNamed(
      context,
      '/community',
      arguments: {'communityId': community.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _communities.isEmpty
          ? const Center(child: Text('No communities found'))
          : ListView.separated(
        itemCount: _communities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final community = _communities[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(community.name),
            subtitle: Text('${community.memberCount} members'),
            onTap: () => _onCommunityTap(community),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCommunityDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Community'),
      ),
    );
  }
}
