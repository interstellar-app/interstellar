import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';

final isWebViewSupported = PlatformUtils.isMobile;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

late final String appVersion;
late final http.Client appHttpClient;
