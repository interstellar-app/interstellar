import 'package:flutter/material.dart';

class ListTileSwitch extends StatelessWidget {
  const ListTileSwitch({
    required this.value,
    required this.onChanged,
    this.leading,
    this.title,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  final bool value;
  final void Function(bool)? onChanged;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
      enabled: enabled,
    );
  }
}
