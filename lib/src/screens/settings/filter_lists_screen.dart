import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/filter_list.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_select.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class FilterListsScreen extends StatefulWidget {
  const FilterListsScreen({super.key});

  @override
  State<FilterListsScreen> createState() => _FilterListsScreenState();
}

class _FilterListsScreenState extends State<FilterListsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).filterLists)),
      body: ListView(
        children: [
          ...ac.filterLists.keys.map(
            (name) => Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(name),
                    onTap: () => context.router.push(
                      EditFilterListRoute(filterList: name),
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        final filterList = context
                            .read<AppController>()
                            .filterLists[name]!;

                        final config = await ConfigShare.create(
                          type: ConfigShareType.filterList,
                          name: name,
                          payload: filterList.toJson(),
                        );

                        if (!context.mounted) return;
                        var communityName = mbinConfigsCommunityName;
                        if (communityName.endsWith(
                          context.read<AppController>().instanceHost,
                        )) {
                          communityName = communityName.split('@').first;
                        }

                        final community = await context
                            .read<AppController>()
                            .api
                            .community
                            .getByName(communityName);

                        if (!context.mounted) return;

                        await context.router.push(
                          CreateRoute(
                            initTitle: '[Filter List] $name',
                            initBody:
                                'Short description here...\n\n${config.toMarkdown()}',
                            initCommunity: community,
                          ),
                        );
                      },
                      icon: const Icon(Symbols.share_rounded),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Switch(
                    value: ac.profile.filterLists[name] ?? false,
                    onChanged: (value) {
                      ac.updateProfile(
                        ac.selectedProfileValue.copyWith(
                          filterLists: {
                            ...?ac.selectedProfileValue.filterLists,
                            name: value,
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.add_rounded),
            title: Text(l(context).filterList_new),
            onTap: () =>
                context.router.push(EditFilterListRoute(filterList: null)),
          ),
        ],
      ),
    );
  }
}

@RoutePage()
class EditFilterListScreen extends StatefulWidget {
  const EditFilterListScreen({
    @PathParam('filterList') required this.filterList,
    this.importFilterList,
    super.key,
  });

  final String? filterList;
  final FilterList? importFilterList;

  @override
  State<EditFilterListScreen> createState() => _EditFilterListScreenState();
}

class _EditFilterListScreenState extends State<EditFilterListScreen> {
  final nameController = TextEditingController();
  FilterList filterListData = FilterList.nullFilterList;

  @override
  void initState() {
    super.initState();

    if (widget.filterList != null) {
      nameController.text = widget.filterList!;

      if (widget.importFilterList != null) {
        filterListData = widget.importFilterList!;
      } else {
        filterListData = context
            .read<AppController>()
            .filterLists[widget.filterList!]!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.importFilterList != null
              ? l(context).filterList_import
              : widget.filterList == null
              ? l(context).filterList_new
              : l(context).filterList_edit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.filterList != null && widget.importFilterList == null) ...[
            ListTileSwitch(
              title: Text(l(context).filterList_activateFilter),
              value: ac.profile.filterLists[widget.filterList] ?? false,
              onChanged: (value) {
                ac.updateProfile(
                  ac.selectedProfileValue.copyWith(
                    filterLists: {
                      ...?ac.selectedProfileValue.filterLists,
                      widget.filterList!: value,
                    },
                  ),
                );
              },
            ),
            const Divider(),
          ],
          TextEditor(
            nameController,
            label: l(context).filterList_name,
            onChanged: (_) => setState(() {}),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l(context).filterList_phrases),
              ),
              Flexible(
                child: Wrap(
                  children: [
                    ...(filterListData.phrases.map(
                      (phrase) => Padding(
                        padding: const EdgeInsets.all(2),
                        child: InputChip(
                          label: Text(phrase),
                          onDeleted: () async {
                            final newPhrases = filterListData.phrases.toSet()
                              ..remove(phrase);

                            setState(() {
                              filterListData = filterListData.copyWith(
                                phrases: newPhrases,
                              );
                            });
                          },
                        ),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: IconButton(
                        onPressed: () async {
                          final phraseTextEditingController =
                              TextEditingController();

                          final phrase = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l(context).filterList_addPhrase),
                              content: TextEditor(phraseTextEditingController),
                              actions: [
                                OutlinedButton(
                                  onPressed: () {
                                    context.router.pop();
                                  },
                                  child: Text(l(context).cancel),
                                ),
                                LoadingFilledButton(
                                  onPressed: () async {
                                    context.router.pop(
                                      phraseTextEditingController.text,
                                    );
                                  },
                                  label: Text(l(context).filterList_addPhrase),
                                ),
                              ],
                            ),
                          );

                          if (phrase == null) return;

                          final newPhrases = filterListData.phrases.toSet()
                            ..add(phrase);

                          setState(() {
                            filterListData = filterListData.copyWith(
                              phrases: newPhrases,
                            );
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ListTileSwitch(
            title: Text(l(context).filterList_showWithContentWarning),
            value: filterListData.showWithWarning,
            onChanged: (value) => setState(() {
              filterListData = filterListData.copyWith(showWithWarning: value);
            }),
          ),
          ListTileSelect<FilterListMatchMode>(
            title: l(context).filterList_matchMode,
            selectionMenu: _filterListMatchModeSelect(context),
            value: filterListData.matchMode,
            oldValue: filterListData.matchMode,
            onChange: (newValue) => setState(() {
              filterListData = filterListData.copyWith(matchMode: newValue);
            }),
          ),
          ListTileSwitch(
            title: Text(l(context).filterList_caseSensitive),
            subtitle: Text(l(context).filterList_caseSensitive_help),
            value: filterListData.caseSensitive,
            onChanged: (value) => setState(() {
              filterListData = filterListData.copyWith(caseSensitive: value);
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: LoadingFilledButton(
              icon: const Icon(Symbols.save_rounded),
              onPressed:
                  nameController.text.isEmpty ||
                      ((nameController.text != widget.filterList ||
                              widget.importFilterList != null) &&
                          ac.filterLists.containsKey(nameController.text))
                  ? null
                  : () async {
                      final name = nameController.text;

                      if (widget.filterList == null ||
                          widget.importFilterList != null) {
                        await ac.setFilterList(name, FilterList.nullFilterList);
                      } else if (name != widget.filterList) {
                        await ac.renameFilterList(widget.filterList!, name);
                      }

                      await ac.setFilterList(name, filterListData);

                      if (!context.mounted) return;
                      context.router.pop();
                    },
              label: Text(l(context).saveChanges),
            ),
          ),
          if (widget.filterList != null && widget.importFilterList == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.delete_rounded),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(l(context).filterList_delete),
                      content: Text(widget.filterList!),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => context.router.pop(),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ac.removeFilterList(widget.filterList!);

                            if (!context.mounted) return;
                            context.router.pop();
                            context.router.pop();
                          },
                          child: Text(l(context).delete),
                        ),
                      ],
                    ),
                  );
                },
                label: Text(l(context).filterList_delete),
              ),
            ),
        ],
      ),
    );
  }
}

SelectionMenu<FilterListMatchMode> _filterListMatchModeSelect(
  BuildContext context,
) => SelectionMenu(l(context).filterList_matchMode, [
  SelectionMenuItem(
    value: FilterListMatchMode.simple,
    title: l(context).filterList_matchMode_simple,
    subtitle: l(context).filterList_matchMode_simple_help,
  ),
  SelectionMenuItem(
    value: FilterListMatchMode.wholeWords,
    title: l(context).filterList_matchMode_wholeWords,
    subtitle: l(context).filterList_matchMode_wholeWords_help,
  ),
  SelectionMenuItem(
    value: FilterListMatchMode.regex,
    title: l(context).filterList_matchMode_regex,
    subtitle: l(context).filterList_matchMode_regex_help,
  ),
]);
