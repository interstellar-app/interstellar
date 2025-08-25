import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/api/api.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/oauth.dart';
import 'package:interstellar/src/controller/account.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/controller/filter_list.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/jwt_http_client.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/markdown/markdown_mention.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:simplytranslate/simplytranslate.dart';
import 'package:unifiedpush/constants.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:webpush_encryption/webpush_encryption.dart';

enum HapticsType { light, medium, heavy, selection, vibrate }

class AppController with ChangeNotifier {
  final _mainStore = StoreRef.main();
  final _accountStore = StoreRef<String, JsonMap>('account');
  final _feedStore = StoreRef<String, JsonMap>('feeds');
  final _feedCacheStore = StoreRef<String, JsonMap>('feedCache');
  final _filterListStore = StoreRef<String, JsonMap>('filterList');
  final _profileStore = StoreRef<String, JsonMap>('profile');
  final _serverStore = StoreRef<String, JsonMap>('server');
  final _readStore = StoreRef<String, JsonMap>('read');
  final _miscStore = StoreRef<String, dynamic>('misc');

  late final _mainProfileRecord = _mainStore.record('mainProfile');
  late final _selectedProfileRecord = _mainStore.record('selectedProfile');
  late final _autoSelectProfileRecord = _mainStore.record('autoSelectProfile');

  late final _selectedAccountRecord = _mainStore.record('selectedAccount');
  late final _starsRecord = _mainStore.record('stars');
  late final _webPushKeysRecord = _mainStore.record('webPushKeys');

  RecordRef<String, JsonMap> _profileRecord(String name) =>
      _profileStore.record(FieldKey.escape(name));

  late String _mainProfile;
  String get mainProfile => _mainProfile;
  late String _selectedProfile;
  String get selectedProfile => _selectedProfile;
  late String? _autoSelectProfile;
  String? get autoSelectProfile => _autoSelectProfile;

  late ProfileRequired _builtProfile;
  ProfileRequired get profile => _builtProfile;

  late ProfileOptional _selectedProfileValue;
  ProfileOptional get selectedProfileValue => _selectedProfileValue;

  late List<String> _stars;
  List<String> get stars => _stars;

  late WebPushKeySet _webPushKeys;
  WebPushKeySet get webPushKeys => _webPushKeys;

  bool get isPushRegistered =>
      _accounts[_selectedAccount]?.isPushRegistered ?? false;

  late Map<String, Server> _servers;
  late Map<String, Account> _accounts;
  late API _api;

  Map<String, Server> get servers => _servers;
  Map<String, Account> get accounts => _accounts;
  late String _selectedAccount;
  String get selectedAccount => _selectedAccount;
  String get localName => _selectedAccount.split('@').first;
  String get instanceHost => _selectedAccount.split('@').last;
  bool get isLoggedIn => localName.isNotEmpty;
  ServerSoftware get serverSoftware => _servers[instanceHost]!.software;
  API get api => _api;

  late Map<String, Feed> _feeds;
  Map<String, Feed> get feeds => _feeds;

  late Map<String, FilterList> _filterLists;
  Map<String, FilterList> get filterLists => _filterLists;

  late Function refreshState;

  late SimplyTranslator _translator;
  SimplyTranslator get translator => _translator;

  late Logger _logger;
  Logger get logger => _logger;

  Future<File> get logFile async {
    final logDir = await getApplicationSupportDirectory();
    final logFile = join(logDir.path, 'log.log');
    return File(logFile);
  }

  Future<void> init() async {
    refreshState = () {};
    _logger = Logger(
      printer: SimplePrinter(printTime: true, colors: false),
      output: FileOutput(file: await logFile),
      filter: ProductionFilter()
    );
    logger.i('Initializing interstellar');

    final mainProfileTemp = await _mainProfileRecord.get(db) as String?;
    if (mainProfileTemp != null) {
      _mainProfile = mainProfileTemp;
    } else {
      _mainProfile = 'Default';
      await _profileRecord(
        _mainProfile,
      ).put(db, ProfileOptional.nullProfile.toJson());
      await _mainProfileRecord.put(db, _mainProfile);
    }
    _autoSelectProfile = await _autoSelectProfileRecord.get(db) as String?;
    if (_autoSelectProfile != null) {
      _selectedProfile = _autoSelectProfile!;
    } else {
      _selectedProfile =
          await _selectedProfileRecord.get(db) as String? ?? _mainProfile;
    }

    await _rebuildProfile();

    _stars = (await _starsRecord.get(db) as List<Object?>? ?? [])
        .map((v) => v as String)
        .toList();

    final webPushKeysValue = await _webPushKeysRecord.get(db) as String?;
    if (webPushKeysValue != null) {
      _webPushKeys = await WebPushKeySet.deserialize(webPushKeysValue);
    } else {
      _webPushKeys = await WebPushKeySet.newKeyPair();
      await _webPushKeysRecord.put(db, _webPushKeys.serialize);
    }

    _servers = Map.fromEntries(
      (await _serverStore.find(
        db,
      )).map((record) => MapEntry(record.key, Server.fromJson(record.value))),
    );

    if (_autoSelectProfile != null && _builtProfile.autoSwitchAccount != null) {
      _selectedAccount = _builtProfile.autoSwitchAccount!;
    } else {
      _selectedAccount = await _selectedAccountRecord.get(db) as String? ?? '';
    }

    _accounts = Map.fromEntries(
      (await _accountStore.find(
        db,
      )).map((record) => MapEntry(record.key, Account.fromJson(record.value))),
    );

    if (_servers.isEmpty || _accounts.isEmpty || _selectedAccount.isEmpty) {
      await saveServer(ServerSoftware.mbin, 'kbin.earth');
      await setAccount('@kbin.earth', const Account(), switchNow: true);
    }

    _feeds = Map.fromEntries(
      (await _feedStore.find(
        db,
      )).map((record) => MapEntry(record.key, Feed.fromJson(record.value))),
    );

    _filterLists = Map.fromEntries(
      (await _filterListStore.find(db)).map(
        (record) => MapEntry(record.key, FilterList.fromJson(record.value)),
      ),
    );

    _translator = SimplyTranslator(EngineType.libre);

    await _updateAPI();
    logger.i('Finished init');
  }

  Future<void> _rebuildProfile() async {
    _selectedProfileValue = await getProfile(_selectedProfile);

    _builtProfile = ProfileRequired.fromOptional(
      (await getProfile(_mainProfile)).merge(_selectedProfileValue),
    );
    refreshState();
  }

  Future<void> updateProfile(ProfileOptional value) async {
    setProfile(_selectedProfile, value);
  }

  Future<ProfileOptional> getProfile(String profile) async {
    final record = _profileRecord(profile);

    final profileValue = await record.get(db);

    return profileValue == null
        ? ProfileOptional.nullProfile
        : ProfileOptional.fromJson(profileValue);
  }

  Future<void> setProfile(String profile, ProfileOptional value) async {
    final record = _profileRecord(profile);
    await record.put(db, value.toJson());

    await _rebuildProfile();

    notifyListeners();
  }

  Future<void> switchProfiles(String? newProfile) async {
    if (newProfile == null) return;
    if (newProfile == _selectedProfile) return;

    logger.i('Switch profiles $_selectedProfile -> $newProfile');

    _selectedProfile = newProfile;
    await _selectedProfileRecord.put(db, _selectedProfile);

    await _rebuildProfile();

    if (_builtProfile.autoSwitchAccount != null &&
        _builtProfile.autoSwitchAccount != _selectedAccount) {
      await switchAccounts(_builtProfile.autoSwitchAccount);
    } else {
      // switchAccounts() already calls notifyListeners(),
      // so it's only necessary to run if switchAccounts() is not run.
      notifyListeners();
    }
  }

  Future<void> setMainProfile(String? newProfile) async {
    if (newProfile == null) return;
    if (newProfile == _mainProfile) return;

    _mainProfile = newProfile;
    await _mainProfileRecord.put(db, _mainProfile);

    await _rebuildProfile();

    notifyListeners();
  }

  Future<void> setAutoSelectProfile(String? newProfile) async {
    if (newProfile == _autoSelectProfile) return;

    _autoSelectProfile = newProfile;
    if (_autoSelectProfile != null) {
      await _autoSelectProfileRecord.put(db, _autoSelectProfile);
    } else {
      await _autoSelectProfileRecord.delete(db);
    }

    notifyListeners();
  }

  Future<List<String>> getProfileNames() async {
    final list = await _profileStore.findKeys(db);
    list.sort((a, b) {
      // Main profile should be in the front
      if (a == _mainProfile) return -1;
      if (b == _mainProfile) return 1;

      return a.compareTo(b);
    });
    return list;
  }

  Future<void> deleteProfile(String profileName) async {
    if (profileName == _mainProfile) return;

    if (profileName == _autoSelectProfile) await setAutoSelectProfile(null);
    if (profileName == _selectedProfile) await switchProfiles(_mainProfile);

    final record = _profileRecord(profileName);
    await record.delete(db);
  }

  Future<void> renameProfile(
    String oldProfileName,
    String newProfileName,
  ) async {
    await setProfile(newProfileName, await getProfile(oldProfileName));

    if (_mainProfile == oldProfileName) await setMainProfile(newProfileName);
    if (_selectedProfile == oldProfileName) {
      await switchProfiles(newProfileName);
    }

    await deleteProfile(oldProfileName);
  }

  Future<void> saveServer(ServerSoftware software, String server) async {
    if (_servers.containsKey(server) &&
        _servers[server]!.software == software) {
      return;
    }

    _servers[server] = Server(software: software);

    await _serverStore.record(server).put(db, _servers[server]!.toJson());
  }

  Future<String> getMbinOAuthIdentifier(
    ServerSoftware software,
    String server,
  ) async {
    if (_servers.containsKey(server) &&
        _servers[server]!.oauthIdentifier != null) {
      return _servers[server]!.oauthIdentifier!;
    }

    if (software != ServerSoftware.mbin) {
      throw Exception('Register oauth only allowed on mbin');
    }

    String oauthIdentifier = await registerOauthApp(server);
    _servers[server] = Server(
      software: software,
      oauthIdentifier: oauthIdentifier,
    );

    await _serverStore.record(server).put(db, _servers[server]!.toJson());

    return oauthIdentifier;
  }

  Future<void> setAccount(
    String key,
    Account value, {
    bool switchNow = false,
  }) async {
    _accounts[key] = value;

    await _accountStore.record(key).put(db, _accounts[key]!.toJson());

    if (switchNow) {
      await switchAccounts(key);
    } else {
      // The following is already done when switchAccounts is run, so only needed without switchAccounts.
      _updateAPI();

      notifyListeners();
    }
  }

  Future<void> removeAccount(String key) async {
    if (!_accounts.containsKey(key)) return;

    try {
      if (_accounts[key]!.isPushRegistered ?? false) await unregisterPush(key);
    } catch (e) {
      // Ignore error in case unregister fails so the account is still removed
    }

    // Remove a profile's autoSwitchAccount value if it is for this account
    final autoSwitchAccountProfiles = await _profileStore.find(
      db,
      finder: Finder(filter: Filter.equals('autoSwitchAccount', key)),
    );
    for (var record in autoSwitchAccountProfiles) {
      await _profileRecord(record.key).put(
        db,
        ProfileOptional.fromJson(
          record.value,
        ).copyWith(autoSwitchAccount: null).toJson(),
      );
    }

    // Remove read posts associated with account
    _readStore.delete(
      db,
      finder: Finder(filter: Filter.equals('account', key)),
    );

    _rebuildProfile();

    _accounts.remove(key);
    _selectedAccount = _accounts.keys.firstOrNull ?? '@kbin.earth';

    // If there are no accounts left from a server, then remove the server's data
    final keyAccountServer = key.split('@').last;
    if (_accounts.keys
        .firstWhere(
          (account) => account.split('@').last == keyAccountServer,
          orElse: () => '',
        )
        .isEmpty) {
      _feedCacheStore.delete(
        db,
        finder: Finder(filter: Filter.equals('server', keyAccountServer)),
      );

      _servers.remove(keyAccountServer);

      await _serverStore.record(keyAccountServer).delete(db);
    }

    _updateAPI();

    notifyListeners();

    await _accountStore.record(key).delete(db);
    await _selectedAccountRecord.put(db, _selectedAccount);
  }

  Future<void> switchAccounts(String? newAccount) async {
    if (newAccount == null) return;
    if (newAccount == _selectedAccount) return;

    logger.i('Switch accounts $_selectedAccount -> $newAccount');

    _selectedAccount = newAccount;
    await _updateAPI();

    userMentionCache.clear();
    communityMentionCache.clear();

    notifyListeners();
    refreshState();

    await _selectedAccountRecord.put(db, _selectedAccount);
  }

  Future<void> _updateAPI() async {
    _api = await getApiForAccount(_selectedAccount);
  }

  Future<API> getApiForAccount(String account) async {
    final instance = account.split('@').last;
    final software = _servers[instance]!.software;

    http.Client httpClient = http.Client();

    switch (software) {
      case ServerSoftware.mbin:
        oauth2.Credentials? credentials = _accounts[account]?.oauth;
        if (credentials != null) {
          String identifier = _servers[instance]!.oauthIdentifier!;
          httpClient = oauth2.Client(
            credentials,
            identifier: identifier,
            onCredentialsRefreshed: (newCredentials) async {
              _accounts[account] = _accounts[account]!.copyWith(
                oauth: newCredentials,
              );

              await _accountStore
                  .record(account)
                  .put(db, _accounts[account]!.toJson());
            },
          );
        }
        break;
      case ServerSoftware.lemmy:
      case ServerSoftware.piefed:
        String? jwt = _accounts[account]!.jwt;
        if (jwt != null) {
          httpClient = JwtHttpClient(jwt);
        }
        break;
    }

    return API(
      ServerClient(
        httpClient: httpClient,
        software: software,
        domain: instance,
      ),
    );
  }

  Future<void> addStar(String newStar) async {
    if (_stars.contains(newStar)) return;

    _stars.add(newStar);

    notifyListeners();

    await _starsRecord.put(db, _stars);
  }

  Future<void> removeStar(String oldStar) async {
    if (!_stars.contains(oldStar)) return;

    _stars.remove(oldStar);

    notifyListeners();

    await _starsRecord.put(db, _stars);
  }

  Future<void> registerPush(BuildContext context) async {
    if (serverSoftware != ServerSoftware.mbin) {
      throw Exception('Push notifications only allowed on Mbin');
    }

    final permissionsResult = await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    if (permissionsResult == false) {
      throw Exception('Notification permissions denied');
    }

    if (!context.mounted) return;
    await UnifiedPush.registerAppWithDialog(context, _selectedAccount, [
      featureAndroidBytesMessage,
    ]);

    await addPushRegistrationStatus(_selectedAccount);
  }

  Future<void> unregisterPush([String? overrideAccount]) async {
    if (serverSoftware != ServerSoftware.mbin) {
      throw Exception('Push notifications only allowed on Mbin');
    }

    final account = overrideAccount ?? _selectedAccount;

    await UnifiedPush.unregister(account);

    // When unregistering a non selected account, make sure the api uses the correct
    // authentication for the target account, instead of the currently selected account.
    await (account == _selectedAccount ? api : await getApiForAccount(account))
        .notifications
        .pushDelete();

    removePushRegistrationStatus(account);
  }

  Future<void> addPushRegistrationStatus(String account) async {
    _accounts[account] = _accounts[account]!.copyWith(isPushRegistered: true);

    notifyListeners();

    await _accountStore.record(account).put(db, _accounts[account]!.toJson());
  }

  Future<void> removePushRegistrationStatus(String account) async {
    _accounts[account] = _accounts[account]!.copyWith(isPushRegistered: false);

    notifyListeners();

    await _accountStore.record(account).put(db, _accounts[account]!.toJson());
  }

  Future<void> setFeed(String name, Feed value) async {
    _feeds[name] = value;

    notifyListeners();

    await _feedStore.record(FieldKey.escape(name)).put(db, value.toJson());
  }

  Future<void> removeFeed(String name) async {
    _feeds.remove(name);

    notifyListeners();

    await _feedStore.record(FieldKey.escape(name)).delete(db);
  }

  Future<void> renameFeed(String oldName, String newName) async {
    _feeds[newName] = _feeds[oldName]!.copyWith(name: newName);
    _feeds.remove(oldName);

    notifyListeners();

    await _feedStore
        .record(FieldKey.escape(newName))
        .put(db, _feeds[newName]!.toJson());
    await _feedStore.record(FieldKey.escape(oldName)).delete(db);
  }

  Future<void> setFilterList(String name, FilterList value) async {
    _filterLists[name] = value;

    notifyListeners();

    await _filterListStore
        .record(FieldKey.escape(name))
        .put(db, value.toJson());
  }

  Future<void> removeFilterList(String name) async {
    _filterLists.remove(name);

    // Remove a profile's activation value if it is for this filter list
    for (var record in await _profileStore.find(db)) {
      final profile = ProfileOptional.fromJson(record.value);
      if (profile.filterLists?.containsKey(name) == true) {
        final newProfileFilterLists = {...profile.filterLists!};
        newProfileFilterLists.remove(name);
        await _profileRecord(record.key).put(
          db,
          profile.copyWith(filterLists: newProfileFilterLists).toJson(),
        );
      }
    }

    _rebuildProfile();

    notifyListeners();

    await _filterListStore.record(FieldKey.escape(name)).delete(db);
  }

  Future<void> renameFilterList(String oldName, String newName) async {
    _filterLists[newName] = _filterLists[oldName]!;
    _filterLists.remove(oldName);

    // Update a profile's activation value if it is for this filter list
    for (var record in await _profileStore.find(db)) {
      final profile = ProfileOptional.fromJson(record.value);
      if (profile.filterLists?.containsKey(oldName) == true) {
        final newProfileFilterLists = {
          ...profile.filterLists!,
          newName: profile.filterLists![oldName]!,
        };
        newProfileFilterLists.remove(oldName);
        await _profileRecord(record.key).put(
          db,
          profile.copyWith(filterLists: newProfileFilterLists).toJson(),
        );
      }
    }

    _rebuildProfile();

    notifyListeners();

    await _filterListStore
        .record(FieldKey.escape(newName))
        .put(db, _filterLists[newName]!.toJson());
    await _filterListStore.record(FieldKey.escape(oldName)).delete(db);
  }

  Future<void> vibrate(HapticsType type) async {
    if (!profile.hapticFeedback) return;

    switch (type) {
      case HapticsType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticsType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticsType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticsType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticsType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  Finder _readStoreFinder(PostModel post) => Finder(
    filter: Filter.and([
      Filter.equals('account', _selectedAccount),
      Filter.equals('postType', post.type.name),
      Filter.equals('postId', post.id),
    ]),
  );

  Future<List<PostModel>> markAsRead(List<PostModel> posts, bool read) async {
    // Use Lemmy's and PieFed's read API when available
    if (isLoggedIn && serverSoftware != ServerSoftware.mbin) {
      await api.threads.markAsRead(posts.map((post) => post.id).toList(), read);
    }
    // Use local database otherwise.
    // If marking as read, then check for a db row first, and add one if not present.
    else if (read) {
      await db.transaction((txn) async {
        for (var post in posts) {
          if (!await isRead(post)) {
            await _readStore.add(txn, {
              'account': _selectedAccount,
              'postType': post.type.name,
              'postId': post.id,
            });
          }
        }
      });
    }
    // If marking as unread, then delete any matching database rows.
    else {
      await db.transaction((txn) async {
        for (var post in posts) {
          await _readStore.delete(txn, finder: _readStoreFinder(post));
        }
      });
    }

    return posts.map((post) => post.copyWith(read: read)).toList();
  }

  Future<bool> isRead(PostModel post) async {
    return (await _readStore.find(
          db,
          finder: _readStoreFinder(post),
        )).firstOrNull !=
        null;
  }

  Finder _feedCacheStoreFinder(String name, FeedSource source) => Finder(
    filter: Filter.and([
      Filter.equals('server', instanceHost),
      Filter.equals('name', name),
      Filter.equals('source', source.index),
    ]),
  );

  Future<int?> fetchCachedFeedInput(String name, FeedSource source) async {
    final cachedValue = (await _feedCacheStore.find(
        db,
        finder: _feedCacheStoreFinder(name, source))
    ).firstOrNull;
    if (cachedValue != null) return cachedValue.value['id'] as int;

    try {
      final newValue = switch (source) {
        FeedSource.community => (await api.community.getByName(name)).id,
        FeedSource.user => (await api.users.getByName(name)).id,
        FeedSource.feed => name.split(':').last != instanceHost // tmp until proper getByName method can be made
            ? throw Exception('Wrong instance')
            : int.parse(name.split(':').first),
        FeedSource.topic => name.split(':').last != instanceHost // tmp until proper getByName method can be made
            ? throw Exception('Wrong instance')
            : int.parse(name.split(':').first),
        _ => null,
      };

      if (newValue != null) {
        await _feedCacheStore.add(db, {
          'server': instanceHost,
          'name': name,
          'id': newValue,
          'source': source.index
        });
      }

      return newValue;
    } catch (error) {
      return null;
    }
  }

  Future<void> cacheValue(String key, dynamic value) async {
    await _miscStore.record(key).put(db, value);
  }

  Future<dynamic> fetchCachedValue(String key) async {
    return await _miscStore.record(key).get(db);
  }
}
