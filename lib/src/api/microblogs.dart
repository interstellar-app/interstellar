import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:interstellar/src/utils/utils.dart';

class MbinAPIMicroblogs {
  final ServerClient client;

  MbinAPIMicroblogs(this.client);

  Future<PostListModel> list(
    FeedSource source, {
    int? sourceId,
    String? page,
    FeedSort? sort,
  }) async {
    final path = switch (source) {
      FeedSource.all => '/posts',
      FeedSource.local => '/posts',
      FeedSource.subscribed => '/posts/subscribed',
      FeedSource.moderated => '/posts/moderated',
      FeedSource.favorited => '/posts/favourited',
      FeedSource.community => '/magazine/${sourceId!}/posts',
      FeedSource.user => '/users/${sourceId!}/posts',
      FeedSource.domain => throw Exception(
        'Domain source not allowed for microblog',
      ),
      FeedSource.feed => throw Exception('Feeds source not allowed for mbin'),
      FeedSource.topic => throw Exception('Topics source not allowed for mbin'),
    };

    final query = {
      'p': page,
      'sort': mbinGetSort(sort)?.name,
      'time': mbinGetSortTime(sort),
      if (source == FeedSource.local) 'federation': 'local',
    };

    final response = await client.get(path, queryParams: query);

    return PostListModel.fromMbinPosts(response.bodyJson);
  }

  Future<PostModel> get(int postId) async {
    final path = '/post/$postId';

    final response = await client.get(path);

    return PostModel.fromMbinPost(response.bodyJson);
  }

  Future<PostModel> putVote(int postID, int choice) async {
    final path = '/post/$postID/vote/$choice';

    final response = await client.put(path);

    return PostModel.fromMbinPost(response.bodyJson);
  }

  Future<PostModel> putFavorite(int postID) async {
    final path = '/post/$postID/favourite';

    final response = await client.put(path);

    return PostModel.fromMbinPost(response.bodyJson);
  }

  Future<PostModel> edit(
    int postID,
    String body,
    String lang,
    bool isAdult,
  ) async {
    final path = '/post/$postID';

    final response = await client.put(
      path,
      body: {'body': body, 'lang': lang, 'isAdult': isAdult},
    );

    return PostModel.fromMbinPost(response.bodyJson);
  }

  Future<void> delete(int postID) async {
    final path = '/post/$postID';

    final response = await client.delete(path);
  }

  Future<PostModel> create(
    int communityId, {
    required String body,
    required String lang,
    required bool isAdult,
  }) async {
    final path = '/magazine/$communityId/posts';

    final response = await client.post(
      path,
      body: {'body': body, 'lang': lang, 'isAdult': isAdult},
    );

    return PostModel.fromMbinPost(response.bodyJson);
  }

  Future<PostModel> createImage(
    int communityId, {
    required XFile image,
    required String alt,
    required String body,
    required String lang,
    required bool isAdult,
  }) async {
    final path = '/magazine/$communityId/posts/image';

    final request = http.MultipartRequest(
      'POST',
      Uri.https(client.domain, client.software.apiPathPrefix + path),
    );

    final multipartFile = http.MultipartFile.fromBytes(
      'uploadImage',
      await image.readAsBytes(),
      filename: basename(image.path),
      contentType: MediaType.parse(lookupMimeType(image.path)!),
    );
    request.files.add(multipartFile);
    request.fields['body'] = body;
    request.fields['lang'] = lang;
    request.fields['isAdult'] = isAdult.toString();
    request.fields['alt'] = alt;
    var response = await client.sendRequest(request);

    return PostModel.fromMbinPost(response.bodyJson);
  }

  Future<void> report(int postId, String reason) async {
    final path = '/post/$postId/report';

    final response = await client.post(path, body: {'reason': reason});
  }
}
