import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/magazine.dart';
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

class APIMagazines {
  final ServerClient client;

  APIMagazines(this.client);

  Future<DetailedMagazineListModel> list({
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

        return DetailedMagazineListModel.fromMbin(response.bodyJson);

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
                'Can not filter magazines by blocked on Lemmy',
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

          return DetailedMagazineListModel.fromLemmy(json);
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
                'Can not filter magazines by blocked on Lemmy',
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

          return DetailedMagazineListModel.fromLemmy(json);
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
                'Can not filter magazines by blocked on Lemmy',
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

          return DetailedMagazineListModel.fromPiefed(json);
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
                'Can not filter magazines by blocked on Lemmy',
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

          return DetailedMagazineListModel.fromPiefed(json);
        }
    }
  }

  Future<DetailedMagazineModel> get(int magazineId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$magazineId';

        final response = await client.get(path);

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community';
        final query = {'id': magazineId.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedMagazineModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community';
        final query = {'id': magazineId.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedMagazineModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedMagazineModel> getByName(String magazineName) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/name/$magazineName';

        final response = await client.get(path);

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community';
        final query = {'name': magazineName.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedMagazineModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community';
        final query = {'name': magazineName.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedMagazineModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedMagazineModel> subscribe(int magazineId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/magazine/$magazineId/${state ? 'subscribe' : 'unsubscribe'}';

        final response = await client.put(path);

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community/follow';

        final response = await client.post(
          path,
          body: {'community_id': magazineId, 'follow': state},
        );

        return DetailedMagazineModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community/follow';

        final response = await client.post(
          path,
          body: {'community_id': magazineId, 'follow': state},
        );

        return DetailedMagazineModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedMagazineModel> block(int magazineId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/magazine/$magazineId/${state ? 'block' : 'unblock'}';

        final response = await client.put(path);

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community/block';

        final response = await client.post(
          path,
          body: {'community_id': magazineId, 'block': state},
        );

        return DetailedMagazineModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community/block';

        final response = await client.post(
          path,
          body: {'community_id': magazineId, 'block': state},
        );

        return DetailedMagazineModel.fromPiefed(response.bodyJson);
    }
  }
}
