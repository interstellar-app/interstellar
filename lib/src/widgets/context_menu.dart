import 'package:flutter/material.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
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
  final String? subtitle;
  final Widget? child;
  final IconData? icon;
  final double iconFill;
  final Future<void> Function()? onTap;
  final List<ContextMenuItem>? subItems;
  final Widget? trailing;

  const ContextMenuItem({
    this.title,
    this.subtitle,
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
  final List<Uri> links;
  final List<ContextMenuItem> items;
  final double actionSpacing;

  const ContextMenu({
    this.title,
    this.actions = const [],
    this.links = const [],
    this.items = const [],
    this.actionSpacing = 12,
  });

  Future<void> openMenu(
    BuildContext context,
  ) async => await showModalBottomSheet(
    context: context,
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
          if (links.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: links
                    .map(
                      (link) => Flexible(
                        child: Card.outlined(
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            height: 40,
                            child: InkWell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  link.host,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .apply(
                                        decoration: TextDecoration.underline,
                                      ),
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();

                                openWebpagePrimary(context, link);
                              },
                              onLongPress: () {
                                Navigator.of(context).pop();

                                openWebpageSecondary(context, link);
                              },
                              onSecondaryTap: () {
                                Navigator.of(context).pop();

                                openWebpageSecondary(context, link);
                              },
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ListView(
                shrinkWrap: true,
                children: items
                    .map(
                      (item) => LoadingListTile(
                        title: Text(item.title!),
                        subtitle: item.subtitle != null
                            ? Text(item.subtitle!)
                            : null,
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
