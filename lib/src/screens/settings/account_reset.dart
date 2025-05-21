import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:provider/provider.dart';

import './account_migration.dart';

class AccountResetScreen extends StatefulWidget {
  const AccountResetScreen({super.key});

  @override
  State<AccountResetScreen> createState() => _AccountResetScreenState();
}

class _AccountResetScreenState extends State<AccountResetScreen> {
  int _index = 0;

  String? _selectedAccount;

  MigrationOrResetProgress _resetProgress = MigrationOrResetProgress.pending;

  final _resetMagazineSubscriptions = MigrationOrResetType<int>();
  final _resetMagazineBlocks = MigrationOrResetType<int>();
  final _resetUserFollows = MigrationOrResetType<int>();
  final _resetUserBlocks = MigrationOrResetType<int>();

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final step1Complete = _selectedAccount != null;

    final isAccountMbin =
        _selectedAccount != null &&
        ac.servers[_selectedAccount!.split('@').last]!.software ==
            ServerSoftware.mbin;

    void resetCommand() async {
      try {
        if (_resetProgress != MigrationOrResetProgress.pending) return;

        // Update widget state to display progress and check for cancels
        bool progressAndCheckCancel() {
          if (mounted) {
            setState(() {});
          }
          return !mounted;
        }

        setState(() {
          _resetProgress = MigrationOrResetProgress.readingSource;
        });
        final api = await ac.getApiForAccount(_selectedAccount!);
        if (_resetMagazineSubscriptions.enabled) {
          String? nextPage;
          do {
            final res = await api.magazines.list(
              page: nextPage,
              filter: ExploreFilter.subscribed,
            );

            _resetMagazineSubscriptions.found.addAll(
              res.items.map((e) => e.id),
            );
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }
        if (_resetMagazineBlocks.enabled && isAccountMbin) {
          String? nextPage;
          do {
            final res = await api.magazines.list(
              page: nextPage,
              filter: ExploreFilter.blocked,
            );

            _resetMagazineBlocks.found.addAll(res.items.map((e) => e.id));
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }
        if (_resetUserFollows.enabled && isAccountMbin) {
          String? nextPage;
          do {
            final res = await api.users.list(
              page: nextPage,
              filter: ExploreFilter.subscribed,
            );

            _resetUserFollows.found.addAll(res.items.map((e) => e.id));
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }
        if (_resetUserBlocks.enabled && isAccountMbin) {
          String? nextPage;
          do {
            final res = await api.users.list(
              page: nextPage,
              filter: ExploreFilter.blocked,
            );

            _resetUserBlocks.found.addAll(res.items.map((e) => e.id));
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }

        setState(() {
          _resetProgress = MigrationOrResetProgress.writingDestination;
        });
        for (var item in _resetMagazineSubscriptions.found) {
          try {
            await api.magazines.subscribe(item, false);
            _resetMagazineSubscriptions.complete.add(item);
          } catch (e) {
            _resetMagazineSubscriptions.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }
        for (var item in _resetMagazineBlocks.found) {
          try {
            await api.magazines.block(item, false);
            _resetMagazineBlocks.complete.add(item);
          } catch (e) {
            _resetMagazineBlocks.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }
        for (var item in _resetUserFollows.found) {
          try {
            await api.users.follow(item, false);
            _resetUserFollows.complete.add(item);
          } catch (e) {
            _resetUserFollows.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }
        for (var item in _resetUserBlocks.found) {
          try {
            await api.users.putBlock(item, false);
            _resetUserBlocks.complete.add(item);
          } catch (e) {
            _resetUserBlocks.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }

        setState(() {
          _resetProgress = MigrationOrResetProgress.complete;
        });
      } catch (_) {
        setState(() {
          _resetProgress = MigrationOrResetProgress.failed;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_accountReset)),
      body: ListView(
        children: switch (_resetProgress) {
          MigrationOrResetProgress.pending => [
            Stepper(
              currentStep: _index,
              onStepCancel: _index > 0
                  ? () {
                      setState(() {
                        _index -= 1;
                      });
                    }
                  : null,
              onStepContinue: step1Complete || _index > 0
                  ? () {
                      if (_index < 2) {
                        setState(() {
                          _index += 1;
                        });
                      } else {
                        resetCommand();
                      }
                    }
                  : null,
              onStepTapped: (int index) {
                setState(() {
                  _index = index;
                });
              },
              steps: [
                Step(
                  title: Text(l(context).settings_accountReset_step1),
                  content: Column(
                    children: [
                      ListTile(
                        title: Text(l(context).settings_accountReset_step1),
                        subtitle: _selectedAccount == null
                            ? null
                            : Text(_selectedAccount!),
                        onTap: () async {
                          final newSourceAccount = await showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return AccountSelectWidget(
                                oldAccount: _selectedAccount ?? '',
                                onlyNonGuestAccounts: true,
                              );
                            },
                          );

                          if (newSourceAccount == null) return;

                          setState(() {
                            _selectedAccount = newSourceAccount;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Step(
                  state: step1Complete ? StepState.indexed : StepState.disabled,
                  title: Text(l(context).settings_accountReset_step2),
                  content: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          l(
                            context,
                          ).settings_accountReset_step2_resetMagazineSubscriptions,
                        ),
                        value: _resetMagazineSubscriptions.enabled,
                        onChanged: (value) => {
                          if (value != null)
                            setState(() {
                              _resetMagazineSubscriptions.enabled = value;
                            }),
                        },
                      ),
                      if (isAccountMbin)
                        CheckboxListTile(
                          title: Text(
                            l(
                              context,
                            ).settings_accountReset_step2_resetMagazineBlocks,
                          ),
                          value: _resetMagazineBlocks.enabled,
                          onChanged: (value) => {
                            if (value != null)
                              setState(() {
                                _resetMagazineBlocks.enabled = value;
                              }),
                          },
                        ),
                      if (isAccountMbin)
                        CheckboxListTile(
                          title: Text(
                            l(
                              context,
                            ).settings_accountReset_step2_resetUserFollows,
                          ),
                          value: _resetUserFollows.enabled,
                          onChanged: (value) => {
                            if (value != null)
                              setState(() {
                                _resetUserFollows.enabled = value;
                              }),
                          },
                        ),
                      if (isAccountMbin)
                        CheckboxListTile(
                          title: Text(
                            l(
                              context,
                            ).settings_accountReset_step2_resetUserBlocks,
                          ),
                          value: _resetUserBlocks.enabled,
                          onChanged: (value) => {
                            if (value != null)
                              setState(() {
                                _resetUserBlocks.enabled = value;
                              }),
                          },
                        ),
                    ],
                  ),
                ),
                Step(
                  state: step1Complete ? StepState.indexed : StepState.disabled,
                  title: Text(l(context).settings_accountReset_step3),
                  content: const Row(children: []),
                ),
              ],
            ),
          ],
          MigrationOrResetProgress.readingSource => [
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(l(context).settings_accountReset_readingFromAccount),
                  Text(
                    l(context).settings_accountReset_foundXItems(
                      _resetMagazineSubscriptions.found.length +
                          _resetMagazineBlocks.found.length +
                          _resetUserFollows.found.length +
                          _resetUserBlocks.found.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
          MigrationOrResetProgress.writingDestination => [
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(l(context).settings_accountReset_removingItems),
                  Text(
                    l(context).settings_accountReset_completeXItems(
                      _resetMagazineSubscriptions.complete.length +
                          _resetMagazineBlocks.complete.length +
                          _resetUserFollows.complete.length +
                          _resetUserBlocks.complete.length,
                      _resetMagazineSubscriptions.found.length +
                          _resetMagazineBlocks.found.length +
                          _resetUserFollows.found.length +
                          _resetUserBlocks.found.length,
                    ),
                  ),
                  Text(
                    l(context).settings_accountReset_failedXItems(
                      _resetMagazineSubscriptions.failed.length +
                          _resetMagazineBlocks.failed.length +
                          _resetUserFollows.failed.length +
                          _resetUserBlocks.failed.length,
                      _resetMagazineSubscriptions.found.length +
                          _resetMagazineBlocks.found.length +
                          _resetUserFollows.found.length +
                          _resetUserBlocks.found.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
          MigrationOrResetProgress.complete => [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(l(context).settings_accountReset_complete),
                  Text(
                    l(context).settings_accountReset_completeXItems(
                      _resetMagazineSubscriptions.complete.length +
                          _resetMagazineBlocks.complete.length +
                          _resetUserFollows.complete.length +
                          _resetUserBlocks.complete.length,
                      _resetMagazineSubscriptions.found.length +
                          _resetMagazineBlocks.found.length +
                          _resetUserFollows.found.length +
                          _resetUserBlocks.found.length,
                    ),
                  ),
                  Text(
                    l(context).settings_accountReset_failedXItems(
                      _resetMagazineSubscriptions.failed.length +
                          _resetMagazineBlocks.failed.length +
                          _resetUserFollows.failed.length +
                          _resetUserBlocks.failed.length,
                      _resetMagazineSubscriptions.found.length +
                          _resetMagazineBlocks.found.length +
                          _resetUserFollows.found.length +
                          _resetUserBlocks.found.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
          MigrationOrResetProgress.failed => [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [Text(l(context).settings_accountReset_failed)],
              ),
            ),
          ],
        },
      ),
    );
  }
}
