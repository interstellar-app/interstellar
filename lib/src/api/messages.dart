import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/message.dart';
import 'package:interstellar/src/utils/models.dart';

class APIMessages {
  APIMessages(this.client);

  final ServerClient client;

  Future<MessageListModel> list({int? myUserId, String? page}) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/messages';
        final query = {'p': page};

        final response = await client.get(path, queryParams: query);

        return MessageListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/private_message/list';
        final query = {'unread_only': 'false', 'page': page, 'limit': '20'};

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;

        json['next_page'] = lemmyCalcNextIntPage(
          json['private_messages']! as List<dynamic>,
          page,
        );

        return MessageListModel.fromLemmy(json, myUserId!);

      case ServerSoftware.piefed:
        const path = '/private_message/list';
        final query = {'unread_only': 'false', 'page': page, 'limit': '20'};

        final response = await client.get(path, queryParams: query);

        return MessageListModel.fromPiefed(response.bodyJson, myUserId!);
    }
  }

  Future<MessageThreadModel> getThreadWithMessages({
    required int threadId,
    int? myUserId,
    String? page,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/messages/thread/$threadId/newest';
        final query = {'p': page};

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        json['threadId'] = threadId;

        return MessageThreadModel.fromMbin(json);

      case ServerSoftware.lemmy:
        const path = '/private_message/list';
        final query = {'unread_only': 'false', 'page': page, 'limit': '20'};

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        final nextPage = lemmyCalcNextIntPage(
          json['private_messages']! as List<dynamic>,
          page,
        );
        json['next_page'] = nextPage;

        return MessageListModel.fromLemmy(
              json,
              myUserId!,
              filterByThreadId: threadId,
            ).items.firstOrNull ??
            MessageThreadModel(
              id: threadId,
              participants: [],
              messages: [],
              nextPage: null,
            ).copyWith(nextPage: nextPage);

      case ServerSoftware.piefed:
        const path = '/private_message/list';
        final query = {'unread_only': 'false', 'page': page, 'limit': '20'};

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;

        return (MessageListModel.fromPiefed(
                  json,
                  myUserId!,
                  filterByThreadId: threadId,
                ).items.firstOrNull ??
                MessageThreadModel(
                  id: threadId,
                  participants: [],
                  messages: [],
                  nextPage: null,
                ))
            .copyWith(nextPage: json['next_page'] as String?);
    }
  }

  Future<MessageThreadModel> create(int userId, String body) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/message';

        final response = await client.post(path, body: {'body': body});

        return MessageThreadModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/private_message';

        final response = await client.post(
          path,
          body: {'recipient_id': userId, 'content': body},
        );

        final json = response.bodyJson;

        return MessageListModel.fromLemmy(
          {
            'private_messages': [json['private_message_view']],
          },
          (json as dynamic)['private_message_view']['creator']['id'] as int,
        ).items.first;

      case ServerSoftware.piefed:
        const path = '/private_message';

        final response = await client.post(
          path,
          body: {'recipient_id': userId, 'content': body},
        );

        final json = response.bodyJson;

        return MessageListModel.fromPiefed(
          {
            'private_messages': [json['private_message_view']],
          },
          (json as dynamic)['private_message_view']['creator']['id'] as int,
        ).items.first;
    }
  }

  Future<MessageThreadModel> postThreadReply(
    int threadId, // Should be recipient user id for Lemmy
    String body,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/messages/thread/$threadId/reply';

        final response = await client.post(path, body: {'body': body});

        return MessageThreadModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        return create(threadId, body);

      case ServerSoftware.piefed:
        return create(threadId, body);
    }
  }
}
