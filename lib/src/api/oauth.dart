import 'dart:convert';

import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/utils.dart';
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

  final redirectUrl = PlatformUtils.isWeb ? 'http://${Uri.base.host}:${Uri.base.port}/auth.html' : redirectUri;

  final response = await appHttpClient.post(
    Uri.https(instanceHost, path),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'name': oauthName,
      'contactEmail': oauthContact,
      'public': true,
      'redirectUris': [redirectUrl],
      'grants': oauthGrants,
      'scopes': oauthScopes,
    }),
  );

  return response.bodyJson['identifier'] as String;
}
