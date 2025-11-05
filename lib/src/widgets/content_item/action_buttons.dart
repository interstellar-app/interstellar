import 'package:flutter/material.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:interstellar/src/utils/utils.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    this.upVotes,
    this.downVotes,
    this.boosts,
    this.numComments,
    this.activeBookmarkLists,
    this.isUpvoted = false,
    this.isDownvoted = false,
    this.isBoosted = false,
    this.onUpVote,
    this.onDownVote,
    this.onBoost,
    this.onReply,
    this.onAddBookmark,
    this.onRemoveBookmark,
  });

  final int? upVotes;
  final int? downVotes;
  final int? boosts;
  final int? numComments;
  final List<String>? activeBookmarkLists;

  final bool isUpvoted;
  final bool isDownvoted;
  final bool isBoosted;

  final void Function()? onUpVote;
  final void Function()? onDownVote;
  final void Function()? onBoost;
  final void Function()? onReply;
  final Future<void> Function()? onAddBookmark;
  final Future<void> Function()? onRemoveBookmark;

  @override
  Widget build(BuildContext context) {
    final comments = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (numComments != null) ...[
          Icon(Symbols.comment_rounded),
          Text(intFormat(numComments!)),
        ],
        if (onReply != null)
          IconButton(
            onPressed: onReply,
            icon: const Icon(Symbols.reply_rounded),
          ),
      ],
    );

    final bookmarks = activeBookmarkLists == null
        ? null
        : activeBookmarkLists!.isEmpty
        ? LoadingIconButton(
            onPressed: onAddBookmark,
            icon: const Icon(Symbols.bookmark_rounded, fill: 0),
          )
        : LoadingIconButton(
            onPressed: onRemoveBookmark,
            icon: const Icon(Symbols.bookmark_rounded, fill: 1),
          );

    final voting = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (boosts != null && onBoost != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onBoost,
                color: isBoosted ? Colors.purple.shade400 : null,
                icon: const Icon(Symbols.rocket_launch_rounded),
              ),
              Text(intFormat(boosts!)),
            ],
          ),
        if (upVotes != null && onUpVote != null)
          IconButton(
            onPressed: onUpVote,
            color: isUpvoted ? Colors.green.shade400 : null,
            icon: const Icon(Symbols.arrow_upward_rounded),
          ),
        Text(intFormat((upVotes ?? 0) - (downVotes ?? 0))),
        if (downVotes != null && onDownVote != null)
          IconButton(
            onPressed: onDownVote,
            color: isDownvoted ? Colors.red.shade400 : null,
            icon: const Icon(Symbols.arrow_downward_rounded),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) =>
          Row(children: [comments, const Spacer(), ?bookmarks, voting]),
    );
  }
}
