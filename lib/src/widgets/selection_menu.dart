import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class SelectionMenuItem<T> {
  final T value;
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;
  final List<SelectionMenuItem<T>>? subItems;

  const SelectionMenuItem({
    required this.value,
    required this.title,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.subItems,
  });

  SelectionMenu<T>? get subItemsSelectionMenu =>
      subItems == null ? null : SelectionMenu<T>(title, subItems!);
}

class SelectionMenu<T> {
  final String title;
  final List<SelectionMenuItem<T>> options;

  const SelectionMenu(this.title, this.options);

  Future<T?> askSelection(BuildContext context, T? oldSelection) async =>
      showModalBottomSheet<T>(
        context: context,
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...options.map(
                      (option) => ListTile(
                        title: Text(option.title),
                        onTap: () => context.router.pop(option.value),
                        leading: Icon(option.icon, color: option.iconColor),
                        selected: oldSelection == option.value,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.2),
                        subtitle: option.subtitle != null
                            ? Text(option.subtitle!)
                            : null,
                        trailing:
                            option.subItems != null &&
                                option.subItems!.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.arrow_right),
                                onPressed: () async {
                                  final subSelection = await option
                                      .subItemsSelectionMenu!
                                      .askSelection(context, oldSelection);
                                  if (!context.mounted) return;
                                  context.router.pop(subSelection);
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      );

  SelectionMenuItem<T> getOption(T value) {
    for (final option in options) {
      if (option.subItems == null) continue;
      try {
        return option.subItemsSelectionMenu!.getOption(value);
      } catch (_) {}
    }
    return options.firstWhere((option) => option.value == value);
  }
}
