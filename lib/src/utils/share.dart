import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/platform/platform.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<ShareResult> shareUri(Uri uri) async {
  if (PlatformIs.mobile) {
    return Share.shareUri(uri);
  } else {
    return Share.share(uri.toString());
  }
}

Future<ShareResult> shareFile(Uri uri, String filename) async {
  final response = await http.get(uri);

  final file = XFile.fromData(response.bodyBytes);

  final params = ShareParams(
    text: uri.toString(),
    files: [file],
    fileNameOverrides: [basename(uri.toString())],
  );
  final result = await SharePlus.instance.share(params);

  return result;
}

Future<void> downloadUri(
  BuildContext context,
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  final response = await http.get(uri);

  final mimeType = lookupMimeType(uri.toString());
  final file = XFile.fromData(response.bodyBytes, mimeType: mimeType);

  if (await downloadFromFile(file, filename, defaultDir: defaultDir)) {
    if (!context.mounted) return;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l(context).downloaded_file(filename)),
        showCloseIcon: true,
      ),
    );
  }
}

Future<void> downloadFile(
  BuildContext context,
  XFile file,
  String filename, {
  Directory? defaultDir,
}) async {
  if (await downloadFromFile(file, filename, defaultDir: defaultDir)) {
    if (!context.mounted) return;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l(context).downloaded_file(filename)),
        showCloseIcon: true,
      ),
    );
  }
}
