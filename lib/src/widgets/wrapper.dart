import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({
    required this.shouldWrap,
    required this.parentBuilder,
    required this.child,
    super.key,
  });

  final bool shouldWrap;
  final Widget Function(Widget child) parentBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return shouldWrap ? parentBuilder(child) : child;
  }
}
