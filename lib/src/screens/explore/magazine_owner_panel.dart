import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class MagazineOwnerPanel extends StatefulWidget {
  final DetailedMagazineModel initData;
  final void Function(DetailedMagazineModel) onUpdate;

  const MagazineOwnerPanel({
    super.key,
    required this.initData,
    required this.onUpdate,
  });

  @override
  State<MagazineOwnerPanel> createState() => _MagazineOwnerPanelState();
}

class _MagazineOwnerPanelState extends State<MagazineOwnerPanel> {
  late DetailedMagazineModel _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;
  }

  @override
  Widget build(BuildContext context) {
    onUpdate(DetailedMagazineModel newValue) {
      setState(() {
        _data = newValue;
        widget.onUpdate(newValue);
      });
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Owner Panel for ${widget.initData.name}'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'General'),
              Tab(text: 'Moderators'),
              Tab(text: 'Deletion'),
            ],
          ),
        ),
        body: TabBarView(
          physics: appTabViewPhysics(context),
          children: <Widget>[
            MagazineOwnerPanelGeneral(data: _data, onUpdate: onUpdate),
            MagazineOwnerPanelModerators(data: _data, onUpdate: onUpdate),
            MagazineOwnerPanelDeletion(data: _data, onUpdate: onUpdate),
          ],
        ),
      ),
    );
  }
}

class MagazineOwnerPanelGeneral extends StatefulWidget {
  // Data is null for magazine creation screen
  final DetailedMagazineModel? data;
  final void Function(DetailedMagazineModel) onUpdate;

  const MagazineOwnerPanelGeneral({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<MagazineOwnerPanelGeneral> createState() =>
      _MagazineOwnerPanelGeneralState();
}

class _MagazineOwnerPanelGeneralState extends State<MagazineOwnerPanelGeneral> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late bool _isAdult;
  late bool _isPostingRestrictedToMods;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.data?.name ?? '';
    _titleController.text = widget.data?.title ?? '';
    _descriptionController.text = widget.data?.description ?? '';

    _isAdult = widget.data?.isAdult ?? false;
    _isPostingRestrictedToMods =
        widget.data?.isPostingRestrictedToMods ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final descriptionDraftController = context.watch<DraftsController>().auto(
      'magazine:description${widget.data == null ? '' : ':${widget.data}'}',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.data == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: TextEditor(
              _nameController,
              label: 'Name',
              onChanged: (_) => setState(() {}),
              maxLength: 25,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: TextEditor(
            _titleController,
            label: 'Title',
            onChanged: (_) => setState(() {}),
            maxLength: 50,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: MarkdownEditor(
            _descriptionController,
            originInstance: context.watch<AppController>().instanceHost,
            draftController: descriptionDraftController,
            label: 'Description',
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Is adult'),
                value: _isAdult,
                onChanged: (bool value) {
                  setState(() {
                    _isAdult = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Is posting restricted to mods'),
                value: _isPostingRestrictedToMods,
                onChanged: (bool value) {
                  setState(() {
                    _isPostingRestrictedToMods = value;
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: LoadingFilledButton(
            onPressed:
                _nameController.text.isEmpty ||
                    _titleController.text.isEmpty ||
                    (_titleController.text == widget.data?.title &&
                        _descriptionController.text ==
                            widget.data?.description &&
                        _isAdult == widget.data?.isAdult &&
                        _isPostingRestrictedToMods ==
                            widget.data?.isPostingRestrictedToMods)
                ? null
                : () async {
                    final result = widget.data == null
                        ? await context
                              .read<AppController>()
                              .api
                              .magazineModeration
                              .create(
                                name: _nameController.text,
                                title: _titleController.text,
                                description: _descriptionController.text,
                                isAdult: _isAdult,
                                isPostingRestrictedToMods:
                                    _isPostingRestrictedToMods,
                              )
                        : await context
                              .read<AppController>()
                              .api
                              .magazineModeration
                              .edit(
                                widget.data!.id,
                                title: _titleController.text,
                                description: _descriptionController.text,
                                isAdult: _isAdult,
                                isPostingRestrictedToMods:
                                    _isPostingRestrictedToMods,
                              );

                    await descriptionDraftController.discard();

                    widget.onUpdate(result);
                  },
            label: Text(l(context).save),
          ),
        ),
      ],
    );
  }
}

class MagazineOwnerPanelModerators extends StatefulWidget {
  final DetailedMagazineModel data;
  final void Function(DetailedMagazineModel) onUpdate;

  const MagazineOwnerPanelModerators({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<MagazineOwnerPanelModerators> createState() =>
      _MagazineOwnerPanelModeratorsState();
}

class _MagazineOwnerPanelModeratorsState
    extends State<MagazineOwnerPanelModerators> {
  final TextEditingController _addModController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextEditor(
                _addModController,
                label: 'Add Moderator',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _addModController.text.isEmpty
                  ? null
                  : () async {
                      final user = await context
                          .read<AppController>()
                          .api
                          .users
                          .getByName(_addModController.text);

                      if (!mounted) return;
                      final result = await showDialog<DetailedMagazineModel>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Add Moderator'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              UserItemSimple(UserModel.fromDetailedUser(user)),
                            ],
                          ),
                          actions: <Widget>[
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            LoadingFilledButton(
                              onPressed: () async {
                                Navigator.of(context).pop(
                                  await context
                                      .read<AppController>()
                                      .api
                                      .magazineModeration
                                      .updateModerator(
                                        widget.data.id,
                                        user.id,
                                        true,
                                      ),
                                );
                              },
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                      );

                      if (result != null) widget.onUpdate(result);
                    },
              label: const Text('Add'),
              icon: const Icon(Symbols.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.data.moderators.map(
          (mod) => UserItemSimple(
            mod,
            isOwner: mod.id == widget.data.owner?.id,
            trailingWidgets: [
              IconButton(
                icon: const Icon(Symbols.delete_outline_rounded),
                onPressed: () async {
                  final result = await showDialog<DetailedMagazineModel>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Remove moderator'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserItemSimple(
                            mod,
                            isOwner: mod.id == widget.data.owner?.id,
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        LoadingFilledButton(
                          onPressed: () async {
                            Navigator.of(context).pop(
                              await context
                                  .read<AppController>()
                                  .api
                                  .magazineModeration
                                  .updateModerator(
                                    widget.data.id,
                                    mod.id,
                                    false,
                                  ),
                            );
                          },
                          label: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (result != null) widget.onUpdate(result);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MagazineOwnerPanelDeletion extends StatefulWidget {
  final DetailedMagazineModel data;
  final void Function(DetailedMagazineModel) onUpdate;

  const MagazineOwnerPanelDeletion({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<MagazineOwnerPanelDeletion> createState() =>
      _MagazineOwnerPanelDeletionState();
}

class _MagazineOwnerPanelDeletionState
    extends State<MagazineOwnerPanelDeletion> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: FilledButton(
            onPressed: widget.data.icon == null
                ? null
                : () async {
                    await context
                        .read<AppController>()
                        .api
                        .magazineModeration
                        .removeIcon(widget.data.id);

                    widget.onUpdate(widget.data.copyWith(icon: null));
                  },
            child: const Text('Remove icon'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: FilledButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red),
            ),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) =>
                    MagazineOwnerPanelDeletionDialog(data: widget.data),
              );

              if (result == true) {
                if (!mounted) return;
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete Magazine'),
          ),
        ),
      ],
    );
  }
}

class MagazineOwnerPanelDeletionDialog extends StatefulWidget {
  final DetailedMagazineModel data;

  const MagazineOwnerPanelDeletionDialog({super.key, required this.data});

  @override
  State<MagazineOwnerPanelDeletionDialog> createState() =>
      _MagazineOwnerPanelDeletionDialogState();
}

class _MagazineOwnerPanelDeletionDialogState
    extends State<MagazineOwnerPanelDeletionDialog> {
  final TextEditingController _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final magazineName = widget.data.name;

    return AlertDialog(
      title: const Text('Delete magazine'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WARNING: You are about to delete this magazine and all of its related posts. Type "$magazineName" below to confirm deletion.',
          ),
          const SizedBox(height: 16),
          TextEditor(_confirmController, onChanged: (_) => setState(() {})),
        ],
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        LoadingFilledButton(
          onPressed: _confirmController.text != magazineName
              ? null
              : () async {
                  await context
                      .read<AppController>()
                      .api
                      .magazineModeration
                      .delete(widget.data.id);

                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
          label: const Text('DELETE MAGAZINE'),
        ),
      ],
    );
  }
}
