import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:provider/provider.dart';

class FloatingMenu extends StatefulWidget {
  final ActionItem? tapAction;
  final ActionItem? holdAction;
  final List<ActionItem> menuActions;

  const FloatingMenu({
    required this.tapAction,
    required this.holdAction,
    required this.menuActions,
    super.key,
  });

  @override
  State<FloatingMenu> createState() => FloatingMenuState();
}

class FloatingMenuState extends State<FloatingMenu>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();

    final animationSpeed = context.read<AppController>().profile.animationSpeed;
    final totalDuration = animationSpeed == 0
        ? 0
        : (250 / animationSpeed).toInt();
    final gapDuration = (150 / widget.menuActions.length) / animationSpeed;

    _animationController = AnimationController(
      duration: Duration(milliseconds: totalDuration),
      vsync: this,
    );

    for (var i = 0; i < widget.menuActions.length; i++) {
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (gapDuration / totalDuration) * i,
              1 -
                  (gapDuration / totalDuration) *
                      (widget.menuActions.length - 1 - i),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    }
  }

  void toggle() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ...widget.menuActions
            .asMap()
            .entries
            .map(
              (entry) => SlideTransition(
                position: _slideAnimations[entry.key],
                child: Container(
                  width: 45,
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FloatingActionButton(
                      onPressed: () {
                        entry.value.callback!();
                        _animationController.reverse();
                      },
                      heroTag: null,
                      tooltip: entry.value.name,
                      child: Icon(entry.value.icon),
                    ),
                  ),
                ),
              ),
            )
            .toList()
            .reversed,
        if (widget.tapAction != null || widget.holdAction != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
            child: GestureDetector(
              onLongPress: widget.holdAction?.callback,
              onSecondaryTap: widget.holdAction?.callback,
              child: FloatingActionButton(
                onPressed: widget.tapAction?.callback,
                child: widget.tapAction == null
                    ? null
                    : Icon(widget.tapAction!.icon),
              ),
            ),
          ),
      ],
    );
  }
}
