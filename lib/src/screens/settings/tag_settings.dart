import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/tags/tag_screen.dart';
import 'package:interstellar/src/widgets/tags/tagged_users.dart';

class TagSettingsScreen extends StatelessWidget {
  const TagSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).tags)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l(context).tags),
            onTap: () =>
                pushRoute(context, builder: (context) => const TagsScreen()),
          ),
          ListTile(
            title: Text(l(context).tags_users),
            onTap: () => pushRoute(
              context,
              builder: (context) => const TaggedUsersScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
