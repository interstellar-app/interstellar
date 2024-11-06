import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_display),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Symbols.bedtime_rounded, fill: 0),
            title: Text(l(context).settings_themeMode),
            subtitle: Text(
                themeModeSelect(context).getOption(ac.profile.themeMode).title),
            onTap: () async {
              final themeMode = await themeModeSelect(context)
                  .askSelection(context, ac.selectedProfileValue.themeMode);

              if (themeMode == null) return;

              ac.updateProfile(
                ac.selectedProfileValue.copyWith(themeMode: themeMode),
              );
            },
          ),
          ListTile(
            leading: const Icon(Symbols.palette_rounded, fill: 0),
            title: Text(l(context).settings_colorScheme),
            subtitle:
                Text(colorSchemeNameMap(context)[ac.profile.colorScheme]!),
            onTap: () async {
              final colorScheme = await colorSchemeSelect(context)
                  .askSelection(context, ac.selectedProfileValue.colorScheme);

              if (colorScheme == null) return;

              ac.updateProfile(
                ac.selectedProfileValue.copyWith(colorScheme: colorScheme),
              );
            },
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.contrast_rounded, fill: 0),
            title: Text(l(context).settings_enableTrueBlack),
            subtitle: Text(l(context).settings_enableTrueBlack_help),
            value: ac.profile.enableTrueBlack,
            onChanged: ac.profile.themeMode == ThemeMode.light
                ? null
                : (newValue) => ac.updateProfile(
                      ac.selectedProfileValue
                          .copyWith(enableTrueBlack: newValue),
                    ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.view_agenda_rounded, fill: 0),
            title: Text(l(context).settings_compactMode),
            value: ac.profile.compactMode,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(compactMode: newValue),
            ),
          ),
          const Divider(),
          ListTileSwitch(
            leading: const Icon(Symbols.globe, fill: 0),
            title: Text(l(context).settings_alwaysShowInstance),
            subtitle: Text(l(context).settings_alwaysShowInstance_help),
            value: ac.profile.alwaysShowInstance,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(alwaysShowInstance: newValue),
            ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.warning_rounded, fill: 0),
            title: Text(l(context).settings_alwaysRevealContentWarnings),
            value: ac.profile.alwaysRevealContentWarnings,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .copyWith(alwaysRevealContentWarnings: newValue),
            ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.flag_2_rounded, fill: 0),
            title: Text(l(context).settings_coverMediaMarkedSensitive),
            value: ac.profile.coverMediaMarkedSensitive,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .copyWith(coverMediaMarkedSensitive: newValue),
            ),
          ),
        ],
      ),
    );
  }
}

SelectionMenu<ThemeMode> themeModeSelect(BuildContext context) => SelectionMenu(
      l(context).settings_themeMode,
      [
        SelectionMenuItem(
          value: ThemeMode.system,
          title: l(context).settings_themeMode_system,
          icon: Icons.auto_mode,
        ),
        SelectionMenuItem(
          value: ThemeMode.light,
          title: l(context).settings_themeMode_light,
          icon: Icons.light_mode,
        ),
        SelectionMenuItem(
          value: ThemeMode.dark,
          title: l(context).settings_themeMode_dark,
          icon: Icons.dark_mode,
        ),
      ],
    );

Map<FlexScheme, String> colorSchemeNameMap(BuildContext context) => {
      FlexScheme.custom: l(context).settings_colorScheme_dynamic,
      FlexScheme.blue: l(context).settings_colorScheme_blue,
      FlexScheme.indigo: l(context).settings_colorScheme_indigo,
      FlexScheme.hippieBlue: l(context).settings_colorScheme_hippieBlue,
      FlexScheme.aquaBlue: l(context).settings_colorScheme_aquaBlue,
      FlexScheme.brandBlue: l(context).settings_colorScheme_brandBlue,
      FlexScheme.deepBlue: l(context).settings_colorScheme_deepBlue,
      FlexScheme.sakura: l(context).settings_colorScheme_sakura,
      FlexScheme.mandyRed: l(context).settings_colorScheme_mandyRed,
      FlexScheme.red: l(context).settings_colorScheme_red,
      FlexScheme.redWine: l(context).settings_colorScheme_redWine,
      FlexScheme.purpleBrown: l(context).settings_colorScheme_purpleBrown,
      FlexScheme.green: l(context).settings_colorScheme_green,
      FlexScheme.money: l(context).settings_colorScheme_money,
      FlexScheme.jungle: l(context).settings_colorScheme_jungle,
      FlexScheme.greyLaw: l(context).settings_colorScheme_greyLaw,
      FlexScheme.wasabi: l(context).settings_colorScheme_wasabi,
      FlexScheme.gold: l(context).settings_colorScheme_gold,
      FlexScheme.mango: l(context).settings_colorScheme_mango,
      FlexScheme.amber: l(context).settings_colorScheme_amber,
      FlexScheme.vesuviusBurn: l(context).settings_colorScheme_vesuviusBurn,
      FlexScheme.deepPurple: l(context).settings_colorScheme_deepPurple,
      FlexScheme.ebonyClay: l(context).settings_colorScheme_ebonyClay,
      FlexScheme.barossa: l(context).settings_colorScheme_barossa,
      FlexScheme.shark: l(context).settings_colorScheme_shark,
      FlexScheme.bigStone: l(context).settings_colorScheme_bigStone,
      FlexScheme.damask: l(context).settings_colorScheme_damask,
      FlexScheme.bahamaBlue: l(context).settings_colorScheme_bahamaBlue,
      FlexScheme.mallardGreen: l(context).settings_colorScheme_mallardGreen,
      FlexScheme.espresso: l(context).settings_colorScheme_espresso,
      FlexScheme.outerSpace: l(context).settings_colorScheme_outerSpace,
      FlexScheme.blueWhale: l(context).settings_colorScheme_blueWhale,
      FlexScheme.sanJuanBlue: l(context).settings_colorScheme_sanJuanBlue,
      FlexScheme.rosewood: l(context).settings_colorScheme_rosewood,
      FlexScheme.blumineBlue: l(context).settings_colorScheme_blumineBlue,
      FlexScheme.flutterDash: l(context).settings_colorScheme_flutterDash,
    };

SelectionMenu<FlexScheme> colorSchemeSelect(BuildContext context) =>
    SelectionMenu(
      l(context).settings_colorScheme,
      colorSchemeNameMap(context)
          .keys
          .map((colorScheme) => SelectionMenuItem(
                value: colorScheme,
                title: colorSchemeNameMap(context)[colorScheme]!,
                icon: colorScheme == FlexScheme.custom
                    ? Icons.auto_mode
                    : Icons.brightness_1,
                iconColor: colorScheme == FlexScheme.custom
                    ? null
                    : FlexColor.schemesWithCustom[colorScheme]!.light.primary,
              ))
          .toList(),
    );
