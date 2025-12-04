import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/tags/user_tags.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class TaggedUsersScreen extends StatefulWidget {
  const TaggedUsersScreen({super.key});

  @override
  State<TaggedUsersScreen> createState() => _TaggedUsersState();
}

class _TaggedUsersState extends State<TaggedUsersScreen> {
  List<String> _users = [];

  @override
  void initState() {
    super.initState();
    context.read<AppController>().getTaggedUsers().then(
      (value) => setState(() {
        _users = value;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).tags_users)),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_users[index]),
          onTap: () => pushRoute(
            context,
            builder: (context) => UserTags(user: _users[index]),
          ),
          trailing: IconButton(
            onPressed: () async {
              final ac = context.read<AppController>();

              final userTags = await ac.getUserTags(_users[index]);
              for (final tag in userTags) {
                await ac.removeTagFromUser(tag, _users[index]);
              }
              setState(() {
                _users.removeAt(index);
              });
            },
            icon: const Icon(Symbols.delete_rounded),
          ),
        ),
      ),
    );
  }
}
