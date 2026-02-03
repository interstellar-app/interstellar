import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';

@RoutePage()
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
            onTap: () => context.router.push(const AccountMigrationRoute()),
          ),
          ListTile(
            title: Text(l(context).settings_accountReset),
            subtitle: Text(l(context).settings_accountReset_help),
            onTap: () => context.router.push(const AccountResetRoute()),
          ),
        ],
      ),
    );
  }
}
