import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/comments.dart' as api_comments;
import 'package:interstellar/src/api/entries.dart' as api_entries;
import 'package:interstellar/src/models/entry.dart';
import 'package:interstellar/src/models/entry_comment.dart';
import 'package:interstellar/src/screens/entries/entry_comment.dart';
import 'package:interstellar/src/screens/entries/entry_item.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:provider/provider.dart';

class EntryPage extends StatefulWidget {
  const EntryPage(
    this.initData,
    this.onUpdate, {
    super.key,
  });

  final EntryModel initData;
  final void Function(EntryModel) onUpdate;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  EntryModel? _data;

  api_comments.CommentsSort commentsSort = api_comments.CommentsSort.hot;

  final PagingController<int, EntryCommentModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    _data = widget.initData;

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  void _onUpdate(EntryModel newValue) {
    setState(() {
      _data = newValue;
    });
    widget.onUpdate(newValue);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newPage = await api_comments.fetchComments(
        context.read<SettingsController>().httpClient,
        context.read<SettingsController>().instanceHost,
        _data!.entryId,
        page: pageKey,
        sort: commentsSort,
      );

      final isLastPage =
          newPage.pagination.currentPage == newPage.pagination.maxPage;

      if (isLastPage) {
        _pagingController.appendLastPage(newPage.items);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newPage.items, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) return const Center();

    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.title ?? ''),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(
          () => _pagingController.refresh(),
        ),
        child: CustomScrollView(
          slivers: [
            if (_data != null)
              SliverToBoxAdapter(
                child: EntryItem(
                  _data!,
                  _onUpdate,
                  onReply: whenLoggedIn(context, (body) async {
                    var newComment = await api_comments.postComment(
                      context.read<SettingsController>().httpClient,
                      context.read<SettingsController>().instanceHost,
                      body,
                      _data!.entryId,
                    );
                    var newList = _pagingController.itemList;
                    newList?.insert(0, newComment);
                    setState(() {
                      _pagingController.itemList = newList;
                    });
                  }),
                  onEdit: _data!.visibility != 'soft_deleted'
                      ? whenLoggedIn(
                          context,
                          (body) async {
                            final newEntry = await api_entries.editEntry(
                                context.read<SettingsController>().httpClient,
                                context.read<SettingsController>().instanceHost,
                                _data!.entryId,
                                _data!.title,
                                _data!.isOc,
                                body,
                                _data!.lang,
                                _data!.isAdult);
                            _onUpdate(newEntry);
                          },
                          matchesUsername: _data!.user.username,
                        )
                      : null,
                  onDelete: _data!.visibility != 'soft_deleted'
                      ? whenLoggedIn(
                          context,
                          () async {
                            await api_entries.deletePost(
                              context.read<SettingsController>().httpClient,
                              context.read<SettingsController>().instanceHost,
                              _data!.entryId,
                            );
                            _onUpdate(_data!.copyWith(
                              body: '_thread deleted_',
                              uv: null,
                              dv: null,
                              favourites: null,
                              visibility: 'soft_deleted',
                            ));
                          },
                          matchesUsername: _data!.user.username,
                        )
                      : null,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DropdownButton<api_comments.CommentsSort>(
                      value: commentsSort,
                      onChanged: (newSort) {
                        if (newSort != null) {
                          setState(() {
                            commentsSort = newSort;
                            _pagingController.refresh();
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: api_comments.CommentsSort.hot,
                          child: Text('Hot'),
                        ),
                        DropdownMenuItem(
                          value: api_comments.CommentsSort.top,
                          child: Text('Top'),
                        ),
                        DropdownMenuItem(
                          value: api_comments.CommentsSort.newest,
                          child: Text('Newest'),
                        ),
                        DropdownMenuItem(
                          value: api_comments.CommentsSort.active,
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: api_comments.CommentsSort.oldest,
                          child: Text('Oldest'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PagedSliverList<int, EntryCommentModel>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<EntryCommentModel>(
                itemBuilder: (context, item, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: EntryComment(item, (newValue) {
                    var newList = _pagingController.itemList;
                    newList![index] = newValue;
                    setState(() {
                      _pagingController.itemList = newList;
                    });
                  },
                  opUserId: widget.initData.user.userId),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
