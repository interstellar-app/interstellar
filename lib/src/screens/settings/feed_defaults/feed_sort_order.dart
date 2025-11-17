import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';

class FeedSortOrderSettingsScreen extends StatefulWidget {
  const FeedSortOrderSettingsScreen({super.key});

  @override
  State<FeedSortOrderSettingsScreen> createState() =>
      _FeedSortOrderSettingsScreen();
}

class _FeedSortOrderSettingsScreen extends State<FeedSortOrderSettingsScreen> {
  late List<FeedSort> _feedSortOrder;

  @override
  void initState() {
    super.initState();
    _feedSortOrder = context
        .read<AppController>()
        .profile
        .feedSortOrder
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_feedSortOrder),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _feedSortOrder = ProfileRequired.defaultProfile.feedSortOrder
                  .toList();
              ac.updateProfile(
                ac.selectedProfileValue.copyWith(feedSortOrder: _feedSortOrder),
              );
            }),
            icon: const Icon(Symbols.restore),
          ),
        ],
      ),
      body: ReorderableListView(
        children: _feedSortOrder
            .mapIndexed(
              (index, item) => ListTile(
                key: Key(item.index.toString()),
                leading: Icon(item.icon),
                title: Text(item.name.capitalize),
                trailing: Platform.isIOS || Platform.isAndroid
                    ? const Icon(Symbols.drag_handle_rounded)
                    : null,
              ),
            )
            .toList(),
        onReorder: (int oldIndex, int newIndex) => setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _feedSortOrder.removeAt(oldIndex);
          _feedSortOrder.insert(newIndex, item);
          ac.updateProfile(
            ac.selectedProfileValue.copyWith(feedSortOrder: _feedSortOrder),
          );
        }),
      ),
    );
  }
}
