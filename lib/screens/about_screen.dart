import 'package:flutter/material.dart';
import '../widgets/home_return_arrow.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeReturnAppBar(
        title: 'About',
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('About Peer support')),
    );
  }
} 