import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:provider/provider.dart';

import 'message_item.dart';
import 'message_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin<MessagesScreen> {
  final PagingController<String, MessageThreadModel> _pagingController =
      PagingController(firstPageKey: '');

  @override
  bool get wantKeepAlive => true;

  int? _userId;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    try {
      // Need to have user id for Lemmy and PieFed
      if (_userId == null &&
          context.read<AppController>().serverSoftware != ServerSoftware.mbin) {
        _userId = (await context.read<AppController>().api.users.getMe()).id;
      }

      // Check BuildContext
      if (!mounted) return;

      final newPage = await context.read<AppController>().api.messages.list(
        page: nullIfEmpty(pageKey),
        myUserId: _userId,
      );

      // Check BuildContext
      if (!mounted) return;

      // Prevent duplicates
      final currentItemIds = _pagingController.itemList?.map((e) => e.id) ?? [];
      final newItems = newPage.items
          .where((e) => !currentItemIds.contains(e.id))
          .toList();

      _pagingController.appendPage(newItems, newPage.nextPage);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<MessageThreadModel>(
              firstPageErrorIndicatorBuilder: (context) =>
                  FirstPageErrorIndicator(
                    error: _pagingController.error,
                    onTryAgain: _pagingController.retryLastFailedRequest,
                  ),
              newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
                error: _pagingController.error,
                onTryAgain: _pagingController.retryLastFailedRequest,
              ),
              itemBuilder: (context, item, index) => MessageItem(
                item,
                (newValue) {
                  var newList = _pagingController.itemList;
                  newList![index] = newValue;
                  setState(() {
                    _pagingController.itemList = newList;
                  });
                },
                onClick: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MessageThreadScreen(
                        threadId: item.id,
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
              ),
            ),
          ),
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
