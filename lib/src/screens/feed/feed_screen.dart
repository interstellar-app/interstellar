import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/create_screen.dart';
import 'package:interstellar/src/screens/feed/nav_drawer.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/floating_menu.dart';
import 'package:interstellar/src/widgets/scaffold.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:interstellar/src/widgets/subordinate_scroll.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedScreen extends StatefulWidget {
  final FeedSource? source;
  final int? sourceId;
  final String? title;
  final Widget? details;
  final DetailedCommunityModel? createPostCommunity;

  const FeedScreen({
    super.key,
    this.source,
    this.sourceId,
    this.title,
    this.details,
    this.createPostCommunity,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin<FeedScreen> {
  final _fabKey = GlobalKey<FloatingMenuState>();
  final List<GlobalKey<_FeedScreenBodyState>> _feedKeyList = [];
  late FeedSource _filter;
  late FeedView _view;
  FeedSort? _sort;
  late bool _hideReadPosts;
  bool _isHidden = false;

  @override
  bool get wantKeepAlive => true;

  _getFeedKey(int index) {
    while (index >= _feedKeyList.length) {
      _feedKeyList.add(GlobalKey());
    }
    return _feedKeyList[index];
  }

  FeedSort _defaultSortFromMode(FeedView view) => widget.source != null
      ? context.read<AppController>().profile.feedDefaultExploreSort
      : switch (view) {
          FeedView.threads =>
            context.read<AppController>().profile.feedDefaultThreadsSort,
          FeedView.microblog =>
            context.read<AppController>().profile.feedDefaultMicroblogSort,
          FeedView.timeline => FeedSort.newest,
        };

  @override
  void initState() {
    super.initState();

    _filter =
        whenLoggedIn(
          context,
          context.read<AppController>().profile.feedDefaultFilter,
        ) ??
        FeedSource.all;
    _view = context.read<AppController>().serverSoftware == ServerSoftware.mbin
        ? context.read<AppController>().profile.feedDefaultView
        : FeedView.threads;
    _hideReadPosts = context
        .read<AppController>()
        .profile
        .feedDefaultHideReadPosts;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sort = _sort ?? _defaultSortFromMode(_view);

    final currentFeedModeOption = feedViewSelect(context).getOption(_view);
    final currentFeedSortOption = feedSortSelect(context).getOption(sort);

    // in community check if user is moderator
    // don't really need for mbin since mbin api returns
    // canAuthUserModerate with content items
    // lemmy and piefed don't return this info
    final localUserPart = context.read<AppController>().localName;
    final userCanModerate = widget.createPostCommunity == null
        ? false
        : widget.createPostCommunity!.moderators.any(
            (mod) => mod.name == localUserPart,
          );

    final actions = [
      feedActionCreateNew(context).withProps(
        context.watch<AppController>().isLoggedIn
            ? context.watch<AppController>().profile.feedActionCreateNew
            : ActionLocation.hide,
        () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CreateScreen(initCommunity: widget.createPostCommunity),
            ),
          );
        },
      ),
      feedActionSetFilter(context).withProps(
        whenLoggedIn(context, widget.source != null) ?? true
            ? ActionLocation.hide
            : parseEnum(
                ActionLocation.values,
                ActionLocation.hide,
                context.watch<AppController>().profile.feedActionSetFilter.name,
              ),
        () async {
          final newFilter = await feedFilterSelect(
            context,
          ).askSelection(context, _filter);

          if (newFilter != null && newFilter != _filter) {
            setState(() {
              _filter = newFilter;
            });
          }
        },
      ),
      feedActionSetSort(context).withProps(
        parseEnum(
          ActionLocation.values,
          ActionLocation.hide,
          context.watch<AppController>().profile.feedActionSetSort.name,
        ),
        () async {
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
      feedActionSetView(context).withProps(
        context.watch<AppController>().serverSoftware != ServerSoftware.mbin ||
                widget.source == FeedSource.domain
            ? ActionLocation.hide
            : parseEnum(
                ActionLocation.values,
                ActionLocation.hide,
                context.watch<AppController>().profile.feedActionSetView.name,
              ),
        () async {
          final newMode = await feedViewSelect(
            context,
          ).askSelection(context, _view);

          if (newMode != null && newMode != _view) {
            setState(() {
              _view = newMode;
            });
          }
        },
      ),
      feedActionRefresh(context).withProps(
        context.watch<AppController>().profile.feedActionRefresh,
        () {
          for (var key in _feedKeyList) {
            key.currentState?.refresh();
          }
        },
      ),
      feedActionBackToTop(context).withProps(
        context.watch<AppController>().profile.feedActionBackToTop,
        () {
          for (var key in _feedKeyList) {
            key.currentState?.backToTop();
          }
        },
      ),
      feedActionExpandFab(context).withProps(
        context.watch<AppController>().profile.feedActionExpandFab,
        () {
          _fabKey.currentState?.toggle();
        },
      ),
      _hideReadPosts
          ? feedActionShowReadPosts(context).withProps(
              context.watch<AppController>().profile.feedActionHideReadPosts,
              () => setState(() {
                _hideReadPosts = !_hideReadPosts;
                for (var key in _feedKeyList) {
                  key.currentState?.refresh();
                }
              }),
            )
          : feedActionHideReadPosts(context).withProps(
              context.watch<AppController>().profile.feedActionHideReadPosts,
              () => setState(() {
                _hideReadPosts = !_hideReadPosts;
                for (var key in _feedKeyList) {
                  key.currentState?.refresh();
                }
              }),
            ),
    ];

    final tabsAction = [
      if (context.watch<AppController>().profile.feedActionSetFilter ==
              ActionLocationWithTabs.tabs &&
          widget.source == null &&
          context.watch<AppController>().isLoggedIn)
        actions.firstWhere(
          (action) => action.name == feedActionSetFilter(context).name,
        ),
      if (context.watch<AppController>().profile.feedActionSetView ==
              ActionLocationWithTabs.tabs &&
          context.watch<AppController>().serverSoftware == ServerSoftware.mbin)
        actions.firstWhere(
          (action) => action.name == feedActionSetView(context).name,
        ),
    ].firstOrNull;

    return Wrapper(
      shouldWrap: tabsAction != null,
      parentBuilder: (child) => DefaultTabController(
        initialIndex: switch (tabsAction?.name) {
          String name when name == feedActionSetFilter(context).name =>
            feedFilterSelect(context).options
                .asMap()
                .entries
                .firstWhere(
                  (entry) =>
                      entry.value.value ==
                      context.watch<AppController>().profile.feedDefaultFilter,
                )
                .key,
          String name when name == feedActionSetView(context).name =>
            feedViewSelect(context).options
                .asMap()
                .entries
                .firstWhere(
                  (entry) =>
                      entry.value.value ==
                      (context.watch<AppController>().serverSoftware ==
                              ServerSoftware.mbin
                          ? context
                                .watch<AppController>()
                                .profile
                                .feedDefaultView
                          : FeedView.threads),
                )
                .key,
          _ => 0,
        },
        length: switch (tabsAction?.name) {
          String name when name == feedActionSetFilter(context).name =>
            feedFilterSelect(context).options.length,
          String name when name == feedActionSetView(context).name =>
            feedViewSelect(context).options.length,
          _ => 0,
        },
        child: DefaultTabControllerListener(
          onTabSelected: (newIndex) {
            setState(() {
              if (tabsAction?.name == feedActionSetView(context).name) {
                switch (newIndex) {
                  case 0:
                    _view = FeedView.threads;
                    break;
                  case 1:
                    _view = FeedView.microblog;
                    break;
                  case 2:
                    _view = FeedView.timeline;
                    break;
                  default:
                }
              }
            });
          },
          child: child,
        ),
      ),
      child: AdvancedScaffold(
        body: NotificationListener<UserScrollNotification>(
          onNotification: (scroll) {
            if (scroll.direction == ScrollDirection.forward) {
              if (_isHidden) {
                setState(() => _isHidden = false);
              }
            } else if (scroll.direction == ScrollDirection.reverse) {
              if (!_isHidden) {
                setState(() => _isHidden = true);
              }
            }
            return true;
          },
          child: SafeArea(
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, isScrolled) {
                final ac = context.read<AppController>();

                return [
                  SliverAppBar(
                    floating: ac.profile.hideFeedUIOnScroll,
                    pinned: !ac.profile.hideFeedUIOnScroll,
                    snap: ac.profile.hideFeedUIOnScroll,
                    title: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.title ??
                            context.watch<AppController>().selectedAccount +
                                (context.watch<AppController>().isLoggedIn
                                    ? ''
                                    : ' (${l(context).guest})'),
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                      subtitle: Row(
                        children: [
                          Text(currentFeedModeOption.title),
                          if (currentFeedModeOption.value !=
                              FeedView.timeline) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('•'),
                            ),
                            Icon(currentFeedSortOption.icon, size: 20),
                            const SizedBox(width: 2),
                            Text(currentFeedSortOption.title),
                          ],
                        ],
                      ),
                    ),
                    actions: actions
                        .where(
                          (action) => action.location == ActionLocation.appBar,
                        )
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              tooltip: action.name,
                              icon: Icon(action.icon),
                              onPressed: action.callback,
                            ),
                          ),
                        )
                        .toList(),
                    bottom: tabsAction == null
                        ? null
                        : TabBar(
                            tabs: switch (tabsAction.name) {
                              String name
                                  when name ==
                                      feedActionSetFilter(context).name =>
                                feedFilterSelect(context).options
                                    .map(
                                      (option) => Tab(
                                        text: option.title.substring(0, 3),
                                        icon: ac.profile.compactMode
                                            ? null
                                            : Icon(option.icon),
                                      ),
                                    )
                                    .toList(),
                              String name
                                  when name ==
                                      feedActionSetView(context).name =>
                                feedViewSelect(context).options
                                    .map(
                                      (option) => Tab(
                                        text: option.title,
                                        icon: ac.profile.compactMode
                                            ? null
                                            : Icon(option.icon),
                                      ),
                                    )
                                    .toList(),
                              _ => [],
                            },
                          ),
                  ),
                ];
              },
              body: Builder(
                builder: (context) {
                  final controller = tabsAction == null
                      ? null
                      : DefaultTabController.of(context);
                  return tabsAction == null
                      ? FeedScreenBody(
                          key: _getFeedKey(0),
                          source: widget.source ?? _filter,
                          sourceId: widget.sourceId,
                          sort: sort,
                          view: _view,
                          details: widget.details,
                          hideReadPosts: _hideReadPosts,
                          isActive: true,
                        )
                      : TabBarView(
                          physics: appTabViewPhysics(context),
                          children: switch (tabsAction.name) {
                            String name
                                when name ==
                                    feedActionSetFilter(context).name =>
                              [
                                FeedScreenBody(
                                  key: _getFeedKey(0),
                                  source: FeedSource.subscribed,
                                  sort: sort,
                                  view: _view,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 0,
                                ),
                                FeedScreenBody(
                                  key: _getFeedKey(1),
                                  source: FeedSource.moderated,
                                  sort: sort,
                                  view: _view,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 1,
                                ),
                                FeedScreenBody(
                                  key: _getFeedKey(2),
                                  source: FeedSource.favorited,
                                  sort: sort,
                                  view: _view,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 2,
                                ),
                                FeedScreenBody(
                                  key: _getFeedKey(3),
                                  source: FeedSource.all,
                                  sort: sort,
                                  view: _view,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 3,
                                ),
                                FeedScreenBody(
                                  key: _getFeedKey(4),
                                  source: FeedSource.local,
                                  sort: sort,
                                  view: _view,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 4,
                                ),
                              ],
                            String name
                                when name == feedActionSetView(context).name =>
                              [
                                FeedScreenBody(
                                  key: _getFeedKey(0),
                                  source: widget.source ?? _filter,
                                  sourceId: widget.sourceId,
                                  sort:
                                      _sort ??
                                      _defaultSortFromMode(FeedView.threads),
                                  view: FeedView.threads,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 0,
                                ),
                                FeedScreenBody(
                                  key: _getFeedKey(1),
                                  source: widget.source ?? _filter,
                                  sourceId: widget.sourceId,
                                  sort:
                                      _sort ??
                                      _defaultSortFromMode(FeedView.microblog),
                                  view: FeedView.microblog,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 1,
                                ),
                                FeedScreenBody(
                                  key: _getFeedKey(2),
                                  source: widget.source ?? _filter,
                                  sourceId: widget.sourceId,
                                  sort: FeedSort.newest,
                                  view: FeedView.timeline,
                                  details: widget.details,
                                  userCanModerate: userCanModerate,
                                  hideReadPosts: _hideReadPosts,
                                  isActive: controller?.index == 2,
                                ),
                              ],
                            _ => [],
                          },
                        );
                },
              ),
            ),
          ),
        ),
        floatingActionButton: AnimatedSlide(
          offset:
              _isHidden &&
                  context.read<AppController>().profile.hideFeedUIOnScroll
              ? Offset(0, 0.2)
              : Offset.zero,
          duration: context.read<AppController>().profile.animationSpeed == 0
              ? Duration.zero
              : Duration(milliseconds: (300 / context.read<AppController>()
                .profile.animationSpeed).toInt(),
                ),
          child: FloatingMenu(
            key: _fabKey,
            tapAction: actions
                .where((action) => action.location == ActionLocation.fabTap)
                .firstOrNull,
            holdAction: actions
                .where((action) => action.location == ActionLocation.fabHold)
                .firstOrNull,
            menuActions: actions
                .where((action) => action.location == ActionLocation.fabMenu)
                .toList(),
          ),
        ),
        drawer: widget.sourceId != null ? null : const NavDrawer(),
      ),
    );
  }
}

enum FeedView { threads, microblog, timeline }

SelectionMenu<FeedView> feedViewSelect(BuildContext context) =>
    SelectionMenu(l(context).feedView, [
      SelectionMenuItem(
        value: FeedView.threads,
        title: l(context).threads,
        icon: Symbols.feed_rounded,
      ),
      SelectionMenuItem(
        value: FeedView.microblog,
        title: l(context).microblog,
        icon: Symbols.chat_rounded,
      ),
      SelectionMenuItem(
        value: FeedView.timeline,
        title: l(context).timeline,
        icon: Symbols.view_timeline_rounded,
      ),
    ]);

SelectionMenu<FeedSort> feedSortSelect(BuildContext context) {
  final isLemmy =
      context.read<AppController>().serverSoftware == ServerSoftware.lemmy;
  final isPiefed =
      context.read<AppController>().serverSoftware == ServerSoftware.piefed;

  return SelectionMenu(l(context).sort, [
    SelectionMenuItem(
      value: FeedSort.hot,
      title: l(context).sort_hot,
      icon: Symbols.local_fire_department_rounded,
    ),
    SelectionMenuItem(
      value: FeedSort.top,
      title: l(context).sort_top,
      icon: Symbols.trending_up_rounded,
      subItems: isPiefed
          ? null
          : [
              if (isLemmy)
                SelectionMenuItem(
                  value: FeedSort.topHour,
                  title: l(context).sort_top_1h,
                ),
              if (!isLemmy && !isPiefed)
                SelectionMenuItem(
                  value: FeedSort.topThreeHour,
                  title: l(context).sort_top_3h,
                ),
              SelectionMenuItem(
                value: FeedSort.topSixHour,
                title: l(context).sort_top_6h,
              ),
              SelectionMenuItem(
                value: FeedSort.topTwelveHour,
                title: l(context).sort_top_12h,
              ),
              SelectionMenuItem(
                value: FeedSort.topDay,
                title: l(context).sort_top_1d,
              ),
              SelectionMenuItem(
                value: FeedSort.topWeek,
                title: l(context).sort_top_1w,
              ),
              SelectionMenuItem(
                value: FeedSort.topMonth,
                title: l(context).sort_top_1m,
              ),
              if (isLemmy) ...[
                SelectionMenuItem(
                  value: FeedSort.topThreeMonths,
                  title: l(context).sort_top_3m,
                ),
                SelectionMenuItem(
                  value: FeedSort.topSixMonths,
                  title: l(context).sort_top_6m,
                ),
                SelectionMenuItem(
                  value: FeedSort.topNineMonths,
                  title: l(context).sort_top_9m,
                ),
              ],
              SelectionMenuItem(
                value: FeedSort.topYear,
                title: l(context).sort_top_1y,
              ),
              SelectionMenuItem(
                value: FeedSort.top,
                title: l(context).sort_top_all,
              ),
            ],
    ),
    SelectionMenuItem(
      value: FeedSort.newest,
      title: l(context).sort_newest,
      icon: Symbols.nest_eco_leaf_rounded,
    ),
    SelectionMenuItem(
      value: FeedSort.active,
      title: l(context).sort_active,
      icon: Symbols.rocket_launch_rounded,
    ),

    // Not in PieFed
    if (!isPiefed) ...[
      SelectionMenuItem(
        value: FeedSort.commented,
        title: l(context).sort_commented,
        icon: Symbols.chat_rounded,
        subItems: isLemmy || isPiefed
            ? null
            : [
                SelectionMenuItem(
                  value: FeedSort.commentedThreeHour,
                  title: l(context).sort_commented_3h,
                ),
                SelectionMenuItem(
                  value: FeedSort.commentedSixHour,
                  title: l(context).sort_commented_6h,
                ),
                SelectionMenuItem(
                  value: FeedSort.commentedTwelveHour,
                  title: l(context).sort_commented_12h,
                ),
                SelectionMenuItem(
                  value: FeedSort.commentedDay,
                  title: l(context).sort_commented_1d,
                ),
                SelectionMenuItem(
                  value: FeedSort.commentedWeek,
                  title: l(context).sort_commented_1w,
                ),
                SelectionMenuItem(
                  value: FeedSort.commentedMonth,
                  title: l(context).sort_commented_1m,
                ),
                SelectionMenuItem(
                  value: FeedSort.commentedYear,
                  title: l(context).sort_commented_1y,
                ),
                SelectionMenuItem(
                  value: FeedSort.commented,
                  title: l(context).sort_commented_all,
                ),
              ],
      ),
      SelectionMenuItem(
        value: FeedSort.oldest,
        title: l(context).sort_oldest,
        icon: Symbols.access_time_rounded,
      ),
    ],

    if (isLemmy || isPiefed)
      SelectionMenuItem(
        value: FeedSort.scaled,
        title: l(context).sort_scaled,
        icon: Symbols.scale_rounded,
      ),

    // lemmy specific
    if (isLemmy) ...[
      SelectionMenuItem(
        value: FeedSort.newComments,
        title: l(context).sort_newComments,
        icon: Symbols.mark_chat_unread_rounded,
      ),
      SelectionMenuItem(
        value: FeedSort.controversial,
        title: l(context).sort_controversial,
        icon: Symbols.thumbs_up_down_rounded,
      ),
    ],
  ]);
}

SelectionMenu<FeedSource> feedFilterSelect(BuildContext context) =>
    SelectionMenu(l(context).filter, [
      SelectionMenuItem(
        value: FeedSource.subscribed,
        title: l(context).filter_subscribed,
        icon: Symbols.group_rounded,
      ),
      SelectionMenuItem(
        value: FeedSource.moderated,
        title: l(context).filter_moderated,
        icon: Symbols.lock_rounded,
      ),
      SelectionMenuItem(
        value: FeedSource.favorited,
        title: l(context).filter_favorited,
        icon: Symbols.favorite_rounded,
      ),
      SelectionMenuItem(
        value: FeedSource.all,
        title: l(context).filter_all,
        icon: Symbols.newspaper_rounded,
      ),
      SelectionMenuItem(
        value: FeedSource.local,
        title: l(context).filter_local,
        icon: Symbols.home_pin_rounded,
      ),
    ]);

class FeedScreenBody extends StatefulWidget {
  final FeedSource source;
  final int? sourceId;
  final FeedSort sort;
  final FeedView view;
  final Widget? details;
  final bool userCanModerate;
  final bool hideReadPosts;
  final bool isActive;

  const FeedScreenBody({
    super.key,
    required this.source,
    this.sourceId,
    required this.sort,
    required this.view,
    this.details,
    this.userCanModerate = false,
    this.hideReadPosts = false,
    this.isActive = false,
  });

  @override
  State<FeedScreenBody> createState() => _FeedScreenBodyState();
}

class _FeedScreenBodyState extends State<FeedScreenBody>
    with AutomaticKeepAliveClientMixin<FeedScreenBody> {
  final _pagingController = PagingController<String, PostModel>(
    firstPageKey: '',
  );
  SubordinateScrollController? _scrollController;
  ScrollDirection _scrollDirection = ScrollDirection.idle;

  // Map of postId to FilterList names for posts that match lists that are marked as warnings.
  // If a post matches any FilterList that is not shown with warning, then the post is not shown at all.
  final Map<(PostType, int), Set<String>> _filterListWarnings = {};

  PostType _timelineViewLeftoverType = PostType.thread;
  List<PostModel> _timelineViewLeftoverPosts = [];

  int _lastVisibleIndex = 0;
  final _markAsReadDebounce = Debouncer(duration: Duration(milliseconds: 500));
  bool _lastPageFilteredOut = false;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
    _scrollController?.addListener(getScrollDirection);
  }

  void getScrollDirection() {
    final direction =
        _scrollController?.position.userScrollDirection ?? ScrollDirection.idle;
    if (direction != ScrollDirection.idle) {
      setState(() {
        _scrollDirection = direction;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<(List<PostModel>, String?)> _tryFetchPage(String pageKey) async {
    List<PostModel> newItems;
    String? nextPageKey;
    switch (widget.view) {
      case FeedView.threads:
        final postListModel = await context
            .read<AppController>()
            .api
            .threads
            .list(
              widget.source,
              sourceId: widget.sourceId,
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

        newItems = postListModel.items;
        nextPageKey = postListModel.nextPage;

        break;

      case FeedView.microblog:
        final postListModel = await context
            .read<AppController>()
            .api
            .microblogs
            .list(
              widget.source,
              sourceId: widget.sourceId,
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

        newItems = postListModel.items;
        nextPageKey = postListModel.nextPage;

        break;

      case FeedView.timeline:
        final threadsFuture = context.read<AppController>().api.threads.list(
          widget.source,
          sourceId: widget.sourceId,
          page: nullIfEmpty(pageKey),
          sort: FeedSort.newest,
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
        final microblogFuture = context
            .read<AppController>()
            .api
            .microblogs
            .list(
              widget.source,
              sourceId: widget.sourceId,
              page: nullIfEmpty(pageKey),
              sort: FeedSort.newest,
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

        final [threadsResult, microblogResult] = await Future.wait([
          threadsFuture,
          microblogFuture,
        ]);

        final newThreads = [
          if (_timelineViewLeftoverType == PostType.thread)
            ..._timelineViewLeftoverPosts,
          ...threadsResult.items,
        ];
        final newMicroblog = [
          if (_timelineViewLeftoverType == PostType.microblog)
            ..._timelineViewLeftoverPosts,
          ...microblogResult.items,
        ];

        newItems = [];

        // While both lists still have items, keep popping the item from the front that is newer.
        while (newThreads.isNotEmpty && newMicroblog.isNotEmpty) {
          if (newThreads.first.createdAt.compareTo(
                newMicroblog.first.createdAt,
              ) >
              0) {
            newItems.add(newThreads.removeAt(0));
          } else {
            newItems.add(newMicroblog.removeAt(0));
          }
        }

        // Once one of the lists is drained out, if one of the next page's is null, then just add the rest of the items.
        if (threadsResult.nextPage == null ||
            microblogResult.nextPage == null) {
          newItems.addAll([...newThreads, ...newMicroblog]);
        } else {
          // Otherwise, store the leftover (unsorted) posts for next round.
          if (newThreads.isNotEmpty) {
            _timelineViewLeftoverType = PostType.thread;
            _timelineViewLeftoverPosts = newThreads;
          } else {
            _timelineViewLeftoverType = PostType.microblog;
            _timelineViewLeftoverPosts = newMicroblog;
          }
        }

        nextPageKey = threadsResult.nextPage ?? microblogResult.nextPage;

        break;
    }

    // Check BuildContext
    // if (!mounted) return;

    // Prevent duplicates
    final currentItemIds =
        _pagingController.itemList?.map((post) => (post.type, post.id)) ?? [];
    final filterListActivations = context
        .read<AppController>()
        .profile
        .filterLists;
    final items = newItems
        .where((post) => !currentItemIds.contains((post.type, post.id)))
        .where((post) {
          // Skip feed filters if it's an explore page
          if (widget.sourceId != null) return true;

          for (var filterListEntry
              in context.read<AppController>().filterLists.entries) {
            if (filterListActivations[filterListEntry.key] == true) {
              final filterList = filterListEntry.value;

              if ((post.title != null && filterList.hasMatch(post.title!)) ||
                  (post.body != null && filterList.hasMatch(post.body!))) {
                if (filterList.showWithWarning) {
                  if (!_filterListWarnings.containsKey((post.type, post.id))) {
                    _filterListWarnings[(post.type, post.id)] = {};
                  }

                  _filterListWarnings[(post.type, post.id)]!.add(
                    filterListEntry.key,
                  );
                } else {
                  return false;
                }
              }
            }
          }

          return true;
        })
        .toList();

    final ac = context.read<AppController>();

    final finalItems =
        ac.serverSoftware == ServerSoftware.lemmy && ac.isLoggedIn
        ? items
        : await Future.wait(
            items.map(
              (item) async =>
                  (await ac.isRead(item)) ? item.copyWith(read: true) : item,
            ),
          );

    return (
      finalItems.where((item) => !(widget.hideReadPosts && item.read)).toList(),
      nextPageKey,
    );
  }

  Future<void> _fetchPage(String pageKey, {bool toEnd = false}) async {
    if (pageKey.isEmpty) _filterListWarnings.clear();
    try {
      var (newItems, nextPageKey) = await _tryFetchPage(pageKey);
      int emptyPageCount = 0;
      while ((emptyPageCount < 2 || toEnd) &&
          newItems.isEmpty &&
          nextPageKey != null &&
          nextPageKey.isNotEmpty) {
        (newItems, nextPageKey) = await _tryFetchPage(nextPageKey);
        emptyPageCount++;
      }
      setState(() {
        _lastPageFilteredOut = newItems.isEmpty && nextPageKey != null;
      });
      _pagingController.appendPage(
        newItems,
        newItems.isEmpty ? null : nextPageKey,
      );
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void backToTop() {
    _scrollController?.animateTo(
      _scrollController?.position.minScrollExtent ?? 0,
      duration: Durations.long1,
      curve: Curves.easeInOut,
    );
  }

  void refresh() {
    _pagingController.refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentController = PrimaryScrollController.of(context);
    if (parentController != _scrollController?.parent) {
      _scrollController?.dispose();
      _scrollController = SubordinateScrollController(parent: parentController);
      _scrollController!.addListener(getScrollDirection);
      _scrollController!.isActive = widget.isActive;
    }
  }

  @override
  void didUpdateWidget(covariant FeedScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view != oldWidget.view ||
        widget.sort != oldWidget.sort ||
        widget.source != oldWidget.source ||
        widget.sourceId != oldWidget.sourceId) {
      _pagingController.refresh();
    }
    _scrollController?.isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (widget.details != null) SliverToBoxAdapter(child: widget.details),
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<PostModel>(
              firstPageErrorIndicatorBuilder: (context) =>
                  FirstPageErrorIndicator(
                    error: _pagingController.error,
                    onTryAgain: _pagingController.retryLastFailedRequest,
                  ),
              newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
                error: _pagingController.error,
                onTryAgain: _pagingController.retryLastFailedRequest,
              ),
              noItemsFoundIndicatorBuilder: _lastPageFilteredOut
                  ? (context) => NoItemsFoundIndicator(
                      nextPageKey: _pagingController.nextPageKey,
                      onTryAgain: _fetchPage,
                    )
                  : null,
              noMoreItemsIndicatorBuilder: _lastPageFilteredOut
                  ? (context) => NoItemsFoundIndicator(
                      nextPageKey: _pagingController.nextPageKey,
                      onTryAgain: _fetchPage,
                    )
                  : null,
              itemBuilder: (context, item, index) {
                void onPostTap() {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration:
                          context.read<AppController>()
                              .profile.animationSpeed == 0
                          ? Duration.zero
                          : Duration(
                              milliseconds:
                                  (300 / context.read<AppController>()
                                      .profile.animationSpeed).toInt(),
                            ),
                      reverseTransitionDuration:
                          context.read<AppController>()
                                .profile.animationSpeed == 0
                          ? Duration.zero
                          : Duration(
                              milliseconds:
                                  (300 / context.read<AppController>()
                                        .profile.animationSpeed).toInt(),
                            ),
                      pageBuilder: (context, _, __) => PostPage(
                        initData: item,
                        onUpdate: (newValue) {
                          var newList = _pagingController.itemList;
                          newList![index] = newValue;
                          setState(() {
                            _pagingController.itemList = newList;
                          });
                        },
                        userCanModerate: widget.userCanModerate,
                      ),
                    ),
                  );
                }

                return Wrapper(
                  shouldWrap:
                      (context
                              .read<AppController>()
                              .profile
                              .markThreadsReadOnScroll &&
                          widget.view == FeedView.threads) ||
                      (context
                              .read<AppController>()
                              .profile
                              .markMicroblogsReadOnScroll &&
                          widget.view == FeedView.microblog),
                  parentBuilder: (child) {
                    return VisibilityDetector(
                      key: Key(item.id.toString()),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (index <= _lastVisibleIndex &&
                            info.visibleFraction == 0 &&
                            _scrollDirection == ScrollDirection.reverse) {
                          _markAsReadDebounce.run(() async {
                            List<int> readPosts = [];
                            for (int i = index; i >= 0; i--) {
                              if (_pagingController.itemList == null) return;
                              final post = _pagingController.itemList![i];
                              if (post.read || readPosts.contains(i)) {
                                continue;
                              }
                              readPosts.add(i);
                            }
                            if (readPosts.isNotEmpty) {
                              var postsMarkedAsRead = await context
                                  .read<AppController>()
                                  .markAsRead(
                                    readPosts
                                        .map(
                                          (index) => _pagingController
                                              .itemList![index],
                                        )
                                        .toList(),
                                    true,
                                  );

                              var newList = _pagingController.itemList;
                              for (var (index, i) in readPosts.indexed) {
                                newList![i] = postsMarkedAsRead[index];
                              }
                              setState(() {
                                _pagingController.itemList = newList;
                              });
                            }
                          });
                        }

                        if (info.visibleFraction == 1) {
                          setState(() {
                            _lastVisibleIndex = index;
                          });
                        }
                      },
                      child: child,
                    );
                  },
                  child: context.watch<AppController>().profile.compactMode
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: item.read
                                    ? Theme.of(context).cardColor.darken(3)
                                    : null,
                              ),
                              child: PostItem(
                                item,
                                (newValue) {
                                  var newList = _pagingController.itemList;
                                  newList![index] = newValue;
                                  setState(() {
                                    _pagingController.itemList = newList;
                                  });
                                },
                                onReply: whenLoggedIn(context, (
                                  body,
                                  lang,
                                ) async {
                                  await context
                                      .read<AppController>()
                                      .api
                                      .comments
                                      .create(
                                        item.type,
                                        item.id,
                                        body,
                                        lang: lang,
                                      );
                                }),
                                onTap: onPostTap,
                                filterListWarnings:
                                    _filterListWarnings[(item.type, item.id)],
                                userCanModerate: widget.userCanModerate,
                                isTopLevel: true,
                                isCompact: true,
                              ),
                            ),
                            const Divider(height: 1, thickness: 1),
                          ],
                        )
                      : Card(
                          color: item.read
                              ? Theme.of(context).cardColor.darken(3)
                              : null,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: PostItem(
                            item,
                            (newValue) {
                              var newList = _pagingController.itemList;
                              newList![index] = newValue;
                              setState(() {
                                _pagingController.itemList = newList;
                              });
                            },
                            onTap: onPostTap,
                            isPreview: true,
                            onReply: whenLoggedIn(context, (body, lang) async {
                              await context
                                  .read<AppController>()
                                  .api
                                  .comments
                                  .create(item.type, item.id, body, lang: lang);
                            }),
                            filterListWarnings:
                                _filterListWarnings[(item.type, item.id)],
                            userCanModerate: widget.userCanModerate,
                            isTopLevel: true,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }
}
