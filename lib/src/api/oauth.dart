import 'dart:convert';

import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/utils/globals.dart';

const oauthName = 'Interstellar';
const oauthContact = 'appstore@jwr.one';
const oauthGrants = ['authorization_code', 'refresh_token'];
const oauthScopes = [
  'read',
  'write',
  'delete',
  'subscribe',
  'block',
  'vote',
  'report',
  'user',
  'moderate',
  'bookmark_list',
];

Future<String> registerOauthApp(String instanceHost) async {
  const path = '/api/client';
  final url = Uri.https(instanceHost, path);

  final response = await appHttpClient.post(
    url,
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'name': oauthName,
      'contactEmail': oauthContact,
      'public': true,
      'redirectUris': [oauthRedirectUri.toString()],
      'grants': oauthGrants,
      'scopes': oauthScopes,
    }),
  );
  ServerClient.checkResponseSuccess(url, response);

  return response.bodyJson['identifier']! as String;
}
