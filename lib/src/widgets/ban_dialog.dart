import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

Future<void> openBanDialog(
  BuildContext context, {
  required UserModel user,
  required MagazineModel magazine,
}) async {
  await showDialog<DetailedMagazineModel>(
    context: context,
    builder: (BuildContext context) =>
        BanDialog(user: user, magazine: magazine),
  );
}

class BanDialog extends StatefulWidget {
  final UserModel user;
  final MagazineModel magazine;

  const BanDialog({required this.user, required this.magazine, super.key});

  @override
  State<BanDialog> createState() => _BanDialogState();
}

class _BanDialogState extends State<BanDialog> {
  final _reasonTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l(context).banUser),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l(context).banUser_help(widget.user.name, widget.magazine.name)),
          const SizedBox(height: 16),
          TextEditor(
            _reasonTextEditingController,
            label: l(context).reason,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l(context).cancel),
        ),
        LoadingFilledButton(
          onPressed: _reasonTextEditingController.text.isEmpty
              ? null
              : () async {
                  await context
                      .read<AppController>()
                      .api
                      .magazineModeration
                      .createBan(
                        widget.magazine.id,
                        widget.user.id,
                        reason: _reasonTextEditingController.text,
                      );

                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
          label: Text(l(context).banUserX(widget.user.name)),
          uesHaptics: true,
        ),
      ],
    );
  }
}
