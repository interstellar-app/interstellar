import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/list_tile_select.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class FeedDefaultSettingsScreen extends StatelessWidget {
  const FeedDefaultSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_feedDefaults)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Symbols.filter_list_rounded),
            title: Text(l(context).settings_feedSourceOrder),
            onTap: () =>
                context.router.push(const FeedSourceOrderSettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.tab_rounded),
            title: Text(l(context).settings_feedViewOrder),
            onTap: () =>
                context.router.push(const FeedViewOrderSettingsRoute()),
          ),
          ListTile(
            leading: const Icon(Symbols.sort_rounded),
            title: Text(l(context).settings_feedSortOrder),
            onTap: () =>
                context.router.push(const FeedSortOrderSettingsRoute()),
          ),
          ListTileSelect(
            title: l(context).settings_feedDefaults_threadsSort,
            icon: Symbols.newsmode_rounded,
            selectionMenu: feedSortSelect(context),
            value: ac.profile.feedDefaultThreadsSort,
            oldValue: ac.selectedProfileValue.feedDefaultThreadsSort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(
                feedDefaultThreadsSort: newValue,
              ),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_feedDefaults_microblogSort,
            icon: Symbols.article_rounded,
            selectionMenu: feedSortSelect(context),
            value: ac.profile.feedDefaultMicroblogSort,
            oldValue: ac.selectedProfileValue.feedDefaultMicroblogSort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(
                feedDefaultMicroblogSort: newValue,
              ),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_feedDefaults_combinedSort,
            icon: Symbols.article_rounded,
            selectionMenu: feedSortSelect(context),
            value: ac.profile.feedDefaultCombinedSort,
            oldValue: ac.selectedProfileValue.feedDefaultCombinedSort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(
                feedDefaultCombinedSort: newValue,
              ),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_feedDefaults_exploreSort,
            icon: Symbols.explore_rounded,
            selectionMenu: feedSortSelect(context),
            value: ac.profile.feedDefaultExploreSort,
            oldValue: ac.selectedProfileValue.feedDefaultExploreSort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(
                feedDefaultExploreSort: newValue,
              ),
            ),
          ),
          ListTileSelect(
            title: l(context).settings_feedDefaults_commentSort,
            icon: Symbols.comment_rounded,
            selectionMenu: commentSortSelect(context),
            value: ac.profile.feedDefaultCommentSort,
            oldValue: ac.selectedProfileValue.feedDefaultCommentSort,
            onChange: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(
                feedDefaultCommentSort: newValue,
              ),
            ),
          ),
          ListTileSwitch(
            leading: const Icon(Symbols.visibility_off_rounded),
            title: Text(l(context).settings_feedDefaults_hideReadPosts),
            value: ac.profile.feedDefaultHideReadPosts,
            onChanged: (newValue) => ac.updateProfile(
              ac.selectedProfileValue.copyWith(
                feedDefaultHideReadPosts: newValue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
