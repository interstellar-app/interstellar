import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

enum CommentSort { hot, top, newest, active, oldest }

const Map<CommentSort, String> lemmyCommentSortMap = {
  CommentSort.active: 'Controversial',
  CommentSort.hot: 'Hot',
  CommentSort.newest: 'New',
  CommentSort.oldest: 'Old',
  CommentSort.top: 'Top',
};

SelectionMenu<CommentSort> commentSortSelect(BuildContext context) =>
    SelectionMenu(l(context).sortComments, [
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
      if (context.read<AppController>().serverSoftware != ServerSoftware.piefed)
        SelectionMenuItem(
          value: CommentSort.active,
          title: l(context).sort_active,
          icon: Symbols.rocket_launch_rounded,
        ),
      if (context.read<AppController>().serverSoftware != ServerSoftware.piefed)
        SelectionMenuItem(
          value: CommentSort.oldest,
          title: l(context).sort_oldest,
          icon: Symbols.access_time_rounded,
        ),
    ]);

const _postTypeMbin = {PostType.thread: 'entry', PostType.microblog: 'posts'};
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
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbin[postType]}/$postId/comments';
        final query = {'p': page, 'sortBy': sort?.name};

        final response = await client.get(path, queryParams: query);

        return CommentListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment/list';
        final query = {
          'post_id': postId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
          'max_depth': '8',
          'type_': 'All',
        };

        final response = await client.get(path, queryParams: query);

        return CommentListModel.fromLemmyToTree(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/post/replies';
        final query = {
          'post_id': postId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
        };

        final response = await client.get(path, queryParams: query);

        return CommentListModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<CommentListModel> listFromUser(
    PostType postType,
    int userId, {
    String? page,
    CommentSort? sort,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/${_postTypeMbinComment[postType]}';
        final query = {'p': page, 'sort': sort?.name};

        final response = await client.get(path, queryParams: query);

        return CommentListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user';
        final query = {
          'person_id': userId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;

        json['next_page'] = lemmyCalcNextIntPage(
          json['comments'] as List<dynamic>,
          page,
        );

        return CommentListModel.fromLemmyToFlat(
          json,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/comment/list';
        final query = {
          'person_id': userId.toString(),
          'page': page,
          'sort': lemmyCommentSortMap[sort],
        };

        final response = await client.get(path, queryParams: query);

        return CommentListModel.fromPiefedToFlat(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<CommentModel> get(PostType postType, int commentId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId';

        final response = await client.get(path);

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment/list';
        final query = {'parent_id': commentId.toString(), 'type_': 'All'};

        final response = await client.get(path, queryParams: query);

        return CommentModel.fromLemmy(
          (response.bodyJson['comments'] as List<dynamic>).firstWhere(
            (item) => item['comment']['id'] == commentId,
          ),
          possibleChildrenJson: response.bodyJson['comments'] as List<dynamic>,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/post/replies';
        final query = {'parent_id': commentId.toString()};

        final response = await client.get(path, queryParams: query);

        return CommentModel.fromPiefed(
          (response.bodyJson['comments'] as List<dynamic>).firstWhere(
            (item) => item['comment']['id'] == commentId,
          ),
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<CommentModel> vote(
    PostType postType,
    int commentId,
    int choice,
    int newScore, {
    String? emoji,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = choice == 1
            ? '/${_postTypeMbinComment[postType]}/$commentId/favourite'
            : '/${_postTypeMbinComment[postType]}/$commentId/vote/$choice';

        final response = await client.put(path);

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment/like';

        final response = await client.post(
          path,
          body: {'comment_id': commentId, 'score': newScore},
        );

        return CommentModel.fromLemmy(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/comment/like';

        final response = await client.post(
          path,
          body: {
            'comment_id': commentId,
            'score': newScore,
            if (emoji != null) 'emoji': emoji,
          },
        );

        return CommentModel.fromPiefed(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<CommentModel> boost(PostType postType, int commentId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId/vote/1';

        final response = await client.put(path);

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
    required String lang,
    XFile? image,
    String? alt,
    bool isAdult = false,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        if (image == null) {
          final path =
              '/${_postTypeMbin[postType]}/$postId/comments${parentCommentId != null ? '/$parentCommentId/reply' : ''}';

          final response = await client.post(
            path,
            body: {'body': body, 'lang': lang},
          );

          return CommentModel.fromMbin(response.bodyJson);
        } else {
          final path =
              '/${_postTypeMbin[postType]}/$postId/comments${parentCommentId != null ? '/$parentCommentId/reply' : ''}/image';

          final request = http.MultipartRequest(
            'POST',
            Uri.https(client.domain, client.software.apiPathPrefix + path),
          );
          final file = http.MultipartFile.fromBytes(
            'uploadImage',
            await image.readAsBytes(),
            filename: basename(image.path),
            contentType: MediaType.parse(lookupMimeType(image.path)!),
          );
          request.files.add(file);
          request.fields['body'] = body;
          request.fields['lang'] = lang;
          request.fields['isAdult'] = isAdult.toString();
          request.fields['alt'] = alt ?? '';

          final response = await client.sendRequest(request);

          return CommentModel.fromMbin(response.bodyJson);
        }

      case ServerSoftware.lemmy:
        const path = '/comment';

        final response = await client.post(
          path,
          body: {
            'content': body,
            'post_id': postId,
            'parent_id': parentCommentId,
            'language_id': await client.languageIdFromCode(lang),
          },
        );

        return CommentModel.fromLemmy(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/comment';

        final response = await client.post(
          path,
          body: {
            'body': body,
            'post_id': postId,
            if (parentCommentId != null) 'parent_id': parentCommentId,
            'language_id': await client.languageIdFromCode(lang),
          },
        );

        return CommentModel.fromPiefed(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
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

        final response = await client.put(path, body: {'body': body});

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/comment';

        final response = await client.put(
          path,
          body: {'comment_id': commentId, 'content': body},
        );

        return CommentModel.fromLemmy(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/comment';

        final response = await client.put(
          path,
          body: {'comment_id': commentId, 'body': body},
        );

        return CommentModel.fromPiefed(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<void> delete(PostType postType, int commentId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId';

        final response = await client.delete(path);

      case ServerSoftware.lemmy:
        const path = '/comment/delete';

        final response = await client.post(
          path,
          body: {'comment_id': commentId, 'deleted': true},
        );

      case ServerSoftware.piefed:
        const path = '/comment/delete';

        final response = await client.post(
          path,
          body: {'comment_id': commentId, 'deleted': true},
        );
    }
  }

  Future<void> report(PostType postType, int commentId, String reason) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/${_postTypeMbinComment[postType]}/$commentId/report';

        final response = await client.post(path, body: {'reason': reason});

      case ServerSoftware.lemmy:
        const path = '/comment/report';

        final response = await client.post(
          path,
          body: {'comment_id': commentId, 'reason': reason},
        );

      case ServerSoftware.piefed:
        const path = '/comment/report';

        final response = await client.post(
          path,
          body: {'comment_id': commentId, 'reason': reason},
        );
    }
  }
}
