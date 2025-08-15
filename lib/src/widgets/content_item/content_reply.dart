import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';

class ContentReply extends StatefulWidget {
  const ContentReply({
    super.key,
    this.inline = true,
    required this.content,
    required this.onReply,
    required this.onComplete,
    required this.draftResourceId,
  });

  final bool inline;
  final ContentItem content;
  final Future<void> Function(String body, String lang) onReply;
  final Function() onComplete;
  final String draftResourceId;

  @override
  State<ContentReply> createState() => _ContentReplyState();
}

class _ContentReplyState extends State<ContentReply> {
  final TextEditingController _textController = TextEditingController();
  late String _replyLanguage;

  @override
  void initState() {
    super.initState();

    _replyLanguage = context
        .read<AppController>()
        .profile
        .defaultCreateLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final replyDraftController = context.watch<DraftsController>().auto(
      widget.draftResourceId,
    );

    final reply = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          MarkdownEditor(
            _textController,
            originInstance: null,
            draftController: replyDraftController,
            autoFocus: true,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () async {
                  final newLang = await languageSelectionMenu(
                    context,
                  ).askSelection(context, _replyLanguage);

                  if (newLang != null) {
                    setState(() {
                      _replyLanguage = newLang;
                    });
                  }
                },
                icon: Icon(Symbols.globe_rounded),
                tooltip: getLanguageName(context, _replyLanguage),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onComplete,
                child: Text(l(context).cancel),
              ),
              const SizedBox(width: 8),
              LoadingFilledButton(
                onPressed: () async {
                  await widget.onReply(_textController.text, _replyLanguage);

                  await replyDraftController.discard();
                  widget.onComplete();
                },
                label: Text(l(context).submit),
                uesHaptics: true,
              ),
            ],
          ),
        ],
      ),
    );

    if (!widget.inline) {
      final parent = Padding(
        padding: const EdgeInsets.all(8),
        child: Text(widget.content.title ?? widget.content.body!),
      );

      return Scaffold(
        appBar: AppBar(
          title: Text(
            l(context).replying_toX(
              widget.content.user ?? widget.content.contentTypeName,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [parent, reply],
        ),
      );
    } else {
      return reply;
    }
  }
}
