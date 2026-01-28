import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

const _redirectHost = 'localhost';
const _redirectPort = 46837;
const redirectUri = 'http://$_redirectHost:$_redirectPort';

@RoutePage()
class RedirectListener extends StatefulWidget {
  final Uri initUri;
  final String title;

  const RedirectListener(this.initUri, {super.key, this.title = ''});

  @override
  State<RedirectListener> createState() => _RedirectListenerState();
}

class _RedirectListenerState extends State<RedirectListener> {
  WebViewController? _controller;
  HttpServer? _httpServer;

  Future<Uri> _listenForAuth() async {
    if (!PlatformUtils.isWeb) {
      _httpServer = await HttpServer.bind(_redirectHost, _redirectPort);
      _httpServer?.listen((req) async {
        req.response.statusCode = 200;
        req.response.headers.set('content-type', 'text/plain');
        req.response.writeln(l(context).redirectReceivedMessage);

        await req.response.close();
      });
    }

    final callbackUrlScheme = PlatformUtils.isWeb ? 'http': 'http://$_redirectHost:$_redirectPort';
    final result = await FlutterWebAuth2.authenticate(url: widget.initUri.toString(), callbackUrlScheme: callbackUrlScheme, options: FlutterWebAuth2Options(useWebview: false));
    return Uri.parse(result);
  }

  @override
  void initState() {
    super.initState();
    if (!isWebViewSupported) {
      _listenForAuth().then(
        (value) => context.router.pop(value.queryParameters),
      );
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(redirectUri)) {
                WebViewCookieManager().clearCookies();
                context.router.pop(Uri.parse(request.url).queryParameters);
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(widget.initUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isWebViewSupported) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: WebViewWidget(controller: _controller!),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l(context).continueInBrowser),
            const SizedBox(height: 8),
            LoadingTextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: widget.initUri.toString()),
                );
              },
              label: Text(l(context).continueInBrowser_manual),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!PlatformUtils.isWeb) {
      _httpServer?.close();
    }
    super.dispose();
  }
}
