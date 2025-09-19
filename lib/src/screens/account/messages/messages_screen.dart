import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'message_item.dart';
import 'message_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin<MessagesScreen> {
  late final _pagingController =
      AdvancedPagingController<String, MessageThreadModel, int>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => item.id,
        fetchPage: (pageKey) async {
          final ac = context.read<AppController>();

          if (_userId == null && ac.serverSoftware != ServerSoftware.mbin) {
            _userId = (await ac.api.users.getMe()).id;
          }

          final newPage = await ac.api.messages.list(
            page: nullIfEmpty(pageKey),
            myUserId: _userId,
          );

          return (newPage.items, newPage.nextPage);
        },
      );

  @override
  bool get wantKeepAlive => true;

  int? _userId;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        AdvancedPagedScrollView(
          controller: _pagingController,
          itemBuilder: (context, item, index) => MessageItem(
            item,
            (newValue) {
              var newList = _pagingController.value.items;
              newList![index] = newValue;
              _pagingController.value = _pagingController.value.copyWith();
            },
            onClick: () => pushRoute(
              context,
              builder: (context) => MessageThreadScreen(
                threadId: item.id,
                initData: item,
                onUpdate: (newValue) =>
                    _pagingController.updateItem(item, newValue),
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'new-message',
            onPressed: () {
              pushRoute(
                context,
                builder: (context) => ExploreScreen(
                  mode: ExploreType.people,
                  title: 'New chat',
                  onTap: (selected, item) async {
                    Navigator.of(context).pop();
                    await pushRoute(
                      context,
                      builder: (context) =>
                          MessageThreadScreen(threadId: null, otherUser: item),
                    );
                    _pagingController.refresh();
                  },
                ),
              );
            },
            child: const Icon(Symbols.add_rounded),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
