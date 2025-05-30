import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/breakpoints.dart';

/// Wrapper of [Scaffold] which displays the drawer persistently based on screen size.
class AdvancedScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;

  const AdvancedScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasDrawer = drawer != null;
    final isExpanded = Breakpoints.isExpanded(context);

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          if (hasDrawer && isExpanded) SizedBox(width: 360, child: drawer!),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
      drawer: hasDrawer && !isExpanded
          ? Drawer(child: SafeArea(child: drawer!))
          : null,
    );
  }
}
