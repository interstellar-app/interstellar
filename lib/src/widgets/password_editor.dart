import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/utils.dart';

class PasswordEditor extends StatefulWidget {
  const PasswordEditor(this.controller, {this.onChanged, super.key});

  final TextEditingController controller;
  final void Function(String)? onChanged;

  @override
  State<PasswordEditor> createState() => _PasswordEditorState();
}

class _PasswordEditorState extends State<PasswordEditor> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: l(context).password,
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
          onPressed: () => setState(() => obscureText = !obscureText),
        ),
      ),
      onChanged: widget.onChanged,
      autofillHints: const [AutofillHints.password],
      obscureText: obscureText,
    );
  }
}
