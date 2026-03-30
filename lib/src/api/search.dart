import 'package:extended_image/extended_image.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/search.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/utils/utils.dart';

class APISearch {
  APISearch(this.client);

  final ServerClient client;

  Future<SearchListModel> get({
    String? page,
    String? search,
    ExploreFilter? filter,
    int? communityId,
    int? userId,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/search';

        final response = await client.get(
          path,
          queryParams: {
            'p': page,
            'q': search,
            'authorId': userId?.toString(),
            'magazineId': communityId?.toString(),
          },
        );

        return SearchListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/search';
        final query = {
          'q': search,
          'page': page ?? '1',
          'type_': 'All',
          'listing_type': switch (filter) {
            ExploreFilter.all => 'All',
            ExploreFilter.local => 'Local',
            _ => 'All',
          },
          'community_id': communityId?.toString(),
          'creator_id': userId?.toString(),
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        String? nextPage;
        if ((json['comments']! as List<dynamic>).isNotEmpty ||
            (json['posts']! as List<dynamic>).isNotEmpty ||
            (json['communities']! as List<dynamic>).isNotEmpty ||
            (json['users']! as List<dynamic>).isNotEmpty) {
          nextPage = (int.parse(page ?? '1') + 1).toString();
        }

        json['next_page'] = nextPage;

        return SearchListModel.fromLemmy(
          json,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

      case ServerSoftware.piefed:
        const path = '/search';
        final query = {
          'q': search,
          'page': page ?? '1',
          // Only use "Posts" type until "All" type is supported in PieFed
          'type_': 'Posts',
          'listing_type': switch (filter) {
            ExploreFilter.all => 'All',
            ExploreFilter.local => 'Local',
            _ => 'All',
          },
          'community_id': communityId?.toString(),
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        String? nextPage;
        if ((json['comments']! as List<dynamic>).isNotEmpty ||
            (json['posts']! as List<dynamic>).isNotEmpty ||
            (json['communities']! as List<dynamic>).isNotEmpty ||
            (json['users']! as List<dynamic>).isNotEmpty) {
          nextPage = (int.parse(page ?? '1') + 1).toString();
        }

        json['next_page'] = nextPage;

        return SearchListModel.fromPiefed(
          json,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<dynamic> resolveObject(String search) async {
    try {
      switch (client.software) {
        case ServerSoftware.mbin:
          // using the search api here kinda works but is slow and throws 500 errors occasionally

          const path = '/search';

          final response = await client.get(path, queryParams: {'q': search});

          // get first of the ap objects found.
          final json = response.bodyJson;
          final actor = (json['apActors']! as List<dynamic>).firstOrNull;
          if (actor?['type'] == 'user')
            return DetailedUserModel.fromMbin(actor['object'] as JsonMap);
          if (actor?['type'] == 'magazine')
            return DetailedCommunityModel.fromMbin(actor['object'] as JsonMap);

          final object = (json['apObjects']! as List<dynamic>).firstOrNull;
          if (object?['itemType'] == 'entry')
            return PostModel.fromMbinEntry(object as JsonMap);
          if (object?['itemType'] == 'post')
            return PostModel.fromMbinPost(object as JsonMap);
          if (object?['itemType'] == 'entry_comment' ||
              object?['itemType'] == 'post_comment')
            return CommentModel.fromMbin(object as JsonMap);

          return null;

        case ServerSoftware.lemmy:
          const path = '/resolve_object';

          final response = await client.get(path, queryParams: {'q': search});

          final json = response.bodyJson;
          if (json['comment'] != null) {
            return CommentModel.fromPiefed(
              json['comment']! as JsonMap,
              langCodeIdPairs: await client.languageCodeIdPairs(),
            );
          } else if (json['post'] != null) {
            return PostModel.fromPiefed(
              json['post']! as JsonMap,
              langCodeIdPairs: await client.languageCodeIdPairs(),
            );
          } else if (json['community'] != null) {
            return DetailedCommunityModel.fromPiefed(
              json['community']! as JsonMap,
            );
          } else if (json['person'] != null) {
            return DetailedUserModel.fromPiefed(json['person']! as JsonMap);
          }
          return null;

        case ServerSoftware.piefed:
          const path = '/resolve_object';

          final response = await client.get(path, queryParams: {'q': search});

          final json = response.bodyJson;
          if (json['comment'] != null) {
            return CommentModel.fromPiefed(
              json['comment']! as JsonMap,
              langCodeIdPairs: await client.languageCodeIdPairs(),
            );
          } else if (json['post'] != null) {
            return PostModel.fromPiefed(
              json['post']! as JsonMap,
              langCodeIdPairs: await client.languageCodeIdPairs(),
            );
          } else if (json['community'] != null) {
            return DetailedCommunityModel.fromPiefed(
              json['community']! as JsonMap,
            );
          } else if (json['person'] != null) {
            return DetailedUserModel.fromPiefed(json['person']! as JsonMap);
          } else if (json['feed'] != null) {
            return FeedModel.fromPiefed(json['feed']! as JsonMap);
          }
          return null;
      }
    } on ClientException catch (e) {
      if (e.message.contains('No object found')) {
        return null;
      }
      rethrow;
    }
  }
}
