import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/explore/domain_screen.dart';
import 'package:interstellar/src/utils/share.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/report_content.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:interstellar/src/widgets/context_menu.dart';

void showContentMenu(
  BuildContext context,
  ContentItem widget, {
  Function()? onEdit,
  Function(String lang)? onTranslate,
  Function()? onReply,
}) {
  final ac = context.read<AppController>();

  ContextMenu(
    actionSpacing: 50,
    actions: [
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
      ContextMenuAction(
        child: NotificationControlSegment(
          widget.notificationControlStatus!,
          widget.onNotificationControlStatusChange!,
        ),
      ),
    ],
    items: [
      ContextMenuItem(
        title: l(context).openInBrowser,
        onTap: () async => openWebpagePrimary(context, widget.openLinkUri!),
      ),
      ContextMenuItem(
        title: l(context).share,
        onTap: () => shareUri(widget.openLinkUri!),
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
          trailing: const Icon(Symbols.arrow_right_rounded),
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
          title: 'Translate',
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
      if (widget.onModeratePin != null ||
          widget.onModerateMarkNSFW != null ||
          widget.onModerateDelete != null ||
          widget.onModerateBan != null)
        ContextMenuItem(
          title: l(context).moderate,
          // onTap: () async => showModerateMenu(context, widget),
          subItems: [
            ContextMenuItem(
              title: l(context).pin,
              onTap: () async {
                widget.onModeratePin!();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ContextMenuItem(
              title: l(context).notSafeForWork_mark,
              onTap: () async {
                widget.onModerateMarkNSFW!();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ContextMenuItem(
              title: l(context).delete,
              onTap: () async {
                widget.onModerateDelete!();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
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

void showBookmarksMenu(BuildContext context, ContentItem widget) async {
  final possibleBookMarkLists = await widget.loadPossibleBookmarkLists!();
  if (!context.mounted) return;

  ContextMenu(
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
