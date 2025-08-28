import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/filter_list.dart';
import 'package:interstellar/src/controller/rule.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/screens/feed/create_screen.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_select.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
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
          ...ac.rules.keys.map(
            (name) => Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(name),
                    onTap: () => pushRoute(
                      context,
                      builder: (context) => EditRuleScreen(rule: name),
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        final filterList = context
                            .read<AppController>()
                            .rules[name]!;

                        final config = await ConfigShare.create(
                          type: ConfigShareType.filterList,
                          name: name,
                          payload: filterList.toJson(),
                        );

                        if (!context.mounted) return;
                        String communityName = mbinConfigsCommunityName;
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

                        await pushRoute(
                          context,
                          builder: (context) => CreateScreen(
                            initTitle: '[Rule] $name',
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
                    value: ac.profile.rules[name] == true,
                    onChanged: (value) {
                      ac.updateProfile(
                        ac.selectedProfileValue.copyWith(
                          rules: {
                            ...?ac.selectedProfileValue.rules,
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
            onTap: () => pushRoute(
              context,
              builder: (context) => const EditRuleScreen(rule: null),
            ),
          ),
        ],
      ),
    );
  }
}

class EditRuleScreen extends StatefulWidget {
  final String? rule;
  final Rule? importRule;

  const EditRuleScreen({required this.rule, this.importRule, super.key});

  @override
  State<EditRuleScreen> createState() => _EditRuleScreenState();
}

class _EditRuleScreenState extends State<EditRuleScreen> {
  final nameController = TextEditingController();
  Rule ruleData = Rule.nullRule;

  @override
  void initState() {
    super.initState();

    if (widget.rule != null) {
      nameController.text = widget.rule!;

      if (widget.importRule != null) {
        ruleData = widget.importRule!;
      } else {
        ruleData = context.read<AppController>().rules[widget.rule!]!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.importRule != null
              ? l(context).filterList_import
              : widget.rule == null
              ? l(context).filterList_new
              : l(context).filterList_edit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.rule != null && widget.importRule == null) ...[
            ListTileSwitch(
              title: Text(l(context).filterList_activateFilter),
              value: ac.profile.rules[widget.rule] == true,
              onChanged: (value) {
                ac.updateProfile(
                  ac.selectedProfileValue.copyWith(
                    rules: {
                      ...?ac.selectedProfileValue.rules,
                      widget.rule!: value,
                    },
                  ),
                );
              },
            ),
            const Divider(),
          ],
          TextEditor(
            nameController,
            label: l(context).name,
            onChanged: (_) => setState(() {}),
          ),
          Text('Trigger', style: Theme.of(context).textTheme.titleMedium),
          Text('Conditions', style: Theme.of(context).textTheme.titleMedium),
          Text('Actions', style: Theme.of(context).textTheme.titleMedium),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: LoadingFilledButton(
              icon: const Icon(Symbols.save_rounded),
              onPressed:
                  nameController.text.isEmpty ||
                      ((nameController.text != widget.rule ||
                              widget.importRule != null) &&
                          ac.rules.containsKey(nameController.text))
                  ? null
                  : () async {
                      final name = nameController.text;

                      if (widget.rule == null || widget.importRule != null) {
                        await ac.setRule(name, Rule.nullRule);
                      } else if (name != widget.rule) {
                        await ac.renameRule(widget.rule!, name);
                      }

                      await ac.setRule(name, ruleData);

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
              label: Text(l(context).saveChanges),
            ),
          ),
          if (widget.rule != null && widget.importRule == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.delete_rounded),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(l(context).filterList_delete),
                      content: Text(widget.rule!),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ac.removeRule(widget.rule!);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pop(context);
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
