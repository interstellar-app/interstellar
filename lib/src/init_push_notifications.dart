import 'dart:convert';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:webpush_encryption/webpush_encryption.dart';

Future<ByteArrayAndroidBitmap> _downloadImageToAndroidBitmap(String url) async {
  final res = await http.get(Uri.parse(url));

  final enc = base64.encode(res.bodyBytes);

  final androidBitmap = ByteArrayAndroidBitmap.fromBase64String(enc);

  return androidBitmap;
}

Future<void> initPushNotifications(AppController ac) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings(
        '@drawable/ic_launcher_monochrome',
      ),
    ),
  );

  final random = Random();

  await UnifiedPush.initialize(
    onNewEndpoint: (PushEndpoint endpoint, String instance) async {
      await ac.api.notifications.pushRegister(
        endpoint: endpoint.url,
        serverKey: ac.webPushKeys.publicKey.auth,
        contentPublicKey: ac.webPushKeys.publicKey.p256dh,
      );
    },
    onRegistrationFailed: (FailedReason reason, String instance) {
      ac.removePushRegistrationStatus(instance);
    },
    onUnregistered: (String instance) {
      ac.removePushRegistrationStatus(instance);
    },
    onMessage: (PushMessage message, String instance) async {
      final data = jsonDecode(
        utf8.decode(
          message.decrypted
              ? message.content
              : await WebPush().decrypt(ac.webPushKeys, message.content),
        ),
      );

      final hostDomain = instance.split('@').last;
      final avatarUrl = data['avatarUrl'] as String?;

      await flutterLocalNotificationsPlugin.show(
        random.nextInt(2 ^ 31 - 1),
        data['title'],
        data['message'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            data['category'] as String,
            data['category'] as String,
            largeIcon: avatarUrl != null
                ? await _downloadImageToAndroidBitmap(
                    'https://$hostDomain$avatarUrl',
                  )
                : null,
          ),
        ),
      );
    },
  );
}

Future<String?> getUnifiedPushDistributor(BuildContext context) async {
  const noDistributorUrl = 'https://unifiedpush.org/users/intro/';

  final distributors = await UnifiedPush.getDistributors();

  if (!context.mounted) return null;

  if (distributors.length > 1) {
    return SelectionMenu<String>(
      l(context).pushNotificationsDialog_title,
      distributors.map((d) => SelectionMenuItem(value: d, title: d)).toList(),
    ).askSelection(context, null);
  } else if (distributors.length == 1) {
    return distributors.single;
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l(context).pushNotificationsDialog_title),
        content: SingleChildScrollView(
          child: SelectableText(
            l(context).pushNotificationsDialog_noDistributor(noDistributorUrl),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: context.router.pop,
            child: Text(l(context).close),
          ),
          FilledButton(
            onPressed: () =>
                openWebpagePrimary(context, Uri.parse(noDistributorUrl)),
            child: Text(l(context).openInBrowser),
          ),
        ],
      ),
    );

    return null;
  }
}
