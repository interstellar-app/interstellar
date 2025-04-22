import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/bookmark.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/ban_dialog.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:interstellar/src/widgets/content_item/content_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';

class PostComment extends StatefulWidget {
  const PostComment(
    this.comment,
    this.onUpdate, {
    this.opUserId,
    this.onClick,
    this.userCanModerate = false,
    this.level = 0,
    super.key,
  });

  final CommentModel comment;
  final void Function(CommentModel) onUpdate;
  final int? opUserId;
  final void Function()? onClick;
  final bool userCanModerate;
  final int level;

  @override
  State<PostComment> createState() => _PostCommentState();
}

class _PostCommentState extends State<PostComment> {
  final ExpandableController _expandableController =
      ExpandableController(initialExpanded: true);

  void collapse() {
    setState(() {
      _expandableController.toggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final canModerate =
        widget.userCanModerate || (widget.comment.canAuthUserModerate ?? false);

    final Widget userWidget = Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: DisplayName(
                widget.comment.user.name,
                icon: widget.comment.user.avatar,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserScreen(
                      widget.comment.user.id,
                    ),
                  ),
                )
              ),
            ),
            UserStatusIcons(
              cakeDay: widget.comment.user.createdAt,
              isBot: widget.comment.user.isBot,
            ),
            if (widget.opUserId == widget.comment.user.id)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Tooltip(
                  message: l(context).originalPoster_long,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Text(
                    l(context).originalPoster_short,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final contentItem = ContentItem(
      originInstance: getNameHost(context, widget.comment.user.name),
      image: widget.comment.image,
      body: widget.comment.body ?? '_${l(context).commentDeleted}_',
      lang: widget.comment.lang,
      createdAt: widget.comment.createdAt,
      editedAt: widget.comment.editedAt,
      user: widget.comment.user.name,
      userIcon: widget.comment.user.avatar,
      userIdOnClick: widget.comment.user.id,
      userCakeDay: widget.comment.user.createdAt,
      userIsBot: widget.comment.user.isBot,
      opUserId: widget.opUserId,
      boosts: widget.comment.boosts,
      isBoosted: widget.comment.myBoost == true,
      onBoost: whenLoggedIn(context, () async {
        var newValue = await ac.api.comments
            .boost(widget.comment.postType, widget.comment.id);
        widget.onUpdate(newValue.copyWith(
          childCount: widget.comment.childCount,
          children: widget.comment.children,
        ));
      }),
      upVotes: widget.comment.upvotes,
      onUpVote: whenLoggedIn(context, () async {
        var newValue = await ac.api.comments.vote(
            widget.comment.postType,
            widget.comment.id,
            1,
            widget.comment.myVote == 1 ? 0 : 1);
        widget.onUpdate(newValue.copyWith(
          childCount: widget.comment.childCount,
          children: widget.comment.children,
        ));
      }),
      isUpVoted: widget.comment.myVote == 1,
      downVotes: widget.comment.downvotes,
      isDownVoted: widget.comment.myVote == -1,
      onDownVote: whenLoggedIn(context, () async {
        var newValue = await ac.api.comments.vote(
            widget.comment.postType,
            widget.comment.id,
            -1,
            widget.comment.myVote == -1 ? 0 : -1);
        widget.onUpdate(newValue.copyWith(
          childCount: widget.comment.childCount,
          children: widget.comment.children,
        ));
      }),
      contentTypeName: l(context).comment,
      onReply: whenLoggedIn(context, (body) async {
        var newSubComment = await ac.api.comments.create(
          widget.comment.postType,
          widget.comment.postId,
          body,
          parentCommentId: widget.comment.id,
        );

        widget.onUpdate(widget.comment.copyWith(
          childCount: widget.comment.childCount + 1,
          children: [newSubComment, ...widget.comment.children!],
        ));
      }),
      onReport: whenLoggedIn(context, (reason) async {
        await ac.api.comments
            .report(widget.comment.postType, widget.comment.id, reason);
      }),
      onEdit: widget.comment.visibility != 'soft_deleted'
          ? whenLoggedIn(context, (body) async {
              var newValue = await ac.api.comments.edit(
                widget.comment.postType,
                widget.comment.id,
                body,
              );

              widget.onUpdate(newValue.copyWith(
                childCount: widget.comment.childCount,
                children: widget.comment.children,
              ));
            }, matchesUsername: widget.comment.user.name)
          : null,
      onDelete: widget.comment.visibility != 'soft_deleted'
          ? whenLoggedIn(context, () async {
              await ac.api.comments
                  .delete(widget.comment.postType, widget.comment.id);

              if (!mounted) return;

              widget.onUpdate(widget.comment.copyWith(
                body: '_${l(context).commentDeleted}_',
                upvotes: null,
                downvotes: null,
                boosts: null,
                visibility: 'soft_deleted',
              ));
            }, matchesUsername: widget.comment.user.name)
          : null,
      onModerateDelete: !canModerate
          ? null
          : () async {
              final newValue = await ac.api.moderation.commentDelete(
                widget.comment.postType,
                widget.comment.id,
                true,
              );

              widget.onUpdate(newValue.copyWith(
                childCount: widget.comment.childCount,
                children: widget.comment.children,
              ));
            },
      onModerateBan: !canModerate
          ? null
          : () async {
              await openBanDialog(context,
                  user: widget.comment.user,
                  magazine: widget.comment.magazine);
            },
      openLinkUri: Uri.https(
        ac.instanceHost,
        ac.serverSoftware == ServerSoftware.mbin
            ? '/m/${widget.comment.magazine.name}/${switch (widget.comment.postType) {
                PostType.thread => 't',
                PostType.microblog => 'p',
              }}/${widget.comment.postId}/-/${switch (widget.comment.postType) {
                PostType.thread => 'comment',
                PostType.microblog => 'reply',
              }}/${widget.comment.id}'
            : '/comment/${widget.comment.id}',
      ),
      editDraftResourceId:
          'edit:${widget.comment.postType.name}:comment:${context.watch<AppController>().instanceHost}:${widget.comment.id}',
      replyDraftResourceId:
          'reply:${widget.comment.postType.name}:comment:${context.watch<AppController>().instanceHost}:${widget.comment.id}',
      activeBookmarkLists: widget.comment.bookmarks,
      loadPossibleBookmarkLists: whenLoggedIn(
        context,
        () async => (await ac.api.bookmark.getBookmarkLists())
            .map((list) => list.name)
            .toList(),
        matchesSoftware: ServerSoftware.mbin,
      ),
      onAddBookmark: whenLoggedIn(context, (() async {
        final newBookmarks = await ac.api.bookmark.addBookmarkToDefault(
          subjectType: BookmarkListSubject.fromPostType(
              postType: widget.comment.postType, isComment: true),
          subjectId: widget.comment.id,
        );
        widget
            .onUpdate(widget.comment.copyWith(bookmarks: newBookmarks));
      })),
      onAddBookmarkToList: whenLoggedIn(
        context,
        (String listName) async {
          final newBookmarks = await ac.api.bookmark.addBookmarkToList(
            subjectType: BookmarkListSubject.fromPostType(
                postType: widget.comment.postType, isComment: true),
            subjectId: widget.comment.id,
            listName: listName,
          );
          widget.onUpdate(
              widget.comment.copyWith(bookmarks: newBookmarks));
        },
        matchesSoftware: ServerSoftware.mbin,
      ),
      onRemoveBookmark: whenLoggedIn(context, () async {
        final newBookmarks =
            await ac.api.bookmark.removeBookmarkFromAll(
          subjectType: BookmarkListSubject.fromPostType(
              postType: widget.comment.postType, isComment: true),
          subjectId: widget.comment.id,
        );
        widget
            .onUpdate(widget.comment.copyWith(bookmarks: newBookmarks));
      }),
      onRemoveBookmarkFromList: whenLoggedIn(
        context,
        (String listName) async {
          final newBookmarks =
              await ac.api.bookmark.removeBookmarkFromList(
            subjectType: BookmarkListSubject.fromPostType(
                postType: widget.comment.postType, isComment: true),
            subjectId: widget.comment.id,
            listName: listName,
          );
          widget.onUpdate(
              widget.comment.copyWith(bookmarks: newBookmarks));
        },
        matchesSoftware: ServerSoftware.mbin,
      ),
      notificationControlStatus:
          widget.comment.notificationControlStatus,
      onNotificationControlStatusChange:
          widget.comment.notificationControlStatus == null
              ? null
              : (newStatus) async {
                  await ac.api.notifications.updateControl(
                    targetType:
                        NotificationControlUpdateTargetType.comment,
                    targetId: widget.comment.id,
                    status: newStatus,
                  );

                  widget.onUpdate(widget.comment
                      .copyWith(notificationControlStatus: newStatus));
                },
    );

    final menuWidget = IconButton(
      icon: const Icon(Symbols.more_vert_rounded),
      onPressed: () {
        showContentMenu(
            context,
            contentItem,
        );
      },
    );

    return Expandable(
      controller: _expandableController,
      collapsed: Card(
        margin: const EdgeInsets.only(top: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onClick ?? collapse,
          onLongPress: () => showContentMenu(context, contentItem),
          onSecondaryTap: () => showContentMenu(context, contentItem),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      userWidget,
                      Padding(
                        padding:
                        const EdgeInsets.only(right: 10),
                        child: Tooltip(
                          message: l(context).createdAt(
                              dateTimeFormat(
                                  widget.comment.createdAt)) +
                              (widget.comment.editedAt == null
                                  ? ''
                                  : '\n${l(context).editedAt(dateTimeFormat(widget.comment.editedAt!))}'),
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text(
                            dateDiffFormat(widget.comment.createdAt),
                            style: const TextStyle(
                                fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                menuWidget
              ],
            )
          )
        )
      ),
      expanded: Column(
        children: [
          Card(
            margin: const EdgeInsets.only(top: 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onClick ?? collapse,
              onLongPress: () => showContentMenu(context, contentItem),
              onSecondaryTap: () => showContentMenu(context, contentItem),
              child: contentItem,
            ),
          ),
          if (widget.comment.childCount > 0 &&
              _expandableController.expanded &&
              (widget.comment.children?.isEmpty ?? false))
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostCommentScreen(
                    widget.comment.postType,
                    widget.comment.id,
                    opUserId: widget.opUserId,
                  ),
                ),
              ),
              child: Text(l(context).openReplies(widget.comment.childCount)),
            ),
          if (widget.comment.childCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 1),
              padding: const EdgeInsets.only(left: 9),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.primaries[widget.level],//Theme.of(context).colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: widget.comment.children!
                    .asMap()
                    .entries
                    .map((item) => PostComment(
                          item.value,
                          (newValue) {
                            var newChildren = [...widget.comment.children!];
                            newChildren[item.key] = newValue;
                            widget.onUpdate(widget.comment.copyWith(
                              childCount: widget.comment.childCount + 1,
                              children: newChildren,
                            ));
                          },
                          opUserId: widget.opUserId,
                          onClick: widget.onClick,
                          userCanModerate: widget.userCanModerate,
                          level: widget.level + 1,
                        ))
                    .toList(),
              ),
            ),
        ],
      )
    );
  }
}
