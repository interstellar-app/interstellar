import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:interstellar/src/utils/utils.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_symbols_icons/symbols.dart';

import './markdown.dart';

class SpoilerMarkdownSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\s{0,3}:{3,}\s*spoiler\s+(\S.*)$');

  RegExp endPattern = RegExp(r'^\s{0,3}:{3,}\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    final Match? match = pattern.firstMatch(parser.current.content);
    final String? title = match?.group(1)?.trim();

    parser.advance();

    final List<String> body = [];

    while (!parser.isDone) {
      if (endPattern.hasMatch(parser.current.content)) {
        parser.advance();
        break;
      } else {
        body.add(parser.current.content);
        parser.advance();
      }
    }

    final md.Node spoiler = md.Element('p', [
      md.Element('spoiler', [md.Text('$title\n${body.join('\n')}')]),
    ]);

    return spoiler;
  }
}

class SpoilerMarkdownBuilder extends mdf.MarkdownElementBuilder {
  final String originInstance;

  SpoilerMarkdownBuilder({required this.originInstance});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String text = element.textContent;
    final splitIndex = text.indexOf('\n');
    final title = text.substring(0, splitIndex).trim();
    final body = text.substring(splitIndex + 1).trim();

    return SpoilerWidget(
      originInstance: originInstance,
      title: nullIfEmpty(title),
      body: nullIfEmpty(body),
    );
  }
}

class SpoilerWidget extends StatefulWidget {
  final String originInstance;

  final String? title;
  final String? body;

  const SpoilerWidget({
    super.key,
    required this.originInstance,
    this.title,
    this.body,
  });

  @override
  State<SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<SpoilerWidget> {
  final ExpandableController controller = ExpandableController(
    initialExpanded: false,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      onTap: () => setState(controller.toggle),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  controller.expanded
                      ? Symbols.expand_more_rounded
                      : Symbols.chevron_right_rounded,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Markdown(widget.title ?? 'spoiler', widget.originInstance),
              ],
            ),
            Expandable(
              controller: controller,
              collapsed: const SizedBox(),
              expanded: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Markdown(widget.body ?? '', widget.originInstance),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
