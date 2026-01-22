import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/widgets/image_selector.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
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
  final Future<void> Function(
    String body,
    String lang, {
    XFile? image,
    String? alt,
  })
  onReply;
  final Function() onComplete;
  final String draftResourceId;

  @override
  State<ContentReply> createState() => _ContentReplyState();
}

class _ContentReplyState extends State<ContentReply> {
  final TextEditingController _textController = TextEditingController();
  late String _replyLanguage;

  XFile? _imageFile;
  String? _altText;

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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: MarkdownEditor(
              _textController,
              originInstance: null,
              draftController: replyDraftController,
              autoFocus: true,
              inline: widget.inline,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (context.read<AppController>().serverSoftware ==
                  ServerSoftware.mbin)
                ImageSelector(
                  _imageFile,
                  (file, altText) => setState(() {
                    _imageFile = file;
                    _altText = altText;
                  }),
                  inline: true,
                ),
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
                  await widget.onReply(
                    _textController.text,
                    _replyLanguage,
                    image: _imageFile,
                    alt: _altText,
                  );

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
  }
}

@RoutePage()
class ContentReplyScreen extends StatelessWidget {
  const ContentReplyScreen({
    super.key,
    this.inline = true,
    required this.content,
    required this.onReply,
    required this.onComplete,
    required this.draftResourceId,
  });

  final bool inline;
  final ContentItem content;
  final Future<void> Function(
      String body,
      String lang, {
      XFile? image,
      String? alt,
      })
  onReply;
  final Function() onComplete;
  final String draftResourceId;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context).replying_toX(
            content.user?.name ?? content.contentTypeName,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(8),
            child: Markdown(
              content.title ?? content.body!,
              content.originInstance,
              nsfw: content.isNSFW,
            ),
          )),
          SliverToBoxAdapter(child: ContentReply(inline: false, content: content, onReply: onReply, onComplete: onComplete, draftResourceId: draftResourceId)),
        ],
      ),
    );
  }

}