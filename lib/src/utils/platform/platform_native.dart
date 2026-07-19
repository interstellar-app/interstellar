import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart';

// get sqlite on native platforms.
Future<CommonSqlite3> getSqlite() async {
  return sqlite3;
}

Future<bool> downloadFromFile(
  XFile file,
  String filename, {
  Directory? defaultDir,
}) async {
  final useBytes = PlatformIs.mobile;

  String? filePath;
  if (defaultDir == null) {
    try {
      filePath = await FilePicker.platform.saveFile(
        fileName: filename,
        bytes: useBytes ? await file.readAsBytes() : null,
      );

      if (filePath == null) return false;
    } catch (e) {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Downloads directory not found');

      filePath = '${dir.path}/$filename';
    }
  } else {
    filePath = '${defaultDir.path}/$filename';
  }

  if (!useBytes || defaultDir != null) {
    final outFile = File(filePath);
    await outFile.writeAsBytes(await file.readAsBytes());
  }

  return true;
}
