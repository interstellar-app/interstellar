import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<ShareResult> shareUri(Uri uri) async {
  if (PlatformIs.mobile) {
    return await Share.shareUri(uri);
  } else {
    return await Share.share(uri.toString());
  }
}

Future<ShareResult> shareFile(Uri uri, String filename) async {
  final response = await http.get(uri);

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(response.bodyBytes);

  final result = await Share.shareXFiles([XFile(file.path)]);

  await file.delete();

  return result;
}

Future<void> downloadFile(
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

  if (!useBytes) {
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
  }
}
