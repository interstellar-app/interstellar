import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';

class UserItemSimple extends StatelessWidget {
  final UserModel user;
  final bool isOwner;
  final List<Widget>? trailingWidgets;
  final bool noTap;

  const UserItemSimple(
    this.user, {
    this.isOwner = false,
    this.trailingWidgets,
    this.noTap = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: noTap
          ? null
          : () => context.router.push(UserRoute(userId: user.id)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (user.avatar != null) Avatar(user.avatar, radius: 16),
            Container(width: 8 + (user.avatar != null ? 0 : 32)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isOwner ? FontWeight.bold : null,
                    ),
                  ),
                  if (isOwner) Text(l(context).owner),
                ],
              ),
            ),
            ...trailingWidgets ?? [],
          ],
        ),
      ),
    );
  }
}
