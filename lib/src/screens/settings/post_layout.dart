import 'dart:io';
import 'package:auto_route/annotations.dart';
import 'package:collection/collection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/widgets/content_item/content_item.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';

@RoutePage()
class PostLayoutSettingsScreen extends StatefulWidget {
  const PostLayoutSettingsScreen({super.key});

  @override
  State<PostLayoutSettingsScreen> createState() => _PostLayoutSettingsScreen();
}

class _PostLayoutSettingsScreen extends State<PostLayoutSettingsScreen> {
  late List<PostComponent> _postComponentOrder;

  @override
  void initState() {
    super.initState();
    _postComponentOrder = context
        .read<AppController>()
        .profile
        .postComponentOrder
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_postLayoutOrder),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _postComponentOrder = ProfileRequired
                  .defaultProfile
                  .postComponentOrder
                  .toList();
              ac.updateProfile(
                ac.selectedProfileValue.copyWith(postComponentOrder: null),
              );
            }),
            icon: const Icon(Symbols.restore),
          ),
        ],
      ),
      body: ReorderableListView(
        children: _postComponentOrder
            .mapIndexed(
              (index, item) => ListTile(
                key: Key(item.index.toString()),
                leading: Icon(switch (item) {
                  PostComponent.title => Symbols.title_rounded,
                  PostComponent.image => Symbols.image_rounded,
                  PostComponent.info => Symbols.info_rounded,
                  PostComponent.body => Symbols.article_rounded,
                  PostComponent.link => Symbols.link_rounded,
                  PostComponent.flairs => Symbols.flag_rounded,
                }),
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
          final item = _postComponentOrder.removeAt(oldIndex);
          _postComponentOrder.insert(newIndex, item);
          ac.updateProfile(
            ac.selectedProfileValue.copyWith(
              postComponentOrder: _postComponentOrder,
            ),
          );
        }),
      ),
    );
  }
}
