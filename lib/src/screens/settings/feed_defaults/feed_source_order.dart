import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';

class FeedSourceOrderSettingsScreen extends StatefulWidget {
  const FeedSourceOrderSettingsScreen({super.key});

  @override
  State<FeedSourceOrderSettingsScreen> createState() =>
      _FeedSourceOrderSettingsScreen();
}

class _FeedSourceOrderSettingsScreen
    extends State<FeedSourceOrderSettingsScreen> {
  late List<FeedSource> _feedSourceOrder;

  @override
  void initState() {
    super.initState();
    _feedSourceOrder = context
        .read<AppController>()
        .profile
        .feedSourceOrder
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_feedSourceOrder),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _feedSourceOrder = ProfileRequired.defaultProfile.feedSourceOrder
                  .toList();
              ac.updateProfile(
                ac.selectedProfileValue.copyWith(
                  feedSourceOrder: _feedSourceOrder,
                ),
              );
            }),
            icon: const Icon(Symbols.restore),
          ),
        ],
      ),
      body: ReorderableListView(
        children: _feedSourceOrder
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
          final item = _feedSourceOrder.removeAt(oldIndex);
          _feedSourceOrder.insert(newIndex, item);
          ac.updateProfile(
            ac.selectedProfileValue.copyWith(feedSourceOrder: _feedSourceOrder),
          );
        }),
      ),
    );
  }
}
