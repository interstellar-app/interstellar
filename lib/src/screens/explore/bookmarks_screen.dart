import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/bookmark_list.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

@RoutePage()
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
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Delete bookmark list'),
                                  content: Text(_bookmarkLists[index].name),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () => context.router.pop(),
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
                                        context.router.pop();
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
                onTap: () => context.router.push(
                  BookmarksRoute(bookmarkList: _bookmarkLists[index].name),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

@RoutePage()
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    @PathParam('bookmarkList') this.bookmarkList,
  });

  final String? bookmarkList;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late final _pagingController = AdvancedPagingController<String, dynamic, int>(
    logger: context.read<AppController>().logger,
    firstPageKey: '',
    // TODO(jwr1): this is not safe, items of different types (comment, microblog, etc.) could have the same id
    getItemId: (item) => item.id,
    fetchPage: (pageKey) async {
      final ac = context.read<AppController>();

      final bookmarks = await ac.api.bookmark.list(
        page: nullIfEmpty(pageKey),
        list: widget.bookmarkList,
      );

      return (bookmarks.$1, bookmarks.$2);
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.read<AppController>().serverSoftware == ServerSoftware.mbin
              ? '${widget.bookmarkList ?? ''} ${l(context).bookmarks}'
              : l(context).bookmarks,
        ),
      ),
      body: AdvancedPagedScrollView(
        controller: _pagingController,
        itemBuilder: (context, item, index) {
          return switch (item) {
            PostModel _ => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: PostItem(
                item,
                (newValue) =>
                    _pagingController.updateItem(newValue.id, newValue),
                onTap: () => pushPostPage(
                  context,
                  postId: item.id,
                  postType: item.type,
                  initData: item,
                  onUpdate: (newValue) =>
                      _pagingController.updateItem(item, newValue),
                ),
                isPreview: item.type == PostType.thread,
                isTopLevel: true,
              ),
            ),
            CommentModel _ => Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: PostComment(
                item,
                (newValue) =>
                    _pagingController.updateItem(newValue.id, newValue),
                onClick: () => context.router.push(
                  PostCommentRoute(postType: item.postType, commentId: item.id),
                ),
              ),
            ),
            _ => throw UnreachableError(),
          };
        },
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
