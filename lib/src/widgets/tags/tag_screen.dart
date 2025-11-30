import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/tags/tag_editor.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key, this.onSelect});

  final void Function(Tag)? onSelect;

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    context.read<AppController>().getTags().then(
      (tags) => setState(() {
        _tags = tags;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).tags),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: _tags.length,
            itemBuilder: (context, index) => ListTile(
              title: TagWidget(tag: _tags[index]),
              onTap: widget.onSelect != null
                  ? () {
                      widget.onSelect!(_tags[index]);
                      Navigator.pop(context);
                    }
                  : () => pushRoute(
                      context,
                      builder: (context) => TagEditor(
                        tag: _tags[index],
                        onUpdate: (tag) => setState(() {
                          if (tag == null) {
                            _tags.removeAt(index);
                            return;
                          }
                          _tags[index] = tag;
                        }),
                      ),
                    ),
              trailing: widget.onSelect != null
                  ? null
                  : IconButton(
                      onPressed: () async {
                        await ac.removeTag(_tags[index]);
                        setState(() {
                          _tags.removeAt(index);
                        });
                      },
                      icon: const Icon(Symbols.delete_rounded),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilledButton(
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
            )),
          ),
        ],
      ),
    );
  }
}
