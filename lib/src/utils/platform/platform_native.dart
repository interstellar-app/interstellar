import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

// get sqlite on native platforms.
Future<CommonSqlite3> getSqlite() async {
  return sqlite3;
}

Future<bool> downloadFromUri(
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  final response = await http.get(uri);

  if (defaultDir == null) {
    String? filePath;
    try {
      filePath = (await FilePicker.saveFile(
        fileName: filename,
        bytes: response.bodyBytes,
      ))?.path;

      if (filePath == null) return false;
    } catch (e) {
      // If file saver fails, then try to download to downloads directory
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Downloads directory not found');

      filePath = '${dir.path}/$filename';
    }
  } else {
    final filePath = '${defaultDir.path}/$filename';

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    if (PlatformIs.android) {
      MediaScanner.loadMedia(path: filePath);
    }
  }

  return true;
}
