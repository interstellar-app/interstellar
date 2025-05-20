import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/account/account_screen.dart';
import 'package:interstellar/src/screens/account/notification/notification_badge.dart';
import 'package:interstellar/src/screens/account/notification/notification_count_controller.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/settings/settings_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/variables.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:intl/locale.dart' as intl_locale;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
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

    final intlLocale = intl_locale.Locale.tryParse(ac.profile.appLanguage);

    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        final dynamicLightColorScheme =
            ac.profile.colorScheme == FlexScheme.custom
            ? lightColorScheme
            : null;
        final dynamicDarkColorScheme =
            ac.profile.colorScheme == FlexScheme.custom
            ? darkColorScheme
            : null;

        return ChangeNotifierProxyProvider<
          AppController,
          NotificationCountController
        >(
          create: (_) => NotificationCountController(),
          update: (_, ac, notificationCountController) =>
              notificationCountController!..updateAppController(ac),
          child: MaterialApp(
            restorationScopeId: 'app',
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              LocaleNamesLocalizationsDelegate(),
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateTitle: (BuildContext context) => l(context).interstellar,
            locale: intlLocale == null
                ? null
                : Locale.fromSubtags(
                    languageCode: intlLocale.languageCode,
                    countryCode: intlLocale.countryCode,
                    scriptCode: intlLocale.scriptCode,
                  ),
            theme: FlexThemeData.light(
              colorScheme: dynamicLightColorScheme,
              scheme: dynamicLightColorScheme != null
                  ? null
                  : ac.profile.colorScheme,
              surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
              blendLevel: 13,
            ),
            darkTheme: FlexThemeData.dark(
              colorScheme: dynamicDarkColorScheme,
              scheme: dynamicDarkColorScheme != null
                  ? null
                  : ac.profile.colorScheme,
              surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
              blendLevel: 13,
              darkIsTrueBlack: ac.profile.enableTrueBlack,
            ),
            themeMode: ac.profile.themeMode,
            scaffoldMessengerKey: scaffoldMessengerKey,
            home: OrientationBuilder(
              builder: (context, orientation) {
                return Scaffold(
                  bottomNavigationBar: orientation == Orientation.portrait
                      ? NavigationBar(
                          height: 56,
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysHide,
                          destinations: [
                            NavigationDestination(
                              label: l(context).feed,
                              icon: const Icon(Symbols.home_rounded),
                              selectedIcon: const Icon(
                                Symbols.home_rounded,
                                fill: 1,
                              ),
                            ),
                            NavigationDestination(
                              label: l(context).explore,
                              icon: const Icon(Symbols.explore_rounded),
                              selectedIcon: const Icon(
                                Symbols.explore_rounded,
                                fill: 1,
                              ),
                            ),
                            NavigationDestination(
                              label: l(context).account,
                              icon: Wrapper(
                                shouldWrap: context
                                    .watch<AppController>()
                                    .isLoggedIn,
                                parentBuilder: (child) =>
                                    NotificationBadge(child: child),
                                child: const Icon(Symbols.person_rounded),
                              ),
                              selectedIcon: Wrapper(
                                shouldWrap: context
                                    .watch<AppController>()
                                    .isLoggedIn,
                                parentBuilder: (child) =>
                                    NotificationBadge(child: child),
                                child: const Icon(
                                  Symbols.person_rounded,
                                  fill: 1,
                                ),
                              ),
                            ),
                            NavigationDestination(
                              label: l(context).settings,
                              icon: const Icon(Symbols.settings_rounded),
                              selectedIcon: const Icon(
                                Symbols.settings_rounded,
                                fill: 1,
                              ),
                            ),
                          ],
                          selectedIndex: _navIndex,
                          onDestinationSelected: _changeNav,
                        )
                      : null,
                  body: Row(
                    children: [
                      if (orientation == Orientation.landscape)
                        NavigationRail(
                          selectedIndex: _navIndex,
                          onDestinationSelected: _changeNav,
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            NavigationRailDestination(
                              label: Text(l(context).feed),
                              icon: const Icon(Symbols.feed_rounded),
                              selectedIcon: const Icon(
                                Symbols.feed_rounded,
                                fill: 1,
                              ),
                            ),
                            NavigationRailDestination(
                              label: Text(l(context).explore),
                              icon: const Icon(Symbols.explore_rounded),
                              selectedIcon: const Icon(
                                Symbols.explore_rounded,
                                fill: 1,
                              ),
                            ),
                            NavigationRailDestination(
                              label: Text(l(context).account),
                              icon: Wrapper(
                                shouldWrap: context
                                    .watch<AppController>()
                                    .isLoggedIn,
                                parentBuilder: (child) =>
                                    NotificationBadge(child: child),
                                child: const Icon(Symbols.person_rounded),
                              ),
                              selectedIcon: Wrapper(
                                shouldWrap: context
                                    .watch<AppController>()
                                    .isLoggedIn,
                                parentBuilder: (child) =>
                                    NotificationBadge(child: child),
                                child: const Icon(
                                  Symbols.person_rounded,
                                  fill: 1,
                                ),
                              ),
                            ),
                            NavigationRailDestination(
                              label: Text(l(context).settings),
                              icon: const Icon(Symbols.settings_rounded),
                              selectedIcon: const Icon(
                                Symbols.settings_rounded,
                                fill: 1,
                              ),
                            ),
                          ],
                        ),
                      if (orientation == Orientation.landscape)
                        const VerticalDivider(thickness: 1, width: 1),
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
              },
            ),
          ),
        );
      },
    );
  }
}
