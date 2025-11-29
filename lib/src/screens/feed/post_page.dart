import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/menus/content_menu.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/api/bookmark.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/widgets/ban_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class PostPage extends StatefulWidget {
  const PostPage({
    this.postType,
    this.postId,
    this.initData,
    this.onUpdate,
    super.key,
    this.userCanModerate = false,
  });

  final PostType? postType;
  final int? postId;
  final PostModel? initData;
  final void Function(PostModel)? onUpdate;
  final bool userCanModerate;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  PostModel? _data;

  CommentSort commentSort = CommentSort.hot;

  @override
  void initState() {
    super.initState();

    commentSort = context.read<AppController>().profile.feedDefaultCommentSort;

    _initData();
  }

  void _initData() async {
    if (widget.initData != null) {
      _data = widget.initData!;
    }
    // Cross posts are only returned on fetching single post not on list
    // so need to fetch full post info.
    if (widget.postType != null && widget.postId != null || _data != null) {
      final newPost = await switch (widget.postType ?? _data!.type) {
        PostType.thread => context.read<AppController>().api.threads.get(
          widget.postId ?? _data!.id,
        ),
        PostType.microblog => context.read<AppController>().api.microblogs.get(
          widget.postId ?? _data!.id,
        ),
      };
      if (!mounted) return;
      setState(() {
        _data = newPost;
      });
    } else if (_data == null) {
      throw Exception('Post data was uninitialized');
    }

    if (!mounted) return;
    _onUpdate(
      (await context.read<AppController>().markAsRead([
        _data!,
        ...?(context.read<AppController>().profile.markCrossPostsAsRead
            ? _data!.crossPosts
            : null),
      ], true)).first,
    );
  }

  void _onUpdate(PostModel newValue) {
    if (!mounted) return;
    setState(() {
      _data = newValue;
    });
    widget.onUpdate?.call(newValue);
  }

  void _updateCrossPost(PostModel crossPost) {
    var newCrossPosts = _data!.crossPosts.toList();
    int indexOfPost = newCrossPosts.indexWhere(
      (post) => post.id == crossPost.id,
    );
    newCrossPosts[indexOfPost] = crossPost;
    _onUpdate(_data!.copyWith(crossPosts: newCrossPosts));
  }

  Future<void> showCrossPostMenu(
    BuildContext context,
    PostModel crossPost,
  ) async {
    final ac = context.read<AppController>();
    final canModerate = crossPost.canAuthUserModerate ?? false;
    final contentItem = ContentItem(
      originInstance: getNameHost(context, crossPost.user.name),
      user: crossPost.user,
      updateUser: (user) async {
        _updateCrossPost(crossPost.copyWith(user: user));
      },
      community: crossPost.community,
      boosts: crossPost.boosts,
      isBoosted: crossPost.myBoost == true,
      onBoost: whenLoggedIn(context, () async {
        _updateCrossPost(
          (await ac.markAsRead([
            await switch (crossPost.type) {
              PostType.thread => ac.api.threads.boost(crossPost.id),
              PostType.microblog => ac.api.microblogs.putVote(crossPost.id, 1),
            },
          ], true)).first,
        );
      }),
      upVotes: crossPost.upvotes,
      isUpVoted: crossPost.myVote == 1,
      onUpVote: whenLoggedIn(context, () async {
        _updateCrossPost(
          (await ac.markAsRead([
            await switch (crossPost.type) {
              PostType.thread => ac.api.threads.vote(
                crossPost.id,
                1,
                crossPost.myVote == 1 ? 0 : 1,
              ),
              PostType.microblog => ac.api.microblogs.putFavorite(crossPost.id),
            },
          ], true)).first,
        );
      }),
      downVotes: crossPost.downvotes,
      isDownVoted: crossPost.myVote == -1,
      onDownVote: whenLoggedIn(context, () async {
        _updateCrossPost(
          (await ac.markAsRead([
            await switch (crossPost.type) {
              PostType.thread => ac.api.threads.vote(
                crossPost.id,
                -1,
                crossPost.myVote == -1 ? 0 : -1,
              ),
              PostType.microblog => ac.api.microblogs.putVote(crossPost.id, -1),
            },
          ], true)).first,
        );
      }),
      contentTypeName: l(context).post,
      onReport: whenLoggedIn(context, (reason) async {
        await switch (crossPost.type) {
          PostType.thread => ac.api.threads.report(crossPost.id, reason),
          PostType.microblog => ac.api.microblogs.report(crossPost.id, reason),
        };
      }),
      onMarkAsRead: () async {
        _updateCrossPost(
          (await ac.markAsRead([crossPost], !crossPost.read)).first,
        );
      },
      onModeratePin: !canModerate
          ? null
          : () async {
              _updateCrossPost(
                await ac.api.moderation.postPin(crossPost.type, crossPost.id),
              );
            },
      onModerateMarkNSFW: !canModerate
          ? null
          : () async {
              _updateCrossPost(
                await ac.api.moderation.postMarkNSFW(
                  crossPost.type,
                  crossPost.id,
                  !crossPost.isNSFW,
                ),
              );
            },
      onModerateDelete: !canModerate
          ? null
          : () async {
              _updateCrossPost(
                await ac.api.moderation.postDelete(
                  crossPost.type,
                  crossPost.id,
                  true,
                ),
              );
            },
      onModerateBan: !canModerate
          ? null
          : () async {
              await openBanDialog(
                context,
                user: crossPost.user,
                community: crossPost.community,
              );
            },
      numComments: crossPost.numComments,
      openLinkUri: genPostUrl(context, crossPost),
      editDraftResourceId:
          'edit:${crossPost.type.name}:${ac.instanceHost}:${crossPost.id}',
      replyDraftResourceId:
          'reply:${crossPost.type.name}:${ac.instanceHost}:${crossPost.id}',
      activeBookmarkLists: crossPost.bookmarks,
      loadPossibleBookmarkLists: whenLoggedIn(
        context,
        () async => (await ac.api.bookmark.getBookmarkLists())
            .map((list) => list.name)
            .toList(),
        matchesSoftware: ServerSoftware.mbin,
      ),
      onAddBookmark: whenLoggedIn(context, () async {
        try {
          final newBookmarks = await ac.api.bookmark.addBookmarkToDefault(
            subjectType: BookmarkListSubject.fromPostType(
              postType: crossPost.type,
              isComment: false,
            ),
            subjectId: crossPost.id,
          );
          _updateCrossPost(crossPost.copyWith(bookmarks: newBookmarks));
        } catch (e) {
          //
        }
      }),
      onAddBookmarkToList: whenLoggedIn(context, (String listName) async {
        final newBookmarks = await ac.api.bookmark.addBookmarkToList(
          subjectType: BookmarkListSubject.fromPostType(
            postType: crossPost.type,
            isComment: false,
          ),
          subjectId: crossPost.id,
          listName: listName,
        );
        _updateCrossPost(crossPost.copyWith(bookmarks: newBookmarks));
      }, matchesSoftware: ServerSoftware.mbin),
      onRemoveBookmark: whenLoggedIn(context, () async {
        try {
          final newBookmarks = await ac.api.bookmark.removeBookmarkFromAll(
            subjectType: BookmarkListSubject.fromPostType(
              postType: crossPost.type,
              isComment: false,
            ),
            subjectId: crossPost.id,
          );
          _updateCrossPost(crossPost.copyWith(bookmarks: newBookmarks));
        } catch (e) {
          //
        }
      }),
      onRemoveBookmarkFromList: whenLoggedIn(context, (String listName) async {
        final newBookmarks = await ac.api.bookmark.removeBookmarkFromList(
          subjectType: BookmarkListSubject.fromPostType(
            postType: crossPost.type,
            isComment: false,
          ),
          subjectId: crossPost.id,
          listName: listName,
        );
        _updateCrossPost(crossPost.copyWith(bookmarks: newBookmarks));
      }, matchesSoftware: ServerSoftware.mbin),
      notificationControlStatus: crossPost.notificationControlStatus,
      onNotificationControlStatusChange:
          crossPost.notificationControlStatus == null
          ? null
          : (newStatus) async {
              await ac.api.notifications.updateControl(
                targetType: switch (crossPost.type) {
                  PostType.thread => NotificationControlUpdateTargetType.entry,
                  PostType.microblog =>
                    NotificationControlUpdateTargetType.post,
                },
                targetId: crossPost.id,
                status: newStatus,
              );

              _updateCrossPost(
                crossPost.copyWith(notificationControlStatus: newStatus),
              );
            },
      crossPost: crossPost,
    );
    showContentMenu(context, contentItem);
  }

  GlobalKey<_CommentSectionState> _mainCommentSectionKey =
      GlobalKey<_CommentSectionState>();

  @override
  Widget build(BuildContext context) {
    final currentCommentSortOption = commentSortSelect(
      context,
    ).getOption(commentSort);

    if (_data == null) {
      return const LoadingTemplate();
    }

    PostModel post = _data!;

    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            post.title ?? post.body ?? '',
            softWrap: false,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
          subtitle: Row(
            children: [
              Text(l(context).comments),
              const SizedBox(width: 6),
              Icon(currentCommentSortOption.icon, size: 20),
              const SizedBox(width: 2),
              Text(currentCommentSortOption.title),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () async {
                final newSort = await commentSortSelect(
                  context,
                ).askSelection(context, commentSort);

                if (newSort != null && newSort != commentSort) {
                  setState(() {
                    commentSort = newSort;
                    _mainCommentSectionKey = GlobalKey<_CommentSectionState>();
                  });
                }
              },
              icon: const Icon(Symbols.sort_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.sync(
            () => setState(
              () => _mainCommentSectionKey = GlobalKey<_CommentSectionState>(),
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PostItem(
                  post,
                  _onUpdate,
                  onReply: whenLoggedIn(context, (
                    body,
                    lang, {
                    XFile? image,
                    String? alt,
                  }) async {
                    var newComment = await context
                        .read<AppController>()
                        .api
                        .comments
                        .create(
                          post.type,
                          post.id,
                          body,
                          lang: lang,
                          image: image,
                          alt: alt,
                        );

                    _mainCommentSectionKey.currentState?._pagingController
                        .prependPage('', [newComment]);
                  }),
                  onEdit: post.visibility != 'soft_deleted'
                      ? whenLoggedIn(context, (body) async {
                          final newPost = await switch (post.type) {
                            PostType.thread => ac.api.threads.edit(
                              post.id,
                              post.title!,
                              post.isOC,
                              body,
                              post.lang,
                              post.isNSFW,
                            ),
                            PostType.microblog => ac.api.microblogs.edit(
                              post.id,
                              body,
                              post.lang!,
                              post.isNSFW,
                            ),
                          };
                          _onUpdate(newPost);
                        }, matchesUsername: post.user.name)
                      : null,
                  onDelete: post.visibility != 'soft_deleted'
                      ? whenLoggedIn(context, () async {
                          await switch (post.type) {
                            PostType.thread => ac.api.threads.delete(post.id),
                            PostType.microblog => ac.api.microblogs.delete(
                              post.id,
                            ),
                          };
                          _onUpdate(
                            post.copyWith(
                              body: '_${l(context).postDeleted}_',
                              upvotes: null,
                              downvotes: null,
                              boosts: null,
                              visibility: 'soft_deleted',
                            ),
                          );
                        }, matchesUsername: post.user.name)
                      : null,
                  userCanModerate: widget.userCanModerate,
                ),
              ),
              if (_data != null && _data!.crossPosts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ElevatedButton(
                      onPressed: () => ContextMenu(
                        title: l(context).crossPosts,
                        items: _data!.crossPosts
                            .map(
                              (crossPost) => ContextMenuItem(
                                title: crossPost.community.name,
                                subtitle: l(
                                  context,
                                ).commentsX(crossPost.numComments),
                                onTap: () => pushRoute(
                                  context,
                                  builder: (context) => PostPage(
                                    postType: PostType.thread,
                                    postId: crossPost.id,
                                    initData: crossPost,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ).openMenu(context),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l(context).crossPostCount(post.crossPosts.length),
                        ),
                      ),
                    ),
                  ),
                ),
              CommentSection(
                id: post.id,
                postType: post.type,
                sort: commentSort,
                opUserId: post.user.id,
                key: _mainCommentSectionKey,
              ),
              if (context.read<AppController>().profile.showCrossPostComments)
                ...post.crossPosts
                    .where((crossPost) => crossPost.numComments > 0)
                    .map(
                      (crossPost) => SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(child: const Divider()),
                          SliverToBoxAdapter(
                            child: ListTile(
                              title: Text(
                                l(
                                  context,
                                ).crossPostComments(crossPost.community.name),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              trailing: LoadingIconButton(
                                onPressed: () =>
                                    showCrossPostMenu(context, crossPost),
                                icon: const Icon(Symbols.more_vert_rounded),
                              ),
                              onTap: () => pushRoute(
                                context,
                                builder: (context) => PostPage(
                                  postType: crossPost.type,
                                  postId: crossPost.id,
                                  initData: crossPost,
                                ),
                              ),
                              onLongPress: () =>
                                  showCrossPostMenu(context, crossPost),
                            ),
                          ),
                          CommentSection(
                            id: crossPost.id,
                            postType: crossPost.type,
                            sort: commentSort,
                            opUserId: crossPost.user.id,
                            key: Key('${crossPost.id}$commentSort'),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentSection extends StatefulWidget {
  const CommentSection({
    super.key,
    required this.id,
    required this.postType,
    required this.sort,
    required this.opUserId,
    this.canModerate = false,
  });

  final int id;
  final PostType postType;
  final CommentSort sort;
  final int opUserId;
  final bool canModerate;

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late final _pagingController =
      AdvancedPagingController<String, CommentModel, int>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => item.id,
        fetchPage: (pageKey) async {
          final ac = context.read<AppController>();

          final newPage = await ac.api.comments.list(
            widget.postType,
            widget.id,
            page: nullIfEmpty(pageKey),
            sort: widget.sort,
            usePreferredLangs: whenLoggedIn(
              context,
              ac.profile.useAccountLanguageFilter,
            ),
            langs: ac.profile.customLanguageFilter.toList(),
          );

          return (newPage.items, newPage.nextPage);
        },
      );

  @override
  Widget build(BuildContext context) {
    return AdvancedPagedSliverList(
      controller: _pagingController,
      itemBuilder: (context, item, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: PostComment(
          item,
          (newValue) => _pagingController.updateItem(item, newValue),
          opUserId: widget.opUserId,
          userCanModerate: widget.canModerate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
