import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/screens/feed/create_screen.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/widgets/emoji_picker/emoji_picker.dart';
import 'package:interstellar/src/widgets/menus/community_menu.dart';
import 'package:interstellar/src/widgets/menus/user_menu.dart';
import 'package:interstellar/src/widgets/tags/post_flairs.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/explore/domain_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/report_content.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/controller/server.dart';

Future<void> showContentMenu(
  BuildContext context,
  ContentItem widget, {
  Function()? onEdit,
  Function(String lang)? onTranslate,
  Function()? onReply,
}) async {
  final ac = context.read<AppController>();

  return ContextMenu(
    actionSpacing: 50,
    actions: [
      if (widget.onEmojiReact != null)
        ContextMenuAction(
          child: EmojiPicker(
            childBuilder: (onClick, focusNode) => IconButton(
              onPressed: onClick,
              focusNode: focusNode,
              icon: Icon(Symbols.add_reaction_rounded),
            ),
            onSelect: (emoji) => widget.onEmojiReact!(emoji),
          ),
        ),
      if (widget.boosts != null)
        ContextMenuAction(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  widget.onBoost!();
                  Navigator.pop(context);
                },
                icon: const Icon(Symbols.rocket_launch_rounded),
                color: widget.isBoosted ? Colors.purple.shade400 : null,
              ),
              Text(intFormat(widget.boosts!)),
            ],
          ),
        ),
      if (widget.upVotes != null)
        ContextMenuAction(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  widget.onUpVote!();
                  Navigator.pop(context);
                },
                icon: const Icon(Symbols.arrow_upward_rounded),
                color: widget.isUpVoted ? Colors.green.shade400 : null,
              ),
              Text(intFormat(widget.upVotes!)),
            ],
          ),
        ),
      if (widget.downVotes != null)
        ContextMenuAction(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  widget.onDownVote!();
                  Navigator.pop(context);
                },
                icon: const Icon(Symbols.arrow_downward_rounded),
                color: widget.isDownVoted ? Colors.red.shade400 : null,
              ),
              Text(intFormat(widget.downVotes!)),
            ],
          ),
        ),
      if (widget.notificationControlStatus != null &&
          widget.onNotificationControlStatusChange != null &&
          ((ac.serverSoftware == ServerSoftware.mbin &&
                  widget.contentTypeName != l(context).comment) ||
              ac.serverSoftware == ServerSoftware.piefed))
        ContextMenuAction(
          child: NotificationControlSegment(
            widget.notificationControlStatus!,
            widget.onNotificationControlStatusChange!,
          ),
        ),
    ],
    links: widget.shareLinks,
    items: [
      if (widget.crossPost != null && context.read<AppController>().isLoggedIn)
        ContextMenuItem(
          title: l(context).crossPost,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateScreen(crossPost: widget.crossPost!),
            ),
          ),
        ),
      if (widget.domain != null)
        ContextMenuItem(
          title: l(context).moreFrom(widget.domain!),
          onTap: () => pushRoute(
            context,
            builder: (context) => DomainScreen(widget.domainIdOnClick!),
          ),
        ),
      if (widget.onReply != null && onReply != null)
        ContextMenuItem(
          title: l(context).reply,
          onTap: () async {
            onReply();
            Navigator.pop(context);
          },
        ),
      if (widget.activeBookmarkLists != null &&
          widget.loadPossibleBookmarkLists != null &&
          widget.onAddBookmarkToList != null &&
          widget.onRemoveBookmarkFromList != null)
        ContextMenuItem(
          title: l(context).bookmark,
          onTap: () async => showBookmarksMenu(context, widget),
          trailing: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Symbols.arrow_right_rounded),
          ),
        ),
      if (ac.serverSoftware != ServerSoftware.mbin &&
          widget.activeBookmarkLists != null &&
          widget.onAddBookmark != null &&
          widget.onRemoveBookmark != null)
        ContextMenuItem(
          title: l(context).bookmark,
          onTap: () async {
            if (widget.activeBookmarkLists!.isEmpty) {
              widget.onAddBookmark!();
            } else {
              widget.onRemoveBookmark!();
            }
            Navigator.pop(context);
          },
        ),
      if (widget.onMarkAsRead != null)
        ContextMenuItem(
          title: widget.read
              ? l(context).action_markUnread
              : l(context).action_markRead,
          onTap: () async {
            widget.onMarkAsRead!();
            Navigator.of(context).pop();
          },
        ),
      if (widget.onReport != null)
        ContextMenuItem(
          title: l(context).report,
          onTap: () async {
            final reportReason = await reportContent(
              context,
              widget.contentTypeName,
            );

            if (reportReason != null) {
              await widget.onReport!(reportReason);
            }
          },
        ),
      if (widget.onEdit != null && onEdit != null)
        ContextMenuItem(
          title: l(context).edit,
          onTap: () async {
            onEdit();
            Navigator.pop(context);
          },
        ),
      if (widget.onDelete != null)
        ContextMenuItem(
          title: l(context).delete,
          onTap: () async {
            // Don't show dialog if askBeforeDeleting is disabled
            if (!ac.profile.askBeforeDeleting) {
              widget.onDelete!();
              Navigator.pop(context);
              return;
            }

            showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text(l(context).deleteX(widget.contentTypeName)),
                actions: <Widget>[
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l(context).cancel),
                  ),
                  LoadingFilledButton(
                    onPressed: () async {
                      await widget.onDelete!();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    label: Text(l(context).delete),
                    uesHaptics: true,
                  ),
                ],
                actionsOverflowAlignment: OverflowBarAlignment.center,
                actionsOverflowButtonSpacing: 8,
                actionsOverflowDirection: VerticalDirection.up,
              ),
            );
          },
        ),
      if (widget.onUpdateFlairs != null)
        ContextMenuItem(
          title: l(context).editFlairs,
          onTap: () async {
            final community = await ac.api.community.get(widget.community!.id);
            if (!context.mounted) return;
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) => PostFlairsModal(
                flairs: widget.flairs,
                availableFlairs: community.flairs,
                onUpdate: (flairs) async {
                  final post = await ac.api.threads.assignFlairs(
                    widget.id,
                    flairs.map((flair) => flair.id).toList(),
                  );
                  if (!context.mounted) return;
                  widget.onUpdateFlairs!(post);
                },
              ),
            );
          },
        ),
      if (widget.body != null)
        ContextMenuItem(
          title: l(context).viewSource,
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l(context).viewSource),
              content: Card.outlined(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(widget.body!),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l(context).close),
                ),
                LoadingTonalButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.body!));

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  label: Text(l(context).copy),
                ),
              ],
            ),
          ),
        ),
      if (widget.body != null && onTranslate != null)
        ContextMenuItem(
          title: l(context).translate,
          onTap: () async {
            await onTranslate(ac.profile.defaultCreateLanguage);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          trailing: LoadingIconButton(
            onPressed: () async {
              final langCode = await languageSelectionMenu(context)
                  .askSelection(
                    context,
                    ac.selectedProfileValue.defaultCreateLanguage,
                  );

              if (langCode == null) return;
              await onTranslate(langCode);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            icon: Icon(Symbols.arrow_right_rounded),
          ),
        ),
      if (widget.user != null)
        ContextMenuItem(
          title: normalizeName(widget.user!.name, ac.instanceHost),
          subtitle: l(context).user,
          onTap: () async {
            Navigator.pop(context);
            showUserMenu(
              context,
              user: widget.user!,
              update: widget.updateUser,
              navigateOption: true,
            );
          },
          trailing: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Symbols.arrow_right_rounded),
          ),
        ),
      if (widget.community != null)
        ContextMenuItem(
          title: normalizeName(widget.community!.name, ac.instanceHost),
          subtitle: l(context).community,
          onTap: () async {
            Navigator.pop(context);
            showCommunityMenu(
              context,
              community: widget.community,
              navigateOption: true,
            );
          },
          trailing: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Symbols.arrow_right_rounded),
          ),
        ),
      if (widget.onModeratePin != null ||
          widget.onModerateMarkNSFW != null ||
          widget.onModerateDelete != null ||
          widget.onModerateBan != null)
        ContextMenuItem(
          title: l(context).moderate,
          // onTap: () async => showModerateMenu(context, widget),
          subItems: [
            if (widget.onModeratePin != null)
              ContextMenuItem(
                title: l(context).pin,
                onTap: () async {
                  widget.onModeratePin!();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            if (widget.onModerateMarkNSFW != null)
              ContextMenuItem(
                title: l(context).notSafeForWork_mark,
                onTap: () async {
                  widget.onModerateMarkNSFW!();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            if (widget.onModerateDelete != null)
              ContextMenuItem(
                title: l(context).delete,
                onTap: () async {
                  widget.onModerateDelete!();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            if (widget.onModerateBan != null)
              ContextMenuItem(
                title: l(context).banUser,
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  widget.onModerateBan!();
                },
              ),
          ],
        ),
    ],
  ).openMenu(context);
}

Future<void> showBookmarksMenu(BuildContext context, ContentItem widget) async {
  final possibleBookMarkLists = await widget.loadPossibleBookmarkLists!();
  if (!context.mounted) return;

  return ContextMenu(
    title: l(context).bookmark,
    items: [
      ...{...widget.activeBookmarkLists!, ...possibleBookMarkLists}.map(
        (listName) => widget.activeBookmarkLists!.contains(listName)
            ? ContextMenuItem(
                title: l(context).bookmark_removeFromX(listName),
                icon: Symbols.bookmark_rounded,
                iconFill: 1,
                onTap: () async {
                  widget.onRemoveBookmarkFromList!(listName);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              )
            : ContextMenuItem(
                title: l(context).bookmark_addToX(listName),
                icon: Symbols.bookmark_rounded,
                onTap: () async {
                  widget.onAddBookmarkToList!(listName);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
      ),
    ],
  ).openMenu(context);
}
