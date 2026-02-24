import 'package:collection/collection.dart';
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
  APIThreads(this.client);

  final ServerClient client;

  Future<PostListModel> list(
    FeedSource source, {
    int? sourceId,
    String? page,
    FeedSort? sort,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = switch (source) {
          FeedSource.all => '/entries',
          FeedSource.local => '/entries',
          FeedSource.subscribed => '/entries/subscribed',
          FeedSource.moderated => '/entries/moderated',
          FeedSource.favorited => '/entries/favourited',
          FeedSource.community => '/magazine/${sourceId!}/entries',
          FeedSource.user => '/users/${sourceId!}/entries',
          FeedSource.domain => '/domain/${sourceId!}/entries',
          FeedSource.feed => throw Exception(
            'Feeds source not allowed for mbin',
          ),
          FeedSource.topic => throw Exception(
            'Topics source not allowed for mbin',
          ),
        };
        final query = {
          'p': page,
          'sort': mbinGetSort(sort)?.name,
          'time': mbinGetSortTime(sort),
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
            'sort': lemmyFeedSortMap[sort],
          };

          final response = await client.get(path, queryParams: query);

          final json = response.bodyJson;

          json['next_page'] = lemmyCalcNextIntPage(
            json['posts']! as List<dynamic>,
            page,
          );

          return PostListModel.fromLemmy(
            json,
            langCodeIdPairs: await client.languageCodeIdPairs(),
          );
        }

        const path = '/post/list';
        final query = {'page_cursor': page, 'sort': lemmyFeedSortMap[sort]}
          ..addAll(switch (source) {
            FeedSource.all => {'type_': 'All'},
            FeedSource.local => {'type_': 'Local'},
            FeedSource.subscribed => {'type_': 'Subscribed'},
            FeedSource.moderated => {'type_': 'ModeratorView'},
            FeedSource.favorited => {'liked_only': 'true'},
            FeedSource.community => {'community_id': sourceId!.toString()},
            FeedSource.user => throw UnreachableError(),
            FeedSource.domain => throw Exception(
              'Domain source not allowed for lemmy',
            ),
            FeedSource.feed => throw Exception(
              'Feeds source not allowed for lemmy',
            ),
            FeedSource.topic => throw Exception(
              'Topics source not allowed for lemmy',
            ),
          });

        final response = await client.get(path, queryParams: query);

        return PostListModel.fromLemmy(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/post/list';
        final query = {'page': page, 'sort': lemmyFeedSortMap[sort]}
          ..addAll(switch (source) {
            FeedSource.all => {'type_': 'All'},
            FeedSource.local => {'type_': 'Local'},
            FeedSource.subscribed => {'type_': 'Subscribed'},
            FeedSource.moderated => {'type_': 'ModeratorView'},
            FeedSource.favorited => {'liked_only': 'true'},
            FeedSource.community => {'community_id': sourceId!.toString()},
            FeedSource.user => {'person_id': sourceId.toString()},
            FeedSource.domain => throw Exception(
              'Domain source not allowed for fromPiefed',
            ),
            FeedSource.feed => {'feed_id': sourceId.toString()},
            FeedSource.topic => {'topic_id': sourceId.toString()},
          });

        final response = await client.get(path, queryParams: query);

        return PostListModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
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

        return PostModel.fromLemmy(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/post';
        final query = {'id': postId.toString()};

        final response = await client.get(path, queryParams: query);

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<PostModel> vote(
    int postId,
    int choice,
    int newScore, {
    String? emoji,
  }) async {
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
          body: {'post_id': postId, 'score': newScore},
        );

        return PostModel.fromLemmy(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        final response = await client.post(
          '/post/like',
          body: {'post_id': postId, 'score': newScore, 'emoji': ?emoji},
        );

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
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

  Future<PostModel> votePoll(int postId, List<int> choiceIds) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Tried to vote on a poll on mbin');
      case ServerSoftware.lemmy:
        throw Exception('Tried to vote on a poll on lemmy');
      case ServerSoftware.piefed:
        const path = '/post/poll_vote';
        final response = await client.post(
          path,
          body: {'post_id': postId, 'choice_id': choiceIds},
        );
        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<PostModel> edit(
    int postId,
    String title,
    bool? isOc,
    String body,
    String? lang,
    bool? isAdult,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/entry/$postId';

        final response = await client.put(
          path,
          body: {
            'title': title,
            'tags': [],
            'isOc': isOc,
            'body': body,
            'lang': lang,
            'isAdult': isAdult,
          },
        );

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/post';

        final response = await client.put(
          path,
          body: {
            'post_id': postId,
            'name': title,
            'body': body,
            'nsfw': isAdult,
          },
        );

        return PostModel.fromLemmy(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/post';

        final response = await client.put(
          path,
          body: {
            'post_id': postId,
            'name': title,
            'body': body,
            'nsfw': isAdult,
          },
        );

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<void> delete(int postID) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final response = await client.delete('/entry/$postID');

        return;

      case ServerSoftware.lemmy:
        final response = await client.post(
          '/post/delete',
          body: {'post_id': postID, 'deleted': true},
        );

        return;

      case ServerSoftware.piefed:
        final response = await client.post(
          '/post/delete',
          body: {'post_id': postID, 'deleted': true},
        );

        return;
    }
  }

  Future<PostModel> assignFlairs(int postId, List<int> flairIds) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw UnsupportedError(
          'Mbin doesnt support assigning flairs to a post',
        );
      case ServerSoftware.lemmy:
        throw UnsupportedError(
          'Lemmy doesnt support assigning flairs to a post',
        );
      case ServerSoftware.piefed:
        const path = '/post/assign_flair';
        final response = await client.post(
          path,
          body: {'post_id': postId, 'flair_id_list': flairIds},
        );

        return PostModel.fromPiefed({
          'post_view': response.bodyJson,
        }, langCodeIdPairs: await client.languageCodeIdPairs());
    }
  }

  Future<PostModel> create({
    required int communityId,
    required String title,
    required String lang,
    String? body,
    String? url,
    XFile? image,
    String? alt,
    bool isAdult = false,
    bool isOc = false,
    List<String> tags = const [],
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        assert(
          body?.isNotEmpty != null || url?.isNotEmpty != null || image != null,
          'Post needs either a body an url or an image.',
        );
        tags = tags.where((tag) => tag.isNotEmpty).toList();

        final path = '/magazine/$communityId/entries';

        final response = await client.postMultipart(
          path,
          builder: (request) async {
            request.fields['title'] = title;
            if (url != null) {
              request.fields['url'] = url;
            }
            for (var i = 0; i < tags.length; ++i) {
              request.fields['tags[$i]'] = tags[i];
            }
            request.fields['isOc'] = isOc.toString();
            if (body != null && body.isNotEmpty) {
              request.fields['body'] = body;
            }
            request.fields['lang'] = lang;
            request.fields['isAdult'] = isAdult.toString();
            if (alt != null) {
              request.fields['alt'] = alt;
            }
            if (image != null) {
              final file = http.MultipartFile.fromBytes(
                'uploadImage',
                await image.readAsBytes(),
                filename: image.name,
                contentType: MediaType.parse(
                  image.mimeType ?? lookupMimeType(image.path)!,
                ),
              );
              request.files.add(file);
            }
          },
        );

        return PostModel.fromMbinEntry(response.bodyJson);

      case ServerSoftware.lemmy:
        if (image != null) {
          const uploadPath = '/pictrs/image';

          final pictrsResponse = await client.postMultipart(
            uploadPath,
            builder: (request) async {
              final multipartFile = http.MultipartFile.fromBytes(
                'images[]',
                await image.readAsBytes(),
                filename: image.name,
                contentType: MediaType.parse(
                  image.mimeType ?? lookupMimeType(image.path)!,
                ),
              );
              request.files.add(multipartFile);
            },
          );

          final imageName =
              ((pictrsResponse.bodyJson['files']! as List<Object?>).first!
                      as JsonMap)['file']
                  as String?;

          url = 'https://${client.domain}/pictrs/image/$imageName';
        }

        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'name': title,
            'community_id': communityId,
            'url': url,
            'body': body,
            'nsfw': isAdult,
            'alt_text': alt,
            'language_id': await client.languageIdFromCode(lang),
          },
        );

        return PostModel.fromLemmy(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        if (image != null) {
          const uploadPath = '/upload/image';

          final uploadResponse = await client.postMultipart(
            uploadPath,
            builder: (request) async {
              final multipartFile = http.MultipartFile.fromBytes(
                'file',
                await image.readAsBytes(),
                filename: image.name,
                contentType: MediaType.parse(
                  image.mimeType ?? lookupMimeType(image.path)!,
                ),
              );
              request.files.add(multipartFile);
            },
          );

          final imageUrl = uploadResponse.bodyJson['url'] as String?;

          url = imageUrl;
        }

        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'title': title,
            'community_id': communityId,
            'url': url,
            'body': body,
            'nsfw': isAdult,
            'alt_text': alt,
            'language_id': await client.languageIdFromCode(lang),
          },
        );

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<PostModel> createPoll(
    int communityId, {
    required String title,
    required bool isOc,
    required String body,
    required String lang,
    required bool isAdult,
    required List<String> choices,
    required DateTime? endDate,
    required String mode,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw UnimplementedError('Polls are unsupported on mbin');

      case ServerSoftware.lemmy:
        throw UnimplementedError('Polls are unsupported on lemmy');

      case ServerSoftware.piefed:
        const path = '/post';
        final response = await client.post(
          path,
          body: {
            'title': title,
            'community_id': communityId,
            'body': body,
            'nsfw': isAdult,
            'language_id': await client.languageIdFromCode(lang),
            'poll': {
              if (endDate != null)
                'end_poll': endDate.toUtc().toIso8601String(),
              'mode': mode,
              'choices': choices
                  .mapIndexed(
                    (index, choice) => {
                      'id': index,
                      'choice_text': choice,
                      'sort_order': index,
                    },
                  )
                  .toList(),
            },
          },
        );

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<void> report(int postId, String reason) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/entry/$postId/report';

        final response = await client.post(path, body: {'reason': reason});

      case ServerSoftware.lemmy:
        const path = '/post/report';

        final response = await client.post(
          path,
          body: {'post_id': postId, 'reason': reason},
        );

      case ServerSoftware.piefed:
        const path = '/post/report';

        final response = await client.post(
          path,
          body: {'post_id': postId, 'reason': reason},
        );
    }
  }

  Future<void> markAsRead(List<int> postIds, bool read) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw UnsupportedError('Mbin doesnt support marking posts as read');
      case ServerSoftware.lemmy:
        const path = '/post/mark_as_read';

        final response = await client.post(
          path,
          body: {'post_ids': postIds, 'read': read},
        );
      case ServerSoftware.piefed:
        const path = '/post/mark_as_read';

        final response = await client.post(
          path,
          body: {'post_ids': postIds, 'read': read},
        );
    }
  }
}
