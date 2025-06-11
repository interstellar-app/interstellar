import 'package:flutter/material.dart';
import 'package:interstellar/src/api/bookmark.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/ban_dialog.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:provider/provider.dart';
import 'package:simplytranslate/simplytranslate.dart';
import 'package:interstellar/src/widgets/super_hero.dart';

class PostItem extends StatefulWidget {
  const PostItem(
    this.item,
    this.onUpdate, {
    super.key,
    this.isPreview = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.filterListWarnings,
    this.userCanModerate = false,
    this.isTopLevel = false,
    this.isCompact = false,
  });

  final PostModel item;
  final void Function(PostModel) onUpdate;
  final Future<void> Function(String body, String lang)? onReply;
  final Future<void> Function(String)? onEdit;
  final Future<void> Function()? onDelete;
  final void Function()? onTap;
  final bool isPreview;
  final Set<String>? filterListWarnings;
  final bool userCanModerate;
  final bool isTopLevel;
  final bool isCompact;

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  Translation? _translation;

  @override
  void initState() {
    super.initState();
    if (context.read<AppController>().profile.autoTranslate &&
        widget.item.lang !=
            context.read<AppController>().profile.defaultCreateLanguage &&
        widget.item.body != null &&
        widget.item.lang != null) {
      getTranslation(
        context.read<AppController>().profile.defaultCreateLanguage,
      );
    }
  }

  Future<void> getTranslation(String lang) async {
    try {
      final translation = await context
          .read<AppController>()
          .translator
          .translateSimply(widget.item.body!, to: lang);
      if (!mounted) return;
      setState(() {
        _translation = translation;
      });
    } catch (e) {
      // ignore translation errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final canModerate =
        widget.userCanModerate || (widget.item.canAuthUserModerate ?? false);

    return SuperHero(
      tag: widget.item.toString(),
      child: Material(
        color: Colors.transparent,
        child: ContentItem(
          originInstance: getNameHost(context, widget.item.user.name),
          title: widget.item.title,
          image: widget.item.image,
          link: widget.item.url != null ? Uri.parse(widget.item.url!) : null,
          body: widget.item.body,
          translation: _translation,
          lang: widget.item.lang,
          onTranslate: (String lang) async {
            await getTranslation(lang);
          },
          createdAt: widget.item.createdAt,
          editedAt: widget.item.editedAt,
          isPreview: widget.item.type == PostType.microblog
              ? false
              : widget.isPreview,
          fullImageSize: widget.isPreview
              ? switch (widget.item.type) {
                  PostType.thread => ac.profile.fullImageSizeThreads,
                  PostType.microblog => ac.profile.fullImageSizeMicroblogs,
                }
              : true,
          showCommunityFirst: widget.item.type == PostType.thread,
          read: widget.isTopLevel && widget.item.read,
          isPinned: widget.item.isPinned,
          isNSFW: widget.item.isNSFW,
          isOC: widget.item.isOC == true,
          user: widget.item.user.name,
          userIcon: widget.item.user.avatar,
          userIdOnClick: widget.item.user.id,
          userCakeDay: widget.item.user.createdAt,
          userIsBot: widget.item.user.isBot,
          community: widget.item.community.name,
          communityIcon: widget.item.community.icon,
          communityIdOnClick: widget.item.community.id,
          domain: widget.item.domain?.name,
          domainIdOnClick: widget.item.domain?.id,
          boosts: widget.item.boosts,
          isBoosted: widget.item.myBoost == true,
          onBoost: whenLoggedIn(context, () async {
            widget.onUpdate(
              (await ac.markAsRead([
                await switch (widget.item.type) {
                  PostType.thread => ac.api.threads.boost(widget.item.id),
                  PostType.microblog => ac.api.microblogs.putVote(
                    widget.item.id,
                    1,
                  ),
                },
              ], true)).first,
            );
          }),
          upVotes: widget.item.upvotes,
          isUpVoted: widget.item.myVote == 1,
          onUpVote: whenLoggedIn(context, () async {
            widget.onUpdate(
              (await ac.markAsRead([
                await switch (widget.item.type) {
                  PostType.thread => ac.api.threads.vote(
                    widget.item.id,
                    1,
                    widget.item.myVote == 1 ? 0 : 1,
                  ),
                  PostType.microblog => ac.api.microblogs.putFavorite(
                    widget.item.id,
                  ),
                },
              ], true)).first,
            );
          }),
          downVotes: widget.item.downvotes,
          isDownVoted: widget.item.myVote == -1,
          onDownVote: whenLoggedIn(context, () async {
            widget.onUpdate(
              (await ac.markAsRead([
                await switch (widget.item.type) {
                  PostType.thread => ac.api.threads.vote(
                    widget.item.id,
                    -1,
                    widget.item.myVote == -1 ? 0 : -1,
                  ),
                  PostType.microblog => ac.api.microblogs.putVote(
                    widget.item.id,
                    -1,
                  ),
                },
              ], true)).first,
            );
          }),
          contentTypeName: l(context).post,
          onReply: widget.onReply,
          onReport: whenLoggedIn(context, (reason) async {
            await switch (widget.item.type) {
              PostType.thread => ac.api.threads.report(widget.item.id, reason),
              PostType.microblog => ac.api.microblogs.report(
                widget.item.id,
                reason,
              ),
            };
          }),
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
          onMarkAsRead: () async {
            widget.onUpdate(
              (await ac.markAsRead([widget.item], !widget.item.read)).first,
            );
          },
          onModeratePin: !canModerate
              ? null
              : () async {
                  widget.onUpdate(
                    await ac.api.moderation.postPin(
                      widget.item.type,
                      widget.item.id,
                    ),
                  );
                },
          onModerateMarkNSFW: !canModerate
              ? null
              : () async {
                  widget.onUpdate(
                    await ac.api.moderation.postMarkNSFW(
                      widget.item.type,
                      widget.item.id,
                      !widget.item.isNSFW,
                    ),
                  );
                },
          onModerateDelete: !canModerate
              ? null
              : () async {
                  widget.onUpdate(
                    await ac.api.moderation.postDelete(
                      widget.item.type,
                      widget.item.id,
                      true,
                    ),
                  );
                },
          onModerateBan: !canModerate
              ? null
              : () async {
                  await openBanDialog(
                    context,
                    user: widget.item.user,
                    community: widget.item.community,
                  );
                },
          numComments: widget.item.numComments,
          openLinkUri: Uri.https(
            ac.instanceHost,
            ac.serverSoftware == ServerSoftware.mbin
                ? '/m/${widget.item.community.name}/${switch (widget.item.type) {
                    PostType.thread => 't',
                    PostType.microblog => 'p',
                  }}/${widget.item.id}'
                : '/post/${widget.item.id}',
          ),
          editDraftResourceId:
              'edit:${widget.item.type.name}:${ac.instanceHost}:${widget.item.id}',
          replyDraftResourceId:
              'reply:${widget.item.type.name}:${ac.instanceHost}:${widget.item.id}',
          filterListWarnings: widget.filterListWarnings,
          activeBookmarkLists: widget.item.bookmarks,
          loadPossibleBookmarkLists: whenLoggedIn(
            context,
            () async => (await ac.api.bookmark.getBookmarkLists())
                .map((list) => list.name)
                .toList(),
            matchesSoftware: ServerSoftware.mbin,
          ),
          onAddBookmark: whenLoggedIn(context, () async {
            final newBookmarks = await ac.api.bookmark.addBookmarkToDefault(
              subjectType: BookmarkListSubject.fromPostType(
                postType: widget.item.type,
                isComment: false,
              ),
              subjectId: widget.item.id,
            );
            widget.onUpdate(widget.item.copyWith(bookmarks: newBookmarks));
          }),
          onAddBookmarkToList: whenLoggedIn(context, (String listName) async {
            final newBookmarks = await ac.api.bookmark.addBookmarkToList(
              subjectType: BookmarkListSubject.fromPostType(
                postType: widget.item.type,
                isComment: false,
              ),
              subjectId: widget.item.id,
              listName: listName,
            );
            widget.onUpdate(widget.item.copyWith(bookmarks: newBookmarks));
          }, matchesSoftware: ServerSoftware.mbin),
          onRemoveBookmark: whenLoggedIn(context, () async {
            final newBookmarks = await ac.api.bookmark.removeBookmarkFromAll(
              subjectType: BookmarkListSubject.fromPostType(
                postType: widget.item.type,
                isComment: false,
              ),
              subjectId: widget.item.id,
            );
            widget.onUpdate(widget.item.copyWith(bookmarks: newBookmarks));
          }),
          onRemoveBookmarkFromList: whenLoggedIn(context, (
            String listName,
          ) async {
            final newBookmarks = await ac.api.bookmark.removeBookmarkFromList(
              subjectType: BookmarkListSubject.fromPostType(
                postType: widget.item.type,
                isComment: false,
              ),
              subjectId: widget.item.id,
              listName: listName,
            );
            widget.onUpdate(widget.item.copyWith(bookmarks: newBookmarks));
          }, matchesSoftware: ServerSoftware.mbin),
          notificationControlStatus: widget.item.notificationControlStatus,
          onNotificationControlStatusChange:
              widget.item.notificationControlStatus == null
              ? null
              : (newStatus) async {
                  await ac.api.notifications.updateControl(
                    targetType: switch (widget.item.type) {
                      PostType.thread =>
                        NotificationControlUpdateTargetType.entry,
                      PostType.microblog =>
                        NotificationControlUpdateTargetType.post,
                    },
                    targetId: widget.item.id,
                    status: newStatus,
                  );

                  widget.onUpdate(
                    widget.item.copyWith(notificationControlStatus: newStatus),
                  );
                },
          isCompact: widget.isCompact,
          onClick: widget.isTopLevel ? widget.onTap : null,
        ),
      ),
    );
  }
}
