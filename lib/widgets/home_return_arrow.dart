import 'package:flutter/material.dart';

class HomeReturnArrow extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final EdgeInsetsGeometry? margin;
  final bool isFloating;

  const HomeReturnArrow({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.margin,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.primaryColor;
    final defaultIconColor = iconColor ?? Colors.white;
    final defaultSize = size ?? 56.0;

    if (isFloating) {
      return Container(
        margin: margin ?? EdgeInsets.all(16),
        child: FloatingActionButton(
          onPressed: () => _navigateToHome(context),
          backgroundColor: defaultBackgroundColor,
          foregroundColor: defaultIconColor,
          child: Icon(Icons.home, size: defaultSize * 0.4),
          mini: true,
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.all(8),
      child: Material(
        color: defaultBackgroundColor,
        borderRadius: BorderRadius.circular(defaultSize / 2),
        child: InkWell(
          onTap: () => _navigateToHome(context),
          borderRadius: BorderRadius.circular(defaultSize / 2),
          child: Container(
            width: defaultSize,
            height: defaultSize,
            child: Icon(
              Icons.home,
              color: defaultIconColor,
              size: defaultSize * 0.4,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home and clear the navigation stack
    // Since the app uses WebAuthWrapper as home, we need to pop to root
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// AppBar version of the home return arrow
class HomeReturnAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showHomeButton;
  final PreferredSizeWidget? bottom;

  const HomeReturnAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.showHomeButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.primaryColor;
    final defaultForegroundColor = foregroundColor ?? Colors.white;

    return AppBar(
      title: Text(title),
      backgroundColor: defaultBackgroundColor,
      foregroundColor: defaultForegroundColor,
      leading: showHomeButton
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () => _navigateToHome(context),
                ),
              ],
            )
          : IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
      leadingWidth: showHomeButton ? 96 : 48, // Double width when showing both icons
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + bottom!.preferredSize.height);

  void _navigateToHome(BuildContext context) {
    // Navigate to home and clear the navigation stack
    // Since the app uses WebAuthWrapper as home, we need to pop to root
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
} 