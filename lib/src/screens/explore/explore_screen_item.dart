import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/domain_screen.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:provider/provider.dart';

class ExploreScreenItem extends StatelessWidget {
  final dynamic item;
  final void Function(dynamic newValue) onUpdate;

  const ExploreScreenItem(this.item, this.onUpdate, {super.key});

  @override
  Widget build(BuildContext context) {
    // ListTile based items
    if (item is DetailedMagazineModel ||
        item is DetailedUserModel ||
        item is DomainModel) {
      final icon = switch (item) {
        DetailedMagazineModel i => i.icon,
        DetailedUserModel i => i.avatar,
        _ => null,
      };
      final title = switch (item) {
        DetailedMagazineModel i => i.title,
        DetailedUserModel i => i.displayName ?? i.name.split('@').first,
        DomainModel i => i.name,
        _ => throw 'Unreachable',
      };
      final subtitle = switch (item) {
        DetailedMagazineModel i => i.name,
        DetailedUserModel i => i.name,
        _ => null,
      };
      final isSubscribed = switch (item) {
        DetailedMagazineModel i => i.isUserSubscribed,
        DetailedUserModel i => i.isFollowedByUser,
        DomainModel i => i.isUserSubscribed,
        _ => throw 'Unreachable',
      };
      final subscriptions = switch (item) {
        DetailedMagazineModel i => i.subscriptionsCount,
        DetailedUserModel i => i.followersCount ?? 0,
        DomainModel i => i.subscriptionsCount,
        _ => throw 'Unreachable',
      };
      final onSubscribe = switch (item) {
        DetailedMagazineModel i => (selected) async {
          var newValue = await context
              .read<AppController>()
              .api
              .magazines
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
        _ => throw 'Unreachable',
      };
      final onClick = switch (item) {
        DetailedMagazineModel i => () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return MagazineScreen(i.id, initData: i, onUpdate: onUpdate);
            },
          ),
        ),
        DetailedUserModel i => () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return UserScreen(i.id, initData: i, onUpdate: onUpdate);
            },
          ),
        ),
        DomainModel i => () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return DomainScreen(i.id, initData: i, onUpdate: onUpdate);
            },
          ),
        ),
        _ => throw 'Unreachable',
      };

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SubscriptionButton(
              isSubscribed: isSubscribed,
              subscriptionCount: subscriptions,
              onSubscribe: onSubscribe,
              followMode: item is DetailedUserModel,
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return PostPage(initData: item, onUpdate: onUpdate);
              },
            ),
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
          onClick: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return PostCommentScreen(item.postType, item.id);
              },
            ),
          ),
        ),
      ),
      _ => throw Exception('Unrecognized search item'),
    };
  }
}
