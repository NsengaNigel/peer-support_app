import 'package:flutter/material.dart';
import '../widgets/home_return_arrow.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeReturnAppBar(
        title: 'Help & Feedback',
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('Help & Feedback')),
    );
  }
} 