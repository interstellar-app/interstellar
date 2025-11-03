import 'package:flutter/widgets.dart';

enum ServerSoftware {
  mbin,
  lemmy,
  piefed;

  String get apiPathPrefix => switch (this) {
    ServerSoftware.mbin => '/api',
    ServerSoftware.lemmy => '/api/v3',
    ServerSoftware.piefed => '/api/alpha',
  };

  String get title => switch (this) {
    ServerSoftware.mbin => 'Mbin',
    ServerSoftware.lemmy => 'Lemmy',
    ServerSoftware.piefed => 'PieFed',
  };

  Color get color => switch (this) {
    ServerSoftware.mbin => Color(0xff4f2696),
    ServerSoftware.lemmy => Color(0xff03a80e),
    ServerSoftware.piefed => Color(0xff0e6ef9),
  };
}
