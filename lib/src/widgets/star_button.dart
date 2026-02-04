import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class StarButton extends StatelessWidget {
  const StarButton(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final isStarred = context.watch<AppController>().stars.contains(name);

    return IconButton(
      onPressed: isStarred
          ? () => context.read<AppController>().removeStar(name)
          : () => context.read<AppController>().addStar(name),
      icon: context.read<AppController>().stars.contains(name)
          ? const Icon(Symbols.star_rounded, fill: 1)
          : const Icon(Symbols.star_rounded),
      color: isStarred ? Colors.yellow : null,
    );
  }
}
