import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class RestrictedAuthException implements Exception {
  RestrictedAuthException(this.message, this.uri);

  final String message;

  final Uri? uri;

  @override
  String toString() {
    var msg = message;
    if (uri != null) {
      msg = '$msg, uri: $uri';
    }
    return msg;
  }
}

class ServerClient {
  ServerClient({
    required this.httpClient,
    required this.software,
    required this.domain,
  });

  http.Client httpClient;
  ServerSoftware software;
  String domain;
  List<(String, int)>? _langCodeIdPairs;

  Future<http.Response> get(
    String path, {
    Map<String, String?>? queryParams,
    JsonMap? body,
  }) => _send('GET', path, queryParams: queryParams, body: body);

  Future<http.Response> post(
    String path, {
    Map<String, String?>? queryParams,
    JsonMap? body,
  }) => _send('POST', path, queryParams: queryParams, body: body);

  Future<http.Response> put(
    String path, {
    Map<String, String?>? queryParams,
    JsonMap? body,
  }) => _send('PUT', path, queryParams: queryParams, body: body);

  Future<http.Response> delete(
    String path, {
    Map<String, String?>? queryParams,
    JsonMap? body,
  }) => _send('DELETE', path, queryParams: queryParams, body: body);

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String?>? queryParams,
    JsonMap? body,
  }) async {
    final request = http.Request(method, _uri(path, queryParams: queryParams));

    if (body != null) {
      request.body = jsonEncode(body);
      request.headers['Content-Type'] = 'application/json';
    }

    return _sendRequest(request);
  }

  Future<http.Response> postMultipart(
    String path, {
    Map<String, String?>? queryParams,
    Map<String, String>? fields,
    Map<String, XFile>? files,
  }) => _sendMultipart(
    'POST',
    path,
    queryParams: queryParams,
    fields: fields,
    files: files,
  );

  Future<http.Response> _sendMultipart(
    String method,
    String path, {
    Map<String, String?>? queryParams,
    Map<String, String>? fields,
    Map<String, XFile>? files,
  }) async {
    final request = http.MultipartRequest(
      method,
      _uri(path, queryParams: queryParams),
    );

    if (fields != null) request.fields.addAll(fields);
    for (final entry in (files ?? {}).entries) {
      final name = entry.key;
      final file = entry.value;

      final filename = basename(file.path);
      final mime = lookupMimeType(filename);

      request.files.add(
        http.MultipartFile.fromBytes(
          name,
          await file.readAsBytes(),
          filename: filename,
          contentType: mime == null ? null : MediaType.parse(mime),
        ),
      );
    }

    return _sendRequest(request);
  }

  Future<http.Response> _sendRequest(http.BaseRequest request) async {
    final response = await http.Response.fromStream(
      await httpClient.send(request),
    );

    checkResponseSuccess(request.url, response);

    return response;
  }

  Uri _uri(String path, {Map<String, String?>? queryParams}) => Uri.https(
    domain,
    software.apiPathPrefix + path,
    queryParams == null ? null : _normalizeQueryParams(queryParams),
  );

  /// Remove null and empty values.
  Map<String, String> _normalizeQueryParams(Map<String, String?> queryParams) =>
      Map<String, String>.from(
        Map.fromEntries(
          queryParams.entries.where(
            (e) => e.value != null && e.value!.isNotEmpty,
          ),
        ),
      );

  Future<List<(String, int)>> languageCodeIdPairs() async {
    if (_langCodeIdPairs == null) {
      List<dynamic> allLanguages;

      switch (software) {
        case ServerSoftware.mbin:
          throw Exception('Tried to get lang id with Mbin');

        case ServerSoftware.lemmy:
          final response = await get('/site');

          final json = response.bodyJson;

          allLanguages = json['all_languages']! as List<dynamic>;

        case ServerSoftware.piefed:
          final response = await get('/site');

          final json = response.bodyJson;

          allLanguages =
              (json['site']! as JsonMap)['all_languages']! as List<dynamic>;
      }

      _langCodeIdPairs = allLanguages
          .map((e) => (e['code'] as String, e['id'] as int))
          // Don't track "und" (undefined) language
          .where((pair) => pair.$1 != 'und')
          .toList();
    }

    return _langCodeIdPairs!;
  }

  Future<int?> languageIdFromCode(String lang) async {
    for (final pair in await languageCodeIdPairs()) {
      if (pair.$1 == lang) return pair.$2;
    }
    return null;
  }

  /// Throws an error if [response] is not successful.
  static void checkResponseSuccess(Uri url, http.Response response) {
    if (response.statusCode < 400) return;
    if (response.statusCode == 401) {
      throw RestrictedAuthException(response.body, url);
    }

    var message = 'Request failed with status ${response.statusCode}';

    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }

    if (response.body.isNotEmpty) {
      message = '$message: ${response.body}';
    }

    throw http.ClientException(message, url);
  }
}

extension BodyJson on http.Response {
  JsonMap get bodyJson {
    // Force utf8 decoding due to Lemmy not providing correct content type headers (https://github.com/interstellar-app/interstellar/pull/50)
    return jsonDecode(utf8.decode(bodyBytes)) as JsonMap;
  }
}
