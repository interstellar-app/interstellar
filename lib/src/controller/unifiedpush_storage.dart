import 'dart:async';

import 'package:drift/drift.dart';
import 'package:interstellar/src/controller/database/database.dart';
import 'package:unifiedpush_storage_interface/distributor_storage.dart';
import 'package:unifiedpush_storage_interface/keys_storage.dart';
import 'package:unifiedpush_storage_interface/registrations_storage.dart';
import 'package:unifiedpush_storage_interface/storage.dart';

class UnifiedPushStorageInterstellar extends UnifiedPushStorage {
  @override
  FutureOr<void> init() {}

  @override
  DistributorStorage get distrib => DistributorStorageInterstellar();

  @override
  KeysStorage get keys => KeysStorageInterstellar();

  @override
  RegistrationsStorage get registrations => RegistrationsStorageInterstellar();
}

class DistributorStorageInterstellar extends DistributorStorage {
  @override
  FutureOr<void> ack() async {
    await database
        .update(database.miscCache)
        .write(
          const MiscCacheCompanion(unifiedpushDistributorAck: Value(true)),
        );
  }

  @override
  FutureOr<String?> get() async {
    final miscCache = await database.select(database.miscCache).getSingle();

    return miscCache.unifiedpushDistributorName;
  }

  @override
  FutureOr<void> remove() async {
    await database
        .update(database.miscCache)
        .write(
          const MiscCacheCompanion(
            unifiedpushDistributorName: Value(null),
            unifiedpushDistributorAck: Value(false),
          ),
        );
  }

  @override
  FutureOr<void> set(String distributor) async {
    final current = get();

    if (current != distributor) {
      await database
          .update(database.miscCache)
          .write(
            MiscCacheCompanion(
              unifiedpushDistributorName: Value(distributor),
              unifiedpushDistributorAck: const Value(false),
            ),
          );
    }
  }
}

class KeysStorageInterstellar extends KeysStorage {
  @override
  FutureOr<String?> get(String instance) async {
    final account = await (database.select(
      database.accounts,
    )..where((account) => account.handle.equals(instance))).getSingleOrNull();

    return account?.unifiedpushKey;
  }

  @override
  FutureOr<void> remove(String instance) async {
    await (database.update(database.accounts)
          ..where((account) => account.handle.equals(instance)))
        .write(const AccountsCompanion(unifiedpushKey: Value(null)));
  }

  @override
  FutureOr<void> set(String instance, String serializedKey) async {
    await (database.update(database.accounts)
          ..where((account) => account.handle.equals(instance)))
        .write(AccountsCompanion(unifiedpushKey: Value(serializedKey)));
  }
}

class RegistrationsStorageInterstellar extends RegistrationsStorage {
  TokenInstance? _accountToTokenInstance(Account? account) {
    if (account?.unifiedpushToken == null) return null;

    return TokenInstance(account!.unifiedpushToken!, account.handle);
  }

  @override
  FutureOr<TokenInstance?> getFromInstance(String instance) async {
    final account = await (database.select(
      database.accounts,
    )..where((account) => account.handle.equals(instance))).getSingleOrNull();

    return _accountToTokenInstance(account);
  }

  @override
  FutureOr<TokenInstance?> getFromToken(String token) async {
    final account =
        await (database.select(database.accounts)
              ..where((account) => account.unifiedpushToken.equals(token)))
            .getSingleOrNull();

    return _accountToTokenInstance(account);
  }

  @override
  FutureOr<bool> remove(String instance) async {
    final result =
        await (database.update(database.accounts)
              ..where((account) => account.handle.equals(instance)))
            .write(const AccountsCompanion(unifiedpushToken: Value(null)));

    return result > 0;
  }

  @override
  FutureOr<void> removeAll() async {
    await database
        .update(database.accounts)
        .write(const AccountsCompanion(unifiedpushToken: Value(null)));
  }

  @override
  FutureOr<void> save(TokenInstance token) async {
    await (database.update(database.accounts)
          ..where((account) => account.handle.equals(token.instance)))
        .write(AccountsCompanion(unifiedpushToken: Value(token.token)));
  }
}
