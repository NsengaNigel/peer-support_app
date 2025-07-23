import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../services/user_manager.dart';
import '../models/user_model.dart';
import '../widgets/admin_actions.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({Key? key}) : super(key: key);

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  late TabController _tabController;
  
  List<Community> _allCommunities = [];
  List<Community> _userCommunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _allCommunities = [];
            _userCommunities = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Load all communities and user's joined communities
      final allCommunitiesFuture = _communityService.getAllCommunities();
      final userCommunitiesFuture = _communityService.getUserCommunities(userId: user.uid);

      final results = await Future.wait([allCommunitiesFuture, userCommunitiesFuture]);
      
      if (mounted) {
        setState(() {
          _allCommunities = results[0] as List<Community>;
          _userCommunities = results[1] as List<Community>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load communities: $e')),
      );
    }
  }

  Future<void> _joinCommunity(Community community) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('You must be logged in');

      // Add user to community members
      await _communityService.joinCommunity(
        communityId: community.id,
        userId: user.uid,
      );

      // Refresh communities
      await _loadCommunities();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${community.name}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining community: $e')),
      );
    }
  }

  Future<void> _leaveCommunity(Community community) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('You must be logged in');

      // Remove user from community members
      await _communityService.leaveCommunity(
        communityId: community.id,
        userId: user.uid,
      );

      // Refresh communities
      await _loadCommunities();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Left ${community.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving community: $e')),
      );
    }
  }

  bool _isUserInCommunity(String communityId) {
    return _userCommunities.any((c) => c.id == communityId);
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
                  decoration: const InputDecoration(
                    labelText: 'Community Name',
                    hintText: 'Enter community name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your community',
                  ),
                  maxLines: 3,
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

                    // Refresh communities after creation
                    await _loadCommunities();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Community created successfully!')),
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

  Widget _buildCommunityCard(Community community, {bool isJoined = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            community.name.isNotEmpty ? community.name[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                community.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Admin actions for super admins
            if (UserManager.currentUserModel?.isSuperAdmin == true)
              AdminCommunityActions(
                communityId: community.id,
                communityName: community.name,
                onDeleted: () {
                  // Refresh communities list when community is deleted
                  _loadCommunities();
                },
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${community.memberCount} members',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isJoined
            ? ElevatedButton(
                onPressed: () => _leaveCommunity(community),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Leave'),
              )
            : ElevatedButton(
                onPressed: () => _joinCommunity(community),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Join'),
              ),
        onTap: () => _onCommunityTap(community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00BCD4),
        title: const Text('Communities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Communities'),
            Tab(text: 'My Communities'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // All Communities Tab
                RefreshIndicator(
                  onRefresh: _loadCommunities,
                  child: _allCommunities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No communities found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to create a community!',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allCommunities.length,
                          itemBuilder: (context, index) {
                            final community = _allCommunities[index];
                            final isJoined = _isUserInCommunity(community.id);
                            return _buildCommunityCard(community, isJoined: isJoined);
                          },
                        ),
                ),
                // My Communities Tab
                RefreshIndicator(
                  onRefresh: _loadCommunities,
                  child: _userCommunities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No communities joined',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Join communities to see them here!',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _userCommunities.length,
                          itemBuilder: (context, index) {
                            final community = _userCommunities[index];
                            return _buildCommunityCard(community, isJoined: true);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCommunityDialog,
        backgroundColor: Color(0xFF00BCD4),
        icon: const Icon(Icons.add),
        label: const Text('New Community'),
      ),
    );
  }
}
