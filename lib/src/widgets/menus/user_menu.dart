import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/utils/ap_urls.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/screens/settings/feed_settings_screen.dart';
import 'package:interstellar/src/widgets/tags/tag_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:provider/provider.dart';

Future<void> showUserMenu(
  BuildContext context, {
  required DetailedUserModel user,
  Function(DetailedUserModel)? update,
  bool navigateOption = false,
}) async {
  final ac = context.read<AppController>();

  final isMe =
      ac.isLoggedIn &&
      whenLoggedIn(context, true, matchesUsername: user.name) == true;
  final globalName = user.name.contains('@')
      ? '@${user.name}'
      : '@${user.name}@${ac.instanceHost}';

  return ContextMenu(
    actions: [
      if (!isMe && ac.serverSoftware == ServerSoftware.mbin)
        ContextMenuAction(
          child: SubscriptionButton(
            isSubscribed: user.isFollowedByUser,
            subscriptionCount: user.followersCount,
            onSubscribe: (selected) async {
              var newValue = await ac.api.users.follow(user.id, selected);
              if (update != null) {
                update(newValue);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            followMode: true,
          ),
        ),
      ContextMenuAction(child: StarButton(globalName)),
      if (ac.isLoggedIn && !isMe)
        ContextMenuAction(
          child: LoadingIconButton(
            onPressed: () async {
              final newValue = await ac.api.users.putBlock(
                user.id,
                !(user.isBlockedByUser ?? false),
              );

              if (update != null) {
                update(newValue);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Symbols.block_rounded),
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                user.isBlockedByUser == true
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
      if (ac.isLoggedIn && !isMe)
        ContextMenuAction(
          icon: Symbols.mail_rounded,
          onTap: () => context.router.push(
            MessageThreadRoute(
              threadId: null,
              userId: user.id,
              otherUser: user,
            ),
          ),
        ),
    ],
    links: genUserUrls(context, UserModel.fromDetailedUser(user)),
    items: [
      if (navigateOption)
        ContextMenuItem(
          title: l(context).openItem(user.name),
          onTap: () =>
              context.router.push(UserRoute(userId: user.id, initData: user)),
        ),
      ContextMenuItem(
        title: l(context).feeds_addTo,
        onTap: () async => showAddToFeedMenu(
          context,
          normalizeName(user.name, ac.instanceHost),
          FeedSource.user,
        ),
      ),
      if (ac.serverSoftware != ServerSoftware.piefed)
        ContextMenuItem(
          title: l(context).search,
          onTap: () => context.router.push(
            ExploreRoute(
              mode: ExploreType.people,
              id: user.id,
              title: l(context).searchSource(user.name),
            ),
          ),
        ),
      ContextMenuItem(
        title: l(context).tags,
        onTap: () async {
          showModalBottomSheet(
            context: context,
            builder: (context) => TagsList(
              username: user.name,
              onUpdate: (tags) async {
                await ac.reassignTagsToUser(tags, user.name);
              },
            ),
          );
        },
      ),
      if (ac.serverSoftware == ServerSoftware.lemmy)
        ContextMenuItem(
          title: l(context).modlog,
          onTap: () => context.router.push(ModLogRoute(userId: user.id)),
        ),
    ],
  ).openMenu(context);
}
