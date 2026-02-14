import 'package:auto_route/auto_route.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/bookmark.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/utils/ap_urls.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/ban_dialog.dart';
import 'package:interstellar/src/widgets/content_item/content_info.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:interstellar/src/widgets/menus/content_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:simplytranslate/simplytranslate.dart';

class PostComment extends StatefulWidget {
  const PostComment(
    this.comment,
    this.onUpdate, {
    this.opUserId,
    this.onClick,
    this.userCanModerate = false,
    this.level = 0,
    this.showChildren = true,
    this.postLocked = false,
    super.key,
  });

  final CommentModel comment;
  final void Function(CommentModel) onUpdate;
  final int? opUserId;
  final void Function()? onClick;
  final bool userCanModerate;
  final int level;
  final bool showChildren;
  final bool postLocked;

  @override
  State<PostComment> createState() => _PostCommentState();
}

class _PostCommentState extends State<PostComment> {
  final ExpandableController _expandableController = ExpandableController(
    initialExpanded: true,
  );

  Translation? _translation;

  @override
  void initState() {
    super.initState();
    if (context.read<AppController>().profile.autoTranslate &&
        widget.comment.lang !=
            context.read<AppController>().profile.defaultCreateLanguage &&
        widget.comment.body != null &&
        widget.comment.lang != null) {
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
          .translateSimply(widget.comment.body!, to: lang);
      if (!mounted) return;
      setState(() {
        _translation = translation;
      });
    } catch (e) {
      // ignore translation errors
    }
  }

  void collapse() {
    setState(_expandableController.toggle);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final canModerate =
        widget.userCanModerate || (widget.comment.canAuthUserModerate ?? false);

    final contentItem = ContentItem(
      originInstance: getNameHost(context, widget.comment.user.name),
      id: widget.comment.id,
      image: widget.comment.image,
      body: widget.comment.body ?? '_${l(context).commentDeleted}_',
      translation: _translation,
      lang: widget.comment.lang,
      createdAt: widget.comment.createdAt,
      editedAt: widget.comment.editedAt,
      fullImageSize: true,
      isLocked: widget.comment.isLocked,
      user: widget.comment.user,
      updateUser: (user) async =>
          widget.onUpdate(widget.comment.copyWith(user: user)),
      opUserId: widget.opUserId,
      boosts: widget.comment.boosts,
      isBoosted: widget.comment.myBoost ?? false,
      onBoost: whenLoggedIn(context, () async {
        final newValue = await ac.api.comments.boost(
          widget.comment.postType,
          widget.comment.id,
        );
        widget.onUpdate(
          newValue.copyWith(
            childCount: widget.comment.childCount,
            children: widget.comment.children,
          ),
        );
      }),
      upVotes: widget.comment.upvotes,
      onUpVote: whenLoggedIn(context, () async {
        final newValue = await ac.api.comments.vote(
          widget.comment.postType,
          widget.comment.id,
          1,
          widget.comment.myVote == 1 ? 0 : 1,
        );
        widget.onUpdate(
          newValue.copyWith(
            childCount: widget.comment.childCount,
            children: widget.comment.children,
          ),
        );
      }),
      isUpVoted: widget.comment.myVote == 1,
      downVotes: widget.comment.downvotes,
      isDownVoted: widget.comment.myVote == -1,
      onDownVote: whenLoggedIn(context, () async {
        final newValue = await ac.api.comments.vote(
          widget.comment.postType,
          widget.comment.id,
          -1,
          widget.comment.myVote == -1 ? 0 : -1,
        );
        widget.onUpdate(
          newValue.copyWith(
            childCount: widget.comment.childCount,
            children: widget.comment.children,
          ),
        );
      }),
      contentTypeName: l(context).comment,
      onReply: widget.postLocked || widget.comment.isLocked
          ? null
          : whenLoggedIn(context, (
              body,
              lang, {
              XFile? image,
              String? alt,
            }) async {
              final newSubComment = await ac.api.comments.create(
                widget.comment.postType,
                widget.comment.postId,
                body,
                parentCommentId: widget.comment.id,
                lang: lang,
                image: image,
                alt: alt,
              );

              widget.onUpdate(
                widget.comment.copyWith(
                  childCount: widget.comment.childCount + 1,
                  children: [newSubComment, ...widget.comment.children!],
                ),
              );
            }),
      onReport: whenLoggedIn(context, (reason) async {
        await ac.api.comments.report(
          widget.comment.postType,
          widget.comment.id,
          reason,
        );
      }),
      onEdit: widget.comment.visibility != 'soft_deleted'
          ? whenLoggedIn(context, (body) async {
              final newValue = await ac.api.comments.edit(
                widget.comment.postType,
                widget.comment.id,
                body,
              );

              widget.onUpdate(
                newValue.copyWith(
                  childCount: widget.comment.childCount,
                  children: widget.comment.children,
                ),
              );
            }, matchesUsername: widget.comment.user.name)
          : null,
      onDelete: widget.comment.visibility != 'soft_deleted'
          ? whenLoggedIn(context, () async {
              await ac.api.comments.delete(
                widget.comment.postType,
                widget.comment.id,
              );

              if (!context.mounted) return;

              widget.onUpdate(
                widget.comment.copyWith(
                  body: '_${l(context).commentDeleted}_',
                  upvotes: null,
                  downvotes: null,
                  boosts: null,
                  visibility: 'soft_deleted',
                ),
              );
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

              widget.onUpdate(
                newValue.copyWith(
                  childCount: widget.comment.childCount,
                  children: widget.comment.children,
                ),
              );
            },
      onModerateBan: !canModerate
          ? null
          : () async {
              await openBanDialog(
                context,
                user: widget.comment.user,
                community: widget.comment.community,
              );
            },
      onModerateLock: !canModerate || ac.serverSoftware != ServerSoftware.piefed
          ? null
          : () async {
              widget.onUpdate(
                await ac.api.moderation.commentLock(
                  widget.comment.postType,
                  widget.comment.id,
                  !widget.comment.isLocked,
                ),
              );
            },
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
      onAddBookmark: whenLoggedIn(context, () async {
        final newBookmarks = await ac.api.bookmark.addBookmarkToDefault(
          subjectType: BookmarkListSubject.fromPostType(
            postType: widget.comment.postType,
            isComment: true,
          ),
          subjectId: widget.comment.id,
        );
        widget.onUpdate(widget.comment.copyWith(bookmarks: newBookmarks));
      }),
      onAddBookmarkToList: whenLoggedIn(context, (String listName) async {
        final newBookmarks = await ac.api.bookmark.addBookmarkToList(
          subjectType: BookmarkListSubject.fromPostType(
            postType: widget.comment.postType,
            isComment: true,
          ),
          subjectId: widget.comment.id,
          listName: listName,
        );
        widget.onUpdate(widget.comment.copyWith(bookmarks: newBookmarks));
      }, matchesSoftware: ServerSoftware.mbin),
      onRemoveBookmark: whenLoggedIn(context, () async {
        final newBookmarks = await ac.api.bookmark.removeBookmarkFromAll(
          subjectType: BookmarkListSubject.fromPostType(
            postType: widget.comment.postType,
            isComment: true,
          ),
          subjectId: widget.comment.id,
        );
        widget.onUpdate(widget.comment.copyWith(bookmarks: newBookmarks));
      }),
      onRemoveBookmarkFromList: whenLoggedIn(context, (String listName) async {
        final newBookmarks = await ac.api.bookmark.removeBookmarkFromList(
          subjectType: BookmarkListSubject.fromPostType(
            postType: widget.comment.postType,
            isComment: true,
          ),
          subjectId: widget.comment.id,
          listName: listName,
        );
        widget.onUpdate(widget.comment.copyWith(bookmarks: newBookmarks));
      }, matchesSoftware: ServerSoftware.mbin),
      notificationControlStatus: widget.comment.notificationControlStatus,
      onNotificationControlStatusChange:
          widget.comment.notificationControlStatus == null
          ? null
          : (newStatus) async {
              await ac.api.notifications.updateControl(
                targetType: NotificationControlUpdateTargetType.comment,
                targetId: widget.comment.id,
                status: newStatus,
              );

              widget.onUpdate(
                widget.comment.copyWith(notificationControlStatus: newStatus),
              );
            },
      onClick: widget.onClick ?? collapse,
      shareLinks: genCommentUrls(context, widget.comment),
      emojiReactions: widget.comment.emojiReactions,
      onEmojiReact: widget.comment.emojiReactions == null
          ? null
          : whenLoggedIn(context, (emoji) async {
              final newValue = await ac.api.comments.vote(
                widget.comment.postType,
                widget.comment.id,
                1,
                1,
                emoji: emoji,
              );
              widget.onUpdate(
                newValue.copyWith(
                  childCount: widget.comment.childCount,
                  children: widget.comment.children,
                ),
              );
            }),
    );

    final menuWidget = IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Symbols.more_vert_rounded),
      onPressed: () {
        showContentMenu(
          context,
          contentItem,
          onTranslate: (String lang) async {
            await getTranslation(lang);
          },
        );
      },
    );

    return Expandable(
      controller: _expandableController,
      collapsed: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onClick ?? collapse,
          onLongPress: () => showContentMenu(
            context,
            contentItem,
            onTranslate: (String lang) async {
              await getTranslation(lang);
            },
          ),
          onSecondaryTap: () => showContentMenu(
            context,
            contentItem,
            onTranslate: (String lang) async {
              await getTranslation(lang);
            },
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: ContentInfo(
              user: widget.comment.user,
              isOp: widget.comment.user.id == widget.opUserId,
              isLocked: widget.comment.isLocked,
              createdAt: widget.comment.createdAt,
              editedAt: widget.comment.editedAt,
            ),
          ),
        ),
      ),
      expanded: Column(
        children: [
          contentItem,
          if (widget.showChildren) ...[
            if (widget.comment.childCount > 0 &&
                _expandableController.expanded &&
                (widget.comment.children?.isEmpty ?? false))
              TextButton(
                onPressed: () => context.router.push(
                  PostCommentRoute(
                    postType: widget.comment.postType,
                    commentId: widget.comment.id,
                    opUserId: widget.opUserId,
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
                      color:
                          Colors.primaries[widget
                              .level], //Theme.of(context).colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: widget.comment.children!
                      .asMap()
                      .entries
                      .map(
                        (item) => PostComment(
                          item.value,
                          (newValue) {
                            final newChildren = [...widget.comment.children!];
                            newChildren[item.key] = newValue;
                            widget.onUpdate(
                              widget.comment.copyWith(
                                childCount: widget.comment.childCount + 1,
                                children: newChildren,
                              ),
                            );
                          },
                          opUserId: widget.opUserId,
                          onClick: widget.onClick,
                          userCanModerate: widget.userCanModerate,
                          level: widget.level + 1,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
