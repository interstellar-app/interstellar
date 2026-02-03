import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

enum APIExploreSort {
  hot,
  active,
  newest,

  //lemmy specific
  oldest,
  mostComments,
  newComments,
  controversial,
  scaled,

  topAll,
  topDay,
  topWeek,
  topMonth,
  topYear,
  topHour,
  topSixHour,
  topTwelveHour,
  topThreeMonths,
  topSixMonths,
  topNineMonths;

  static List<APIExploreSort> valuesBySoftware(ServerSoftware software) =>
      switch (software) {
        ServerSoftware.mbin => [hot, active, newest],
        ServerSoftware.lemmy => values,
        ServerSoftware.piefed => [hot, topAll, newest, active],
      };

  String nameBySoftware(ServerSoftware software) => switch (software) {
    ServerSoftware.mbin => switch (this) {
      APIExploreSort.active => 'active',
      APIExploreSort.hot => 'hot',
      APIExploreSort.newest => 'newest',
      _ => 'hot',
    },
    ServerSoftware.lemmy => switch (this) {
      APIExploreSort.active => 'Active',
      APIExploreSort.hot => 'Hot',
      APIExploreSort.newest => 'New',
      APIExploreSort.topAll => 'TopAll',
      APIExploreSort.oldest => 'Old',
      APIExploreSort.mostComments => 'MostComments',
      APIExploreSort.newComments => 'NewComments',
      APIExploreSort.topDay => 'TopDay',
      APIExploreSort.topWeek => 'TopWeek',
      APIExploreSort.topMonth => 'TopMonth',
      APIExploreSort.topYear => 'TopYear',
      APIExploreSort.topHour => 'TopHour',
      APIExploreSort.topSixHour => 'TopSixHour',
      APIExploreSort.topTwelveHour => 'TopTwelveHour',
      APIExploreSort.topThreeMonths => 'TopThreeMonths',
      APIExploreSort.topSixMonths => 'TopSixMonths',
      APIExploreSort.topNineMonths => 'TopNineMonths',
      APIExploreSort.controversial => 'Controversial',
      APIExploreSort.scaled => 'Scaled',
    },
    ServerSoftware.piefed => switch (this) {
      APIExploreSort.active => 'Active',
      APIExploreSort.hot => 'Hot',
      APIExploreSort.newest => 'New',
      APIExploreSort.topAll => 'Top',
      _ => 'Hot',
    },
  };
}

class APICommunity {
  final ServerClient client;

  APICommunity(this.client);

  Future<DetailedCommunityListModel> list({
    String? page,
    ExploreFilter? filter,
    APIExploreSort sort = APIExploreSort.hot,
    String? search,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            (filter == null ||
                filter == ExploreFilter.all ||
                filter == ExploreFilter.local)
            ? '/magazines'
            : '/magazines/${filter.name}';
        final query = {
          'p': page,
          if (filter == null ||
              filter == ExploreFilter.all ||
              filter == ExploreFilter.local) ...{
            'sort': sort.nameBySoftware(client.software),
            'q': search,
            'federation': filter == ExploreFilter.local ? 'local' : null,
          },
        };

        final response = await client.get(path, queryParams: query);

        return DetailedCommunityListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        if (search == null) {
          const path = '/community/list';
          final query = {
            'type_': switch (filter) {
              ExploreFilter.all => 'All',
              ExploreFilter.local => 'Local',
              ExploreFilter.moderated => 'ModeratorView',
              ExploreFilter.subscribed => 'Subscribed',
              ExploreFilter.blocked => throw Exception(
                'Can not filter communities by blocked on Lemmy',
              ),
              null => 'All',
            },
            'limit': '50',
            'sort': sort.nameBySoftware(client.software),
            'page': page,
          };

          final response = await client.get(path, queryParams: query);

          final json = response.bodyJson;

          json['next_page'] = lemmyCalcNextIntPage(
            json['communities'] as List<dynamic>,
            page,
          );

          return DetailedCommunityListModel.fromLemmy(json);
        } else {
          const path = '/search';
          final query = {
            'type_': 'Communities',
            'listing_type': switch (filter) {
              ExploreFilter.all => 'All',
              ExploreFilter.local => 'Local',
              ExploreFilter.moderated => 'ModeratorView',
              ExploreFilter.subscribed => 'Subscribed',
              ExploreFilter.blocked => throw Exception(
                'Can not filter communities by blocked on Lemmy',
              ),
              null => 'All',
            },
            'limit': '50',
            'sort': sort.nameBySoftware(client.software),
            'page': page,
            'q': search,
          };

          final response = await client.get(path, queryParams: query);

          final json = response.bodyJson;

          json['next_page'] = lemmyCalcNextIntPage(
            json['communities'] as List<dynamic>,
            page,
          );

          return DetailedCommunityListModel.fromLemmy(json);
        }

      case ServerSoftware.piefed:
        if (search == null) {
          const path = '/community/list';
          final query = {
            'type_': switch (filter) {
              ExploreFilter.all => 'All',
              ExploreFilter.local => 'Local',
              ExploreFilter.moderated => 'ModeratorView',
              ExploreFilter.subscribed => 'Subscribed',
              ExploreFilter.blocked => throw Exception(
                'Can not filter communities by blocked on Lemmy',
              ),
              null => 'All',
            },
            'limit': '50',
            'sort': sort.nameBySoftware(client.software),
            'page': page,
          };

          final response = await client.get(path, queryParams: query);

          return DetailedCommunityListModel.fromPiefed(response.bodyJson);
        } else {
          const path = '/search';
          final query = {
            'type_': 'Communities',
            'listing_type': switch (filter) {
              ExploreFilter.all => 'All',
              ExploreFilter.local => 'Local',
              ExploreFilter.moderated => 'ModeratorView',
              ExploreFilter.subscribed => 'Subscribed',
              ExploreFilter.blocked => throw Exception(
                'Can not filter communities by blocked on Lemmy',
              ),
              null => 'All',
            },
            'limit': '50',
            'sort': sort.nameBySoftware(client.software),
            'page': page,
            'q': search,
          };

          final response = await client.get(path, queryParams: query);

          return DetailedCommunityListModel.fromPiefed(response.bodyJson);
        }
    }
  }

  Future<DetailedCommunityModel> get(int communityId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$communityId';

        final response = await client.get(path);

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community';
        final query = {'id': communityId.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedCommunityModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community';
        final query = {'id': communityId.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedCommunityModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedCommunityModel> getByName(String communityName) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/name/$communityName';

        final response = await client.get(path);

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community';
        final query = {'name': communityName};

        final response = await client.get(path, queryParams: query);

        return DetailedCommunityModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community';
        final query = {'name': communityName};

        final response = await client.get(path, queryParams: query);

        return DetailedCommunityModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedCommunityModel> subscribe(int communityId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/magazine/$communityId/${state ? 'subscribe' : 'unsubscribe'}';

        final response = await client.put(path);

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community/follow';

        final response = await client.post(
          path,
          body: {'community_id': communityId, 'follow': state},
        );

        return DetailedCommunityModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community/follow';

        final response = await client.post(
          path,
          body: {'community_id': communityId, 'follow': state},
        );

        return DetailedCommunityModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedCommunityModel> block(int communityId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$communityId/${state ? 'block' : 'unblock'}';

        final response = await client.put(path);

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community/block';

        final response = await client.post(
          path,
          body: {'community_id': communityId, 'block': state},
        );

        return DetailedCommunityModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community/block';

        final response = await client.post(
          path,
          body: {'community_id': communityId, 'block': state},
        );

        return DetailedCommunityModel.fromPiefed(response.bodyJson);
    }
  }
}
