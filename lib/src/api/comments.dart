import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';

enum CommentSort { newest, top, hot, active, oldest }

const Map<CommentSort, String> lemmyCommentSortMap = {
  CommentSort.active: 'Controversial',
  CommentSort.hot: 'Hot',
  CommentSort.newest: 'New',
  CommentSort.oldest: 'Old',
  CommentSort.top: 'Top',
};

SelectionMenu<CommentSort> commentSortSelect(BuildContext context) =>
    SelectionMenu(
      l(context).sortComments,
      [
        SelectionMenuItem(
          value: CommentSort.hot,
          title: l(context).sort_hot,
          icon: Symbols.local_fire_department_rounded,
        ),
        SelectionMenuItem(
          value: CommentSort.top,
          title: l(context).sort_top,
          icon: Symbols.trending_up_rounded,
        ),
        SelectionMenuItem(
          value: CommentSort.newest,
          title: l(context).sort_newest,
          icon: Symbols.nest_eco_leaf_rounded,
        ),
        SelectionMenuItem(
          value: CommentSort.active,
          title: l(context).sort_active,
          icon: Symbols.rocket_launch_rounded,
        ),
        SelectionMenuItem(
          value: CommentSort.oldest,
          title: l(context).sort_oldest,
          icon: Symbols.access_time_rounded,
        ),
      ],
    );

const _postTypeMbin = {
  PostType.thread: 'entry',
  PostType.microblog: 'posts',
};
const _postTypeMbinComment = {
  PostType.thread: 'comments',
  PostType.microblog: 'post-comments',
};

class APIComments {
  final ServerClient client;

  APIComments(this.client);

  Future<CommentListModel> list(
    PostType postType,
    int postId, {
    String? page,
    CommentSort? sort,
    List<String>? langs,
    bool? usePreferredLangs,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbin[postType]}/$postId/comments';
        final query = {
          'p': page,
          'sortBy': sort?.name,
          'lang': langs?.join(','),
          'usePreferredLangs': (usePreferredLangs ?? false).toString(),
        };

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return CommentListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment/list';
        final query = {
          'post_id': postId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
          'max_depth': '8',
        };

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return CommentListModel.fromLemmyToTree(response.bodyJson);

      case ServerSoftware.piefed:
        const path = '/comment/list';
        final query = {
          'post_id': postId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
          'max_depth': '8',
        };

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return CommentListModel.fromPiefedToTree(response.bodyJson);
    }
  }

  Future<CommentListModel> listFromUser(
    PostType postType,
    int userId, {
    String? page,
    CommentSort? sort,
    List<String>? langs,
    bool? usePreferredLangs,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/${_postTypeMbinComment[postType]}';
        final query = {
          'p': page,
          'sort': sort?.name,
          'lang': langs?.join(','),
          'usePreferredLangs': (usePreferredLangs ?? false).toString(),
        };

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return CommentListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user';
        final query = {
          'person_id': userId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort]
        };

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        final json = response.bodyJson;

        json['next_page'] =
            lemmyCalcNextIntPage(json['comments'] as List<dynamic>, page);

        return CommentListModel.fromLemmyToFlat(json);

      case ServerSoftware.piefed:
        const path = '/user';
        final query = {
          'person_id': userId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort]
        };

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        final json = response.bodyJson;

        json['next_page'] =
            lemmyCalcNextIntPage(json['comments'] as List<dynamic>, page);

        return CommentListModel.fromPiefedToFlat(json);
    }
  }

  Future<CommentModel> get(PostType postType, int commentId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId';

        final response = await client.send(HttpMethod.get, path);

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment/list';
        final query = {'parent_id': commentId.toString()};

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return CommentModel.fromLemmy(
          (response.bodyJson['comments'] as List<dynamic>)
              .firstWhere((item) => item['comment']['id'] == commentId),
          possibleChildrenJson: response.bodyJson['comments'] as List<dynamic>,
        );

      case ServerSoftware.piefed:
        const path = '/comment/list';
        final query = {'parent_id': commentId.toString()};

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return CommentModel.fromPiefed(
          (response.bodyJson['comments'] as List<dynamic>)
              .firstWhere((item) => item['comment']['id'] == commentId),
          possibleChildrenJson: response.bodyJson['comments'] as List<dynamic>,
        );
    }
  }

  Future<CommentModel> vote(
    PostType postType,
    int commentId,
    int choice,
    int newScore,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = choice == 1
            ? '/${_postTypeMbinComment[postType]}/$commentId/favourite'
            : '/${_postTypeMbinComment[postType]}/$commentId/vote/$choice';

        final response = await client.send(HttpMethod.put, path);

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment/like';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'comment_id': commentId,
            'score': newScore,
          },
        );

        return CommentModel.fromLemmy(
            response.bodyJson['comment_view'] as Map<String, Object?>);

      case ServerSoftware.piefed:
        const path = '/comment/like';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'comment_id': commentId,
            'score': newScore,
          },
        );

        return CommentModel.fromPiefed(
            response.bodyJson['comment_view'] as Map<String, Object?>);
    }
  }

  Future<CommentModel> boost(PostType postType, int commentId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId/vote/1';

        final response = await client.send(HttpMethod.put, path);

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Tried to boost on lemmy');

      case ServerSoftware.piefed:
        throw Exception('Tried to boost on piefed');
    }
  }

  Future<CommentModel> create(
    PostType postType,
    int postId,
    String body, {
    int? parentCommentId,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/${_postTypeMbin[postType]}/$postId/comments${parentCommentId != null ? '/$parentCommentId/reply' : ''}';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {'body': body},
        );

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'content': body,
            'post_id': postId,
            'parent_id': parentCommentId
          },
        );

        return CommentModel.fromLemmy(
            response.bodyJson['comment_view'] as Map<String, Object?>);

      case ServerSoftware.piefed:
        const path = '/comment';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'content': body,
            'post_id': postId,
            'parent_id': parentCommentId
          },
        );

        return CommentModel.fromPiefed(
            response.bodyJson['comment_view'] as Map<String, Object?>);
    }
  }

  Future<CommentModel> edit(
    PostType postType,
    int commentId,
    String body,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId';

        final response = await client.send(
          HttpMethod.put,
          path,
          body: {
            'body': body,
          },
        );

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment';

        final response = await client.send(
          HttpMethod.put,
          path,
          body: {
            'comment_id': commentId,
            'content': body,
          },
        );

        return CommentModel.fromLemmy(
            response.bodyJson['comment_view'] as Map<String, Object?>);

      case ServerSoftware.piefed:
        const path = '/comment';

        final response = await client.send(
          HttpMethod.put,
          path,
          body: {
            'comment_id': commentId,
            'content': body,
          },
        );

        return CommentModel.fromPiefed(
            response.bodyJson['comment_view'] as Map<String, Object?>);
    }
  }

  Future<void> delete(PostType postType, int commentId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId';

        final response = await client.send(HttpMethod.delete, path);

      case ServerSoftware.lemmy:
        const path = '/comment/delete';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'comment_id': commentId,
            'deleted': true,
          },
        );

      case ServerSoftware.piefed:
        const path = '/comment/delete';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'comment_id': commentId,
            'deleted': true,
          },
        );
    }
  }

  Future<void> report(PostType postType, int commentId, String reason) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId/report';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {'reason': reason},
        );

      case ServerSoftware.lemmy:
        const path = '/comment/report';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'comment_id': commentId,
            'reason': reason,
          },
        );

      case ServerSoftware.piefed:
        const path = '/comment/report';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'comment_id': commentId,
            'reason': reason,
          },
        );
    }
  }
}
