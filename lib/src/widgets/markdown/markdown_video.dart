import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:markdown/markdown.dart' as md;
import 'package:interstellar/src/widgets/video.dart';

class VideoMarkdownSyntax extends md.InlineSyntax {
  VideoMarkdownSyntax() : super(r'!\[video\/mp4\]\((https:\/\/[^\s]+\.mp4)\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('video', match[1]!));
    return true;
  }
}

class YoutubeEmbedSyntax extends md.InlineSyntax {
  //from here https://stackoverflow.com/a/61033353
  static const _youtubePattern =
      r'(?:https?:\/\/)?(?:www\.)?youtu(?:\.be\/|be.com\/\S*(?:watch|embed)(?:(?:(?=\/[-a-zA-Z0-9_]{11,}(?!\S))\/)|(?:\S*v=|v\/)))([-a-zA-Z0-9_]{11,})';

  static const String _mdLinkPattern =
      r'\[(.*?)\]\(\s*' + _youtubePattern + r'(?:\s*".*?")?\s*\)';

  static final _mdLinkPatternRegExp = RegExp(
    _mdLinkPattern,
    multiLine: true,
    caseSensitive: true,
  );
  static final _borderRegExp = RegExp(r'[^a-z0-9@/\\]', caseSensitive: false);

  YoutubeEmbedSyntax() : super(_youtubePattern);

  bool _isMarkdownLink = false;

  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    startMatchPos ??= parser.pos;

    _isMarkdownLink = String.fromCharCode(parser.charAt(parser.pos)) == '[';
    bool isAutoLink = String.fromCharCode(parser.charAt(parser.pos)) == '<';
    if (isAutoLink) {
      startMatchPos += 1;
    }

    if (parser.pos > 0 && !_isMarkdownLink && !isAutoLink) {
      final precededBy = String.fromCharCode(parser.charAt(parser.pos - 1));
      if (_borderRegExp.matchAsPrefix(precededBy) == null) {
        return false;
      }
    }

    final match = (_isMarkdownLink ? _mdLinkPatternRegExp : pattern)
        .matchAsPrefix(parser.source, startMatchPos);
    if (match == null) return false;

    if (parser.source.length > match.end && !_isMarkdownLink && !isAutoLink) {
      final followedBy = String.fromCharCode(parser.charAt(match.end));
      if (_borderRegExp.matchAsPrefix(followedBy) == null) {
        return false;
      }
    }
    if (isAutoLink && String.fromCharCode(parser.charAt(match.end)) == '>') {
      parser.consume(2);
      startMatchPos += 1;
    }

    parser.writeText();

    if (onMatch(parser, match)) parser.consume(match[0]!.length);
    return true;
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final link =
        'https://www.youtube.com/watch?v=${match[_isMarkdownLink ? 2 : 1]!}';

    final anchor = md.Element.text('a', match[_isMarkdownLink ? 1 : 0]!);
    anchor.attributes['href'] = link;

    parser.addNode(anchor);

    parser.addNode(md.Element.text('video', link));
    return true;
  }
}

class VideoMarkdownBuilder extends mdf.MarkdownElementBuilder {
  final bool enableBlur;
  VideoMarkdownBuilder({this.enableBlur = false});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var textContent = element.textContent;

    return VideoPlayer(Uri.parse(textContent), enableBlur: enableBlur);
  }
}
