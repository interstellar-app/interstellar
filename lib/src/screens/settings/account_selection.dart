import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/server_software_indicator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

Future<String?> switchAccount(
  BuildContext context, [
  String? oldAccount,
]) async {
  return await showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return AccountSelectWidget(
        oldAccount: oldAccount,
        showAccountControls: true,
      );
    },
  );
}

Future<String?> selectAccountWithNone(
  BuildContext context, [
  String? oldAccount,
]) async {
  return await showModalBottomSheet<String>(
    context: context,
    builder: (BuildContext context) {
      return AccountSelectWidget(oldAccount: oldAccount, showNoneOption: true);
    },
  );
}

class AccountSelectWidget extends StatefulWidget {
  final bool showNoneOption;
  final bool showAccountControls;
  final bool onlyNonGuestAccounts;
  final String? oldAccount;

  const AccountSelectWidget({
    this.showNoneOption = false,
    this.showAccountControls = false,
    this.onlyNonGuestAccounts = false,
    this.oldAccount,
    super.key,
  });

  @override
  State<AccountSelectWidget> createState() => _AccountSelectWidgetState();
}

class _AccountSelectWidgetState extends State<AccountSelectWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final oldAccount = widget.oldAccount ?? ac.selectedAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l(context).account_switch,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (widget.showNoneOption)
                ListTile(
                  title: Text(l(context).profile_autoSelectAccount_none),
                  onTap: () async {
                    context.router.pop('');
                  },
                ),
              ...ac.accounts.keys
                  .where(
                    (account) =>
                        !widget.onlyNonGuestAccounts ||
                        account.split('@').first.isNotEmpty,
                  )
                  .map(
                    (account) => ListTile(
                      title: Row(
                        children: [
                          ServerSoftwareIndicator(
                            label: account,
                            software:
                                ac.servers[account.split('@').last]!.software,
                          ),
                        ],
                      ),
                      onTap: () async {
                        context.router.pop(account);
                      },
                      selected: account == oldAccount,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.2),
                      trailing: widget.showAccountControls
                          ? IconButton(
                              icon: const Icon(Symbols.delete_rounded),
                              onPressed: ac.selectedAccount == account
                                  ? null
                                  : () {
                                      showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            AlertDialog(
                                              title: Text(
                                                l(context).removeAccount,
                                              ),
                                              content: Text(account),
                                              actions: <Widget>[
                                                OutlinedButton(
                                                  onPressed: () =>
                                                      context.router.pop(),
                                                  child: Text(
                                                    l(context).cancel,
                                                  ),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    context.router.pop();
                                                    ac.removeAccount(account);
                                                  },
                                                  child: Text(
                                                    l(context).remove,
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                            )
                          : null,
                    ),
                  ),
              if (widget.showAccountControls)
                ListTile(
                  title: Text(l(context).addAccount),
                  leading: const Icon(Symbols.login_rounded),
                  onTap: () => context.router.push(LoginSelectRoute()),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
