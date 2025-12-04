import 'dart:convert';

import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/widgets/redirect_listen.dart';

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

  final response = await appHttpClient.post(
    Uri.https(instanceHost, path),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'name': oauthName,
      'contactEmail': oauthContact,
      'public': true,
      'redirectUris': [redirectUri],
      'grants': oauthGrants,
      'scopes': oauthScopes,
    }),
  );

  return response.bodyJson['identifier'] as String;
}
