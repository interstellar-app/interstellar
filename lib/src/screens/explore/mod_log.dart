import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/modlog.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/content_item/content_info.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import '../../api/moderation.dart';

@RoutePage()
class ModLogScreen extends StatefulWidget {
  const ModLogScreen({super.key, this.communityId, this.userId});

  final int? communityId;
  final int? userId;

  @override
  State<ModLogScreen> createState() => _ModLogScreenState();
}

class _ModLogScreenState extends State<ModLogScreen> {
  late final _pagingController = AdvancedPagingController<String, ModlogItemModel, int>(
    logger: context.read<AppController>().logger,
    firstPageKey: '',
    getItemId: (item) => item.hashCode,
    fetchPage: (pageKey) async {
      final ac = context.read<AppController>();

      final newPage = await ac.api.moderation.modLog(
        communityId: widget.communityId,
        userId: widget.userId,
        type: _filter,
        page: pageKey,
      );

      final newItems = switch (ac.serverSoftware) {
        ServerSoftware.mbin => newPage.items,
        ServerSoftware.lemmy =>
          _filter != ModLogType.all
              ? newPage.items.where((item) => item.type == _filter).toList()
              : newPage.items,
        // Lemmy API returns both positive and negative mod action types for each filter type.
        // e.g. passing PinnedPost to the API returns both pinned and unpinned actions.
        // So we do a little extra filtering here to narrow it down further.
        ServerSoftware.piefed => throw UnimplementedError(),
      };

      return (newItems, newPage.nextPage);
    },
  );
  ModLogType _filter = ModLogType.all;

  Function()? _itemOnTap(ModlogItemModel item) => switch (item.type) {
    ModLogType.all => null,
    ModLogType.postDeleted =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.postRestored =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.commentDeleted =>
      item.comment == null
          ? null
          : () => context.router.push(
              PostCommentRoute(
                postType: PostType.thread,
                commentId: item.comment!.id,
              ),
            ),
    ModLogType.commentRestored =>
      item.comment == null
          ? null
          : () => context.router.push(
              PostCommentRoute(
                postType: PostType.thread,
                commentId: item.comment!.id,
              ),
            ),
    ModLogType.postPinned =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.postUnpinned =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.microblogPostDeleted =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.microblog, postId: item.postId),
            ),
    ModLogType.microblogPostRestored =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.microblog, postId: item.postId),
            ),
    ModLogType.microblogCommentDeleted =>
      item.comment == null
          ? null
          : () => context.router.push(
              PostCommentRoute(
                postType: PostType.microblog,
                commentId: item.comment!.id,
              ),
            ),
    ModLogType.microblogCommentRestored =>
      item.comment == null
          ? null
          : () => context.router.push(
              PostCommentRoute(
                postType: PostType.microblog,
                commentId: item.comment!.id,
              ),
            ),
    ModLogType.ban =>
      item.user == null
          ? null
          : () => context.router.push(UserRoute(userId: item.user!.id)),
    ModLogType.unban =>
      item.user == null
          ? null
          : () => context.router.push(UserRoute(userId: item.user!.id)),
    ModLogType.moderatorAdded =>
      item.user == null
          ? null
          : () => context.router.push(UserRoute(userId: item.user!.id)),
    ModLogType.moderatorRemoved =>
      item.user == null
          ? null
          : () => context.router.push(UserRoute(userId: item.user!.id)),
    ModLogType.communityAdded => () => context.router.push(
      CommunityRoute(communityId: item.community.id),
    ),
    ModLogType.communityRemoved => () => context.router.push(
      CommunityRoute(communityId: item.community.id),
    ),
    ModLogType.postLocked =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.postUnlocked =>
      item.postId == null
          ? null
          : () => context.router.push(
              PostRoute(postType: PostType.thread, postId: item.postId),
            ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).modlog),
        actions: [
          IconButton(
            onPressed: () async {
              final filter = await modlogFilterType(
                context,
              ).askSelection(context, _filter);
              if (filter == null) return;
              setState(() {
                _filter = filter;
              });
              _pagingController.refresh();
            },
            icon: const Icon(Symbols.filter_alt_rounded),
          ),
        ],
      ),
      body: AdvancedPagedScrollView(
        controller: _pagingController,
        itemBuilder: (context, item, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _itemOnTap(item),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: switch (item.type) {
                              ModLogType.all => Colors.white,
                              ModLogType.postDeleted => Colors.red,
                              ModLogType.postRestored => Colors.green,
                              ModLogType.commentDeleted => Colors.red,
                              ModLogType.commentRestored => Colors.green,
                              ModLogType.postPinned => Colors.orange,
                              ModLogType.postUnpinned => Colors.orange,
                              ModLogType.microblogPostDeleted => Colors.red,
                              ModLogType.microblogPostRestored => Colors.green,
                              ModLogType.microblogCommentDeleted => Colors.red,
                              ModLogType.microblogCommentRestored =>
                                Colors.green,
                              ModLogType.ban => Colors.red,
                              ModLogType.unban => Colors.green,
                              ModLogType.moderatorAdded => Colors.orange,
                              ModLogType.moderatorRemoved => Colors.orange,
                              ModLogType.communityAdded => Colors.green,
                              ModLogType.communityRemoved => Colors.red,
                              ModLogType.postLocked => Colors.orange,
                              ModLogType.postUnlocked => Colors.orange,
                            },
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(switch (item.type) {
                            ModLogType.all => '',
                            ModLogType.postDeleted => l(
                              context,
                            ).modlog_deletedPost,
                            ModLogType.postRestored => l(
                              context,
                            ).modlog_restoredPost,
                            ModLogType.commentDeleted => l(
                              context,
                            ).modlog_deletedComment,
                            ModLogType.commentRestored => l(
                              context,
                            ).modlog_restoredComment,
                            ModLogType.postPinned => l(
                              context,
                            ).modlog_pinnedPost,
                            ModLogType.postUnpinned => l(
                              context,
                            ).modlog_unpinnedPost,
                            ModLogType.microblogPostDeleted => l(
                              context,
                            ).modlog_deletedPost,
                            ModLogType.microblogPostRestored => l(
                              context,
                            ).modlog_restoredPost,
                            ModLogType.microblogCommentDeleted => l(
                              context,
                            ).modlog_deletedComment,
                            ModLogType.microblogCommentRestored => l(
                              context,
                            ).modlog_restoredComment,
                            ModLogType.ban => l(context).modlog_bannedUser,
                            ModLogType.unban => l(context).modlog_unbannedUser,
                            ModLogType.moderatorAdded => l(
                              context,
                            ).modlog_addModerator,
                            ModLogType.moderatorRemoved => l(
                              context,
                            ).modlog_removedModerator,
                            ModLogType.communityAdded => l(
                              context,
                            ).modlog_communityAdded,
                            ModLogType.communityRemoved => l(
                              context,
                            ).modlog_communityRemoved,
                            ModLogType.postLocked => l(
                              context,
                            ).modlog_postLocked,
                            ModLogType.postUnlocked => l(
                              context,
                            ).modlog_postUnlocked,
                          }),
                        ),
                      ),
                      ContentInfo(
                        user: item.moderator,
                        community: item.community,
                        createdAt: item.createdAt,
                      ),
                      if (item.postId != null || item.comment != null)
                        Text(
                          'Content: ${item.postId != null ? item.postTitle ?? l(context).modlog_deletedPost : item.comment?.body ?? l(context).modlog_deletedComment}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (item.user != null)
                        UserItemSimple(
                          UserModel.fromDetailedUser(item.user!),
                          noTap: true,
                        ),
                      if (item.reason != null && item.reason!.isNotEmpty)
                        Text(
                          l(context).modlog_reason(item.reason!),
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(thickness: 0, height: 0),
            ],
          );
        },
      ),
    );
  }
}

SelectionMenu<ModLogType> modlogFilterType(BuildContext context) {
  final software = context.read<AppController>().serverSoftware;
  return SelectionMenu(l(context).modlog, [
    SelectionMenuItem(value: ModLogType.all, title: l(context).modlog_all),
    SelectionMenuItem(
      value: ModLogType.postDeleted,
      title: l(context).modlog_deletedPost,
    ),
    if (software == ServerSoftware.mbin)
      SelectionMenuItem(
        value: ModLogType.postRestored,
        title: l(context).modlog_restoredPost,
      ),
    SelectionMenuItem(
      value: ModLogType.commentDeleted,
      title: l(context).modlog_deletedComment,
    ),
    if (software == ServerSoftware.mbin)
      SelectionMenuItem(
        value: ModLogType.commentRestored,
        title: l(context).modlog_restoredComment,
      ),
    SelectionMenuItem(
      value: ModLogType.postPinned,
      title: l(context).modlog_pinnedPost,
    ),
    SelectionMenuItem(
      value: ModLogType.postUnpinned,
      title: l(context).modlog_unpinnedPost,
    ),
    SelectionMenuItem(
      value: ModLogType.ban,
      title: l(context).modlog_bannedUser,
    ),
    SelectionMenuItem(
      value: ModLogType.unban,
      title: l(context).modlog_unbannedUser,
    ),
    SelectionMenuItem(
      value: ModLogType.moderatorAdded,
      title: l(context).modlog_addModerator,
    ),
    SelectionMenuItem(
      value: ModLogType.moderatorRemoved,
      title: l(context).modlog_removedModerator,
    ),
    if (software != ServerSoftware.mbin) ...[
      SelectionMenuItem(
        value: ModLogType.communityAdded,
        title: l(context).modlog_communityAdded,
      ),
      SelectionMenuItem(
        value: ModLogType.communityRemoved,
        title: l(context).modlog_communityRemoved,
      ),
      SelectionMenuItem(
        value: ModLogType.postLocked,
        title: l(context).modlog_postLocked,
      ),
      SelectionMenuItem(
        value: ModLogType.postUnlocked,
        title: l(context).modlog_postUnlocked,
      ),
    ],
  ]);
}
