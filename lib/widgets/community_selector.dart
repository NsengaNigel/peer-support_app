import 'package:flutter/material.dart';
import '../models/community.dart';

class CommunitySelector extends StatelessWidget {
  final Community? selectedCommunity;
  final List<Community> communities;
  final Function(Community?) onCommunitySelected;
  final bool isLoading;

  const CommunitySelector({
    Key? key,
    required this.selectedCommunity,
    required this.communities,
    required this.onCommunitySelected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading communities...'),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<Community>(
                value: selectedCommunity,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select a community'),
                ),
                isExpanded: true,
                items: communities.map((Community community) {
                  return DropdownMenuItem<Community>(
                    value: community,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              community.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'r/${community.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${community.memberCount} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onCommunitySelected,
              ),
            ),
    );
  }
} 