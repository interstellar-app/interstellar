import 'package:flutter/widgets.dart';

/// Breakpoint sizes are as specified here:
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class Breakpoints {
  static const widthCompact = 0;
  static const widthMedium = 600;
  static const widthExpanded = 840;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) {
    final width = screenWidth(context);
    return widthCompact <= width && width < widthMedium;
  }

  static bool isMedium(BuildContext context) {
    final width = screenWidth(context);
    return widthMedium <= width && width < widthExpanded;
  }

  static bool isExpanded(BuildContext context) {
    final width = screenWidth(context);
    return widthExpanded <= width;
  }
}
