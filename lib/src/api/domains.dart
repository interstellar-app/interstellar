import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';

class MbinAPIDomains {
  final ServerClient client;

  MbinAPIDomains(this.client);

  Future<DomainListModel> list({
    String? page,
    ExploreFilter? filter,
    String? search,
  }) async {
    final path =
        '/domains${switch (filter) {
          null || ExploreFilter.all => '',
          ExploreFilter.subscribed => '/subscribed',
          ExploreFilter.blocked => '/blocked',
          _ => throw Exception('Not allowed filter in domains request'),
        }}';

    final query = {
      'p': page,
      if (filter == null || filter == ExploreFilter.all) 'q': search,
    };

    final response = await client.get(path, queryParams: query);

    return DomainListModel.fromMbin(response.bodyJson);
  }

  Future<DomainModel> get(int domainId) async {
    final path = '/domain/$domainId';

    final response = await client.get(path);

    return DomainModel.fromMbin(response.bodyJson);
  }

  Future<DomainModel> putSubscribe(int domainId, bool state) async {
    final path = '/domain/$domainId/${state ? 'subscribe' : 'unsubscribe'}';

    final response = await client.put(path);

    return DomainModel.fromMbin(response.bodyJson);
  }

  Future<DomainModel> putBlock(int domainId, bool state) async {
    final path = '/domain/$domainId/${state ? 'block' : 'unblock'}';

    final response = await client.put(path);

    return DomainModel.fromMbin(response.bodyJson);
  }
}
