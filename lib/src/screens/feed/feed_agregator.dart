import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'feed_screen.dart';

double calcRanking(PostModel post, DateTime time) {
  final scaleFactor = 10000;
  final gravity = 1.8;
  final score = (post.upvotes ?? 0) - (post.downvotes ?? 0);

  return scaleFactor *
      log(max(1, 3 + score)) /
      pow((DateTime.now().difference(time).inHours) + 2, gravity);
}

int lemmyActive(PostModel lhs, PostModel rhs) {
  return calcRanking(
    rhs,
    rhs.lastActive,
  ).compareTo(calcRanking(lhs, lhs.lastActive));
}

int lemmyHot(PostModel lhs, PostModel rhs) {
  return calcRanking(
    rhs,
    rhs.createdAt,
  ).compareTo(calcRanking(lhs, lhs.createdAt));
}

int mbinActive(PostModel lhs, PostModel rhs) {
  return rhs.lastActive.compareTo(lhs.lastActive);
}

//TODO: mbinHot

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
  List<List<PostModel>> inputs,
  FeedSort sort, {
  List<PostModel>? previousRemainder,
}) {
  if (inputs.length < 2) {
    return (inputs.first, []);
  }

  final sortFunc = switch (sort) {
    FeedSort.active => mbinActive,
    FeedSort.hot => lemmyHot,
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
    firsts.sort((lhs, rhs) => sortFunc(lhs.$2, rhs.$2));

    // Remove selected post from input list and add to posts list
    posts.add(mutableInputs[firsts.first.$1].removeAt(0));
  }

  // Save remaining posts for next pass
  for (var (index, input) in mutableInputs.indexed) {
    remainder[index] = input;
  }

  debugPrint(
    'Merge(${inputs.length}, $sort, ${previousRemainder?.length}) -> (${posts.length}, ${remainder.map((i) => i.length)})',
  );
  return (posts, remainder);
}

class FeedInputState {
  final String title;
  final FeedSource source;
  final int? sourceId;
  List<PostModel> _leftover = [];
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
    if (_nextPage == null) {
      return (_leftover, _nextPage);
    }

    switch (view) {
      case FeedView.threads:
        final postListModel = await ac.api.threads.list(
          source,
          sourceId: sourceId,
          page: nullIfEmpty(pageKey),
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
          page: nullIfEmpty(pageKey),
          sort: sort,
          usePreferredLangs: ac.profile.useAccountLanguageFilter,
          langs: ac.profile.customLanguageFilter.toList(),
        );
        _nextPage = postListModel.nextPage;
        return ([..._leftover, ...postListModel.items], postListModel.nextPage);
      case FeedView.timeline:
        final threadFuture = _nextPage != null
            ? ac.api.threads.list(
                source,
                sourceId: sourceId,
                page: nullIfEmpty(pageKey),
                sort: sort,
                usePreferredLangs: ac.profile.useAccountLanguageFilter,
                langs: ac.profile.customLanguageFilter.toList(),
              )
            : Future.value();
        final microblogFuture = _timelinePage != null
            ? ac.api.microblogs.list(
                source,
                sourceId: sourceId,
                page: nullIfEmpty(pageKey),
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
          [...postLists],
          sort,
          previousRemainder: _leftover,
        );

        _leftover = merged.$2.expand((list) => list).toList();

        _nextPage = results.first.nextPage ?? results.last?.nextPage;
        _timelinePage = results.last?.nextPage;

        debugPrint(
          '$title input fetch($pageKey, $view, $sort) -> (${merged.$1.length}, ${merged.$2.map((i) => i.length).toList()})',
        );
        return (merged.$1, _nextPage);
    }
  }
}

class FeedAggregator {
  final List<FeedInputState> inputs;

  const FeedAggregator({required this.inputs});

  static Future<FeedAggregator> createFeed(AppController ac, Feed feed) async {
    final inputs = await feed.inputs.map((input) async {
      int? source;
      try {
        source = (switch (input.sourceType) {
          FeedSource.all => null,
          FeedSource.local => null,
          FeedSource.subscribed => null,
          FeedSource.moderated => null,
          FeedSource.favorited => null,
          FeedSource.community =>
          (await ac.api.community.getByName(
              denormalizeName(input.name, ac.instanceHost))).id,
          FeedSource.user =>
          (await ac.api.users.getByName(
              denormalizeName(input.name, ac.instanceHost))).id,
          FeedSource.domain => throw UnimplementedError(),
        });
      } catch (error) {
        return null;
      }
      return FeedInputState(title: input.name, source: input.sourceType, sourceId: source);
    }).wait;
    return FeedAggregator(inputs: inputs.nonNulls.toList());
  }

  Future<(List<PostModel>, String?)> fetchPage(
    AppController ac,
    String pageKey,
    FeedView view,
    FeedSort sort,
  ) async {
    final futures = inputs.map(
      (input) => input.fetchPage(ac, pageKey, view, sort),
    );
    final results = await Future.wait(futures);

    final postInputs = results.map((result) => result.$1).toList();

    final merged = merge(postInputs, sort);

    for (var (index, posts) in merged.$2.indexed) {
      inputs[index]._leftover = posts;
    }

    debugPrint(
      'Aggregator fetch($pageKey, $view, $sort) -> (${merged.$1.length}, ${merged.$2.map((i) => i.length).toList()})',
    );

    // check for read status
    final newItems = ac.serverSoftware == ServerSoftware.lemmy && ac.isLoggedIn
        ? merged.$1
        : await Future.wait(
            merged.$1.map(
              (item) async =>
                  (await ac.isRead(item)) ? item.copyWith(read: true) : item,
            ),
          );

    return (newItems, results.firstOrNull?.$2);
  }

  void refresh() {
    for (var input in inputs) {
      input._leftover = [];
      input._nextPage = '';
      input._timelinePage = '';
    }
  }
}
