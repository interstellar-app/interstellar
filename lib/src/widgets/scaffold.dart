import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/breakpoints.dart';

/// Wrapper of [Scaffold] which displays the drawer persistently based on screen size.
class AdvancedScaffold extends StatelessWidget {
  const AdvancedScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.controller,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final ExpandableController? controller;

  @override
  Widget build(BuildContext context) {
    final hasDrawer = drawer != null;
    final isExpanded = Breakpoints.isExpanded(context);

    return Scaffold(
      appBar: appBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDrawer && isExpanded)
            Expandable(
              controller: controller,
              collapsed: Container(),
              expanded: SizedBox(width: 360, child: drawer),
            ),
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
