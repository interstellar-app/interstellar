import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';

final isWebViewSupported = PlatformIs.mobile;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

late final String appVersion;
late final http.Client appHttpClient;

const redirectHost = 'localhost';
const redirectPort = 46837;
final redirectUri = PlatformIs.web
    ? '${Uri.base.origin}/auth.html'
    : PlatformIs.mobile
    ? 'interstellar://redirect'
    : 'http://$redirectHost:$redirectPort';
