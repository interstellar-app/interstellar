import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/tags/tag_editor.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class TagsList extends StatefulWidget {
  const TagsList({
    super.key,
    this.activeTags,
    this.availableTags,
    this.username,
    this.onUpdate,
  });

  final List<Tag>? activeTags;
  final List<Tag>? availableTags;
  final void Function(List<Tag>)? onUpdate;
  final String? username;

  @override
  State<TagsList> createState() => _TagsListState();
}

class _TagsListState extends State<TagsList> {
  List<Tag> _activeTags = [];
  List<Tag> _availableTags = [];

  @override
  void didUpdateWidget(covariant TagsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availableTags != null &&
        widget.availableTags != _availableTags) {
      setState(() {
        _availableTags = widget.availableTags!;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final ac = context.read<AppController>();

    if (widget.activeTags != null) {
      _activeTags = widget.activeTags!;
    } else if (widget.username != null) {
      ac
          .getUserTags(widget.username!)
          .then(
            (tags) => setState(() {
              _activeTags = tags;
            }),
          );
    }
    if (widget.availableTags != null) {
      setState(() {
        _availableTags = widget.availableTags!;
      });
    } else {
      ac.getTags().then(
        (tags) => setState(() {
          _availableTags = tags;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTagIds = _activeTags.map((tag) => tag.id).toList();

    return Wrapper(
      shouldWrap: widget.onUpdate != null,
      parentBuilder: (child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l(context).tags,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Flexible(
            child: Stack(
              children: [
                child,
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: TagsFloatingButton(
                    onUpdate: (newTag) => setState(() {
                      _availableTags = [..._availableTags, newTag];
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: _availableTags.length,
        itemBuilder: (context, index) {
          final tag = _availableTags[index];

          final isActive = activeTagIds.contains(tag.id);

          toggleTag(bool? newValue) {
            if (newValue == null) return;

            if (newValue) {
              if (!activeTagIds.contains(tag.id)) {
                setState(() {
                  _activeTags = [..._activeTags, tag];
                  widget.onUpdate!(_activeTags);
                });
              }
            } else {
              if (activeTagIds.contains(tag.id)) {
                setState(() {
                  _activeTags = [..._activeTags]..remove(tag);
                  widget.onUpdate!(_activeTags);
                });
              }
            }
          }

          return ListTile(
            title: TagWidget(tag: tag),
            leading: widget.onUpdate != null
                ? Checkbox(value: isActive, onChanged: toggleTag)
                : IconButton(
                    onPressed: () =>
                        context.router.push(TagUsersRoute(tag: tag)),
                    icon: Icon(Symbols.person_rounded),
                  ),
            onTap: widget.onUpdate != null ? () => toggleTag(!isActive) : null,
            trailing: IconButton(
              onPressed: () => context.router.push(
                TagEditorRoute(
                  tag: tag,
                  onUpdate: (tag) => setState(() {
                    final newAvailableTags = [..._availableTags];

                    if (tag == null) {
                      newAvailableTags.removeAt(index);
                    } else {
                      newAvailableTags[index] = tag;
                    }

                    setState(() {
                      _availableTags = newAvailableTags;
                    });
                  }),
                ),
              ),
              icon: const Icon(Symbols.edit_rounded),
            ),
          );
        },
      ),
    );
  }
}

@RoutePage()
class TagUsersScreen extends StatefulWidget {
  const TagUsersScreen(this.tag, {super.key});

  final Tag tag;

  @override
  State<TagUsersScreen> createState() => TagUsersScreenState();
}

class TagUsersScreenState extends State<TagUsersScreen> {
  List<String>? _users;

  @override
  void initState() {
    super.initState();

    context
        .read<AppController>()
        .getTagUsers(widget.tag.id)
        .then(
          (users) => setState(() {
            _users = users;
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.tag.tag)),
      body: _users == null
          ? Center(child: CircularProgressIndicator())
          : _users!.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l(context).tags_noUsers,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: _users!
                  .map(
                    (username) => ListTile(
                      title: Text(username),
                      onTap: () async {
                        String name = username;

                        if (name.endsWith(ac.instanceHost)) {
                          name = name.split('@').first;
                        }
                        final user = await ac.api.users.getByName(name);

                        if (!context.mounted) return;

                        context.router.push(
                          UserRoute(userId: user.id, initData: user),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class TagsFloatingButton extends StatelessWidget {
  const TagsFloatingButton({super.key, required this.onUpdate});

  final Function(Tag) onUpdate;

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return FloatingActionButton.extended(
      label: Text(l(context).tags_new),
      icon: Icon(Symbols.add_rounded),
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
        await context.router.push(
          TagEditorRoute(
            tag: tag!,
            onUpdate: (newTag) async {
              cancelled = false;
              if (newTag == null) {
                await ac.removeTag(tag!);
                return;
              }
              onUpdate(newTag);
            },
          ),
        );
        if (cancelled) {
          await ac.removeTag(tag!);
        }
      },
    );
  }
}

@RoutePage()
class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<Tag> _availableTags = [];

  @override
  void initState() {
    super.initState();

    context.read<AppController>().getTags().then(
      (tags) => setState(() {
        _availableTags = tags;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).tags)),
      body: TagsList(availableTags: _availableTags),
      floatingActionButton: TagsFloatingButton(
        onUpdate: (newTag) {
          setState(() {
            _availableTags = [..._availableTags, newTag];
          });
        },
      ),
    );
  }
}
