import 'package:flutter/material.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:interstellar/src/widgets/paging.dart';
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
    // Crossposts are only returned on fetching single post not on list
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
      body: RefreshIndicator(
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
                onReply: whenLoggedIn(context, (body, lang) async {
                  var newComment = await context
                      .read<AppController>()
                      .api
                      .comments
                      .create(post.type, post.id, body, lang: lang);

                  _mainCommentSectionKey.currentState?._pagingController
                      .prependPage('', [newComment]);
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
            if (context.read<AppController>().profile.showCrosspostComments)
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
                          key: Key('${crossPost.id}$commentSort'),
                        ),
                      ],
                    ),
                  ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
