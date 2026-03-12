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
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        const path = '/feed';
        final query = {'id': feedId.toString()};

        final response = await client.get(path, queryParams: query);

        return FeedModel.fromPiefed(response.bodyJson);
    }
  }

  Future<FeedModel> getByName(String feedName) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        const path = '/feed';
        final query = {'name': feedName};

        final response = await client.get(path, queryParams: query);

        return FeedModel.fromPiefed(response.bodyJson);
    }
  }

  Future<FeedModel> subscribe(int feedId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        const path = '/feed/follow';

        final response = await client.post(
          path,
          body: {'feed_id': feedId, 'follow': state},
        );

        return FeedModel.fromPiefed(response.bodyJson);
    }
  }

  Future<FeedModel> edit({
    required int feedId,
    String? title,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    bool? nsfw,
    bool? nsfl,
    bool? public,
    bool? instanceFeed,
    bool? showChildPosts,
    int? parentId,
    List<String>? communities,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        const path = '/feed';

        final response = await client.put(
          path,
          body: {
            'feed_id': feedId,
            'title': ?title,
            'description': ?description,
            'icon_url': ?iconUrl,
            'banner_url': ?bannerUrl,
            'nsfw': ?nsfw,
            'nsfl': ?nsfl,
            'public': ?public,
            'is_instance_feed': ?instanceFeed,
            'show_child_posts': ?showChildPosts,
            'parent_feed_id': ?parentId,
            'communities': ?communities?.join('\n'),
          },
        );

        return FeedModel.fromPiefed(response.bodyJson);
    }
  }

  Future<void> delete({required int feedId}) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        throw Exception('Feeds not available on mbin');

      case ServerSoftware.lemmy:
        throw Exception('Feeds not available on lemmy');

      case ServerSoftware.piefed:
        const path = '/feed/delete';

        final response = await client.post(
          path,
          body: {'feed_id': feedId, 'deleted': true},
        );
    }
  }
}
