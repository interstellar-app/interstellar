import 'package:flutter/material.dart';

class SettingsHeader extends StatelessWidget {
  final String text;

  const SettingsHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium!.merge(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
