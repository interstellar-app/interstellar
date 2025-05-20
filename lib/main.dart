import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/variables.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/init_push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await initDatabase();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(400, 400),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Show snackbar on error
  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    // Don't show error for rendering issues
    if (details.library == 'rendering library') return;
    // Don't show error for image loading issues
    if (details.library == 'image resource service') return;

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(details.summary.toString())),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
    return false;
  };

  final ac = AppController();
  await ac.init();

  if (Platform.isAndroid) {
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
