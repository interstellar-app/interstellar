import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/account/account_screen.dart';
import 'package:interstellar/src/screens/account/notification/notification_badge.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/settings/settings_screen.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/utils.dart';
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

  void _changeNav(int newIndex) {
    setState(() {
      _navIndex = newIndex;
    });
    _pageController.jumpToPage(_navIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    ac.refreshState = () {
      setState(() {
        _feedKey = UniqueKey();
        _exploreKey = UniqueKey();
        _accountKey = UniqueKey();
      });
    };

    final notCompact = !Breakpoints.isCompact(context);

    return Scaffold(
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
                  icon: Wrapper(
                    shouldWrap: context.watch<AppController>().isLoggedIn,
                    parentBuilder: (child) => NotificationBadge(child: child),
                    child: const Icon(Symbols.person_rounded),
                  ),
                  selectedIcon: Wrapper(
                    shouldWrap: context.watch<AppController>().isLoggedIn,
                    parentBuilder: (child) => NotificationBadge(child: child),
                    child: const Icon(Symbols.person_rounded, fill: 1),
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
                  icon: Wrapper(
                    shouldWrap: context.watch<AppController>().isLoggedIn,
                    parentBuilder: (child) => NotificationBadge(child: child),
                    child: const Icon(Symbols.person_rounded),
                  ),
                  selectedIcon: Wrapper(
                    shouldWrap: context.watch<AppController>().isLoggedIn,
                    parentBuilder: (child) => NotificationBadge(child: child),
                    child: const Icon(Symbols.person_rounded, fill: 1),
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
                FeedScreen(key: _feedKey),
                ExploreScreen(key: _exploreKey),
                AccountScreen(key: _accountKey),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
