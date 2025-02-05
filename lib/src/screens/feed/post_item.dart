import 'package:flutter/material.dart';
import 'package:interstellar/src/api/bookmark.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/ban_dialog.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:provider/provider.dart';

class PostItem extends StatelessWidget {
  const PostItem(
    this.item,
    this.onUpdate, {
    super.key,
    this.isPreview = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.filterListWarnings,
  });

  final PostModel item;
  final void Function(PostModel) onUpdate;
  final Future<void> Function(String)? onReply;
  final Future<void> Function(String)? onEdit;
  final Future<void> Function()? onDelete;
  final bool isPreview;
  final Set<String>? filterListWarnings;

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final canModerate = item.canAuthUserModerate ?? false;

    return ContentItem(
      originInstance: getNameHost(context, item.user.name),
      title: item.title,
      image: item.image,
      link: item.url != null ? Uri.parse(item.url!) : null,
      body: item.body,
      createdAt: item.createdAt,
      editedAt: item.editedAt,
      isPreview: item.type == PostType.microblog ? false : isPreview,
      fullImageSize: isPreview
          ? switch (item.type) {
              PostType.thread => ac.profile.fullImageSizeThreads,
              PostType.microblog => ac.profile.fullImageSizeMicroblogs,
            }
          : true,
      showMagazineFirst: item.type == PostType.thread,
      isPinned: item.isPinned,
      isNSFW: item.isNSFW,
      isOC: item.isOC == true,
      user: item.user.name,
      userIcon: item.user.avatar,
      userIdOnClick: item.user.id,
      userCakeDay: item.user.createdAt,
      userIsBot: item.user.isBot,
      magazine: item.magazine.name,
      magazineIcon: item.magazine.icon,
      magazineIdOnClick: item.magazine.id,
      domain: item.domain?.name,
      domainIdOnClick: item.domain?.id,
      boosts: item.boosts,
      isBoosted: item.myBoost == true,
      onBoost: whenLoggedIn(context, () async {
        onUpdate(await switch (item.type) {
          PostType.thread => ac.api.threads.boost(item.id),
          PostType.microblog => ac.api.microblogs.putVote(item.id, 1),
        });
      }),
      upVotes: item.upvotes,
      isUpVoted: item.myVote == 1,
      onUpVote: whenLoggedIn(context, () async {
        onUpdate(await switch (item.type) {
          PostType.thread =>
            ac.api.threads.vote(item.id, 1, item.myVote == 1 ? 0 : 1),
          PostType.microblog => ac.api.microblogs.putFavorite(item.id),
        });
      }),
      downVotes: item.downvotes,
      isDownVoted: item.myVote == -1,
      onDownVote: whenLoggedIn(context, () async {
        onUpdate(await switch (item.type) {
          PostType.thread =>
            ac.api.threads.vote(item.id, -1, item.myVote == -1 ? 0 : -1),
          PostType.microblog => ac.api.microblogs.putVote(item.id, -1),
        });
      }),
      contentTypeName: l(context).post,
      onReply: onReply,
      onReport: whenLoggedIn(context, (reason) async {
        await switch (item.type) {
          PostType.thread => ac.api.threads.report(item.id, reason),
          PostType.microblog => ac.api.microblogs.report(item.id, reason),
        };
      }),
      onEdit: onEdit,
      onDelete: onDelete,
      onModeratePin: !canModerate
          ? null
          : () async {
              onUpdate(await ac.api.moderation.postPin(item.type, item.id));
            },
      onModerateMarkNSFW: !canModerate
          ? null
          : () async {
              onUpdate(await ac.api.moderation
                  .postMarkNSFW(item.type, item.id, !item.isNSFW));
            },
      onModerateDelete: !canModerate
          ? null
          : () async {
              onUpdate(
                  await ac.api.moderation.postDelete(item.type, item.id, true));
            },
      onModerateBan: !canModerate
          ? null
          : () async {
              await openBanDialog(context,
                  user: item.user, magazine: item.magazine);
            },
      numComments: item.numComments,
      openLinkUri: Uri.https(
        ac.instanceHost,
        ac.serverSoftware == ServerSoftware.lemmy
            ? '/post/${item.id}'
            : '/m/${item.magazine.name}/${switch (item.type) {
                PostType.thread => 't',
                PostType.microblog => 'p',
              }}/${item.id}',
      ),
      editDraftResourceId:
          'edit:${item.type.name}:${ac.instanceHost}:${item.id}',
      replyDraftResourceId:
          'reply:${item.type.name}:${ac.instanceHost}:${item.id}',
      filterListWarnings: filterListWarnings,
      activeBookmarkLists: item.bookmarks,
      loadPossibleBookmarkLists: () async =>
          (await ac.api.bookmark.getBookmarkLists())
              .map((list) => list.name)
              .toList(),
      onAddBookmark: () async {
        final newBookmarks = await ac.api.bookmark.addBookmarkToDefault(
          subjectType: BookmarkListSubject.fromPostType(
              postType: item.type, isComment: false),
          subjectId: item.id,
        );
        onUpdate(item.copyWith(bookmarks: newBookmarks));
      },
      onAddBookmarkToList: (String listName) async {
        final newBookmarks = await ac.api.bookmark.addBookmarkToList(
          subjectType: BookmarkListSubject.fromPostType(
              postType: item.type, isComment: false),
          subjectId: item.id,
          listName: listName,
        );
        onUpdate(item.copyWith(bookmarks: newBookmarks));
      },
      onRemoveBookmark: () async {
        final newBookmarks = await ac.api.bookmark.removeBookmarkFromAll(
          subjectType: BookmarkListSubject.fromPostType(
              postType: item.type, isComment: false),
          subjectId: item.id,
        );
        onUpdate(item.copyWith(bookmarks: newBookmarks));
      },
      onRemoveBookmarkFromList: (String listName) async {
        final newBookmarks = await ac.api.bookmark.removeBookmarkFromList(
          subjectType: BookmarkListSubject.fromPostType(
              postType: item.type, isComment: false),
          subjectId: item.id,
          listName: listName,
        );
        onUpdate(item.copyWith(bookmarks: newBookmarks));
      },
    );
  }
}
