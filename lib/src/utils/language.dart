import 'package:flutter/widgets.dart';
import 'package:interstellar/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';

String getLanguageName(
  BuildContext context,
  String langCode, [
  bool useNativeNames = false,
]) => langCode.isEmpty
    ? l(context).systemLanguage
    : ((useNativeNames
              ? LocaleNamesLocalizationsDelegate.nativeLocaleNames[langCode]
              : LocaleNames.of(context)!.nameOf(langCode)) ??
          langCode);

SelectionMenu<String> languageSelectionMenu(BuildContext context) =>
    SelectionMenu(
      l(context).languages,
      kMaterialSupportedLanguages
          .map(
            (langTag) => SelectionMenuItem(
              value: langTag,
              title: getLanguageName(context, langTag),
            ),
          )
          .toList()
        ..sort((lhs, rhs) => lhs.title.compareTo(rhs.title)),
    );

SelectionMenu<String> languageSelectionMenuAppSupported(BuildContext context) =>
    SelectionMenu(
      l(context).languages,
      [
            '',
            ...AppLocalizations.supportedLocales.map(
              (locale) => locale.toLanguageTag(),
            ),
          ]
          .map(
            (langTag) => SelectionMenuItem(
              value: langTag,
              title: getLanguageName(context, langTag, true),
            ),
          )
          .toList(),
    );
