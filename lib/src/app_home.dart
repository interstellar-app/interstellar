import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/account/inbox_screen.dart';
import 'package:interstellar/src/screens/account/messages/message_thread_screen.dart';
import 'package:interstellar/src/screens/account/notification/notification_badge.dart';
import 'package:interstellar/src/screens/account/self_feed.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/screens/settings/profile_selection.dart';
import 'package:interstellar/src/screens/settings/settings_screen.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int _navIndex = 0;
  final PageController _pageController = PageController();
  Key _feedKey = UniqueKey();
  Key _exploreKey = UniqueKey();
  Key _accountKey = UniqueKey();
  Key _inboxKey = UniqueKey();
  final ScrollController _feedScrollController = ScrollController();
  final FocusNode _exploreFocusNode = FocusNode();
  int _exitCounter = 0;

  void _changeNav(int newIndex) {
    if (newIndex == _navIndex) {
      final ac = context.read<AppController>();

      switch (newIndex) {
        case 0:
          _feedScrollController.animateTo(
            _feedScrollController.position.minScrollExtent,
            duration: Durations.long1,
            curve: Curves.easeInOut,
          );
          return;
        case 1:
          _exploreFocusNode.requestFocus();
          return;
        case 2:
          () async {
            final newAccount = await switchAccount(context);
            if (newAccount == null || newAccount == ac.selectedAccount) {
              return;
            }

            await ac.switchAccounts(newAccount);
          }();
          return;
        case 3:
          if (ac.isLoggedIn) {
            pushRoute(
              context,
              builder: (context) => ExploreScreen(
                mode: ExploreType.people,
                title: l(context).newChat,
                onTap: (selected, item) async {
                  Navigator.pop(context);
                  await pushRoute(
                    context,
                    builder: (context) =>
                        MessageThreadScreen(threadId: null, otherUser: item),
                  );
                },
              ),
            );
          }
        case 4:
          switchProfileSelect(context);
          return;
      }
    }
    setState(() {
      _navIndex = newIndex;
    });
    _pageController.jumpToPage(_navIndex);
  }

  void _handleExit(bool didPop, result) async {
    if (didPop) return;
    if (_navIndex != 0) {
      _changeNav(0);
      return;
    }

    if (_exitCounter == 0) {
      _exitCounter++;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l(context).exitMessage)),
      );
      Timer(const Duration(seconds: 5), () {
        _exitCounter = 0;
      });
    } else if (context.mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    ac.refreshState = () {
      setState(() {
        _feedKey = UniqueKey();
        _exploreKey = UniqueKey();
        _accountKey = UniqueKey();
        _inboxKey = UniqueKey();
      });
    };

    final notCompact = !Breakpoints.isCompact(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleExit,
      child: Scaffold(
        bottomNavigationBar: notCompact
            ? null
            : NavigationBar(
                height: 56,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                destinations: [
                  NavigationDestination(
                    label: l(context).feed,
                    icon: const Icon(Symbols.home_rounded),
                    selectedIcon: const Icon(Symbols.home_rounded, fill: 1),
                  ),
                  NavigationDestination(
                    label: l(context).explore,
                    icon: const Icon(Symbols.explore_rounded),
                    selectedIcon: const Icon(Symbols.explore_rounded, fill: 1),
                  ),
                  NavigationDestination(
                    label: l(context).account,
                    icon: const Icon(Symbols.person_rounded),
                    selectedIcon: const Icon(Symbols.person_rounded, fill: 1),
                  ),
                  NavigationDestination(
                    label: l(context).inbox,
                    icon: Wrapper(
                      shouldWrap: context.watch<AppController>().isLoggedIn,
                      parentBuilder: (child) => NotificationBadge(child: child),
                      child: const Icon(Symbols.inbox_rounded),
                    ),
                    selectedIcon: Wrapper(
                      shouldWrap: context.watch<AppController>().isLoggedIn,
                      parentBuilder: (child) => NotificationBadge(child: child),
                      child: const Icon(Symbols.inbox_rounded, fill: 1),
                    ),
                  ),
                  NavigationDestination(
                    label: l(context).settings,
                    icon: const Icon(Symbols.settings_rounded),
                    selectedIcon: const Icon(Symbols.settings_rounded, fill: 1),
                  ),
                ],
                selectedIndex: _navIndex,
                onDestinationSelected: _changeNav,
              ),
        body: Row(
          children: [
            if (notCompact)
              NavigationRail(
                selectedIndex: _navIndex,
                onDestinationSelected: _changeNav,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    label: Text(l(context).feed),
                    icon: const Icon(Symbols.feed_rounded),
                    selectedIcon: const Icon(Symbols.feed_rounded, fill: 1),
                  ),
                  NavigationRailDestination(
                    label: Text(l(context).explore),
                    icon: const Icon(Symbols.explore_rounded),
                    selectedIcon: const Icon(Symbols.explore_rounded, fill: 1),
                  ),
                  NavigationRailDestination(
                    label: Text(l(context).account),
                    icon: const Icon(Symbols.person_rounded),
                    selectedIcon: const Icon(Symbols.person_rounded, fill: 1),
                  ),
                  NavigationRailDestination(
                    label: Text(l(context).inbox),
                    icon: Wrapper(
                      shouldWrap: context.watch<AppController>().isLoggedIn,
                      parentBuilder: (child) => NotificationBadge(child: child),
                      child: const Icon(Symbols.inbox_rounded),
                    ),
                    selectedIcon: Wrapper(
                      shouldWrap: context.watch<AppController>().isLoggedIn,
                      parentBuilder: (child) => NotificationBadge(child: child),
                      child: const Icon(Symbols.inbox_rounded, fill: 1),
                    ),
                  ),
                  NavigationRailDestination(
                    label: Text(l(context).settings),
                    icon: const Icon(Symbols.settings_rounded),
                    selectedIcon: const Icon(Symbols.settings_rounded, fill: 1),
                  ),
                ],
              ),
            if (notCompact) const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  FeedScreen(
                    key: _feedKey,
                    scrollController: _feedScrollController,
                  ),
                  ExploreScreen(key: _exploreKey, focusNode: _exploreFocusNode),
                  SelfFeed(key: _accountKey),
                  InboxScreen(key: _inboxKey),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
