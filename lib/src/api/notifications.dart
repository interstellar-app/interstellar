import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

// new_ is used because new is a reserved keyword
enum NotificationsFilter { all, new_, read }

enum NotificationControlUpdateTargetType {
  entry,
  post,
  magazine,
  user,
  comment,
}

class APINotifications {
  final ServerClient client;

  APINotifications(this.client);

  Future<NotificationListModel> list({
    String? page,
    NotificationsFilter? filter,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/notifications/${filter == NotificationsFilter.new_ ? 'new' : (filter?.name ?? 'all')}';
        final query = {'p': page};

        final response = await client.get(path, queryParams: query);

        return NotificationListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        final query = {
          'unread_only': (filter == NotificationsFilter.new_).toString(),
          'page': page?.toString(),
          'limit': '20',
        };

        final messagesFuture =
            client.get('/private_message/list', queryParams: query);
        final mentionFuture = client.get('/user/mention', queryParams: query);
        final repliesFuture = client.get('/user/replies', queryParams: query);

        final [messagesResponse, mentionResponse, repliesResponse] =
            await Future.wait(
          [messagesFuture, mentionFuture, repliesFuture],
          eagerError: true,
        );

        final result = NotificationListModel.fromLemmy(
          messagesResponse.bodyJson,
          mentionResponse.bodyJson,
          repliesResponse.bodyJson,
        );

        return result.copyWith(
            nextPage: lemmyCalcNextIntPage(result.items, page));

      case ServerSoftware.piefed:
        final path = '/user/notifications';
        final status = switch (filter) {
          NotificationsFilter.new_ => 'New',
          NotificationsFilter.read => 'Read',
          NotificationsFilter.all || null => 'All',
        };

        final query = {'page': page, 'status_request': status};

        final response = await client.get(path, queryParams: query);

        return NotificationListModel.fromPiefed(response.bodyJson);
    }
  }

  Future<int> getCount() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/notifications/count';

        final response = await client.get(path);

        return response.bodyJson['count'] as int;

      case ServerSoftware.lemmy:
        const path = '/user/unread_count';

        final response = await client.get(path);

        return (response.bodyJson['replies'] as int) +
            (response.bodyJson['mentions'] as int) +
            (response.bodyJson['private_messages'] as int);

      case ServerSoftware.piefed:
        const path = '/user/notifications_count';

        final response = await client.get(path);

        return response.bodyJson['count'] as int;
    }
  }

  Future<void> putReadAll() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/notifications/read';

        final response = await client.put(path);

        return;

      case ServerSoftware.lemmy:
        const path = '/user/mark_all_as_read';

        final response = await client.post(path);

        return;

      case ServerSoftware.piefed:
        const path = '/user/mark_all_notifications_read';

        final response = await client.put(path);

        return;
    }
  }

  Future<NotificationModel> putRead(
    int notificationId,
    bool readState,
    NotificationType notificationType, // Only needed for Lemmy
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/notifications/$notificationId/${readState ? 'read' : 'unread'}';
        final response = await client.put(path);

        return NotificationModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        final path = switch (notificationType) {
          NotificationType.message => '/private_message/mark_as_read',
          NotificationType.mention => '/user/mention/mark_as_read',
          NotificationType.reply =>
            throw Exception("can't mark Lemmy reply as read"),
          _ => throw Exception('invalid notification type for lemmy'),
        };

        final response = await client.post(
          path,
          body: {
            switch (notificationType) {
              NotificationType.message => 'private_message_id',
              NotificationType.mention => 'person_mention_id',
              NotificationType.reply =>
                throw Exception("can't mark Lemmy reply as read"),
              _ => throw Exception('invalid notification type for lemmy'),
            }: notificationId,
            'read': readState,
          },
        );

        return switch (notificationType) {
          NotificationType.message => NotificationModel.fromLemmyMessage(
              response.bodyJson['private_message_view'] as JsonMap),
          NotificationType.mention => NotificationModel.fromLemmyMention(
              response.bodyJson['person_mention_view'] as JsonMap),
          NotificationType.reply =>
            throw Exception("can't mark Lemmy reply as read"),
          _ => throw Exception('invalid notification type for lemmy'),
        };

      case ServerSoftware.piefed:
        final path = '/user/notification_state';

        final body = {'notif_id': notificationId, 'read_state': readState};

        final response = await client.put(path, body: body);

        return NotificationModel.fromPiefed(response.bodyJson);
    }
  }

  // Returns server's public key
  Future<void> pushRegister({
    required String endpoint,
    required String serverKey,
    required String contentPublicKey,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/notification/push';

        final response = await client.post(
          path,
          body: {
            'endpoint': endpoint,
            'serverKey': serverKey,
            'contentPublicKey': contentPublicKey
          },
        );

        return;

      case ServerSoftware.lemmy:
        throw Exception('No push notifications on Lemmy');

      case ServerSoftware.piefed:
        throw Exception('Notifications not yet implemented on PieFed');
    }
  }

  Future<void> pushDelete() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/notification/push';

        final response = await client.delete(
          path,
        );

        return;

      case ServerSoftware.lemmy:
        throw Exception('No push notifications on Lemmy');

      case ServerSoftware.piefed:
        throw Exception('Notifications not yet implemented on PieFed');
    }
  }

  Future<void> updateControl({
    required NotificationControlUpdateTargetType targetType,
    required int targetId,
    required NotificationControlStatus status,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/notification/update/${targetType.name}/$targetId/${status.toJson()}';

        final response = await client.put(
          path,
        );

        return;

      case ServerSoftware.lemmy:
        throw Exception('No notification controls on Lemmy');

      case ServerSoftware.piefed:
        final path = switch (targetType) {
          NotificationControlUpdateTargetType.entry => '/post/subscribe',
          NotificationControlUpdateTargetType.post =>
            throw UnsupportedError('Microblogs not on PieFed'),
          NotificationControlUpdateTargetType.magazine =>
            '/community/subscribe',
          NotificationControlUpdateTargetType.user => '/user/subscribe',
          NotificationControlUpdateTargetType.comment => '/comment/subscribe',
        };

        final response = await client.put(
          path,
          body: {
            switch (targetType) {
              NotificationControlUpdateTargetType.entry => 'post_id',
              NotificationControlUpdateTargetType.post =>
                throw UnsupportedError('Microblogs not on PieFed'),
              NotificationControlUpdateTargetType.magazine => 'community_id',
              NotificationControlUpdateTargetType.user => 'person_id',
              NotificationControlUpdateTargetType.comment => 'comment_id',
            }: targetId,
            'subscribe': status == NotificationControlStatus.loud,
          },
        );
    }
  }
}
