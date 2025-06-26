import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:provider/provider.dart';

class MessageThreadItem extends StatelessWidget {
  final bool fromMyUser;
  final MessageThreadItemModel? prevMessage;
  final MessageThreadItemModel currMessage;
  final MessageThreadItemModel? nextMessage;

  const MessageThreadItem({
    required this.fromMyUser,
    required this.prevMessage,
    required this.currMessage,
    required this.nextMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Convert to local time so timelines markings are correct.
    final prevCreatedAt = prevMessage?.createdAt.toLocal();
    final currCreatedAt = currMessage.createdAt.toLocal();
    final nextCreatedAt = nextMessage?.createdAt.toLocal();

    final showDate =
        prevMessage == null ||
        !DateUtils.isSameDay(currCreatedAt, prevCreatedAt!);
    final showTime =
        prevMessage == null ||
        currCreatedAt.difference(prevCreatedAt!).inMinutes > 15;

    final showName =
        showTime || currMessage.sender.name != prevMessage!.sender.name;

    const defaultRadius = Radius.circular(20);
    const connectedRadius = Radius.circular(4);

    final topRadius = showName ? defaultRadius : connectedRadius;
    final bottomRadius =
        nextMessage == null ||
            currMessage.sender.name != nextMessage!.sender.name ||
            nextCreatedAt!.difference(currCreatedAt).inMinutes > 15
        ? defaultRadius
        : connectedRadius;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: fromMyUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        DateUtils.isSameDay(currCreatedAt, DateTime.now())
                            ? 'Today'
                            : dateOnlyFormat(currCreatedAt),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            if (showTime || showName)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: reverseList([
                    const Spacer(),
                    if (showTime)
                      Text(
                        timeOnlyFormat(currCreatedAt),
                        style: const TextStyle(fontWeight: FontWeight.w300),
                      ),
                    if (showName)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: fromMyUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            DisplayName(
                              currMessage.sender.name,
                              icon: currMessage.sender.avatar,
                              onTap: () => pushRoute(
                                context,
                                builder: (context) =>
                                    UserScreen(currMessage.sender.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ], !fromMyUser),
                ),
              ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: max(
                  constraints.maxWidth * (2 / 3),
                  min(constraints.maxWidth - 32, 600),
                ),
              ),
              child: Card(
                color: fromMyUser
                    ? Theme.of(context).colorScheme.primary
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: fromMyUser ? defaultRadius : topRadius,
                    topRight: fromMyUser ? topRadius : defaultRadius,
                    bottomLeft: fromMyUser ? defaultRadius : bottomRadius,
                    bottomRight: fromMyUser ? bottomRadius : defaultRadius,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Markdown(
                    currMessage.body,
                    context.watch<AppController>().instanceHost,
                    themeData: Theme.of(context).copyWith(
                      textTheme: fromMyUser
                          ? Theme.of(context).primaryTextTheme
                          : Theme.of(context).textTheme,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
