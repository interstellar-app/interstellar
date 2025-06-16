import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/account/messages/message_thread_screen.dart';
import 'package:interstellar/src/screens/account/profile_edit_screen.dart';
import 'package:interstellar/src/screens/explore/bookmarks_screen.dart';
import 'package:interstellar/src/screens/explore/explore_screen_item.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

enum UserFeedType { thread, microblog, comment, reply, follower, following }

class UserScreen extends StatefulWidget {
  final int userId;
  final DetailedUserModel? initData;
  final void Function(DetailedUserModel)? onUpdate;

  const UserScreen(this.userId, {super.key, this.initData, this.onUpdate});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  DetailedUserModel? _data;
  TextEditingController? _messageController;
  late FeedSort _sort;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;
    _sort = context.read<AppController>().profile.feedDefaultExploreSort;

    if (_data == null) {
      context
          .read<AppController>()
          .api
          .users
          .get(widget.userId)
          .then(
            (value) => setState(() {
              _data = value;
            }),
          );
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

    final messageDraftController = context.watch<DraftsController>().auto(
      'message:${ac.instanceHost}:${user.name}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          if (isMyUser && ac.serverSoftware != ServerSoftware.piefed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Icon(Symbols.bookmarks_rounded, size: 20),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return ac.serverSoftware == ServerSoftware.mbin
                          ? BookmarkListScreen()
                          : BookmarksScreen();
                    },
                  ),
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
        child: NestedScrollView(
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
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ProfileEditScreen(_data!, (
                                            DetailedUserModel user,
                                          ) {
                                            setState(() {
                                              _data = user;
                                            });
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
                                    subscriptionCount: user.followersCount ?? 0,
                                    onSubscribe: (selected) async {
                                      var newValue = await ac.api.users.follow(
                                        user.id,
                                        selected,
                                      );
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
                                    onPressed: () {
                                      setState(() {
                                        _messageController =
                                            TextEditingController();
                                      });
                                    },
                                    icon: const Icon(Symbols.mail_rounded),
                                    tooltip: 'Send message',
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

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l(context).copied),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text(globalName),
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
                        if (_messageController != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                MarkdownEditor(
                                  _messageController!,
                                  originInstance: null,
                                  draftController: messageDraftController,
                                  label: 'Message',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _messageController = null;
                                        });
                                      },
                                      child: Text(l(context).cancel),
                                    ),
                                    LoadingFilledButton(
                                      onPressed: () async {
                                        final newThread = await ac.api.messages
                                            .create(
                                              user.id,
                                              _messageController!.text,
                                            );

                                        await messageDraftController.discard();

                                        setState(() {
                                          _messageController = null;

                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MessageThreadScreen(
                                                    threadId: newThread.id,
                                                    initData: newThread,
                                                  ),
                                            ),
                                          );
                                        });
                                      },
                                      label: Text(l(context).send),
                                      uesHaptics: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
          body: TabBarView(
            physics: appTabViewPhysics(context),
            children: [
              UserScreenBody(
                mode: UserFeedType.thread,
                sort: _sort,
                data: _data,
              ),
              if (ac.serverSoftware == ServerSoftware.mbin)
                UserScreenBody(
                  mode: UserFeedType.microblog,
                  sort: _sort,
                  data: _data,
                ),
              UserScreenBody(
                mode: UserFeedType.comment,
                sort: _sort,
                data: _data,
              ),
              if (ac.serverSoftware == ServerSoftware.mbin)
                UserScreenBody(
                  mode: UserFeedType.reply,
                  sort: _sort,
                  data: _data,
                ),
              if (ac.serverSoftware == ServerSoftware.mbin)
                UserScreenBody(
                  mode: UserFeedType.follower,
                  sort: _sort,
                  data: _data,
                ),
              if (ac.serverSoftware == ServerSoftware.mbin)
                UserScreenBody(
                  mode: UserFeedType.following,
                  sort: _sort,
                  data: _data,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserScreenBody extends StatefulWidget {
  final UserFeedType mode;
  final FeedSort sort;
  final DetailedUserModel? data;

  const UserScreenBody({
    super.key,
    required this.mode,
    required this.sort,
    this.data,
  });

  @override
  State<UserScreenBody> createState() => _UserScreenBodyState();
}

class _UserScreenBodyState extends State<UserScreenBody>
    with AutomaticKeepAliveClientMixin<UserScreenBody> {
  final PagingController<String, dynamic> _pagingController = PagingController(
    firstPageKey: '',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode || widget.sort != oldWidget.sort) {
      _pagingController.refresh();
    }
  }

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    final ac = context.read<AppController>();

    const Map<FeedSort, CommentSort> feedToCommentSortMap = {
      FeedSort.active: CommentSort.active,
      FeedSort.commented: CommentSort.active,
      FeedSort.hot: CommentSort.hot,
      FeedSort.newest: CommentSort.newest,
      FeedSort.oldest: CommentSort.oldest,
      FeedSort.top: CommentSort.top,
    };

    try {
      final newPage = await (switch (widget.mode) {
        UserFeedType.thread => ac.api.threads.list(
          FeedSource.user,
          sourceId: widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: widget.sort,
          usePreferredLangs: whenLoggedIn(
            context,
            ac.profile.useAccountLanguageFilter,
          ),
          langs: ac.profile.customLanguageFilter,
        ),
        UserFeedType.microblog => ac.api.microblogs.list(
          FeedSource.user,
          sourceId: widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: widget.sort,
          usePreferredLangs: whenLoggedIn(
            context,
            ac.profile.useAccountLanguageFilter,
          ),
          langs: ac.profile.customLanguageFilter,
        ),
        UserFeedType.comment => ac.api.comments.listFromUser(
          PostType.thread,
          widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: feedToCommentSortMap[widget.sort],
          usePreferredLangs: whenLoggedIn(
            context,
            ac.profile.useAccountLanguageFilter,
          ),
          langs: ac.profile.customLanguageFilter,
        ),
        UserFeedType.reply => ac.api.comments.listFromUser(
          PostType.microblog,
          widget.data!.id,
          page: nullIfEmpty(pageKey),
          sort: feedToCommentSortMap[widget.sort],
          usePreferredLangs: whenLoggedIn(
            context,
            ac.profile.useAccountLanguageFilter,
          ),
          langs: ac.profile.customLanguageFilter,
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

      if (!mounted) return;

      final currentItemIds =
          _pagingController.itemList?.map((post) => post.id) ?? [];
      List<dynamic> newItems = (switch (newPage) {
        PostListModel newPage =>
          newPage.items
              .where((element) => !currentItemIds.contains(element.id))
              .toList(),
        CommentListModel newPage =>
          newPage.items
              .where((element) => !currentItemIds.contains(element.id))
              .toList(),
        DetailedUserListModel newPage =>
          newPage.items
              .where((element) => !currentItemIds.contains(element.id))
              .toList(),
        Object _ => [],
      });

      _pagingController.appendPage(newItems, (switch (newPage) {
        PostListModel newPage => newPage.nextPage,
        CommentListModel newPage => newPage.nextPage,
        DetailedUserListModel newPage => newPage.nextPage,
        Object _ => null,
      }));
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<dynamic>(
              firstPageErrorIndicatorBuilder: (context) =>
                  FirstPageErrorIndicator(
                    error: _pagingController.error,
                    onTryAgain: _pagingController.retryLastFailedRequest,
                  ),
              newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
                error: _pagingController.error,
                onTryAgain: _pagingController.retryLastFailedRequest,
              ),
              itemBuilder: (context, item, index) {
                return switch (widget.mode) {
                  UserFeedType.thread || UserFeedType.microblog => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return PostPage(
                                initData: item,
                                onUpdate: (newValue) {
                                  var newList = _pagingController.itemList;
                                  newList![index] = newValue;
                                  setState(() {
                                    _pagingController.itemList = newList;
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                      child: PostItem(item, (newValue) {
                        var newList = _pagingController.itemList;
                        newList![index] = newValue;
                        setState(() {
                          _pagingController.itemList = newList;
                        });
                      }, isPreview: item.type == PostType.thread),
                    ),
                  ),
                  UserFeedType.comment || UserFeedType.reply => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: PostComment(
                      item,
                      (newValue) {
                        var newList = _pagingController.itemList;
                        newList![index] = newValue;
                        setState(() {
                          _pagingController.itemList = newList;
                        });
                      },
                      onClick: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return PostCommentScreen(item.postType, item.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  UserFeedType.follower ||
                  UserFeedType.following => ExploreScreenItem(item, (newValue) {
                    var newList = _pagingController.itemList;
                    newList![index] = newValue;
                    setState(() {
                      _pagingController.itemList = newList;
                    });
                  }),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
