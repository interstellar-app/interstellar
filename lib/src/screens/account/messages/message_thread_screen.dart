import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/screens/account/messages/message_thread_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../models/user.dart';

class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({
    required this.threadId,
    this.otherUser,
    this.initData,
    this.onUpdate,
    super.key,
  });

  final int? threadId;
  final DetailedUserModel? otherUser;
  final MessageThreadModel? initData;
  final void Function(MessageThreadModel)? onUpdate;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  MessageThreadModel? _data;
  final TextEditingController _controller = TextEditingController();

  final PagingController<String, MessageThreadItemModel> _pagingController =
      PagingController(firstPageKey: '');

  int? _userId;
  int? _threadId;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();

    _threadId =
        widget.threadId ??
        (context.read<AppController>().serverSoftware != ServerSoftware.mbin
            ? widget.otherUser?.id
            : null);
    _otherUserId = widget.otherUser?.id;
    _data = widget.initData;
    if (_data != null) {
      _pagingController.appendPage(_data!.messages, '');
    }

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    if (_threadId == null) {
      _pagingController.appendLastPage([]);
    }
    try {
      // Need to have user id for Lemmy and PieFed
      if (_userId == null &&
          context.read<AppController>().serverSoftware != ServerSoftware.mbin) {
        _userId = (await context.read<AppController>().api.users.getMe()).id;
      }

      // Check BuildContext
      if (!mounted) return;

      final newPage = await context
          .read<AppController>()
          .api
          .messages
          .getThreadWithMessages(
            threadId: _threadId!,
            page: nullIfEmpty(pageKey),
            myUserId: _userId,
          );

      // Check BuildContext
      if (!mounted) return;

      if (_data == null) {
        setState(() {
          _data = newPage;
        });
      }

      // Prevent duplicates
      final currentItemIds = _pagingController.itemList?.map((e) => e.id) ?? [];
      final newItems = newPage.messages
          .where((e) => !currentItemIds.contains(e.id))
          .toList();

      _pagingController.appendPage(newItems, newPage.nextPage);
    } catch (error) {
      if (!mounted) return;
      context.read<AppController>().logger.e(error);
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = context.watch<AppController>().localName;

    final messageUser = _data?.participants.firstWhere(
      (user) => user.name != myUsername,
      orElse: () => _data!.participants.first,
    ) ?? widget.otherUser;

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

                            setState(() {
                              _data = newThread;
                              _threadId = newThread.id;

                              var newList = _pagingController.itemList;
                              newList?.insert(0, newThread.messages.first);
                              setState(() {
                                _pagingController.itemList = newList;
                              });
                            });

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
              sliver: PagedSliverList(
                pagingController: _pagingController,
                builderDelegate:
                    PagedChildBuilderDelegate<MessageThreadItemModel>(
                      firstPageErrorIndicatorBuilder: (context) =>
                          FirstPageErrorIndicator(
                            error: _pagingController.error,
                            onTryAgain:
                                _pagingController.retryLastFailedRequest,
                          ),
                      newPageErrorIndicatorBuilder: (context) =>
                          NewPageErrorIndicator(
                            error: _pagingController.error,
                            onTryAgain:
                                _pagingController.retryLastFailedRequest,
                          ),
                      itemBuilder: (context, item, index) {
                        final messages = _pagingController.itemList!;

                        final nextMessage = index - 1 < 0
                            ? null
                            : messages.elementAtOrNull(index - 1);
                        final currMessage = messages[index];
                        final prevMessage = index + 1 >= messages.length
                            ? null
                            : messages.elementAt(index + 1);

                        final fromMyUser =
                            currMessage.sender.name == myUsername;

                        return MessageThreadItem(
                          fromMyUser: fromMyUser,
                          prevMessage: prevMessage,
                          currMessage: currMessage,
                          nextMessage: nextMessage,
                        );
                      },
                    ),
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
