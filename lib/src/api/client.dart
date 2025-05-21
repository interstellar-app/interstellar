import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/utils.dart';

class ServerClient {
  http.Client httpClient;
  ServerSoftware software;
  String domain;

  ServerClient({
    required this.httpClient,
    required this.software,
    required this.domain,
  });

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    JsonMap? body,
    Map<String, String?>? queryParams,
  }) =>
      send('GET', path, headers: headers, body: body, queryParams: queryParams);

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    JsonMap? body,
    Map<String, String?>? queryParams,
  }) => send(
    'POST',
    path,
    headers: headers,
    body: body,
    queryParams: queryParams,
  );

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    JsonMap? body,
    Map<String, String?>? queryParams,
  }) =>
      send('PUT', path, headers: headers, body: body, queryParams: queryParams);

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    JsonMap? body,
    Map<String, String?>? queryParams,
  }) => send(
    'DELETE',
    path,
    headers: headers,
    body: body,
    queryParams: queryParams,
  );

  Future<http.Response> send(
    String method,
    String path, {
    Map<String, String>? headers,
    JsonMap? body,
    Map<String, String?>? queryParams,
  }) async {
    var request = http.Request(
      method,
      Uri.https(
        domain,
        software.apiPathPrefix + path,
        queryParams == null ? null : _normalizeQueryParams(queryParams),
      ),
    );

    if (body != null) {
      request.body = jsonEncode(body);
      request.headers['Content-Type'] = 'application/json';
    }
    if (headers != null) request.headers.addAll(headers);

    return await sendRequest(request);
  }

  Future<http.Response> sendRequest(http.BaseRequest request) async {
    final response = await http.Response.fromStream(
      await httpClient.send(request),
    );

    checkResponseSuccess(request.url, response);

    return response;
  }

  /// Remove null and empty values.
  Map<String, String> _normalizeQueryParams(Map<String, String?> queryParams) =>
      Map<String, String>.from(
        Map.fromEntries(
          queryParams.entries.where(
            (e) => (e.value != null && e.value!.isNotEmpty),
          ),
        ),
      );

  /// Throws an error if [response] is not successful.
  static void checkResponseSuccess(Uri url, http.Response response) {
    if (response.statusCode < 400) return;

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
