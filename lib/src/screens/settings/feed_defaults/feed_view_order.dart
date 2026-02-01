import 'package:auto_route/annotations.dart';
import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';

@RoutePage()
class FeedViewOrderSettingsScreen extends StatefulWidget {
  const FeedViewOrderSettingsScreen({super.key});

  @override
  State<FeedViewOrderSettingsScreen> createState() =>
      _FeedViewOrderSettingsScreen();
}

class _FeedViewOrderSettingsScreen extends State<FeedViewOrderSettingsScreen> {
  late List<FeedView> _feedViewOrder;

  @override
  void initState() {
    super.initState();
    _feedViewOrder = context
        .read<AppController>()
        .profile
        .feedViewOrder
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_feedViewOrder),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _feedViewOrder = ProfileRequired.defaultProfile.feedViewOrder
                  .toList();
              ac.updateProfile(
                ac.selectedProfileValue.copyWith(feedViewOrder: null),
              );
            }),
            icon: const Icon(Symbols.restore),
          ),
        ],
      ),
      body: ReorderableListView(
        children: _feedViewOrder
            .mapIndexed(
              (index, item) => ListTile(
                key: Key(item.index.toString()),
                leading: Icon(item.icon),
                title: Text(item.name.capitalize),
                trailing: PlatformIs.mobile
                    ? const Icon(Symbols.drag_handle_rounded)
                    : null,
              ),
            )
            .toList(),
        onReorder: (int oldIndex, int newIndex) => setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _feedViewOrder.removeAt(oldIndex);
          _feedViewOrder.insert(newIndex, item);
          ac.updateProfile(
            ac.selectedProfileValue.copyWith(feedViewOrder: _feedViewOrder),
          );
        }),
      ),
    );
  }
}
