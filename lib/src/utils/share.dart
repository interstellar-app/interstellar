import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/platform/platform.dart'
    if (dart.library.io) 'package:interstellar/src/utils/platform/platform_native.dart'
    if (dart.library.js_interop) 'package:interstellar/src/utils/platform/platform_web.dart';
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
  Uri uri,
  String filename, {
  Directory? defaultDir,
}) async {
  downloadFromUri(uri, filename, defaultDir: defaultDir);
}
