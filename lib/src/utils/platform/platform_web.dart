import 'dart:convert';
import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

// get sqlite on web
Future<CommonSqlite3> getSqlite() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final filesystem = await IndexedDbFileSystem.open(dbName: 'interstellar');
  sqlite.registerVirtualFileSystem(filesystem, makeDefault: true);
  return sqlite;
}

Future<bool> downloadFromFile(
  XFile file,
  String filename, {
  Directory? defaultDir,
}) async {
  final data = base64Encode(await file.readAsBytes());
  final mimeType = file.mimeType;

  final a = web.HTMLAnchorElement()
    ..href = 'data:$mimeType;base64,$data'
    ..download = filename
    ..click()
    ..remove();

  return true;
}
