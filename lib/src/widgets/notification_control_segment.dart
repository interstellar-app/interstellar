import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class NotificationControlSegment extends StatelessWidget {
  final NotificationControlStatus value;
  final Future<void> Function(NotificationControlStatus) onChange;

  const NotificationControlSegment(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<NotificationControlStatus>(
      segments: [
        // Mbin allows muted notification status, but PieFed does not
        if (context.read<AppController>().serverSoftware == ServerSoftware.mbin)
          ButtonSegment(
            value: NotificationControlStatus.muted,
            icon: const Icon(Symbols.notifications_off_rounded),
            tooltip: l(context).notificationControlStatus_muted,
          ),
        ButtonSegment(
          value: NotificationControlStatus.default_,
          icon: const Icon(Symbols.notifications_rounded),
          tooltip: l(context).notificationControlStatus_default,
        ),
        ButtonSegment(
          value: NotificationControlStatus.loud,
          icon: const Icon(Symbols.campaign_rounded),
          tooltip: l(context).notificationControlStatus_loud,
        ),
      ],
      selected: {value},
      onSelectionChanged: (newSelection) {
        onChange(newSelection.first);
      },
      showSelectedIcon: false,
    );
  }
}
