import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/utils/share.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:interstellar/src/controller/router.gr.dart';

void openWebpagePrimary(BuildContext context, Uri uri) {
  launchUrl(uri);
}

void openWebpageSecondary(BuildContext context, Uri uri) {
  showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l(context).openLink),
      content: SelectableText(uri.toString()),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => context.router.pop(),
          child: Text(l(context).cancel),
        ),
        FilledButton.tonal(
          onPressed: () {
            context.router.pop();
            shareUri(uri);
          },
          child: Text(l(context).share),
        ),
        LoadingTonalButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: uri.toString()));

            if (!context.mounted) return;
            context.router.pop();
          },
          label: Text(l(context).copy),
        ),
        if (isWebViewSupported)
          FilledButton.tonal(
            onPressed: () {
              context.router.pop();

              var controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadRequest(uri);

              context.router.push(WebViewRoute(controller: controller));
            },
            child: Text(l(context).webView),
          ),
        FilledButton(
          onPressed: () {
            context.router.pop();

            launchUrl(uri);
          },
          child: Text(l(context).browser),
        ),
      ],
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.up,
    ),
  );
}

@RoutePage()
class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key, required this.controller});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WebViewWidget(controller: controller),
    );
  }
}
