import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/menus/community_menu.dart';
import 'package:interstellar/src/widgets/menus/user_menu.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ExploreScreenItem extends StatelessWidget {
  const ExploreScreenItem(
    this.item,
    this.onUpdate, {
    super.key,
    this.onTap,
    this.button,
  });

  final dynamic item;
  final void Function(dynamic newValue) onUpdate;
  final void Function()? onTap;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    // ListTile based items
    if (item is DetailedCommunityModel ||
        item is DetailedUserModel ||
        item is DomainModel ||
        item is FeedModel) {
      final icon = switch (item) {
        final DetailedCommunityModel i => i.icon,
        final DetailedUserModel i => i.avatar,
        final FeedModel i => i.icon,
        _ => null,
      };
      final title = switch (item) {
        final DetailedCommunityModel i => i.title,
        final DetailedUserModel i => i.displayName ?? i.name.split('@').first,
        final DomainModel i => i.name,
        final FeedModel i => i.title,
        _ => throw UnreachableError(),
      };
      final subtitle = switch (item) {
        final DetailedCommunityModel i => i.name,
        final DetailedUserModel i => i.name,
        final FeedModel i => normalizeName(
          i.name,
          context.read<AppController>().instanceHost,
        ),
        _ => null,
      };
      final isSubscribed = switch (item) {
        final DetailedCommunityModel i => i.isUserSubscribed,
        final DetailedUserModel i => i.isFollowedByUser,
        final DomainModel i => i.isUserSubscribed,
        final FeedModel i => i.subscribed,
        _ => throw UnreachableError(),
      };
      final subscriptions = switch (item) {
        final DetailedCommunityModel i => i.subscriptionsCount,
        final DetailedUserModel i => i.followersCount,
        final DomainModel i => i.subscriptionsCount,
        final FeedModel i => i.subscriptionCount,
        _ => throw UnreachableError(),
      };
      final onSubscribe = switch (item) {
        final DetailedCommunityModel i => (bool selected) async {
          final newValue = await context
              .read<AppController>()
              .api
              .community
              .subscribe(i.id, selected);

          onUpdate(newValue);
        },
        final DetailedUserModel i => (bool selected) async {
          final newValue = await context.read<AppController>().api.users.follow(
            i.id,
            selected,
          );

          onUpdate(newValue);
        },
        final DomainModel i => (bool selected) async {
          final newValue = await context
              .read<AppController>()
              .api
              .domains
              .putSubscribe(i.id, selected);

          onUpdate(newValue);
        },
        FeedModel _ => null,
        _ => throw UnreachableError(),
      };
      final navigate = switch (item) {
        final DetailedCommunityModel i => () => context.router.push(
          CommunityRoute(communityId: i.id, initData: i, onUpdate: onUpdate),
        ),
        final DetailedUserModel i => () => context.router.push(
          UserRoute(userId: i.id, initData: i, onUpdate: onUpdate),
        ),
        final DomainModel i => () => context.router.push(
          DomainRoute(domainId: i.id, initData: i, onUpdate: onUpdate),
        ),
        final FeedModel i => () => context.router.push(
          FeedRoute(
            feed: FeedAggregator(
              name: title,
              inputs: [
                FeedInputState(
                  title: title,
                  source: i.owner == null ? FeedSource.topic : FeedSource.feed,
                  sourceId: i.id,
                ),
              ],
            ),
          ),
        ),
        _ => throw UnreachableError(),
      };
      final onClick = onTap ?? navigate;

      return ListTile(
        leading: icon == null
            ? const SizedBox(width: 16)
            : Avatar(icon, radius: 16),
        title: Row(
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            if (item is DetailedUserModel)
              UserStatusIcons(cakeDay: item.createdAt, isBot: item.isBot),
          ],
        ),
        onLongPress: () => switch (item) {
          final DetailedCommunityModel i => showCommunityMenu(
            context,
            detailedCommunity: i,
            navigateOption: true,
          ),
          final DetailedUserModel i => showUserMenu(
            context,
            user: i,
            navigateOption: true,
          ),
          DomainModel _ => {},
          FeedModel _ => {},
          _ => throw UnreachableError(),
        },
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: button == null
            ? subscriptions != null && onSubscribe != null
                  ? SubscriptionButton(
                      isSubscribed: isSubscribed,
                      subscriptionCount: subscriptions,
                      onSubscribe: onSubscribe,
                      followMode: item is DetailedUserModel,
                    )
                  : null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button!,
                  IconButton(
                    onPressed: navigate,
                    icon: const Icon(Symbols.open_in_new_rounded),
                  ),
                ],
              ),
        onTap: onClick,
      );
    }

    // Card based items
    return switch (item) {
      final PostModel item => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => pushPostPage(
            context,
            postId: item.id,
            postType: item.type,
            initData: item,
            onUpdate: onUpdate,
          ),
          child: PostItem(
            item,
            onUpdate,
            isPreview: item.type != PostType.microblog,
          ),
        ),
      ),
      final CommentModel item => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: PostComment(
          item,
          onUpdate,
          onClick: () => context.router.push(
            PostCommentRoute(postType: item.postType, commentId: item.id),
          ),
        ),
      ),
      _ => throw Exception('Unrecognized search item'),
    };
  }
}
