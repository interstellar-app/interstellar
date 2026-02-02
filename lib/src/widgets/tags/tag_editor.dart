import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

@RoutePage()
class TagEditorScreen extends StatefulWidget {
  const TagEditorScreen({super.key, required this.tag, required this.onUpdate});

  final Tag tag;
  final void Function(Tag?) onUpdate;

  @override
  State<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends State<TagEditorScreen> {
  late final TextEditingController _tagController;
  late Color _textColor;
  late Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.tag.tag);
    _textColor = widget.tag.textColor;
    _backgroundColor = widget.tag.backgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.tag.tag)),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextEditor(_tagController, label: 'Tag'),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: _backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(l(context).color),
                onTap: () {
                  Color c = _backgroundColor;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l(context).pickColor),
                      content: ColorPicker(
                        pickerColor: c,
                        onColorChanged: (color) {
                          c = color;
                        },
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () => context.router.pop(),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _backgroundColor = c;
                              final tc = ColorScheme.fromSeed(seedColor: c);
                              _textColor = tc.primaryFixed;
                            });
                            context.router.pop();
                          },
                          child: Text(l(context).save),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => context.router.pop(),
                    child: Text(l(context).cancel),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      await ac.removeTag(widget.tag);
                      if (!context.mounted) return;
                      widget.onUpdate(null);
                      context.router.pop();
                    },
                    child: Text(l(context).delete),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    onPressed: () async {
                      Tag tag;
                      try {
                        tag = await ac.setTag(
                          Tag(
                            id: widget.tag.id,
                            tag: _tagController.text,
                            backgroundColor: _backgroundColor,
                            textColor: _textColor,
                          ),
                        );
                      } catch (err) {
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l(context).tags_exist),
                            actions: [
                              OutlinedButton(
                                onPressed: () => context.router.pop(),
                                child: Text(l(context).okay),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      widget.onUpdate(tag);
                      if (!context.mounted) return;
                      context.router.pop();
                    },
                    child: Text(l(context).save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
