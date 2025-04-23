import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';

enum ActionLocation { hide, appBar, fabTap, fabHold, fabMenu }

enum ActionLocationWithTabs { hide, appBar, fabTap, fabHold, fabMenu, tabs }

class ActionItem {
  final String name;
  final IconData icon;
  final void Function()? callback;
  final ActionLocation? location;
  final Color? color;

  const ActionItem({
    required this.name,
    required this.icon,
    this.callback,
    this.location,
    this.color,
  });

  ActionItem withProps(ActionLocation location, void Function()? callback) =>
      ActionItem(
        name: name,
        icon: icon,
        callback: callback,
        location: location,
        color: color,
      );
}

ActionItem feedActionBackToTop(BuildContext context) => ActionItem(
      name: l(context).action_backToTop,
      icon: Symbols.keyboard_double_arrow_up_rounded,
    );
ActionItem feedActionCreateNew(BuildContext context) => ActionItem(
      name: l(context).action_createNew,
      icon: Symbols.create_rounded,
    );
ActionItem feedActionExpandFab(BuildContext context) => ActionItem(
      name: l(context).action_expandFABMenu,
      icon: Symbols.menu_rounded,
    );
ActionItem feedActionRefresh(BuildContext context) => ActionItem(
      name: l(context).action_refresh,
      icon: Symbols.refresh_rounded,
    );
ActionItem feedActionSetFilter(BuildContext context) => ActionItem(
      name: l(context).action_setFilter,
      icon: Symbols.filter_alt_rounded,
    );
ActionItem feedActionSetSort(BuildContext context) => ActionItem(
      name: l(context).action_setSort,
      icon: Symbols.sort_rounded,
    );
ActionItem feedActionSetView(BuildContext context) => ActionItem(
      name: l(context).action_setView,
      icon: Symbols.tab_rounded,
    );
ActionItem feedActionHideReadPosts(BuildContext context) => ActionItem(
      name: l(context).settings_hideReadPosts,
      icon: Symbols.visibility_off_rounded,
    );
ActionItem feedActionShowReadPosts(BuildContext context) => ActionItem(
  name: l(context).action_showReadPosts,
  icon: Symbols.visibility_rounded,
);

SelectionMenu<ActionLocation> actionLocationSelect(BuildContext context) =>
    SelectionMenu(
      l(context).action_setLocation,
      [
        SelectionMenuItem(
          value: ActionLocation.hide,
          title: l(context).action_hide,
          icon: Symbols.visibility_off_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocation.appBar,
          title: l(context).action_appBar,
          icon: Symbols.web_asset_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocation.fabTap,
          title: l(context).action_fabTap,
          icon: Symbols.touch_app_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocation.fabHold,
          title: l(context).action_fabHold,
          icon: Symbols.touch_app_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocation.fabMenu,
          title: l(context).action_fabMenu,
          icon: Symbols.menu_rounded,
        ),
      ],
    );

SelectionMenu<ActionLocationWithTabs> actionLocationWithTabsSelect(
        BuildContext context) =>
    SelectionMenu(
      l(context).action_setLocation,
      [
        SelectionMenuItem(
          value: ActionLocationWithTabs.hide,
          title: l(context).action_hide,
          icon: Symbols.visibility_off_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocationWithTabs.appBar,
          title: l(context).action_appBar,
          icon: Symbols.web_asset_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocationWithTabs.fabTap,
          title: l(context).action_fabTap,
          icon: Symbols.touch_app_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocationWithTabs.fabHold,
          title: l(context).action_fabHold,
          icon: Symbols.touch_app_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocationWithTabs.fabMenu,
          title: l(context).action_fabMenu,
          icon: Symbols.menu_rounded,
        ),
        SelectionMenuItem(
          value: ActionLocationWithTabs.tabs,
          title: l(context).action_tabs,
          icon: Symbols.tab_rounded,
        ),
      ],
    );

enum SwipeAction {
  upvote,
  downvote,
  boost,
  bookmark,
  reply,
  markAsRead,
  moderatePin,
  moderateMarkNSFW,
  moderateDelete,
  moderateBan
}

ActionItem swipeActionUpvote(BuildContext context) => ActionItem(
      name: l(context).action_upvote,
      icon: Symbols.arrow_upward_rounded,
      color: Colors.green,
    );
ActionItem swipeActionDownvote(BuildContext context) => ActionItem(
      name: l(context).action_downvote,
      icon: Symbols.arrow_downward_rounded,
      color: Colors.red,
    );
ActionItem swipeActionBoost(BuildContext context) => ActionItem(
      name: l(context).action_boost,
      icon: Symbols.rocket_launch_rounded,
      color: Colors.purple,
    );
ActionItem swipeActionBookmark(BuildContext context) => ActionItem(
      name: l(context).action_bookmark,
      icon: Symbols.bookmark,
      color: Colors.yellow,
    );
ActionItem swipeActionReply(BuildContext context) => ActionItem(
      name: l(context).action_reply,
      icon: Symbols.reply_rounded,
      color: Colors.cyanAccent,
    );
ActionItem swipeActionMarkRead(BuildContext context) => ActionItem(
      name: l(context).action_markRead,
      icon: Symbols.mark_chat_read,
      color: Colors.amberAccent,
    );
ActionItem swipeActionModeratePin(BuildContext context) => ActionItem(
      name: l(context).action_moderatePin,
      icon: Symbols.push_pin_rounded,
      color: Colors.blue,
    );
ActionItem swipeActionModerateMarkNSFW(BuildContext context) => ActionItem(
      name: l(context).action_moderateMarkNSFW,
      icon: Symbols.stop_circle_rounded,
      color: Colors.pink,
    );
ActionItem swipeActionModerateDelete(BuildContext context) => ActionItem(
      name: l(context).action_moderateDelete,
      icon: Symbols.delete_rounded,
      color: Colors.black,
    );
ActionItem swipeActionModerateBan(BuildContext context) => ActionItem(
      name: l(context).action_moderateBan,
      icon: Symbols.block_rounded,
      color: Colors.orange,
    );

SelectionMenu<SwipeAction> swipeActionSelect(BuildContext context) =>
    SelectionMenu(
      'Swipe Action',
      [
        SelectionMenuItem(
          value: SwipeAction.upvote,
          title: l(context).action_upvote,
          icon: Symbols.arrow_upward_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.downvote,
          title: l(context).action_downvote,
          icon: Symbols.arrow_downward_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.boost,
          title: l(context).action_boost,
          icon: Symbols.rocket_launch_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.bookmark,
          title: l(context).action_bookmark,
          icon: Symbols.bookmark,
        ),
        SelectionMenuItem(
          value: SwipeAction.reply,
          title: l(context).action_reply,
          icon: Symbols.reply_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.markAsRead,
          title: l(context).action_markRead,
          icon: Symbols.mark_chat_read,
        ),
        SelectionMenuItem(
          value: SwipeAction.moderatePin,
          title: l(context).action_moderatePin,
          icon: Symbols.push_pin_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.moderateMarkNSFW,
          title: l(context).action_moderateMarkNSFW,
          icon: Symbols.stop_circle_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.moderateDelete,
          title: l(context).action_moderateDelete,
          icon: Symbols.delete_rounded,
        ),
        SelectionMenuItem(
          value: SwipeAction.moderateBan,
          title: l(context).action_moderateBan,
          icon: Symbols.block_rounded,
        ),
      ],
    );
