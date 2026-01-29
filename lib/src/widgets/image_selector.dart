import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';

class ImageSelector extends StatefulWidget {
  const ImageSelector(
    this.selected,
    this.onSelected, {
    this.enabled = true,
    this.inline = false,
    super.key,
  });

  final XFile? selected;
  final void Function(XFile?, String?) onSelected;
  final bool enabled;
  final bool inline;

  @override
  State<ImageSelector> createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  final TextEditingController _altTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return widget.selected == null
        ? Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: IconButton(
                    onPressed: widget.enabled
                        ? () async {
                            XFile? image = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              widget.onSelected(image, _altTextController.text);
                            }
                          }
                        : null,
                    tooltip: l(context).uploadFromGallery,
                    iconSize: 35,
                    icon: const Icon(Symbols.image_rounded),
                  ),
                ),
                if (PlatformUtils.isMobile)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: IconButton(
                      onPressed: widget.enabled
                          ? () async {
                              XFile? image = await ImagePicker().pickImage(
                                source: ImageSource.camera,
                              );
                              widget.onSelected(image, _altTextController.text);
                            }
                          : null,
                      tooltip: l(context).uploadFromCamera,
                      iconSize: 35,
                      icon: const Icon(Symbols.camera_rounded),
                    ),
                  ),
              ],
            ),
          )
        : widget.inline
        ? IconButton(
            onPressed: () {
              widget.onSelected(null, null);
            },
            icon: const Icon(Symbols.cancel_rounded),
          )
        : Card.outlined(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(widget.selected!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextEditor(
                          _altTextController,
                          keyboardType: TextInputType.text,
                          label: l(context).altText,
                          onChanged: (_) => setState(() {
                            widget.onSelected(
                              widget.selected,
                              _altTextController.text,
                            );
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              widget.onSelected(null, null);
                            });
                          },
                          icon: const Icon(Symbols.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
