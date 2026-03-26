import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:provider/provider.dart';

class MessageItem extends StatelessWidget {
  const MessageItem(this.item, this.onUpdate, {this.onClick, super.key});

  final MessageThreadModel item;
  final void Function(MessageThreadModel) onUpdate;
  final void Function()? onClick;

  @override
  Widget build(BuildContext context) {
    final messageUser = item.participants.firstWhere(
      (user) => user.name != context.watch<AppController>().localName,
      orElse: () => item.participants.first,
    );

    return ListTile(
      title: Text(
        messageUser.name,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      subtitle: Text(
        item.messages.first.body.replaceAll('\n', ' '),
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Avatar(messageUser.avatar),
      trailing: Text(
        '${dateDiffFormat(start: item.messages.first.createdAt)} ago',
      ),
      onTap: onClick,
    );
  }
}
