import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:interstellar/src/app_home.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/account/notification/notification_count_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/variables.dart';
import 'package:intl/locale.dart' as intl_locale;
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(ac.profile.globalTextScale),
            ),
            child: MaterialApp(
              restorationScopeId: 'app',
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                LocaleNamesLocalizationsDelegate(),
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              onGenerateTitle: (BuildContext context) =>
                  l(context).interstellar,
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
              home: AppHome(),
            ),
          ),
        );
      },
    );
  }
}
