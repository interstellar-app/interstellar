import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen(this.user, this.onUpdate, {super.key});

  final DetailedUserModel user;
  final void Function(DetailedUserModel) onUpdate;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreen();
}

class _ProfileEditScreen extends State<ProfileEditScreen> {
  late TextEditingController? _aboutTextController;
  XFile? _avatarFile;
  bool _deleteAvatar = false;
  XFile? _coverFile;
  bool _deleteCover = false;
  UserSettings? _settings;
  bool _settingsChanged = false;

  @override
  void initState() {
    super.initState();

    _aboutTextController = TextEditingController(text: widget.user.about);
    _initSettings();
  }

  Future<void> _initSettings() async {
    final settings = await context
        .read<AppController>()
        .api
        .users
        .getUserSettings();
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aboutDraftController = context.watch<DraftsController>().auto(
      'profile:about:${context.watch<AppController>().selectedAccount}',
    );

    Future<void> onSave() async {
      if (_settingsChanged) {
        _settings = await context
            .read<AppController>()
            .api
            .users
            .saveUserSettings(_settings!);
      }
      if (!context.mounted) return;

      var user = await context.read<AppController>().api.users.updateProfile(
        _aboutTextController!.text,
      );

      await aboutDraftController.discard();

      if (!context.mounted) return;
      if (_deleteAvatar) {
        user = await context.read<AppController>().api.users.deleteAvatar();
      }
      if (!context.mounted) return;
      if (_deleteCover) {
        user = await context.read<AppController>().api.users.deleteCover();
      }

      if (!context.mounted) return;
      if (_avatarFile != null) {
        user = await context.read<AppController>().api.users.updateAvatar(
          _avatarFile!,
        );
      }
      if (!context.mounted) return;
      if (_coverFile != null) {
        user = await context.read<AppController>().api.users.updateCover(
          _coverFile!,
        );
      }

      if (!context.mounted) return;

      user ??= await context.read<AppController>().api.users.getMe();

      if (!context.mounted) return;

      widget.onUpdate(user);
      context.router.pop();
    }

    final avatarPresent =
        !_deleteAvatar && (widget.user.avatar != null || _avatarFile != null);
    final coverPresent =
        !_deleteCover && (widget.user.cover != null || _coverFile != null);

    return Scaffold(
      appBar: AppBar(title: Text(l(context).account_edit)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              fit: StackFit.passthrough,
              children: [
                Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 3,
                      ),
                      height: coverPresent ? null : 128,
                      margin: const EdgeInsets.only(bottom: 48),
                      child: !coverPresent
                          ? null
                          : _coverFile != null
                          ? Image.file(
                              File(_coverFile!.path),
                              fit: BoxFit.cover,
                            )
                          : AdvancedImage(
                              widget.user.cover!,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned.fill(
                      bottom: 48,
                      child: Material(
                        color: Colors.black.withAlpha(64),
                        child: InkWell(
                          onTap: coverPresent
                              ? () async {
                                  setState(() {
                                    _deleteCover = true;
                                    _coverFile = null;
                                  });
                                }
                              : () async {
                                  final image = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                  );

                                  setState(() {
                                    _deleteCover = false;
                                    _coverFile = image;
                                  });
                                },
                          child: Icon(
                            coverPresent
                                ? Symbols.delete_rounded
                                : Symbols.add_photo_alternate_rounded,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 12,
                  child: Stack(
                    children: [
                      Avatar(
                        avatarPresent ? widget.user.avatar : null,
                        radius: 36,
                        borderRadius: 4,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        overrideImageProvider: _avatarFile == null
                            ? null
                            : FileImage(File(_avatarFile!.path)),
                      ),
                      Positioned.fill(
                        child: Align(
                          child: LoadingIconButton(
                            style: ButtonStyle(
                              fixedSize: const WidgetStatePropertyAll(
                                Size.fromRadius(36),
                              ),
                              iconSize: const WidgetStatePropertyAll(36),
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.black.withAlpha(64),
                              ),
                            ),
                            onPressed: avatarPresent
                                ? () async {
                                    setState(() {
                                      _deleteAvatar = true;
                                      _avatarFile = null;
                                    });
                                  }
                                : () async {
                                    final image = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                    );

                                    setState(() {
                                      _deleteAvatar = false;
                                      _avatarFile = image;
                                    });
                                  },
                            icon: Icon(
                              avatarPresent
                                  ? Symbols.delete_rounded
                                  : Symbols.add_photo_alternate_rounded,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 16,
                  child: LoadingFilledButton(
                    onPressed: onSave,
                    label: Text(l(context).saveChanges),
                    uesHaptics: true,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName ??
                                  widget.user.name.split('@').first,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              widget.user.name.contains('@')
                                  ? '@${widget.user.name}'
                                  : '@${widget.user.name}@${context.watch<AppController>().instanceHost}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: MarkdownEditor(
                      _aboutTextController!,
                      originInstance: null,
                      draftController: aboutDraftController,
                      label: l(context).account_settings_about,
                    ),
                  ),
                  if (_settings != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        children: [
                          Text(
                            l(context).account_settings_settings,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SwitchListTile(
                            title: Text(l(context).account_settings_showNSFW),
                            value: _settings!.showNSFW,
                            onChanged: (bool value) {
                              setState(() {
                                _settings!.showNSFW = value;
                                _settingsChanged = true;
                              });
                            },
                          ),
                          if (_settings!.blurNSFW != null)
                            SwitchListTile(
                              title: Text(l(context).account_settings_blurNSFW),
                              value: _settings!.blurNSFW!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.blurNSFW = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                          if (_settings!.showReadPosts != null)
                            SwitchListTile(
                              title: Text(
                                l(context).account_settings_showReadPosts,
                              ),
                              value: _settings!.showReadPosts!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.showReadPosts = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                          if (_settings!.showSubscribedUsers != null)
                            SwitchListTile(
                              title: Text(
                                l(context).account_settings_showSubscribedUsers,
                              ),
                              value: _settings!.showSubscribedUsers!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.showSubscribedUsers = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                          if (_settings!.showSubscribedCommunities != null)
                            SwitchListTile(
                              title: Text(
                                l(
                                  context,
                                ).account_settings_showSubscribedCommunities,
                              ),
                              value: _settings!.showSubscribedCommunities!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.showSubscribedCommunities = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                          if (_settings!.showSubscribedDomains != null)
                            SwitchListTile(
                              title: Text(
                                l(
                                  context,
                                ).account_settings_showSubscribedDomains,
                              ),
                              value: _settings!.showSubscribedDomains!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.showSubscribedDomains = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                          if (_settings!.showProfileSubscriptions != null)
                            SwitchListTile(
                              title: Text(
                                l(
                                  context,
                                ).account_settings_showProfileSubscriptions,
                              ),
                              value: _settings!.showProfileSubscriptions!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.showProfileSubscriptions = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                          if (_settings!.showProfileFollowings != null)
                            SwitchListTile(
                              title: Text(
                                l(
                                  context,
                                ).account_settings_showProfileFollowings,
                              ),
                              value: _settings!.showProfileFollowings!,
                              onChanged: (bool? value) {
                                setState(() {
                                  _settings!.showProfileFollowings = value;
                                  _settingsChanged = true;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
