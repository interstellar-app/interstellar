import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  final bool shouldWrap;
  final Widget Function(Widget child) parentBuilder;
  final Widget child;

  const Wrapper({
    required this.shouldWrap,
    required this.parentBuilder,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return shouldWrap ? parentBuilder(child) : child;
  }
}
