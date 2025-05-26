import 'package:flutter/material.dart';

class SubordinateScrollController extends ScrollController {
  SubordinateScrollController({
    required ScrollController parent,
    String? debugLabel,
  }) : _parent = parent,
        super(
        initialScrollOffset: parent.initialScrollOffset,
        keepScrollOffset: parent.keepScrollOffset,
        debugLabel: switch ((parent.debugLabel, debugLabel)) {
          (null, null) => null,
          (null, String label) => label,
          (String label, null) => '$label/sub',
          (String parentLabel, String label) => '$parentLabel/$label',
        },
      );

  final ScrollController _parent;
  bool _isActive = false;

  ScrollController get parent => _parent;

  bool get isActive => _isActive;
  set isActive(bool value) {
    if (_isActive != value) {
      _isActive = value;
      if (_isActive) {
        _attachToParent();
      } else {
        _detachFromParent();
      }
    }
  }

  @override
  ScrollPosition createScrollPosition(
      ScrollPhysics physics,
      ScrollContext context,
      ScrollPosition? oldPosition,
      ) {
    return _parent.createScrollPosition(physics, context, oldPosition);
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (_isActive) {
      _parent.attach(position);
    }
  }

  @override
  void detach(ScrollPosition position) {
    if (_isActive) {
      _parent.detach(position);
    }
    super.detach(position);
  }

  void _detachFromParent() {
    for (final position in positions) {
      _parent.detach(position);
    }
  }

  void _attachToParent() {
    for (final position in positions) {
      _parent.attach(position);
    }
  }

  @override
  void dispose() {
    if (isActive) {
      isActive = false;
    }
    super.dispose();
  }
}