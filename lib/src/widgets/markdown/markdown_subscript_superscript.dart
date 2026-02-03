import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:markdown/markdown.dart' as md;

class SubscriptMarkdownSyntax extends md.InlineSyntax {
  SubscriptMarkdownSyntax() : super(r'~([^~\s]+)~');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('sub', match[1]!));
    return true;
  }
}

class SuperscriptMarkdownSyntax extends md.InlineSyntax {
  SuperscriptMarkdownSyntax() : super(r'\^([^\s^]+)\^');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('sup', match[1]!));
    return true;
  }
}

class SubscriptMarkdownBuilder extends mdf.MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;

    return SubscriptSuperscriptWidget(text: textContent, isSuperscript: false);
  }
}

class SuperscriptMarkdownBuilder extends mdf.MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;

    return SubscriptSuperscriptWidget(text: textContent, isSuperscript: true);
  }
}

class SubscriptSuperscriptWidget extends StatelessWidget {
  final String text;
  final bool isSuperscript;

  const SubscriptSuperscriptWidget({
    required this.text,
    required this.isSuperscript,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            child: Transform.translate(
              offset: Offset(0, isSuperscript ? -5.0 : 3.0),
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
