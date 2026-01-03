import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:interstellar/src/widgets/user_status_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ContentInfo extends StatelessWidget {
  const ContentInfo({
    super.key,
    this.user,
    this.isOp = false,
    this.community,
    this.showCommunityFirst = false,
    this.filterListWarnings,
    this.isPinned = false,
    this.isNSFW = false,
    this.isOC = false,
    this.lang,
    this.createdAt,
    this.editedAt,
    this.userTags = const [],
    this.menuWidget,
  });

  final DetailedUserModel? user;
  final bool isOp;
  final CommunityModel? community;
  final bool showCommunityFirst;

  final Set<String>? filterListWarnings;
  final bool isPinned;
  final bool isNSFW;
  final bool isOC;
  final String? lang;
  final DateTime? createdAt;
  final DateTime? editedAt;

  final List<Tag> userTags;

  final Widget? menuWidget;

  @override
  Widget build(BuildContext context) {
    final warning = filterListWarnings == null || filterListWarnings!.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: l(
                context,
              ).filterListWarningX(filterListWarnings!.join(', ')),
              triggerMode: TooltipTriggerMode.tap,
              child: const Icon(
                Symbols.warning_amber_rounded,
                color: Colors.red,
              ),
            ),
          );

    final pinned = !isPinned
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: l(context).pinnedInCommunity,
              triggerMode: TooltipTriggerMode.tap,
              child: const Icon(Symbols.push_pin_rounded, size: 20),
            ),
          );

    final nsfw = !isNSFW
        ? null
        : Padding(
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
          );

    final oc = !isOC
        ? null
        : Padding(
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
          );

    final langWidget =
        lang == null ||
            lang == context.read<AppController>().profile.defaultCreateLanguage
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: getLanguageName(context, lang!),
              triggerMode: TooltipTriggerMode.tap,
              child: Text(
                lang!,
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

    final created = createdAt == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message:
                  l(context).createdAt(dateTimeFormat(createdAt!)) +
                  (editedAt == null
                      ? ''
                      : '\n${l(context).editedAt(dateTimeFormat(editedAt!))}'),
              triggerMode: TooltipTriggerMode.tap,
              child: Text(
                dateDiffFormat(createdAt!),
                style: const TextStyle(fontWeight: FontWeight.w300),
              ),
            ),
          );

    final userWidget = user == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DisplayName(
                    user!.name,
                    displayName: user!.displayName,
                    icon: user!.avatar,
                    onTap: () => pushRoute(
                      context,
                      builder: (context) => UserScreen(user!.id),
                    ),
                  ),
                ),
                UserStatusIcons(cakeDay: user!.createdAt, isBot: user!.isBot),
                if (isOp)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
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
          );

    final communityWidget = community == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DisplayName(
              community!.name,
              icon: community!.icon,
              onTap: () => pushRoute(
                context,
                builder: (context) => CommunityScreen(community!.id),
              ),
            ),
          );

    // return Row(
    final internal = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              ?warning,
              ?pinned,
              ?nsfw,
              ?oc,
              ?langWidget,
              if (showCommunityFirst) ?communityWidget,
              if (!showCommunityFirst) ?userWidget,
              ?created,
              if (!showCommunityFirst) ?communityWidget,
              if (showCommunityFirst) ?userWidget,
            ],
          ),
        ),
        ?menuWidget,
      ],
    );

    if (userTags.isEmpty) {
      return internal;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        internal,
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: userTags.map((tag) => TagWidget(tag: tag)).toList(),
          ),
        ),
      ],
    );
  }
}
