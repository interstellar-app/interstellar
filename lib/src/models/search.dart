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

    for (final actor in json['apActors']) {
      final type = actor['type'];
      if (type == 'user') {
        items.add(DetailedUserModel.fromMbin(actor['object'] as JsonMap));
      } else if (type == 'magazine') {
        items.add(DetailedCommunityModel.fromMbin(actor['object'] as JsonMap));
      }
    }
    for (final item in json['apObjects']) {
      final itemType = item['itemType'];
      if (itemType == 'entry') {
        items.add(PostModel.fromMbinEntry(item as JsonMap));
      } else if (itemType == 'post') {
        items.add(PostModel.fromMbinPost(item as JsonMap));
      } else if (itemType == 'entry_comment' || itemType == 'post_comment') {
        items.add(CommentModel.fromMbin(item as JsonMap));
      }
    }
    for (final item in json['items']) {
      final itemType = item['itemType'];
      if (itemType == 'entry') {
        items.add(PostModel.fromMbinEntry(item as JsonMap));
      } else if (itemType == 'post') {
        items.add(PostModel.fromMbinPost(item as JsonMap));
      } else if (itemType == 'entry_comment' || itemType == 'post_comment') {
        items.add(CommentModel.fromMbin(item as JsonMap));
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
