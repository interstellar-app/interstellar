import 'package:sqlite3/wasm.dart';

// get sqlite on web
Future<CommonSqlite3> getSqlite() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final filesystem = await IndexedDbFileSystem.open(dbName: 'interstellar');
  sqlite.registerVirtualFileSystem(filesystem, makeDefault: true);
  return sqlite;
}
