import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/screens/explore/community_owner_panel.dart';
import 'package:interstellar/src/screens/explore/community_mod_panel.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/screens/settings/feed_settings_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

Future<void> showCommunityMenu(
  BuildContext context, {
  DetailedCommunityModel? detailedCommunity,
  CommunityModel? community,
  Function(DetailedCommunityModel)? update,
  bool navigateOption = false,
}) async {
  final ac = context.read<AppController>();

  if (detailedCommunity == null && community == null) return;

  final name = detailedCommunity?.name ?? community!.name;
  final globalName = (name).contains('@')
      ? '!$name'
      : '!$name@${ac.instanceHost}';

  final isModerator = detailedCommunity == null
      ? false
      : detailedCommunity.moderators.any((mod) => mod.name == ac.localName);

  return ContextMenu(
    actions: [
      ContextMenuAction(
        child: SubscriptionButton(
          isSubscribed: detailedCommunity?.isUserSubscribed,
          subscriptionCount: detailedCommunity?.subscriptionsCount,
          onSubscribe: (selected) async {
            var newValue = await ac.api.community.subscribe(
              detailedCommunity?.id ?? community!.id,
              selected,
            );

            if (update != null) {
              update(newValue);
            }
          },
          followMode: false,
        ),
      ),
      ContextMenuAction(child: StarButton(globalName)),
      ContextMenuAction(
        child: LoadingIconButton(
          onPressed: () async {
            final newValue = await ac.api.community.block(
              detailedCommunity?.id ?? community!.id,
              detailedCommunity != null
                  ? !detailedCommunity.isBlockedByUser!
                  : false,
            );
            update!(newValue);
          },
          icon: const Icon(Symbols.block_rounded),
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              detailedCommunity != null &&
                      detailedCommunity.isBlockedByUser == true
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ),
    ],
    items: [
      ContextMenuItem(
        title: 'Open',
        onTap: () => pushRoute(
          context,
          builder: (context) => CommunityScreen(
            detailedCommunity?.id ?? community!.id,
            initData: detailedCommunity,
          ),
        ),
      ),
      ContextMenuItem(
        title: l(context).openInBrowser,
        onTap: () async => openWebpagePrimary(
          context,
          Uri.https(
            ac.instanceHost,
            ac.serverSoftware == ServerSoftware.mbin ? '/m/$name' : '/c/$name',
          ),
        ),
      ),
      if (detailedCommunity != null)
        ContextMenuItem(
          title: l(context).viewMods,
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l(context).modsOf(name)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: detailedCommunity.moderators
                    .map(
                      (mod) => UserItemSimple(
                        mod,
                        isOwner: mod.id == detailedCommunity.owner?.id,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      if (isModerator)
        ContextMenuItem(
          title: l(context).modPanel,
          onTap: () => pushRoute(
            context,
            builder: (context) => CommunityModPanel(
              initData: detailedCommunity,
              onUpdate: update!,
            ),
          ),
        ),
      if (detailedCommunity != null &&
          detailedCommunity.owner != null &&
          detailedCommunity.owner!.name == ac.localName)
        ContextMenuItem(
          title: l(context).ownerPanel,
          onTap: () => pushRoute(
            context,
            builder: (context) => CommunityOwnerPanel(
              initData: detailedCommunity,
              onUpdate: update!,
            ),
          ),
        ),
      ContextMenuItem(
        title: l(context).feeds_addTo,
        onTap: () async => showAddToFeedMenu(
          context,
          normalizeName(name, ac.instanceHost),
          FeedSource.community,
        ),
      ),
    ],
  ).openMenu(context);
}
