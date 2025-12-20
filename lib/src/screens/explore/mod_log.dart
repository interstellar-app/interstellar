import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/modlog.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/content_item/content_info.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:provider/provider.dart';

import '../../api/moderation.dart';

class ModLog extends StatefulWidget {
  const ModLog({super.key, this.communityId});

  final int? communityId;

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
            page: pageKey,
          );

          return (newPage.items, newPage.nextPage);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).modlog)),
      body: AdvancedPagedScrollView(
        controller: _pagingController,
        itemBuilder: (context, item, index) {
          return Card(
            margin: const EdgeInsets.all(8),
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
                              ModLogType.entry_deleted => Colors.red,
                              ModLogType.entry_restored => Colors.green,
                              ModLogType.entry_comment_deleted => Colors.red,
                              ModLogType.entry_comment_restored => Colors.green,
                              ModLogType.entry_pinned => Colors.orange,
                              ModLogType.entry_unpinned => Colors.orange,
                              ModLogType.post_deleted => Colors.red,
                              ModLogType.post_restored => Colors.green,
                              ModLogType.post_comment_deleted => Colors.red,
                              ModLogType.post_comment_restored => Colors.green,
                              ModLogType.ban => Colors.red,
                              ModLogType.unban => Colors.green,
                              ModLogType.moderator_add => Colors.orange,
                              ModLogType.moderator_remove => Colors.orange,
                            },
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(switch (item.type) {
                            ModLogType.all => '',
                            ModLogType.entry_deleted => l(context).modlog_deletedPost,
                            ModLogType.entry_restored => l(context).modlog_restoredPost,
                            ModLogType.entry_comment_deleted => l(context).modlog_deletedComment,
                            ModLogType.entry_comment_restored => l(context).modlog_restoredComment,
                            ModLogType.entry_pinned => l(context).modlog_pinnedPost,
                            ModLogType.entry_unpinned => l(context).modlog_unpinnedPost,
                            ModLogType.post_deleted => l(context).modlog_deletedPost,
                            ModLogType.post_restored => l(context).modlog_restoredPost,
                            ModLogType.post_comment_deleted => l(context).modlog_deletedComment,
                            ModLogType.post_comment_restored => l(context).modlog_restoredComment,
                            ModLogType.ban => l(context).modlog_bannedUser,
                            ModLogType.unban => l(context).modlog_unbannedUser,
                            ModLogType.moderator_add => l(context).modlog_addModerator,
                            ModLogType.moderator_remove => l(context).modlog_removedModerator,
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
                  if (item.post != null && item.comment == null)
                    PostItem(
                      item.post!,
                      (post) {},
                      isCompact: false,
                      isPreview: true,
                      isTopLevel: true,
                      onTap: () => pushRoute(
                        context,
                        builder: (context) => PostPage(
                          postType: item.post!.type,
                          postId: item.post!.id,
                          initData: item.post,
                        ),
                      ),
                    ),
                  if (item.comment != null)
                    PostComment(item.comment!, (post) {}),
                  if (item.ban != null) UserItemSimple(item.ban!.bannedUser),
                  if (item.reason != null && item.reason!.isNotEmpty)
                    Text(l(context).modlog_reason(item.reason!)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
