import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../controller/server.dart';

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

  final PagingController<String, CommentModel> _pagingController =
      PagingController(firstPageKey: '');

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
    // Lemmy and PieFed only return crossposts on fetching single post not on list
    // so need to fetch full post info. Can skip on mbin.
    if (widget.postType != null && widget.postId != null ||
        _data != null &&
            context.read<AppController>().serverSoftware !=
                ServerSoftware.mbin) {
      final newPost = await switch (widget.postType ?? _data!.type) {
        PostType.thread => context.read<AppController>().api.threads.get(
          widget.postId ?? _data!.id,
        ),
        PostType.microblog => context.read<AppController>().api.microblogs.get(
          widget.postId ?? _data!.id,
        ),
      };
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
        ...?(context.read<AppController>().profile.markCrosspostsAsRead
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

  @override
  Widget build(BuildContext context) {
    final currentCommentSortOption = commentSortSelect(
      context,
    ).getOption(commentSort);

    if (_data == null) {
      return const LoadingTemplate();
    }

    PostModel post = _data!;

    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            post.title ?? post.body ?? '',
            softWrap: false,
            overflow: TextOverflow.fade,
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
                    _pagingController.refresh();
                  });
                }
              },
              icon: const Icon(Symbols.sort_rounded),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PostItem(
                post,
                _onUpdate,
                onReply: whenLoggedIn(context, (body, lang) async {
                  var newComment = await context
                      .read<AppController>()
                      .api
                      .comments
                      .create(post.type, post.id, body, lang: lang);
                  var newList = _pagingController.itemList;
                  newList?.insert(0, newComment);
                  setState(() {
                    _pagingController.itemList = newList;
                  });
                }),
                onEdit: post.visibility != 'soft_deleted'
                    ? whenLoggedIn(context, (body) async {
                        final newPost = await switch (post.type) {
                          PostType.thread =>
                            context.read<AppController>().api.threads.edit(
                              post.id,
                              post.title!,
                              post.isOC,
                              body,
                              post.lang,
                              post.isNSFW,
                            ),
                          PostType.microblog =>
                            context.read<AppController>().api.microblogs.edit(
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
                          PostType.thread =>
                            context.read<AppController>().api.threads.delete(
                              post.id,
                            ),
                          PostType.microblog =>
                            context.read<AppController>().api.microblogs.delete(
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
            ),
            if (context.read<AppController>().profile.showCrosspostComments)
              ...post.crossPosts.map(
                (crossPost) => SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text(
                          l(
                            context,
                          ).crossPostComments(crossPost.community.name),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        onTap: () => pushRoute(
                          context,
                          builder: (context) => PostPage(
                            postType: crossPost.type,
                            postId: crossPost.id,
                            initData: crossPost,
                          ),
                        ),
                      ),
                    ),
                    CommentSection(
                      id: crossPost.id,
                      postType: crossPost.type,
                      sort: commentSort,
                      opUserId: crossPost.user.id,
                    ),
                  ],
                ),
              ),
          ],
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
  final PagingController<String, CommentModel> _pagingController =
      PagingController(firstPageKey: '');

  Future<void> _fetchPage(String pageKey) async {
    try {
      final newPage = await context.read<AppController>().api.comments.list(
        widget.postType,
        widget.id,
        page: nullIfEmpty(pageKey),
        sort: widget.sort,
        usePreferredLangs: whenLoggedIn(
          context,
          context.read<AppController>().profile.useAccountLanguageFilter,
        ),
        langs: context
            .read<AppController>()
            .profile
            .customLanguageFilter
            .toList(),
      );

      // Check BuildContext
      if (!mounted) return;

      // Prevent duplicates
      final currentItemIds = _pagingController.itemList?.map((e) => e.id) ?? [];
      final newItems = newPage.items
          .where((e) => !currentItemIds.contains(e.id))
          .toList();

      _pagingController.appendPage(newItems, newPage.nextPage);
    } catch (error) {
      if (!mounted) return;
      context.read<AppController>().logger.e(error);
      _pagingController.error = error;
    }
  }

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  Widget build(BuildContext context) {
    return PagedSliverList(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<CommentModel>(
        firstPageErrorIndicatorBuilder: (context) => FirstPageErrorIndicator(
          error: _pagingController.error,
          onTryAgain: _pagingController.retryLastFailedRequest,
        ),
        newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
          error: _pagingController.error,
          onTryAgain: _pagingController.retryLastFailedRequest,
        ),
        itemBuilder: (context, item, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: PostComment(
            item,
            (newValue) {
              var newList = _pagingController.itemList;
              newList![index] = newValue;
              setState(() {
                _pagingController.itemList = newList;
              });
            },
            opUserId: widget.opUserId,
            userCanModerate: widget.canModerate,
          ),
        ),
      ),
    );
  }
}
