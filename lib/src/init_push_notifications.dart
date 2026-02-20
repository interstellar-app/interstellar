import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/unifiedpush_storage.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:webpush_encryption/webpush_encryption.dart';

Future<void> initPushNotifications(AppController ac, bool isBackground) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    settings: InitializationSettings(
      android: const AndroidInitializationSettings(
        '@drawable/ic_launcher_monochrome',
      ),
      linux: LinuxInitializationSettings(
        defaultActionName: 'Open notification',
        defaultIcon: AssetsLinuxIcon('assets/icons/logo.png'),
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

      ac.logger.d('UnifiedPush message for $instance: ${data['title']}');

      final hostDomain = instance.split('@').last;

      final avatarUrl = data['avatarUrl'] as String?;
      final avatarFile = avatarUrl == null
          ? null
          : await cacheRemoteFile('https://$hostDomain$avatarUrl');

      await flutterLocalNotificationsPlugin.show(
        id: random.nextInt(2 ^ 31 - 1),
        title: data['title'],
        body: data['message'],
        notificationDetails: NotificationDetails(
          android: PlatformIs.android
              ? AndroidNotificationDetails(
                  data['category'] as String,
                  data['category'] as String,
                  largeIcon: avatarFile == null
                      ? null
                      : FilePathAndroidBitmap(avatarFile.path),
                )
              : null,
          linux: PlatformIs.linux
              ? LinuxNotificationDetails(
                  icon: avatarFile == null
                      ? null
                      : FilePathLinuxIcon(avatarFile.path),
                )
              : null,
        ),
      );
    },
    linuxOptions: PlatformIs.linux
        ? LinuxOptions(
            dbusName: 'one.jwr.interstellar',
            storage: UnifiedPushStorageInterstellar(),
            background: isBackground,
          )
        : null,
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
    showDialog<void>(
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
