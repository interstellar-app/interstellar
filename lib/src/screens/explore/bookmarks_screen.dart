import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/bookmark_list.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  List<BookmarkListModel> _bookmarkLists = [];
  final _newListController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fetch();
  }

  Future<void> _fetch() async {
    final ac = context.read<AppController>();

    final lists = await ac.api.bookmark.getBookmarkLists();
    setState(() {
      _bookmarkLists = lists;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).bookmarkLists)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextEditor(
                        _newListController,
                        hint: l(context).bookmarkLists_createHint,
                      ),
                    ),
                  ),
                  LoadingFilledButton(
                    onPressed: () async {
                      if (_newListController.text.isEmpty) return;
                      await ac.api.bookmark.createBookmarkList(
                        _newListController.text,
                      );
                      _fetch();
                    },
                    label: Text(l(context).bookmarkLists_create),
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _bookmarkLists.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_bookmarkLists[index].name),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!_bookmarkLists[index].isDefault)
                          LoadingFilledButton(
                            onPressed: () async {
                              await ac.api.bookmark.makeBookmarkListDefault(
                                _bookmarkLists[index].name,
                              );
                              _fetch();
                            },
                            label: Text(l(context).bookmarkLists_setDefault),
                          ),
                        if (!_bookmarkLists[index].isDefault)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: LoadingFilledButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: Text('Delete bookmark list'),
                                  content: Text(_bookmarkLists[index].name),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(l(context).cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        await ac.api.bookmark
                                            .deleteBookmarkList(
                                              _bookmarkLists[index].name,
                                            );
                                        _fetch();
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      },
                                      child: Text(l(context).delete),
                                    ),
                                  ],
                                ),
                              ),
                              label: Text(l(context).delete),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Text(_bookmarkLists[index].count.toString()),
                onTap: () => pushRoute(
                  context,
                  builder: (context) =>
                      BookmarksScreen(bookmarkList: _bookmarkLists[index].name),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BookmarksScreen extends StatefulWidget {
  final String? bookmarkList;

  const BookmarksScreen({super.key, this.bookmarkList});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final PagingController<String, dynamic> _pagingController = PagingController(
    firstPageKey: '',
  );

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    final ac = context.read<AppController>();

    try {
      final bookmarks = await ac.api.bookmark.list(
        page: nullIfEmpty(pageKey),
        list: widget.bookmarkList,
      );
      _pagingController.appendPage(bookmarks.$1, bookmarks.$2);
    } catch (e) {
      if (!mounted) return;
      ac.logger.e(e);
      _pagingController.error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookmarkList ?? ''} ${l(context).bookmarks}'),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: CustomScrollView(
          slivers: [
            PagedSliverList(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<dynamic>(
                itemBuilder: (context, item, index) {
                  return switch (item) {
                    PostModel _ => Card(
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
                        onTap: () => pushRoute(
                          context,
                          builder: (context) => PostPage(
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
                        isPreview: item.type == PostType.thread,
                        isTopLevel: true,
                      ),
                    ),
                    CommentModel _ => Padding(
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
                        onClick: () => pushRoute(
                          context,
                          builder: (context) =>
                              PostCommentScreen(item.postType, item.id),
                        ),
                      ),
                    ),
                    _ => throw 'unreachable',
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
