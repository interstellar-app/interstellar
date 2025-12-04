import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
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
      appBar: AppBar(title: Text(l(context).tags)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FilledButton(
                onPressed: () async {
                  Tag? tag;
                  try {
                    tag = await ac.addTag();
                  } catch (err) {
                    if (!context.mounted) return;
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(l(context).tags_exist),
                          actions: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(l(context).cancel),
                            ),
                            LoadingFilledButton(
                              onPressed: () async {
                                int num = 0;
                                while (tag == null) {
                                  try {
                                    tag = await ac.addTag(tag: 'Tag ${num++}');
                                  } catch (err) {
                                    //
                                  }
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                              label: Text(l(context).rename),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  if (!context.mounted || tag == null) return;
                  bool cancelled = true;
                  await pushRoute(
                    context,
                    builder: (context) => TagEditor(
                      tag: tag!,
                      onUpdate: (newTag) async {
                        cancelled = false;
                        if (newTag == null) {
                          await ac.removeTag(tag!);
                          return;
                        }
                        if (widget.onSelect != null) {
                          widget.onSelect!(newTag);
                        }
                        setState(() {
                          _tags.add(newTag);
                        });
                      },
                    ),
                  );
                  if (cancelled) {
                    await ac.removeTag(tag!);
                  }
                },
                child: Text(l(context).tags_addNew),
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}
