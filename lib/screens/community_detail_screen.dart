import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/community_service.dart';
import '../services/user_manager.dart';
import '../services/history_service.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool _joined = false;
  String _communityName = '';
  String _communityDescription = '';
  int _memberCount = 0;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isJoining = false;
  final CommunityService _communityService = CommunityService();
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _loadCommunityDetails();
    // Track community visit for history
    _historyService.visitCommunity(widget.communityId);
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

      // Check if current user is a member of this community
      final currentUser = UserManager.currentUser;
      bool isJoined = false;
      
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final joinedCommunities = List<String>.from(userData['joinedCommunities'] ?? []);
          isJoined = joinedCommunities.contains(widget.communityId);
        }
      }

      // Fetch posts from the community (remove orderBy to avoid index issues)
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('communityId', isEqualTo: widget.communityId)
          .get();

      // Sort posts manually
      final posts = postsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();

      // Sort by creation date (newest first)
      posts.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];
        
        DateTime? aDateTime;
        DateTime? bDateTime;
        
        // Handle both Timestamp and String formats
        if (aCreatedAt is Timestamp) {
          aDateTime = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          aDateTime = DateTime.tryParse(aCreatedAt);
        }
        
        if (bCreatedAt is Timestamp) {
          bDateTime = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          bDateTime = DateTime.tryParse(bCreatedAt);
        }
        
        if (aDateTime == null || bDateTime == null) return 0;
        return bDateTime.compareTo(aDateTime);
      });

      if (mounted) {
        setState(() {
          _communityName = communityData['name'] ?? '';
          _communityDescription = communityData['description'] ?? '';
          _memberCount = communityData['memberCount'] ?? 0;
          _joined = isJoined;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading community: $e')),
        );
      }
    }
  }

  Future<void> _joinCommunity() async {
    final currentUser = UserManager.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join communities')),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await _communityService.joinCommunity(
        communityId: widget.communityId,
        userId: currentUser.uid,
      );
      
      if (mounted) {
        setState(() {
          _joined = true;
          _memberCount++;
          _isJoining = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined $_communityName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveCommunity() async {
    final currentUser = UserManager.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await _communityService.leaveCommunity(
        communityId: widget.communityId,
        userId: currentUser.uid,
      );
      
      if (mounted) {
        setState(() {
          _joined = false;
          _memberCount--;
          _isJoining = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left $_communityName'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_communityName),
        backgroundColor: Color(0xFF00BCD4),
        actions: [
          if (_joined)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _isJoining ? null : _leaveCommunity,
              tooltip: 'Leave Community',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF00BCD4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.group,
                          color: Color(0xFF00BCD4),
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _communityName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$_memberCount members',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _communityDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Join/Leave button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : (_joined ? _leaveCommunity : _joinCommunity),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _joined ? Colors.red : Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isJoining
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _joined ? 'Leave Community' : 'Join Community',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Posts section
            if (_joined) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Community Posts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_posts.length} posts',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_posts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.post_add,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No posts yet in this community',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to share something!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...(_posts.map((post) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF00BCD4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.forum,
                        color: Color(0xFF00BCD4),
                      ),
                    ),
                    title: Text(
                      post['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      post['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/post_detail',
                        arguments: post['id'],
                      );
                    },
                  ),
                ))),
            ] else ...[
              // Not joined message
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Join the community to see posts',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connect with other members and participate in discussions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}