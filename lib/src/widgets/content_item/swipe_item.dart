import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:provider/provider.dart';

class SwipeItem extends StatefulWidget {
  const SwipeItem({
    required this.child,
    super.key,
    this.onUpVote,
    this.onDownVote,
    this.onBoost,
    this.onBookmark,
    this.onReply,
    this.onMarkAsRead,
    this.onModeratePin,
    this.onModerateMarkNSFW,
    this.onModerateDelete,
    this.onModerateBan,
  });

  final Widget child;
  final void Function()? onUpVote;
  final void Function()? onDownVote;
  final void Function()? onBoost;
  final void Function()? onBookmark;
  final void Function()? onReply;
  final void Function()? onMarkAsRead;
  final Future<void> Function()? onModeratePin;
  final Future<void> Function()? onModerateMarkNSFW;
  final Future<void> Function()? onModerateDelete;
  final Future<void> Function()? onModerateBan;

  @override
  State<SwipeItem> createState() => _SwipeItemState();
}

class _SwipeItemState extends State<SwipeItem> {
  Color _color = Colors.green;
  double _dismissThreshold = 0;
  DismissUpdateDetails? _oldDismissDetails;
  DismissDirection _dismissDirection = DismissDirection.startToEnd;
  int _currentAction = 0;

  ActionItem getSwipeAction(SwipeAction action) {
    return switch (action) {
      SwipeAction.upvote => swipeActionUpvote(
        context,
      ).withProps(ActionLocation.hide, widget.onUpVote),
      SwipeAction.downvote => swipeActionDownvote(
        context,
      ).withProps(ActionLocation.hide, widget.onDownVote),
      SwipeAction.boost => swipeActionBoost(
        context,
      ).withProps(ActionLocation.hide, widget.onBoost),
      SwipeAction.bookmark => swipeActionBookmark(
        context,
      ).withProps(ActionLocation.hide, widget.onBookmark),
      SwipeAction.reply => swipeActionReply(
        context,
      ).withProps(ActionLocation.hide, widget.onReply),
      SwipeAction.markAsRead => swipeActionMarkRead(
        context,
      ).withProps(ActionLocation.hide, widget.onMarkAsRead),
      SwipeAction.moderatePin => swipeActionModeratePin(
        context,
      ).withProps(ActionLocation.hide, widget.onModeratePin),
      SwipeAction.moderateMarkNSFW => swipeActionModerateMarkNSFW(
        context,
      ).withProps(ActionLocation.hide, widget.onModerateMarkNSFW),
      SwipeAction.moderateDelete => swipeActionModerateDelete(
        context,
      ).withProps(ActionLocation.hide, widget.onModerateDelete),
      SwipeAction.moderateBan => swipeActionModerateBan(
        context,
      ).withProps(ActionLocation.hide, widget.onModerateBan),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final actionThreshold = ac.profile.swipeActionThreshold;

    final actions = <ActionItem>[
      getSwipeAction(ac.profile.swipeActionLeftShort),
      getSwipeAction(ac.profile.swipeActionLeftLong),
      getSwipeAction(ac.profile.swipeActionRightShort),
      getSwipeAction(ac.profile.swipeActionRightLong),
    ];

    return Listener(
      onPointerUp: (event) {
        final actionSelectorValue =
            _dismissDirection == DismissDirection.endToStart ? 2 : 0;

        for (var i = 0; i < 2; i++) {
          if (_dismissThreshold > actionThreshold &&
              (_dismissThreshold < (actionThreshold * (i + 2)) || i == 1)) {
            _dismissThreshold = 0;
            if (actions[i + actionSelectorValue].callback != null) {
              actions[i + actionSelectorValue].callback!();
              ac.vibrate(HapticsType.medium);
            }
            break;
          }
        }
      },
      child: Dismissible(
        key: ObjectKey(widget.child.key),
        background: Container(
          color: _color,
          alignment: _dismissDirection == DismissDirection.startToEnd
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              _dismissDirection == DismissDirection.startToEnd
                  ? actions[_currentAction].icon
                  : actions[_currentAction + 2].icon,
            ),
          ),
        ),
        dismissThresholds: const {
          DismissDirection.startToEnd: 1,
          DismissDirection.endToStart: 1,
        },
        onUpdate: (DismissUpdateDetails newDetails) {
          final oldDetails = _oldDismissDetails;
          _oldDismissDetails = newDetails;
          _dismissThreshold = newDetails.progress;
          if (_dismissDirection != newDetails.direction) {
            setState(() {
              _dismissDirection = newDetails.direction;
            });
          }

          bool isRangeNewlyEntered(
            double startInclusive, [
            double? endExclusive,
          ]) =>
              ((oldDetails?.progress ?? 0) < startInclusive &&
                  newDetails.progress >= startInclusive) ||
              (endExclusive != null &&
                  (oldDetails?.progress ?? 0) >= endExclusive &&
                  newDetails.progress < endExclusive);

          if (isRangeNewlyEntered(actionThreshold) ||
              isRangeNewlyEntered(actionThreshold * 2)) {
            ac.vibrate(HapticsType.light);
          }

          final actionSelectorValue =
              newDetails.direction == DismissDirection.endToStart ? 2 : 0;

          if (oldDetails == null ||
              oldDetails.progress == 0 ||
              oldDetails.direction != newDetails.direction ||
              isRangeNewlyEntered(0, actionThreshold)) {
            setState(() {
              _color = actions[0 + actionSelectorValue].color!.darken(30);
            });
          } else if (isRangeNewlyEntered(
            actionThreshold,
            actionThreshold * 2,
          )) {
            setState(() {
              _color = actions[0 + actionSelectorValue].color!;
              _currentAction = 0;
            });
          } else if (isRangeNewlyEntered(actionThreshold * 2)) {
            setState(() {
              _color = actions[1 + actionSelectorValue].color!;
              _currentAction = 1;
            });
          }
        },
        confirmDismiss: (direction) async => false,
        child: widget.child,
      ),
    );
  }
}
