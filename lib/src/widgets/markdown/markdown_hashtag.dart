import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:markdown/markdown.dart' as md;

class HashtagMarkdownSyntax extends md.InlineSyntax {
  HashtagMarkdownSyntax() : super(_tagPattern);

  static const String _tagPattern =
      r'(?:\s|^)(?:#(?!(?:\d+|\w+?_|_\w*?)(?:\s|$)))(\w+)(?=\s|$)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tag = match.group(0);

    final node = md.Element.text('tag', tag ?? 'unknown');

    parser.addNode(node);

    return true;
  }
}

class HashtagMarkdownBuilder extends mdf.MarkdownElementBuilder {
  HashtagMarkdownBuilder();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: HashtagWidget(element.textContent),
          ),
        ],
      ),
    );
  }
}

class HashtagWidget extends StatelessWidget {
  const HashtagWidget(this.tag, {super.key});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(tag, style: const TextStyle(color: Colors.blue)),
      onTap: () => context.router.push(
        FeedRoute(
          feedName: tag,
          feed: FeedAggregator.fromSingleSource(
            name: tag,
            source: FeedSource.tag,
            sourceId: tag,
          ),
        ),
      ),
    );
  }
}
