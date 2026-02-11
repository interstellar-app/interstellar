import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/share.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum LinkAction {
  share,
  copy,
  openInBrowser,
  openInWebview,
  menu;

  Future<void> call(BuildContext context, Uri uri) async {
    switch (this) {
      case LinkAction.share:
        shareUri(uri);
      case LinkAction.copy:
        await Clipboard.setData(ClipboardData(text: uri.toString()));
      case LinkAction.openInBrowser:
        launchUrl(uri);
      case LinkAction.openInWebview:
        final controller = WebViewController();
        unawaited(controller.setJavaScriptMode(JavaScriptMode.unrestricted));
        unawaited(controller.loadRequest(uri));

        unawaited(context.router.push(WebViewRoute(controller: controller)));
      case LinkAction.menu:
        openWebpageSecondary(context, uri);
    }
  }
}

void openWebpagePrimary(BuildContext context, Uri uri) =>
    context.read<AppController>().profile.defaultLinkAction.call(context, uri);

void openWebpageSecondary(BuildContext context, Uri uri) => showDialog<String>(
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
          LinkAction.share.call(context, uri);
        },
        child: Text(l(context).share),
      ),
      LoadingTonalButton(
        onPressed: () async {
          await LinkAction.copy.call(context, uri);
          if (!context.mounted) return;
          context.router.pop();
        },
        label: Text(l(context).copy),
      ),
      if (isWebViewSupported)
        FilledButton.tonal(
          onPressed: () {
            context.router.pop();
            LinkAction.openInWebview.call(context, uri);
          },
          child: Text(l(context).webView),
        ),
      FilledButton(
        onPressed: () {
          context.router.pop();
          LinkAction.openInBrowser.call(context, uri);
        },
        child: Text(l(context).browser),
      ),
    ],
    actionsOverflowAlignment: OverflowBarAlignment.center,
    actionsOverflowButtonSpacing: 8,
    actionsOverflowDirection: VerticalDirection.up,
  ),
);

@RoutePage()
class WebViewScreen extends StatelessWidget {
  const WebViewScreen({required this.controller, super.key});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WebViewWidget(controller: controller),
    );
  }
}

SelectionMenu<LinkAction> linkActionSelect(BuildContext context) =>
    SelectionMenu(l(context).setLinkAction, [
      SelectionMenuItem(
        value: LinkAction.share,
        title: l(context).share,
        icon: Symbols.share_rounded,
      ),
      SelectionMenuItem(
        value: LinkAction.copy,
        title: l(context).copy,
        icon: Symbols.copy_all_rounded,
      ),
      SelectionMenuItem(
        value: LinkAction.openInBrowser,
        title: l(context).browser,
        icon: Symbols.open_in_browser_rounded,
      ),
      SelectionMenuItem(
        value: LinkAction.menu,
        title: l(context).openLinkMenu,
        icon: Symbols.menu_rounded,
      ),
    ]);
