import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';

class UserStatusIcons extends StatelessWidget {
  final DateTime? cakeDay;
  final bool isBot;

  const UserStatusIcons({
    required this.cakeDay,
    required this.isBot,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    Widget? botWidget;
    Widget? cakeDayWidget;

    if (isBot) {
      botWidget = Tooltip(
        message: l(context).botAccount,
        child: const Icon(Symbols.smart_toy_rounded),
      );
    }

    if (cakeDay == null) {
    } else if (now.difference(cakeDay!).inDays <= 14) {
      cakeDayWidget = Tooltip(
        message: l(context).newUser,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => const LinearGradient(
            transform: GradientRotation(pi / 2),
            stops: [0, 1],
            colors: [
              Colors.green,
              Colors.lightGreen,
            ],
          ).createShader(bounds),
          child: const Icon(Symbols.psychiatry_rounded),
        ),
      );
    } else if (cakeDay!.day == now.day && cakeDay!.month == now.month) {
      cakeDayWidget = Tooltip(
        message: l(context).cakeDay,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => const LinearGradient(
            transform: GradientRotation(pi / 2),
            stops: [0, 0.5, 1],
            colors: [
              Colors.yellow,
              Colors.pink,
              Colors.blue,
            ],
          ).createShader(bounds),
          child: const Icon(Symbols.cake_rounded),
        ),
      );
    }

    return Row(
      children: [
        ?botWidget,
        ?cakeDayWidget,
      ]
          .map((widget) => Padding(
                padding: const EdgeInsets.only(left: 5),
                child: widget,
              ))
          .toList(),
    );
  }
}
