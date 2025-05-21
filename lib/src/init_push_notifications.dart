import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/controller/controller.dart';
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
    onNewEndpoint: (String endpoint, String instance) async {
      await ac.api.notifications.pushRegister(
        endpoint: endpoint,
        serverKey: ac.webPushKeys.publicKey.auth,
        contentPublicKey: ac.webPushKeys.publicKey.p256dh,
      );
    },
    onRegistrationFailed: (String instance) {
      ac.removePushRegistrationStatus(instance);
    },
    onUnregistered: (String instance) {
      ac.removePushRegistrationStatus(instance);
    },
    onMessage: (Uint8List message, String instance) async {
      final data = jsonDecode(
        utf8.decode(await WebPush().decrypt(ac.webPushKeys, message)),
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
