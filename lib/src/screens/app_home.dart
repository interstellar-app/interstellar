import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/screens/account/notification/notification_badge.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart'
    show ExploreType;
import 'package:interstellar/src/screens/settings/account_selection.dart';
import 'package:interstellar/src/screens/settings/profile_selection.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AppInstanceScreen extends StatelessWidget {
  const AppInstanceScreen({
    @PathParam('instance') required this.instance,
    super.key,
  });

  final String instance;

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}

@RoutePage()
class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int _navIndex = 0;
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
            context.router.push(
              ExploreRoute(
                mode: ExploreType.people,
                title: l(context).newChat,
                onTap: (selected, item) async {
                  context.router.pop();
                  context.router.push(
                    MessageThreadRoute(userId: item.id, otherUser: item),
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
  }

  Future<void> _handleExit(bool didPop, result) async {
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
    final ac = context.read<AppController>();
    ac.refreshState = () {
      setState(() {
        _feedKey = UniqueKey();
        _exploreKey = UniqueKey();
        _accountKey = UniqueKey();
        _inboxKey = UniqueKey();
      });
      context.router.root.replace(AppInstanceRoute(instance: ac.instanceHost));
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleExit,
      child: AutoTabsRouter(
        routes: [
          HomeRoute(key: _feedKey, scrollController: _feedScrollController),
          ExploreTab(key: _exploreKey, focusNode: _exploreFocusNode),
          SelfFeed(key: _accountKey),
          InboxRoute(key: _inboxKey),
          const SettingsRoute(),
        ],
        homeIndex: 0,
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          final notCompact = !Breakpoints.isCompact(context);

          return Scaffold(
            body: notCompact
                ? Row(
                    children: [
                      NavigationRail(
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(Symbols.home_rounded),
                            selectedIcon: const Icon(
                              Symbols.home_rounded,
                              fill: 1,
                            ),
                            label: Text(l(context).feed),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Symbols.explore_rounded),
                            selectedIcon: const Icon(
                              Symbols.explore_rounded,
                              fill: 1,
                            ),
                            label: Text(l(context).explore),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Symbols.person_rounded),
                            selectedIcon: const Icon(
                              Symbols.person_rounded,
                              fill: 1,
                            ),
                            label: Text(l(context).account),
                          ),
                          NavigationRailDestination(
                            icon: Wrapper(
                              shouldWrap: context
                                  .watch<AppController>()
                                  .isLoggedIn,
                              parentBuilder: (child) =>
                                  NotificationBadge(child: child),
                              child: const Icon(Symbols.inbox_rounded),
                            ),
                            selectedIcon: Wrapper(
                              shouldWrap: context
                                  .watch<AppController>()
                                  .isLoggedIn,
                              parentBuilder: (child) =>
                                  NotificationBadge(child: child),
                              child: const Icon(Symbols.inbox_rounded, fill: 1),
                            ),
                            label: Text(l(context).inbox),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Symbols.settings_rounded),
                            selectedIcon: const Icon(
                              Symbols.settings_rounded,
                              fill: 1,
                            ),
                            label: Text(l(context).settings),
                          ),
                        ],
                        selectedIndex: tabsRouter.activeIndex,
                        onDestinationSelected: (index) {
                          _changeNav(index);
                          tabsRouter.setActiveIndex(index);
                        },
                        labelType: NavigationRailLabelType.all,
                      ),
                      Expanded(child: child),
                    ],
                  )
                : child,
            bottomNavigationBar: notCompact
                ? null
                : NavigationBar(
                    height: 56,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                    selectedIndex: tabsRouter.activeIndex,
                    onDestinationSelected: (index) {
                      _changeNav(index);
                      tabsRouter.setActiveIndex(index);
                    },
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Symbols.home_rounded),
                        selectedIcon: const Icon(Symbols.home_rounded, fill: 1),
                        label: l(context).feed,
                      ),
                      NavigationDestination(
                        icon: const Icon(Symbols.explore_rounded),
                        selectedIcon: const Icon(
                          Symbols.explore_rounded,
                          fill: 1,
                        ),
                        label: l(context).explore,
                      ),
                      NavigationDestination(
                        icon: const Icon(Symbols.person_rounded),
                        selectedIcon: const Icon(
                          Symbols.person_rounded,
                          fill: 1,
                        ),
                        label: l(context).account,
                      ),
                      NavigationDestination(
                        icon: Wrapper(
                          shouldWrap: context.watch<AppController>().isLoggedIn,
                          parentBuilder: (child) =>
                              NotificationBadge(child: child),
                          child: const Icon(Symbols.inbox_rounded),
                        ),
                        selectedIcon: Wrapper(
                          shouldWrap: context.watch<AppController>().isLoggedIn,
                          parentBuilder: (child) =>
                              NotificationBadge(child: child),
                          child: const Icon(Symbols.inbox_rounded, fill: 1),
                        ),
                        label: l(context).inbox,
                      ),
                      NavigationDestination(
                        icon: const Icon(Symbols.settings_rounded),
                        selectedIcon: const Icon(
                          Symbols.settings_rounded,
                          fill: 1,
                        ),
                        label: l(context).settings,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
