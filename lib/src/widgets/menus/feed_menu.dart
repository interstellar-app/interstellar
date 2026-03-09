import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/settings/feed_settings_screen.dart';
import 'package:interstellar/src/utils/ap_urls.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:provider/provider.dart';

Future<void> showFeedMenu(
  BuildContext context, {
  FeedModel? feed,
  void Function(FeedModel)? update,
  bool navigateOption = false,
}) async {
  final ac = context.read<AppController>();

  if (feed == null) return;

  final globalName = feed.name.contains('@')
      ? '!${feed.name}'
      : '!${feed.name}@${ac.instanceHost}';

  final isOwner = feed.owner ?? false;

  return ContextMenu(
    actions: [
      ContextMenuAction(
        child: SubscriptionButton(
          isSubscribed: feed.subscribed,
          subscriptionCount: feed.subscriptionCount,
          onSubscribe: (selected) async {
            final newValue = await ac.api.feed.subscribe(feed.id, selected);

            if (update != null) {
              update(newValue);
            }
          },
          followMode: false,
        ),
      ),
      ContextMenuAction(child: StarButton(globalName)),
    ],
    links: genFeedUrls(context, feed),
    items: [
      if (navigateOption)
        ContextMenuItem(
          title: l(context).openItem(feed.name),
          onTap: () => context.router.push(
            FeedRoute(
              feedName: feed.title,
              feed: FeedAggregator(
                name: feed.title,
                inputs: [
                  FeedInputState(
                    title: feed.name,
                    source: feed.owner == null
                        ? FeedSource.topic
                        : FeedSource.feed,
                    sourceId: feed.id,
                  ),
                ],
              ),
              details: FeedDetails(feed: feed),
            ),
          ),
        ),
      ContextMenuItem(
        title: l(context).feeds_addTo,
        onTap: () async => showAddToFeedMenu(
          context,
          normalizeName(feed.name, ac.instanceHost),
          FeedSource.feed,
        ),
      ),
      ContextMenuItem(
        title: l(context).save,
        onTap: () async {
          await ac.setFeed(
            feed.name,
            Feed(
              inputs: {
                FeedInput(
                  name: normalizeName(feed.name, ac.instanceHost),
                  sourceType: FeedSource.feed,
                ),
              },
            ),
          );
          if (!context.mounted) return;
          context.router.pop();
        },
      ),
      ContextMenuItem(
        title: l(context).communities,
        subItems: feed.communities
            .map(
              (community) => ContextMenuItem(
                title: community.name,
                onTap: () => context.router.push(
                  CommunityRoute(communityName: community.name),
                ),
              ),
            )
            .toList(),
      ),
    ],
  ).openMenu(context);
}
