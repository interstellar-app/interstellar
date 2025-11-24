import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class TagEditor extends StatefulWidget {
  const TagEditor({super.key, required this.tag, required this.onUpdate});

  final Tag tag;
  final void Function(Tag?) onUpdate;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
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
                tileColor: _textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text('Text Color'),
                onTap: () {
                  Color c = _textColor;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a colour!'),
                      content: ColorPicker(
                        pickerColor: c,
                        onColorChanged: (color) {
                          c = color;
                        },
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _textColor = c;
                            });
                            Navigator.pop(context);
                          },
                          child: Text(l(context).save),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: _backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text('Background Color'),
                onTap: () {
                  Color c = _backgroundColor;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a colour!'),
                      content: ColorPicker(
                        pickerColor: c,
                        onColorChanged: (color) {
                          c = color;
                        },
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _backgroundColor = c;
                            });
                            Navigator.pop(context);
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
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      await ac.removeTag(widget.tag);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text('Delete'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    onPressed: () async {
                      final tag = await ac.setTag(
                        Tag(
                          id: widget.tag.id,
                          tag: _tagController.text,
                          backgroundColor: _backgroundColor,
                          textColor: _textColor,
                        ),
                      );
                      widget.onUpdate(tag);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text('Save'),
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
