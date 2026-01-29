import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();

    _initSettings();
  }

  void _initSettings() async {
    final settings = await context
        .read<AppController>()
        .api
        .users
        .getUserSettings();
    setState(() {
      _settings = settings;
    });
  }

  void _saveSettings() async {
    final settings = await context
        .read<AppController>()
        .api
        .users
        .saveUserSettings(_settings!);
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_notificationsForX(ac.selectedAccount)),
      ),
      body: ListView(
        children: [
          if (PlatformUtils.isAndroid) ...[
            ListTileSwitch(
              leading: const Icon(Symbols.notifications_active_rounded),
              title: Text(
                context.watch<AppController>().isPushRegistered
                    ? l(context).notifications_unregisterPush
                    : l(context).notifications_registerPush,
              ),
              value: ac.isPushRegistered,
              onChanged: (bool? value) async {
                if (value == true) {
                  await ac.registerPush(context);
                } else if (value == false) {
                  await ac.unregisterPush();
                }
              },
            ),
            const Divider(),
          ],
          if (_settings != null) ...[
            ListTileSwitch(
              title: Text(l(context).account_settings_notifyOnThread),
              value: _settings!.notifyOnNewEntry!,
              onChanged: (bool? value) {
                setState(() {
                  _settings!.notifyOnNewEntry = value!;
                  _saveSettings();
                });
              },
            ),
            ListTileSwitch(
              title: Text(l(context).account_settings_notifyOnMicroblog),
              value: _settings!.notifyOnNewPost!,
              onChanged: (bool? value) {
                setState(() {
                  _settings!.notifyOnNewPost = value!;
                  _saveSettings();
                });
              },
            ),
            ListTileSwitch(
              title: Text(l(context).account_settings_notifyOnThreadReply),
              value: _settings!.notifyOnNewEntryReply!,
              onChanged: (bool? value) {
                setState(() {
                  _settings!.notifyOnNewEntryReply = value!;
                  _saveSettings();
                });
              },
            ),
            ListTileSwitch(
              title: Text(
                l(context).account_settings_notifyOnThreadCommentReply,
              ),
              value: _settings!.notifyOnNewEntryCommentReply!,
              onChanged: (bool? value) {
                setState(() {
                  _settings!.notifyOnNewEntryCommentReply = value!;
                  _saveSettings();
                });
              },
            ),
            ListTileSwitch(
              title: Text(l(context).account_settings_notifyOnMicroblogReply),
              value: _settings!.notifyOnNewPostReply!,
              onChanged: (bool? value) {
                setState(() {
                  _settings!.notifyOnNewPostReply = value!;
                  _saveSettings();
                });
              },
            ),
            ListTileSwitch(
              title: Text(
                l(context).account_settings_notifyOnMicroblogCommentReply,
              ),
              value: _settings!.notifyOnNewPostCommentReply!,
              onChanged: (bool? value) {
                setState(() {
                  _settings!.notifyOnNewPostCommentReply = value!;
                  _saveSettings();
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
