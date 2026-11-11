import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'message.freezed.dart';

@freezed
abstract class MessageListModel with _$MessageListModel {
  const factory({
    required List<MessageThreadModel> items,
    required String? nextPage,
  }) = _MessageListModel;

  factory fromMbin(JsonMap json) => MessageListModel(
    items: (json['items']! as List<dynamic>)
        .map((post) => MessageThreadModel.fromMbin(post as JsonMap))
        .toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination']! as JsonMap),
  );

  factory fromLemmy(JsonMap json, int myUserId, {int? filterByThreadId}) {
    final threads = <int, JsonMap>{};

    for (final message in json['private_messages']! as List<dynamic>) {
      final creator = message['creator'] as JsonMap;
      final recipient = message['recipient'] as JsonMap;

      // Use the userId of the other person as the threadId
      final threadId = (creator['id']! as int) == myUserId
          ? recipient['id']! as int
          : creator['id']! as int;

      if (filterByThreadId != null && filterByThreadId != threadId) continue;

      if (threads[threadId] == null) {
        threads[threadId] = {
          'threadId': threadId,
          'messages': <JsonMap>[],
          'participants': [creator, recipient],
          'next_page': json['next_page'] as String?,
        };
      }

      (threads[threadId]!['messages']! as List<JsonMap>).add(message);
    }

    return MessageListModel(
      items: threads.values.map(MessageThreadModel.fromLemmy).toList(),
      nextPage: json['next_page'] as String?,
    );
  }

  factory fromPiefed(JsonMap json, int myUserId, {int? filterByThreadId}) {
    final threads = <int, JsonMap>{};

    for (final message in json['private_messages']! as List<dynamic>) {
      final creator = message['creator'] as JsonMap;
      final recipient = message['recipient'] as JsonMap;

      // Use the userId of the other person as the threadId
      final threadId = (creator['id']! as int) == myUserId
          ? recipient['id']! as int
          : creator['id']! as int;

      if (filterByThreadId != null && filterByThreadId != threadId) continue;

      if (threads[threadId] == null) {
        threads[threadId] = {
          'threadId': threadId,
          'messages': <JsonMap>[],
          'participants': [creator, recipient],
          'next_page': json['next_page'] as String?,
        };
      }

      (threads[threadId]!['messages']! as List<JsonMap>).add(message);
    }

    return MessageListModel(
      items: threads.values.map(MessageThreadModel.fromPiefed).toList(),
      nextPage: json['next_page'] as String?,
    );
  }
}

@freezed
abstract class MessageThreadModel with _$MessageThreadModel {
  const factory({
    required int id,
    required List<DetailedUserModel> participants,
    required List<MessageThreadItemModel> messages,
    required String? nextPage,
  }) = _MessageThreadModel;

  factory fromMbin(JsonMap json) => MessageThreadModel(
    id: json['threadId']! as int,
    participants: (json['participants']! as List<dynamic>)
        .map(
          (participant) => DetailedUserModel.fromMbin(participant as JsonMap),
        )
        .toList(),
    messages: ((json['messages'] ?? json['items'])! as List<dynamic>)
        .map((message) => MessageThreadItemModel.fromMbin(message as JsonMap))
        .toList(),
    nextPage: json['pagination'] == null
        ? null
        : mbinCalcNextPaginationPage(json['pagination']! as JsonMap),
  );

  factory fromLemmy(JsonMap json) => MessageThreadModel(
    id: json['threadId']! as int,
    participants: (json['participants']! as List<dynamic>)
        .map(
          (participant) =>
              DetailedUserModel.fromLemmy({'person': participant as JsonMap}),
        )
        .toList(),
    messages: (json['messages']! as List<JsonMap>)
        .map(MessageThreadItemModel.fromLemmy)
        .toList(),
    nextPage: json['next_page'] as String?,
  );

  factory fromPiefed(JsonMap json) => MessageThreadModel(
    id: json['threadId']! as int,
    participants: (json['participants']! as List<dynamic>)
        .map(
          (participant) =>
              DetailedUserModel.fromPiefed({'person': participant as JsonMap}),
        )
        .toList(),
    messages: (json['messages']! as List<JsonMap>).reversed
        .map(MessageThreadItemModel.fromPiefed)
        .toList(),
    nextPage: json['next_page'] as String?,
  );
}

@freezed
abstract class MessageThreadItemModel with _$MessageThreadItemModel {
  const factory({
    required int id,
    required UserModel sender,
    required String body,
    required DateTime createdAt,
    required bool isRead,
  }) = _MessageThreadItemModel;

  factory fromMbin(JsonMap json) => MessageThreadItemModel(
    id: json['messageId']! as int,
    sender: UserModel.fromMbin(json['sender']! as JsonMap),
    body: json['body']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    isRead: json['status']! as String == 'read',
  );

  factory fromLemmy(JsonMap json) {
    final pm = json['private_message']! as JsonMap;

    return MessageThreadItemModel(
      id: pm['id']! as int,
      sender: UserModel.fromLemmy(json['creator']! as JsonMap),
      body: pm['content']! as String,
      createdAt: DateTime.parse(pm['published']! as String),
      isRead: pm['read']! as bool,
    );
  }

  factory fromPiefed(JsonMap json) {
    final pm = json['private_message']! as JsonMap;

    return MessageThreadItemModel(
      id: pm['id']! as int,
      sender: UserModel.fromPiefed(json['creator']! as JsonMap),
      body: pm['content']! as String,
      createdAt: DateTime.parse(pm['published']! as String),
      isRead: pm['read']! as bool,
    );
  }
}
