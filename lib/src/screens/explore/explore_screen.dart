import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/community.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/explore/explore_screen_item.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/user.dart';

class ExploreScreen extends StatefulWidget {
  final ExploreType? mode;
  final bool subOnly;
  final FocusNode? focusNode;
  final void Function(bool, dynamic)? onTap;
  final Set<String>? selected;

  const ExploreScreen({
    this.mode,
    this.subOnly = false,
    this.focusNode,
    this.onTap,
    this.selected,
    super.key,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin<ExploreScreen> {
  String search = '';
  final searchDebounce = Debouncer(duration: const Duration(milliseconds: 500));
  Set<String>? _selected;

  ExploreType type = ExploreType.communities;

  APIExploreSort sort = APIExploreSort.hot;
  ExploreFilter filter = ExploreFilter.all;

  final PagingController<String, dynamic> _pagingController = PagingController(
    firstPageKey: '',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _selected = widget.selected;

    if (widget.mode != null) {
      type = widget.mode!;
    }
    if (widget.subOnly) {
      filter = ExploreFilter.subscribed;
    }

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    if (type == ExploreType.all && search.isEmpty) {
      _pagingController.appendLastPage([]);
      return;
    }

    try {
      switch (type) {
        case ExploreType.communities:
          final newPage = await context
              .read<AppController>()
              .api
              .community
              .list(
                page: nullIfEmpty(pageKey),
                filter: filter,
                sort: sort,
                search: nullIfEmpty(search),
              );

          // Check BuildContext
          if (!mounted) return;

          // Prevent duplicates
          final currentItemIds =
              _pagingController.itemList?.map((e) => e.id) ?? [];
          final newItems = newPage.items
              .where((e) => !currentItemIds.contains(e.id))
              .toList();

          _pagingController.appendPage(newItems, newPage.nextPage);
          break;

        case ExploreType.people:
          // Lemmy cannot search with an empty query
          if (context.read<AppController>().serverSoftware ==
                  ServerSoftware.lemmy &&
              search.isEmpty) {
            _pagingController.appendLastPage([]);
            return;
          }

          final newPage = await context.read<AppController>().api.users.list(
            page: nullIfEmpty(pageKey),
            filter: filter,
            search: search,
          );

          // Check BuildContext
          if (!mounted) return;

          // Prevent duplicates
          final currentItemIds =
              _pagingController.itemList?.map((e) => e.id) ?? [];
          final newItems = newPage.items
              .where((e) => !currentItemIds.contains(e.id))
              .toList();

          _pagingController.appendPage(newItems, newPage.nextPage);
          break;

        case ExploreType.domains:
          final newPage = await context.read<AppController>().api.domains.list(
            page: nullIfEmpty(pageKey),
            filter: filter,
            search: nullIfEmpty(search),
          );

          // Check BuildContext
          if (!mounted) return;

          // Prevent duplicates
          final currentItemIds =
              _pagingController.itemList?.map((e) => e.id) ?? [];
          final newItems = newPage.items
              .where((e) => !currentItemIds.contains(e.id))
              .toList();

          _pagingController.appendPage(newItems, newPage.nextPage);
          break;

        case ExploreType.all:
          final newPage = await context.read<AppController>().api.search.get(
            page: nullIfEmpty(pageKey),
            search: search,
          );

          if (!mounted) return;

          _pagingController.appendPage(newPage.items, newPage.nextPage);
          break;
      }
    } catch (error) {
      _pagingController.error = error;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.mode) {
          ExploreType.communities => l(context).subscriptions_community,
          ExploreType.people => l(context).subscriptions_user,
          ExploreType.domains => l(context).subscriptions_domain,
          _ =>
            _selected != null
                ? l(context).feeds_selectInputs
                : '${l(context).explore} ${context.watch<AppController>().instanceHost}',
        }),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: CustomScrollView(
          slivers: [
            if (!widget.subOnly)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                            !(context.watch<AppController>().serverSoftware ==
                                    ServerSoftware.mbin &&
                                (filter != ExploreFilter.all &&
                                    filter != ExploreFilter.local)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Symbols.search_rounded),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          filled: true,
                          hintText: l(context).searchTheFediverse,
                        ),
                        focusNode: widget.focusNode,
                        onTapOutside: (event) {
                          widget.focusNode?.unfocus();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (widget.mode == null ||
                              widget.mode == ExploreType.communities) ...[
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
                          ],
                          if (widget.mode == null ||
                              widget.mode == ExploreType.people) ...[
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
                                    context
                                                    .read<AppController>()
                                                    .serverSoftware ==
                                                ServerSoftware.mbin &&
                                            filter == ExploreFilter.local ||
                                        // Using Lemmy or PieFed and filter is set to subscribed
                                        context
                                                    .read<AppController>()
                                                    .serverSoftware !=
                                                ServerSoftware.mbin &&
                                            filter ==
                                                ExploreFilter.subscribed ||
                                        // Using Lemmy or PieFed and filter is set to moderated
                                        context
                                                    .read<AppController>()
                                                    .serverSoftware !=
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
                          ],
                          if (context.watch<AppController>().serverSoftware ==
                                  ServerSoftware.mbin &&
                              _selected == null &&
                              (widget.mode == null ||
                                  widget.mode == ExploreType.domains)) ...[
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
                          if (_selected == null &&
                              (widget.mode == null ||
                                  widget.mode == ExploreType.all)) ...[
                            ChoiceChip(
                              label: Text(l(context).filter_all),
                              selected: type == ExploreType.all,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    if (context
                                                .read<AppController>()
                                                .serverSoftware ==
                                            ServerSoftware.mbin ||
                                        context
                                                    .read<AppController>()
                                                    .serverSoftware !=
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
                                context.read<AppController>().serverSoftware ==
                                        ServerSoftware.mbin &&
                                    type == ExploreType.all
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
                                context.watch<AppController>().serverSoftware ==
                                        ServerSoftware.mbin &&
                                    ((filter != ExploreFilter.all &&
                                            filter != ExploreFilter.local) ||
                                        type != ExploreType.communities)
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
            PagedSliverList(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<dynamic>(
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
                itemBuilder: (context, item, index) {
                  final selected = _selected?.contains(switch (item) {
                    DetailedCommunityModel i => i.name,
                    DetailedUserModel i => i.name,
                    DomainModel i => i.name,
                    _ => '',
                  });

                  onSelect(bool selected) {
                    widget.onTap!(selected, item);
                    final name = switch (item) {
                      DetailedCommunityModel i => i.name,
                      DetailedUserModel i => i.name,
                      DomainModel i => i.name,
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
                    (newValue) {
                      var newList = _pagingController.itemList;
                      newList![index] = newValue;
                      setState(() {
                        _pagingController.itemList = newList;
                      });
                    },
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
            ),
          ],
        ),
      ),
    );
  }
}

enum ExploreType { communities, people, domains, all }

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
