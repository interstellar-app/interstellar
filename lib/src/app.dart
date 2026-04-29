import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:interstellar/l10n/app_localizations.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/account/notification/notification_count_controller.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/instances.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:intl/locale.dart' as intl_locale;
import 'package:provider/provider.dart';

final router = AppRouter();

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
            child: MaterialApp.router(
              routerConfig: router.config(
                deepLinkTransformer: (link) async {
                  final knownInstance = knownInstances[link.host];
                  if (knownInstance == null) return SynchronousFuture(link);

                  // Ensure item is federated to current instance.
                  final item = await ac.api.search.resolveObject(
                    link.toString(),
                  );

                  // Construct interstellar compatible uri.
                  final newUri = switch (item) {
                    final PostModel p => Uri.parse(
                      '/${ac.instanceHost}/c/${p.community.name}/${p.type == PostType.thread ? 'thread' : 'microblog'}/${p.id}',
                    ),
                    final CommentModel c => Uri.parse(
                      '/${ac.instanceHost}/comment/${c.id}',
                    ),
                    final DetailedUserModel u => Uri.parse(
                      '/${ac.instanceHost}/u/${u.name}',
                    ),
                    final DetailedCommunityModel c => Uri.parse(
                      '/${ac.instanceHost}/c/${c.name}',
                    ),
                    Object() => link,
                    null => link,
                  };

                  return SynchronousFuture(newUri);
                },
              ),
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
              themeAnimationDuration: ac.calcAnimationDuration(),
              scaffoldMessengerKey: scaffoldMessengerKey,
            ),
          ),
        );
      },
    );
  }
}
