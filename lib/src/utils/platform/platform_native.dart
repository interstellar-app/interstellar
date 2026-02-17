import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

// get sqlite on native platforms.
Future<CommonSqlite3> getSqlite() async {
  return sqlite3;
}

Future<void> downloadFromUri(
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  final response = await http.get(uri);
  // Whether to use bytes property or need to manually write file
  final useBytes = PlatformIs.mobile;

  String? filePath;
  if (defaultDir == null) {
    try {
      filePath = await FilePicker.platform.saveFile(
        fileName: filename,
        bytes: useBytes ? response.bodyBytes : null,
      );

      if (filePath == null) return;
    } catch (e) {
      // If file saver fails, then try to download to downloads directory
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Downloads directory not found');

      filePath = '${dir.path}/$filename';
    }
  } else {
    filePath = '${defaultDir.path}/$filename';
  }

  if (!useBytes || defaultDir != null) {
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
  }
}
