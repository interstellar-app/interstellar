import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/account/messages/messages_screen.dart';
import 'package:interstellar/src/screens/account/notification/notification_badge.dart';
import 'package:interstellar/src/screens/account/notification/notification_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key, this.placeholder = false});

  // This is so the generated route includes parameters so that a key can be passed.
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return whenLoggedIn(
          context,
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(context.watch<AppController>().selectedAccount),
                bottom: TabBar(
                  tabs: [
                    Tab(
                      text: l(context).notifications,
                      icon: const NotificationBadge(
                        child: Icon(Symbols.notifications_rounded),
                      ),
                    ),
                    Tab(
                      text: l(context).messages,
                      icon: const Icon(Symbols.message_rounded),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                physics: appTabViewPhysics(context),
                children: const [NotificationsScreen(), MessagesScreen()],
              ),
            ),
          ),
        ) ??
        Center(child: Text(l(context).notLoggedIn));
  }
}
