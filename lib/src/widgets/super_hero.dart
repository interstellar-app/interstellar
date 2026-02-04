import 'package:flutter/material.dart';

// Is workaround for having nested hero animations which is disallowed by
// default in flutter but works anyway.
class SuperHero extends Hero {
  const SuperHero({
    required super.tag,
    required super.child,
    super.key,
    super.createRectTween,
    super.flightShuttleBuilder,
    super.placeholderBuilder,
    super.transitionOnUserGestures,
  });
}
