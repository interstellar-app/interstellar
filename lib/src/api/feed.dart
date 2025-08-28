import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/feed.dart';

class APIFeed {
  final ServerClient client;

  APIFeed(this.client);

  Future<FeedListModel> list({
    bool mineOnly = false,
    bool excludeCommunities = true,
    bool topics = false,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        if (topics) {
          const path = '/topic/list';

          final response = await client.get(path);

          final json = response.bodyJson;

          return FeedListModel.fromPiefed(json);
        }
        const path = '/feed/list';
        final query = {
          'mine_only': mineOnly.toString(),
          'exclude_communities': excludeCommunities.toString()
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;

        return FeedListModel.fromPiefed(json);
    }
  }

  Future<FeedModel> get(int feedId) async {
    throw UnimplementedError('Not yet implemented');
  }

  Future<FeedModel> getByName(String feedName) async {
    throw UnimplementedError('Not yet implemented');
  }

  Future<FeedModel> subscribe(int feedId, bool state) async {
    throw UnimplementedError('Not yet implemented');
  }
}
