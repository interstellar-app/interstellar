import 'package:interstellar/src/api/bookmark.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/community.dart';
import 'package:interstellar/src/api/community_moderation.dart';
import 'package:interstellar/src/api/domains.dart';
import 'package:interstellar/src/api/feed.dart';
import 'package:interstellar/src/api/images.dart';
import 'package:interstellar/src/api/messages.dart';
import 'package:interstellar/src/api/microblogs.dart';
import 'package:interstellar/src/api/moderation.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/api/search.dart';
import 'package:interstellar/src/api/threads.dart';
import 'package:interstellar/src/api/users.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/utils/utils.dart';

class API {
  final ServerClient client;

  final APIComments comments;
  final MbinAPIDomains domains;
  final APIThreads threads;
  final APICommunity community;
  final APICommunityModeration communityModeration;
  final APIFeed feed;
  final APIMessages messages;
  final APIModeration moderation;
  final APINotifications notifications;
  final MbinAPIMicroblogs microblogs;
  final APISearch search;
  final APIUsers users;
  final APIBookmark bookmark;
  final APIImages images;

  API(this.client)
    : comments = APIComments(client),
      domains = MbinAPIDomains(client),
      threads = APIThreads(client),
      community = APICommunity(client),
      communityModeration = APICommunityModeration(client),
      feed = APIFeed(client),
      messages = APIMessages(client),
      moderation = APIModeration(client),
      notifications = APINotifications(client),
      microblogs = MbinAPIMicroblogs(client),
      search = APISearch(client),
      users = APIUsers(client),
      bookmark = APIBookmark(client),
      images = APIImages(client);
}

Future<ServerSoftware?> getServerSoftware(String server) async {
  final response = await appHttpClient.get(
    Uri.https(server, '/nodeinfo/2.0.json'),
  );

  try {
    return ServerSoftware.values.byName(
      ((response.bodyJson['software'] as JsonMap)['name'] as String)
          .toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}
