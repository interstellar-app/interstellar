import 'dart:ui';

import 'package:flutter/material.dart';

class Blur extends StatelessWidget {
  const new(
    this.child, {
    super.key,
    this.blur = 16,
    this.blurColor = Colors.white,
    this.borderRadius,
    this.colorOpacity = 0.2,
    this.overlay,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double blur;
  final Color blurColor;
  final BorderRadius? borderRadius;
  final double colorOpacity;
  final Widget? overlay;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  color: blurColor.withOpacity(colorOpacity),
                ),
                alignment: alignment,
                child: overlay,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
