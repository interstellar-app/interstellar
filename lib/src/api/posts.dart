import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class APIPosts {
  final ServerSoftware software;
  final http.Client httpClient;
  final String server;

  APIPosts(
    this.software,
    this.httpClient,
    this.server,
  );

  Future<PostListModel> list(
    FeedSource source, {
    String? page,
    FeedSort? sort,
    List<String>? langs,
    bool? usePreferredLangs,
  }) async {
    if (source.getPostsPath() == null) {
      throw Exception('Failed to load posts');
    }

    final path = source.getPostsPath()!;
    final query = queryParams({
      'p': page,
      'sort': sort?.name,
      'lang': langs?.join(','),
      'usePreferredLangs': (usePreferredLangs ?? false).toString(),
    });

    final response = await httpClient.get(Uri.https(server, path, query));

    httpErrorHandler(response, message: 'Failed to load posts');

    return PostListModel.fromKbinPosts(
        jsonDecode(response.body) as Map<String, Object?>);
  }

  Future<PostModel> get(int postId) async {
    final path = '/api/post/$postId';

    final response = await httpClient.get(Uri.https(server, path));

    httpErrorHandler(response, message: 'Failed to load posts');

    return PostModel.fromKbinPost(
        jsonDecode(response.body) as Map<String, Object?>);
  }

  Future<PostModel> putVote(int postID, int choice) async {
    final path = '/api/post/$postID/vote/$choice';

    final response = await httpClient.put(Uri.https(server, path));

    httpErrorHandler(response, message: 'Failed to send vote');

    return PostModel.fromKbinPost(
        jsonDecode(response.body) as Map<String, Object?>);
  }

  Future<PostModel> putFavorite(int postID) async {
    final path = '/api/post/$postID/favourite';

    final response = await httpClient.put(Uri.https(server, path));

    httpErrorHandler(response, message: 'Failed to send vote');

    return PostModel.fromKbinPost(
        jsonDecode(response.body) as Map<String, Object?>);
  }

  Future<PostModel> edit(
    int postID,
    String body,
    String lang,
    bool isAdult,
  ) async {
    final path = '/api/post/$postID';

    final response = await httpClient.put(
      Uri.https(server, path),
      body: jsonEncode({'body': body, 'lang': lang, 'isAdult': isAdult}),
    );

    httpErrorHandler(response, message: "Failed to edit post");

    return PostModel.fromKbinPost(
        jsonDecode(response.body) as Map<String, Object?>);
  }

  Future<void> delete(
    int postID,
  ) async {
    final path = '/api/post/$postID';

    final response = await httpClient.delete(Uri.https(server, path));

    httpErrorHandler(response, message: "Failed to delete post");
  }

  Future<PostModel> create(
    int magazineID, {
    required String body,
    required String lang,
    required bool isAdult,
  }) async {
    final path = '/api/magazine/$magazineID/posts';

    final response = await httpClient.post(Uri.https(server, path),
        body: jsonEncode({'body': body, 'lang': lang, 'isAdult': isAdult}));

    httpErrorHandler(response, message: "Failed to create post");

    return PostModel.fromKbinPost(
        jsonDecode(response.body) as Map<String, Object?>);
  }

  Future<PostModel> createImage(
    int magazineID, {
    required XFile image,
    required String alt,
    required String body,
    required String lang,
    required bool isAdult,
  }) async {
    final path = '/api/magazine/$magazineID/posts/image';

    var request = http.MultipartRequest('POST', Uri.https(server, path));

    var multipartFile = http.MultipartFile.fromBytes(
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
    var response =
        await http.Response.fromStream(await httpClient.send(request));

    httpErrorHandler(response, message: "Failed to create post");

    return PostModel.fromKbinPost(
        jsonDecode(response.body) as Map<String, Object?>);
  }
}
