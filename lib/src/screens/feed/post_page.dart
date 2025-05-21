import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
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
    } else if (widget.postType != null && widget.postId != null) {
      final newPost = await switch (widget.postType!) {
        PostType.thread => context.read<AppController>().api.threads.get(
          widget.postId!,
        ),
        PostType.microblog => context.read<AppController>().api.microblogs.get(
          widget.postId!,
        ),
      };
      setState(() {
        _data = newPost;
      });
    } else {
      throw Exception('Post data was uninitialized');
    }

    _pagingController.addPageRequestListener(_fetchPage);

    if (!mounted) return;
    _onUpdate(
      (await context.read<AppController>().markAsRead([_data!], true)).first,
    );
  }

  void _onUpdate(PostModel newValue) {
    setState(() {
      _data = newValue;
    });
    widget.onUpdate?.call(newValue);
  }

  Future<void> _fetchPage(String pageKey) async {
    try {
      final newPage = await context.read<AppController>().api.comments.list(
        _data!.type,
        _data!.id,
        page: nullIfEmpty(pageKey),
        sort: commentSort,
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
      _pagingController.error = error;
    }
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
                onReply: whenLoggedIn(context, (body) async {
                  var newComment = await context
                      .read<AppController>()
                      .api
                      .comments
                      .create(post.type, post.id, body);
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
            PagedSliverList(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<CommentModel>(
                firstPageErrorIndicatorBuilder: (context) =>
                    FirstPageErrorIndicator(
                      error: _pagingController.error,
                      onTryAgain: _pagingController.retryLastFailedRequest,
                    ),
                newPageErrorIndicatorBuilder: (context) =>
                    NewPageErrorIndicator(
                      error: _pagingController.error,
                      onTryAgain: _pagingController.retryLastFailedRequest,
                    ),
                itemBuilder: (context, item, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: PostComment(
                    item,
                    (newValue) {
                      var newList = _pagingController.itemList;
                      newList![index] = newValue;
                      setState(() {
                        _pagingController.itemList = newList;
                      });
                    },
                    opUserId: post.user.id,
                    userCanModerate: widget.userCanModerate,
                  ),
                ),
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
