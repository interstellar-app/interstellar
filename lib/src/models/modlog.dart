import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

import '../api/moderation.dart';

part 'modlog.freezed.dart';

@freezed
abstract class ModlogItemModel with _$ModlogItemModel {
  const factory ModlogItemModel({
    required ModLogType type,
    required DateTime createdAt,
    required String? reason,
    required CommunityModel community,
    required DetailedUserModel? moderator,
    required int? postId,
    required String? postTitle,
    required CommentModel? comment,
    required CommunityBanModel? ban,
  }) = _ModlogItemModel;

  factory ModlogItemModel.fromMbin(JsonMap json) {
    final type = ModLogType.fromMbin(json['type'] as String);

    return ModlogItemModel(
      type: type,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reason: '',
      community: CommunityModel.fromMbin(json['magazine'] as JsonMap),
      moderator: DetailedUserModel.fromMbin(json['moderator'] as JsonMap),
      postId: switch (type) {
        ModLogType.all => null,
        ModLogType.postDeleted =>
          (json['subject'] as JsonMap)['entryId'] as int,
        ModLogType.postRestored =>
          (json['subject'] as JsonMap)['entryId'] as int,
        ModLogType.commentDeleted => null,
        ModLogType.commentRestored => null,
        ModLogType.postPinned => null,
        ModLogType.postUnpinned => null,
        ModLogType.post_deleted =>
          (json['subject'] as JsonMap)['postId'] as int,
        ModLogType.post_restored =>
          (json['subject'] as JsonMap)['postId'] as int,
        ModLogType.post_comment_deleted => null,
        ModLogType.post_comment_restored => null,
        ModLogType.ban => null,
        ModLogType.unban => null,
        ModLogType.moderatorAdded => null,
        ModLogType.moderatorRemoved => null,
        ModLogType.communityAdded => null,
        ModLogType.communityRemoved => null,
        ModLogType.postLocked => null,
        ModLogType.postUnlocked => null,
      },
      postTitle: switch (type) {
        ModLogType.all => null,
        ModLogType.postDeleted =>
          (json['subject'] as JsonMap)['title'] as String,
        ModLogType.postRestored =>
          (json['subject'] as JsonMap)['title'] as String,
        ModLogType.commentDeleted => null,
        ModLogType.commentRestored => null,
        ModLogType.postPinned => null,
        ModLogType.postUnpinned => null,
        ModLogType.post_deleted =>
          (json['subject'] as JsonMap)['title'] as String,
        ModLogType.post_restored =>
          (json['subject'] as JsonMap)['title'] as String,
        ModLogType.post_comment_deleted => null,
        ModLogType.post_comment_restored => null,
        ModLogType.ban => null,
        ModLogType.unban => null,
        ModLogType.moderatorAdded => null,
        ModLogType.moderatorRemoved => null,
        ModLogType.communityAdded => null,
        ModLogType.communityRemoved => null,
        ModLogType.postLocked => null,
        ModLogType.postUnlocked => null,
      },
      comment: switch (type) {
        ModLogType.all => null,
        ModLogType.postDeleted => null,
        ModLogType.postRestored => null,
        ModLogType.commentDeleted => CommentModel.fromMbin(
          json['subject'] as JsonMap,
        ),
        ModLogType.commentRestored => CommentModel.fromMbin(
          json['subject'] as JsonMap,
        ),
        ModLogType.postPinned => null,
        ModLogType.postUnpinned => null,
        ModLogType.post_deleted => null,
        ModLogType.post_restored => null,
        ModLogType.post_comment_deleted => CommentModel.fromMbin(
          json['subject'] as JsonMap,
        ),
        ModLogType.post_comment_restored => CommentModel.fromMbin(
          json['subject'] as JsonMap,
        ),
        ModLogType.ban => null,
        ModLogType.unban => null,
        ModLogType.moderatorAdded => null,
        ModLogType.moderatorRemoved => null,
        ModLogType.communityAdded => null,
        ModLogType.communityRemoved => null,
        ModLogType.postLocked => null,
        ModLogType.postUnlocked => null,
      },
      ban: switch (type) {
        ModLogType.all => null,
        ModLogType.postDeleted => null,
        ModLogType.postRestored => null,
        ModLogType.commentDeleted => null,
        ModLogType.commentRestored => null,
        ModLogType.postPinned => null,
        ModLogType.postUnpinned => null,
        ModLogType.post_deleted => null,
        ModLogType.post_restored => null,
        ModLogType.post_comment_deleted => null,
        ModLogType.post_comment_restored => null,
        ModLogType.ban => CommunityBanModel.fromMbin(
          json['subject'] as JsonMap,
        ),
        ModLogType.unban => CommunityBanModel.fromMbin(
          json['subject'] as JsonMap,
        ),
        ModLogType.moderatorAdded => null,
        ModLogType.moderatorRemoved => null,
        ModLogType.communityAdded => null,
        ModLogType.communityRemoved => null,
        ModLogType.postLocked => null,
        ModLogType.postUnlocked => null,
      },
    );
  }

  factory ModlogItemModel.fromLemmy(
    JsonMap json, {
    required List<(String, int)> langCodeIdPairs,
  }) {
    final type = ModLogType.values.byName(json['type'] as String);

    return ModlogItemModel(
      type: type,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reason: json['reason'] as String?,
      community: CommunityModel.fromLemmy(json['community'] as JsonMap),
      moderator: json['moderator'] != null
          ? DetailedUserModel.fromLemmy(json['moderator'] as JsonMap)
          : null,
      postId: (json['post'] as JsonMap?)?['id'] as int?,
      postTitle: (json['post'] as JsonMap?)?['name'] as String?,
      comment: json['comment'] != null
          ? CommentModel.fromLemmy(json, langCodeIdPairs: langCodeIdPairs)
          : null,
      ban: type == ModLogType.ban ? CommunityBanModel.fromLemmy(json) : null,
    );
  }
}

@freezed
abstract class ModlogListModel with _$ModlogListModel {
  const factory ModlogListModel({
    required List<ModlogItemModel> items,
    required String? nextPage,
  }) = _ModlogListModel;

  factory ModlogListModel.fromMbin(JsonMap json) => ModlogListModel(
    items: (json['items'] as List<dynamic>)
        .map((item) => ModlogItemModel.fromMbin(item as JsonMap))
        .toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
  );

  factory ModlogListModel.fromLemmy(
    JsonMap json, {
    required List<(String, int)> langCodeIdPairs,
  }) {
    final removedPosts = (json['removed_posts'] as List<dynamic>)
        .map(
          (item) => ModlogItemModel.fromLemmy({
            'type': (item['mod_remove_post'] as JsonMap)['removed'] as bool
                ? ModLogType.postDeleted.name
                : ModLogType.postRestored.name,
            'createdAt':
                (item['mod_remove_post'] as JsonMap)['when_'] as String,
            'reason': (item['mod_remove_post'] as JsonMap)['reason'] as String?,
            ...item,
          }, langCodeIdPairs: langCodeIdPairs),
        )
        .toList();

    final lockedPosts = (json['locked_posts'] as List<dynamic>).map(
      (item) => ModlogItemModel.fromLemmy({
        'type': (item['mod_lock_post'] as JsonMap)['locked'] as bool
            ? ModLogType.postLocked.name
            : ModLogType.postUnlocked.name,
        'createdAt': (item['mod_lock_post'] as JsonMap)['when_'] as String,
        ...item,
      }, langCodeIdPairs: langCodeIdPairs),
    );

    final featuredPosts = (json['featured_posts'] as List<dynamic>).map(
      (item) => ModlogItemModel.fromLemmy({
        'type': (item['mod_feature_post'] as JsonMap)['featured'] as bool
            ? ModLogType.postPinned.name
            : ModLogType.postUnpinned.name,
        'createdAt': (item['mod_feature_post'] as JsonMap)['when_'] as String,
        ...item,
      }, langCodeIdPairs: langCodeIdPairs),
    );

    final removedComments = (json['removed_comments'] as List<dynamic>).map(
      (item) => ModlogItemModel.fromLemmy({
        'type': (item['mod_remove_comment'] as JsonMap)['removed'] as bool
            ? ModLogType.commentDeleted.name
            : ModLogType.commentRestored.name,
        'createdAt': (item['mod_remove_comment'] as JsonMap)['when_'] as String,
        'reason': (item['mod_remove_comment'] as JsonMap)['reason'] as String?,
        ...item as JsonMap,
        'creator': {'person': item['commenter'] as JsonMap},
      }, langCodeIdPairs: langCodeIdPairs),
    );

    final removedCommunities = (json['removed_communities'] as List<dynamic>)
        .map(
          (item) => ModlogItemModel.fromLemmy({
            'type': (item['mod_remove_community'] as JsonMap)['removed'] as bool
                ? ModLogType.communityRemoved.name
                : ModLogType.communityAdded.name,
            'createdAt':
                (item['mod_remove_community'] as JsonMap)['when_'] as String,
            ...item as JsonMap,
          }, langCodeIdPairs: langCodeIdPairs),
        );

    final modBannedCommunity = (json['banned_from_community'] as List<dynamic>)
        .map(
          (item) => ModlogItemModel.fromLemmy({
            'type':
                (item['mod_ban_from_community'] as JsonMap)['banned'] as bool
                ? ModLogType.ban.name
                : ModLogType.unban.name,
            'createdAt':
                (item['mod_ban_from_community'] as JsonMap)['when_'] as String,
            ...item,
            'reason':
                (item['mod_ban_from_community'] as JsonMap)['reason']
                    as String?,
            'expires':
                (item['mod_ban_from_community'] as JsonMap)['expires']
                    as String?,
          }, langCodeIdPairs: langCodeIdPairs),
        );

    final modAddedToCommunity = (json['added_to_community'] as List<dynamic>)
        .map(
          (item) => ModlogItemModel.fromLemmy({
            'type': (item['mod_add_community'] as JsonMap)['removed'] as bool
                ? ModLogType.moderatorRemoved.name
                : ModLogType.moderatorAdded.name,
            'createdAt':
                (item['mod_add_community'] as JsonMap)['when_'] as String,
            ...item,
            'expires':
                (item['mod_add_community'] as JsonMap)['expires'] as String?,
          }, langCodeIdPairs: langCodeIdPairs),
        );

    final items = [
      ...removedPosts,
      ...lockedPosts,
      ...featuredPosts,
      ...removedComments,
      ...removedCommunities,
      ...modBannedCommunity,
      ...modAddedToCommunity,
    ];

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ModlogListModel(
      items: items,
      nextPage: items.isNotEmpty ? json['next_page'] as String? : null,
    );
  }
}
