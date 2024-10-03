import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/explore_screen_item.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/screens/profile/messages/message_thread_screen.dart';
import 'package:interstellar/src/screens/profile/profile_edit_screen.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/star_button.dart';
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
    _sort = context.read<SettingsController>().defaultExploreFeedSort;

    if (_data == null) {
      context
          .read<SettingsController>()
          .api
          .users
          .get(
            widget.userId,
          )
          .then((value) => setState(() {
                _data = value;
              }));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const LoadingTemplate();
    }

    final user = _data!;
    final currentFeedSortOption = feedSortSelect(context).getOption(_sort);

    final globalName = user.name.contains('@')
        ? '@${user.name}'
        : '@${user.name}@${context.watch<SettingsController>().instanceHost}';

    final messageDraftController = context.watch<DraftsController>().auto(
        'message:${context.watch<SettingsController>().instanceHost}:${user.name}');

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Flexible(child: Text(user.name)),
              DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodySmall!.color),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•'),
                    ),
                    Icon(currentFeedSortOption.icon, size: 20),
                    const SizedBox(width: 2),
                    Text(currentFeedSortOption.title),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () async {
                  final newSort = await feedSortSelect(context)
                      .askSelection(context, _sort);

                  if (newSort != null && newSort != _sort) {
                    setState(() {
                      _sort = newSort;
                    });
                  }
                },
                icon: const Icon(Icons.sort),
              ),
            ),
          ],
        ),
        body: DefaultTabController(
          length: context.watch<SettingsController>().serverSoftware ==
                  ServerSoftware.lemmy
              ? 2
              : 6,
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
                        height: user.cover == null ? 100 : null,
                        child: user.cover != null
                            ? AdvancedImage(
                                user.cover!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Avatar(
                            user.avatar,
                            radius: 32,
                            borderRadius: 4,
                          ),
                        ),
                      ),
                      if (whenLoggedIn(context, true,
                              matchesUsername: user.name) !=
                          null)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextButton(
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return ProfileEditScreen(_data!,
                                    (DetailedUserModel? user) {
                                  setState(() {
                                    _data = user;
                                  });
                                });
                              })),
                              child: const Text('Edit'),
                            ),
                          ),
                        )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ??
                                        user.name.split('@').first,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      await Clipboard.setData(
                                        ClipboardData(
                                            text: user.name.contains('@')
                                                ? '@${user.name}'
                                                : '@${user.name}@${context.read<SettingsController>().instanceHost}'),
                                      );

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(l(context).copied),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Text(globalName),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                          'Joined: ${dateOnlyFormat(user.createdAt)}'),
                                      UserStatusIcons(
                                        cakeDay: user.createdAt,
                                        isBot: user.isBot,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (user.followersCount != null)
                              LoadingChip(
                                selected: user.isFollowedByUser ?? false,
                                icon: const Icon(Symbols.people_rounded),
                                label:
                                    Text(intFormat(user.followersCount ?? 0)),
                                onSelected:
                                    whenLoggedIn(context, (selected) async {
                                  var newValue = await context
                                      .read<SettingsController>()
                                      .api
                                      .users
                                      .follow(user.id, selected);
                                  setState(() {
                                    _data = newValue;
                                  });
                                  if (widget.onUpdate != null) {
                                    widget.onUpdate!(newValue);
                                  }
                                }),
                              ),
                            StarButton(globalName),
                            if (whenLoggedIn(context, true) == true)
                              LoadingIconButton(
                                onPressed: () async {
                                  final newValue = await context
                                      .read<SettingsController>()
                                      .api
                                      .users
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
                                icon: const Icon(Icons.block),
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(
                                      user.isBlockedByUser == true
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context).disabledColor),
                                ),
                              ),
                            if (!user.name.contains('@') &&
                                context
                                        .read<SettingsController>()
                                        .serverSoftware !=
                                    ServerSoftware.lemmy)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _messageController =
                                        TextEditingController();
                                  });
                                },
                                icon: const Icon(Icons.mail),
                                tooltip: 'Send message',
                              )
                          ],
                        ),
                        if (_messageController != null)
                          Column(children: [
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
                                    final newThread = await context
                                        .read<SettingsController>()
                                        .api
                                        .messages
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
                                            initData: newThread,
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                  label: Text(l(context).send),
                                )
                              ],
                            )
                          ]),
                        if (user.about != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Markdown(
                                user.about!,
                                getNameHost(context, user.name),
                              )),
                      ],
                    ),
                  ),
                ],
              )),
              SliverAppBar(
                automaticallyImplyLeading: false,
                title: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(
                      text: 'Threads',
                      icon: Icon(Icons.feed),
                    ),
                    if (context.watch<SettingsController>().serverSoftware !=
                        ServerSoftware.lemmy)
                      const Tab(
                        text: 'Microblogs',
                        icon: Icon(Icons.chat),
                      ),
                    const Tab(
                      text: 'Comments',
                      icon: Icon(Icons.comment),
                    ),
                    if (context.watch<SettingsController>().serverSoftware !=
                        ServerSoftware.lemmy)
                      const Tab(
                        text: 'Replies',
                        icon: Icon(Icons.comment),
                      ),
                    if (context.watch<SettingsController>().serverSoftware !=
                        ServerSoftware.lemmy)
                      const Tab(
                        text: 'Followers',
                        icon: Icon(Icons.people),
                      ),
                    if (context.watch<SettingsController>().serverSoftware !=
                        ServerSoftware.lemmy)
                      const Tab(
                        text: 'Following',
                        icon: Icon(Icons.groups),
                      )
                  ],
                ),
                pinned: true,
              )
            ],
            body: TabBarView(children: [
              UserScreenBody(
                mode: UserFeedType.thread,
                sort: _sort,
                data: _data,
              ),
              if (context.watch<SettingsController>().serverSoftware !=
                  ServerSoftware.lemmy)
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
              if (context.watch<SettingsController>().serverSoftware !=
                  ServerSoftware.lemmy)
                UserScreenBody(
                  mode: UserFeedType.reply,
                  sort: _sort,
                  data: _data,
                ),
              if (context.watch<SettingsController>().serverSoftware !=
                  ServerSoftware.lemmy)
                UserScreenBody(
                  mode: UserFeedType.follower,
                  sort: _sort,
                  data: _data,
                ),
              if (context.watch<SettingsController>().serverSoftware !=
                  ServerSoftware.lemmy)
                UserScreenBody(
                  mode: UserFeedType.following,
                  sort: _sort,
                  data: _data,
                ),
            ]),
          ),
        ));
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

class _UserScreenBodyState extends State<UserScreenBody> {
  final PagingController<String, dynamic> _pagingController =
      PagingController(firstPageKey: '');

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
        UserFeedType.thread =>
          context.read<SettingsController>().api.threads.list(
                FeedSource.user,
                sourceId: widget.data!.id,
                page: nullIfEmpty(pageKey),
                sort: widget.sort,
                usePreferredLangs: whenLoggedIn(context,
                    context.read<SettingsController>().useAccountLangFilter),
                langs: context.read<SettingsController>().langFilter.toList(),
              ),
        UserFeedType.microblog =>
          context.read<SettingsController>().api.microblogs.list(
                FeedSource.user,
                sourceId: widget.data!.id,
                page: nullIfEmpty(pageKey),
                sort: widget.sort,
                usePreferredLangs: whenLoggedIn(context,
                    context.read<SettingsController>().useAccountLangFilter),
                langs: context.read<SettingsController>().langFilter.toList(),
              ),
        UserFeedType.comment =>
          context.read<SettingsController>().api.comments.listFromUser(
                PostType.thread,
                widget.data!.id,
                page: nullIfEmpty(pageKey),
                sort: feedToCommentSortMap[widget.sort],
                usePreferredLangs: whenLoggedIn(context,
                    context.read<SettingsController>().useAccountLangFilter),
                langs: context.read<SettingsController>().langFilter.toList(),
              ),
        UserFeedType.reply =>
          context.read<SettingsController>().api.comments.listFromUser(
                PostType.microblog,
                widget.data!.id,
                page: nullIfEmpty(pageKey),
                sort: feedToCommentSortMap[widget.sort],
                usePreferredLangs: whenLoggedIn(context,
                    context.read<SettingsController>().useAccountLangFilter),
                langs: context.read<SettingsController>().langFilter.toList(),
              ),
        UserFeedType.follower =>
          context.read<SettingsController>().api.users.listFollowers(
                widget.data!.id,
                page: nullIfEmpty(pageKey),
              ),
        UserFeedType.following =>
          context.read<SettingsController>().api.users.listFollowing(
                widget.data!.id,
                page: nullIfEmpty(pageKey),
              ),
      });

      if (!mounted) return;

      final currentItemIds =
          _pagingController.itemList?.map((post) => post.id) ?? [];
      List<dynamic> newItems = (switch (newPage) {
        PostListModel newPage => newPage.items
            .where((element) => !currentItemIds.contains(element.id))
            .toList(),
        CommentListModel newPage => newPage.items
            .where((element) => !currentItemIds.contains(element.id))
            .toList(),
        DetailedUserListModel newPage => newPage.items
            .where((element) => !currentItemIds.contains(element.id))
            .toList(),
        Object _ => []
      });

      _pagingController.appendPage(
          newItems,
          (switch (newPage) {
            PostListModel newPage => newPage.nextPage,
            CommentListModel newPage => newPage.nextPage,
            DetailedUserListModel newPage => newPage.nextPage,
            Object _ => null
          }));
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<dynamic>(
                itemBuilder: (context, item, index) {
              return switch (widget.mode) {
                UserFeedType.thread || UserFeedType.microblog => Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) {
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
                            }),
                          );
                        },
                        child: PostItem(
                          item,
                          (newValue) {
                            var newList = _pagingController.itemList;
                            newList![index] = newValue;
                            setState(() {
                              _pagingController.itemList = newList;
                            });
                          },
                          isPreview: item.type == PostType.thread,
                        )),
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
                          MaterialPageRoute(builder: (context) {
                            return PostCommentScreen(item.postType, item.id);
                          }),
                        );
                      },
                    ),
                  ),
                UserFeedType.follower ||
                UserFeedType.following =>
                  ExploreScreenItem(item, (newValue) {
                    var newList = _pagingController.itemList;
                    newList![index] = newValue;
                    setState(() {
                      _pagingController.itemList = newList;
                    });
                  }),
              };
            }),
          )
        ],
      ),
    );
  }
}
