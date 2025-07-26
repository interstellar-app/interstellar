import 'package:flutter/material.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:interstellar/src/widgets/loading_list_tile.dart';

class ContextMenuAction {
  final Widget? child;
  final IconData? icon;
  final Future<void> Function()? onTap;

  const ContextMenuAction({this.child, this.icon, this.onTap});
}

class ContextMenuItem {
  final String? title;
  final Widget? child;
  final IconData? icon;
  final double iconFill;
  final Future<void> Function()? onTap;
  final List<ContextMenuItem>? subItems;
  final Widget? trailing;

  const ContextMenuItem({
    this.title,
    this.child,
    this.icon,
    this.iconFill = 0,
    this.onTap,
    this.subItems,
    this.trailing,
  });

  ContextMenu? get subItemsContextMenu =>
      subItems == null ? null : ContextMenu(title: title, items: subItems!);
}

class ContextMenu {
  final String? title;
  final List<ContextMenuAction> actions;
  final List<ContextMenuItem> items;
  final double actionSpacing;

  const ContextMenu({
    this.title,
    this.actions = const [],
    this.items = const [],
    this.actionSpacing = 12,
  });

  Future<void> openMenu(
    BuildContext context,
  ) async => await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: actionSpacing,
              children: actions
                  .map(
                    (action) =>
                        action.child ??
                        LoadingIconButton(
                          icon: Icon(action.icon),
                          onPressed: action.onTap,
                        ),
                  )
                  .toList(),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items
                    .map(
                      (item) => LoadingListTile(
                        title: Text(item.title!),
                        leading: Icon(item.icon, fill: item.iconFill),
                        onTap:
                            item.onTap ??
                            (item.subItems != null && item.subItems!.isNotEmpty
                                ? () => item.subItemsContextMenu!.openMenu(
                                    context,
                                  )
                                : null),
                        trailing:
                            item.trailing ??
                            (item.subItems != null && item.subItems!.isNotEmpty
                                ? IconButton(
                                    onPressed: () async => item
                                        .subItemsContextMenu!
                                        .openMenu(context),
                                    icon: Icon(Symbols.arrow_right_rounded),
                                  )
                                : null),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    },
  );
}
