import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/modlog.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/content_item/content_info.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import '../../api/moderation.dart';

class ModLog extends StatefulWidget {
  const ModLog({super.key, this.communityId, this.userId});

  final int? communityId;
  final int? userId;

  @override
  State<ModLog> createState() => _ModLogState();
}

class _ModLogState extends State<ModLog> {
  late final _pagingController =
      AdvancedPagingController<String, ModlogItemModel, int>(
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

          return (newPage.items, newPage.nextPage);
        },
      );
  ModLogType _filter = ModLogType.all;

  Function()? _itemOnTap(ModlogItemModel item) => switch (item.type) {
    ModLogType.all => null,
    ModLogType.postDeleted =>
      item.postId == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostPage(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.postRestored =>
      item.postId == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostPage(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.commentDeleted =>
      item.comment == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostCommentScreen(PostType.thread, item.comment!.id),
            ),
    ModLogType.commentRestored =>
      item.comment == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostCommentScreen(PostType.thread, item.comment!.id),
            ),
    ModLogType.postPinned =>
      item.postId == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostPage(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.postUnpinned =>
      item.postId == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostPage(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.post_deleted =>
      item.postId == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostPage(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.post_restored =>
      item.postId == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostPage(postType: PostType.thread, postId: item.postId),
            ),
    ModLogType.post_comment_deleted =>
      item.comment == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostCommentScreen(PostType.thread, item.comment!.id),
            ),
    ModLogType.post_comment_restored =>
      item.comment == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) =>
                  PostCommentScreen(PostType.thread, item.comment!.id),
            ),
    ModLogType.ban =>
      item.ban == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) => UserScreen(item.ban!.bannedUser.id),
            ),
    ModLogType.unban =>
      item.ban == null
          ? null
          : () => pushRoute(
              context,
              builder: (context) => UserScreen(item.ban!.bannedUser.id),
            ),
    ModLogType.moderatorAdded => null,
    ModLogType.moderatorRemoved => null,
    ModLogType.communityAdded => null,
    ModLogType.communityRemoved => null,
    ModLogType.postLocked => null,
    ModLogType.postUnlocked => null,
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
            icon: const Icon(Symbols.sort_rounded),
          ),
        ],
      ),
      body: AdvancedPagedScrollView(
        controller: _pagingController,
        itemBuilder: (context, item, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: InkWell(
              onTap: _itemOnTap(item),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        // mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
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
                                ModLogType.post_deleted => Colors.red,
                                ModLogType.post_restored => Colors.green,
                                ModLogType.post_comment_deleted => Colors.red,
                                ModLogType.post_comment_restored =>
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
                              ModLogType.post_deleted => l(
                                context,
                              ).modlog_deletedPost,
                              ModLogType.post_restored => l(
                                context,
                              ).modlog_restoredPost,
                              ModLogType.post_comment_deleted => l(
                                context,
                              ).modlog_deletedComment,
                              ModLogType.post_comment_restored => l(
                                context,
                              ).modlog_restoredComment,
                              ModLogType.ban => l(context).modlog_bannedUser,
                              ModLogType.unban => l(
                                context,
                              ).modlog_unbannedUser,
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
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: ContentInfo(
                              user: item.moderator,
                              community: item.community,
                              createdAt: item.createdAt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.postId != null &&
                        item.postTitle != null &&
                        item.comment == null)
                      Text(
                        item.postTitle!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (item.comment != null)
                      Text(
                        item.comment!.body ?? l(context).modlog_deletedComment,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    // PostComment(item.comment!, (post) {}),
                    if (item.ban != null)
                      UserItemSimple(item.ban!.bannedUser, noTap: true),
                    if (item.reason != null && item.reason!.isNotEmpty)
                      Text(l(context).modlog_reason(item.reason!)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

SelectionMenu<ModLogType> modlogFilterType(BuildContext context) {
  final software = context.read<AppController>().serverSoftware;
  return SelectionMenu(l(context).sortComments, [
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
    if (software == ServerSoftware.mbin) ...[
      SelectionMenuItem(
        value: ModLogType.post_deleted,
        title: l(context).modlog_deletedPost,
      ),
      SelectionMenuItem(
        value: ModLogType.post_restored,
        title: l(context).modlog_restoredPost,
      ),
      SelectionMenuItem(
        value: ModLogType.post_comment_deleted,
        title: l(context).modlog_deletedComment,
      ),
      SelectionMenuItem(
        value: ModLogType.post_comment_restored,
        title: l(context).modlog_restoredComment,
      ),
    ],
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
