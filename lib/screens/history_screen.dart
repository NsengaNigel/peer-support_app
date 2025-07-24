import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_manager.dart';
import '../models/community.dart';
import 'communities_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Community> _visitedCommunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitedCommunities();
  }

  Future<void> _loadVisitedCommunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserModel = UserManager.currentUserModel;
      if (currentUserModel == null || currentUserModel.visitedCommunities.isEmpty) {
        setState(() {
          _visitedCommunities = [];
          _isLoading = false;
        });
        return;
      }

      // Get community details for visited community IDs
      final visitedCommunities = <Community>[];
      final communityIds = currentUserModel.visitedCommunities.reversed.take(20).toList(); // Last 20 visited

      // Batch the queries (Firestore 'in' has limit of 10)
      for (int i = 0; i < communityIds.length; i += 10) {
        final batch = communityIds.skip(i).take(10).toList();
        final communitiesQuery = await FirebaseFirestore.instance
            .collection('communities')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in communitiesQuery.docs) {
          visitedCommunities.add(Community.fromMap(doc.data(), doc.id));
        }
      }

      // Sort by visit order (most recent first)
      visitedCommunities.sort((a, b) {
        final aIndex = communityIds.indexOf(a.id);
        final bIndex = communityIds.indexOf(b.id);
        return aIndex.compareTo(bIndex);
      });

      setState(() {
        _visitedCommunities = visitedCommunities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History'),
        content: Text('Are you sure you want to clear your community visit history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = UserManager.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'visitedCommunities': [],
          });
          await UserManager.refreshUserModel();
          await _loadVisitedCommunities();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('History cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('History'),
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          if (_visitedCommunities.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _clearHistory();
                } else if (value == 'refresh') {
                  _loadVisitedCommunities();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear History', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visitedCommunities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No communities visited',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Communities you visit will appear here',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CommunitiesScreen()),
                          );
                        },
                        icon: Icon(Icons.explore),
                        label: Text('Explore Communities'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVisitedCommunities,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: _visitedCommunities.length,
                    itemBuilder: (context, index) {
                      final community = _visitedCommunities[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF00BCD4),
                            child: Text(
                              community.name.isNotEmpty ? community.name[0].toUpperCase() : 'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            community.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${community.memberCount} members',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () => _onCommunityTap(community),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 