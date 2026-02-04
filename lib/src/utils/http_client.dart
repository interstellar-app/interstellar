import 'dart:async';

import 'package:http/http.dart' as http;

class UserAgentHttpClient extends http.BaseClient {
  UserAgentHttpClient(this._userAgent);

  final String _userAgent;
  final http.Client _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['User-Agent'] = _userAgent;

    return _httpClient.send(request);
  }

  @override
  void close() {
    _httpClient.close();
  }
}

class JwtHttpClient extends http.BaseClient {
  JwtHttpClient(this._jwt, this._httpClient);

  final String _jwt;

  final http.Client _httpClient;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['authorization'] = 'Bearer $_jwt';

    return _httpClient.send(request);
  }

  @override
  void close() {
    _httpClient.close();
  }
}
