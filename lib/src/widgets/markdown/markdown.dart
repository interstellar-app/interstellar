import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/widgets/image.dart';
import 'package:interstellar/src/widgets/markdown/markdown_config_share.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:interstellar/src/widgets/video.dart';

import './markdown_mention.dart';
import './markdown_spoiler.dart';
import './markdown_subscript_superscript.dart';
import './markdown_video.dart';

class Markdown extends StatelessWidget {
  final String data;
  final String originInstance;
  final ThemeData? themeData;

  const Markdown(
    this.data,
    this.originInstance, {
    this.themeData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return mdf.MarkdownBody(
      data: data,
      styleSheet:
          mdf.MarkdownStyleSheet.fromTheme(themeData ?? Theme.of(context))
              .merge(mdf.MarkdownStyleSheet(
        blockquoteDecoration: BoxDecoration(
          color: Colors.blue.shade500.withAlpha(50),
          borderRadius: BorderRadius.circular(2.0),
        ),
      )),
      onTapLink: (text, href, title) async {
        if (href != null) {
          openWebpageSecondary(context, Uri.parse(href));
        }
      },
      imageBuilder: (uri, title, alt) {
        if (uri.path.split('.').last == 'mp4') {
          return VideoPlayer(uri);
        }
        return AdvancedImage(
          ImageModel(
            src: uri.toString(),
            altText: alt,
            blurHash: null,
            blurHashWidth: null,
            blurHashHeight: null,
          ),
          openTitle: title ?? '',
        );
      },
      inlineSyntaxes: [
        SubscriptMarkdownSyntax(),
        SuperscriptMarkdownSyntax(),
        MentionMarkdownSyntax(),
        VideoMarkdownSyntax(),
        YoutubeEmbedSyntax()
      ],
      blockSyntaxes: [
        SpoilerMarkdownSyntax(),
        ConfigShareMarkdownSyntax(),
      ],
      builders: {
        'sub': SubscriptMarkdownBuilder(),
        'sup': SuperscriptMarkdownBuilder(),
        'mention': MentionMarkdownBuilder(originInstance: originInstance),
        'video': VideoMarkdownBuilder(),
        'spoiler': SpoilerMarkdownBuilder(originInstance: originInstance),
        'config-share': ConfigShareMarkdownBuilder(),
      },
    );
  }
}
