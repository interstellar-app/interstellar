import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class BehaviorSettingsScreen extends StatelessWidget {
  const BehaviorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final customLanguageFilterEnabled =
        ac.serverSoftware == ServerSoftware.mbin &&
            !ac.profile.useAccountLanguageFilter;

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_behavior),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Symbols.translate_rounded),
            title: Text(l(context).settings_defaultPostLanguage),
            subtitle:
                Text(getLanguageName(context, ac.profile.defaultPostLanguage)),
            onTap: () async {
              final langCode = await languageSelectionMenu(context)
                  .askSelection(
                      context, ac.selectedProfileValue.defaultPostLanguage);

              if (langCode == null) return;

              ac.updateProfile(
                ac.selectedProfileValue.copyWith(defaultPostLanguage: langCode),
              );
            },
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.filter_list_rounded),
            title: Text(l(context).settings_useAccountLanguageFilter),
            subtitle: Text(l(context).settings_useAccountLanguageFilter_help),
            value: ac.profile.useAccountLanguageFilter,
            onChanged: ac.serverSoftware != ServerSoftware.mbin
                ? null
                : (newValue) => ac.updateProfile(
                      ac.selectedProfileValue
                          .copyWith(useAccountLanguageFilter: newValue),
                    ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l(context).settings_customLanguageFilter,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: customLanguageFilterEnabled
                          ? null
                          : Theme.of(context).disabledColor),
                ),
              ),
              Flexible(
                child: Wrap(
                  children: [
                    ...(ac.profile.customLanguageFilter.map(
                      (langCode) => Padding(
                        padding: const EdgeInsets.all(2),
                        child: InputChip(
                          isEnabled: customLanguageFilterEnabled,
                          label: Text(getLanguageName(context, langCode)),
                          onDeleted: () async {
                            final newLanguageFilter =
                                ac.profile.customLanguageFilter.toSet();

                            newLanguageFilter.remove(langCode);

                            ac.updateProfile(
                              ac.selectedProfileValue.copyWith(
                                  customLanguageFilter:
                                      newLanguageFilter.toList()),
                            );
                          },
                        ),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: IconButton(
                        onPressed: !customLanguageFilterEnabled
                            ? null
                            : () async {
                                final langCode =
                                    await languageSelectionMenu(context)
                                        .askSelection(context, null);

                                if (langCode == null) return;

                                final newLanguageFilter =
                                    ac.profile.customLanguageFilter.toSet();

                                newLanguageFilter.add(langCode);

                                ac.updateProfile(
                                  ac.selectedProfileValue.copyWith(
                                      customLanguageFilter:
                                          newLanguageFilter.toList()),
                                );
                              },
                        icon: const Icon(Icons.add),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.tabs_rounded),
            title: Text(l(context).settings_disableTabSwiping),
            value: ac.profile.disableTabSwiping,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(disableTabSwiping: newValue),
            ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.person_remove_rounded),
            title: Text(l(context).settings_askBeforeUnsubscribing),
            value: ac.profile.askBeforeUnsubscribing,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .copyWith(askBeforeUnsubscribing: newValue),
            ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.delete_rounded),
            title: Text(l(context).settings_askBeforeDeleting),
            value: ac.profile.askBeforeDeleting,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(askBeforeDeleting: newValue),
            ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.play_arrow_rounded),
            title: Text(l(context).settings_autoPlayVideos),
            value: ac.profile.autoPlayVideos,
            onChanged: (newValue) => ac.updateProfile(
                ac.selectedProfileValue.copyWith(autoPlayVideos: newValue)),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.vibration_rounded),
            title: Text(l(context).settings_hapticFeedback),
            value: ac.profile.hapticFeedback,
            onChanged: (newValue) => ac.updateProfile(
                ac.selectedProfileValue.copyWith(hapticFeedback: newValue)),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.translate_rounded),
            title: Text(l(context).settings_autoTranslate),
            value: ac.profile.autoTranslate,
            onChanged: (newValue) => ac.updateProfile(
                ac.selectedProfileValue.copyWith(autoTranslate: newValue)),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.playlist_add_check_rounded),
            title: Text(l(context).settings_markThreadsReadOnScroll),
            value: ac.profile.markThreadsReadOnScroll,
            onChanged: (newValue) => ac.updateProfile(ac.selectedProfileValue
                .copyWith(markThreadsReadOnScroll: newValue)),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.playlist_add_check_rounded),
            title: Text(l(context).settings_markMicroblogsReadOnScroll),
            value: ac.profile.markMicroblogsReadOnScroll,
            onChanged: (newValue) => ac.updateProfile(ac.selectedProfileValue
                .copyWith(markMicroblogsReadOnScroll: newValue)),
          ),
        ],
      ),
    );
  }
}
