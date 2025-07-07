import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class CommunityOwnerPanel extends StatefulWidget {
  final DetailedCommunityModel initData;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityOwnerPanel({
    super.key,
    required this.initData,
    required this.onUpdate,
  });

  @override
  State<CommunityOwnerPanel> createState() => _CommunityOwnerPanelState();
}

class _CommunityOwnerPanelState extends State<CommunityOwnerPanel> {
  late DetailedCommunityModel _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;
  }

  @override
  Widget build(BuildContext context) {
    onUpdate(DetailedCommunityModel newValue) {
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
            CommunityOwnerPanelGeneral(data: _data, onUpdate: onUpdate),
            CommunityOwnerPanelModerators(data: _data, onUpdate: onUpdate),
            CommunityOwnerPanelDeletion(data: _data, onUpdate: onUpdate),
          ],
        ),
      ),
    );
  }
}

class CommunityOwnerPanelGeneral extends StatefulWidget {
  // Data is null for community creation screen
  final DetailedCommunityModel? data;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityOwnerPanelGeneral({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<CommunityOwnerPanelGeneral> createState() =>
      _CommunityOwnerPanelGeneralState();
}

class _CommunityOwnerPanelGeneralState
    extends State<CommunityOwnerPanelGeneral> {
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
      'community:description${widget.data == null ? '' : ':${widget.data}'}',
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
                    final ac = context.read<AppController>();
                    final result = widget.data == null
                        ? await ac
                              .api
                              .communityModeration
                              .create(
                                name: _nameController.text,
                                title: _titleController.text,
                                description: _descriptionController.text,
                                isAdult: _isAdult,
                                isPostingRestrictedToMods:
                                    _isPostingRestrictedToMods,
                              )
                        : await ac
                              .api
                              .communityModeration
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

class CommunityOwnerPanelModerators extends StatefulWidget {
  final DetailedCommunityModel data;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityOwnerPanelModerators({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<CommunityOwnerPanelModerators> createState() =>
      _CommunityOwnerPanelModeratorsState();
}

class _CommunityOwnerPanelModeratorsState
    extends State<CommunityOwnerPanelModerators> {
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

                      if (!context.mounted) return;
                      final result = await showDialog<DetailedCommunityModel>(
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
                                      .communityModeration
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
                  final result = await showDialog<DetailedCommunityModel>(
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
                                  .communityModeration
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

class CommunityOwnerPanelDeletion extends StatefulWidget {
  final DetailedCommunityModel data;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityOwnerPanelDeletion({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<CommunityOwnerPanelDeletion> createState() =>
      _CommunityOwnerPanelDeletionState();
}

class _CommunityOwnerPanelDeletionState
    extends State<CommunityOwnerPanelDeletion> {
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
                        .communityModeration
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
                    CommunityOwnerPanelDeletionDialog(data: widget.data),
              );

              if (result == true) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete Community'),
          ),
        ),
      ],
    );
  }
}

class CommunityOwnerPanelDeletionDialog extends StatefulWidget {
  final DetailedCommunityModel data;

  const CommunityOwnerPanelDeletionDialog({super.key, required this.data});

  @override
  State<CommunityOwnerPanelDeletionDialog> createState() =>
      _CommunityOwnerPanelDeletionDialogState();
}

class _CommunityOwnerPanelDeletionDialogState
    extends State<CommunityOwnerPanelDeletionDialog> {
  final TextEditingController _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final communityName = widget.data.name;

    return AlertDialog(
      title: const Text('Delete community'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WARNING: You are about to delete this community and all of its related posts. Type "$communityName" below to confirm deletion.',
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
          onPressed: _confirmController.text != communityName
              ? null
              : () async {
                  await context
                      .read<AppController>()
                      .api
                      .communityModeration
                      .delete(widget.data.id);

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                },
          label: const Text('DELETE COMMUNITY'),
        ),
      ],
    );
  }
}
