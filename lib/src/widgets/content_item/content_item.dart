import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/content_item/content_menu.dart';
import 'package:interstellar/src/widgets/content_item/swipe_item.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:interstellar/src/widgets/video.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:interstellar/src/widgets/content_item/content_item_link_panel.dart';
import 'package:simplytranslate/simplytranslate.dart';

class ContentItem extends StatefulWidget {
  final String originInstance;

  final String? title;
  final ImageModel? image;
  final Uri? link;
  final String? body;
  final String? lang;
  final DateTime? createdAt;
  final DateTime? editedAt;

  final bool isPreview;
  final bool fullImageSize;
  final bool showMagazineFirst;

  final bool isPinned;
  final bool isNSFW;
  final bool isOC;

  final String? user;
  final ImageModel? userIcon;
  final int? userIdOnClick;
  final DateTime? userCakeDay;
  final bool userIsBot;
  final int? opUserId;

  final String? magazine;
  final ImageModel? magazineIcon;
  final int? magazineIdOnClick;

  final String? domain;
  final int? domainIdOnClick;

  final int? boosts;
  final bool isBoosted;
  final void Function()? onBoost;

  final int? upVotes;
  final bool isUpVoted;
  final void Function()? onUpVote;

  final int? downVotes;
  final bool isDownVoted;
  final void Function()? onDownVote;

  final String contentTypeName;
  final Uri? openLinkUri;
  final int? numComments;
  final Future<void> Function(String)? onReply;
  final Future<void> Function(String)? onReport;
  final Future<void> Function(String)? onEdit;
  final Future<void> Function()? onDelete;

  final Future<void> Function()? onModeratePin;
  final Future<void> Function()? onModerateMarkNSFW;
  final Future<void> Function()? onModerateDelete;
  final Future<void> Function()? onModerateBan;

  final String editDraftResourceId;
  final String replyDraftResourceId;

  final Set<String>? filterListWarnings;

  final List<String>? activeBookmarkLists;
  final Future<List<String>> Function()? loadPossibleBookmarkLists;
  final Future<void> Function()? onAddBookmark;
  final Future<void> Function(String)? onAddBookmarkToList;
  final Future<void> Function()? onRemoveBookmark;
  final Future<void> Function(String)? onRemoveBookmarkFromList;

  final NotificationControlStatus? notificationControlStatus;
  final Future<void> Function(NotificationControlStatus)?
      onNotificationControlStatusChange;
  final bool isCompact;

  const ContentItem({
    required this.originInstance,
    this.title,
    this.image,
    this.link,
    this.body,
    this.lang,
    this.createdAt,
    this.editedAt,
    this.isPreview = false,
    this.fullImageSize = false,
    this.showMagazineFirst = false,
    this.isPinned = false,
    this.isNSFW = false,
    this.isOC = false,
    this.user,
    this.userIcon,
    this.userIdOnClick,
    this.userCakeDay,
    this.userIsBot = false,
    this.opUserId,
    this.magazine,
    this.magazineIcon,
    this.magazineIdOnClick,
    this.domain,
    this.domainIdOnClick,
    this.boosts,
    this.isBoosted = false,
    this.onBoost,
    this.upVotes,
    this.isUpVoted = false,
    this.onUpVote,
    this.downVotes,
    this.isDownVoted = false,
    this.onDownVote,
    this.openLinkUri,
    this.numComments,
    required this.contentTypeName,
    this.onReply,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.onModeratePin,
    this.onModerateMarkNSFW,
    this.onModerateDelete,
    this.onModerateBan,
    required this.editDraftResourceId,
    required this.replyDraftResourceId,
    this.filterListWarnings,
    this.activeBookmarkLists,
    this.loadPossibleBookmarkLists,
    this.onAddBookmark,
    this.onAddBookmarkToList,
    this.onRemoveBookmark,
    this.onRemoveBookmarkFromList,
    this.notificationControlStatus,
    this.onNotificationControlStatusChange,
    this.isCompact = false,
    super.key,
  });

  @override
  State<ContentItem> createState() => _ContentItemState();
}

class _ContentItemState extends State<ContentItem> {
  TextEditingController? _replyTextController;
  TextEditingController? _editTextController;
  Translation? _translation;

  @override
  void initState() {
    super.initState();
    getTranslation();
  }

  void getTranslation() async {
    if (context.read<AppController>().profile.autoTranslate &&
        widget.lang != context.read<AppController>().profile.defaultPostLanguage &&
        widget.body != null && widget.lang != null) {
      try {
        final translation = await context
            .read<AppController>()
            .translator
            .translateSimply(widget.body!, to: context
            .read<AppController>()
            .profile
            .defaultPostLanguage);
        if (!mounted) return;
        setState(() {
          _translation = translation;
        });
      } catch (e) {
        // ignore translation errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCompact ? compact() : full();
  }

  Widget contentBody(BuildContext context) {
    return _translation != null
        // A translation is available
        ? widget.isPreview
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.body!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(getLanguageName(context, widget.lang!)),
                      Icon(Symbols.arrow_right),
                      Text(_translation!.targetLanguage.name),
                    ],
                  ),
                  Divider(),
                  Text(
                    _translation!.translations.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Markdown(widget.body!, widget.originInstance),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(getLanguageName(context, widget.lang!)),
                      Icon(Symbols.arrow_right),
                      Text(_translation!.targetLanguage.name),
                    ],
                  ),
                  Divider(),
                  Markdown(
                      _translation!.translations.text, widget.originInstance),
                ],
              )
        // No translation is available
        : widget.isPreview
            ? Text(
                widget.body!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              )
            : Markdown(widget.body!, widget.originInstance);
  }

  Widget full() {
    final isVideo =
        widget.link != null && isSupportedYouTubeVideo(widget.link!);

    final Widget? userWidget = widget.user != null
        ? Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: DisplayName(
                      widget.user!,
                      icon: widget.userIcon,
                      onTap: widget.userIdOnClick != null
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => UserScreen(
                                    widget.userIdOnClick!,
                                  ),
                                ),
                              )
                          : null,
                    ),
                  ),
                  UserStatusIcons(
                    cakeDay: widget.userCakeDay,
                    isBot: widget.userIsBot,
                  ),
                  if (widget.opUserId == widget.userIdOnClick)
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Tooltip(
                        message: l(context).originalPoster_long,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Text(
                          l(context).originalPoster_short,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        : null;
    final Widget? magazineWidget = widget.magazine != null
        ? Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: DisplayName(
                widget.magazine!,
                icon: widget.magazineIcon,
                onTap: widget.magazineIdOnClick != null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MagazineScreen(
                              widget.magazineIdOnClick!,
                            ),
                          ),
                        )
                    : null,
              ),
            ),
          )
        : null;

    final editDraftController =
        context.watch<DraftsController>().auto(widget.editDraftResourceId);
    final replyDraftController =
        context.watch<DraftsController>().auto(widget.replyDraftResourceId);

    return LayoutBuilder(builder: (context, constrains) {
      final hasWideSize = constrains.maxWidth > 800;
      final isRightImage = hasWideSize;

      final double rightImageSize = hasWideSize ? 128 : 64;

      final imageOpenTitle = widget.title ?? widget.body ?? '';

      final imageWidget = widget.image == null
          ? null
          : isRightImage
              ? SizedBox(
                  height: rightImageSize,
                  width: rightImageSize,
                  child: AdvancedImage(
                    widget.image!,
                    fit: BoxFit.cover,
                    openTitle: imageOpenTitle,
                    enableBlur: widget.isNSFW &&
                        context
                            .watch<AppController>()
                            .profile
                            .coverMediaMarkedSensitive,
                  ),
                )
              : (!widget.fullImageSize
                  ? SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: AdvancedImage(
                        widget.image!,
                        fit: BoxFit.cover,
                        openTitle: imageOpenTitle,
                        enableBlur: widget.isNSFW,
                      ),
                    )
                  : AdvancedImage(
                      widget.image!,
                      openTitle: imageOpenTitle,
                      fit: BoxFit.scaleDown,
                      enableBlur: widget.isNSFW,
                    ));

      final titleStyle = hasWideSize
          ? Theme.of(context).textTheme.titleLarge!
          : Theme.of(context).textTheme.titleMedium!;
      final titleOverflow =
          widget.isPreview && context.watch<AppController>().profile.compactMode
              ? TextOverflow.ellipsis
              : null;

      final menuWidget = IconButton(
        icon: const Icon(Symbols.more_vert_rounded),
        onPressed: () {
          showContentMenu(
              context,
              widget,
              onEdit: () => setState(() {
                _editTextController = TextEditingController(text: widget.body);
              })
          );
        },
      );

      return Wrapper(
          shouldWrap: context.watch<AppController>().profile.enableSwipeActions,
          parentBuilder: (child) => SwipeItem(
                onUpVote: widget.onUpVote,
                onDownVote: widget.onDownVote,
                onBoost: widget.onBoost,
                onBookmark: () async {
                  if (widget.activeBookmarkLists != null &&
                      widget.onAddBookmark != null &&
                      widget.onRemoveBookmark != null) {
                    widget.activeBookmarkLists!.isEmpty
                        ? widget.onAddBookmark!()
                        : widget.onRemoveBookmark!();
                  }
                },
                onReply: widget.onReply != null
                    ? () => setState(() {
                          _replyTextController = TextEditingController();
                        })
                    : () {},
                onModeratePin: widget.onModeratePin,
                onModerateMarkNSFW: widget.onModerateMarkNSFW,
                onModerateDelete: widget.onModerateDelete,
                onModerateBan: widget.onModerateBan,
                child: child,
              ),
          child: Column(
            children: <Widget>[
              if ((!isRightImage && imageWidget != null) ||
                  (!widget.isPreview && isVideo))
                Wrapper(
                  shouldWrap: widget.fullImageSize,
                  parentBuilder: (child) => Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 2,
                      ),
                      child: child),
                  child: (!widget.isPreview && isVideo)
                      ? VideoPlayer(widget.link!)
                      : imageWidget!,
                ),
              Container(
                padding: widget.title != null
                    ? const EdgeInsets.all(12)
                    : const EdgeInsets.fromLTRB(12, 0, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (widget.title != null)
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      widget.title!,
                                      style: titleStyle,
                                      overflow: titleOverflow,
                                    ),
                                  ),
                                ),
                                menuWidget,
                              ],
                            ),
                          if (widget.link != null)
                            ContentItemLinkPanel(link: widget.link!),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (widget.filterListWarnings?.isNotEmpty ==
                                        true)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Tooltip(
                                          message: l(context)
                                              .filterListWarningX(widget
                                                  .filterListWarnings!
                                                  .join(', ')),
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: const Icon(
                                            Symbols.warning_amber_rounded,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    if (widget.isPinned)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Tooltip(
                                          message: l(context).pinnedInMagazine,
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: const Icon(
                                              Symbols.push_pin_rounded,
                                              size: 20),
                                        ),
                                      ),
                                    if (widget.isNSFW)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Tooltip(
                                          message:
                                              l(context).notSafeForWork_long,
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: Text(
                                            l(context).notSafeForWork_short,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (widget.isOC)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Tooltip(
                                          message:
                                              l(context).originalContent_long,
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: Text(
                                            l(context).originalContent_short,
                                            style: const TextStyle(
                                              color: Colors.lightGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!widget.showMagazineFirst &&
                                        userWidget != null)
                                      userWidget,
                                    if (widget.showMagazineFirst &&
                                        magazineWidget != null)
                                      magazineWidget,
                                    if (widget.createdAt != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Tooltip(
                                          message: l(context).createdAt(
                                                  dateTimeFormat(
                                                      widget.createdAt!)) +
                                              (widget.editedAt == null
                                                  ? ''
                                                  : '\n${l(context).editedAt(dateTimeFormat(widget.editedAt!))}'),
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: Text(
                                            dateDiffFormat(widget.createdAt!),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ),
                                      ),
                                    if (widget.showMagazineFirst &&
                                        userWidget != null)
                                      userWidget,
                                    if (!widget.showMagazineFirst &&
                                        magazineWidget != null)
                                      magazineWidget,
                                  ],
                                ),
                              ),
                              if (widget.title == null) menuWidget,
                            ],
                          ),
                          // The menu button on the info row provides padding; add this padding when the menu button is not present
                          if (widget.title != null) SizedBox(height: 10),
                          if (widget.body != null &&
                              widget.body!.isNotEmpty &&
                              !(widget.isPreview &&
                                  context
                                      .watch<AppController>()
                                      .profile
                                      .compactMode))
                            contentBody(context),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child:
                                LayoutBuilder(builder: (context, constrains) {
                              final votingWidgets = [
                                if (widget.activeBookmarkLists != null)
                                  widget.activeBookmarkLists!.isEmpty
                                      ? LoadingIconButton(
                                          onPressed: widget.onAddBookmark,
                                          icon: const Icon(
                                            Symbols.bookmark_rounded,
                                            fill: 0,
                                          ),
                                        )
                                      : LoadingIconButton(
                                          onPressed: widget.onRemoveBookmark,
                                          icon: const Icon(
                                            Symbols.bookmark_rounded,
                                            fill: 1,
                                          ),
                                        ),
                                if (widget.boosts != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Symbols.rocket_launch_rounded),
                                          color: widget.isBoosted
                                              ? Colors.purple.shade400
                                              : null,
                                          onPressed: widget.onBoost,
                                        ),
                                        Text(intFormat(widget.boosts!))
                                      ],
                                    ),
                                  ),
                                if (widget.upVotes != null ||
                                    widget.downVotes != null)
                                  Row(
                                    children: [
                                      if (widget.upVotes != null)
                                        IconButton(
                                          icon: const Icon(
                                              Symbols.arrow_upward_rounded),
                                          color: widget.isUpVoted
                                              ? Colors.green.shade400
                                              : null,
                                          onPressed: widget.onUpVote,
                                        ),
                                      Text(intFormat((widget.upVotes ?? 0) -
                                          (widget.downVotes ?? 0))),
                                      if (widget.downVotes != null)
                                        IconButton(
                                          icon: const Icon(
                                              Symbols.arrow_downward_rounded),
                                          color: widget.isDownVoted
                                              ? Colors.red.shade400
                                              : null,
                                          onPressed: widget.onDownVote,
                                        ),
                                    ],
                                  ),
                              ];
                              final commentWidgets = [
                                if (widget.numComments != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Symbols.comment_rounded),
                                        const SizedBox(width: 4),
                                        Text(intFormat(widget.numComments!))
                                      ],
                                    ),
                                  ),
                                if (widget.onReply != null)
                                  IconButton(
                                    icon: const Icon(Symbols.reply_rounded),
                                    onPressed: () => setState(() {
                                      _replyTextController =
                                          TextEditingController();
                                    }),
                                  ),
                              ];

                              return constrains.maxWidth < 300
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: votingWidgets,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: <Widget>[
                                            ...commentWidgets,
                                            const Spacer(),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: <Widget>[
                                        ...commentWidgets,
                                        const Spacer(),
                                        ...votingWidgets,
                                      ],
                                    );
                            }),
                          ),
                          if (!widget.isPreview &&
                              widget.notificationControlStatus != null &&
                              widget.onNotificationControlStatusChange != null &&
                              context.read<AppController>().serverSoftware !=
                                  ServerSoftware.piefed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  NotificationControlSegment(
                                    widget.notificationControlStatus!,
                                    widget.onNotificationControlStatusChange!,
                                  )
                                ],
                              ),
                            ),
                          if (widget.onReply != null &&
                              _replyTextController != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  MarkdownEditor(
                                    _replyTextController!,
                                    originInstance: null,
                                    draftController: replyDraftController,
                                    autoFocus: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                          onPressed: () => setState(() {
                                                _replyTextController!.dispose();
                                                _replyTextController = null;
                                              }),
                                          child: Text(l(context).cancel)),
                                      const SizedBox(width: 8),
                                      LoadingFilledButton(
                                        onPressed: () async {
                                          await widget.onReply!(
                                              _replyTextController!.text);

                                          await replyDraftController.discard();

                                          setState(() {
                                            _replyTextController!.dispose();
                                            _replyTextController = null;
                                          });
                                        },
                                        label: Text(l(context).submit),
                                        uesHaptics: true,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          if (widget.onEdit != null &&
                              _editTextController != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  MarkdownEditor(
                                    _editTextController!,
                                    originInstance: null,
                                    draftController: editDraftController,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                          onPressed: () => setState(() {
                                                _editTextController!.dispose();
                                                _editTextController = null;
                                              }),
                                          child: Text(l(context).cancel)),
                                      const SizedBox(width: 8),
                                      LoadingFilledButton(
                                        onPressed: () async {
                                          await widget.onEdit!(
                                              _editTextController!.text);

                                          await editDraftController.discard();

                                          setState(() {
                                            _editTextController!.dispose();
                                            _editTextController = null;
                                          });
                                        },
                                        label: Text(l(context).submit),
                                        uesHaptics: true,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isRightImage && imageWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageWidget,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ));
    });
  }

  Widget compact() {
    // TODO: Figure out how to use full existing height of row, instead of fixed value.
    final imageWidget = widget.image == null
        ? null
        : SizedBox(
      height: 96,
      width: 96,
      child: AdvancedImage(
        widget.image!,
        fit: BoxFit.cover,
        openTitle: widget.title,
        enableBlur: widget.isNSFW &&
            context
                .watch<AppController>()
                .profile
                .coverMediaMarkedSensitive,
      ),
    );

    final Widget? userWidget = widget.user != null
        ? Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: DisplayName(
                widget.user!,
                onTap: widget.userIdOnClick != null
                    ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserScreen(
                      widget.userIdOnClick!,
                    ),
                  ),
                )
                    : null,
              ),
            ),
            UserStatusIcons(
              cakeDay: widget.userCakeDay,
              isBot: widget.userIsBot,
            ),
          ],
        ),
      ),
    )
        : null;
    final Widget? magazineWidget = widget.magazine != null
        ? Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: DisplayName(
          widget.magazine!,
          onTap: widget.magazineIdOnClick != null
              ? () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MagazineScreen(
                widget.magazineIdOnClick!,
              ),
            ),
          )
              : null,
        ),
      ),
    )
        : null;

    final replyDraftController =
    context.watch<DraftsController>().auto(widget.replyDraftResourceId);

    return Wrapper(
      shouldWrap: context.watch<AppController>().profile.enableSwipeActions,
      parentBuilder: (child) => SwipeItem(
        onUpVote: widget.onUpVote,
        onDownVote: widget.onDownVote,
        onBoost: widget.onBoost,
        onBookmark: () async {
          if (widget.activeBookmarkLists != null &&
              widget.onAddBookmark != null &&
              widget.onRemoveBookmark != null) {
            widget.activeBookmarkLists!.isEmpty
                ? widget.onAddBookmark!()
                : widget.onRemoveBookmark!();
          }
        },
        onReply: widget.onReply != null
            ? () => setState(() {
          _replyTextController = TextEditingController();
        })
            : () {},
        onModeratePin: widget.onModeratePin,
        onModerateMarkNSFW: widget.onModerateMarkNSFW,
        onModerateDelete: widget.onModerateDelete,
        onModerateBan: widget.onModerateBan,
        child: child,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (widget.filterListWarnings?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Tooltip(
                            message: l(context).filterListWarningX(
                                widget.filterListWarnings!.join(', ')),
                            triggerMode: TooltipTriggerMode.tap,
                            child: const Icon(
                              Symbols.warning_amber_rounded,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      if (widget.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Tooltip(
                            message: l(context).pinnedInMagazine,
                            triggerMode: TooltipTriggerMode.tap,
                            child: const Icon(Symbols.push_pin_rounded,
                                size: 20),
                          ),
                        ),
                      if (widget.isNSFW)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Tooltip(
                            message: l(context).notSafeForWork_long,
                            triggerMode: TooltipTriggerMode.tap,
                            child: Text(
                              l(context).notSafeForWork_short,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (widget.isOC)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Tooltip(
                            message: l(context).originalContent_long,
                            triggerMode: TooltipTriggerMode.tap,
                            child: Text(
                              l(context).originalContent_short,
                              style: const TextStyle(
                                color: Colors.lightGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (!widget.showMagazineFirst && userWidget != null)
                        userWidget,
                      if (widget.showMagazineFirst && magazineWidget != null)
                        magazineWidget,
                      if (widget.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Tooltip(
                            message: l(context).createdAt(
                                dateTimeFormat(widget.createdAt!)) +
                                (widget.editedAt == null
                                    ? ''
                                    : '\n${l(context).editedAt(dateTimeFormat(widget.editedAt!))}'),
                            triggerMode: TooltipTriggerMode.tap,
                            child: Text(
                              dateDiffFormat(widget.createdAt!),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                      if (widget.showMagazineFirst && userWidget != null)
                        userWidget,
                      if (!widget.showMagazineFirst && magazineWidget != null)
                        magazineWidget,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(l(context).pointsX(
                          (widget.upVotes ?? 0) - (widget.downVotes ?? 0))),
                      const Text(' · '),
                      Text(l(context).commentsX(widget.numComments ?? 0)),
                    ],
                  ),
                  if (widget.onReply != null && _replyTextController != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          MarkdownEditor(
                            _replyTextController!,
                            originInstance: null,
                            draftController: replyDraftController,
                            autoFocus: true,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                  onPressed: () => setState(() {
                                    _replyTextController!.dispose();
                                    _replyTextController = null;
                                  }),
                                  child: Text(l(context).cancel)),
                              const SizedBox(width: 8),
                              LoadingFilledButton(
                                onPressed: () async {
                                  await widget
                                      .onReply!(_replyTextController!.text);

                                  await replyDraftController.discard();

                                  setState(() {
                                    _replyTextController!.dispose();
                                    _replyTextController = null;
                                  });
                                },
                                label: Text(l(context).submit),
                                uesHaptics: true,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (imageWidget != null) imageWidget,
        ],
      )
    );
  }
}
