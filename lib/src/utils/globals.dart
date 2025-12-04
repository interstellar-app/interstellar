import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final isWebViewSupported = Platform.isAndroid || Platform.isIOS;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

late final String appVersion;
late final http.Client appHttpClient;
