import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/tags/tag_screen.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PostFlairs extends StatefulWidget {
  const PostFlairs({
    super.key,
    required this.flairs,
    required this.availableFlairs,
    required this.onUpdate,
  });

  final List<Tag> flairs;
  final List<Tag> availableFlairs;
  final Function(List<Tag>) onUpdate;

  @override
  State<PostFlairs> createState() => _PostFlairsState();
}

class _PostFlairsState extends State<PostFlairs> {
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _tags = widget.flairs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).editFlairs)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FilledButton(
                onPressed: () => pushRoute(
                  context,
                  builder: (context) => TagsScreen(
                    tags: widget.availableFlairs,
                    onSelect: (tag) async {
                      final flairs = _tags.toList();

                      if (flairs.contains(tag)) return;

                      flairs.add(tag);

                      widget.onUpdate(flairs);

                      if (!mounted) return;
                      setState(() {
                        _tags = flairs;
                      });
                    },
                  ),
                ),
                child: Text(l(context).addFlair),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _tags.length,
            itemBuilder: (context, index) => ListTile(
              title: TagWidget(tag: _tags[index]),
              trailing: IconButton(
                onPressed: () async {
                  final flairs = _tags.toList();
                  flairs.removeAt(index);

                  widget.onUpdate(flairs);

                  setState(() {
                    _tags = flairs;
                  });
                },
                icon: const Icon(Symbols.delete_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
