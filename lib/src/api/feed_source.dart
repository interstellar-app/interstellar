import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/controller/server.dart';

enum FeedView {
  threads(icon: Symbols.feed_rounded),
  microblog(software: ServerSoftware.mbinFlag, icon: Symbols.chat_rounded),
  combined(software: ServerSoftware.mbinFlag, icon: Symbols.view_timeline_rounded);

  const FeedView({this.software = ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, this.icon});

  final int software;
  final IconData? icon;

  String title(BuildContext context) => switch (this) {
    FeedView.threads => l(context).threads,
    FeedView.microblog => l(context).microblog,
    FeedView.combined => l(context).combined,
  };

  static List<FeedView> match({
    List<FeedView> values = FeedView.values,
    required int software,
  }) {
    return values.where(
          (item) => (item.software & software) == software,).toList();
  }
}

enum FeedSource {
  all(icon: Symbols.newspaper_rounded),
  local(icon: Symbols.home_pin_rounded),
  subscribed(icon: Symbols.group_rounded),
  moderated(icon: Symbols.lock_rounded),
  favorited(icon: Symbols.favorite_rounded),
  community,
  user,
  domain,
  feed,
  topic;

  const FeedSource({this.icon});

  final IconData? icon;

  String title(BuildContext context) => switch (this) {
    FeedSource.all => l(context).filter_all,
    FeedSource.local => l(context).filter_local,
    FeedSource.subscribed => l(context).filter_subscribed,
    FeedSource.moderated => l(context).filter_moderated,
    FeedSource.favorited => l(context).filter_favorited,
    FeedSource.community => name.capitalize,
    FeedSource.user => name.capitalize,
    FeedSource.domain => name.capitalize,
    FeedSource.feed => name.capitalize,
    FeedSource.topic => name.capitalize,
  };
}

enum FeedSort {
  hot(icon: Symbols.local_fire_department_rounded),
  top(icon: Symbols.trending_up_rounded),
  newest(icon: Symbols.nest_eco_leaf_rounded),
  active(icon: Symbols.rocket_launch_rounded),
  commented(software: ServerSoftware.mbinFlag | ServerSoftware.lemmyFlag, icon: Symbols.chat_rounded),
  oldest(software: ServerSoftware.mbinFlag | ServerSoftware.lemmyFlag, icon: Symbols.access_time_rounded),
  scaled(software: ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, icon: Symbols.scale_rounded),
  newComments(software: ServerSoftware.lemmyFlag, icon: Symbols.mark_chat_unread_rounded),
  controversial(software: ServerSoftware.lemmyFlag, icon: Symbols.thumbs_up_down_rounded),

  topHour(software: ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topThreeHour(software: ServerSoftware.mbinFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topSixHour(software: ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topTwelveHour(software: ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topDay(software: ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topWeek(software: ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topMonth(software: ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topThreeMonths(software: ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topSixMonths(software: ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topNineMonths(software: ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),
  topYear(software: ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag, parent: FeedSort.top, icon: Symbols.trending_up_rounded),

  commentedThreeHour(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded),
  commentedSixHour(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded),
  commentedTwelveHour(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded),
  commentedDay(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded),
  commentedWeek(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded),
  commentedMonth(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded),
  commentedYear(software: ServerSoftware.mbinFlag, parent: FeedSort.commented, icon: Symbols.chat_rounded);

  const FeedSort({
    this.software = ServerSoftware.mbinFlag | ServerSoftware.piefedFlag | ServerSoftware.lemmyFlag,
    this.parent,
    this.icon,
  });

  final int software;
  final FeedSort? parent;
  final IconData? icon;

  String title(BuildContext context) => switch (this) {
    FeedSort.hot => l(context).sort_hot,
    FeedSort.top => l(context).sort_top,
    FeedSort.newest => l(context).sort_newest,
    FeedSort.active => l(context).sort_active,
    FeedSort.commented => l(context).sort_commented,
    FeedSort.oldest => l(context).sort_oldest,
    FeedSort.scaled => l(context).sort_scaled,
    FeedSort.newComments => l(context).sort_newComments,
    FeedSort.controversial => l(context).sort_controversial,
    FeedSort.topHour => l(context).sort_topHour,
    FeedSort.topThreeHour => l(context).sort_top_3h,
    FeedSort.topSixHour => l(context).sort_top_6h,
    FeedSort.topTwelveHour => l(context).sort_top_12h,
    FeedSort.topDay => l(context).sort_top_1d,
    FeedSort.topWeek => l(context).sort_top_1w,
    FeedSort.topMonth => l(context).sort_top_1m,
    FeedSort.topThreeMonths => l(context).sort_top_3m,
    FeedSort.topSixMonths => l(context).sort_top_6m,
    FeedSort.topNineMonths => l(context).sort_top_9m,
    FeedSort.topYear => l(context).sort_topYear,
    FeedSort.commentedThreeHour => l(context).sort_commented_3h,
    FeedSort.commentedSixHour => l(context).sort_commented_6h,
    FeedSort.commentedTwelveHour => l(context).sort_commented_12h,
    FeedSort.commentedDay => l(context).sort_commented_1d,
    FeedSort.commentedWeek => l(context).sort_commented_1w,
    FeedSort.commentedMonth => l(context).sort_commented_1m,
    FeedSort.commentedYear => l(context).sort_commented_1y,
  };

  static List<FeedSort> match({
    required List<FeedSort> values,
    required int software,
    FeedSort? parent,
    bool flat = true,
  }) {
    return values
        .where(
          (item) =>
              (item.software & software) == software &&
              (item.parent == parent || flat),
        )
        .toList();
  }
}
