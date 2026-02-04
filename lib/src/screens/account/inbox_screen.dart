import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/account/messages/messages_screen.dart';
import 'package:interstellar/src/screens/account/notification/notification_badge.dart';
import 'package:interstellar/src/screens/account/notification/notification_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with AutomaticKeepAliveClientMixin<InboxScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
