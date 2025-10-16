import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/settings/debug/log_console.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/controller/database.dart';

class DebugSettingsScreen extends StatelessWidget {
  const DebugSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_debug)),
      body: ListView(
        children: [
          ListTileSwitch(
            leading: const Icon(Symbols.error_rounded),
            title: Text(l(context).settings_debug_showErrors),
            value: ac.profile.showErrors,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(showErrors: newValue),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.storage_rounded),
            title: Text(l(context).settings_debug_clearDatabase),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l(context).settings_debug_clearDatabase),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l(context).cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await deleteTables();
                      ac.logger.i('Cleared database');
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(l(context).remove),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.person_rounded),
            title: Text(l(context).settings_debug_clearAccounts),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l(context).settings_debug_clearAccounts),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l(context).cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      for (var account in ac.accounts.keys) {
                        ac.removeAccount(account);
                      }
                      ac.logger.i('Cleared accounts');
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(l(context).remove),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.tune_rounded),
            title: Text(l(context).settings_debug_clearProfiles),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l(context).settings_debug_clearProfiles),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l(context).cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final profileNames = await ac.getProfileNames();
                      for (var profile in profileNames) {
                        ac.deleteProfile(profile);
                      }
                      ac.logger.i('Cleared profiles');
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(l(context).remove),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.list_rounded),
            title: Text(l(context).settings_debug_log),
            onTap: () => pushRoute(context, builder: (context) => LogConsole()),
          ),
        ],
      ),
    );
  }
}
