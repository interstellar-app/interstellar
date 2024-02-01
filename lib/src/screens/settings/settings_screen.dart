import 'package:flutter/material.dart';
import 'package:interstellar/src/api/comment.dart';
import 'package:interstellar/src/screens/feed_screen.dart';
import 'package:interstellar/src/screens/settings/login.dart';
import 'package:interstellar/src/utils/themes.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';

import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = themeModeSelect.options.firstWhere(
      (option) => option.value == controller.themeMode,
    );
    final currentTheme = themeSelect.options.firstWhere(
      (option) => option.value == controller.themeAccent,
    );
    final currentDefaultFeedMode = feedModeSelect.options.firstWhere(
      (option) => option.value == controller.defaultFeedMode,
    );
    final currentDefaultEntriesFeedSort = feedSortSelect.options.firstWhere(
      (option) => option.value == controller.defaultEntriesFeedSort,
    );
    final currentDefaultPostsFeedSort = feedSortSelect.options.firstWhere(
      (option) => option.value == controller.defaultPostsFeedSort,
    );
    final currentDefaultExploreFeedSort = feedSortSelect.options.firstWhere(
      (option) => option.value == controller.defaultExploreFeedSort,
    );
    final currentDefaultCommentSort = commentSortSelect.options.firstWhere(
      (option) => option.value == controller.defaultCommentSort,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            title: const Text('Theme Mode'),
            leading: const Icon(Icons.palette),
            onTap: () async {
              controller.updateThemeMode(
                await themeModeSelect.inquireSelection(
                  context,
                  currentThemeMode.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentThemeMode.icon),
                const SizedBox(width: 4),
                Text(currentThemeMode.title),
              ],
            ),
          ),
          ListTile(
            title: const Text('Theme Accent Color'),
            leading: const Icon(Icons.palette),
            onTap: () async {
              controller.updateThemeAccent(
                await themeSelect.inquireSelection(
                  context,
                  currentTheme.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentTheme.icon),
                const SizedBox(width: 4),
                Text(currentTheme.title),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Feed', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            title: const Text('Default Feed Mode'),
            leading: const Icon(Icons.tab),
            onTap: () async {
              controller.updateDefaultFeedMode(
                await feedModeSelect.inquireSelection(
                  context,
                  currentDefaultFeedMode.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentDefaultFeedMode.icon),
                const SizedBox(width: 4),
                Text(currentDefaultFeedMode.title),
              ],
            ),
          ),
          ListTile(
            title: const Text('Default Threads Feed Sort'),
            leading: const Icon(Icons.sort),
            onTap: () async {
              controller.updateDefaultEntriesFeedSort(
                await feedSortSelect.inquireSelection(
                  context,
                  currentDefaultEntriesFeedSort.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentDefaultEntriesFeedSort.icon),
                const SizedBox(width: 4),
                Text(currentDefaultEntriesFeedSort.title),
              ],
            ),
          ),
          ListTile(
            title: const Text('Default Posts Feed Sort'),
            leading: const Icon(Icons.sort),
            onTap: () async {
              controller.updateDefaultPostsFeedSort(
                await feedSortSelect.inquireSelection(
                  context,
                  currentDefaultPostsFeedSort.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentDefaultPostsFeedSort.icon),
                const SizedBox(width: 4),
                Text(currentDefaultPostsFeedSort.title),
              ],
            ),
          ),
          ListTile(
            title: const Text('Default Explore Feed Sort'),
            leading: const Icon(Icons.sort),
            onTap: () async {
              controller.updateDefaultExploreFeedSort(
                await feedSortSelect.inquireSelection(
                  context,
                  currentDefaultExploreFeedSort.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentDefaultExploreFeedSort.icon),
                const SizedBox(width: 4),
                Text(currentDefaultExploreFeedSort.title),
              ],
            ),
          ),
          ListTile(
            title: const Text('Default Comment Sort'),
            leading: const Icon(Icons.comment),
            onTap: () async {
              controller.updateDefaultCommentSort(
                await commentSortSelect.inquireSelection(
                  context,
                  currentDefaultCommentSort.value,
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentDefaultCommentSort.icon),
                const SizedBox(width: 4),
                Text(currentDefaultCommentSort.title),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Accounts',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...(controller.oauthCredentials.keys.toList()..sort())
              .map((account) => ListTile(
                    title: Text(
                      account,
                      style: TextStyle(
                        fontWeight: account == controller.selectedAccount
                            ? FontWeight.w800
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => controller.setSelectedAccount(account),
                    trailing: IconButton(
                        onPressed: () {
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Remove account'),
                              content: Text(account),
                              actions: <Widget>[
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    controller.removeOAuthCredentials(account);
                                  },
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline)),
                  )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Add Account'),
            ),
          )
        ],
      ),
    );
  }
}

const SelectionMenu<ThemeMode> themeModeSelect = SelectionMenu(
  'Theme Mode',
  [
    SelectionMenuItem(
      value: ThemeMode.system,
      title: 'System',
      icon: Icons.auto_mode,
    ),
    SelectionMenuItem(
      value: ThemeMode.light,
      title: 'Light',
      icon: Icons.light_mode,
    ),
    SelectionMenuItem(
      value: ThemeMode.dark,
      title: 'Dark',
      icon: Icons.dark_mode,
    ),
  ],
);

SelectionMenu<String> themeSelect = SelectionMenu(
  "Theme Accent Color",
  themes.entries
      .map((themeInfo) => SelectionMenuItem(
          value: themeInfo.value.name,
          title: themeInfo.value.name,
          icon: Icons.palette))
      .toList(),
);
