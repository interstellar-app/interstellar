import 'package:flutter/material.dart';
import 'package:interstellar/src/api/community.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/explore/explore_screen_item.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/hide_on_scroll.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/models/feed.dart';

class ExploreScreen extends StatefulWidget {
  final ExploreType? mode;
  final int? id;
  final bool subOnly;
  final FocusNode? focusNode;
  final void Function(bool, dynamic)? onTap;
  final Set<String>? selected;
  final String? title;

  const ExploreScreen({
    this.mode,
    this.id,
    this.subOnly = false,
    this.focusNode,
    this.onTap,
    this.selected,
    this.title,
    super.key,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin<ExploreScreen> {
  late FocusNode _focusNode;
  String search = '';
  final searchDebounce = Debouncer(duration: const Duration(milliseconds: 500));
  Set<String>? _selected;

  ExploreType type = ExploreType.communities;

  APIExploreSort sort = APIExploreSort.hot;
  ExploreFilter filter = ExploreFilter.all;

  late final _pagingController = AdvancedPagingController<String, dynamic, int>(
    logger: context.read<AppController>().logger,
    firstPageKey: '',
    // TODO: this is not safe, items of different types (comment, microblog, etc.) could have the same id
    getItemId: (item) => item.id,
    fetchPage: (pageKey) async {
      final ac = context.read<AppController>();

      final searchType = widget.id != null ? ExploreType.all : type;

      if (searchType == ExploreType.all && search.isEmpty) {
        return ([], null);
      }

      switch (searchType) {
        case ExploreType.communities:
          final newPage = await ac.api.community.list(
            page: nullIfEmpty(pageKey),
            filter: filter,
            sort: sort,
            search: nullIfEmpty(search),
          );

          return (newPage.items, newPage.nextPage);

        case ExploreType.people:
          // Lemmy cannot search with an empty query
          if ((context.read<AppController>().serverSoftware !=
                  ServerSoftware.mbin) &&
              search.isEmpty) {
            return ([], null);
          }

          final newPage = await ac.api.users.list(
            page: nullIfEmpty(pageKey),
            filter: filter,
            search: search,
          );

          return (newPage.items, newPage.nextPage);

        case ExploreType.domains:
          final newPage = await ac.api.domains.list(
            page: nullIfEmpty(pageKey),
            filter: filter,
            search: nullIfEmpty(search),
          );

          return (newPage.items, newPage.nextPage);

        case ExploreType.feeds:
        case ExploreType.topics:
          final newPage = await ac.api.feed.list(
            topics: type == ExploreType.topics,
          );

          return (newPage.items, null);

        case ExploreType.all:
          final newPage = await ac.api.search.get(
            page: nullIfEmpty(pageKey),
            search: search,
            userId: type == ExploreType.people ? widget.id : null,
            communityId: type == ExploreType.communities ? widget.id : null,
          );

          return (newPage.items, newPage.nextPage);
      }
    },
  );
  late final ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _focusNode = widget.focusNode ?? FocusNode();

    _selected = widget.selected;

    if (widget.mode != null) {
      type = widget.mode!;
    }
    if (widget.subOnly) {
      filter = ExploreFilter.subscribed;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const chipPadding = EdgeInsets.symmetric(vertical: 6, horizontal: 4);

    final currentExploreSort = exploreSortSelection(context).getOption(sort);
    final currentExploreFilter = exploreFilterSelection(
      context,
      type,
    ).getOption(filter);

    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              switch (widget.mode) {
                ExploreType.communities => l(context).subscriptions_community,
                ExploreType.people => l(context).subscriptions_user,
                ExploreType.domains => l(context).subscriptions_domain,
                _ =>
                  _selected != null
                      ? l(context).feeds_selectInputs
                      : '${l(context).explore} ${ac.instanceHost}',
              },
        ),
      ),
      body: AdvancedPagedScrollView(
        controller: _pagingController,
        scrollController: _scrollController,
        leadingSlivers: [
          if (!widget.subOnly &&
              widget.mode != ExploreType.feeds &&
              widget.mode != ExploreType.topics)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: search,
                      onChanged: (newSearch) {
                        searchDebounce.run(() {
                          search = newSearch;
                          _pagingController.refresh();
                        });
                      },
                      enabled:
                          !(ac.serverSoftware == ServerSoftware.mbin &&
                              (filter != ExploreFilter.all &&
                                  filter != ExploreFilter.local)) &&
                          (type != ExploreType.feeds &&
                              type != ExploreType.topics),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Symbols.search_rounded),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        filled: true,
                        hintText: l(context).searchTheFediverse,
                      ),
                      focusNode: _focusNode,
                      onTapOutside: (event) {
                        _focusNode.unfocus();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (widget.mode == null)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: Text(l(context).communities),
                              selected: type == ExploreType.communities,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    type = ExploreType.communities;
                                    _pagingController.refresh();
                                  });
                                }
                              },
                              padding: chipPadding,
                            ),
                            const SizedBox(width: 4),
                            ChoiceChip(
                              label: Text(l(context).people),
                              selected: type == ExploreType.people,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    type = ExploreType.people;

                                    // Reset explore filter in the following cases:
                                    if (
                                    // Using Mbin and filter is set to local
                                    ac.serverSoftware == ServerSoftware.mbin &&
                                            filter == ExploreFilter.local ||
                                        // Using Lemmy or PieFed and filter is set to subscribed
                                        ac.serverSoftware !=
                                                ServerSoftware.mbin &&
                                            filter ==
                                                ExploreFilter.subscribed ||
                                        // Using Lemmy or PieFed and filter is set to moderated
                                        ac.serverSoftware !=
                                                ServerSoftware.mbin &&
                                            filter == ExploreFilter.moderated) {
                                      filter = ExploreFilter.all;
                                    }

                                    _pagingController.refresh();
                                  });
                                }
                              },
                              padding: chipPadding,
                            ),
                            const SizedBox(width: 4),
                            if (ac.serverSoftware == ServerSoftware.mbin &&
                                _selected == null) ...[
                              ChoiceChip(
                                label: Text(l(context).domains),
                                selected: type == ExploreType.domains,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      type = ExploreType.domains;

                                      if (filter == ExploreFilter.local ||
                                          filter == ExploreFilter.moderated) {
                                        filter = ExploreFilter.all;
                                      }
                                      _pagingController.refresh();
                                    });
                                  }
                                },
                                padding: chipPadding,
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (ac.serverSoftware == ServerSoftware.piefed) ...[
                              ChoiceChip(
                                label: Text(l(context).feeds),
                                selected: type == ExploreType.feeds,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      type = ExploreType.feeds;
                                      _pagingController.refresh();
                                    });
                                  }
                                },
                                padding: chipPadding,
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: Text(l(context).topics),
                                selected: type == ExploreType.topics,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      type = ExploreType.topics;
                                      _pagingController.refresh();
                                    });
                                  }
                                },
                                padding: chipPadding,
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (_selected == null) ...[
                              ChoiceChip(
                                label: Text(l(context).filter_all),
                                selected: type == ExploreType.all,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      if (ac.serverSoftware ==
                                              ServerSoftware.mbin ||
                                          ac.serverSoftware !=
                                                  ServerSoftware.mbin &&
                                              filter ==
                                                  ExploreFilter.subscribed) {
                                        filter = ExploreFilter.all;
                                      }

                                      type = ExploreType.all;

                                      _pagingController.refresh();
                                    });
                                  }
                                },
                                padding: chipPadding,
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ActionChip(
                          padding: chipDropdownPadding,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(currentExploreFilter.icon, size: 20),
                              const SizedBox(width: 4),
                              Text(currentExploreFilter.title),
                              const Icon(Symbols.arrow_drop_down_rounded),
                            ],
                          ),
                          onPressed:
                              ac.serverSoftware == ServerSoftware.mbin &&
                                      type == ExploreType.all ||
                                  type == ExploreType.feeds ||
                                  type == ExploreType.topics
                              ? null
                              : () async {
                                  final result = await exploreFilterSelection(
                                    context,
                                    type,
                                  ).askSelection(context, filter);

                                  if (result != null) {
                                    setState(() {
                                      filter = result;
                                      _pagingController.refresh();
                                    });
                                  }
                                },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          padding: chipDropdownPadding,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(currentExploreSort.icon, size: 20),
                              const SizedBox(width: 4),
                              Text(currentExploreSort.title),
                              const Icon(Symbols.arrow_drop_down_rounded),
                            ],
                          ),
                          // For Mbin, sorting only works for communities, and only
                          // when the all or local filters are enabled
                          onPressed:
                              ac.serverSoftware == ServerSoftware.mbin &&
                                      ((filter != ExploreFilter.all &&
                                              filter != ExploreFilter.local) ||
                                          type != ExploreType.communities) ||
                                  type == ExploreType.feeds ||
                                  type == ExploreType.topics
                              ? null
                              : () async {
                                  final result = await exploreSortSelection(
                                    context,
                                  ).askSelection(context, sort);

                                  if (result != null) {
                                    setState(() {
                                      sort = result;
                                      _pagingController.refresh();
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        itemBuilder: (context, item, index) {
          final selected = _selected?.contains(switch (item) {
            DetailedCommunityModel i => i.name,
            DetailedUserModel i => i.name,
            DomainModel i => i.name,
            FeedModel i => i.name,
            _ => '',
          });

          onSelect(bool selected) {
            widget.onTap!(selected, item);
            final name = switch (item) {
              DetailedCommunityModel i => i.name,
              DetailedUserModel i => i.name,
              DomainModel i => i.name,
              FeedModel i => i.name,
              _ => null,
            };
            if (name == null) return;
            setState(() {
              if (selected) {
                _selected!.add(name);
              } else {
                _selected!.remove(name);
              }
            });
          }

          return ExploreScreenItem(
            item,
            (newValue) => _pagingController.updateItem(item, newValue),
            onTap: _selected == null
                ? widget.onTap == null
                      ? null
                      : () => widget.onTap!(true, item)
                : () => onSelect(!selected!),
            button: _selected == null || widget.onTap == null
                ? null
                : Checkbox(
                    value: selected!,
                    onChanged: (newValue) => onSelect(newValue!),
                  ),
          );
        },
      ),
      floatingActionButton: Wrapper(
        shouldWrap: ac.profile.hideFeedUIOnScroll,
        parentBuilder: (child) => HideOnScroll(
          controller: _scrollController,
          hiddenOffset: Offset(0, 1.5),
          duration: ac.calcAnimationDuration(),
          child: child,
        ),
        child: FloatingActionButton(
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

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

enum ExploreType { communities, people, domains, feeds, topics, all }

enum ExploreFilter {
  all,
  local,
  subscribed, // Also counts as followed filter
  moderated, // Also counts as followers filter
  blocked,
}

SelectionMenu<ExploreFilter> exploreFilterSelection(
  BuildContext context,
  ExploreType type,
) => SelectionMenu(l(context).sort, [
  SelectionMenuItem(
    value: ExploreFilter.all,
    title: l(context).filter_allResults,
    icon: Symbols.newspaper_rounded,
  ),
  if (context.read<AppController>().serverSoftware != ServerSoftware.mbin ||
      type == ExploreType.communities)
    SelectionMenuItem(
      value: ExploreFilter.local,
      title: l(context).filter_local,
      icon: Symbols.home_rounded,
    ),
  ...(whenLoggedIn(context, [
        if (context.read<AppController>().serverSoftware ==
                ServerSoftware.mbin ||
            type == ExploreType.communities)
          SelectionMenuItem(
            value: ExploreFilter.subscribed,
            title: type == ExploreType.people
                ? l(context).filter_followed
                : l(context).filter_subscribed,
            icon: Symbols.people_rounded,
          ),
        if (type != ExploreType.domains &&
            (context.read<AppController>().serverSoftware ==
                    ServerSoftware.mbin ||
                type != ExploreType.people))
          SelectionMenuItem(
            value: ExploreFilter.moderated,
            title: type == ExploreType.people
                ? l(context).filter_followers
                : l(context).filter_moderated,
            icon: Symbols.lock_rounded,
          ),
        if (context.read<AppController>().serverSoftware == ServerSoftware.mbin)
          SelectionMenuItem(
            value: ExploreFilter.blocked,
            title: l(context).filter_blocked,
            icon: Symbols.block_rounded,
          ),
      ]) ??
      []),
]);

SelectionMenu<APIExploreSort> exploreSortSelection(BuildContext context) {
  final options = [
    SelectionMenuItem(
      value: APIExploreSort.hot,
      title: l(context).sort_hot,
      icon: Symbols.local_fire_department_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topAll,
      title: l(context).sort_top,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.newest,
      title: l(context).sort_newest,
      icon: Symbols.nest_eco_leaf_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.active,
      title: l(context).sort_active,
      icon: Symbols.rocket_launch_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.mostComments,
      title: l(context).sort_commented,
      icon: Symbols.chat_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.oldest,
      title: l(context).sort_oldest,
      icon: Symbols.access_time_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.newComments,
      title: l(context).sort_newComments,
      icon: Symbols.mark_chat_unread_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.controversial,
      title: l(context).sort_controversial,
      icon: Symbols.thumbs_up_down_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.scaled,
      title: l(context).sort_scaled,
      icon: Symbols.scale_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topDay,
      title: l(context).sort_topDay,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topWeek,
      title: l(context).sort_topWeek,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topMonth,
      title: l(context).sort_topMonth,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topYear,
      title: l(context).sort_topYear,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topHour,
      title: l(context).sort_topHour,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topSixHour,
      title: l(context).sort_topSixHour,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topTwelveHour,
      title: l(context).sort_topTwelveHour,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topThreeMonths,
      title: l(context).sort_topThreeMonths,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topSixMonths,
      title: l(context).sort_topSixMonths,
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: APIExploreSort.topNineMonths,
      title: l(context).sort_topNineMonths,
      icon: Symbols.trending_up_rounded,
    ),
  ];

  return SelectionMenu(
    l(context).sort,
    APIExploreSort.valuesBySoftware(
          context.read<AppController>().serverSoftware,
        )
        .map((value) => options.firstWhere((option) => option.value == value))
        .toList(),
  );
}
