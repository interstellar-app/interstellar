import 'dart:convert';
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
import 'package:oauth2/oauth2.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:drift/drift.dart';
part 'database.g.dart';

class CredentialsConverter extends TypeConverter<Credentials, String> {
  const CredentialsConverter();

  @override
  Credentials fromSql(String fromDb) {
    return Credentials.fromJson(jsonDecode(fromDb));
  }

  @override
  String toSql(Credentials credentials) {
    return jsonEncode(credentials);
  }
}

class Accounts extends Table {
  TextColumn get handle => text()();
  TextColumn get oauth => text().map(const CredentialsConverter()).nullable()();
  TextColumn get jwt => text().nullable()();
  BoolColumn get isPushRegistered => boolean().nullable()();

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

class FeedItems extends Table {
  TextColumn get name => text()();
  TextColumn get items => text().map(const FeedInputConverter())();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class FeedCache extends Table {
  TextColumn get name => text()();
  TextColumn get server => text()();
  IntColumn get id => integer()();
  IntColumn get source => intEnum<FeedSource>()();

  @override
  Set<Column<Object>> get primaryKey => {name, server};
}

class Servers extends Table {
  TextColumn get name => text()();
  IntColumn get software => intEnum<ServerSoftware>()();
  TextColumn get oauthIdentifier => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class ReadPostCache extends Table {
  TextColumn get account => text()();
  IntColumn get postType => intEnum<PostType>()();
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
class FilterListCache extends Table {
  TextColumn get name => text()();
  TextColumn get phrases => text().map(const FilterListConverter())();
  IntColumn get matchMode => intEnum<FilterListMatchMode>()();
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
    return jsonDecode(fromDb) as Map<String, bool>;
  }

  @override
  String toSql(Map<String, bool> activations) {
    return jsonEncode(activations);
  }
}

@UseRowClass(ProfileOptional)
class Profiles extends Table {
  TextColumn get name => text()();

  TextColumn get autoSwitchAccount => text().nullable()();
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
  IntColumn get themeMode => intEnum<ThemeMode>().nullable()();
  IntColumn get colorScheme => intEnum<FlexScheme>().nullable()();
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
  IntColumn get feedDefaultView => intEnum<FeedView>().nullable()();
  IntColumn get feedDefaultFilter => intEnum<FeedSource>().nullable()();
  IntColumn get feedDefaultThreadsSort => intEnum<FeedSort>().nullable()();
  IntColumn get feedDefaultMicroblogSort => intEnum<FeedSort>().nullable()();
  IntColumn get feedDefaultCombinedSort => intEnum<FeedSort>().nullable()();
  IntColumn get feedDefaultExploreSort => intEnum<FeedSort>().nullable()();
  IntColumn get feedDefaultCommentSort => intEnum<CommentSort>().nullable()();
  BoolColumn get feedDefaultHideReadPosts => boolean().nullable()();
  // Feed actions
  IntColumn get feedActionBackToTop => intEnum<ActionLocation>().nullable()();
  IntColumn get feedActionCreateNew => intEnum<ActionLocation>().nullable()();
  IntColumn get feedActionExpandFab => intEnum<ActionLocation>().nullable()();
  IntColumn get feedActionRefresh => intEnum<ActionLocation>().nullable()();
  IntColumn get feedActionSetFilter =>
      intEnum<ActionLocationWithTabs>().nullable()();
  IntColumn get feedActionSetSort => intEnum<ActionLocation>().nullable()();
  IntColumn get feedActionSetView =>
      intEnum<ActionLocationWithTabs>().nullable()();
  IntColumn get feedActionHideReadPosts =>
      intEnum<ActionLocation>().nullable()();
  // Swipe actions
  BoolColumn get enableSwipeActions => boolean().nullable()();
  IntColumn get swipeActionLeftShort => intEnum<SwipeAction>().nullable()();
  IntColumn get swipeActionLeftLong => intEnum<SwipeAction>().nullable()();
  IntColumn get swipeActionRightShort => intEnum<SwipeAction>().nullable()();
  IntColumn get swipeActionRightLong => intEnum<SwipeAction>().nullable()();
  RealColumn get swipeActionThreshold => real().nullable()();
  // Filter list activations
  TextColumn get filterLists =>
      text().nullable().map(const FilterListActivationConverter())();
  BoolColumn get showErrors => boolean().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

// Table to store misc data that is either one off or doesn't fit into other tables
class MiscCache extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
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
    FeedItems,
    FeedCache,
    Servers,
    ReadPostCache,
    FilterListCache,
    Profiles,
    MiscCache,
    Drafts,
  ],
)
class InterstellarDatabase extends _$InterstellarDatabase {
  InterstellarDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'interstellar.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

late final Database db;
InterstellarDatabase database = InterstellarDatabase();

Future<void> initDatabase() async {
  final dir = await getApplicationSupportDirectory();

  final dbPath = join(dir.path, 'database');

  db = await databaseFactoryIo.openDatabase(dbPath);
}
