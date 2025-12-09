import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';

class PostFlairsModal extends StatefulWidget {
  const PostFlairsModal({
    super.key,
    required this.flairs,
    required this.availableFlairs,
    required this.onUpdate,
  });

  final List<Tag> flairs;
  final List<Tag> availableFlairs;
  final void Function(List<Tag>) onUpdate;

  @override
  State<PostFlairsModal> createState() => _PostFlairsModalState();
}

class _PostFlairsModalState extends State<PostFlairsModal> {
  late List<Tag> _flairs;

  @override
  void initState() {
    super.initState();

    _flairs = widget.flairs;
  }

  @override
  Widget build(BuildContext context) {
    final activeFlairIds = _flairs.map((flair) => flair.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l(context).editFlairs,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              ...widget.availableFlairs.map(
                (flair) => CheckboxListTile(
                  value: activeFlairIds.contains(flair.id),
                  title: TagWidget(tag: flair),
                  onChanged: (value) {
                    if (value == null) return;

                    if (value) {
                      if (!activeFlairIds.contains(flair.id)) {
                        setState(() {
                          _flairs = [..._flairs, flair];
                          widget.onUpdate(_flairs);
                        });
                      }
                    } else {
                      if (activeFlairIds.contains(flair.id)) {
                        setState(() {
                          _flairs = [..._flairs]..remove(flair);
                          widget.onUpdate(_flairs);
                        });
                      }
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: SizedBox(width: 28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
