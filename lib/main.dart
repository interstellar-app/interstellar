import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/http_client.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/init_push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  appVersion = (await PackageInfo.fromPlatform()).version;
  appHttpClient = UserAgentHttpClient('Interstellar/$appVersion');

  await initDatabase();

  if (PlatformUtils.isDesktop) {
    await windowManager.ensureInitialized();

    // Get smallest dimensions of available displays and set minimum window
    // size to be a 16th of those dimensions.
    final screenSize = PlatformDispatcher.instance.displays
        .map((display) => display.size)
        .reduce((a, b) => Size(min(a.width, b.width), min(a.height, b.height)));
    final minWindowSize = screenSize / 8;

    WindowOptions windowOptions = WindowOptions(minimumSize: minWindowSize);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final ac = AppController();
  await ac.init();

  // Show snackbar on error
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ac.logger.e(details.summary);

    // Don't show error for rendering issues
    if (details.library == 'rendering library') return;
    // Don't show error for image loading issues
    if (details.library == 'image resource service') return;

    if (ac.profile.showErrors) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(details.summary.toString()),
          showCloseIcon: true,
        ),
      );
    }
  };
  PlatformDispatcher.instance.onError = (error, st) {
    ac.logger.e(error, stackTrace: st);
    if (ac.profile.showErrors) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(error.toString()), showCloseIcon: true),
      );
    }
    return false;
  };

  if (PlatformUtils.isAndroid) {
    await initPushNotifications(ac);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ac),
        ChangeNotifierProvider(create: (context) => DraftsController()),
      ],
      child: const App(),
    ),
  );
}
