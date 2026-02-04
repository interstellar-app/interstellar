import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HideOnScroll extends StatefulWidget {
  const HideOnScroll({
    required this.controller,
    required this.hiddenOffset,
    required this.child,
    super.key,
    this.duration = Duration.zero,
  });

  final ScrollController? controller;
  final Offset hiddenOffset;
  final Duration duration;
  final Widget child;

  @override
  State<HideOnScroll> createState() => _HideOnScrollState();
}

class _HideOnScrollState extends State<HideOnScroll> {
  bool _hidden = false;

  void _onScroll() {
    final scrollDirection = widget.controller?.position.userScrollDirection;
    if (scrollDirection == ScrollDirection.forward && _hidden) {
      setState(() => _hidden = false);
    } else if (scrollDirection == ScrollDirection.reverse) {
      setState(() => _hidden = true);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _hidden ? widget.hiddenOffset : Offset.zero,
      duration: widget.duration,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onScroll);
    super.dispose();
  }
}
