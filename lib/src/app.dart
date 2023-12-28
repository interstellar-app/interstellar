import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';

import 'screens/feed_screen.dart';
import 'screens/settings/settings_controller.dart';
import 'screens/settings/settings_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _navIndex = 0;

  void _changeNav(int newIndex) {
    setState(() {
      _navIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return ChangeNotifierProvider.value(
          value: widget.settingsController,
          child: MaterialApp(
            restorationScopeId: 'app',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: ThemeData(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: widget.settingsController.themeMode,
            home: OrientationBuilder(
              builder: (context, orientation) {
                return Scaffold(
                  bottomNavigationBar: orientation == Orientation.portrait
                      ? NavigationBar(
                          destinations: const [
                            NavigationDestination(
                                label: 'Feed',
                                icon: Icon(Icons.feed_outlined),
                                selectedIcon: Icon(Icons.feed)),
                            NavigationDestination(
                                label: 'Explore',
                                icon: Icon(Icons.explore_outlined),
                                selectedIcon: Icon(Icons.explore)),
                            NavigationDestination(
                                label: 'Profile',
                                icon: Icon(Icons.person_outlined),
                                selectedIcon: Icon(Icons.person)),
                            NavigationDestination(
                                label: 'Settings',
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings)),
                          ],
                          selectedIndex: _navIndex,
                          onDestinationSelected: _changeNav,
                        )
                      : null,
                  body: Row(children: [
                    if (orientation == Orientation.landscape)
                      NavigationRail(
                        selectedIndex: _navIndex,
                        onDestinationSelected: _changeNav,
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                              label: Text('Feed'),
                              icon: Icon(Icons.feed_outlined),
                              selectedIcon: Icon(Icons.feed)),
                          NavigationRailDestination(
                              label: Text('Explore'),
                              icon: Icon(Icons.explore_outlined),
                              selectedIcon: Icon(Icons.explore)),
                          NavigationRailDestination(
                              label: Text('Profile'),
                              icon: Icon(Icons.person_outlined),
                              selectedIcon: Icon(Icons.person)),
                          NavigationRailDestination(
                              label: Text('Settings'),
                              icon: Icon(Icons.settings_outlined),
                              selectedIcon: Icon(Icons.settings)),
                        ],
                      ),
                    if (orientation == Orientation.landscape)
                      const VerticalDivider(
                        thickness: 1,
                        width: 1,
                      ),
                    Expanded(
                        child: [
                      const FeedScreen(),
                      const ExploreScreen(),
                      const ProfileScreen(),
                      SettingsScreen(controller: widget.settingsController)
                    ][_navIndex])
                  ]),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
