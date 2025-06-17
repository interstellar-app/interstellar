import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/feed/create_screen.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/api/community.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/screens/explore/explore_screen_item.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';

class FeedSettingsScreen extends StatefulWidget {
  const FeedSettingsScreen({super.key});

  @override
  State<FeedSettingsScreen> createState() => _FeedSettingsScreenState();
}

class _FeedSettingsScreenState extends State<FeedSettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text('Feeds')),
      body: ListView(
        children: [
          ...ac.feeds.keys.map(
            (name) => ListTile(
              title: Text(name),
              onTap: () async {
                final feed = await FeedAggregator.createFeed(
                  ac,
                  ac.feeds[name]!,
                );
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FeedScreen(feed: feed),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditFeedScreen(
                          feed: name,
                          feedData: ac.feeds[name],
                        ),
                      ),
                    ),
                    icon: const Icon(Symbols.edit_rounded),
                  ),
                  IconButton(
                    onPressed: () async {
                      final ac = context.watch<AppController>();

                      final feed = ac.feeds[name]!;

                      final config = await ConfigShare.create(
                        type: ConfigShareType.filterList,
                        name: name,
                        payload: feed.toJson(),
                      );

                      if (!mounted) return;
                      String communityName = mbinConfigsCommunityName;
                      if (communityName.endsWith(ac.instanceHost)) {
                        communityName = communityName.split('@').first;
                      }

                      final community = await ac.api.community.getByName(
                        communityName,
                      );

                      if (!context.mounted) return;

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateScreen(
                            initTitle: '[Filter List] $name',
                            initBody:
                                'Short description here...\n\n${config.toMarkdown()}',
                            initCommunity: community,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Symbols.share_rounded),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.add_rounded),
            title: Text('New feed'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EditFeedScreen(feed: null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditFeedScreen extends StatefulWidget {
  final String? feed;
  final Feed? feedData;

  const EditFeedScreen({required this.feed, this.feedData, super.key});

  @override
  State<EditFeedScreen> createState() => _EditFeedScreenState();
}

class _EditFeedScreenState extends State<EditFeedScreen> {
  late Feed feedData;
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.feed != null) {
      nameController.text = widget.feed!;
    }

    feedData = widget.feedData == null
        ? Feed(name: '', inputs: {})
        : widget.feedData!;
  }

  void addInput(FeedInput input) {
    setState(() {
      feedData = feedData.copyWith(inputs: {...feedData.inputs, input});
    });
  }

  void removeInput(FeedInput input) {
    final inputs = {...feedData.inputs};
    inputs.remove(input);
    setState(() {
      feedData = feedData.copyWith(inputs: inputs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(title: Text('Edit feed ${widget.feed}')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextEditor(
              nameController,
              label: l(context).filterList_name,
              onChanged: (_) => setState(() {}),
            ),
          ),
          ...feedData.inputs.map((input) {
            return ListTile(
              title: Text(input.name),
              trailing: IconButton(
                onPressed: () {
                  removeInput(input);
                },
                icon: const Icon(Symbols.delete_rounded),
              ),
            );
          }),
          ListTile(
            leading: const Icon(Symbols.add_rounded),
            title: Text('Add input'),
            onTap: () async {
              // final item = await Navigator.of(context).push(
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExploreFeedInputsScreen(
                    inputs: feedData.inputs.map((input) => input.name).toSet(),
                    onSelect: (selected, item) {
                      final name = switch (item) {
                        DetailedCommunityModel i => i.name,
                        DetailedUserModel i => i.name,
                        DomainModel i => i.name,
                        _ => null,
                      };
                      final source = switch (item) {
                        DetailedCommunityModel i => FeedSource.community,
                        DetailedUserModel i => FeedSource.user,
                        DomainModel i => FeedSource.domain,
                        _ => null,
                      };

                      if (name == null || source == null) return;

                      if (selected) {
                        addInput(FeedInput(name: name, sourceType: source));
                      } else {
                        removeInput(FeedInput(name: name, sourceType: source));
                      }
                    },
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LoadingFilledButton(
              icon: const Icon(Symbols.save_rounded),
              onPressed:
                  nameController.text.isEmpty ||
                      (nameController.text != widget.feed &&
                          ac.filterLists.containsKey(nameController.text))
                  ? null
                  : () async {
                      final name = nameController.text;
                      if (widget.feed != null && name != widget.feed) {
                        await ac.renameFeed(widget.feed!, name);
                      }

                      await ac.setFeed(name, feedData);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
              label: Text(l(context).saveChanges),
            ),
          ),
          if (widget.feed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.delete_rounded),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(l(context).filterList_delete),
                      content: Text(widget.feed!),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ac.removeFeed(widget.feed!);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text(l(context).delete),
                        ),
                      ],
                    ),
                  );
                },
                label: Text(l(context).filterList_delete),
              ),
            ),
        ],
      ),
    );
  }
}

class ExploreFeedInputsScreen extends StatefulWidget {
  final Set<String> inputs;
  final void Function(bool, dynamic) onSelect;

  const ExploreFeedInputsScreen({
    required this.inputs,
    required this.onSelect,
    super.key,
  });

  @override
  State<ExploreFeedInputsScreen> createState() =>
      _ExploreFeedInputsScreenState();
}

class _ExploreFeedInputsScreenState extends State<ExploreFeedInputsScreen>
    with AutomaticKeepAliveClientMixin<ExploreFeedInputsScreen> {
  String search = '';
  final searchDebounce = Debouncer(duration: const Duration(milliseconds: 500));

  ExploreType type = ExploreType.communities;

  APIExploreSort sort = APIExploreSort.hot;
  ExploreFilter filter = ExploreFilter.all;

  final PagingController<String, dynamic> _pagingController = PagingController(
    firstPageKey: '',
  );

  late final Set<String> _inputs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _inputs = widget.inputs;
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
        title: Text(
          '${l(context).explore} ${context.watch<AppController>().instanceHost}',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: CustomScrollView(
          slivers: [
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
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
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
                                context.read<AppController>().serverSoftware ==
                                            ServerSoftware.mbin &&
                                        filter == ExploreFilter.local ||
                                    // Using Lemmy or PieFed and filter is set to subscribed
                                    context
                                                .read<AppController>()
                                                .serverSoftware !=
                                            ServerSoftware.mbin &&
                                        filter == ExploreFilter.subscribed ||
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
                        if (context.watch<AppController>().serverSoftware ==
                            ServerSoftware.mbin) ...[
                          const SizedBox(width: 4),
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
                  bool selected = _inputs.contains(switch (item) {
                    DetailedCommunityModel i => i.name,
                    DetailedUserModel i => i.name,
                    DomainModel i => i.name,
                    _ => '',
                  });
                  return Row(
                    children: [
                      Expanded(
                        child: ExploreScreenItem(item, (newValue) {
                          var newList = _pagingController.itemList;
                          newList![index] = newValue;
                          setState(() {
                            _pagingController.itemList = newList;
                          });
                        }),
                      ),
                      Checkbox(
                        value: selected,
                        onChanged: (value) {
                          widget.onSelect(value!, item);
                          final name = switch (item) {
                            DetailedCommunityModel i => i.name,
                            DetailedUserModel i => i.name,
                            DomainModel i => i.name,
                            _ => null,
                          };
                          if (name == null) return;

                          setState(() {
                            if (!selected) {
                              _inputs.add(name);
                            } else {
                              _inputs.remove(name);
                            }
                          });
                        },
                      ),
                    ],
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
