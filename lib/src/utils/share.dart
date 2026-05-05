import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/platform/platform.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:path/path.dart';
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

Future<void> downloadFile(
  BuildContext context,
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  await downloadFromUri(uri, filename, defaultDir: defaultDir);
  if (!context.mounted) return;
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(l(context).downloaded_file(filename)),
      showCloseIcon: true,
    ),
  );
}
