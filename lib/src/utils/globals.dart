import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';

final isWebViewSupported = PlatformUtils.isMobile;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

late final String appVersion;
late final http.Client appHttpClient;

const redirectHost = 'localhost';
const redirectPort = 46837;
final redirectUri = PlatformUtils.isWeb
    ? '${Uri.base.origin}/auth.html'
    : PlatformUtils.isMobile ? 'interstellar://redirect' : 'http://$redirectHost:$redirectPort';