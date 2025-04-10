enum FeedSource {
  all,
  local,
  subscribed,
  moderated,
  favorited,
  magazine,
  user,
  domain,
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
