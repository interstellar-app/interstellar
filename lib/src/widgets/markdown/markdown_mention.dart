import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

class MentionMarkdownSyntax extends md.InlineSyntax {
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
  */
  static const String _mentionPattern =
      r'(?:(?:(?:https?:\/\/)?([a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}))?\/([umc])\/@?|(@|!))([a-zA-Z0-9_]+)(?:@([a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}))?';

  /*
    Should match the following patterns:

    [link name](MENTION)
    [link name](MENTION "link title")
  */
  static const String _mdLinkPattern =
      r'\[.*?\]\(\s*' + _mentionPattern + r'(?:\s*".*?")?\s*\)';
  static final _mdLinkPatternRegExp = RegExp(
    _mdLinkPattern,
    multiLine: true,
    caseSensitive: true,
  );

  static final _borderRegExp = RegExp(r'[^a-z0-9@/\\]', caseSensitive: false);

  MentionMarkdownSyntax() : super(_mentionPattern);

  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    startMatchPos ??= parser.pos;

    final isMarkdownLink =
        String.fromCharCode(parser.charAt(parser.pos)) == '[';

    if (parser.pos > 0 && !isMarkdownLink) {
      final precededBy = String.fromCharCode(parser.charAt(parser.pos - 1));
      if (_borderRegExp.matchAsPrefix(precededBy) == null) {
        return false;
      }
    }

    final match = (isMarkdownLink ? _mdLinkPatternRegExp : pattern)
        .matchAsPrefix(parser.source, startMatchPos);
    if (match == null) return false;

    if (parser.source.length > match.end && !isMarkdownLink) {
      final followedBy = String.fromCharCode(parser.charAt(match.end));
      if (_borderRegExp.matchAsPrefix(followedBy) == null) {
        return false;
      }
    }

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
  final String originInstance;

  MentionMarkdownBuilder({required this.originInstance});

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
  final String name;
  final String originInstance;

  const MentionWidget(this.name, this.originInstance, {super.key});

  @override
  State<MentionWidget> createState() => MentionWidgetState();
}

Map<String, DetailedUserModel> userMentionCache = {};
Map<String, DetailedMagazineModel> magazineMentionCache = {};

class MentionWidgetState extends State<MentionWidget> {
  late String _displayName;
  ImageModel? _icon;
  void Function()? _onClick;

  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  void _fetchData() async {
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

    try {
      if (modifier == '@') {
        if (!userMentionCache.containsKey(cacheKey)) {
          userMentionCache[cacheKey] = await context
              .read<AppController>()
              .api
              .users
              .getByName(
                host == context.read<AppController>().instanceHost
                    ? name
                    : '$name@$host',
              );
        }
        final user = userMentionCache[cacheKey]!;

        setState(() {
          _icon = user.avatar;
          _onClick = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserScreen(user.id, initData: user),
              ),
            );
          };
        });
      } else if (modifier == '!') {
        if (!magazineMentionCache.containsKey(cacheKey)) {
          magazineMentionCache[cacheKey] = await context
              .read<AppController>()
              .api
              .magazines
              .getByName(
                host == context.read<AppController>().instanceHost
                    ? name
                    : '$name@$host',
              );
        }
        final magazine = magazineMentionCache[cacheKey]!;

        setState(() {
          _icon = magazine.icon;
          _onClick = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    MagazineScreen(magazine.id, initData: magazine),
              ),
            );
          };
        });
      }
    } catch (_) {
      // User/Magazine not found
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(_displayName),
      avatar: _icon != null ? Avatar(_icon!) : null,
      onPressed: _onClick,
      visualDensity: const VisualDensity(
        vertical: VisualDensity.minimumDensity,
      ),
    );
  }
}
