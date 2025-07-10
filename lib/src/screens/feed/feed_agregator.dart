import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'feed_screen.dart';

double calcLemmyRanking(PostModel post, DateTime time) {
  final scaleFactor = 10000;
  final gravity = 1.8;
  final score = (post.upvotes ?? 0) - (post.downvotes ?? 0);

  return scaleFactor *
      log(max(1, 3 + score)) /
      pow((DateTime.now().difference(time).inHours) + 2, gravity);
}

int lemmyActive(PostModel lhs, PostModel rhs) {
  return calcLemmyRanking(
    rhs,
    rhs.lastActive,
  ).compareTo(calcLemmyRanking(lhs, lhs.lastActive));
}

int lemmyHot(PostModel lhs, PostModel rhs) {
  return calcLemmyRanking(
    rhs,
    rhs.createdAt,
  ).compareTo(calcLemmyRanking(lhs, lhs.createdAt));
}

int mbinActive(PostModel lhs, PostModel rhs) {
  return rhs.lastActive.compareTo(lhs.lastActive);
}

double calcMbinRanking(PostModel post) {
  final netscoreMultiplier = 4500;
  final commentMultiplier = 1500;
  // final commentUniqueMultiplier = 5000;
  final downvotedCutoff = -5;
  final commentDownvotedMultiplier = 500;
  final maxAdvantage = 86400;
  final maxPenalty = 43200;

  final score = (post.boosts ?? 0) + (post.upvotes ?? 0) - (post.downvotes ?? 0);
  final scoreAdvantage = score * netscoreMultiplier;

  var commentAdvantage = 0;
  if (score > downvotedCutoff) {
    commentAdvantage = post.numComments * commentMultiplier;
    //TODO: unique comment check here
  } else {
    commentAdvantage = post.numComments * commentDownvotedMultiplier;
    //TODO: unique comment check here
  }

  final advantage = max(
    min(scoreAdvantage + commentAdvantage, maxAdvantage),
    -maxPenalty,
  );

  final dateAdvantage = min(
    post.createdAt.millisecondsSinceEpoch / 1000,
    DateTime.now().millisecondsSinceEpoch / 1000,
  );

  return min((dateAdvantage + advantage), pow(2, 31) - 1);
}

int mbinHot(PostModel lhs, PostModel rhs) {
  return calcMbinRanking(rhs).compareTo(calcMbinRanking(lhs));
}

int top(PostModel lhs, PostModel rhs) {
  return ((rhs.upvotes ?? 0) - (rhs.downvotes ?? 0)).compareTo(
    ((lhs.upvotes ?? 0) - (lhs.downvotes ?? 0)),
  );
}

int controversial(PostModel lhs, PostModel rhs) {
  return top(lhs, rhs) * -1;
}

int newest(PostModel lhs, PostModel rhs) {
  return rhs.createdAt.compareTo(lhs.createdAt);
}

int oldest(PostModel lhs, PostModel rhs) {
  return newest(lhs, rhs) * -1;
}

int commented(PostModel lhs, PostModel rhs) {
  return rhs.numComments.compareTo(lhs.numComments);
}

(List<PostModel>, List<List<PostModel>>) merge(
  ServerSoftware software,
  List<List<PostModel>> inputs,
  FeedSort sort, {
  List<PostModel>? previousRemainder,
}) {
  if (inputs.length < 2) {
    return (inputs.first, []);
  }

  final sortFunc = switch (sort) {
    FeedSort.active =>
      software == ServerSoftware.mbin ? mbinActive : lemmyActive,
    FeedSort.hot => software == ServerSoftware.mbin ? mbinHot : lemmyHot,
    FeedSort.newest => newest,
    FeedSort.oldest => oldest,
    FeedSort.commented => commented,
    FeedSort.commentedThreeHour => commented,
    FeedSort.commentedSixHour => commented,
    FeedSort.commentedTwelveHour => commented,
    FeedSort.commentedDay => commented,
    FeedSort.commentedWeek => commented,
    FeedSort.commentedMonth => commented,
    FeedSort.commentedYear => commented,
    FeedSort.top => top,
    FeedSort.topDay => top,
    FeedSort.topWeek => top,
    FeedSort.topMonth => top,
    FeedSort.topYear => top,
    FeedSort.topHour => top,
    FeedSort.topThreeHour => top,
    FeedSort.topSixHour => top,
    FeedSort.topTwelveHour => top,
    FeedSort.topThreeMonths => top,
    FeedSort.topSixMonths => top,
    FeedSort.topNineMonths => top,
    FeedSort.newComments => commented,
    FeedSort.controversial => commented,
    FeedSort.scaled => lemmyHot,
  };

  // Copy inputs into mutable lists and include previous remainders if included
  var mutableInputs = inputs
      .map((input) => input.isNotEmpty ? input.toList() : null)
      .nonNulls
      .toList();
  int remainderIndex = mutableInputs.length;
  if (previousRemainder != null) {
    previousRemainder.sort(sortFunc);
    mutableInputs.add(previousRemainder);
  }
  // Create room for remainders from merge inputs
  List<List<PostModel>> remainder = List.generate(
    inputs.length + (previousRemainder != null ? 1 : 0),
    (index) => [],
  );
  List<PostModel> posts = [];

  // Merge until one of the inputs (excluding previous remainders) is drained
  while (mutableInputs
      .sublist(0, remainderIndex)
      .every((input) => input.isNotEmpty)) {
    // Get first post of each input
    List<(int, PostModel)> firsts = [];
    for (var (index, input) in mutableInputs.indexed) {
      if (input.isNotEmpty) {
        firsts.add((index, input.first));
      }
    }
    // Sort by selected sort function
    firsts.sort((lhs, rhs) {
      if (lhs.$2.isPinned) return -1;
      if (rhs.$2.isPinned) return 1;
      return sortFunc(lhs.$2, rhs.$2);
    });

    // Remove selected post from input list and add to posts list
    posts.add(mutableInputs[firsts.first.$1].removeAt(0));
  }

  // Save remaining posts for next pass
  for (var (index, input) in mutableInputs.indexed) {
    remainder[index] = input;
  }

  return (posts, remainder);
}

class FeedInputState {
  final String title;
  final FeedSource source;
  final int? sourceId;
  List<PostModel> _leftover = [];
  List<PostModel> _timelineThreadsLeftover = [];
  List<PostModel> _timelineMicroblogsLeftover = [];
  String? _nextPage = '';
  String? _timelinePage = '';

  FeedInputState({
    required this.title,
    required this.source,
    required this.sourceId,
  });

  Future<(List<PostModel>, String?)> fetchPage(
    AppController ac,
    String pageKey,
    FeedView view,
    FeedSort sort,
  ) async {
    if (_nextPage == null || _leftover.length > 25) {
      return (_leftover, _nextPage);
    }

    switch (view) {
      case FeedView.threads:
        final postListModel = await ac.api.threads.list(
          source,
          sourceId: sourceId,
          page: nullIfEmpty(_nextPage!),
          sort: sort,
          usePreferredLangs: ac.profile.useAccountLanguageFilter,
          langs: ac.profile.customLanguageFilter.toList(),
        );
        _nextPage = postListModel.nextPage;
        return ([..._leftover, ...postListModel.items], postListModel.nextPage);
      case FeedView.microblog:
        final postListModel = await ac.api.microblogs.list(
          source,
          sourceId: sourceId,
          page: nullIfEmpty(_nextPage!),
          sort: sort,
          usePreferredLangs: ac.profile.useAccountLanguageFilter,
          langs: ac.profile.customLanguageFilter.toList(),
        );
        _nextPage = postListModel.nextPage;
        return ([..._leftover, ...postListModel.items], postListModel.nextPage);
      case FeedView.timeline:
        final threadFuture =
            _nextPage != null && _timelineThreadsLeftover.length < 25
            ? ac.api.threads.list(
                source,
                sourceId: sourceId,
                page: nullIfEmpty(_nextPage!),
                sort: sort,
                usePreferredLangs: ac.profile.useAccountLanguageFilter,
                langs: ac.profile.customLanguageFilter.toList(),
              )
            : Future.value();
        final microblogFuture =
            _timelinePage != null && _timelineMicroblogsLeftover.length < 25
            ? ac.api.microblogs.list(
                source,
                sourceId: sourceId,
                page: nullIfEmpty(_timelinePage!),
                sort: sort,
                usePreferredLangs: ac.profile.useAccountLanguageFilter,
                langs: ac.profile.customLanguageFilter.toList(),
              )
            : Future.value();
        final results = await Future.wait([threadFuture, microblogFuture]);

        final postLists = results
            .map((postListModel) => postListModel?.items ?? <PostModel>[])
            .toList();
        final merged = merge(
          ac.serverSoftware,
          [...postLists],
          sort,
          previousRemainder: [
            ..._timelineThreadsLeftover,
            ..._timelineMicroblogsLeftover,
          ],
        );

        // get next page if new request was sent
        if (_timelineMicroblogsLeftover.length < 25) {
          _timelinePage = results.last?.nextPage;
        }
        if (_timelineThreadsLeftover.length < 25) {
          _nextPage = results.first?.nextPage;
        }

        _timelineThreadsLeftover = merged.$2.first;
        _timelineMicroblogsLeftover = merged.$2.last;

        debugPrint(
          '$title input fetch($pageKey, $view, $sort) -> (${merged.$1.length}, ${merged.$2.map((i) => i.length).toList()}, $_nextPage, $_timelinePage)',
        );

        // if final page of input also return leftover posts
        var result = [..._leftover, ...merged.$1];
        if (_nextPage == null) {
          result.addAll(_timelineThreadsLeftover);
        }
        if (_timelinePage == null) {
          result.addAll(_timelineMicroblogsLeftover);
        }

        return (result, _nextPage ?? _timelinePage);
    }
  }

  FeedInputState clone() {
    return FeedInputState(title: title, source: source, sourceId: sourceId);
  }
}

class FeedAggregator {
  final String name;
  final List<FeedInputState> inputs;

  const FeedAggregator({required this.name, required this.inputs});

  static Future<FeedAggregator> create(AppController ac, Feed feed) async {
    final inputs = await feed.inputs.map((input) async {
      int? source;
      try {
        source = (switch (input.sourceType) {
          FeedSource.all => null,
          FeedSource.local => null,
          FeedSource.subscribed => null,
          FeedSource.moderated => null,
          FeedSource.favorited => null,
          FeedSource.community => (await ac.api.community.getByName(
            denormalizeName(input.name, ac.instanceHost),
          )).id,
          FeedSource.user => (await ac.api.users.getByName(
            denormalizeName(input.name, ac.instanceHost),
          )).id,
          FeedSource.domain => throw UnimplementedError(),
        });
      } catch (error) {
        return null;
      }
      return FeedInputState(
        title: input.name,
        source: input.sourceType,
        sourceId: source,
      );
    }).wait;
    return FeedAggregator(name: feed.name, inputs: inputs.nonNulls.toList());
  }

  Future<(List<PostModel>, String?)> fetchPage(
    AppController ac,
    String pageKey,
    FeedView view,
    FeedSort sort,
  ) async {
    if (inputs.isEmpty) return (<PostModel>[], null);

    final futures = inputs.map(
      (input) => input.fetchPage(ac, pageKey, view, sort),
    );
    final results = await Future.wait(futures);

    final postInputs = results.map((result) => result.$1).toList();

    final merged = merge(ac.serverSoftware, postInputs, sort);

    // store leftover posts
    for (var (index, posts) in merged.$2.indexed) {
      inputs[index]._leftover = posts;
    }

    // get next page of any remaining inputs
    final nextPages = results.where((result) => result.$2 != null);
    final nextPage = nextPages.firstOrNull?.$2;

    final result = merged.$1;
    // if final page also return all leftover posts
    if (nextPage == null) {
      for (var input in inputs) {
        result.addAll(input._leftover);
      }
    }

    debugPrint(
      'Aggregator fetch($pageKey, $view, $sort) -> (${result.length}, ${merged.$2.map((i) => i.length).toList()})\n---------------------------------------------------------------------',
    );

    // check for read status
    final newItems = ac.serverSoftware == ServerSoftware.lemmy && ac.isLoggedIn
        ? result
        : await Future.wait(
            result.map(
              (item) async =>
                  (await ac.isRead(item)) ? item.copyWith(read: true) : item,
            ),
          );

    return (newItems, nextPage);
  }

  void refresh() {
    for (var input in inputs) {
      input._leftover = [];
      input._nextPage = '';
      input._timelinePage = '';
      input._timelineThreadsLeftover = [];
      input._timelineMicroblogsLeftover = [];
    }
  }

  FeedAggregator clone() {
    return FeedAggregator(
      name: name,
      inputs: inputs.map((input) => input.clone()).toList(),
    );
  }
}
