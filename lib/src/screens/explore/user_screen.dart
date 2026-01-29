import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/explore_screen_item.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/hide_on_scroll.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/subordinate_scroll.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:interstellar/src/widgets/menus/user_menu.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

enum UserFeedType { thread, microblog, comment, reply, follower, following }

@RoutePage()
class UserScreen extends StatefulWidget {
  final int userId;
  final DetailedUserModel? initData;
  final void Function(DetailedUserModel)? onUpdate;

  const UserScreen(
    @PathParam('userId') this.userId, {
    super.key,
    this.initData,
    this.onUpdate,
  });

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  DetailedUserModel? _data;
  late FeedSort _sort;
  late final ScrollController _scrollController;
  final List<GlobalKey<_UserScreenBodyState>> _feedKeyList = [];

  GlobalKey<_UserScreenBodyState> _getFeedKey(int index) {
    while (index >= _feedKeyList.length) {
      _feedKeyList.add(GlobalKey());
    }
    return _feedKeyList[index];
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _data = widget.initData;
    _sort = context.read<AppController>().profile.feedDefaultExploreSort;

    if (_data == null) {
      context
          .read<AppController>()
          .api
          .users
          .get(widget.userId)
          .then((value) async {
            if (!context.mounted) return value;
            final tags = await context.read<AppController>().getUserTags(
              value.name,
            );

            return value.copyWith(tags: [...value.tags, ...tags]);
          })
          .then((value) {
            if (!mounted) return;
            setState(() {
              _data = value;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    if (_data == null) {
      return const LoadingTemplate();
    }

    final user = _data!;

    final isLoggedIn = ac.isLoggedIn;
    final isMyUser =
        isLoggedIn &&
        whenLoggedIn(context, true, matchesUsername: user.name) == true;

    final currentFeedSortOption = feedSortSelect(context).getOption(_sort);

    final globalName = user.name.contains('@')
        ? '@${user.name}'
        : '@${user.name}@${ac.instanceHost}';

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          if (isMyUser && ac.serverSoftware != ServerSoftware.piefed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Icon(Symbols.bookmarks_rounded, size: 20),
                onPressed: () => context.router.push(
                  ac.serverSoftware == ServerSoftware.mbin
                      ? BookmarkListRoute()
                      : BookmarksRoute(bookmarkList: 'default'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              padding: chipDropdownPadding,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(currentFeedSortOption.icon, size: 20),
                  const SizedBox(width: 4),
                  Text(currentFeedSortOption.title),
                  const Icon(Symbols.arrow_drop_down_rounded),
                ],
              ),
              onPressed: () async {
                final newSort = await feedSortSelect(
                  context,
                ).askSelection(context, _sort);

                if (newSort != null && newSort != _sort) {
                  setState(() {
                    _sort = newSort;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: ac.serverSoftware == ServerSoftware.mbin ? 6 : 2,
        child: DefaultTabControllerListener(
          onTabSelected: (newIndex) => setState(() {}),
          child: NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height / 3,
                          ),
                          height: user.cover == null ? 48 : null,
                          margin: const EdgeInsets.only(bottom: 48),
                          child: user.cover != null
                              ? AdvancedImage(user.cover!, fit: BoxFit.cover)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 12,
                          child: Avatar(
                            user.avatar,
                            radius: 36,
                            borderRadius: 4,
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isMyUser)
                                    FilledButton(
                                      onPressed: () => context.router.push(
                                        ProfileEditRoute(
                                          user: _data!,
                                          onUpdate: (DetailedUserModel user) {
                                            setState(() {
                                              _data = user;
                                            });
                                          },
                                        ),
                                      ),
                                      child: Text(l(context).account_edit),
                                    ),
                                  if (!isMyUser &&
                                      ac.serverSoftware == ServerSoftware.mbin)
                                    SubscriptionButton(
                                      isSubscribed: user.isFollowedByUser,
                                      subscriptionCount:
                                          user.followersCount ?? 0,
                                      onSubscribe: (selected) async {
                                        var newValue = await ac.api.users
                                            .follow(user.id, selected);
                                        setState(() {
                                          _data = newValue;
                                        });
                                        if (widget.onUpdate != null) {
                                          widget.onUpdate!(newValue);
                                        }
                                      },
                                      followMode: true,
                                    ),
                                  StarButton(globalName),
                                  if (isLoggedIn && !isMyUser)
                                    LoadingIconButton(
                                      onPressed: () async {
                                        final newValue = await ac.api.users
                                            .putBlock(
                                              user.id,
                                              !user.isBlockedByUser!,
                                            );

                                        setState(() {
                                          _data = newValue;
                                        });
                                        if (widget.onUpdate != null) {
                                          widget.onUpdate!(newValue);
                                        }
                                      },
                                      icon: const Icon(Symbols.block_rounded),
                                      style: ButtonStyle(
                                        foregroundColor: WidgetStatePropertyAll(
                                          user.isBlockedByUser == true
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : Theme.of(context).disabledColor,
                                        ),
                                      ),
                                    ),
                                  if (isLoggedIn && !isMyUser)
                                    IconButton(
                                      onPressed: () => context.router.push(
                                        MessageThreadRoute(
                                          threadId: null,
                                          userId: _data?.id,
                                          otherUser: _data,
                                        ),
                                      ),
                                      icon: const Icon(Symbols.mail_rounded),
                                      tooltip: 'Send message',
                                    ),
                                  IconButton(
                                    onPressed: () => showUserMenu(
                                      context,
                                      user: _data!,
                                      update: (newUser) {
                                        setState(() {
                                          _data = newUser;
                                        });
                                        if (widget.onUpdate != null) {
                                          widget.onUpdate!(newUser);
                                        }
                                      },
                                    ),
                                    icon: const Icon(Symbols.more_vert_rounded),
                                  ),
                                ],
                              ),
                              if (!isMyUser &&
                                  _data!.notificationControlStatus != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: NotificationControlSegment(
                                    _data!.notificationControlStatus!,
                                    (newStatus) async {
                                      await ac.api.notifications.updateControl(
                                        targetType:
                                            NotificationControlUpdateTargetType
                                                .user,
                                        targetId: _data!.id,
                                        status: newStatus,
                                      );

                                      final newValue = _data!.copyWith(
                                        notificationControlStatus: newStatus,
                                      );
                                      setState(() {
                                        _data = newValue;
                                      });
                                      if (widget.onUpdate != null) {
                                        widget.onUpdate!(newValue);
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? user.name.split('@').first,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              InkWell(
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: user.name.contains('@')
                                          ? '@${user.name}'
                                          : '@${user.name}@${ac.instanceHost}',
                                    ),
                                  );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l(context).copied),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Text(globalName),
                              ),
                              if (user.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    children: user.tags
                                        .map((tag) => TagWidget(tag: tag))
                                        .toList(),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Joined: ${dateOnlyFormat(user.createdAt)}',
                                  ),
                                  UserStatusIcons(
                                    cakeDay: user.createdAt,
                                    isBot: user.isBot,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (user.about != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Markdown(
                                user.about!,
                                getNameHost(context, user.name),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverAppBar(
                automaticallyImplyLeading: false,
                title: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(text: 'Threads'),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      const Tab(text: 'Microblogs'),
                    const Tab(text: 'Comments'),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      const Tab(text: 'Replies'),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      const Tab(text: 'Followers'),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      const Tab(text: 'Following'),
                  ],
                ),
                pinned: true,
              ),
            ],
            body: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return TabBarView(
                  physics: appTabViewPhysics(context),
                  children: [
                    UserScreenBody(
                      key: _getFeedKey(0),
                      mode: UserFeedType.thread,
                      sort: _sort,
                      data: _data,
                      isActive: controller.index == 0,
                    ),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      UserScreenBody(
                        key: _getFeedKey(1),
                        mode: UserFeedType.microblog,
                        sort: _sort,
                        data: _data,
                        isActive: controller.index == 1,
                      ),
                    UserScreenBody(
                      key: _getFeedKey(2),
                      mode: UserFeedType.comment,
                      sort: _sort,
                      data: _data,
                      isActive: ac.serverSoftware == ServerSoftware.mbin
                          ? controller.index == 2
                          : controller.index == 1,
                    ),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      UserScreenBody(
                        key: _getFeedKey(3),
                        mode: UserFeedType.reply,
                        sort: _sort,
                        data: _data,
                        isActive: controller.index == 3,
                      ),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      UserScreenBody(
                        key: _getFeedKey(4),
                        mode: UserFeedType.follower,
                        sort: _sort,
                        data: _data,
                        isActive: controller.index == 4,
                      ),
                    if (ac.serverSoftware == ServerSoftware.mbin)
                      UserScreenBody(
                        key: _getFeedKey(5),
                        mode: UserFeedType.following,
                        sort: _sort,
                        data: _data,
                        isActive: controller.index == 5,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: Wrapper(
        shouldWrap: ac.profile.hideFeedUIOnScroll,
        parentBuilder: (child) => HideOnScroll(
          controller: _scrollController,
          hiddenOffset: Offset(0, 2),
          duration: ac.calcAnimationDuration(),
          child: child,
        ),
        child: FloatingActionButton(
          heroTag: 'user_screen_floating',
          onPressed: () {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: Durations.long1,
              curve: Curves.easeInOut,
            );
          },
          child: const Icon(Symbols.keyboard_double_arrow_up_rounded),
        ),
      ),
    );
  }
}

class UserScreenBody extends StatefulWidget {
  final UserFeedType mode;
  final FeedSort sort;
  final DetailedUserModel? data;
  final bool isActive;

  const UserScreenBody({
    super.key,
    required this.mode,
    required this.sort,
    this.data,
    this.isActive = false,
  });

  @override
  State<UserScreenBody> createState() => _UserScreenBodyState();
}

class _UserScreenBodyState extends State<UserScreenBody>
    with AutomaticKeepAliveClientMixin<UserScreenBody> {
  late final _pagingController = AdvancedPagingController<String, dynamic, int>(
    logger: context.read<AppController>().logger,
    firstPageKey: '',
    // TODO: this is not safe, items of different types (comment, microblog, etc.) could have the same id
    getItemId: (item) => item.id,
    fetchPage: (pageKey) async {
      final ac = context.read<AppController>();

      const Map<FeedSort, CommentSort> feedToCommentSortMap = {
        FeedSort.active: CommentSort.active,
        FeedSort.commented: CommentSort.active,
        FeedSort.hot: CommentSort.hot,
        FeedSort.newest: CommentSort.newest,
        FeedSort.oldest: CommentSort.oldest,
        FeedSort.top: CommentSort.top,
      };

      final newPage = await (switch (widget.mode) {
        UserFeedType.thread => ac.api.threads.list(
          FeedSource.user,
          sourceId: widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: widget.sort,
        ),
        UserFeedType.microblog => ac.api.microblogs.list(
          FeedSource.user,
          sourceId: widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: widget.sort,
        ),
        UserFeedType.comment => ac.api.comments.listFromUser(
          PostType.thread,
          widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: feedToCommentSortMap[widget.sort],
        ),
        UserFeedType.reply => ac.api.comments.listFromUser(
          PostType.microblog,
          widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: feedToCommentSortMap[widget.sort],
        ),
        UserFeedType.follower => ac.api.users.listFollowers(
          widget.data!.id,
          page: nullIfEmpty(pageKey),
        ),
        UserFeedType.following => ac.api.users.listFollowing(
          widget.data!.id,
          page: nullIfEmpty(pageKey),
        ),
      });

      return (
        switch (newPage) {
          PostListModel newPage => newPage.items,
          CommentListModel newPage => newPage.items,
          DetailedUserListModel newPage => newPage.items,
          Object _ => [],
        },
        switch (newPage) {
          PostListModel newPage => newPage.nextPage,
          CommentListModel newPage => newPage.nextPage,
          DetailedUserListModel newPage => newPage.nextPage,
          Object _ => null,
        },
      );
    },
  );
  SubordinateScrollController? _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentController = PrimaryScrollController.of(context);
    if (parentController != _scrollController?.parent) {
      _scrollController?.dispose();
      _scrollController = SubordinateScrollController(parent: parentController);
      _scrollController!.isActive = widget.isActive;
    }
  }

  @override
  void didUpdateWidget(covariant UserScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode || widget.sort != oldWidget.sort) {
      _pagingController.refresh();
    }
    _scrollController?.isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AdvancedPagedScrollView(
      controller: _pagingController,
      scrollController: _scrollController,
      itemBuilder: (context, item, index) {
        return switch (widget.mode) {
          UserFeedType.thread || UserFeedType.microblog => PostItem(
            item,
            (newValue) => _pagingController.updateItem(item, newValue),
            onTap: () => pushPostPage(
              context,
              postId: item.id,
              postType: item.type,
              initData: item,
              onUpdate: (newValue) =>
                  _pagingController.updateItem(item, newValue),
            ),
            isPreview: true,
            isTopLevel: true,
            isCompact: context.watch<AppController>().profile.compactMode,
          ),
          UserFeedType.comment || UserFeedType.reply => Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: PostComment(
              item,
              (newValue) => _pagingController.updateItem(item, newValue),
              onClick: () => context.router.push(
                PostCommentRoute(postType: item.postType, commentId: item.id),
              ),
              showChildren: false,
            ),
          ),
          UserFeedType.follower || UserFeedType.following => ExploreScreenItem(
            item,
            (newValue) => _pagingController.updateItem(item, newValue),
          ),
        };
      },
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _pagingController.dispose();
    super.dispose();
  }
}
