import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/screens/settings/behavior_screen.dart';
import 'package:interstellar/src/screens/settings/data_utilities.dart';
import 'package:interstellar/src/screens/settings/display_screen.dart';
import 'package:interstellar/src/screens/settings/feed_actions_screen.dart';
import 'package:interstellar/src/screens/settings/feed_defaults_screen.dart';
import 'package:interstellar/src/screens/settings/filter_lists_screen.dart';
import 'package:interstellar/src/screens/settings/notification_screen.dart';
import 'package:interstellar/src/screens/settings/profile_selection.dart';
import 'package:interstellar/src/utils/utils.dart';
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BehaviorSettingsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.palette_rounded),
            title: Text(l(context).settings_display),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DisplaySettingsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.filter_list_rounded),
            title: Text(l(context).settings_feedActions),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FeedActionsSettingsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.tune_rounded),
            title: Text(l(context).settings_feedDefaults),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FeedDefaultSettingsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.filter_1_rounded),
            title: Text(l(context).filterLists),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FilterListsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.notifications_rounded),
            title: Text(l(context).settings_notifications),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            ),
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DataUtilitiesScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.info_rounded),
            title: Text(l(context).settings_about),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
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
            subtitle: Text(ac.selectedAccount),
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
