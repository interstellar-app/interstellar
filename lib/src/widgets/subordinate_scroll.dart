import 'package:flutter/material.dart';

// Helper to prevent multiple scroll positions being attached to
// a single parent scroll controller.
// Attaches/detaches its position from the parent whenever isActive is changed.
// Useful for when having multiple CustomScrollViews under a single
// NestedScrollView.

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
    positions.forEach(_parent.detach);
  }

  void _attachToParent() {
    positions.forEach(_parent.attach);
  }

  @override
  void dispose() {
    if (isActive) {
      isActive = false;
    }
    super.dispose();
  }
}
