import 'package:flutter/material.dart';

class TextEditor extends StatelessWidget {
  const TextEditor(
    this.controller, {
    this.keyboardType,
    this.label,
    this.hint,
    this.onChanged,
    this.enabled,
    this.maxLength,
    this.autofillHints,
    super.key,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? label;
  final String? hint;
  final void Function(String)? onChanged;
  final bool? enabled;
  final int? maxLength;
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        hintText: hint,
      ),
      onChanged: onChanged,
      enabled: enabled,
      maxLength: maxLength,
      autofillHints: autofillHints,
    );
  }
}
