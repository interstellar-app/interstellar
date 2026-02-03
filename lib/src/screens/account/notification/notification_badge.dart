import 'package:flutter/material.dart';
import 'package:interstellar/src/screens/account/notification/notification_count_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationCountController>().value;

    return Wrapper(
      shouldWrap: count != 0,
      parentBuilder: (child) =>
          Badge(label: Text(intFormat(count)), child: child),
      child: widget.child,
    );
  }
}
