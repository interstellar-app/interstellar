import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/text_editor.dart';

Future<String?> reportContent(BuildContext context, String contentTypeName) =>
    showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          ReportContentBody(contentTypeName: contentTypeName),
    );

class ReportContentBody extends StatefulWidget {
  final String contentTypeName;

  const ReportContentBody({required this.contentTypeName, super.key});

  @override
  State<ReportContentBody> createState() => _ReportContentBodyState();
}

class _ReportContentBodyState extends State<ReportContentBody> {
  final _reasonTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l(context).reportX(widget.contentTypeName)),
      content: TextEditor(
        _reasonTextEditingController,
        label: l(context).reason,
        onChanged: (_) => setState(() {}),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => context.router.pop(),
          child: Text(l(context).cancel),
        ),
        FilledButton(
          onPressed: _reasonTextEditingController.text.isEmpty
              ? null
              : () => context.router.pop(_reasonTextEditingController.text),
          child: Text(l(context).report),
        ),
      ],
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.up,
    );
  }
}
