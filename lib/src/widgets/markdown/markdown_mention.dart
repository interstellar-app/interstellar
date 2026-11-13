import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

class MentionMarkdownSyntax extends md.InlineSyntax {
  new() : super(_mentionPattern);

  /*
    Should match the following patterns:

    https://kbin.social/m/interstellar@kbin.earth
    kbin.social/m/interstellar@kbin.earth
    https://kbin.earth/m/interstellar
    kbin.earth/m/interstellar
    /m/interstellar@kbin.earth
    /m/interstellar
    !interstellar@kbin.earth
    !interstellar
    https://lemmy.world/c/fediverse
    lemmy.world/c/fediverse
    /c/fediverse

    https://kbin.social/u/@jwr1@kbin.earth
    kbin.social/u/@jwr1@kbin.earth
    https://kbin.earth/u/jwr1
    kbin.earth/u/jwr1
    /u/@jwr1@kbin.earth
    /u/jwr1
    @jwr1@kbin.earth
    @jwr1

    There cannot be an additional ! symbol, an additional @ symbol, or a word
    character preceding the match.
  */
  static const String _mentionPattern =
      r'(?<![!@\w])(?:(?:(?:https?:\/\/)?([a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}))?\/([umc])\/@?|(@|!))([a-zA-Z0-9_]+)(?:@([a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}))?';

  /*
    Should match the following patterns:

    [link name](MENTION)
    [link name](MENTION "link title")
  */
  static const String _mdLinkPattern =
      r'\[.*?\]\(\s*' + _mentionPattern + r'(?:\s*".*?")?\s*\)';
  static final _mdLinkPatternRegExp = RegExp(_mdLinkPattern, multiLine: true);

  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    startMatchPos ??= parser.pos;

    final isMarkdownLink =
        String.fromCharCode(parser.charAt(parser.pos)) == '[';

    final match = (isMarkdownLink ? _mdLinkPatternRegExp : pattern)
        .matchAsPrefix(parser.source, startMatchPos);
    if (match == null) return false;

    // Write any existing plain text up to this point.
    parser.writeText();

    if (onMatch(parser, match)) parser.consume(match[0]!.length);
    return true;
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final urlDomain = match.group(1);
    final urlModifier = match.group(2);
    final modifier = match.group(3) ?? (urlModifier == 'u' ? '@' : '!');
    final name = match.group(4)!;
    final host = match.group(5) ?? urlDomain;

    final result = '$modifier$name${host != null ? '@$host' : ''}';

    final node = md.Element.text('mention', result);

    parser.addNode(node);

    return true;
  }
}

class MentionMarkdownBuilder extends mdf.MarkdownElementBuilder {
  new({required this.originInstance});

  final String originInstance;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: MentionWidget(element.textContent, originInstance),
          ),
        ],
      ),
    );
  }
}

class MentionWidget extends StatefulWidget {
  const new(this.name, this.originInstance, {super.key});

  final String name;
  final String originInstance;

  @override
  State<MentionWidget> createState() => MentionWidgetState();
}

Map<String, DetailedUserModel?> userMentionCache = {};
Map<String, DetailedCommunityModel?> communityMentionCache = {};

class MentionWidgetState extends State<MentionWidget> {
  late String _displayName;
  ImageModel? _icon;
  void Function()? _onClick;

  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  Future<void> _fetchData() async {
    final modifier = widget.name[0];
    final split = widget.name.substring(1).split('@');
    final name = split[0];
    final host = (split.length > 1) ? split[1] : widget.originInstance;
    final cacheKey = host == context.read<AppController>().instanceHost
        ? name
        : '$name@$host';

    setState(() {
      _displayName = modifier + name;
    });

    if (modifier == '@') {
      if (!userMentionCache.containsKey(cacheKey)) {
        try {
          userMentionCache[cacheKey] = await context
              .read<AppController>()
              .api
              .users
              .getByName(
                host == context.read<AppController>().instanceHost
                    ? name
                    : '$name@$host',
              );
        } catch (_) {
          // User not found
          userMentionCache[cacheKey] = null;
        }
      }

      final user = userMentionCache[cacheKey];

      if (user != null) {
        setState(() {
          _icon = user.avatar;
          _onClick = () => context.router.push(
            UserRoute(username: user.name, userId: user.id, initData: user),
          );
        });
      }
    } else if (modifier == '!') {
      if (!communityMentionCache.containsKey(cacheKey)) {
        try {
          communityMentionCache[cacheKey] = await context
              .read<AppController>()
              .api
              .community
              .getByName(
                host == context.read<AppController>().instanceHost
                    ? name
                    : '$name@$host',
              );
        } catch (_) {
          // Community not found
          communityMentionCache[cacheKey] = null;
        }
      }

      final community = communityMentionCache[cacheKey];

      if (community != null) {
        setState(() {
          _icon = community.icon;
          _onClick = () => context.router.push(
            CommunityRoute(
              communityName: community.name,
              communityId: community.id,
              initData: community,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(_displayName),
      avatar: _icon != null ? Avatar(_icon) : null,
      onPressed: _onClick,
      visualDensity: const VisualDensity(
        vertical: VisualDensity.minimumDensity,
      ),
    );
  }
}
