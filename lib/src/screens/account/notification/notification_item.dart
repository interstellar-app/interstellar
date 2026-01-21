import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/account/messages/message_thread_screen.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'notification_count_controller.dart';

const notificationTitle = {
  NotificationType.mention: 'mentioned you',
  NotificationType.postMention: 'mentioned you in a post',
  NotificationType.commentMention: 'mentioned you in a comment',
  NotificationType.reply: 'replied to you',
  NotificationType.entryCreated: 'created a thread',
  NotificationType.entryEdited: 'edited your thread',
  NotificationType.entryDeleted: 'deleted your thread',
  NotificationType.entryCommentCreated: 'added a new comment',
  NotificationType.entryCommentEdited: 'edited your comment',
  NotificationType.entryCommentReply: 'replied to your comment',
  NotificationType.entryCommentDeleted: 'deleted your comment',
  NotificationType.postCreated: 'created a microblog',
  NotificationType.postEdited: 'edited your microblog',
  NotificationType.postDeleted: 'deleted your microblog',
  NotificationType.postCommentCreated: 'added a new comment',
  NotificationType.postCommentEdited: 'edited your comment',
  NotificationType.postCommentReply: 'replied to your comment',
  NotificationType.postCommentDeleted: 'deleted your comment',
  NotificationType.message: 'messaged you',
  NotificationType.ban: 'banned you',
  NotificationType.reportCreated: 'report created',
  NotificationType.reportRejected: 'report rejected',
  NotificationType.reportApproved: 'report approved',
  NotificationType.newSignup: 'new user registered',
};

class NotificationItem extends StatefulWidget {
  const NotificationItem(this.item, this.onUpdate, {super.key});

  final NotificationModel item;
  final void Function(NotificationModel) onUpdate;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  @override
  Widget build(BuildContext context) {
    // Notification type, subject, and creator must not be null at this point.

    final software = context.watch<AppController>().serverSoftware;

    CommunityModel? bannedCommunity = switch (software) {
      ServerSoftware.mbin =>
        widget.item.type == NotificationType.ban &&
                widget.item.subject['magazine'] != null
            ? CommunityModel.fromMbin(
                widget.item.subject['magazine'] as JsonMap,
              )
            : null,
      ServerSoftware.lemmy => null,
      ServerSoftware.piefed => null,
    };

    final String body = switch (software) {
      ServerSoftware.mbin =>
        (widget.item.subject['body'] ?? widget.item.subject['reason'] ?? '')
            as String,
      ServerSoftware.lemmy => switch (widget.item.type!) {
        NotificationType.message =>
          widget.item.subject['private_message']['content'] as String,
        NotificationType.mention =>
          widget.item.subject['comment']['content'] as String,
        NotificationType.reply =>
          widget.item.subject['comment']['content'] as String,
        _ => throw Exception('invalid notification type for lemmy'),
      },
      ServerSoftware.piefed => (widget.item.subject['notif_body']) as String,
    };

    final void Function()? onTap = switch (software) {
      ServerSoftware.mbin =>
        widget.item.subject.containsKey('threadId')
            ? () => context.router.push(MessageThreadRoute(threadId: widget.item.subject['threadId'] as int,
                ),
              )
            : widget.item.subject.containsKey('commentId')
            ? () => context.router.push(PostCommentRoute(postType: widget.item.subject.containsKey('postId')
            ? PostType.microblog
            : PostType.thread, commentId: widget.item.subject['commentId'] as int))
            : widget.item.subject.containsKey('entryId')
            ? () => context.router.push(PostRoute(
                  postType: PostType.thread,
                  postId: widget.item.subject['entryId'] as int,
                ),
              )
            : widget.item.subject.containsKey('postId')
            ? () => context.router.push(PostRoute(
                  postType: PostType.microblog,
                  postId: widget.item.subject['postId'] as int,
                ),
              )
            : null,
      ServerSoftware.lemmy => switch (widget.item.type!) {
        NotificationType.message => () => context.router.push(MessageThreadRoute(
            threadId: widget.item.subject['creator']['id'] as int,
          ),
        ),
        NotificationType.mention => () => context.router.push(PostCommentRoute(postType: PostType.thread, commentId: widget.item.subject['comment']['id'] as int)),
        NotificationType.reply => () => context.router.push(PostCommentRoute(postType: PostType.thread, commentId: widget.item.subject['comment']['id'] as int)),
        _ => throw Exception('invalid notification type for lemmy'),
      },
      ServerSoftware.piefed => switch (widget.item.type!) {
        NotificationType.entryCreated => () => context.router.push(PostRoute(
            postType: PostType.thread,
            postId: widget.item.subject['post_id'] as int,
          ),
        ),
        NotificationType.entryCommentCreated => () => context.router.push(PostCommentRoute(postType: PostType.thread,
            commentId: widget.item.subject['comment_id'] as int,
          ),
        ),
        NotificationType.entryCommentReply => () => context.router.push(PostCommentRoute(postType: PostType.thread,
            commentId: widget.item.subject['comment_id'] as int,
          ),
        ),
        NotificationType.postMention => () => context.router.push(PostRoute(
            postType: PostType.thread,
            postId: widget.item.subject['post_id'] as int,
          ),
        ),
        NotificationType.commentMention => () => context.router.push(PostCommentRoute(postType: PostType.thread,
            commentId: widget.item.subject['comment_id'] as int,
          ),
        ),
        _ => throw Exception('invalid notification type for piefed'),
      },
    };

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: widget.item.isRead ? Colors.transparent : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, right: 4, bottom: 8, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: DisplayName(
                              widget.item.creator!.name,
                              icon: widget.item.creator!.avatar,
                              onTap: () => context.router.push(UserRoute(userId: widget.item.creator!.id),
                              ),
                            ),
                          ),
                        ),
                        Text(notificationTitle[widget.item.type]!),
                        if (bannedCommunity != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: DisplayName(
                                bannedCommunity.name,
                                icon: bannedCommunity.icon,
                                onTap: () => context.router.push(CommunityRoute(communityId: bannedCommunity.id),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // On Lemmy, there's no API to adjust reply notification read state.
                  if (!(software == ServerSoftware.lemmy &&
                      widget.item.type == NotificationType.reply))
                    LoadingIconButton(
                      onPressed: () async {
                        final newNotification = await context
                            .read<AppController>()
                            .api
                            .notifications
                            .putRead(
                              widget.item.id,
                              !widget.item.isRead,
                              widget.item.type!,
                            );

                        widget.onUpdate(newNotification);

                        if (!context.mounted) return;
                        context.read<NotificationCountController>().reload();
                      },
                      icon: Icon(
                        widget.item.isRead
                            ? Symbols.mark_chat_unread_rounded
                            : Symbols.mark_chat_read_rounded,
                      ),
                      tooltip: widget.item.isRead
                          ? 'Mark as unread'
                          : 'Mark as read',
                    ),
                ],
              ),
              if (body.isNotEmpty)
                Markdown(body, getNameHost(context, widget.item.creator!.name)),
            ],
          ),
        ),
      ),
    );
  }
}
