import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: Center(child: Text('User ID: $userId')),
    );
  }
} 