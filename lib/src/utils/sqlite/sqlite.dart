import 'package:sqlite3/common.dart';

// Stub to handle sqlite on different platforms.
Future<CommonSqlite3> getSqlite() async {
  throw UnsupportedError('Unknown pipeline');
}