import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:interstellar/emojis/emoji_class.dart';
import 'package:interstellar/emojis/emojis.g.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/debouncer.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

final emojiGroupIcons = [
  Symbols.emoji_emotions_rounded,
  Symbols.emoji_people_rounded,
  Symbols.invert_colors_rounded,
  Symbols.emoji_nature_rounded,
  Symbols.emoji_food_beverage_rounded,
  Symbols.emoji_transportation_rounded,
  Symbols.emoji_events_rounded,
  Symbols.emoji_objects_rounded,
  Symbols.emoji_symbols_rounded,
  Symbols.emoji_flags_rounded,
  Symbols.tune_rounded,
];

class EmojiPicker extends StatefulWidget {
  const EmojiPicker({super.key});

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  final FocusNode _buttonFocusNode = FocusNode();
  final _searchController = TextEditingController();
  final _searchDebounce = Debouncer(
    duration: const Duration(milliseconds: 250),
  );
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _emojiGroupGlobalKeys = [];
  Set<int> _visibleEmojiGroups = {0};

  List<List<Emoji>> _emojis = searchEmojis('');

  void _scrollToEmojiGroup(int emojiGroup) {
    final context = _emojiGroupGlobalKeys[emojiGroup].currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: context.read<AppController>().calcAnimationDuration(),
      curve: Curves.easeInOut,
    );
  }

  void _calculateVisibleEmojiGroups() {
    Set<int> newVisibleEmojiGroups = {};

    final viewportStart = _scrollController.offset;
    final viewportEnd =
        viewportStart + _scrollController.position.viewportDimension;

    final List<double?> groupPositions = _emojiGroupGlobalKeys
        .asMap()
        .entries
        .map((entry) {
          final context = entry.value.currentContext;
          if (context == null) return null;

          final renderObject = context.findRenderObject();
          if (renderObject == null) return null;
          final viewport = RenderAbstractViewport.of(renderObject);

          final reveal = viewport.getOffsetToReveal(renderObject, 0.0);

          return reveal.offset;
        })
        .toList();

    for (var i = 0; i < emojiGroups.length; i++) {
      final currPos = groupPositions[i];
      if (currPos == null) continue;
      double? nextPos;
      for (var j = i + 1; j < emojiGroups.length; j++) {
        nextPos = groupPositions[j];

        if (nextPos != null) break;
      }

      if (currPos >= viewportStart && currPos < viewportEnd ||
          (currPos < viewportStart &&
              (nextPos == null || nextPos > viewportStart))) {
        newVisibleEmojiGroups.add(i);
      }
    }

    if (!setEquals(_visibleEmojiGroups, newVisibleEmojiGroups)) {
      setState(() => _visibleEmojiGroups = newVisibleEmojiGroups);
    }
  }

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < emojiGroups.length; i++) {
      _emojiGroupGlobalKeys.add(GlobalKey());
    }

    _scrollController.addListener(_calculateVisibleEmojiGroups);
  }

  void _searchEmojis() {
    setState(() => _emojis = searchEmojis(_searchController.text));
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _calculateVisibleEmojiGroups(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 40;
    final int buttonsWide = emojiGroups.length;

    final buttonStyle = IconButton.styleFrom(
      // backgroundColor: Colors.red,
      fixedSize: const Size.square(buttonSize),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      builder: (context, controller, child) => IconButton(
        icon: Icon(Symbols.add_reaction_rounded),
        focusNode: _buttonFocusNode,
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      ),
      menuChildren: [
        Card(
          margin: EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Symbols.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _searchController.text.isEmpty
                        ? null
                        : () {
                            _searchController.text = '';
                            _searchEmojis();
                          },
                    icon: Icon(Symbols.close_rounded),
                    disabledColor: Theme.of(context).disabledColor,
                  ),
                  border: const OutlineInputBorder(),
                  hintText: l(context).search,
                ),
                onChanged: (newSearch) => _searchDebounce.run(_searchEmojis),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: emojiGroups
                      .asMap()
                      .entries
                      .map(
                        (group) => IconButton(
                          onPressed: _emojis[group.key].isEmpty
                              ? null
                              : () => _scrollToEmojiGroup(group.key),
                          icon: Icon(
                            emojiGroupIcons[group.key],
                            size: 24,
                            weight: _visibleEmojiGroups.contains(group.key)
                                ? 800
                                : 400,
                          ),
                          color: _visibleEmojiGroups.contains(group.key)
                              ? Theme.of(context).primaryColor
                              : null,
                          style: buttonStyle,
                          tooltip: group.value,
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(
                width: buttonSize * buttonsWide,
                height: 300,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    for (
                      var groupIndex = 0;
                      groupIndex < emojiGroups.length;
                      groupIndex++
                    )
                      if (_emojis[groupIndex].isNotEmpty) ...[
                        SliverToBoxAdapter(
                          key: _emojiGroupGlobalKeys[groupIndex],
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              emojiGroups[groupIndex],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: buttonsWide,
                              ),
                          itemCount: _emojis[groupIndex].length,
                          itemBuilder: (context, index) {
                            final emoji = _emojis[groupIndex][index];

                            return IconButton(
                              onPressed: () {},
                              icon: Text(
                                emoji.unicode,
                                style: TextStyle(fontSize: 24),
                              ),
                              style: buttonStyle,
                              tooltip: emoji.label,
                            );
                          },
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}
