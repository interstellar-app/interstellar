import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:provider/provider.dart';

class DisplayName extends StatelessWidget {
  const DisplayName(this.name, {super.key, this.displayName, this.icon, this.onTap});

  final String name;
  final String? displayName;
  final ImageModel? icon;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    var nameTuple = name.split('@');
    String localName = displayName ?? nameTuple.first;
    String? hostName = nameTuple.length > 1 ? nameTuple[1] : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Avatar(icon!, radius: 14),
          ),
        Flexible(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Text(
                localName +
                    (context.watch<AppController>().profile.alwaysShowInstance
                        ? '@${hostName ?? context.watch<AppController>().instanceHost}'
                        : ''),
                style: Theme.of(context).textTheme.labelLarge,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ),
        if (!context.watch<AppController>().profile.alwaysShowInstance &&
            hostName != null)
          Tooltip(
            message: hostName,
            triggerMode: TooltipTriggerMode.tap,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(2, 3, 3, 3),
              child: Text('@'),
            ),
          ),
      ],
    );
  }
}
