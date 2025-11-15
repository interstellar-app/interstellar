import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../utils/utils.dart';

enum FeedView {
  threads(icon: Symbols.feed_rounded),
  microblog(icon: Symbols.chat_rounded),
  combined(icon: Symbols.view_timeline_rounded);

  const FeedView({this.icon});

  final IconData? icon;

  String title(BuildContext context) => switch (this) {
    FeedView.threads => l(context).threads,
    FeedView.microblog => l(context).microblog,
    FeedView.combined => l(context).combined,
  };
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
  active,
  hot,
  newest,
  oldest,
  top,
  commented,
  // mbin specific
  commentedThreeHour,
  commentedSixHour,
  commentedTwelveHour,
  commentedDay,
  commentedWeek,
  commentedMonth,
  commentedYear,

  //lemmy specific
  topDay,
  topWeek,
  topMonth,
  topYear,
  newComments,
  topHour,
  topThreeHour,
  topSixHour,
  topTwelveHour,
  topThreeMonths,
  topSixMonths,
  topNineMonths,
  controversial,
  scaled,
}
