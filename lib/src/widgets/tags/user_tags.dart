import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/tags/tag_editor.dart';
import 'package:interstellar/src/widgets/tags/tag_screen.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class UserTags extends StatefulWidget {
  const UserTags({super.key, required this.user});

  final String user;

  @override
  State<UserTags> createState() => _UserTagsState();
}

class _UserTagsState extends State<UserTags> {
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    context
        .read<AppController>()
        .getUserTags(widget.user)
        .then(
          (tags) => setState(() {
            _tags = tags;
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.user)),
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: _tags.length,
            itemBuilder: (context, index) => ListTile(
              title: TagWidget(tag: _tags[index]),
              trailing: IconButton(
                onPressed: () async {
                  await ac.removeTagFromUser(_tags[index], widget.user);
                  setState(() {
                    _tags.removeAt(index);
                  });
                },
                icon: const Icon(Symbols.delete_rounded),
              ),
              onTap: () => pushRoute(
                context,
                builder: (context) => TagEditor(
                  tag: _tags[index],
                  onUpdate: (tag) {
                    setState(() {
                      if (tag == null) {
                        _tags.removeAt(index);
                        return;
                      }
                      _tags[index] = tag;
                    });
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  onPressed: () => pushRoute(
                    context,
                    builder: (context) => TagsScreen(
                      onSelect: (tag) async {
                        await ac.assignTagToUser(tag, widget.user);
                        if (!mounted) return;
                        setState(() {
                          _tags.add(tag);
                        });
                      },
                    ),
                  ),
                  child: Text(l(context).tags_addExisting),
                ),
                FilledButton(
                  onPressed: () async {
                    var tag = await ac.addTag();
                    if (!context.mounted) return;
                    bool cancelled = true;
                    await pushRoute(context, builder: (context) => TagEditor(
                        tag: tag,
                        onUpdate: (newTag) async {
                          cancelled = false;
                          if (newTag == null) {
                            await ac.removeTag(tag);
                            return;
                          }
                          await ac.assignTagToUser(newTag, widget.user);
                          setState(() {
                            _tags.add(newTag);
                          });
                        }
                    ));
                    if (cancelled) {
                      await ac.removeTag(tag);
                    }
                  },
                  child: Text(l(context).tags_addNew),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
