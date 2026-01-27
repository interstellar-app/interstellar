import 'package:sqlite3/sqlite3.dart';

// get sqlite on native platforms.
Future<CommonSqlite3> getSqlite() async {
  return sqlite3;
}