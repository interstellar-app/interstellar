import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/account/messages/message_thread_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({
    this.threadId,
    @PathParam('userId') this.userId,
    this.otherUser,
    this.initData,
    this.onUpdate,
    super.key,
  });

  final int? threadId;
  final int? userId;
  final DetailedUserModel? otherUser;
  final MessageThreadModel? initData;
  final void Function(MessageThreadModel)? onUpdate;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  MessageThreadModel? _data;
  final TextEditingController _controller = TextEditingController();

  late final _pagingController =
      AdvancedPagingController<String, MessageThreadItemModel, int>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => item.id,
        fetchPage: (pageKey) async {
          final ac = context.read<AppController>();

          if (_threadId == null) {
            return (<MessageThreadItemModel>[], null);
          }

          // Need to have user id for Lemmy and PieFed
          if (_userId == null && ac.serverSoftware != ServerSoftware.mbin) {
            _userId = (await ac.api.users.getMe()).id;
          }

          final newPage = await ac.api.messages.getThreadWithMessages(
            threadId: _threadId!,
            page: nullIfEmpty(pageKey),
            myUserId: _userId,
          );

          if (_data == null) {
            setState(() {
              _data = newPage;
            });
          }

          return (newPage.messages, newPage.nextPage);
        },
      );

  int? _userId;
  int? _threadId;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();

    _otherUserId = widget.userId ?? widget.otherUser?.id;
    _threadId =
        widget.threadId ??
        (context.read<AppController>().serverSoftware != ServerSoftware.mbin
            ? _otherUserId
            : null);
    _data = widget.initData;

    if (_data != null) {
      _pagingController.prependPage('', _data!.messages);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = context.watch<AppController>().localName;

    final messageUser =
        (_data != null && _data!.participants.isNotEmpty
            ? _data?.participants.firstWhere(
                (user) => user.name != myUsername,
                orElse: () => _data!.participants.first,
              )
            : null) ??
        widget.otherUser;

    final messageDraftController = context.watch<DraftsController>().auto(
      'message:${context.watch<AppController>().instanceHost}:${messageUser?.name}',
    );

    return Scaffold(
      appBar: AppBar(title: Text(messageUser?.name ?? '')),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: CustomScrollView(
          reverse: true,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    MarkdownEditor(
                      _controller,
                      originInstance: null,
                      draftController: messageDraftController,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        LoadingFilledButton(
                          onPressed: () async {
                            final ac = context.read<AppController>();
                            MessageThreadModel newThread;
                            if (_threadId == null) {
                              newThread = await ac.api.messages.create(
                                _otherUserId!,
                                _controller.text,
                              );
                            } else {
                              newThread = await ac.api.messages.postThreadReply(
                                _threadId!,
                                _controller.text,
                              );
                            }

                            await messageDraftController.discard();

                            _controller.text = '';

                            _pagingController.prependPage('', [
                              newThread.messages.first,
                            ]);

                            if (widget.onUpdate != null) {
                              widget.onUpdate!(newThread);
                            }
                          },
                          label: Text(l(context).send),
                          icon: const Icon(Symbols.send_rounded),
                          uesHaptics: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AdvancedPagingListener(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) {
                  final pagedItems = state.items ?? [];

                  return AdvancedPagedSliverList(
                    controller: _pagingController,
                    itemBuilder: (context, item, index) {
                      final nextMessage = index - 1 < 0
                          ? null
                          : pagedItems.elementAtOrNull(index - 1);
                      final currMessage = pagedItems[index];
                      final prevMessage = index + 1 >= pagedItems.length
                          ? null
                          : pagedItems.elementAt(index + 1);

                      final fromMyUser = currMessage.sender.name == myUsername;

                      return MessageThreadItem(
                        fromMyUser: fromMyUser,
                        prevMessage: prevMessage,
                        currMessage: currMessage,
                        nextMessage: nextMessage,
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
