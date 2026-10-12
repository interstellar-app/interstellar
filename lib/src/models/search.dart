import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'search.freezed.dart';

@freezed
abstract class SearchListModel with _$SearchListModel {
  const factory SearchListModel({
    required List<Object> items,
    required String? nextPage,
  }) = _SearchListModel;

  factory SearchListModel.fromMbin(Map<String, dynamic> json) {
    final items = <Object>[];

    final itemsJson = json['items']! as List<dynamic>;
    final apResultsJson = json['apResults']! as List<dynamic>;

    for (final itemJson in itemsJson) {
      if (itemJson['entry'] != null) {
        items.add(PostModel.fromMbinEntry(itemJson['entry'] as JsonMap));
      }
      if (itemJson['entryComment'] != null) {
        items.add(CommentModel.fromMbin(itemJson['entryComment'] as JsonMap));
      }
      if (itemJson['post'] != null) {
        items.add(PostModel.fromMbinPost(itemJson['post'] as JsonMap));
      }
      if (itemJson['postComment'] != null) {
        items.add(CommentModel.fromMbin(itemJson['postComment'] as JsonMap));
      }
      if (itemJson['magazine'] != null) {
        items.add(
          DetailedCommunityModel.fromMbin(itemJson['magazine'] as JsonMap),
        );
      }
      if (itemJson['user'] != null) {
        items.add(DetailedUserModel.fromMbin(itemJson['user'] as JsonMap));
      }
    }
    for (final apResultJson in apResultsJson) {
      if (apResultJson['entry'] != null) {
        items.add(PostModel.fromMbinEntry(apResultJson['entry'] as JsonMap));
      }
      if (apResultJson['entryComment'] != null) {
        items.add(
          CommentModel.fromMbin(apResultJson['entryComment'] as JsonMap),
        );
      }
      if (apResultJson['post'] != null) {
        items.add(PostModel.fromMbinPost(apResultJson['post'] as JsonMap));
      }
      if (apResultJson['postComment'] != null) {
        items.add(
          CommentModel.fromMbin(apResultJson['postComment'] as JsonMap),
        );
      }
      if (apResultJson['magazine'] != null) {
        items.add(
          DetailedCommunityModel.fromMbin(apResultJson['magazine'] as JsonMap),
        );
      }
      if (apResultJson['user'] != null) {
        items.add(DetailedUserModel.fromMbin(apResultJson['user'] as JsonMap));
      }
    }

    return SearchListModel(
      items: items,
      nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
    );
  }

  factory SearchListModel.fromLemmy(
    Map<String, dynamic> json, {
    required List<(String, int)> langCodeIdPairs,
  }) {
    final items = <Object>[];

    for (final user in json['users']) {
      items.add(DetailedUserModel.fromLemmy(user));
    }

    for (final community in json['communities']) {
      items.add(DetailedCommunityModel.fromLemmy(community as JsonMap));
    }

    for (final post in json['posts']) {
      items.add(
        PostModel.fromLemmy({
          'post_view': post as JsonMap,
        }, langCodeIdPairs: langCodeIdPairs),
      );
    }

    for (final comment in json['comments']) {
      items.add(
        CommentModel.fromLemmy(
          comment as JsonMap,
          langCodeIdPairs: langCodeIdPairs,
        ),
      );
    }

    return SearchListModel(
      items: items,
      nextPage: json['next_page'] as String?,
    );
  }

  factory SearchListModel.fromPiefed(
    Map<String, dynamic> json, {
    required List<(String, int)> langCodeIdPairs,
  }) {
    final items = <Object>[];

    for (final user in json['users']) {
      items.add(DetailedUserModel.fromPiefed(user));
    }

    for (final community in json['communities']) {
      items.add(DetailedCommunityModel.fromPiefed(community as JsonMap));
    }

    for (final post in json['posts']) {
      items.add(
        PostModel.fromPiefed({
          'post_view': post as JsonMap,
        }, langCodeIdPairs: langCodeIdPairs),
      );
    }

    for (final comment in json['comments']) {
      items.add(
        CommentModel.fromPiefed(
          comment as JsonMap,
          langCodeIdPairs: langCodeIdPairs,
        ),
      );
    }

    return SearchListModel(
      items: items,
      nextPage: json['next_page'] as String?,
    );
  }
}
