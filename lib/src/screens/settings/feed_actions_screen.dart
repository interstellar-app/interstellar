import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/actions.dart';
import 'package:interstellar/src/widgets/list_tile_select.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class FeedActionsSettingsScreen extends StatelessWidget {
  const FeedActionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_feedActions)),
      body: ListView(
        children: [
          ListTileSelect(
            title: l(context).action_expandFABMenu,
            icon: Symbols.menu_rounded,
            selectionMenu: actionLocationSelect(context),
            value: ac.profile.feedActionExpandFab,
            oldValue: ac.selectedProfileValue.feedActionExpandFab,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionExpandFab: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_backToTop,
            icon: Symbols.keyboard_double_arrow_up_rounded,
            selectionMenu: actionLocationSelect(context),
            value: ac.profile.feedActionBackToTop,
            oldValue: ac.selectedProfileValue.feedActionBackToTop,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionBackToTop: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_createNew,
            icon: Symbols.create_rounded,
            selectionMenu: actionLocationSelect(context),
            value: ac.profile.feedActionCreateNew,
            oldValue: ac.selectedProfileValue.feedActionCreateNew,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionCreateNew: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_refresh,
            icon: Symbols.refresh_rounded,
            selectionMenu: actionLocationSelect(context),
            value: ac.profile.feedActionRefresh,
            oldValue: ac.selectedProfileValue.feedActionRefresh,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionRefresh: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_setFilter,
            icon: Symbols.filter_alt_rounded,
            selectionMenu: actionLocationWithTabsSelect(context),
            value: ac.profile.feedActionSetFilter,
            oldValue: ac.selectedProfileValue.feedActionSetFilter,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionSetFilter: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_setSort,
            icon: Symbols.sort_rounded,
            selectionMenu: actionLocationWithTabsSelect(context),
            value: ac.profile.feedActionSetSort,
            oldValue: ac.selectedProfileValue.feedActionSetSort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionSetSort: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_setView,
            icon: Symbols.newspaper_rounded,
            selectionMenu: actionLocationWithTabsSelect(context),
            value: ac.profile.feedActionSetView,
            oldValue: ac.selectedProfileValue.feedActionSetView,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionSetView: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).action_markRead,
            icon: Symbols.visibility_off_rounded,
            selectionMenu: actionLocationSelect(context),
            value: ac.profile.feedActionHideReadPosts,
            oldValue: ac.selectedProfileValue.feedActionHideReadPosts,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue
                  .cleanupActions(newValue.name, ac.profile)
                  .copyWith(feedActionHideReadPosts: newValue),
            ),
          ),
          const Divider(),
          ListTileSwitch(
            leading: const Icon(Symbols.swipe),
            title: Text(l(context).settings_enableSwipeActions),
            value: ac.profile.enableSwipeActions,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(enableSwipeActions: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_swipeActionLeftShort,
            icon: Symbols.comment_rounded,
            selectionMenu: swipeActionSelect(context),
            value: ac.profile.swipeActionLeftShort,
            oldValue: ac.selectedProfileValue.swipeActionLeftShort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(swipeActionLeftShort: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_swipeActionLeftLong,
            icon: Symbols.comment_rounded,
            selectionMenu: swipeActionSelect(context),
            value: ac.profile.swipeActionLeftLong,
            oldValue: ac.selectedProfileValue.swipeActionLeftLong,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(swipeActionLeftLong: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_swipeActionRightShort,
            icon: Symbols.comment_rounded,
            selectionMenu: swipeActionSelect(context),
            value: ac.profile.swipeActionRightShort,
            oldValue: ac.selectedProfileValue.swipeActionRightShort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(swipeActionRightShort: newValue),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_swipeActionRightLong,
            icon: Symbols.comment_rounded,
            selectionMenu: swipeActionSelect(context),
            value: ac.profile.swipeActionRightLong,
            oldValue: ac.selectedProfileValue.swipeActionRightLong,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(swipeActionRightLong: newValue),
            ),
          ),
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l(context).settings_swipeThreshold} : '
                  '${ac.profile.swipeActionThreshold.toStringAsFixed(2)}',
                ),
                Slider(
                  value: ac.profile.swipeActionThreshold,
                  onChanged: (newValue) => ac.updateProfile(
                    ac.selectedProfileValue.copyWith(
                      swipeActionThreshold: newValue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
