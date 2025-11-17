import 'dart:convert';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/database.dart';
import './markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? originInstance;
  final DraftAutoController draftController;
  final void Function(String)? onChanged;
  final bool? enabled;
  final String? label;
  final bool? draftDisableAutoLoad;
  final bool autoFocus;
  final bool inline;

  const MarkdownEditor(
    this.controller, {
    required this.originInstance,
    required this.draftController,
    this.draftDisableAutoLoad,
    this.onChanged,
    this.enabled,
    this.label,
    this.autoFocus = false,
    this.inline = true,
    super.key,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  final _focusNodeTextField = FocusNode();

  final draftDebounce = Debouncer(duration: const Duration(milliseconds: 1000));
  final ScrollController _scrollController = ScrollController();

  void execAction(_MarkdownEditorActionBase action) async {
    final input = _MarkdownEditorData(
      text: widget.controller.text,
      selectionStart: widget.controller.selection.start,
      selectionEnd: widget.controller.selection.end,
    );
    final output = await action.run(input);

    widget.controller.text = output.text;
    widget.controller.selection = widget.controller.selection.copyWith(
      baseOffset: output.selectionStart,
      extentOffset: output.selectionEnd,
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.draftDisableAutoLoad != true) {
      final draftRead = widget.draftController.read();
      if (draftRead != null) {
        widget.controller.text = draftRead.body;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(widget.label!),
          ),
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: DefaultTabController(
            length: 3,
            child: DefaultTabControllerListener(
              onTabSelected: (newIndex) {
                setState(() {});
              },
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.edit_rounded),
                            const SizedBox(width: 8),
                            Text(l(context).markdownEditor_edit),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.preview_rounded),
                            const SizedBox(width: 8),
                            Text(l(context).markdownEditor_preview),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.drafts_rounded),
                            const SizedBox(width: 8),
                            Text(l(context).markdownEditor_drafts),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrapper(
                    shouldWrap: widget.inline,
                    parentBuilder: (child) =>
                        SizedBox(height: 200, child: child),
                    child: Builder(
                      // physics: const NeverScrollableScrollPhysics(),
                      builder: (context) {
                        final controller = DefaultTabController.of(context);
                        switch (controller.index) {
                          case 0:
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      ..._actions(context).map(
                                        (action) => DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: action.showDivider
                                                ? Border(
                                                    right: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outlineVariant,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: IconButton(
                                              onPressed: () {
                                                _focusNodeTextField
                                                    .requestFocus();

                                                execAction(action.action);
                                              },
                                              icon: Icon(action.icon),
                                              tooltip:
                                                  action.tooltip +
                                                  (action.shortcut == null
                                                      ? ''
                                                      : ' (${readableShortcut(action.shortcut!)})'),
                                              style: TextButton.styleFrom(
                                                shape: const LinearBorder(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                            ),
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: IconButton(
                                            onPressed: () async {
                                              final config = await showDialog<String?>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return const _MarkdownEditorConfigShareDialog();
                                                },
                                              );

                                              _focusNodeTextField
                                                  .requestFocus();

                                              if (config == null) return;

                                              execAction(
                                                _MarkdownEditorActionInsertSection(
                                                  config,
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Symbols.share_rounded,
                                            ),
                                            style: TextButton.styleFrom(
                                              shape: const LinearBorder(),
                                            ),
                                            tooltip: l(context).configShare,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, thickness: 1),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: CallbackShortcuts(
                                    bindings: <ShortcutActivator, VoidCallback>{
                                      const SingleActivator(
                                        LogicalKeyboardKey.enter,
                                      ): () => execAction(
                                        const _MarkdownEditorActionEnter(),
                                      ),
                                      for (var action
                                          in _actions(context).where(
                                            (action) => action.shortcut != null,
                                          ))
                                        action.shortcut!: () =>
                                            execAction(action.action),
                                    },
                                    child: TextField(
                                      controller: widget.controller,
                                      keyboardType: TextInputType.multiline,
                                      minLines: 2,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(12),
                                      ),
                                      onChanged: (String value) {
                                        widget.onChanged?.call(value);

                                        draftDebounce.run(() async {
                                          if (value.isNotEmpty) {
                                            await widget.draftController.save(
                                              value,
                                            );
                                          } else {
                                            await widget.draftController
                                                .discard();
                                          }
                                        });
                                      },
                                      enabled: widget.enabled,
                                      focusNode: _focusNodeTextField,
                                      autofocus: widget.autoFocus,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          case 1:
                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Markdown(
                                  widget.controller.text,
                                  widget.originInstance ??
                                      context
                                          .watch<AppController>()
                                          .instanceHost,
                                ),
                              ),
                            );
                          case 2:
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: LoadingFilledButton(
                                        onPressed:
                                            widget.controller.text.isEmpty
                                            ? null
                                            : () async {
                                                await context
                                                    .read<DraftsController>()
                                                    .manualSave(
                                                      widget.controller.text,
                                                    );
                                              },
                                        label: Text(
                                          l(
                                            context,
                                          ).markdownEditor_drafts_manuallySave,
                                        ),
                                        icon: const Icon(Symbols.save_rounded),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: LoadingOutlinedButton(
                                        onPressed:
                                            context
                                                .watch<DraftsController>()
                                                .drafts
                                                .isEmpty
                                            ? null
                                            : () async {
                                                await context
                                                    .read<DraftsController>()
                                                    .removeAll();
                                              },
                                        label: Text(
                                          l(
                                            context,
                                          ).markdownEditor_drafts_discardAll,
                                        ),
                                        icon: const Icon(
                                          Symbols.delete_forever_rounded,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Builder(
                                    builder: (context) {
                                      return ListView(
                                        controller: _scrollController,
                                        shrinkWrap: true,
                                        children: context
                                            .watch<DraftsController>()
                                            .drafts
                                            .reversed
                                            .map(
                                              (
                                                draft,
                                              ) => _MarkdownEditorDraftItem(
                                                draft: draft,
                                                onApply: () {
                                                  widget.controller.text =
                                                      draft.body;

                                                  DefaultTabController.of(
                                                    context,
                                                  ).animateTo(0);
                                                },
                                                originInstance:
                                                    widget.originInstance ??
                                                    context
                                                        .watch<AppController>()
                                                        .instanceHost,
                                              ),
                                            )
                                            .toList(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          case _:
                            return Container();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<_MarkdownEditorActionInfo> _actions(BuildContext context) => [
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionBlock('### '),
    icon: Symbols.title_rounded,
    tooltip: l(context).markdownEditor_heading,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyH, control: true),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('**'),
    icon: Symbols.format_bold_rounded,
    tooltip: l(context).markdownEditor_bold,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('_'),
    icon: Symbols.format_italic_rounded,
    tooltip: l(context).markdownEditor_italic,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyI, control: true),
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('~~'),
    icon: Symbols.strikethrough_s_rounded,
    tooltip: l(context).markdownEditor_strikethrough,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyX,
      control: true,
      alt: true,
    ),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('`'),
    icon: Symbols.code_rounded,
    tooltip: l(context).markdownEditor_inlineCode,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyE, control: true),
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('\n```\n'),
    icon: Symbols.segment_rounded,
    tooltip: l(context).markdownEditor_codeBlock,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyE,
      control: true,
      alt: true,
    ),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionLink(),
    icon: Symbols.link_rounded,
    tooltip: l(context).markdownEditor_link,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyK, control: true),
  ),
  _MarkdownEditorActionInfo(
    action: _MarkdownEditorActionImage(context: context),
    icon: Symbols.image_rounded,
    tooltip: l(context).markdownEditor_image,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyK,
      control: true,
      alt: true,
    ),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('~'),
    icon: Symbols.subscript_rounded,
    tooltip: l(context).markdownEditor_subscript,
    shortcut: const SingleActivator(LogicalKeyboardKey.comma, control: true),
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInline('^'),
    icon: Symbols.superscript_rounded,
    tooltip: l(context).markdownEditor_superscript,
    shortcut: const SingleActivator(LogicalKeyboardKey.period, control: true),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionBlock('> '),
    icon: Symbols.format_quote_rounded,
    tooltip: l(context).markdownEditor_quote,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyQ,
      control: true,
      alt: true,
    ),
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionInsertSection('---'),
    icon: Symbols.horizontal_rule_rounded,
    tooltip: l(context).markdownEditor_horizontalRule,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyH,
      control: true,
      alt: true,
    ),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionBlock('- '),
    icon: Symbols.format_list_bulleted_rounded,
    tooltip: l(context).markdownEditor_bulletedList,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyL, control: true),
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionBlock('1. '),
    icon: Symbols.format_list_numbered_rounded,
    tooltip: l(context).markdownEditor_numberedList,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyL,
      control: true,
      alt: true,
    ),
    showDivider: true,
  ),
  _MarkdownEditorActionInfo(
    action: const _MarkdownEditorActionBlock(
      '\n::: spoiler PREVIEW_HERE\n',
      '\n:::\n',
    ),
    icon: Symbols.warning_rounded,
    tooltip: l(context).markdownEditor_spoiler,
    shortcut: const SingleActivator(
      LogicalKeyboardKey.keyS,
      control: true,
      alt: true,
    ),
    showDivider: true,
  ),
];

class _MarkdownEditorActionInfo {
  final _MarkdownEditorActionBase action;
  final IconData icon;
  final String tooltip;
  final SingleActivator? shortcut;
  final bool showDivider;

  const _MarkdownEditorActionInfo({
    required this.action,
    required this.icon,
    required this.tooltip,
    this.shortcut,
    this.showDivider = false,
  });
}

abstract class _MarkdownEditorActionBase {
  const _MarkdownEditorActionBase();

  Future<_MarkdownEditorData> run(_MarkdownEditorData input);

  _MarkdownEditorData getCurrentLine(_MarkdownEditorData input) {
    final endIndex = input.text.indexOf('\n', input.selectionStart);
    final startIndex = input.selectionStart == 0
        ? -1
        : input.text.lastIndexOf('\n', input.selectionStart - 1);

    final lineEnd = endIndex == -1 ? input.text.length : endIndex;
    final lineStart = startIndex == -1
        ? 0
        : (lineEnd >= startIndex + 1 ? startIndex + 1 : startIndex);

    return _MarkdownEditorData(
      text: input.text,
      selectionStart: lineStart,
      selectionEnd: lineEnd,
    );
  }
}

class _MarkdownEditorData {
  String text;
  int selectionStart;
  int selectionEnd;
  String selectionText;

  _MarkdownEditorData({
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
  }) : selectionText = text.substring(selectionStart, selectionEnd);
}

class _MarkdownEditorActionInline extends _MarkdownEditorActionBase {
  final String startChars;
  final String endChars;

  const _MarkdownEditorActionInline(this.startChars, [String? endChars])
    : endChars = endChars ?? startChars;

  @override
  Future<_MarkdownEditorData> run(_MarkdownEditorData input) async {
    var text = input.text;

    final contextStart = input.selectionStart - startChars.length;
    final contextEnd = input.selectionEnd + endChars.length;
    if (contextStart >= 0 &&
        contextEnd <= text.length &&
        text.substring(contextStart, contextEnd).startsWith(startChars) &&
        text.substring(contextStart, contextEnd).endsWith(endChars)) {
      text = text.replaceRange(input.selectionEnd, contextEnd, '');
      text = text.replaceRange(contextStart, input.selectionStart, '');
      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart - startChars.length,
        selectionEnd: input.selectionEnd - startChars.length,
      );
    } else {
      text = text.replaceRange(
        input.selectionEnd,
        input.selectionEnd,
        endChars,
      );
      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        startChars,
      );
      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart + startChars.length,
        selectionEnd: input.selectionEnd + startChars.length,
      );
    }
  }
}

class _MarkdownEditorActionBlock extends _MarkdownEditorActionBase {
  final String startChars;
  final String endChars;

  const _MarkdownEditorActionBlock(this.startChars, [this.endChars = '']);

  @override
  Future<_MarkdownEditorData> run(_MarkdownEditorData input) async {
    var text = input.text;

    _MarkdownEditorData line = getCurrentLine(input);

    if (line.selectionText.startsWith(startChars) &&
        line.selectionText.endsWith(endChars)) {
      text = text.replaceRange(
        line.selectionEnd - endChars.length,
        line.selectionEnd,
        '',
      );
      text = text.replaceRange(
        line.selectionStart,
        line.selectionStart + startChars.length,
        '',
      );
      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart - startChars.length,
        selectionEnd: input.selectionEnd - startChars.length,
      );
    } else {
      text = text.replaceRange(line.selectionEnd, line.selectionEnd, endChars);
      text = text.replaceRange(
        line.selectionStart,
        line.selectionStart,
        startChars,
      );
      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart + startChars.length,
        selectionEnd: input.selectionEnd + startChars.length,
      );
    }
  }
}

class _MarkdownEditorActionLink extends _MarkdownEditorActionBase {
  final bool isImage;

  const _MarkdownEditorActionLink({this.isImage = false});

  @override
  Future<_MarkdownEditorData> run(_MarkdownEditorData input) async {
    final imageStartChar = isImage ? '!' : '';

    final helpMessage = isImage ? 'altr' : 'text';

    var text = input.text;

    if (input.selectionText.isEmpty) {
      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        '$imageStartChar[$helpMessage](url)',
      );

      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart + 7 + imageStartChar.length,
        selectionEnd: input.selectionStart + 10 + imageStartChar.length,
      );
    }

    if (isValidUrl(input.selectionText)) {
      text = text.replaceRange(input.selectionEnd, input.selectionEnd, ')');
      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        '$imageStartChar[$helpMessage](',
      );

      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart + 1 + imageStartChar.length,
        selectionEnd: input.selectionStart + 5 + imageStartChar.length,
      );
    } else {
      text = text.replaceRange(
        input.selectionEnd,
        input.selectionEnd,
        '](url)',
      );
      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        '$imageStartChar[',
      );

      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionEnd + 3 + imageStartChar.length,
        selectionEnd: input.selectionEnd + 6 + imageStartChar.length,
      );
    }
  }
}

class _MarkdownEditorActionImage extends _MarkdownEditorActionBase {
  final BuildContext context;

  const _MarkdownEditorActionImage({required this.context});

  @override
  Future<_MarkdownEditorData> run(_MarkdownEditorData input) async {
    final imageStartChar = '!';

    final helpMessage = 'altr';

    var text = input.text;

    if (input.selectionText.isEmpty) {
      XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);

      String url = '';
      if (image != null && context.mounted) {
        url = await context.read<AppController>().api.images.uploadImage(
          store: context.read<AppController>().profile.defaultImageStore,
          image: image,
        );
      }

      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        '$imageStartChar[$helpMessage]($url)',
      );

      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart + 7 + imageStartChar.length,
        selectionEnd: input.selectionStart + 10 + imageStartChar.length,
      );
    }

    if (isValidUrl(input.selectionText)) {
      text = text.replaceRange(input.selectionEnd, input.selectionEnd, ')');
      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        '$imageStartChar[$helpMessage](',
      );

      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionStart + 1 + imageStartChar.length,
        selectionEnd: input.selectionStart + 5 + imageStartChar.length,
      );
    } else {
      text = text.replaceRange(
        input.selectionEnd,
        input.selectionEnd,
        '](url)',
      );
      text = text.replaceRange(
        input.selectionStart,
        input.selectionStart,
        '$imageStartChar[',
      );

      return _MarkdownEditorData(
        text: text,
        selectionStart: input.selectionEnd + 3 + imageStartChar.length,
        selectionEnd: input.selectionEnd + 6 + imageStartChar.length,
      );
    }
  }
}

class _MarkdownEditorActionInsertSection extends _MarkdownEditorActionBase {
  final String sectionText;

  const _MarkdownEditorActionInsertSection(this.sectionText);

  @override
  Future<_MarkdownEditorData> run(_MarkdownEditorData input) async {
    var text = input.text;

    int prefixNewlines = 2;
    if (input.selectionStart - 1 >= 0 &&
        text[input.selectionStart - 1] == '\n') {
      prefixNewlines--;

      if (input.selectionStart - 2 >= 0 &&
          text[input.selectionStart - 2] == '\n') {
        prefixNewlines--;
      }
    }

    int suffixNewlines = 2;
    if (input.selectionStart < text.length &&
        text[input.selectionStart] == '\n') {
      suffixNewlines--;

      if (input.selectionStart + 1 < text.length &&
          text[input.selectionStart + 1] == '\n') {
        suffixNewlines--;
      }
    }

    final newText =
        '${'\n' * prefixNewlines}$sectionText${'\n' * suffixNewlines}';

    text = text.replaceRange(
      input.selectionStart,
      input.selectionStart,
      newText,
    );

    return _MarkdownEditorData(
      text: text,
      selectionStart: input.selectionStart + newText.length,
      selectionEnd: input.selectionEnd + newText.length,
    );
  }
}

class _MarkdownEditorActionEnter extends _MarkdownEditorActionBase {
  const _MarkdownEditorActionEnter();

  @override
  Future<_MarkdownEditorData> run(_MarkdownEditorData input) async {
    var text = input.text;

    final line = getCurrentLine(input);

    // Bulleted list
    if (line.selectionText.startsWith('- ') ||
        line.selectionText.startsWith('* ') ||
        line.selectionText.startsWith('+ ')) {
      final style = line.selectionText[0];

      // Empty item
      if (line.selectionText.length == 2) {
        return _MarkdownEditorData(
          text: text.replaceRange(
            line.selectionStart,
            line.selectionStart + 2,
            '',
          ),
          selectionStart: input.selectionStart - 2,
          selectionEnd: input.selectionEnd - 2,
        );
      }

      return _MarkdownEditorData(
        text: text.replaceRange(
          input.selectionStart,
          input.selectionStart,
          '\n$style ',
        ),
        selectionStart: input.selectionStart + 3,
        selectionEnd: input.selectionEnd + 3,
      );
    }

    // Numbered List
    final numberedListMatch = RegExp(
      r'(\d)+([.)]) ',
    ).matchAsPrefix(line.selectionText);
    if (numberedListMatch != null) {
      final currentNumber = numberedListMatch[1]!;
      final nextNumber = (int.parse(currentNumber) + 1).toString();
      final style = numberedListMatch[2];

      // Empty item
      final currentPrefixLength = currentNumber.length + 2;
      if (line.selectionText.length == currentPrefixLength) {
        return _MarkdownEditorData(
          text: text.replaceRange(
            line.selectionStart,
            line.selectionStart + currentPrefixLength,
            '',
          ),
          selectionStart: input.selectionStart - currentPrefixLength,
          selectionEnd: input.selectionEnd - currentPrefixLength,
        );
      }

      final nextPrefixLength = nextNumber.length + 2;
      return _MarkdownEditorData(
        text: text.replaceRange(
          input.selectionStart,
          input.selectionStart,
          '\n$nextNumber$style ',
        ),
        selectionStart: input.selectionStart + 1 + nextPrefixLength,
        selectionEnd: input.selectionEnd + 1 + nextPrefixLength,
      );
    }

    return _MarkdownEditorData(
      text: text.replaceRange(input.selectionStart, input.selectionEnd, '\n'),
      selectionStart: input.selectionStart + 1,
      selectionEnd: input.selectionStart + 1,
    );
  }
}

class _MarkdownEditorDraftItem extends StatefulWidget {
  final Draft draft;
  final void Function() onApply;
  final String originInstance;

  const _MarkdownEditorDraftItem({
    required this.draft,
    required this.onApply,
    required this.originInstance,
  });

  @override
  State<_MarkdownEditorDraftItem> createState() =>
      __MarkdownEditorDraftItemState();
}

class __MarkdownEditorDraftItemState extends State<_MarkdownEditorDraftItem> {
  final ExpandableController _expandableController = ExpandableController(
    initialExpanded: false,
  );

  @override
  Widget build(BuildContext context) {
    discardDraft() {
      context.read<DraftsController>().removeByDate(widget.draft.at);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(
            widget.draft.body,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${dateTimeFormat(widget.draft.at)}\n${widget.draft.resourceId != null ? l(context).markdownEditor_drafts_savedAutomatically : l(context).markdownEditor_drafts_savedManually}${widget.draft.resourceId != null ? ': ${widget.draft.resourceId}' : ''}',
          ),
          leading: Icon(
            _expandableController.expanded
                ? Symbols.expand_less_rounded
                : Symbols.expand_more_rounded,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(l(context).markdownEditor_drafts_apply),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(l(context).close),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);

                              widget.onApply();
                            },
                            child: Text(
                              l(context).markdownEditor_drafts_applyAndKeep,
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);

                              widget.onApply();

                              discardDraft();
                            },
                            child: Text(
                              l(context).markdownEditor_drafts_applyAndDiscard,
                            ),
                          ),
                        ],
                        actionsOverflowAlignment: OverflowBarAlignment.center,
                        actionsOverflowButtonSpacing: 8,
                        actionsOverflowDirection: VerticalDirection.up,
                      );
                    },
                  );
                },
                icon: const Icon(Symbols.check_rounded),
              ),
              IconButton(
                onPressed: discardDraft,
                icon: const Icon(Symbols.delete_outline_rounded),
              ),
            ],
          ),
          onTap: () => setState(_expandableController.toggle),
        ),
        Expandable(
          controller: _expandableController,
          collapsed: const SizedBox(),
          expanded: SizedBox(
            width: double.infinity,
            child: Card.outlined(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(widget.draft.body),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MarkdownEditorConfigShareDialog extends StatefulWidget {
  const _MarkdownEditorConfigShareDialog();

  @override
  State<_MarkdownEditorConfigShareDialog> createState() =>
      _MarkdownEditorConfigShareDialogState();
}

class _MarkdownEditorConfigShareDialogState
    extends State<_MarkdownEditorConfigShareDialog> {
  List<String>? _profiles;
  List<String>? _filterLists;
  List<String>? _feeds;

  @override
  void initState() {
    super.initState();

    loadNames();
  }

  void loadNames() async {
    final ac = context.read<AppController>();
    _profiles = await ac.getProfileNames();
    _filterLists = ac.filterLists.keys.toList();
    _feeds = ac.feeds.keys.toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const headerEdgeInserts = EdgeInsets.fromLTRB(12, 8, 0, 4);

    return SimpleDialog(
      title: Text(l(context).configShare),
      children: [
        if (_profiles != null && _profiles!.isNotEmpty) ...[
          Padding(padding: headerEdgeInserts, child: Text(l(context).profiles)),
          ..._profiles!.map(
            (profileName) => SimpleDialogOption(
              child: Text(profileName),
              onPressed: () async {
                final profile = (await context.read<AppController>().getProfile(
                  profileName,
                )).exportReady();

                final config = await ConfigShare.create(
                  type: ConfigShareType.profile,
                  name: profileName,
                  payload: profile.toJson(),
                );
                if (!context.mounted) return;
                Navigator.pop(context, config.toMarkdown());
              },
            ),
          ),
        ],
        if (_filterLists != null && _filterLists!.isNotEmpty) ...[
          Padding(
            padding: headerEdgeInserts,
            child: Text(l(context).filterLists),
          ),
          ..._filterLists!.map(
            (filterListName) => SimpleDialogOption(
              child: Text(filterListName),
              onPressed: () async {
                final filterList = context
                    .read<AppController>()
                    .filterLists[filterListName]!;

                final config = await ConfigShare.create(
                  type: ConfigShareType.filterList,
                  name: filterListName,
                  payload: filterList.toJson(),
                );
                final configStr = jsonEncode(config.toJson());
                if (!context.mounted) return;
                Navigator.pop(context, configStr);
              },
            ),
          ),
        ],
        if (_feeds != null && _feeds!.isNotEmpty) ...[
          Padding(
            padding: headerEdgeInserts,
            child: Text(l(context).filterLists),
          ),
          ..._feeds!.map(
            (feedName) => SimpleDialogOption(
              child: Text(feedName),
              onPressed: () async {
                final feed = context.read<AppController>().feeds[feedName]!;

                final config = await ConfigShare.create(
                  type: ConfigShareType.feed,
                  name: feedName,
                  payload: feed.toJson(),
                );
                final configStr = jsonEncode(config.toJson());
                if (!context.mounted) return;
                Navigator.pop(context, configStr);
              },
            ),
          ),
        ],
      ],
    );
  }
}
