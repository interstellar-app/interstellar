import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/screens/settings/profile_selection.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/server_software_indicator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Symbols.settings_rounded),
            title: Text(l(context).settings_behavior),
            onTap: () => context.router.push(BehaviorSettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.palette_rounded),
            title: Text(l(context).settings_display),
            onTap: () => context.router.push(DisplaySettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.feed_rounded),
            title: Text(l(context).feeds),
            onTap: () => context.router.push(FeedSettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.filter_list_rounded),
            title: Text(l(context).settings_feedActions),
            onTap: () => context.router.push(FeedActionsSettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.tune_rounded),
            title: Text(l(context).settings_feedDefaults),
            onTap: () => context.router.push(FeedDefaultSettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.label_rounded),
            title: Text(l(context).tags),
            onTap: () => context.router.push(TagsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.filter_1_rounded),
            title: Text(l(context).filterLists),
            onTap: () => context.router.push(FilterListsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.notifications_rounded),
            title: Text(l(context).settings_notifications),
            onTap: () => context.router.push(NotificationSettingsRoute()),
            enabled:
                ac.serverSoftware == ServerSoftware.mbin &&
                context
                    .watch<AppController>()
                    .selectedAccount
                    .split('@')
                    .first
                    .isNotEmpty,
          ),
          ListTile(
            leading: const Icon(Symbols.database_rounded),
            title: Text(l(context).settings_dataUtilities),
            onTap: () => context.router.push(DataUtilitiesRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.info_rounded),
            title: Text(l(context).settings_about),
            onTap: () => context.router.push(AboutRoute()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.tune_rounded),
            title: Text(l(context).profile_switch),
            subtitle: Text(ac.selectedProfile),
            onTap: () => switchProfileSelect(context),
          ),
          ListTile(
            leading: const Icon(Symbols.person_rounded),
            title: Text(l(context).account_switch),
            subtitle: Row(
              children: [
                ServerSoftwareIndicator(
                  label: ac.selectedAccount,
                  software: ac.serverSoftware,
                ),
              ],
            ),
            onTap: () async {
              final newAccount = await switchAccount(context);

              if (newAccount == null || newAccount == ac.selectedAccount) {
                return;
              }

              await ac.switchAccounts(newAccount);
            },
          ),
        ],
      ),
    );
  }
}
