import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/api/api.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/oauth.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/controller/filter_list.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/init_push_notifications.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/jwt_http_client.dart';
import 'package:interstellar/src/widgets/markdown/markdown_mention.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simplytranslate/simplytranslate.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:webpush_encryption/webpush_encryption.dart';
import 'package:drift/drift.dart';

enum HapticsType { light, medium, heavy, selection, vibrate }

class AppController with ChangeNotifier {
  static const _mainProfileKey = 'main-profile';
  static const _selectedProfileKey = 'selected-profile';
  static const _autoSelectProfileKey = 'auto-select-profile';

  static const _selectedAccountKey = 'selected-account';
  static const _starsKey = 'stars';
  static const _webPushKey = 'web-push-keys';

  static const _downloadsDirKey = 'downloads-directory';

  String? _defaultDownloadsDir;
  Directory? get defaultDownloadDir =>
      _defaultDownloadsDir == null ? null : Directory(_defaultDownloadsDir!);

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
      filter: ProductionFilter(),
    );
    logger.i('Initializing interstellar');

    final mainProfileTemp = await fetchCachedValue<String?>(_mainProfileKey);
    if (mainProfileTemp != null) {
      _mainProfile = mainProfileTemp;
    } else {
      _mainProfile = 'Default';
      _selectedProfile = _mainProfile;
      await updateProfile(ProfileOptional.nullProfile);
      await cacheValue(_selectedProfileKey, _selectedProfile);
      await cacheValue(_mainProfileKey, _mainProfile);
    }
    _autoSelectProfile = await fetchCachedValue<String?>(_autoSelectProfileKey);
    if (_autoSelectProfile != null) {
      _selectedProfile = _autoSelectProfile!;
    } else {
      _selectedProfile =
          await fetchCachedValue<String?>(_selectedProfileKey) ?? _mainProfile;
    }

    await _rebuildProfile();

    _stars = (await fetchCachedValue<List<dynamic>>(_starsKey) ?? [])
        .map((v) => v as String)
        .toList();

    final webPushKeysValue = await fetchCachedValue<String?>(_webPushKey);
    if (webPushKeysValue != null) {
      _webPushKeys = await WebPushKeySet.deserialize(webPushKeysValue);
    } else {
      _webPushKeys = await WebPushKeySet.newKeyPair();
      await cacheValue(_webPushKey, _webPushKeys.serialize);
    }

    _servers = Map.fromEntries(
      (await database.select(database.servers).get()).map(
        (server) => MapEntry(server.name, server),
      ),
    );

    if (_autoSelectProfile != null && _builtProfile.autoSwitchAccount != null) {
      _selectedAccount = _builtProfile.autoSwitchAccount!;
    } else {
      _selectedAccount =
          await fetchCachedValue<String?>(_selectedAccountKey) ?? '';
    }

    _accounts = Map.fromEntries(
      (await database.select(database.accounts).get()).map(
        (account) => MapEntry(account.handle, account),
      ),
    );

    if (_servers.isEmpty || _accounts.isEmpty || _selectedAccount.isEmpty) {
      await saveServer(ServerSoftware.mbin, 'kbin.earth');
      await setAccount(
        '@kbin.earth',
        const Account(handle: '@kbin.earth', isPushRegistered: false),
        switchNow: true,
      );
    }

    _feeds = Map.fromEntries(
      (await database.select(database.feeds).get()).map(
        (feed) => MapEntry(feed.name, Feed(inputs: feed.items)),
      ),
    );

    _filterLists = Map.fromEntries(
      (await database.select(database.filterLists).get()).map(
        (list) => MapEntry(list.name, list),
      ),
    );

    _translator = SimplyTranslator(EngineType.libre);

    _defaultDownloadsDir = await getDefaultDownloadDir();

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
    final profileValue = (await (database.select(
      database.profiles,
    )..where((f) => f.name.equals(profile))).get()).firstOrNull;
    return profileValue ?? ProfileOptional.nullProfile;
  }

  Future<void> setProfile(String profile, ProfileOptional value) async {
    await database
        .into(database.profiles)
        .insertOnConflictUpdate(value.copyWith(name: profile));

    await _rebuildProfile();

    notifyListeners();
  }

  Future<void> switchProfiles(String? newProfile) async {
    if (newProfile == null) return;
    if (newProfile == _selectedProfile) return;

    logger.i('Switch profiles $_selectedProfile -> $newProfile');

    _selectedProfile = newProfile;
    await cacheValue(_selectedProfileKey, _selectedProfile);

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
    await cacheValue(_mainProfileKey, _mainProfile);

    await _rebuildProfile();

    notifyListeners();
  }

  Future<void> setAutoSelectProfile(String? newProfile) async {
    if (newProfile == _autoSelectProfile) return;

    _autoSelectProfile = newProfile;
    await cacheValue(_autoSelectProfileKey, _autoSelectProfile);

    notifyListeners();
  }

  Future<List<String>> getProfileNames() async {
    final list = await database
        .select(database.profiles)
        .map((profile) => profile.name)
        .get();
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

    await (database.delete(
      database.profiles,
    )..where((f) => f.name.equals(profileName))).go();
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

    _servers[server] = Server(name: server, software: software);

    await database
        .into(database.servers)
        .insertOnConflictUpdate(_servers[server]!);
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
      name: server,
      software: software,
      oauthIdentifier: oauthIdentifier,
    );

    await database
        .into(database.servers)
        .insertOnConflictUpdate(_servers[server]!);

    return oauthIdentifier;
  }

  Future<void> setAccount(
    String key,
    Account value, {
    bool switchNow = false,
  }) async {
    _accounts[key] = value;

    await database.into(database.accounts).insertOnConflictUpdate(value);

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
      if (_accounts[key]!.isPushRegistered) await unregisterPush(key);
    } catch (e) {
      // Ignore error in case unregister fails so the account is still removed
    }

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
      await (database.delete(
        database.feedInputCache,
      )..where((f) => f.server.equals(keyAccountServer))).go();

      _servers.remove(keyAccountServer);

      await (database.delete(
        database.servers,
      )..where((f) => f.name.equals(keyAccountServer))).go();
    }

    _updateAPI();

    notifyListeners();

    await (database.delete(
      database.accounts,
    )..where((f) => f.handle.equals(key))).go();
    await cacheValue(_selectedAccountKey, _selectedAccount);
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

    await cacheValue(_selectedAccountKey, _selectedAccount);
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
              setAccount(
                account,
                _accounts[account]!.copyWith(oauth: Value(newCredentials)),
              );
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

    await cacheValue(_starsKey, _stars);
  }

  Future<void> removeStar(String oldStar) async {
    if (!_stars.contains(oldStar)) return;

    _stars.remove(oldStar);

    notifyListeners();

    cacheValue(_starsKey, _stars);
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

    final distributor = await getUnifiedPushDistributor(context);
    if (distributor == null) return;

    UnifiedPush.saveDistributor(distributor);
    UnifiedPush.register(instance: _selectedAccount);

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
    try {
      await (account == _selectedAccount
              ? api
              : await getApiForAccount(account))
          .notifications
          .pushDelete();
    } catch (e) {
      // Remove push registration status even if API request fails
    }

    removePushRegistrationStatus(account);
  }

  Future<void> addPushRegistrationStatus(String account) async {
    _accounts[account] = _accounts[account]!.copyWith(
      isPushRegistered: true,
    );

    notifyListeners();

    setAccount(account, _accounts[account]!);
  }

  Future<void> removePushRegistrationStatus(String account) async {
    _accounts[account] = _accounts[account]!.copyWith(
      isPushRegistered: false,
    );

    notifyListeners();

    setAccount(account, _accounts[account]!);
  }

  Future<void> setFeed(String name, Feed value) async {
    _feeds[name] = value;

    notifyListeners();

    await database
        .into(database.feeds)
        .insertOnConflictUpdate(
          FeedsCompanion.insert(name: name, items: value.inputs),
        );
  }

  Future<void> removeFeed(String name) async {
    _feeds.remove(name);

    notifyListeners();

    await (database.delete(
      database.feeds,
    )..where((f) => f.name.equals(name))).go();
  }

  Future<void> renameFeed(String oldName, String newName) async {
    _feeds[newName] = _feeds[oldName]!;
    _feeds.remove(oldName);

    notifyListeners();

    await (database.update(
      database.feeds,
    )..where((f) => f.name.equals(oldName))).write(
      FeedsCompanion.insert(name: newName, items: _feeds[newName]!.inputs),
    );
  }

  Future<void> setFilterList(String name, FilterList value) async {
    _filterLists[name] = value;

    notifyListeners();

    await database
        .into(database.filterLists)
        .insertOnConflictUpdate(value.copyWith(name: name));
  }

  Future<void> removeFilterList(String name) async {
    _filterLists.remove(name);

    // Remove a profile's activation value if it is for this filter list
    final profile = await (database.select(
      database.profiles,
    )..where((f) => f.filterLists.contains(name))).getSingle();
    final newFilterLists = {...?profile.filterLists};
    newFilterLists.remove(name);
    database
        .into(database.profiles)
        .insertOnConflictUpdate(profile.copyWith(filterLists: newFilterLists));

    _rebuildProfile();

    notifyListeners();

    await (database.delete(
      database.filterLists,
    )..where((f) => f.name.equals(name))).go();
  }

  Future<void> renameFilterList(String oldName, String newName) async {
    _filterLists[newName] = _filterLists[oldName]!;
    _filterLists.remove(oldName);

    // Update a profile's activation value if it is for this filter list
    final profile = await (database.select(
      database.profiles,
    )..where((f) => f.filterLists.contains(oldName))).getSingle();
    final newFilterLists = {
      ...?profile.filterLists,
      newName: profile.filterLists?[oldName] ?? false,
    };
    newFilterLists.remove(oldName);
    database
        .into(database.profiles)
        .insertOnConflictUpdate(profile.copyWith(filterLists: newFilterLists));

    _rebuildProfile();

    notifyListeners();

    await database
        .into(database.filterLists)
        .insertOnConflictUpdate(_filterLists[newName]!.copyWith(name: newName));
    await (database.delete(
      database.filterLists,
    )..where((f) => f.name.equals(oldName))).go();
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

  Future<List<PostModel>> markAsRead(List<PostModel> posts, bool read) async {
    // Use Lemmy's and PieFed's read API when available
    if (isLoggedIn && serverSoftware != ServerSoftware.mbin) {
      await api.threads.markAsRead(posts.map((post) => post.id).toList(), read);
    }
    // Use local database otherwise.
    // If marking as read, then check for a db row first, and add one if not present.
    else if (read) {
      await database.transaction(() async {
        for (var post in posts) {
          if (!await isRead(post)) {
            await database
                .into(database.readPostCache)
                .insertOnConflictUpdate(
                  ReadPostCacheCompanion.insert(
                    account: _selectedAccount,
                    postType: post.type,
                    postId: post.id,
                  ),
                );
          }
        }
      });
    }
    // If marking as unread, then delete any matching database rows.
    else {
      await database.transaction(() async {
        for (var post in posts) {
          await (database.delete(database.readPostCache)..where(
                (f) =>
                    f.account.equals(_selectedAccount) &
                    f.postType.equals(post.type.name) &
                    f.postId.equals(post.id),
              ))
              .go();
        }
      });
    }

    return posts.map((post) => post.copyWith(read: read)).toList();
  }

  Future<bool> isRead(PostModel post) async {
    return (await (database.select(database.readPostCache)..where(
                  (f) =>
                      f.account.equals(_selectedAccount) &
                      f.postType.equals(post.type.name) &
                      f.postId.equals(post.id),
                ))
                .get())
            .firstOrNull !=
        null;
  }

  Future<int?> fetchCachedFeedInput(String name, FeedSource source) async {
    final cachedValue =
        (await (database.select(database.feedInputCache)..where(
                  (t) =>
                      t.name.equals(name) &
                      t.server.equals(instanceHost) &
                      t.source.equals(source.name),
                ))
                .get())
            .firstOrNull;

    if (cachedValue != null) return cachedValue.serverId;

    try {
      final newValue = switch (source) {
        FeedSource.community => (await api.community.getByName(name)).id,
        FeedSource.user => (await api.users.getByName(name)).id,
        FeedSource.feed =>
          name.split(':').last !=
                  instanceHost // tmp until proper getByName method can be made
              ? throw Exception('Wrong instance')
              : int.parse(name.split(':').first),
        FeedSource.topic =>
          name.split(':').last !=
                  instanceHost // tmp until proper getByName method can be made
              ? throw Exception('Wrong instance')
              : int.parse(name.split(':').first),
        _ => null,
      };

      if (newValue != null) {
        await database
            .into(database.feedInputCache)
            .insertOnConflictUpdate(
              FeedInputCacheCompanion.insert(
                name: name,
                server: instanceHost,
                serverId: newValue,
                source: source,
              ),
            );
      }

      return newValue;
    } catch (error) {
      return null;
    }
  }

  Future<void> cacheValue<T>(String key, T? value) async {
    if (value == null) {
      await (database.delete(
        database.miscCache,
      )..where((f) => f.key.equals(key))).go();
    } else {
      await database
          .into(database.miscCache)
          .insertOnConflictUpdate(
            MiscCacheCompanion.insert(key: key, json: jsonEncode(value)),
          );
    }
  }

  Future<T?> fetchCachedValue<T>(String key) async {
    final value = (await (database.select(
      database.miscCache,
    )..where((f) => f.key.equals(key))).get()).firstOrNull?.json;
    if (value == null) return null;
    return jsonDecode(value) as T?;
  }

  Future<String?> getDefaultDownloadDir() async {
    return _defaultDownloadsDir ??
        await fetchCachedValue<String?>(_downloadsDirKey);
  }

  Future<void> setDefaultDownloadDir(String? path) async {
    await cacheValue(_downloadsDirKey, path);
    _defaultDownloadsDir = path;
  }
}
