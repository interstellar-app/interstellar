import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart';

class ImageSelector extends StatefulWidget {
  const ImageSelector(
    this.selected,
    this.onSelected, {
    this.enabled = true,
    super.key,
  });

  final XFile? selected;
  final void Function(XFile?) onSelected;
  final bool enabled;

  @override
  State<ImageSelector> createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(5),
        child: widget.selected == null
            ? Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: IconButton(
                      onPressed: widget.enabled
                          ? () async {
                              XFile? image = await _imagePicker.pickImage(
                                  source: ImageSource.gallery);
                              if (image != null) {
                                widget.onSelected(image);
                              }
                            }
                          : null,
                      tooltip: l(context).uploadFromGallery,
                      iconSize: 35,
                      icon: const Icon(Symbols.image_rounded),
                    ),
                  ),
                  if (Platform.isAndroid || Platform.isIOS)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: IconButton(
                        onPressed: widget.enabled
                            ? () async {
                                XFile? image = await _imagePicker.pickImage(
                                    source: ImageSource.camera);
                                if (image != null) {
                                  widget.onSelected(image);
                                }
                              }
                            : null,
                        tooltip: l(context).uploadFromCamera,
                        iconSize: 35,
                        icon: const Icon(Symbols.camera_rounded),
                      ),
                    )
                ],
              )
            : Row(
                children: [
                  Text(basename(widget.selected!.name)),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: IconButton(
                          onPressed: () {
                            setState(() {
                              widget.onSelected(null);
                            });
                          },
                          icon: const Icon(Symbols.close_rounded)))
                ],
              ));
  }
}
