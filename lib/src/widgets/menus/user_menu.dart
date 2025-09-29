import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/screens/account/messages/message_thread_screen.dart';
import 'package:interstellar/src/screens/settings/feed_settings_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:provider/provider.dart';

Future<void> showUserMenu(
  BuildContext context, {
  DetailedUserModel? detailedUser,
  UserModel? user,
  Function(DetailedUserModel)? update,
  bool navigateOption = false,
}) async {
  final ac = context.read<AppController>();

  if (detailedUser == null && user == null) return;

  final isMe =
      ac.isLoggedIn &&
      whenLoggedIn(
            context,
            true,
            matchesUsername: detailedUser?.name ?? user!.name,
          ) ==
          true;
  final globalName = (detailedUser?.name ?? user!.name).contains('@')
      ? '@${detailedUser?.name ?? user!.name}'
      : '@${detailedUser?.name ?? user!.name}@${ac.instanceHost}';

  return ContextMenu(
    actions: [
      if (!isMe &&
          ac.serverSoftware == ServerSoftware.mbin)
        ContextMenuAction(
          child: SubscriptionButton(
            isSubscribed: detailedUser?.isFollowedByUser,
            subscriptionCount: detailedUser?.followersCount,
            onSubscribe: (selected) async {
              var newValue = await ac.api.users.follow(
                detailedUser?.id?? user!.id,
                selected,
              );
              if (update != null) {
                update(newValue);
              }
            },
            followMode: true,
          ),
        ),
      ContextMenuAction(child: StarButton(globalName)),
      if (ac.isLoggedIn &&
          !isMe &&
          detailedUser != null &&
          update != null)
        ContextMenuAction(
          child: LoadingIconButton(
            onPressed: () async {
              final newValue = await ac.api.users.putBlock(
                detailedUser.id,
                !detailedUser.isBlockedByUser!,
              );

              update(newValue);
            },
            icon: const Icon(Symbols.block_rounded),
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                detailedUser.isBlockedByUser == true
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
      if (ac.isLoggedIn && !isMe && detailedUser != null)
        ContextMenuAction(
          icon: Symbols.mail_rounded,
          onTap: () => pushRoute(
            context,
            builder: (context) =>
                MessageThreadScreen(threadId: null, otherUser: detailedUser),
          ),
        ),
    ],
    items: [
      ContextMenuItem(
        title: 'Open',
        onTap: () => pushRoute(
          context,
          builder: (context) =>
              UserScreen(detailedUser?.id ?? user!.id, initData: detailedUser),
        ),
      ),
      ContextMenuItem(
        title: l(context).feeds_addTo,
        onTap: () async => showAddToFeedMenu(
          context,
          normalizeName(detailedUser?.name ?? user!.name, ac.instanceHost),
          FeedSource.user,
        ),
      ),
    ],
  ).openMenu(context);
}
