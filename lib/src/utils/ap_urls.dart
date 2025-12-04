import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:provider/provider.dart';

/// Local url first, remote url last.
/// Only one link if local is the source.
List<Uri> genPostUrls(BuildContext context, PostModel post) {
  final ac = context.read<AppController>();

  final apUrl = post.apId == null ? null : Uri.tryParse(post.apId!);

  return [
    if (apUrl == null || apUrl.host != ac.instanceHost)
      Uri.https(
        ac.instanceHost,
        ac.serverSoftware == ServerSoftware.mbin
            ? '/m/${post.community.name}/${switch (post.type) {
                PostType.thread => 't',
                PostType.microblog => 'p',
              }}/${post.id}'
            : '/post/${post.id}',
      ),
    ?apUrl,
  ];
}

/// Local url first, remote url last.
/// Only one link if local is the source.
List<Uri> genCommentUrls(BuildContext context, CommentModel comment) {
  final ac = context.read<AppController>();

  final apUrl = comment.apId == null ? null : Uri.tryParse(comment.apId!);

  return [
    if (apUrl == null || apUrl.host != ac.instanceHost)
      Uri.https(
        ac.instanceHost,
        ac.serverSoftware == ServerSoftware.mbin
            ? '/m/${comment.community.name}/${switch (comment.postType) {
                PostType.thread => 't',
                PostType.microblog => 'p',
              }}/${comment.postId}/-/${switch (comment.postType) {
                PostType.thread => 'comment',
                PostType.microblog => 'reply',
              }}/${comment.id}'
            : '/comment/${comment.id}',
      ),
    ?apUrl,
  ];
}

/// Local url first, remote url last.
/// Only one link if local is the source.
List<Uri> genCommunityUrls(BuildContext context, CommunityModel community) {
  final ac = context.read<AppController>();

  final apUrl = community.apId == null ? null : Uri.tryParse(community.apId!);

  return [
    if (apUrl == null || apUrl.host != ac.instanceHost)
      Uri.https(
        ac.instanceHost,
        ac.serverSoftware == ServerSoftware.mbin
            ? '/m/${community.name}'
            : '/c/${community.name}',
      ),
    ?apUrl,
  ];
}

/// Local url first, remote url last.
/// Only one link if local is the source.
List<Uri> genUserUrls(BuildContext context, UserModel user) {
  final ac = context.read<AppController>();

  final apUrl = user.apId == null ? null : Uri.tryParse(user.apId!);

  return [
    if (apUrl == null || apUrl.host != ac.instanceHost)
      Uri.https(
        ac.instanceHost,
        '/u/${ac.serverSoftware == ServerSoftware.mbin && getNameHost(context, user.name) != ac.instanceHost ? '@' : ''}${user.name}',
      ),
    ?apUrl,
  ];
}
