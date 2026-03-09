import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/nav_drawer.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/floating_menu.dart';
import 'package:interstellar/src/widgets/hide_on_scroll.dart';
import 'package:interstellar/src/widgets/menus/feed_menu.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/scaffold.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/subordinate_scroll.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedDetails extends StatefulWidget {
  const FeedDetails({required this.feed, super.key, this.onUpdate});

  final FeedModel feed;
  final void Function(FeedModel)? onUpdate;

  @override
  State<FeedDetails> createState() => _FeedDetails();
}

class _FeedDetails extends State<FeedDetails> {
  late FeedModel _data;

  @override
  void initState() {
    super.initState();

    _data = widget.feed;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    final globalName = _data.name;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SubscriptionButton(
                    isSubscribed: _data.subscribed,
                    subscriptionCount: _data.subscriptionCount,
                    onSubscribe: (selected) async {
                      final newValue = await ac.api.feed.subscribe(
                        _data.id,
                        selected,
                      );

                      setState(() {
                        _data = newValue;
                      });
                      widget.onUpdate?.call(newValue);
                    },
                    followMode: false,
                  ),
                  // StarButton(globalName),
                  IconButton(
                    onPressed: () => showFeedMenu(
                      context,
                      feed: _data,
                      update: (newFeed) {
                        setState(() {
                          _data = newFeed;
                        });
                        widget.onUpdate?.call(newFeed);
                      },
                    ),
                    icon: const Icon(Symbols.more_vert_rounded),
                  ),
                ],
              ),
              // if (_data!.notificationControlStatus != null)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 8),
              //     child: NotificationControlSegment(
              //       _data!.notificationControlStatus!,
              //           (newStatus) async {
              //         await ac.api.notifications.updateControl(
              //           targetType: NotificationControlUpdateTargetType
              //               .community,
              //           targetId: _data!.id,
              //           status: newStatus,
              //         );
              //
              //         final newValue = _data!.copyWith(
              //           notificationControlStatus: newStatus,
              //         );
              //         setState(() {
              //           _data = newValue;
              //         });
              //         widget.onUpdate?.call(newValue);
              //       },
              //     ),
              //   ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (_data.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Avatar(_data.icon, radius: 32),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _data.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: _data.name.contains('@')
                                    ? '!${_data.name}'
                                    : '!${_data.name}@${ac.instanceHost}',
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
                      ],
                    ),
                  ),
                  if (constraints.maxWidth > 600) actions,
                ],
              ),
              if (constraints.maxWidth <= 600) actions,
              if (_data.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Markdown(
                    _data.description!,
                    getNameHost(context, _data.name),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

@RoutePage()
class HomeScreen extends FeedScreen {
  const HomeScreen({super.key, super.scrollController})
    : super(feedName: 'home');
}

@RoutePage()
class FeedScreen extends StatefulWidget {
  const FeedScreen({
    @PathParam('feedName') required this.feedName,
    super.key,
    this.feed,
    this.details,
    this.createPostCommunity,
    this.scrollController,
  });

  final String feedName;
  final FeedAggregator? feed;
  final Widget? details;
  final DetailedCommunityModel? createPostCommunity;
  final ScrollController? scrollController;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final ScrollController _scrollController;
  final _fabKey = GlobalKey<FloatingMenuState>();
  final List<GlobalKey<_FeedScreenBodyState>> _feedKeyList = [];
  late FeedSource _filter;
  late FeedView _view;
  FeedSort? _sort;
  late bool _hideReadPosts;

  final ExpandableController _drawerController = ExpandableController(
    initialExpanded: true,
  );
  NavDrawPersistentState? _navDrawPersistentState;

  GlobalKey<_FeedScreenBodyState> _getFeedKey(int index) {
    while (index >= _feedKeyList.length) {
      _feedKeyList.add(GlobalKey());
    }
    return _feedKeyList[index];
  }

  FeedSort _defaultSortFromMode(FeedView view) => widget.details != null
      ? context.read<AppController>().profile.feedDefaultExploreSort
      : switch (view) {
          FeedView.threads =>
            context.read<AppController>().profile.feedDefaultThreadsSort,
          FeedView.microblog =>
            context.read<AppController>().profile.feedDefaultMicroblogSort,
          FeedView.combined =>
            context.read<AppController>().profile.feedDefaultCombinedSort,
        };

  Future<void> _initNavExpanded() async {
    final initExpanded = await context.read<AppController>().expandNavDrawer;
    if (initExpanded != _drawerController.expanded) {
      if (!mounted) return;
      setState(_drawerController.toggle);
    }
  }

  List<Tab> _getFeedTabs(AppController ac, ActionItem tabsAction) {
    return switch (tabsAction.name) {
      final String name when name == feedActionSetFilter(context).name =>
        ac.profile.feedSourceOrder
            .map(
              (option) => Tab(
                text: option.title(context),
                icon: ac.profile.compactMode ? null : Icon(option.icon),
              ),
            )
            .toList(),
      final String name when name == feedActionSetView(context).name =>
        FeedView.match(
              values: ac.profile.feedViewOrder,
              software: ac.serverSoftware.bitFlag,
            )
            .map(
              (option) => Tab(
                text: option.title(context),
                icon: ac.profile.compactMode ? null : Icon(option.icon),
              ),
            )
            .toList(),
      final String name when name == feedActionSetSort(context).name =>
        FeedSort.match(
              values: ac.profile.feedSortOrder,
              software: ac.serverSoftware.bitFlag,
            )
            .map(
              (sort) => Tab(
                text: sort.title(context),
                icon: ac.profile.compactMode ? null : Icon(sort.icon),
              ),
            )
            .toList(),
      String() => throw UnimplementedError(),
    };
  }

  List<FeedScreenBody> _getFeedBodies(
    AppController ac,
    ActionItem tabsAction,
    bool userCanModerate,
    TabController? controller,
  ) {
    return switch (tabsAction.name) {
      final String name when name == feedActionSetFilter(context).name =>
        ac.profile.feedSourceOrder
            .mapIndexed(
              (index, feed) => FeedScreenBody(
                key: _getFeedKey(index),
                feed:
                    widget.feed ??
                    FeedAggregator.fromSingleSource(name: name, source: feed),
                sort: _sort ?? _defaultSortFromMode(_view),
                view: _view,
                details: widget.details,
                userCanModerate: userCanModerate,
                hideReadPosts: _hideReadPosts,
                isActive: controller?.index == index,
              ),
            )
            .toList(),
      final String name when name == feedActionSetView(context).name =>
        FeedView.match(
              values: ac.profile.feedViewOrder,
              software: ac.serverSoftware.bitFlag,
            )
            .mapIndexed(
              (index, view) => FeedScreenBody(
                key: _getFeedKey(index),
                feed:
                    widget.feed ??
                    FeedAggregator.fromSingleSource(
                      name: name,
                      source: _filter,
                    ),
                sort: _sort ?? _defaultSortFromMode(view),
                view: view,
                details: widget.details,
                userCanModerate: userCanModerate,
                hideReadPosts: _hideReadPosts,
                isActive: controller?.index == index,
              ),
            )
            .toList(),
      final String name when name == feedActionSetSort(context).name =>
        FeedSort.match(
              values: ac.profile.feedSortOrder,
              software: context.read<AppController>().serverSoftware.bitFlag,
            )
            .mapIndexed(
              (index, sort) => FeedScreenBody(
                key: _getFeedKey(index),
                feed:
                    widget.feed ??
                    FeedAggregator.fromSingleSource(
                      name: name,
                      source: _filter,
                    ),
                sort: sort,
                view: _view,
                details: widget.details,
                userCanModerate: userCanModerate,
                hideReadPosts: _hideReadPosts,
                isActive: controller?.index == index,
              ),
            )
            .toList(),
      String() => throw UnimplementedError(),
    };
  }

  @override
  void initState() {
    super.initState();

    _scrollController = widget.scrollController ?? ScrollController();

    _filter =
        whenLoggedIn(
          context,
          context.read<AppController>().profile.feedSourceOrder.first,
        ) ??
        FeedSource.all;
    _view = FeedView.match(
      values: context.read<AppController>().profile.feedViewOrder,
      software: context.read<AppController>().serverSoftware.bitFlag,
    ).first;
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
    final sort = _sort ?? _defaultSortFromMode(_view);

    final ac = context.watch<AppController>();

    // in community check if user is moderator
    // don't really need for mbin since mbin api returns
    // canAuthUserModerate with content items
    // lemmy and piefed don't return this info
    final localUserPart = ac.localName;
    final userCanModerate =
        !(widget.createPostCommunity == null) &&
        widget.createPostCommunity!.moderators.any(
          (mod) => mod.name == localUserPart,
        );

    final actions = [
      feedActionCreateNew(context).withProps(
        ac.isLoggedIn ? ac.profile.feedActionCreateNew : ActionLocation.hide,
        () => context.router.push(
          CreateRoute(initCommunity: widget.createPostCommunity),
        ),
      ),
      feedActionSetFilter(context).withProps(
        whenLoggedIn(context, widget.feed != null) ?? true
            ? ActionLocation.hide
            : parseEnum(
                ActionLocation.values,
                ActionLocation.hide,
                ac.profile.feedActionSetFilter.name,
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
          ac.profile.feedActionSetSort.name,
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
        ac.serverSoftware != ServerSoftware.mbin ||
                widget.feed?.inputs.firstOrNull?.source == FeedSource.domain
            ? ActionLocation.hide
            : parseEnum(
                ActionLocation.values,
                ActionLocation.hide,
                ac.profile.feedActionSetView.name,
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
      feedActionRefresh(context).withProps(ac.profile.feedActionRefresh, () {
        for (final key in _feedKeyList) {
          key.currentState?.refresh();
        }
      }),
      feedActionBackToTop(context).withProps(
        ac.profile.feedActionBackToTop,
        () {
          for (final key in _feedKeyList) {
            key.currentState?.backToTop();
          }
        },
      ),
      feedActionExpandFab(context).withProps(
        ac.profile.feedActionExpandFab,
        () {
          _fabKey.currentState?.toggle();
        },
      ),
      if (_hideReadPosts)
        feedActionShowReadPosts(context).withProps(
          ac.profile.feedActionHideReadPosts,
          () => setState(() {
            _hideReadPosts = !_hideReadPosts;
            for (final key in _feedKeyList) {
              key.currentState?.refresh();
            }
          }),
        )
      else
        feedActionHideReadPosts(context).withProps(
          ac.profile.feedActionHideReadPosts,
          () => setState(() {
            _hideReadPosts = !_hideReadPosts;
            for (final key in _feedKeyList) {
              key.currentState?.refresh();
            }
          }),
        ),
    ];

    final tabsAction = [
      if (ac.profile.feedActionSetFilter == ActionLocationWithTabs.tabs &&
          widget.feed == null &&
          ac.isLoggedIn)
        actions.firstWhere(
          (action) => action.name == feedActionSetFilter(context).name,
        ),
      if (ac.profile.feedActionSetView == ActionLocationWithTabs.tabs &&
          ac.serverSoftware == ServerSoftware.mbin)
        actions.firstWhere(
          (action) => action.name == feedActionSetView(context).name,
        ),
      if (ac.profile.feedActionSetSort == ActionLocationWithTabs.tabs)
        actions.firstWhere(
          (action) => action.name == feedActionSetSort(context).name,
        ),
    ].firstOrNull;

    final tabs = tabsAction == null ? null : _getFeedTabs(ac, tabsAction);

    return Wrapper(
      shouldWrap: tabsAction != null,
      parentBuilder: (child) => DefaultTabController(
        initialIndex: switch (tabsAction?.name) {
          final String name when name == feedActionSetSort(context).name =>
            tabs
                    ?.asMap()
                    .entries
                    .firstWhereOrNull(
                      (sort) => widget.details != null
                          ? sort.value.text?.toLowerCase() ==
                                ac.profile.feedDefaultExploreSort.name
                          : sort.value.text?.toLowerCase() ==
                                (switch (_view) {
                                  FeedView.threads =>
                                    ac.profile.feedDefaultThreadsSort.name,
                                  FeedView.microblog =>
                                    ac.profile.feedDefaultMicroblogSort.name,
                                  FeedView.combined =>
                                    ac.profile.feedDefaultCombinedSort.name,
                                }),
                    )
                    ?.key ??
                0,
          _ => 0,
        },
        length: tabs?.length ?? 0,
        child: DefaultTabControllerListener(
          onTabSelected: (newIndex) {
            setState(() {});
          },
          child: child,
        ),
      ),
      child: AdvancedScaffold(
        controller: _drawerController,
        body: SafeArea(
          child: NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, isScrolled) {
              final currentFeedViewOption =
                  tabsAction?.name == feedActionSetView(context).name
                  ? FeedView.match(
                      values: ac.profile.feedViewOrder,
                      software: ac.serverSoftware.bitFlag,
                    )[DefaultTabController.of(context).index]
                  : feedViewSelect(context).getOption(_view).value;
              final currentFeedSortOption =
                  tabsAction?.name == feedActionSetSort(context).name
                  ? ac.profile.feedSortOrder[DefaultTabController.of(
                      context,
                    ).index]
                  : feedSortSelect(context).getOption(sort).value;
              return [
                SliverAppBar(
                  leading:
                      widget.feed == null && Breakpoints.isExpanded(context)
                      ? IconButton(
                          onPressed: () {
                            setState(_drawerController.toggle);
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
                          : ac.selectedAccount +
                                (ac.isLoggedIn ? '' : ' (${l(context).guest})'),
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                    subtitle: Row(
                      children: [
                        Text(currentFeedViewOption.title(context)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('•'),
                        ),
                        Icon(currentFeedSortOption.icon, size: 20),
                        const SizedBox(width: 2),
                        Text(currentFeedSortOption.title(context)),
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
                  bottom: tabsAction == null || tabs == null
                      ? null
                      : TabBar(
                          tabAlignment: tabs.length > 5
                              ? TabAlignment.start
                              : null,
                          isScrollable: tabs.length > 5,
                          tabs: tabs,
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
                        feed:
                            widget.feed ??
                            FeedAggregator.fromSingleSource(
                              name: widget.feed?.name ?? '',
                              source: _filter,
                            ),
                        sort: sort,
                        view: _view,
                        details: widget.details,
                        hideReadPosts: _hideReadPosts,
                        isActive: true,
                      )
                    : TabBarView(
                        physics: appTabViewPhysics(context),
                        children: _getFeedBodies(
                          ac,
                          tabsAction,
                          userCanModerate,
                          controller,
                        ),
                      );
              },
            ),
          ),
        ),
        floatingActionButton: Wrapper(
          shouldWrap: ac.profile.hideFeedUIOnScroll,
          parentBuilder: (child) => HideOnScroll(
            controller: _scrollController,
            hiddenOffset: const Offset(0, 0.2),
            duration: ac.calcAnimationDuration(),
            child: child,
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
        drawer: (widget.feed != null)
            ? null
            : NavDrawer(
                drawerState: _navDrawPersistentState,
                updateState: (NavDrawPersistentState? drawerState) async {
                  drawerState ??= await fetchNavDrawerState(ac);

                  if (!mounted) return;
                  setState(() {
                    _navDrawPersistentState = drawerState;
                  });
                },
              ),
      ),
    );
  }
}

SelectionMenu<FeedView> feedViewSelect(BuildContext context) => SelectionMenu(
  l(context).feedView,
  FeedView.match(
        values: context.read<AppController>().profile.feedViewOrder,
        software: context.read<AppController>().serverSoftware.bitFlag,
      )
      .map(
        (view) => SelectionMenuItem(
          value: view,
          title: view.title(context),
          icon: view.icon,
        ),
      )
      .toList(),
);

List<SelectionMenuItem<FeedSort>> getSortItemsSelect(
  BuildContext context,
  int software,
  FeedSort? sort,
) {
  return FeedSort.match(
        values: context.read<AppController>().profile.feedSortOrder,
        software: software,
        parent: sort,
        flat: false,
      )
      .map(
        (item) => SelectionMenuItem<FeedSort>(
          title: item.title(context),
          value: item,
          icon: item.icon,
          subItems: getSortItemsSelect(context, software, item),
        ),
      )
      .toList();
}

SelectionMenu<FeedSort> feedSortSelect(BuildContext context) {
  final software = context.read<AppController>().serverSoftware.bitFlag;

  return SelectionMenu(
    l(context).sort,
    getSortItemsSelect(context, software, null),
  );
}

SelectionMenu<FeedSource> feedFilterSelect(BuildContext context) =>
    SelectionMenu(
      l(context).filter,
      context
          .read<AppController>()
          .profile
          .feedSourceOrder
          .map(
            (source) => SelectionMenuItem(
              value: source,
              title: source.title(context),
              icon: source.icon,
            ),
          )
          .toList(),
    );

class FeedScreenBody extends StatefulWidget {
  const FeedScreenBody({
    required this.feed,
    required this.sort,
    required this.view,
    super.key,
    this.details,
    this.userCanModerate = false,
    this.hideReadPosts = false,
    this.isActive = false,
  });
  final FeedAggregator feed;
  final FeedSort sort;
  final FeedView view;
  final Widget? details;
  final bool userCanModerate;
  final bool hideReadPosts;
  final bool isActive;

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
          var emptyPageCount = 0;
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
          return (newItems, nextPageKey);
        },
      );
  SubordinateScrollController? _scrollController;
  ScrollDirection _scrollDirection = ScrollDirection.idle;

  // Map of postId to FilterList names for posts that match lists that are marked as warnings.
  // If a post matches any FilterList that is not shown with warning, then the post is not shown at all.
  final Map<(PostType, int), Set<String>> _filterListWarnings = {};

  int _lastVisibleIndex = 0;
  final _markAsReadDebounce = Debouncer(
    duration: const Duration(milliseconds: 500),
  );
  bool _lastPageFilteredOut = false;

  late FeedAggregator _aggregator;

  @override
  void initState() {
    super.initState();

    _aggregator = widget.feed.clone();

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
    if (!mounted) return (<PostModel>[], null);
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
      // if (widget.sourceId != null) return true;

      for (final filterListEntry in ac.filterLists.entries) {
        if (filterListActivations[filterListEntry.key] ?? false) {
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
        widget.feed != oldWidget.feed) {
      _aggregator = widget.feed.clone();
      refresh();
    }
    _scrollController?.isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => Future.sync(refresh),
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
                    pushPostPage(
                      context,
                      communityName: item.community.name,
                      initData: item,
                      userCanModerate: widget.userCanModerate,
                      onUpdate: (newValue) =>
                          _pagingController.updateItem(item, newValue),
                    );
                  }

                  return Wrapper(
                    shouldWrap:
                        (ac.profile.markThreadsReadOnScroll &&
                            widget.view == FeedView.threads) ||
                        (ac.profile.markMicroblogsReadOnScroll &&
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

                              final readPosts = <PostModel>[];
                              for (var i = index; i >= 0; i--) {
                                final post = items[i];
                                if (post.read || readPosts.contains(post)) {
                                  continue;
                                }
                                readPosts.add(post);
                              }
                              if (readPosts.isNotEmpty) {
                                final postsMarkedAsRead = await ac.markAsRead(
                                  readPosts,
                                  true,
                                );

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
                      onReply: whenLoggedIn(context, (
                        body,
                        lang, {
                        XFile? image,
                        String? alt,
                      }) async {
                        await ac.api.comments.create(
                          item.type,
                          item.id,
                          body,
                          lang: lang,
                          image: image,
                          alt: alt,
                        );
                      }),
                      filterListWarnings:
                          _filterListWarnings[(item.type, item.id)],
                      userCanModerate: widget.userCanModerate,
                      isTopLevel: true,
                      isCompact: ac.profile.compactMode,
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
