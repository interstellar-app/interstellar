import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/domain_screen.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/feed.dart';

class ExploreScreenItem extends StatelessWidget {
  final dynamic item;
  final void Function(dynamic newValue) onUpdate;
  final void Function()? onTap;
  final Widget? button;

  const ExploreScreenItem(
    this.item,
    this.onUpdate, {
    super.key,
    this.onTap,
    this.button,
  });

  @override
  Widget build(BuildContext context) {
    // ListTile based items
    if (item is DetailedCommunityModel ||
        item is DetailedUserModel ||
        item is DomainModel ||
        item is FeedModel) {
      final icon = switch (item) {
        DetailedCommunityModel i => i.icon,
        DetailedUserModel i => i.avatar,
        FeedModel i => i.icon,
        _ => null,
      };
      final title = switch (item) {
        DetailedCommunityModel i => i.title,
        DetailedUserModel i => i.displayName ?? i.name.split('@').first,
        DomainModel i => i.name,
        FeedModel i => i.title ?? i.name,
        _ => throw 'Unreachable',
      };
      final subtitle = switch (item) {
        DetailedCommunityModel i => i.name,
        DetailedUserModel i => i.name,
        FeedModel i => normalizeName(i.name, context.read<AppController>().instanceHost),
        _ => null,
      };
      final isSubscribed = switch (item) {
        DetailedCommunityModel i => i.isUserSubscribed,
        DetailedUserModel i => i.isFollowedByUser,
        DomainModel i => i.isUserSubscribed,
        FeedModel i => i.subscribed,
        _ => throw 'Unreachable',
      };
      final subscriptions = switch (item) {
        DetailedCommunityModel i => i.subscriptionsCount,
        DetailedUserModel i => i.followersCount,
        DomainModel i => i.subscriptionsCount,
        FeedModel i => i.subscriptionCount,
        _ => throw 'Unreachable',
      };
      final onSubscribe = switch (item) {
        DetailedCommunityModel i => (selected) async {
          var newValue = await context
              .read<AppController>()
              .api
              .community
              .subscribe(i.id, selected);

          onUpdate(newValue);
        },
        DetailedUserModel i => (selected) async {
          var newValue = await context.read<AppController>().api.users.follow(
            i.id,
            selected,
          );

          onUpdate(newValue);
        },
        DomainModel i => (selected) async {
          var newValue = await context
              .read<AppController>()
              .api
              .domains
              .putSubscribe(i.id, selected);

          onUpdate(newValue);
        },
        FeedModel _ => null,
        _ => throw 'Unreachable',
      };
      final navigate = switch (item) {
        DetailedCommunityModel i => () => pushRoute(
          context,
          builder: (context) =>
              CommunityScreen(i.id, initData: i, onUpdate: onUpdate),
        ),
        DetailedUserModel i => () => pushRoute(
          context,
          builder: (context) =>
              UserScreen(i.id, initData: i, onUpdate: onUpdate),
        ),
        DomainModel i => () => pushRoute(
          context,
          builder: (context) =>
              DomainScreen(i.id, initData: i, onUpdate: onUpdate),
        ),
        FeedModel i => () => pushRoute(
          context,
          builder: (context) => FeedScreen(feed: FeedAggregator(name: title, inputs: [
            FeedInputState(
              title: title,
              source: i.owner == null ? FeedSource.topic : FeedSource.feed, // owner exists for feeds but not for topics so is used to differentiate
              sourceId: i.id,
            )
          ]),)
        ),
        _ => throw 'Unreachable',
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
                    icon: Icon(Symbols.open_in_new_rounded),
                  ),
                ],
              ),
        onTap: onClick,
      );
    }

    // Card based items
    return switch (item) {
      PostModel item => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => pushRoute(
            context,
            builder: (context) => PostPage(initData: item, onUpdate: onUpdate),
          ),
          child: PostItem(
            item,
            onUpdate,
            isPreview: item.type != PostType.microblog,
          ),
        ),
      ),
      CommentModel item => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: PostComment(
          item,
          onUpdate,
          onClick: () => pushRoute(
            context,
            builder: (context) => PostCommentScreen(item.postType, item.id),
          ),
        ),
      ),
      _ => throw Exception('Unrecognized search item'),
    };
  }
}
