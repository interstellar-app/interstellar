import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';

final bool isWebViewSupported = PlatformIs.mobile;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

late final String appVersion;
late final http.Client appHttpClient;

final Uri oauthRedirectUri = Uri.parse(
  PlatformIs.web
      ? '${Uri.base.origin}/auth.html'
      : PlatformIs.linux || PlatformIs.windows
      ? 'http://localhost:46837'
      : 'interstellar://auth',
);
