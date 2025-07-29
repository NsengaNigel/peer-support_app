import 'package:flutter/material.dart';
import '../navigation/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final VoidCallback? onLogout;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: AppDrawer(onLogout: onLogout),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
} 