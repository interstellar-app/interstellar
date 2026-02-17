import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

// get sqlite on web
Future<CommonSqlite3> getSqlite() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final filesystem = await IndexedDbFileSystem.open(dbName: 'interstellar');
  sqlite.registerVirtualFileSystem(filesystem, makeDefault: true);
  return sqlite;
}

Future<void> downloadFromUri(
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  final response = await http.get(uri);

  final data = base64Encode(response.bodyBytes);
  final mimeType = lookupMimeType(uri.toString());

  final a = web.HTMLAnchorElement()
    ..href = 'data:$mimeType;base64,$data'
    ..download = 'image.${uri.pathSegments.last}'
    ..click()
    ..remove();
}
