import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/magazines.dart' as api_magazines;
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:provider/provider.dart';

class MagazinesScreen extends StatefulWidget {
  const MagazinesScreen({
    super.key,
  });

  @override
  State<MagazinesScreen> createState() => _MagazinesScreenState();
}

class _MagazinesScreenState extends State<MagazinesScreen> {
  api_magazines.MagazinesFilter filter = api_magazines.MagazinesFilter.all;
  api_magazines.MagazinesSort sort = api_magazines.MagazinesSort.hot;
  String search = "";

  final PagingController<int, DetailedMagazineModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newPage = await api_magazines.fetchMagazines(
        context.read<SettingsController>().httpClient,
        context.read<SettingsController>().instanceHost,
        page: pageKey,
        filter: filter,
        sort: sort,
        search: search.isEmpty ? null : search,
      );

      // Check BuildContext
      if (!mounted) return;

      final isLastPage =
          newPage.pagination.currentPage == newPage.pagination.maxPage;
      // Prevent duplicates
      final currentItemIds =
          _pagingController.itemList?.map((e) => e.magazineId) ?? [];
      final newItems = newPage.items
          .where((e) => !currentItemIds.contains(e.magazineId))
          .toList();

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(
        () => _pagingController.refresh(),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ...whenLoggedIn(context, [
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: DropdownButton<api_magazines.MagazinesFilter>(
                            value: filter,
                            onChanged: (newFilter) {
                              if (newFilter != null) {
                                setState(() {
                                  filter = newFilter;
                                  _pagingController.refresh();
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: api_magazines.MagazinesFilter.all,
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: api_magazines.MagazinesFilter.subscribed,
                                child: Text('Subscribed'),
                              ),
                              DropdownMenuItem(
                                value: api_magazines.MagazinesFilter.moderated,
                                child: Text('Moderated'),
                              ),
                              DropdownMenuItem(
                                value: api_magazines.MagazinesFilter.blocked,
                                child: Text('Blocked'),
                              ),
                            ],
                          ),
                        )
                      ]) ??
                      [],
                  ...(filter == api_magazines.MagazinesFilter.all
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: DropdownButton<api_magazines.MagazinesSort>(
                              value: sort,
                              onChanged: (newSort) {
                                if (newSort != null) {
                                  setState(() {
                                    sort = newSort;
                                    _pagingController.refresh();
                                  });
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: api_magazines.MagazinesSort.hot,
                                  child: Text('Hot'),
                                ),
                                DropdownMenuItem(
                                  value: api_magazines.MagazinesSort.active,
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: api_magazines.MagazinesSort.newest,
                                  child: Text('Newest'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 128,
                            child: TextFormField(
                              initialValue: search,
                              onChanged: (newSearch) {
                                setState(() {
                                  search = newSearch;
                                  _pagingController.refresh();
                                });
                              },
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text('Search')),
                            ),
                          ),
                        ]
                      : []),
                ],
              ),
            ),
          ),
          PagedSliverList<int, DetailedMagazineModel>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<DetailedMagazineModel>(
              itemBuilder: (context, item, index) => InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MagazineScreen(
                        item.magazineId,
                        initData: item,
                        onUpdate: (newValue) {
                          var newList = _pagingController.itemList;
                          newList![index] = newValue;
                          setState(() {
                            _pagingController.itemList = newList;
                          });
                        },
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    if (item.icon?.storageUrl != null)
                      Avatar(item.icon!.storageUrl, radius: 16),
                    Container(
                        width: 8 + (item.icon?.storageUrl != null ? 0 : 32)),
                    Expanded(
                        child:
                            Text(item.name, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.feed),
                    Container(
                      width: 4,
                    ),
                    Text(intFormat(item.entryCount)),
                    const SizedBox(width: 12),
                    const Icon(Icons.comment),
                    Container(
                      width: 4,
                    ),
                    Text(intFormat(item.entryCommentCount)),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: ButtonStyle(
                          foregroundColor: item.isUserSubscribed == true
                              ? null
                              : MaterialStatePropertyAll(
                                  Theme.of(context).disabledColor)),
                      onPressed: whenLoggedIn(context, () async {
                        var newValue = await api_magazines.putSubscribe(
                            context.read<SettingsController>().httpClient,
                            context.read<SettingsController>().instanceHost,
                            item.magazineId,
                            !item.isUserSubscribed!);
                        var newList = _pagingController.itemList;
                        newList![index] = newValue;
                        setState(() {
                          _pagingController.itemList = newList;
                        });
                      }),
                      child: Row(
                        children: [
                          const Icon(Icons.group),
                          Text(' ${intFormat(item.subscriptionsCount)}'),
                        ],
                      ),
                    )
                  ]),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
