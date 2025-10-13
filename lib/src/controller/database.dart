import 'dart:convert';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/feed.dart';
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
    return (jsonDecode(fromDb) as List<dynamic>).map((json) => FeedInput.fromJson(json)).toSet();
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

@DriftDatabase(tables: [Accounts, FeedItems, FeedCache])
class InterstellarDatabase extends _$InterstellarDatabase {

  InterstellarDatabase([QueryExecutor? executor]) : super(executor?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'interstellar.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      )
    );
  }
}

late final Database db;

Future<void> initDatabase() async {
  final dir = await getApplicationSupportDirectory();

  final dbPath = join(dir.path, 'database');

  db = await databaseFactoryIo.openDatabase(dbPath);
}
