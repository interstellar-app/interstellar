import 'package:flutter/material.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';

class ListTileSelect<T> extends StatelessWidget {
  const ListTileSelect({
    required this.title,
    required this.selectionMenu,
    required this.value,
    required this.oldValue,
    required this.onChange,
    super.key,
    this.icon,
    this.enabled = true,
  });

  final String title;
  final IconData? icon;
  final SelectionMenu<T> selectionMenu;
  final T value;
  final T? oldValue;
  final void Function(T newValue) onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final curOption = selectionMenu.getOption(value);

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(curOption.icon, size: 20),
          const SizedBox(width: 4),
          Text(curOption.title),
          const Icon(Symbols.arrow_drop_down_rounded),
        ],
      ),
      onTap: () async {
        final newValue = await selectionMenu.askSelection(context, oldValue);

        if (newValue == null) return;

        onChange(newValue);
      },
      enabled: enabled,
    );
  }
}
