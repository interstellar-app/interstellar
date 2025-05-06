import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

const Map<FeedSort, String> lemmyFeedSortMap = {
  FeedSort.active: 'Active',
  FeedSort.hot: 'Hot',
  FeedSort.newest: 'New',
  FeedSort.oldest: 'Old',
  FeedSort.top: 'TopAll',
  FeedSort.commented: 'MostComments',
  FeedSort.topDay: 'TopDay',
  FeedSort.topWeek: 'TopWeek',
  FeedSort.topMonth: 'TopMonth',
  FeedSort.topYear: 'TopYear',
  FeedSort.newComments: 'NewComments',
  FeedSort.topHour: 'TopHour',
  FeedSort.topSixHour: 'TopSixHour',
  FeedSort.topTwelveHour: 'TopTwelveHour',
  FeedSort.topThreeMonths: 'TopThreeMonths',
  FeedSort.topSixMonths: 'TopSixMonths',
  FeedSort.topNineMonths: 'TopNineMonths',
  FeedSort.controversial: 'Controversial',
  FeedSort.scaled: 'Scaled',
};

class APIThreads {
  final ServerClient client;

  APIThreads(this.client);

  Future<PostListModel> list(
    FeedSource source, {
    int? sourceId,
    String? page,
    FeedSort? sort,
    List<String>? langs,
    bool? usePreferredLangs,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = switch (source) {
          FeedSource.all => '/entries',
          FeedSource.local => '/entries',
          FeedSource.subscribed => '/entries/subscribed',
          FeedSource.moderated => '/entries/moderated',
          FeedSource.favorited => '/entries/favourited',
          FeedSource.magazine => '/magazine/${sourceId!}/entries',
          FeedSource.user => '/users/${sourceId!}/entries',
          FeedSource.domain => '/domain/${sourceId!}/entries',
        };
        final query = {
          'p': page,
          'sort': mbinGetSort(sort)?.name,
          'time': mbinGetSortTime(sort),
          'lang': langs?.join(','),
          'usePreferredLangs': (usePreferredLangs ?? false).toString(),
          if (source == FeedSource.local) 'federation': 'local',
        };

        final response = await client.get(path, queryParams: query);

        return PostListModel.fromMbinEntries(response.bodyJson);

      case ServerSoftware.lemmy:
        if (source == FeedSource.user) {
          const path = '/user';
          final query = {
            'person_id': sourceId.toString(),
            'page': page,
            'sort': lemmyFeedSortMap[sort]
          };

          final response = await client.get(path, queryParams: query);

          final json = response.bodyJson;

          json['next_page'] =
              lemmyCalcNextIntPage(json['posts'] as List<dynamic>, page);

          return PostListModel.fromLemmy(json);
        }

        const path = '/post/list';
        final query = {
          'page_cursor': page,
          'sort': lemmyFeedSortMap[sort],
        }..addAll(switch (source) {
            FeedSource.all => {'type_': 'All'},
            FeedSource.local => {'type_': 'Local'},
            FeedSource.subscribed => {'type_': 'Subscribed'},
            FeedSource.moderated => {'type_': 'ModeratorView'},
            FeedSource.favorited => {'liked_only': 'true'},
            FeedSource.magazine => {'community_id': sourceId!.toString()},
            FeedSource.user =>
              throw Exception('User source not allowed for lemmy'),
            FeedSource.domain =>
              throw Exception('Domain source not allowed for lemmy'),
          });

        final response = await client.get(path, queryParams: query);

        return PostListModel.fromLemmy(response.bodyJson);

      case ServerSoftware.piefed:
        if (source == FeedSource.user) {
          const path = '/user';
          final query = {
            'person_id': sourceId.toString(),
            'page': page,
            'sort': lemmyFeedSortMap[sort]
          };

          final response = await client.get(path, queryParams: query);

          final json = response.bodyJson;

          json['next_page'] =
              lemmyCalcNextIntPage(json['posts'] as List<dynamic>, page);

          return PostListModel.fromPiefed(json);
        }

        const path = '/post/list';
        final query = {
          'page_cursor': page,
          'sort': lemmyFeedSortMap[sort],
        }..addAll(switch (source) {
            FeedSource.all => {'type_': 'All'},
            FeedSource.local => {'type_': 'Local'},
            FeedSource.subscribed => {'type_': 'Subscribed'},
            FeedSource.moderated => {'type_': 'ModeratorView'},
            FeedSource.favorited => {'liked_only': 'true'},
            FeedSource.magazine => {'community_id': sourceId!.toString()},
            FeedSource.user =>
              throw Exception('User source not allowed for fromPiefed'),
            FeedSource.domain =>
              throw Exception('Domain source not allowed for fromPiefed'),
          });

        final response = await client.get(path, queryParams: query);

        return PostListModel.fromPiefed(response.bodyJson);
    }
  }

  Future<PostModel> get(int postId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/entry/$postId';

        final response = await client.get(path);

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/post';
        final query = {'id': postId.toString()};

        final response = await client.get(path, queryParams: query);

        return PostModel.fromLemmy(response.bodyJson['post_view'] as JsonMap);

      case ServerSoftware.piefed:
        const path = '/post';
        final query = {'id': postId.toString()};

        final response = await client.get(path, queryParams: query);

        return PostModel.fromPiefed(response.bodyJson['post_view'] as JsonMap);
    }
  }

  Future<PostModel> vote(int postId, int choice, int newScore) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = choice == 1
            ? '/entry/$postId/favourite'
            : '/entry/$postId/vote/$choice';

        final response = await client.put(path);

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        final response = await client.post(
          '/post/like',
          body: {
            'post_id': postId,
            'score': newScore,
          },
        );

        return PostModel.fromLemmy(response.bodyJson['post_view'] as JsonMap);

      case ServerSoftware.piefed:
        final response = await client.post(
          '/post/like',
          body: {
            'post_id': postId,
            'score': newScore,
          },
        );

        return PostModel.fromPiefed(response.bodyJson['post_view'] as JsonMap);
    }
  }

  Future<PostModel> boost(int postId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/entry/$postId/vote/1';

        final response = await client.put(path);

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Tried to boost on lemmy');

      case ServerSoftware.piefed:
        throw Exception('Tried to boost on piefed');
    }
  }

  Future<PostModel> edit(
    int entryID,
    String title,
    bool? isOc,
    String body,
    String? lang,
    bool? isAdult,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/entry/$entryID';

        final response = await client.put(
          path,
          body: {
            'title': title,
            'tags': [],
            'isOc': isOc,
            'body': body,
            'lang': lang,
            'isAdult': isAdult
          },
        );

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/post';

        final response = await client.put(
          path,
          body: {
            'post_id': entryID,
            'name': title,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromLemmy(response.bodyJson['post_view'] as JsonMap);

      case ServerSoftware.piefed:
        const path = '/post';

        final response = await client.put(
          path,
          body: {
            'post_id': entryID,
            'name': title,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromPiefed(response.bodyJson['post_view'] as JsonMap);
    }
  }

  Future<void> delete(int postID) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final response = await client.delete('/entry/$postID');

        break;

      case ServerSoftware.lemmy:
        final response = await client.post(
          '/post/delete',
          body: {
            'post_id': postID,
            'deleted': true,
          },
        );

        break;

      case ServerSoftware.piefed:
        final response = await client.post(
          '/post/delete',
          body: {
            'post_id': postID,
            'deleted': true,
          },
        );

        break;
    }
  }

  Future<PostModel> createArticle(
    int magazineID, {
    required String title,
    required bool isOc,
    required String body,
    required String lang,
    required bool isAdult,
    required List<String> tags,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$magazineID/article';

        final response = await client.post(
          path,
          body: {
            'title': title,
            'tags': tags,
            'isOc': isOc,
            'body': body,
            'lang': lang,
            'isAdult': isAdult
          },
        );

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'name': title,
            'community_id': magazineID,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromLemmy(response.bodyJson['post_view'] as JsonMap);

      case ServerSoftware.piefed:
        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'title': title,
            'community_id': magazineID,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromPiefed(response.bodyJson['post_view'] as JsonMap);
    }
  }

  Future<PostModel> createLink(
    int magazineID, {
    required String title,
    required String url,
    required bool isOc,
    required String body,
    required String lang,
    required bool isAdult,
    required List<String> tags,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$magazineID/link';

        final response = await client.post(
          path,
          body: {
            'title': title,
            'url': url,
            'tags': tags,
            'isOc': isOc,
            'body': body,
            'lang': lang,
            'isAdult': isAdult
          },
        );

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'name': title,
            'community_id': magazineID,
            'url': url,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromLemmy(response.bodyJson['post_view'] as JsonMap);

      case ServerSoftware.piefed:
        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'title': title,
            'community_id': magazineID,
            'url': url,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromPiefed(response.bodyJson['post_view'] as JsonMap);
    }
  }

  Future<PostModel> createImage(
    int magazineID, {
    required String title,
    required XFile image,
    required String alt,
    required bool isOc,
    required String body,
    required String lang,
    required bool isAdult,
    required List<String> tags,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$magazineID/image';

        var request = http.MultipartRequest('POST',
            Uri.https(client.domain, client.software.apiPathPrefix + path));
        var multipartFile = http.MultipartFile.fromBytes(
          'uploadImage',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        request.fields['title'] = title;
        for (int i = 0; i < tags.length; i++) {
          request.fields['tags[$i]'] = tags[i];
        }
        request.fields['isOc'] = isOc.toString();
        request.fields['body'] = body;
        request.fields['lang'] = lang;
        request.fields['isAdult'] = isAdult.toString();
        request.fields['alt'] = alt;
        var response = await client.sendRequest(request);

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        const pictrsPath = '/pictrs/image';

        var request =
            http.MultipartRequest('POST', Uri.https(client.domain, pictrsPath));
        var multipartFile = http.MultipartFile.fromBytes(
          'images[]',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        var pictrsResponse = await client.sendRequest(request);

        final json = jsonDecode(pictrsResponse.body) as JsonMap;

        final imageName = ((json['files'] as List<Object?>).first
            as JsonMap)['file'] as String?;

        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'name': title,
            'community_id': magazineID,
            'url': 'https://${client.domain}/pictrs/image/$imageName',
            'body': body,
            'nsfw': isAdult,
            'alt_text': nullIfEmpty(alt),
          },
        );

        return PostModel.fromLemmy(response.bodyJson['post_view'] as JsonMap);

      case ServerSoftware.piefed:
        const uploadPath = '/upload/image';

        var request = http.MultipartRequest(
            'POST',
            Uri.https(
                client.domain, client.software.apiPathPrefix + uploadPath));
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        var uploadResponse = await client.sendRequest(request);

        final json = uploadResponse.bodyJson;

        final imageUrl = json['url'] as String?;

        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'title': title,
            'community_id': magazineID,
            'url': imageUrl,
            'body': body,
            'nsfw': isAdult
          },
        );

        return PostModel.fromPiefed(response.bodyJson['post_view'] as JsonMap);
    }
  }

  Future<void> report(int postId, String reason) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/entry/$postId/report';

        final response = await client.post(
          path,
          body: {'reason': reason},
        );

      case ServerSoftware.lemmy:
        const path = '/post/report';

        final response = await client.post(
          path,
          body: {
            'post_id': postId,
            'reason': reason,
          },
        );

      case ServerSoftware.piefed:
        const path = '/post/report';

        final response = await client.post(
          path,
          body: {
            'post_id': postId,
            'reason': reason,
          },
        );
    }
  }

  Future<void> markAsRead(List<int> postIds, bool read) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw UnsupportedError('Mbin doesnt support marking posts as read');
      case ServerSoftware.lemmy:
        const path = '/post/mark_as_read';

        final response = await client.post(path, body: {
          'post_ids': postIds,
          'read': read,
        });
      case ServerSoftware.piefed:
        throw UnsupportedError('Piefed doesnt support marking posts as read');
    }
  }
}
