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
      appBar: AppBar(title: Text(l(context).rules)),
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
                        final rule = context.read<AppController>().rules[name]!;

                        final config = await ConfigShare.create(
                          type: ConfigShareType.rule,
                          name: name,
                          payload: rule.toJson(),
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
            title: Text(l(context).rule_new),
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

    print(ruleData.toJson());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.importRule != null
              ? l(context).rule_import
              : widget.rule == null
              ? l(context).rule_new
              : l(context).rule_edit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.rule != null && widget.importRule == null) ...[
            ListTileSwitch(
              title: Text(l(context).rule_activate),
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
          ruleData.condition == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Add a condition that needs to be satisfied for the rule to run.',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              ruleData = ruleData.copyWith(
                                condition: RuleCondition(and: []),
                              );
                            });
                          },
                          child: Text('AND'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              ruleData = ruleData.copyWith(
                                condition: RuleCondition(or: []),
                              );
                            });
                          },
                          child: Text('OR'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              ruleData = ruleData.copyWith(
                                condition: RuleCondition(field: ''),
                              );
                            });
                          },
                          child: Text('FIELD'),
                        ),
                      ],
                    ),
                  ],
                )
              : RuleConditionItem(ruleData.condition!, (newValue) {
                  setState(() {
                    ruleData = ruleData.copyWith(condition: newValue);
                  });
                }),
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
                      title: Text(l(context).rule_delete),
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
                label: Text(l(context).rule_delete),
              ),
            ),
        ],
      ),
    );
  }
}

class RuleConditionItem extends StatelessWidget {
  final RuleCondition condition;
  final void Function(RuleCondition? newValue) onChange;

  const RuleConditionItem(this.condition, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    final fieldSegments = (condition.field ?? '').split('.');

    List<Widget> widgets = [];

    RuleField currentField = RuleFieldRoot();

    for (var i = 0; i < fieldSegments.length; i++) {
      if (currentField.subfields != null) {
        widgets.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                isSelected: condition.not == true,
                color: condition.not == true ? Colors.red : null,
                onPressed: () {
                  onChange(
                    condition.copyWith(
                      not: condition.not == true ? null : true,
                    ),
                  );
                },
                icon: Icon(Symbols.swap_horiz_rounded),
                tooltip: condition.not == true ? 'Uninvert' : 'Invert',
              ),
              IconButton(
                onPressed: () {
                  onChange(null);
                },
                icon: Icon(Symbols.close_rounded),
                tooltip: 'Remove',
              ),
              DropdownMenu(
                initialSelection: condition.and != null
                    ? 'AND'
                    : condition.or != null
                    ? 'OR'
                    : fieldSegments[i],
                onSelected: (newValue) {
                  if (newValue == 'AND') {
                    onChange(
                      RuleCondition(
                        and: condition.and ?? condition.or ?? [],
                        not: condition.not,
                      ),
                    );
                  } else if (newValue == 'OR') {
                    onChange(
                      RuleCondition(
                        or: condition.or ?? condition.and ?? [],
                        not: condition.not,
                      ),
                    );
                  } else {
                    onChange(
                      RuleCondition(
                        field: [...fieldSegments.take(i), newValue].join('.'),
                        not: condition.not,
                      ),
                    );
                  }
                },
                dropdownMenuEntries: [
                  if (i == 0) ...[
                    DropdownMenuEntry(value: 'AND', label: 'AND'),
                    DropdownMenuEntry(value: 'OR', label: 'OR'),
                  ],
                  ...currentField.subfields!.map(
                    (subfield) => DropdownMenuEntry(
                      value: subfield.id,
                      label: subfield.getName(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        // final nextField = currentField.getSubfield(fieldId);
        // if (nextField == null) break;
        // currentField = nextField;
      }
    }

    if (condition.and != null || condition.or != null) {
      final isAnd = condition.and != null;
      final subConditions = (isAnd ? condition.and : condition.or)!;

      widgets.add(
        Container(
          margin: EdgeInsets.only(left: 8),
          padding: EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...subConditions
                  .asMap()
                  .map(
                    (i, subCondition) => MapEntry(
                      i,
                      RuleConditionItem(subCondition, (newValue) {
                        final newList = [...subConditions];
                        if (newValue != null) {
                          newList[i] = newValue;
                        } else {
                          newList.removeAt(i);
                        }
                        onChange(
                          isAnd
                              ? RuleCondition(and: newList, not: condition.not)
                              : RuleCondition(or: newList, not: condition.not),
                        );
                      }),
                    ),
                  )
                  .values,
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      final newList = [...subConditions];
                      newList.add(RuleCondition(and: []));
                      onChange(
                        isAnd
                            ? RuleCondition(and: newList, not: condition.not)
                            : RuleCondition(or: newList, not: condition.not),
                      );
                    },
                    child: Text('AND'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final newList = [...subConditions];
                      newList.add(RuleCondition(or: []));
                      onChange(
                        isAnd
                            ? RuleCondition(and: newList, not: condition.not)
                            : RuleCondition(or: newList, not: condition.not),
                      );
                    },
                    child: Text('OR'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final newList = [...subConditions];
                      newList.add(RuleCondition(field: ''));
                      onChange(
                        isAnd
                            ? RuleCondition(and: newList, not: condition.not)
                            : RuleCondition(or: newList, not: condition.not),
                      );
                    },
                    child: Text('FIELD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
