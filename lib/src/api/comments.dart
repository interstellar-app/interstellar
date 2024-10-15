import 'dart:convert';

import 'package:http/http.dart' as http;
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

const SelectionMenu<CommentSort> commentSortSelect = SelectionMenu(
  'Sort Comments',
  [
    SelectionMenuItem(
      value: CommentSort.hot,
      title: 'Hot',
      icon: Symbols.local_fire_department_rounded,
    ),
    SelectionMenuItem(
      value: CommentSort.top,
      title: 'Top',
      icon: Symbols.trending_up_rounded,
    ),
    SelectionMenuItem(
      value: CommentSort.newest,
      title: 'Newest',
      icon: Symbols.nest_eco_leaf_rounded,
    ),
    SelectionMenuItem(
      value: CommentSort.active,
      title: 'Active',
      icon: Symbols.rocket_launch_rounded,
    ),
    SelectionMenuItem(
      value: CommentSort.oldest,
      title: 'Oldest',
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
  final ServerSoftware software;
  final http.Client httpClient;
  final String server;

  APIComments(
    this.software,
    this.httpClient,
    this.server,
  );

  Future<CommentListModel> list(
    PostType postType,
    int postId, {
    String? page,
    CommentSort? sort,
    List<String>? langs,
    bool? usePreferredLangs,
  }) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/${_postTypeMbin[postType]}/$postId/comments';
        final query = queryParams({
          'p': page,
          'sortBy': sort?.name,
          'lang': langs?.join(','),
          'usePreferredLangs': (usePreferredLangs ?? false).toString(),
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load comments');

        return CommentListModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment/list';
        final query = queryParams({
          'post_id': postId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
          'max_depth': '8',
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load comments');

        return CommentListModel.fromLemmy(
            jsonDecode(utf8.decode(response.bodyBytes))
                as Map<String, Object?>);
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
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/users/$userId/${_postTypeMbinComment[postType]}';
        final query = queryParams({
          'p': page,
          'sort': sort?.name,
          'lang': langs?.join(','),
          'usePreferredLangs': (usePreferredLangs ?? false).toString(),
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load comments');

        return CommentListModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/user';
        final query = queryParams({
          'person_id': userId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort]
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load user');

        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;

        json['next_page'] =
            lemmyCalcNextIntPage(json['comments'] as List<dynamic>, page);

        return CommentListModel.fromLemmy(json);
    }
  }

  Future<CommentModel> get(PostType postType, int commentId) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/${_postTypeMbinComment[postType]}/$commentId';

        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to load comment');

        return CommentModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment/list';
        final query = queryParams({
          'parent_id': commentId.toString(),
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load comment');

        return CommentModel.fromLemmy(
          (jsonDecode(response.body)['comments'] as List<dynamic>)
              .firstWhere((item) => item['comment']['id'] == commentId),
          possibleChildren:
              jsonDecode(utf8.decode(response.bodyBytes))['comments']
                  as List<dynamic>,
        );
    }
  }

  Future<CommentModel> vote(
    PostType postType,
    int commentId,
    int choice,
    int newScore,
  ) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = choice == 1
            ? '/api/${_postTypeMbinComment[postType]}/$commentId/favourite'
            : '/api/${_postTypeMbinComment[postType]}/$commentId/vote/$choice';

        final response = await httpClient.put(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to send vote');

        return CommentModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment/like';

        final response = await httpClient.post(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'comment_id': commentId,
            'score': newScore,
          }),
        );

        httpErrorHandler(response, message: 'Failed to send vote');

        return CommentModel.fromLemmy(
            jsonDecode(utf8.decode(response.bodyBytes))['comment_view']
                as Map<String, Object?>);
    }
  }

  Future<CommentModel> boost(PostType postType, int commentId) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/${_postTypeMbinComment[postType]}/$commentId/vote/1';

        final response = await httpClient.put(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to send boost');

        return CommentModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('Tried to boost on lemmy');
    }
  }

  Future<CommentModel> create(
    PostType postType,
    int postId,
    String body, {
    int? parentCommentId,
  }) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path =
            '/api/${_postTypeMbin[postType]}/$postId/comments${parentCommentId != null ? '/$parentCommentId/reply' : ''}';

        final response = await httpClient.post(
          Uri.https(server, path),
          body: jsonEncode({'body': body}),
        );

        httpErrorHandler(response, message: 'Failed to create comment');

        return CommentModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment';

        final response = await httpClient.post(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'content': body,
            'post_id': postId,
            'parent_id': parentCommentId
          }),
        );

        httpErrorHandler(response, message: 'Failed to create comment');

        return CommentModel.fromLemmy(
            jsonDecode(utf8.decode(response.bodyBytes))['comment_view']
                as Map<String, Object?>);
    }
  }

  Future<CommentModel> edit(
    PostType postType,
    int commentId,
    String body,
  ) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/${_postTypeMbinComment[postType]}/$commentId';

        final response = await httpClient.put(
          Uri.https(server, path),
          body: jsonEncode({
            'body': body,
          }),
        );

        httpErrorHandler(response, message: 'Failed to edit comment');

        return CommentModel.fromMbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment';

        final response = await httpClient.put(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'comment_id': commentId,
            'content': body,
          }),
        );

        httpErrorHandler(response, message: 'Failed to edit comment');

        return CommentModel.fromLemmy(
            jsonDecode(utf8.decode(response.bodyBytes))['comment_view']
                as Map<String, Object?>);
    }
  }

  Future<void> delete(PostType postType, int commentId) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/${_postTypeMbinComment[postType]}/$commentId';

        final response = await httpClient.delete(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to delete comment');

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment/delete';

        final response = await httpClient.post(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'comment_id': commentId,
            'deleted': true,
          }),
        );

        httpErrorHandler(response, message: 'Failed to delete comment');
    }
  }

  Future<void> report(PostType postType, int commentId, String reason) async {
    switch (software) {
      case ServerSoftware.mbin:
        final path = '/api/${_postTypeMbinComment[postType]}/$commentId/report';

        final response = await httpClient.post(
          Uri.https(server, path),
          body: jsonEncode({
            'reason': reason,
          }),
        );

        httpErrorHandler(response, message: 'Failed to report comment');

      case ServerSoftware.lemmy:
        const path = '/api/v3/comment/report';

        final response = await httpClient.post(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'comment_id': commentId,
            'reason': reason,
          }),
        );

        httpErrorHandler(response, message: 'Failed to report comment');
    }
  }
}
