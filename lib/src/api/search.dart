import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/search.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';

class APISearch {
  final ServerClient client;

  APISearch(this.client);

  Future<SearchListModel> get({
    String? page,
    String? search,
    ExploreFilter? filter,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/search';

        final response = await client.get(
          path,
          queryParams: {'p': page, 'q': search},
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
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        String? nextPage;
        if ((json['comments'] as List<dynamic>).isNotEmpty ||
            (json['posts'] as List<dynamic>).isNotEmpty ||
            (json['communities'] as List<dynamic>).isNotEmpty ||
            (json['users'] as List<dynamic>).isNotEmpty) {
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
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        String? nextPage;
        if ((json['comments'] as List<dynamic>).isNotEmpty ||
            (json['posts'] as List<dynamic>).isNotEmpty ||
            (json['communities'] as List<dynamic>).isNotEmpty ||
            (json['users'] as List<dynamic>).isNotEmpty) {
          nextPage = (int.parse(page ?? '1') + 1).toString();
        }

        json['next_page'] = nextPage;

        return SearchListModel.fromPiefed(
          json,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }
}
