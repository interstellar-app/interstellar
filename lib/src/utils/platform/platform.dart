export './platform_none.dart'
    if (dart.library.io) './platform_native.dart'
    if (dart.library.js_interop) './platform_web.dart';
