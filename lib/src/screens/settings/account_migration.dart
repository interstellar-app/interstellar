import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:provider/provider.dart';

class AccountMigrationScreen extends StatefulWidget {
  const AccountMigrationScreen({super.key});

  @override
  State<AccountMigrationScreen> createState() => _AccountMigrationScreenState();
}

class _AccountMigrationScreenState extends State<AccountMigrationScreen> {
  int _index = 0;

  String? _sourceAccount;
  String? _destinationAccount;

  MigrationOrResetProgress _migrationProgress =
      MigrationOrResetProgress.pending;

  final _migrateMagazineSubscriptions = MigrationOrResetType<String>();
  final _migrateMagazineBlocks = MigrationOrResetType<String>();
  final _migrateUserFollows = MigrationOrResetType<String>();
  final _migrateUserBlocks = MigrationOrResetType<String>();

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final step1Complete =
        _sourceAccount != null &&
        _destinationAccount != null &&
        _sourceAccount != _destinationAccount;

    final sourceIsMbin =
        _sourceAccount != null &&
        ac.servers[_sourceAccount!.split('@').last]!.software ==
            ServerSoftware.mbin;
    final bothAccountsMbin =
        sourceIsMbin &&
        _destinationAccount != null &&
        ac.servers[_destinationAccount!.split('@').last]!.software ==
            ServerSoftware.mbin;

    void migrationCommand() async {
      try {
        if (_migrationProgress != MigrationOrResetProgress.pending) return;

        // Update widget state to display progress and check for cancels
        bool progressAndCheckCancel() {
          if (mounted) {
            setState(() {});
          }
          return !mounted;
        }

        setState(() {
          _migrationProgress = MigrationOrResetProgress.readingSource;
        });
        final sourceAPI = await ac.getApiForAccount(_sourceAccount!);
        final sourceAccountHost = _sourceAccount!.split('@').last;
        if (_migrateMagazineSubscriptions.enabled) {
          String? nextPage;
          do {
            final res = await sourceAPI.magazines.list(
              page: nextPage,
              filter: ExploreFilter.subscribed,
            );

            _migrateMagazineSubscriptions.found.addAll(
              res.items.map((e) => normalizeName(e.name, sourceAccountHost)),
            );
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }
        if (_migrateMagazineBlocks.enabled && sourceIsMbin) {
          String? nextPage;
          do {
            final res = await sourceAPI.magazines.list(
              page: nextPage,
              filter: ExploreFilter.blocked,
            );

            _migrateMagazineBlocks.found.addAll(
              res.items.map((e) => normalizeName(e.name, sourceAccountHost)),
            );
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }
        if (_migrateUserFollows.enabled && bothAccountsMbin) {
          String? nextPage;
          do {
            final res = await sourceAPI.users.list(
              page: nextPage,
              filter: ExploreFilter.subscribed,
            );

            _migrateUserFollows.found.addAll(
              res.items.map((e) => normalizeName(e.name, sourceAccountHost)),
            );
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }
        if (_migrateUserBlocks.enabled && sourceIsMbin) {
          String? nextPage;
          do {
            final res = await sourceAPI.users.list(
              page: nextPage,
              filter: ExploreFilter.blocked,
            );

            _migrateUserBlocks.found.addAll(
              res.items.map((e) => normalizeName(e.name, sourceAccountHost)),
            );
            nextPage = res.nextPage;

            if (progressAndCheckCancel()) return;
          } while (nextPage != null);
        }

        setState(() {
          _migrationProgress = MigrationOrResetProgress.writingDestination;
        });
        final destAPI = await ac.getApiForAccount(_destinationAccount!);
        final destAccountHost = _destinationAccount!.split('@').last;
        for (var item in _migrateMagazineSubscriptions.found) {
          try {
            final res = await destAPI.magazines.getByName(
              denormalizeName(item, destAccountHost),
            );
            if (res.isUserSubscribed == false) {
              await destAPI.magazines.subscribe(res.id, true);
            }
            _migrateMagazineSubscriptions.complete.add(item);
          } catch (e) {
            _migrateMagazineSubscriptions.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }
        for (var item in _migrateMagazineBlocks.found) {
          try {
            final res = await destAPI.magazines.getByName(
              denormalizeName(item, destAccountHost),
            );
            if (res.isBlockedByUser == false) {
              await destAPI.magazines.block(res.id, true);
            }
            _migrateMagazineBlocks.complete.add(item);
          } catch (e) {
            _migrateMagazineBlocks.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }
        for (var item in _migrateUserFollows.found) {
          try {
            final res = await destAPI.users.getByName(
              denormalizeName(item, destAccountHost),
            );
            if (res.isFollowedByUser == false) {
              await destAPI.users.follow(res.id, true);
            }
            _migrateUserFollows.complete.add(item);
          } catch (e) {
            _migrateUserFollows.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }
        for (var item in _migrateUserBlocks.found) {
          try {
            final res = await destAPI.users.getByName(
              denormalizeName(item, destAccountHost),
            );
            if (res.isBlockedByUser == false) {
              await destAPI.users.putBlock(res.id, true);
            }
            _migrateUserBlocks.complete.add(item);
          } catch (e) {
            _migrateUserBlocks.failed.add(item);
          }
          if (progressAndCheckCancel()) return;
        }

        setState(() {
          _migrationProgress = MigrationOrResetProgress.complete;
        });
      } catch (_) {
        setState(() {
          _migrationProgress = MigrationOrResetProgress.failed;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_accountMigration)),
      body: ListView(
        children: switch (_migrationProgress) {
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
                        migrationCommand();
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
                  state: _sourceAccount == null || _destinationAccount == null
                      ? StepState.editing
                      : _sourceAccount == _destinationAccount
                      ? StepState.error
                      : StepState.complete,
                  title: Text(l(context).settings_accountMigration_step1),
                  content: Column(
                    children: [
                      ListTile(
                        title: Text(
                          l(context).settings_accountMigration_step1_source,
                        ),
                        subtitle: _sourceAccount == null
                            ? null
                            : Text(_sourceAccount!),
                        onTap: () async {
                          final newSourceAccount = await showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return AccountSelectWidget(
                                oldAccount: _sourceAccount ?? '',
                                onlyNonGuestAccounts: true,
                              );
                            },
                          );

                          if (newSourceAccount == null) return;

                          setState(() {
                            _sourceAccount = newSourceAccount;
                          });
                        },
                      ),
                      ListTile(
                        title: Text(
                          l(
                            context,
                          ).settings_accountMigration_step1_destination,
                        ),
                        subtitle: _destinationAccount == null
                            ? null
                            : Text(_destinationAccount!),
                        onTap: () async {
                          final newDestinationAccount =
                              await showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return AccountSelectWidget(
                                    oldAccount: _destinationAccount ?? '',
                                    onlyNonGuestAccounts: true,
                                  );
                                },
                              );

                          if (newDestinationAccount == null) return;

                          setState(() {
                            _destinationAccount = newDestinationAccount;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Step(
                  state: step1Complete ? StepState.indexed : StepState.disabled,
                  title: Text(l(context).settings_accountMigration_step2),
                  content: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          l(
                            context,
                          ).settings_accountMigration_step2_migrateMagazineSubscriptions,
                        ),
                        value: _migrateMagazineSubscriptions.enabled,
                        onChanged: (value) => {
                          if (value != null)
                            setState(() {
                              _migrateMagazineSubscriptions.enabled = value;
                            }),
                        },
                      ),
                      if (sourceIsMbin)
                        CheckboxListTile(
                          title: Text(
                            l(
                              context,
                            ).settings_accountMigration_step2_migrateMagazineBlocks,
                          ),
                          value: _migrateMagazineBlocks.enabled,
                          onChanged: (value) => {
                            if (value != null)
                              setState(() {
                                _migrateMagazineBlocks.enabled = value;
                              }),
                          },
                        ),
                      if (bothAccountsMbin)
                        CheckboxListTile(
                          title: Text(
                            l(
                              context,
                            ).settings_accountMigration_step2_migrateUserFollows,
                          ),
                          value: _migrateUserFollows.enabled,
                          onChanged: (value) => {
                            if (value != null)
                              setState(() {
                                _migrateUserFollows.enabled = value;
                              }),
                          },
                        ),
                      if (sourceIsMbin)
                        CheckboxListTile(
                          title: Text(
                            l(
                              context,
                            ).settings_accountMigration_step2_migrateUserBlocks,
                          ),
                          value: _migrateUserBlocks.enabled,
                          onChanged: (value) => {
                            if (value != null)
                              setState(() {
                                _migrateUserBlocks.enabled = value;
                              }),
                          },
                        ),
                    ],
                  ),
                ),
                Step(
                  state: step1Complete ? StepState.indexed : StepState.disabled,
                  title: Text(l(context).settings_accountMigration_step3),
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
                  Text(l(context).settings_accountMigration_readingFromSource),
                  Text(
                    l(context).settings_accountMigration_foundXItems(
                      _migrateMagazineSubscriptions.found.length +
                          _migrateMagazineBlocks.found.length +
                          _migrateUserFollows.found.length +
                          _migrateUserBlocks.found.length,
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
                  Text(l(context).settings_accountMigration_readingFromSource),
                  Text(
                    l(context).settings_accountMigration_completeXItems(
                      _migrateMagazineSubscriptions.complete.length +
                          _migrateMagazineBlocks.complete.length +
                          _migrateUserFollows.complete.length +
                          _migrateUserBlocks.complete.length,
                      _migrateMagazineSubscriptions.found.length +
                          _migrateMagazineBlocks.found.length +
                          _migrateUserFollows.found.length +
                          _migrateUserBlocks.found.length,
                    ),
                  ),
                  Text(
                    l(context).settings_accountMigration_failedXItems(
                      _migrateMagazineSubscriptions.failed.length +
                          _migrateMagazineBlocks.failed.length +
                          _migrateUserFollows.failed.length +
                          _migrateUserBlocks.failed.length,
                      _migrateMagazineSubscriptions.found.length +
                          _migrateMagazineBlocks.found.length +
                          _migrateUserFollows.found.length +
                          _migrateUserBlocks.found.length,
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
                  Text(l(context).settings_accountMigration_complete),
                  Text(
                    l(context).settings_accountMigration_completeXItems(
                      _migrateMagazineSubscriptions.complete.length +
                          _migrateMagazineBlocks.complete.length +
                          _migrateUserFollows.complete.length +
                          _migrateUserBlocks.complete.length,
                      _migrateMagazineSubscriptions.found.length +
                          _migrateMagazineBlocks.found.length +
                          _migrateUserFollows.found.length +
                          _migrateUserBlocks.found.length,
                    ),
                  ),
                  Text(
                    l(context).settings_accountMigration_failedXItems(
                      _migrateMagazineSubscriptions.failed.length +
                          _migrateMagazineBlocks.failed.length +
                          _migrateUserFollows.failed.length +
                          _migrateUserBlocks.failed.length,
                      _migrateMagazineSubscriptions.found.length +
                          _migrateMagazineBlocks.found.length +
                          _migrateUserFollows.found.length +
                          _migrateUserBlocks.found.length,
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
                children: [Text(l(context).settings_accountMigration_failed)],
              ),
            ),
          ],
        },
      ),
    );
  }
}

enum MigrationOrResetProgress {
  pending,
  readingSource,
  writingDestination,
  complete,
  failed,
}

class MigrationOrResetType<T> {
  bool enabled = true;
  Set<T> found = {};
  Set<T> complete = {};
  Set<T> failed = {};
}
