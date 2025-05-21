import 'package:flutter/material.dart';
import 'package:interstellar/src/screens/settings/account_migration.dart';
import 'package:interstellar/src/screens/settings/account_reset.dart';
import 'package:interstellar/src/utils/utils.dart';

class DataUtilitiesScreen extends StatelessWidget {
  const DataUtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_dataUtilities)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l(context).settings_accountMigration),
            subtitle: Text(l(context).settings_accountMigration_help),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountMigrationScreen(),
              ),
            ),
          ),
          ListTile(
            title: Text(l(context).settings_accountReset),
            subtitle: Text(l(context).settings_accountReset_help),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountResetScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
