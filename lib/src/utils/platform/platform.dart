import 'dart:io';

import 'package:sqlite3/common.dart';

// Stub to handle sqlite on different platforms.
Future<CommonSqlite3> getSqlite() async {
  throw UnsupportedError('Unknown pipeline');
}

Future<void> downloadFromUri(
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  throw UnsupportedError('Unknown platform');
}
