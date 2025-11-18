import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/content_item/action_buttons.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/widgets/content_item/content_info.dart';
import 'package:interstellar/src/widgets/menus/content_menu.dart';
import 'package:interstellar/src/widgets/content_item/content_reply.dart';
import 'package:interstellar/src/widgets/content_item/swipe_item.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/video.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/widgets/content_item/content_item_link_panel.dart';
import 'package:simplytranslate/simplytranslate.dart';

enum PostComponent { title, image, info, body, link }

class ContentItem extends StatefulWidget {
  final String originInstance;

  final String? title;
  final ImageModel? image;
  final Uri? link;
  final String? body;
  final Translation? translation;
  final String? lang;
  final Future<void> Function(String lang)? onTranslate;
  final DateTime? createdAt;
  final DateTime? editedAt;

  final bool isPreview;
  final bool fullImageSize;
  final bool showCommunityFirst;
  final bool read;
  final bool feedView;

  final bool isPinned;
  final bool isNSFW;
  final bool isOC;

  final DetailedUserModel? user;
  final Future<void> Function(DetailedUserModel)? updateUser;
  final int? opUserId;

  final CommunityModel? community;

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
  final Future<void> Function(String body, String lang)? onReply;
  final Future<void> Function(String)? onReport;
  final Future<void> Function(String)? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onMarkAsRead;

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

  final void Function()? onClick;

  const ContentItem({
    required this.originInstance,
    this.title,
    this.image,
    this.link,
    this.body,
    this.translation,
    this.lang,
    this.onTranslate,
    this.createdAt,
    this.editedAt,
    this.isPreview = false,
    this.fullImageSize = false,
    this.showCommunityFirst = false,
    this.read = false,
    this.feedView = true,
    this.isPinned = false,
    this.isNSFW = false,
    this.isOC = false,
    this.user,
    this.opUserId,
    this.community,
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
    this.onMarkAsRead,
    this.updateUser,
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
    this.onClick,
    super.key,
  });

  @override
  State<ContentItem> createState() => _ContentItemState();
}

class _ContentItemState extends State<ContentItem> {
  bool _isReplying = false;
  TextEditingController? _editTextController;

  void _reply() {
    if (widget.onReply == null) return;

    if (context.read<AppController>().profile.inlineReplies) {
      setState(() {
        _isReplying = true;
      });
    } else {
      pushRoute(
        context,
        builder: (context) => ContentReply(
          inline: false,
          content: widget,
          onReply: widget.onReply!,
          onComplete: () => Navigator.pop(context),
          draftResourceId: widget.replyDraftResourceId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: widget.isCompact ? compact() : card());
  }

  Widget card() {
    final isCard =
        context.read<AppController>().profile.showPostsCards &&
            widget.feedView ||
        widget.contentTypeName == l(context).comment;

    return isCard
        ? Card(
            color: widget.read ? Theme.of(context).cardColor.darken(3) : null,
            margin: widget.contentTypeName == l(context).comment
                ? const EdgeInsets.symmetric(vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: post(),
          )
        : Material(
            color: widget.read
                ? Theme.of(context).cardColor.darken(3)
                : Colors.transparent,
            child: post(),
          );
  }

  Widget post() {
    final profile = context.read<AppController>().profile;

    final editDraftController = context.watch<DraftsController>().auto(
      widget.editDraftResourceId,
    );

    final isVideo =
        widget.link != null && isSupportedYouTubeVideo(widget.link!);

    final menuWidget = IconButton(
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
      icon: const Icon(Symbols.more_vert_rounded),
      onPressed: () {
        showContentMenu(
          context,
          widget,
          onEdit: () => setState(() {
            _editTextController = TextEditingController(text: widget.body);
          }),
          onTranslate: widget.onTranslate,
          onReply: _reply,
        );
      },
    );

    return Wrapper(
      shouldWrap: widget.onClick != null,
      parentBuilder: (child) {
        return InkWell(
          onTap: widget.onClick,
          onLongPress: () => showContentMenu(
            context,
            widget,
            onTranslate: widget.onTranslate,
            onReply: _reply,
          ),
          onSecondaryTap: () => showContentMenu(
            context,
            widget,
            onTranslate: widget.onTranslate,
            onReply: _reply,
          ),
          child: child,
        );
      },
      child: Wrapper(
        shouldWrap: profile.enableSwipeActions,
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
          onReply: _reply,
          onMarkAsRead: widget.onMarkAsRead,
          onModeratePin: widget.onModeratePin,
          onModerateMarkNSFW: widget.onModerateMarkNSFW,
          onModerateDelete: widget.onModerateDelete,
          onModerateBan: widget.onModerateBan,
          child: child,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isThumbnail =
                !isVideo &&
                (constraints.maxWidth > 800 ||
                    (widget.image?.blurHashWidth ?? 500) <= 800 &&
                        widget.link != null);
            final image = getImage(
              context,
              width: constraints.maxWidth,
              isThumbnail: isThumbnail,
            );
            final video = !widget.isPreview && isVideo
                ? VideoPlayer(
                    widget.link!,
                    enableBlur:
                        widget.isNSFW &&
                        context
                            .watch<AppController>()
                            .profile
                            .coverMediaMarkedSensitive,
                  )
                : null;

            List<Widget?> components = [];
            final order = widget.contentTypeName == l(context).comment
                ? ProfileRequired.defaultProfile.postComponentOrder
                : profile.postComponentOrder;

            for (final component in order) {
              components.add(switch (component) {
                PostComponent.title => contentTitle(context, menuWidget),
                PostComponent.image =>
                  video ?? (image == null || isThumbnail ? null : image),
                PostComponent.info => ContentInfo(
                  user: widget.user,
                  isOp: widget.opUserId == widget.user?.id,
                  community: widget.community,
                  showCommunityFirst: widget.showCommunityFirst,
                  isPinned: widget.isPinned,
                  isNSFW: widget.isNSFW,
                  isOC: widget.isOC,
                  lang: widget.lang,
                  createdAt: widget.createdAt,
                  editedAt: widget.editedAt,
                  menuWidget: widget.title == null ? menuWidget : null,
                ),
                PostComponent.body =>
                  (widget.body != null &&
                          widget.body!.isNotEmpty &&
                          !(widget.isPreview && profile.compactMode))
                      ? contentBody(context)
                      : null,
                PostComponent.link =>
                  widget.link == null
                      ? null
                      : ContentItemLinkPanel(link: widget.link!),
              });
            }

            // add bottom padding to all except last component
            components = components.nonNulls
                .mapIndexed(
                  (index, component) =>
                      index == (components.nonNulls.length - 1)
                      ? component
                      : Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: component,
                            )
                            as Widget?,
                )
                .toList();

            if (widget.onReply != null && _isReplying) {
              components.add(
                ContentReply(
                  content: widget,
                  onReply: widget.onReply!,
                  onComplete: () => setState(() {
                    _isReplying = false;
                  }),
                  draftResourceId: widget.replyDraftResourceId,
                ),
              );
            }

            if (widget.onEdit != null && _editTextController != null) {
              components.add(
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
                            child: Text(l(context).cancel),
                          ),
                          const SizedBox(width: 8),
                          LoadingFilledButton(
                            onPressed: () async {
                              await widget.onEdit!(_editTextController!.text);

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
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: widget.contentTypeName == l(context).comment
                  ? const EdgeInsets.fromLTRB(12, 0, 12, 8)
                  : const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!(isThumbnail && image != null)) ...components.nonNulls,
                  if (isThumbnail && image != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: components.nonNulls.toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: image,
                        ),
                      ],
                    ),
                  if (!profile.hideActionButtons)
                    ActionButtons(
                      upVotes: widget.upVotes,
                      downVotes: widget.downVotes,
                      boosts: widget.boosts,
                      numComments: widget.numComments,
                      activeBookmarkLists: widget.activeBookmarkLists,
                      isUpvoted: widget.isUpVoted,
                      isDownvoted: widget.isDownVoted,
                      isBoosted: widget.isBoosted,
                      onUpVote: widget.onUpVote,
                      onDownVote: widget.onDownVote,
                      onBoost: widget.onBoost,
                      onReply: widget.onReply == null ? null : _reply,
                      onAddBookmark: widget.onAddBookmark,
                      onRemoveBookmark: widget.onRemoveBookmark,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget? contentTitle(BuildContext context, Widget? menuWidget) {
    if (widget.title == null) return null;
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: widget.read ? FontWeight.w100 : null,
              // letterSpacing: 0,
              height: 0
            ),
            overflow:
                widget.isPreview &&
                    context.watch<AppController>().profile.compactMode
                ? TextOverflow.ellipsis
                : null,
          ),
        ),
        ?menuWidget,
      ],
    );
  }

  Widget contentBody(BuildContext context) {
    final isNSFW =
        widget.isNSFW &&
        context.read<AppController>().profile.coverMediaMarkedSensitive;

    return widget.translation != null
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
                        Text(widget.translation!.targetLanguage.name),
                      ],
                    ),
                    Divider(),
                    Text(
                      widget.translation!.translations.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Markdown(widget.body!, widget.originInstance, nsfw: isNSFW),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(getLanguageName(context, widget.lang!)),
                        Icon(Symbols.arrow_right),
                        Text(widget.translation!.targetLanguage.name),
                      ],
                    ),
                    Divider(),
                    Markdown(
                      widget.translation!.translations.text,
                      widget.originInstance,
                      nsfw: isNSFW,
                    ),
                  ],
                )
        // No translation is available
        : widget.isPreview
        ? Text(widget.body!, maxLines: 4, overflow: TextOverflow.ellipsis)
        : Markdown(widget.body!, widget.originInstance, nsfw: isNSFW);
  }

  Widget? getImage(
    BuildContext context, {
    double width = 800,
    bool isThumbnail = false,
    bool compact = false,
  }) {
    if (widget.image == null) return null;
    final fullImage = !isThumbnail && widget.fullImageSize;
    final double imageSize = compact
        ? 96
        : width > 800
        ? 128
        : 64;
    final imageOpenTitle = widget.title ?? widget.body ?? '';

    final enableBlur =
        widget.isNSFW &&
        context.watch<AppController>().profile.coverMediaMarkedSensitive;

    final image = AdvancedImage(
      widget.image!,
      openTitle: imageOpenTitle,
      fit: widget.fullImageSize ? BoxFit.scaleDown : BoxFit.fitWidth,
      enableBlur: enableBlur,
      hero: AdvancedImage.getHeroTag(),
    );

    if (fullImage) {
      return image;
    } else if (isThumbnail) {
      return SizedBox(height: imageSize, width: imageSize, child: image);
    } else {
      return SizedBox(height: 160, width: double.infinity, child: image);
    }
  }

  Widget compact() {
    // TODO: Figure out how to use full existing height of row, instead of fixed value.
    final imageWidget = getImage(context, isThumbnail: true, compact: true);

    return Column(
      children: [
        Material(
          color: widget.read
              ? Theme.of(context).cardColor.darken(3)
              : Colors.transparent,
          child: Wrapper(
            shouldWrap: widget.onClick != null,
            parentBuilder: (child) {
              return InkWell(
                onTap: widget.onClick,
                onLongPress: () => showContentMenu(
                  context,
                  widget,
                  onTranslate: widget.onTranslate,
                  onReply: _reply,
                ),
                onSecondaryTap: () => showContentMenu(
                  context,
                  widget,
                  onTranslate: widget.onTranslate,
                  onReply: _reply,
                ),
                child: child,
              );
            },
            child: Wrapper(
              shouldWrap: context
                  .watch<AppController>()
                  .profile
                  .enableSwipeActions,
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
                onReply: _reply,
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
                          ?contentTitle(context, null),
                          const SizedBox(height: 4),
                          ContentInfo(
                            user: widget.user,
                            isOp: widget.opUserId == widget.user?.id,
                            community: widget.community,
                            showCommunityFirst: widget.showCommunityFirst,
                            isPinned: widget.isPinned,
                            isNSFW: widget.isNSFW,
                            isOC: widget.isOC,
                            lang: widget.lang,
                            createdAt: widget.createdAt,
                            editedAt: widget.editedAt,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                l(context).pointsX(
                                  (widget.upVotes ?? 0) -
                                      (widget.downVotes ?? 0),
                                ),
                              ),
                              const Text(' · '),
                              Text(
                                l(context).commentsX(widget.numComments ?? 0),
                              ),
                            ],
                          ),
                          if (widget.onReply != null && _isReplying)
                            ContentReply(
                              content: widget,
                              onReply: widget.onReply!,
                              onComplete: () => setState(() {
                                _isReplying = false;
                              }),
                              draftResourceId: widget.replyDraftResourceId,
                            ),
                        ],
                      ),
                    ),
                  ),
                  ?imageWidget,
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}
