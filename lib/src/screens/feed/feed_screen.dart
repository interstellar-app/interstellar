import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/create_screen.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/nav_drawer.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/floating_menu.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/scaffold.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:interstellar/src/widgets/subordinate_scroll.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedScreen extends StatefulWidget {
  final FeedAggregator? feed;
  final FeedSource? source;
  final int? sourceId;
  final String? title;
  final Widget? details;
  final DetailedCommunityModel? createPostCommunity;
  final ScrollController? scrollController;

  const FeedScreen({
    super.key,
    this.feed,
    this.source,
    this.sourceId,
    this.title,
    this.details,
    this.createPostCommunity,
    this.scrollController,
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

  final ExpandableController _drawerController = ExpandableController(
    initialExpanded: true,
  );
  NavDrawPersistentState? _navDrawPersistentState;

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
          FeedView.combined =>
            context.read<AppController>().profile.feedDefaultCombinedSort,
        };

  void _initNavExpanded() async {
    final initExpanded = await context.read<AppController>().expandNavDrawer;
    if (initExpanded != _drawerController.expanded) {
      if (!mounted) return;
      setState(() {
        _drawerController.toggle();
      });
    }
  }

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

    _initNavExpanded();

    () async {
      final drawerState = await fetchNavDrawerState(
        context.read<AppController>(),
      );
      if (!mounted) return;
      setState(() {
        _navDrawPersistentState = drawerState;
      });
    }();
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
          await pushRoute(
            context,
            builder: (context) =>
                CreateScreen(initCommunity: widget.createPostCommunity),
          );
        },
      ),
      feedActionSetFilter(context).withProps(
        whenLoggedIn(context, widget.source != null || widget.feed != null) ??
                true
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
          widget.feed == null &&
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
                    _view = FeedView.combined;
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
        controller: _drawerController,
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
              controller: widget.scrollController,
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, isScrolled) {
                final ac = context.read<AppController>();

                return [
                  SliverAppBar(
                    leading:
                        widget.sourceId == null &&
                            widget.feed == null &&
                            Breakpoints.isExpanded(context)
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _drawerController.toggle();
                              });
                              ac.setExpandNavDrawer(_drawerController.expanded);
                            },
                            icon: const Icon(Symbols.menu_rounded),
                          )
                        : null,
                    floating: ac.profile.hideFeedUIOnScroll,
                    pinned: !ac.profile.hideFeedUIOnScroll,
                    snap: ac.profile.hideFeedUIOnScroll,
                    title: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.feed != null
                            ? widget.feed!.name
                            : widget.title ??
                                  context
                                          .watch<AppController>()
                                          .selectedAccount +
                                      (context.watch<AppController>().isLoggedIn
                                          ? ''
                                          : ' (${l(context).guest})'),
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                      subtitle: Row(
                        children: [
                          Text(currentFeedModeOption.title),
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
                          feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
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
                                  feed: widget.feed,
                                  source: widget.source ?? _filter,
                                  sourceId: widget.sourceId,
                                  sort:
                                      _sort ??
                                      _defaultSortFromMode(FeedView.combined),
                                  view: FeedView.combined,
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
              : Duration(
                  milliseconds:
                      (300 /
                              context
                                  .read<AppController>()
                                  .profile
                                  .animationSpeed)
                          .toInt(),
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
        drawer: (widget.sourceId != null || widget.feed != null)
            ? null
            : NavDrawer(
                drawerState: _navDrawPersistentState,
                updateState: (NavDrawPersistentState? drawerState) async {
                  drawerState ??= await fetchNavDrawerState(
                    context.read<AppController>(),
                  );

                  if (!mounted) return;
                  setState(() {
                    _navDrawPersistentState = drawerState!;
                  });
                },
              ),
      ),
    );
  }
}

enum FeedView { threads, microblog, combined }

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
        value: FeedView.combined,
        title: l(context).combined,
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
      subItems: [
        if (isLemmy || isPiefed)
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
        if (isLemmy || isPiefed) ...[
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
        SelectionMenuItem(value: FeedSort.top, title: l(context).sort_top_all),
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
  final FeedAggregator? feed;
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
    this.feed,
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
  late final _pagingController =
      AdvancedPagingController<String, PostModel, (PostType, int)>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => (item.type, item.id),
        fetchPage: (pageKey) async {
          if (pageKey.isEmpty) _filterListWarnings.clear();

          var (newItems, nextPageKey) = await _tryFetchPage(pageKey);
          int emptyPageCount = 0;
          while ((emptyPageCount < 2) &&
              newItems.isEmpty &&
              nextPageKey != null &&
              nextPageKey.isNotEmpty) {
            (newItems, nextPageKey) = await _tryFetchPage(nextPageKey);
            emptyPageCount++;
          }
          if (!mounted) return (<PostModel>[], null);
          setState(() {
            _lastPageFilteredOut = newItems.isEmpty && nextPageKey != null;
          });
          return (newItems, newItems.isEmpty ? null : nextPageKey);
        },
      );
  SubordinateScrollController? _scrollController;
  ScrollDirection _scrollDirection = ScrollDirection.idle;

  // Map of postId to FilterList names for posts that match lists that are marked as warnings.
  // If a post matches any FilterList that is not shown with warning, then the post is not shown at all.
  final Map<(PostType, int), Set<String>> _filterListWarnings = {};

  int _lastVisibleIndex = 0;
  final _markAsReadDebounce = Debouncer(duration: Duration(milliseconds: 500));
  bool _lastPageFilteredOut = false;

  late FeedAggregator _aggregator;

  @override
  void initState() {
    super.initState();

    _aggregator =
        widget.feed?.clone() ??
        FeedAggregator(
          name: '',
          inputs: [
            FeedInputState(
              title: '',
              source: widget.source,
              sourceId: widget.sourceId,
            ),
          ],
        );

    _scrollController?.addListener(getScrollDirection);
  }

  void getScrollDirection() {
    final direction =
        _scrollController?.position.userScrollDirection ?? ScrollDirection.idle;
    if (direction != ScrollDirection.idle && direction != _scrollDirection) {
      setState(() {
        _scrollDirection = direction;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<(List<PostModel>, String?)> _tryFetchPage(String pageKey) async {
    final ac = context.read<AppController>();

    final page = await _aggregator.fetchPage(
      ac,
      pageKey,
      widget.view,
      widget.sort,
    );
    final newItems = page.$1;
    final nextPageKey = page.$2;

    final filterListActivations = ac.profile.filterLists;
    final items = newItems.where((post) {
      // Skip feed filters if it's an explore page
      if (widget.sourceId != null) return true;

      for (var filterListEntry in ac.filterLists.entries) {
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
    }).toList();

    return (
      items.where((item) => !(widget.hideReadPosts && item.read)).toList(),
      nextPageKey,
    );
  }

  void backToTop() {
    _scrollController?.animateTo(
      _scrollController?.position.minScrollExtent ?? 0,
      duration: Durations.long1,
      curve: Curves.easeInOut,
    );
  }

  void refresh() {
    _aggregator.refresh();
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
        widget.sourceId != oldWidget.sourceId ||
        widget.feed != oldWidget.feed) {
      _aggregator =
          widget.feed?.clone() ??
          FeedAggregator(
            name: '',
            inputs: [
              FeedInputState(
                title: '',
                source: widget.source,
                sourceId: widget.sourceId,
              ),
            ],
          );
      refresh();
    }
    _scrollController?.isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => refresh()),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (widget.details != null) SliverToBoxAdapter(child: widget.details),
          AdvancedPagingListener(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) => PagedSliverList(
              state: state,
              fetchNextPage: fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<PostModel>(
                firstPageErrorIndicatorBuilder: (context) =>
                    FirstPageErrorIndicator(
                      error: _pagingController.value.error,
                      onTryAgain: _pagingController.fetchNextPage,
                    ),
                newPageErrorIndicatorBuilder: (context) =>
                    NewPageErrorIndicator(
                      error: _pagingController.value.error,
                      onTryAgain: _pagingController.fetchNextPage,
                    ),
                noItemsFoundIndicatorBuilder: _lastPageFilteredOut
                    ? (context) =>
                          NoItemsFoundIndicator(onTryAgain: fetchNextPage)
                    : null,
                noMoreItemsIndicatorBuilder: _lastPageFilteredOut
                    ? (context) =>
                          NoItemsFoundIndicator(onTryAgain: fetchNextPage)
                    : null,
                itemBuilder: (context, item, index) {
                  void onPostTap() {
                    pushRoute(
                      context,
                      builder: (context) => PostPage(
                        initData: item,
                        onUpdate: (newValue) =>
                            _pagingController.updateItem(item, newValue),
                        userCanModerate: widget.userCanModerate,
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
                              final items = _pagingController.value.items;
                              if (items == null) return;

                              List<PostModel> readPosts = [];
                              for (int i = index; i >= 0; i--) {
                                final post = items[i];
                                if (post.read || readPosts.contains(i)) {
                                  continue;
                                }
                                readPosts.add(post);
                              }
                              if (readPosts.isNotEmpty) {
                                var postsMarkedAsRead = await context
                                    .read<AppController>()
                                    .markAsRead(readPosts, true);

                                _pagingController.mapItems(
                                  (oldItem) => postsMarkedAsRead.firstWhere(
                                    (newItem) =>
                                        (oldItem.type, oldItem.id) ==
                                        (newItem.type, newItem.id),
                                    orElse: () => oldItem,
                                  ),
                                );
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
                    child: PostItem(
                      item,
                      (newValue) =>
                          _pagingController.updateItem(item, newValue),
                      onTap: onPostTap,
                      isPreview: true,
                      onReply: whenLoggedIn(context, (body, lang) async {
                        await context.read<AppController>().api.comments.create(
                          item.type,
                          item.id,
                          body,
                          lang: lang,
                        );
                      }),
                      filterListWarnings:
                          _filterListWarnings[(item.type, item.id)],
                      userCanModerate: widget.userCanModerate,
                      isTopLevel: true,
                      isCompact: context
                          .watch<AppController>()
                          .profile
                          .compactMode,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _pagingController.dispose();
    super.dispose();
  }
}
