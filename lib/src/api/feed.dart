import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/feed.dart';

class APIFeed {
  APIFeed(this.client);

  final ServerClient client;

  Future<FeedListModel> list({
    bool mineOnly = false,
    bool includeCommunities = false,
    bool topics = false,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        final path = '/${topics ? 'topic' : 'feed'}/list';
        final query = {
          if (!topics) 'mine_only': mineOnly.toString(),
          'include_communities': includeCommunities.toString(),
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
