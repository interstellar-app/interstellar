import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/api/api.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/oauth.dart';
import 'package:interstellar/src/controller/account.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/jwt_http_client.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/password_editor.dart';
import 'package:interstellar/src/widgets/redirect_listen.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:provider/provider.dart';

class LoginConfirmScreen extends StatefulWidget {
  final ServerSoftware software;
  final String server;

  const LoginConfirmScreen(this.software, this.server, {super.key});

  @override
  State<LoginConfirmScreen> createState() => _LoginConfirmScreenState();
}

class _LoginConfirmScreenState extends State<LoginConfirmScreen> {
  final _usernameEmailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _totpTokenTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).addAccount)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  widget.server,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  widget.software.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (widget.software == ServerSoftware.lemmy ||
              widget.software == ServerSoftware.piefed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AutofillGroup(
                child: Column(
                  children: [
                    TextEditor(
                      _usernameEmailTextController,
                      label: l(context).usernameOrEmail,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      autofillHints: [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                    ),
                    const SizedBox(height: 12),
                    PasswordEditor(
                      _passwordTextController,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (widget.software == ServerSoftware.lemmy) ...[
                      const SizedBox(height: 12),
                      TextEditor(
                        _totpTokenTextController,
                        label: l(context).totpToken,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                    ],
                  ],
                ),
              )
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  String account = '@${widget.server}';
                  context.read<AppController>().setAccount(
                    account,
                    const Account(),
                    switchNow: true,
                  );

                  Navigator.pop(context, true);
                },
                child: Text(l(context).guest),
              ),
              const SizedBox(width: 12),
              LoadingFilledButton(
                label: Text(l(context).login),
                onPressed:
                    widget.software == ServerSoftware.lemmy &&
                        (_usernameEmailTextController.text.isEmpty ||
                            _passwordTextController.text.isEmpty)
                    ? null
                    : () async {
                        if (widget.software == ServerSoftware.lemmy ||
                            widget.software == ServerSoftware.piefed) {
                          final loginPath =
                              '${widget.software.apiPathPrefix}/user/login';

                          final loginEndpoint = Uri.https(
                            widget.server,
                            loginPath,
                          );

                          final response = await http.post(
                            loginEndpoint,
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              switch (widget.software) {
                                ServerSoftware.lemmy => 'username_or_email',
                                ServerSoftware.piefed => 'username',
                                ServerSoftware.mbin => throw Exception(
                                  'unreachable',
                                ),
                              }: _usernameEmailTextController.text,
                              'password': _passwordTextController.text,
                              if (widget.software == ServerSoftware.lemmy)
                                'totp_2fa_token': nullIfEmpty(
                                  _totpTokenTextController.text,
                                ),
                            }),
                          );
                          ServerClient.checkResponseSuccess(
                            loginEndpoint,
                            response,
                          );

                          final jwt = response.bodyJson['jwt'] as String;
                          final user = await API(
                            ServerClient(
                              httpClient: JwtHttpClient(jwt),
                              software: widget.software,
                              domain: widget.server,
                            ),
                          ).users.getMe();

                          // Check BuildContext
                          if (!context.mounted) return;
                          context.read<AppController>().setAccount(
                            '${user.name}@${widget.server}',
                            Account(jwt: response.bodyJson['jwt'] as String),
                          );
                        } else {
                          final authorizationEndpoint = Uri.https(
                            widget.server,
                            '/authorize',
                          );
                          final tokenEndpoint = Uri.https(
                            widget.server,
                            '/token',
                          );

                          String identifier = await context
                              .read<AppController>()
                              .getMbinOAuthIdentifier(
                                widget.software,
                                widget.server,
                              );

                          final grant = oauth2.AuthorizationCodeGrant(
                            identifier,
                            authorizationEndpoint,
                            tokenEndpoint,
                          );

                          Uri authorizationUrl = grant.getAuthorizationUrl(
                            Uri.parse(redirectUri),
                            scopes: oauthScopes,
                          );

                          // Check BuildContext
                          if (!context.mounted) return;

                          Map<String, String>? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RedirectListener(
                                authorizationUrl,
                                title: widget.server,
                              ),
                            ),
                          );

                          if (result == null || !result.containsKey('code')) {
                            throw Exception(
                              result?['message'] != null
                                  ? result!['message']
                                  : 'unsuccessful login',
                            );
                          }

                          var client = await grant.handleAuthorizationResponse(
                            result,
                          );

                          var user = await API(
                            ServerClient(
                              httpClient: client,
                              software: widget.software,
                              domain: widget.server,
                            ),
                          ).users.getMe();

                          // Check BuildContext
                          if (!context.mounted) return;

                          context.read<AppController>().setAccount(
                            '${user.name}@${widget.server}',
                            Account(oauth: client.credentials),
                            switchNow: true,
                          );
                        }

                        Navigator.pop(context, true);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
