import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

Future<void> switchProfileSelect(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return const _ProfileSelectWidget();
    },
  );
}

class _ProfileSelectWidget extends StatefulWidget {
  const _ProfileSelectWidget();

  @override
  State<_ProfileSelectWidget> createState() => _ProfileSelectWidgetState();
}

class _ProfileSelectWidgetState extends State<_ProfileSelectWidget> {
  List<String>? profileList;

  void getProfiles() async {
    final profileNames = await context.read<AppController>().getProfileNames();
    setState(() {
      profileList = profileNames;
    });
  }

  @override
  void initState() {
    super.initState();

    getProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l(context).profile_switch,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l(context).profile_about_title),
                      content: SingleChildScrollView(
                        child: Markdown(
                          l(context).profile_about_body,
                          ac.instanceHost,
                        ),
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () => context.router.pop(),
                          child: Text(l(context).close),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Symbols.help_rounded),
              ),
            ],
          ),
        ),
        if (profileList != null)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...profileList!.map(
                  (profileName) => ListTile(
                    title: Text(profileName),
                    subtitle: profileName == ac.mainProfile
                        ? Text(l(context).profile_main)
                        : null,
                    onTap: () async {
                      context.router.pop();
                      await ac.switchProfiles(profileName);
                    },
                    selected: profileName == ac.selectedProfile,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.2),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await context.router.push(
                              EditProfileRoute(
                                profile: profileName,
                                profileList: profileList!,
                              ),
                            );
                            getProfiles();
                          },
                          icon: const Icon(Symbols.edit_rounded),
                        ),
                        IconButton(
                          onPressed: () async {
                            final profile =
                                (await context.read<AppController>().getProfile(
                                  profileName,
                                )).exportReady();

                            final config = await ConfigShare.create(
                              type: ConfigShareType.profile,
                              name: profileName,
                              payload: profile.toJson(),
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

                            await context.router.push(
                              CreateRoute(
                                initTitle: '[Profile] $profileName',
                                initBody:
                                    'Short description here...\n\n${config.toMarkdown()}',
                                initCommunity: community,
                              ),
                            );
                          },
                          icon: const Icon(Symbols.share_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Symbols.add_rounded),
                  title: Text(l(context).profile_new),
                  onTap: () async {
                    await context.router.push(
                      EditProfileRoute(
                        profile: null,
                        profileList: profileList!,
                      ),
                    );
                    getProfiles();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
      ],
    );
  }
}

@RoutePage()
class EditProfileScreen extends StatefulWidget {
  final String? profile;
  final List<String> profileList;
  final ProfileOptional? importProfile;

  const EditProfileScreen({
    required this.profile,
    required this.profileList,
    this.importProfile,
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();

  bool setAsMain = false;

  bool? oldAutoSelect;
  bool newAutoSelect = false;

  String? autoSelectAccount;

  @override
  void initState() {
    super.initState();

    if (widget.profile != null) {
      nameController.text = widget.profile!;

      if (widget.importProfile == null) {
        newAutoSelect =
            widget.profile == context.read<AppController>().autoSelectProfile;
        oldAutoSelect = newAutoSelect;

        context.read<AppController>().getProfile(widget.profile!).then((value) {
          setState(() {
            autoSelectAccount = value.autoSwitchAccount;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();
    final isMainProfile =
        widget.importProfile == null && widget.profile == ac.mainProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.importProfile != null
              ? l(context).profile_import
              : widget.profile == null
              ? l(context).profile_new
              : l(context).profile_edit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextEditor(
            nameController,
            label: l(context).profile_name,
            onChanged: (_) => setState(() {}),
          ),
          ListTileSwitch(
            title: Text(l(context).profile_setAsMain),
            subtitle: Text(l(context).profile_setAsMain_help),
            value: isMainProfile || setAsMain,
            onChanged: isMainProfile
                ? null
                : (newValue) => setState(() {
                    setAsMain = newValue;
                  }),
          ),
          ListTileSwitch(
            title: Text(l(context).profile_autoSelect),
            value: newAutoSelect,
            onChanged: (newValue) => setState(() {
              newAutoSelect = newValue;
            }),
          ),
          ListTile(
            title: Text(l(context).profile_autoSelectAccount),
            subtitle: Text(
              autoSelectAccount ?? l(context).profile_autoSelectAccount_none,
            ),
            onTap: () async {
              final newAutoSelectAccount = await selectAccountWithNone(
                context,
                autoSelectAccount ?? '',
              );

              if (newAutoSelectAccount == null) return;

              setState(() {
                autoSelectAccount = newAutoSelectAccount.isEmpty
                    ? null
                    : newAutoSelectAccount;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: LoadingFilledButton(
              icon: const Icon(Symbols.save_rounded),
              onPressed:
                  nameController.text.isEmpty ||
                      ((nameController.text != widget.profile ||
                              widget.importProfile != null) &&
                          widget.profileList.contains(nameController.text))
                  ? null
                  : () async {
                      final name = nameController.text;

                      if (widget.profile == null ||
                          widget.importProfile != null) {
                        await ac.setProfile(name, ProfileOptional.nullProfile);
                      } else if (name != widget.profile) {
                        await ac.renameProfile(widget.profile!, name);
                      }

                      if (setAsMain) {
                        await ac.setMainProfile(name);
                      }

                      if (oldAutoSelect != newAutoSelect) {
                        await ac.setAutoSelectProfile(
                          newAutoSelect ? name : null,
                        );
                      }

                      final newProfileValue = await ac.getProfile(name);
                      if (autoSelectAccount !=
                          newProfileValue.autoSwitchAccount) {
                        await ac.setProfile(
                          name,
                          newProfileValue.copyWith(
                            autoSwitchAccount: autoSelectAccount,
                          ),
                        );
                      }

                      if (!context.mounted) return;
                      context.router.pop();
                    },
              label: Text(l(context).saveChanges),
            ),
          ),
          if (widget.profile != null && widget.importProfile == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.delete_rounded),
                onPressed: widget.profile == ac.mainProfile
                    ? null
                    : () {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text(l(context).profile_delete),
                            content: Text(widget.profile!),
                            actions: <Widget>[
                              OutlinedButton(
                                onPressed: () => context.router.pop(),
                                child: Text(l(context).cancel),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  await ac.deleteProfile(widget.profile!);

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
                label: Text(l(context).profile_delete),
              ),
            ),
        ],
      ),
    );
  }
}
