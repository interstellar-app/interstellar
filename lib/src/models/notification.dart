import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'notification.freezed.dart';

@freezed
class NotificationListModel with _$NotificationListModel {
  const factory NotificationListModel({
    required List<NotificationModel> items,
    required String? nextPage,
  }) = _NotificationListModel;

  factory NotificationListModel.fromMbin(JsonMap json) => NotificationListModel(
        items: (json['items'] as List<dynamic>)
            .map((post) => NotificationModel.fromMbin(post as JsonMap))
            .toList(),
        nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
      );

  factory NotificationListModel.fromLemmy(
    JsonMap messagesJson,
    JsonMap mentionsJson,
    JsonMap repliesJson,
  ) =>
      NotificationListModel(
        items: [
          ...(messagesJson['private_messages'] as List<dynamic>).map(
              (item) => NotificationModel.fromLemmyMessage(item as JsonMap)),
          ...(mentionsJson['mentions'] as List<dynamic>).map(
              (item) => NotificationModel.fromLemmyMention(item as JsonMap)),
          ...(repliesJson['replies'] as List<dynamic>)
              .map((item) => NotificationModel.fromLemmyReply(item as JsonMap)),
        ],
        nextPage: null,
      );

  factory NotificationListModel.fromPiefed(JsonMap json) =>
      NotificationListModel(
          items: (json['items'] as List<dynamic>)
              .map((notif) => NotificationModel.fromPiefed(notif as JsonMap))
              .toList(),
          nextPage: null); // NotificationListModel
}

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required int id,
    required NotificationType? type,
    required bool isRead,
    required dynamic subject,
    required UserModel? creator,
  }) = _NotificationModel;

  factory NotificationModel.fromMbin(JsonMap json) {
    final subject = json['subject'] as JsonMap?;

    return NotificationModel(
        id: json['notificationId'] as int,
        type: notificationTypeMap[json['type']],
        isRead: json['status'] == 'read',
        subject: subject,
        creator: subject == null
            ? null
            : UserModel.fromMbin((subject['user'] ??
                subject['sender'] ??
                subject['bannedBy']) as JsonMap));
  }

  factory NotificationModel.fromLemmyMessage(JsonMap json) {
    final pm = json['private_message'] as JsonMap;

    return NotificationModel(
      id: pm['id'] as int,
      type: NotificationType.message,
      isRead: pm['read'] as bool,
      subject: json,
      creator: UserModel.fromLemmy(json['creator'] as JsonMap),
    );
  }

  factory NotificationModel.fromLemmyMention(JsonMap json) {
    final pm = json['person_mention'] as JsonMap;

    return NotificationModel(
      id: pm['id'] as int,
      type: NotificationType.mention,
      isRead: pm['read'] as bool,
      subject: json,
      creator: UserModel.fromLemmy(json['creator'] as JsonMap),
    );
  }

  factory NotificationModel.fromLemmyReply(JsonMap json) {
    final cr = json['comment_reply'] as JsonMap;

    return NotificationModel(
      id: cr['id'] as int,
      type: NotificationType.reply,
      isRead: cr['read'] as bool,
      subject: json,
      creator: UserModel.fromLemmy(json['creator'] as JsonMap),
    );
  }

  factory NotificationModel.fromPiefed(JsonMap json) {
    final subject = json;

    return NotificationModel(
        id: json['notif_id'] as int,
        type: notificationTypeMap[json['notif_subtype']],
        isRead: json['status'] == 'read',
        subject: subject,
        creator: UserModel.fromPiefed(json['author'] as JsonMap));
  }
}

enum NotificationStatus { all, new_, read }

enum NotificationType {
  mention,
  postMention, //piefed
  commentMention, //piefed
  reply, // Lemmy specific type
  entryCreated,
  entryEdited,
  entryDeleted,
  entryCommentCreated,
  entryCommentEdited,
  entryCommentReply,
  entryCommentDeleted,
  postCreated,
  postEdited,
  postDeleted,
  postCommentCreated,
  postCommentEdited,
  postCommentReply,
  postCommentDeleted,
  message,
  ban,
  reportCreated,
  reportRejected,
  reportApproved,
  newSignup,
}

const notificationTypeMap = {
  'entry_created_notification': NotificationType.entryCreated,
  'entry_edited_notification': NotificationType.entryEdited,
  'entry_deleted_notification': NotificationType.entryDeleted,
  'entry_mentioned_notification': NotificationType.mention,
  'entry_comment_created_notification': NotificationType.entryCommentCreated,
  'entry_comment_edited_notification': NotificationType.entryCommentEdited,
  'entry_comment_reply_notification': NotificationType.entryCommentReply,
  'entry_comment_deleted_notification': NotificationType.entryCommentDeleted,
  'entry_comment_mentioned_notification': NotificationType.mention,
  'post_created_notification': NotificationType.postCreated,
  'post_edited_notification': NotificationType.postEdited,
  'post_deleted_notification': NotificationType.postDeleted,
  'post_mentioned_notification': NotificationType.mention,
  'post_comment_created_notification': NotificationType.postCommentCreated,
  'post_comment_edited_notification': NotificationType.postCommentEdited,
  'post_comment_reply_notification': NotificationType.postCommentReply,
  'post_comment_deleted_notification': NotificationType.postCommentDeleted,
  'post_comment_mentioned_notification': NotificationType.mention,
  'message_notification': NotificationType.message,
  'ban_notification': NotificationType.ban,
  'report_created_notification': NotificationType.reportCreated,
  'report_rejected_notification': NotificationType.reportRejected,
  'report_approved_notification': NotificationType.reportApproved,
  'new_signup': NotificationType.newSignup,
  'new_post_from_followed_user': NotificationType.entryCreated,
  'new_post_in_followed_community': NotificationType.entryCreated,
  'new_post_in_followed_topic': NotificationType.entryCreated,
  'top_level_comment_on_followed_post': NotificationType.entryCommentCreated,
  'new_reply_on_followed_comment': NotificationType.entryCommentReply,
  'new_post_in_followed_feed': NotificationType.entryCreated,
  'comment_mention': NotificationType.commentMention,
  'post_mention': NotificationType.postMention,
};

enum NotificationControlStatus {
  default_,
  muted,
  loud;

  factory NotificationControlStatus.fromJson(String json) => {
        'Default': NotificationControlStatus.default_,
        'Muted': NotificationControlStatus.muted,
        'Loud': NotificationControlStatus.loud,
      }[json]!;

  String toJson() => {
        NotificationControlStatus.default_: 'Default',
        NotificationControlStatus.muted: 'Muted',
        NotificationControlStatus.loud: 'Loud',
      }[this]!;
}
