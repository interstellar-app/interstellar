import 'dart:io';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/settings/debug/log_console.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
            leading: const Icon(Symbols.schema_rounded),
            title: Text(l(context).settings_debug_inspectDatabase),
            onTap: () => pushRoute(
              context,
              builder: (context) => DriftDbViewer(database),
            ),
          ),
          ListTile(
            title: Text(l(context).settings_debug_exportDatabase),
            onTap: () async {
              final dbDir = await getApplicationSupportDirectory();
              final dbFile = File(
                join(
                  dbDir.path,
                  '${InterstellarDatabase.databaseFilename}.sqlite',
                ),
              );

              final useBytes = Platform.isAndroid || Platform.isIOS;
              String? filePath;
              try {
                filePath = await FilePicker.platform.saveFile(
                  fileName: InterstellarDatabase.databaseFilename,
                  bytes: useBytes ? dbFile.readAsBytesSync() : null,
                );
                if (filePath == null) return;
              } catch (e) {
                final dir = await getDownloadsDirectory();
                if (dir == null) {
                  throw Exception('Downloads directory not found');
                }
                filePath = join(
                  dir.path,
                  InterstellarDatabase.databaseFilename,
                );
              }

              if (!useBytes) {
                dbFile.copy(filePath);
              }
            },
          ),
          ListTile(
            title: Text(l(context).settings_debug_importDatabase),
            onTap: () async {
              String? filePath;
              try {
                final result = await FilePicker.platform.pickFiles();
                filePath = result?.files.single.path;
              } catch (e) {
                //
              }

              if (filePath == null) return;

              final srcFile = File(filePath);

              final dbDir = await getApplicationSupportDirectory();
              final dbFilepath = join(
                dbDir.path,
                '${InterstellarDatabase.databaseFilename}.sqlite',
              );

              srcFile.copy(dbFilepath);
            },
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
            leading: const Icon(Symbols.mark_email_read_rounded),
            title: Text(l(context).settings_debug_clearReadPosts),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l(context).settings_debug_clearReadPosts),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l(context).cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await database.delete(database.readPostCache).go();
                      ac.logger.i('Cleared read posts');
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
            leading: const Icon(Symbols.download_for_offline_rounded),
            title: Text(l(context).settings_debug_clearFeedCache),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l(context).settings_debug_clearFeedCache),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l(context).cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await database.delete(database.feedInputs).go();
                      ac.logger.i('Cleared feed cache');
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
