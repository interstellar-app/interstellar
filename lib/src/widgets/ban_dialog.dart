import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

Future<void> openBanDialog(
  BuildContext context, {
  required UserModel user,
  required CommunityModel community,
}) async {
  await showDialog<DetailedCommunityModel>(
    context: context,
    builder: (BuildContext context) =>
        BanDialog(user: user, community: community),
  );
}

class BanDialog extends StatefulWidget {
  final UserModel user;
  final CommunityModel community;

  const BanDialog({required this.user, required this.community, super.key});

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
          Text(
            l(context).banUser_help(widget.user.name, widget.community.name),
          ),
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
                      .communityModeration
                      .createBan(
                        widget.community.id,
                        widget.user.id,
                        reason: _reasonTextEditingController.text,
                      );

                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
          label: Text(l(context).banUserX(widget.user.name)),
          uesHaptics: true,
        ),
      ],
    );
  }
}
