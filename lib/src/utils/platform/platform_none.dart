import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/common.dart';

// Stub to handle sqlite on different platforms.
Future<CommonSqlite3> getSqlite() async {
  throw UnsupportedError('Unknown pipeline');
}

Future<bool> downloadFromFile(
  XFile file,
  String filename, {
  Directory? defaultDir,
}) async {
  throw UnsupportedError('Unknown platform');
}
