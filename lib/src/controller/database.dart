import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/controller/filter_list.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:oauth2/oauth2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';

part 'database.g.dart';

class CredentialsConverter extends TypeConverter<Credentials, String>
    with JsonTypeConverter2<Credentials, String, String> {
  const CredentialsConverter();

  @override
  Credentials fromSql(String fromDb) {
    return Credentials.fromJson(jsonDecode(fromDb));
  }

  @override
  String toSql(Credentials credentials) {
    return jsonEncode(credentials);
  }

  @override
  Credentials fromJson(String json) {
    return Credentials.fromJson(json);
  }

  @override
  String toJson(Credentials value) {
    return jsonEncode(value);
  }
}

class Accounts extends Table {
  TextColumn get handle => text().clientDefault(() => '@kbin.earth')();
  TextColumn get oauth => text().map(const CredentialsConverter()).nullable()();
  TextColumn get jwt => text().nullable()();
  BoolColumn get isPushRegistered => boolean().withDefault(Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {handle};
}

class FeedInputConverter extends TypeConverter<Set<FeedInput>, String> {
  const FeedInputConverter();

  @override
  Set<FeedInput> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>)
        .map((json) => FeedInput.fromJson(json))
        .toSet();
  }

  @override
  String toSql(Set<FeedInput> inputs) {
    return jsonEncode(inputs.toList());
  }
}

@DataClassName('RawFeed')
class Feeds extends Table {
  TextColumn get name => text()();
  TextColumn get items => text().map(const FeedInputConverter())();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class FeedInputCache extends Table {
  TextColumn get name => text()();
  TextColumn get server => text()();
  IntColumn get serverId => integer()();
  TextColumn get source => textEnum<FeedSource>()();

  @override
  Set<Column<Object>> get primaryKey => {name, server};
}

class Servers extends Table {
  TextColumn get name => text()();
  TextColumn get software => textEnum<ServerSoftware>()();
  TextColumn get oauthIdentifier => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class ReadPostCache extends Table {
  TextColumn get account =>
      text().references(Accounts, #handle, onDelete: KeyAction.cascade)();
  TextColumn get postType => textEnum<PostType>()();
  IntColumn get postId => integer()();

  @override
  Set<Column<Object>> get primaryKey => {account, postType, postId};
}

class FilterListConverter extends TypeConverter<Set<String>, String> {
  const FilterListConverter();

  @override
  Set<String> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>)
        .map((item) => item as String)
        .toSet();
  }

  @override
  String toSql(Set<String> inputs) {
    return jsonEncode(inputs.toList());
  }
}

@UseRowClass(FilterList)
class FilterLists extends Table {
  TextColumn get name => text()();
  TextColumn get phrases => text().map(const FilterListConverter())();
  TextColumn get matchMode => textEnum<FilterListMatchMode>()();
  BoolColumn get caseSensitive => boolean()();
  BoolColumn get showWithWarning => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> strings) {
    return strings.join(',');
  }
}

class FilterListActivationConverter
    extends TypeConverter<Map<String, bool>, String> {
  const FilterListActivationConverter();

  @override
  Map<String, bool> fromSql(String fromDb) {
    return Map.fromEntries(
      (jsonDecode(fromDb) as Map<String, dynamic>).entries.map(
        (a) => MapEntry(a.key, a.value as bool),
      ),
    );
  }

  @override
  String toSql(Map<String, bool> activations) {
    return jsonEncode(activations);
  }
}

@UseRowClass(ProfileOptional)
class Profiles extends Table {
  TextColumn get name => text().clientDefault(() => 'Default')();

  TextColumn get autoSwitchAccount => text().nullable().references(
    Accounts,
    #handle,
    onDelete: KeyAction.setNull,
  )();
  // Behaviour
  TextColumn get defaultCreateLanguage => text().nullable()();
  BoolColumn get useAccountLanguageFilter => boolean().nullable()();
  TextColumn get customLanguageFilter =>
      text().map(const StringListConverter()).nullable()();
  BoolColumn get disableTabSwiping => boolean().nullable()();
  BoolColumn get askBeforeUnsubscribing => boolean().nullable()();
  BoolColumn get askBeforeDeleting => boolean().nullable()();
  BoolColumn get autoPlayVideos => boolean().nullable()();
  BoolColumn get hapticFeedback => boolean().nullable()();
  BoolColumn get autoTranslate => boolean().nullable()();
  BoolColumn get markThreadsReadOnScroll => boolean().nullable()();
  BoolColumn get markMicroblogsReadOnScroll => boolean().nullable()();
  RealColumn get animationSpeed => real().nullable()();
  BoolColumn get inlineReplies => boolean().nullable()();
  BoolColumn get showCrosspostComments => boolean().nullable()();
  BoolColumn get markCrosspostsAsRead => boolean().nullable()();
  // Display
  TextColumn get appLanguage => text().nullable()();
  TextColumn get themeMode => textEnum<ThemeMode>().nullable()();
  TextColumn get colorScheme => textEnum<FlexScheme>().nullable()();
  BoolColumn get enableTrueBlack => boolean().nullable()();
  BoolColumn get compactMode => boolean().nullable()();
  BoolColumn get hideActionButtons => boolean().nullable()();
  BoolColumn get hideFeedUIOnScroll => boolean().nullable()();
  RealColumn get globalTextScale => real().nullable()();
  BoolColumn get alwaysShowInstance => boolean().nullable()();
  BoolColumn get coverMediaMarkedSensitive => boolean().nullable()();
  BoolColumn get fullImageSizeThreads => boolean().nullable()();
  BoolColumn get fullImageSizeMicroblogs => boolean().nullable()();
  // Feed defaults
  TextColumn get feedDefaultView => textEnum<FeedView>().nullable()();
  TextColumn get feedDefaultFilter => textEnum<FeedSource>().nullable()();
  TextColumn get feedDefaultThreadsSort => textEnum<FeedSort>().nullable()();
  TextColumn get feedDefaultMicroblogSort => textEnum<FeedSort>().nullable()();
  TextColumn get feedDefaultCombinedSort => textEnum<FeedSort>().nullable()();
  TextColumn get feedDefaultExploreSort => textEnum<FeedSort>().nullable()();
  TextColumn get feedDefaultCommentSort => textEnum<CommentSort>().nullable()();
  BoolColumn get feedDefaultHideReadPosts => boolean().nullable()();
  // Feed actions
  TextColumn get feedActionBackToTop => textEnum<ActionLocation>().nullable()();
  TextColumn get feedActionCreateNew => textEnum<ActionLocation>().nullable()();
  TextColumn get feedActionExpandFab => textEnum<ActionLocation>().nullable()();
  TextColumn get feedActionRefresh => textEnum<ActionLocation>().nullable()();
  TextColumn get feedActionSetFilter =>
      textEnum<ActionLocationWithTabs>().nullable()();
  TextColumn get feedActionSetSort => textEnum<ActionLocation>().nullable()();
  TextColumn get feedActionSetView =>
      textEnum<ActionLocationWithTabs>().nullable()();
  TextColumn get feedActionHideReadPosts =>
      textEnum<ActionLocation>().nullable()();
  // Swipe actions
  BoolColumn get enableSwipeActions => boolean().nullable()();
  TextColumn get swipeActionLeftShort => textEnum<SwipeAction>().nullable()();
  TextColumn get swipeActionLeftLong => textEnum<SwipeAction>().nullable()();
  TextColumn get swipeActionRightShort => textEnum<SwipeAction>().nullable()();
  TextColumn get swipeActionRightLong => textEnum<SwipeAction>().nullable()();
  RealColumn get swipeActionThreshold => real().nullable()();
  // Filter list activations
  TextColumn get filterLists =>
      text().nullable().map(const FilterListActivationConverter())();
  BoolColumn get showErrors => boolean().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class Stars extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// Table to store misc data that is either one off or doesn't fit into other tables
class MiscCache extends Table {
  IntColumn get id => integer()();
  IntColumn get lock =>
      integer().unique().withDefault(Constant(0)).check(lock.equals(0))();
  TextColumn get mainProfile =>
      text().references(Profiles, #name).clientDefault(() => 'Default')();
  TextColumn get selectedProfile =>
      text().references(Profiles, #name).clientDefault(() => 'Default')();
  TextColumn get autoSelectProfile =>
      text().nullable().references(Profiles, #name)();
  TextColumn get selectedAccount =>
      text().references(Accounts, #handle).clientDefault(() => '@kbin.earth')();
  TextColumn get webPushKeys => text().nullable()();
  TextColumn get downloadsDir => text().nullable()();
  BoolColumn get expandNavDrawer => boolean().withDefault(Constant(true))();
  BoolColumn get expandNavStars => boolean().withDefault(Constant(true))();
  BoolColumn get expandNavFeeds => boolean().withDefault(Constant(true))();
  BoolColumn get expandNavSubscriptions =>
      boolean().withDefault(Constant(true))();
  BoolColumn get expandNavFollows => boolean().withDefault(Constant(true))();
  BoolColumn get expandNavDomains => boolean().withDefault(Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Drafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get body => text()();
  TextColumn get resourceId => text().nullable()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Accounts,
    Feeds,
    FeedInputCache,
    Servers,
    ReadPostCache,
    FilterLists,
    Profiles,
    Stars,
    MiscCache,
    Drafts,
  ],
)
class InterstellarDatabase extends _$InterstellarDatabase {
  InterstellarDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static const databaseFilename = 'interstellar.db';

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: databaseFilename,
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

late InterstellarDatabase database;

Future<void> initDatabase() async {
  if (await migrateDatabase()) return;
  database = InterstellarDatabase();
}

Future<void> deleteTables() async {
  for (var table in database.allTables) {
    await database.delete(table).go();
  }
}

Future<bool> migrateDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final dbPath = join(dir.path, 'database');
  if (!await File(dbPath).exists()) {
    return false;
  }
  final Database db = await databaseFactoryIo.openDatabase(dbPath);
  database = InterstellarDatabase();

  final mainStore = StoreRef.main();
  final accountStore = StoreRef<String, JsonMap>('account');
  final feedStore = StoreRef<String, JsonMap>('feeds');
  final filterListStore = StoreRef<String, JsonMap>('filterList');
  final profileStore = StoreRef<String, JsonMap>('profile');
  final serverStore = StoreRef<String, JsonMap>('server');
  final readStore = StoreRef<String, JsonMap>('read');
  final miscStore = StoreRef<String, dynamic>('misc');
  final draftsStore = StoreRef<int, JsonMap>('draft');

  late final mainProfileRecord = mainStore.record('mainProfile');
  late final selectedProfileRecord = mainStore.record('selectedProfile');
  late final autoSelectProfileRecord = mainStore.record('autoSelectProfile');

  late final selectedAccountRecord = mainStore.record('selectedAccount');
  late final starsRecord = mainStore.record('stars');
  late final webPushKeysRecord = mainStore.record('webPushKeys');

  final stars = (await starsRecord.get(db) as List<Object?>? ?? [])
      .map((v) => v as String)
      .toList();

  await database.transaction(() async {
    for (final star in stars) {
      await database
          .into(database.stars)
          .insertOnConflictUpdate(StarsCompanion.insert(name: star));
    }
  });

  final accounts = Map.fromEntries(
    (await accountStore.find(db)).map(
      (record) => MapEntry(
        record.key,
        Account.fromJson({
          ...record.value,
          'handle': record.key,
          'isPushRegistered': record.value['isPushRegistered'] ?? false,
        }),
      ),
    ),
  );
  for (var entry in accounts.entries) {
    await database.into(database.accounts).insertOnConflictUpdate(entry.value);
  }

  final servers = Map.fromEntries(
    (await serverStore.find(db)).map(
      (record) => MapEntry(
        record.key,
        Server.fromJson({...record.value, 'name': record.key}),
      ),
    ),
  );
  for (var entry in servers.entries) {
    await database.into(database.servers).insertOnConflictUpdate(entry.value);
  }

  final feeds = Map.fromEntries(
    (await feedStore.find(
      db,
    )).map((record) => MapEntry(record.key, Feed.fromJson(record.value))),
  );
  for (var entry in feeds.entries) {
    await database
        .into(database.feeds)
        .insertOnConflictUpdate(
          FeedsCompanion.insert(name: entry.key, items: entry.value.inputs),
        );
  }

  final filterLists = Map.fromEntries(
    (await filterListStore.find(db)).map(
      (record) => MapEntry(
        record.key,
        FilterList.fromJson({...record.value, 'name': record.key}),
      ),
    ),
  );
  for (var entry in filterLists.entries) {
    await database
        .into(database.filterLists)
        .insertOnConflictUpdate(
          FilterListsCompanion.insert(
            name: entry.key,
            phrases: entry.value.phrases,
            matchMode: entry.value.matchMode,
            caseSensitive: entry.value.caseSensitive,
            showWithWarning: entry.value.showWithWarning,
          ),
        );
  }

  final profiles = await profileStore.find(db);
  for (var entry in profiles) {
    await database
        .into(database.profiles)
        .insertOnConflictUpdate(
          ProfileOptional.fromJson({...entry.value, 'name': entry.key}),
        );
  }

  final readPosts = await readStore.find(db);
  await database.transaction(() async {
    for (var entry in readPosts) {
      await database
          .into(database.readPostCache)
          .insertOnConflictUpdate(
            ReadPostCacheCompanion.insert(
              account: entry.value['account'] as String,
              postType: PostType.values.byName(
                entry.value['postType'] as String? ?? 'thread',
              ),
              postId: entry.value['postId'] as int,
            ),
          );
    }
  });

  final drafts = (await draftsStore.find(
    db,
  )).map((d) => Draft.fromJson({...d.value, 'id': d.key}));
  for (var entry in drafts) {
    await database.into(database.drafts).insertOnConflictUpdate(entry);
  }

  final mainProfileTmp =
      await mainProfileRecord.get(db) as String? ?? 'Default';
  final autoSelectProfile =
      await autoSelectProfileRecord.get(db) as String? ?? mainProfileTmp;
  final selectedProfile =
      await selectedProfileRecord.get(db) as String? ?? mainProfileTmp;
  final selectedAccount = await selectedAccountRecord.get(db) as String? ?? '';
  final webPushKeys = await webPushKeysRecord.get(db) as String?;

  final expandedNavDrawer =
      await miscStore.record('nav-widescreen').get(db) as bool?;
  final expandedNavStars = await miscStore.record('nav-stars').get(db) as bool?;
  final expandedNavFeeds = await miscStore.record('nav-feeds').get(db) as bool?;
  final expandedNavSubscriptions =
      await miscStore.record('nav-subscriptions').get(db) as bool?;
  final expandedNavFollows =
      await miscStore.record('nav-follows').get(db) as bool?;
  final expandedNavDomains =
      await miscStore.record('nav-domains').get(db) as bool?;

  await database
      .into(database.miscCache)
      .insertOnConflictUpdate(
        MiscCacheCompanion(
          mainProfile: Value(mainProfileTmp),
          autoSelectProfile: Value(autoSelectProfile),
          selectedProfile: Value(selectedProfile),
          selectedAccount: Value(selectedAccount),
          webPushKeys: Value(webPushKeys),
          expandNavDrawer: Value(expandedNavDrawer ?? true),
          expandNavStars: Value(expandedNavStars ?? true),
          expandNavFeeds: Value(expandedNavFeeds ?? true),
          expandNavSubscriptions: Value(expandedNavSubscriptions ?? true),
          expandNavFollows: Value(expandedNavFollows ?? true),
          expandNavDomains: Value(expandedNavDomains ?? true),
        ),
      );

  await db.close();
  await File(dbPath).delete();

  return true;
}
