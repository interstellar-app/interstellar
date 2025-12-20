import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
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
    required DetailedUserModel moderator,
    required PostModel? post,
    required CommentModel? comment,
    required CommunityBanModel? ban,
  }) = _ModlogItemModel;

  factory ModlogItemModel.fromMbin(JsonMap json) {
    final type = ModLogType.values.byName((json['type'] as String).substring(4));


    return ModlogItemModel(
        type: type,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reason: '',
        community: CommunityModel.fromMbin(json['magazine'] as JsonMap),
        moderator: DetailedUserModel.fromMbin(json['moderator'] as JsonMap),
        post: switch (type) {
          ModLogType.all => null,
          ModLogType.entry_deleted => PostModel.fromMbinEntry(json['subject'] as JsonMap),
          ModLogType.entry_restored => PostModel.fromMbinEntry(json['subject'] as JsonMap),
          ModLogType.entry_comment_deleted => null,
          ModLogType.entry_comment_restored => null,
          ModLogType.entry_pinned => null,
          ModLogType.entry_unpinned => null,
          ModLogType.post_deleted => PostModel.fromMbinPost(json['subject'] as JsonMap),
          ModLogType.post_restored => PostModel.fromMbinPost(json['subject'] as JsonMap),
          ModLogType.post_comment_deleted => null,
          ModLogType.post_comment_restored => null,
          ModLogType.ban => null,
          ModLogType.unban => null,
          ModLogType.moderator_add => null,
          ModLogType.moderator_remove => null,
        },
        comment: switch (type) {
          ModLogType.all => null,
          ModLogType.entry_deleted => null,
          ModLogType.entry_restored => null,
          ModLogType.entry_comment_deleted => CommentModel.fromMbin(json['subject'] as JsonMap),
          ModLogType.entry_comment_restored => CommentModel.fromMbin(json['subject'] as JsonMap),
          ModLogType.entry_pinned => null,
          ModLogType.entry_unpinned => null,
          ModLogType.post_deleted => null,
          ModLogType.post_restored => null,
          ModLogType.post_comment_deleted => CommentModel.fromMbin(json['subject'] as JsonMap),
          ModLogType.post_comment_restored => CommentModel.fromMbin(json['subject'] as JsonMap),
          ModLogType.ban => null,
          ModLogType.unban => null,
          ModLogType.moderator_add => null,
          ModLogType.moderator_remove => null,
        },
      ban: switch (type) {
        ModLogType.all => null,
        ModLogType.entry_deleted => null,
        ModLogType.entry_restored => null,
        ModLogType.entry_comment_deleted => null,
        ModLogType.entry_comment_restored => null,
        ModLogType.entry_pinned => null,
        ModLogType.entry_unpinned => null,
        ModLogType.post_deleted => null,
        ModLogType.post_restored => null,
        ModLogType.post_comment_deleted => null,
        ModLogType.post_comment_restored => null,
        ModLogType.ban => CommunityBanModel.fromMbin(json['subject'] as JsonMap),
        ModLogType.unban => CommunityBanModel.fromMbin(json['subject'] as JsonMap),
        ModLogType.moderator_add => null,
        ModLogType.moderator_remove => null,
      }
    );
  }

  factory ModlogItemModel.fromLemmy(JsonMap json, {
    required List<(String, int)> langCodeIdPairs,
  }) {

    final type = ModLogType.values.byName(json['type'] as String);

    return ModlogItemModel(
        type: type,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reason: json['reason'] as String?,
        community: CommunityModel.fromLemmy(json['community'] as JsonMap),
        moderator: DetailedUserModel.fromLemmy(json['moderator'] as JsonMap),
        post: json['post'] != null ? PostModel.fromLemmy({
          'post_view': {
            'post': json['post'] as JsonMap,
            'community': json['community'] as JsonMap,
            'creator': json['moderator'] as JsonMap,
          }
        }, langCodeIdPairs: langCodeIdPairs) : null,
        comment: json['comment'] != null ? CommentModel.fromLemmy(json, langCodeIdPairs: langCodeIdPairs) : null,
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
        .map((item) => ModlogItemModel.fromMbin(item as JsonMap)).toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap)
  );

  factory ModlogListModel.fromLemmy(JsonMap json, {
    required List<(String, int)> langCodeIdPairs,
  }) {

    final removedPosts = (json['removed_posts'] as List<dynamic>)
        .map((item) => ModlogItemModel.fromLemmy({
      'type': ModLogType.entry_deleted.name,
      'createdAt': (item['mod_remove_post'] as JsonMap)['when_'] as String,
      'reason': (item['mod_remove_post'] as JsonMap)['reason'] as String,
      ...item,
    }, langCodeIdPairs: langCodeIdPairs)).toList();

    final lockedPosts = (json['locked_posts'] as List<dynamic>).map((item) => ModlogItemModel.fromLemmy({
      'type': ModLogType.entry_restored.name,
      'createdAt': (item['mod_lock_post'] as JsonMap)['when_'] as String,
      ...item,
    }, langCodeIdPairs: langCodeIdPairs));

    final featuredPosts = (json['featured_posts'] as List<dynamic>).map((item) => ModlogItemModel.fromLemmy({
      'type': ModLogType.entry_pinned.name,
      'createdAt': (item['mod_feature_post'] as JsonMap)['when_'] as String,
      ...item,
    }, langCodeIdPairs: langCodeIdPairs));

    final removedComments = (json['removed_comments'] as List<dynamic>).map((item) => ModlogItemModel.fromLemmy({
      'type': ModLogType.entry_comment_deleted.name,
      'createdAt': (item['mod_remove_comment'] as JsonMap)['when_'] as String,
      'reason': (item['mod_remove_comment'] as JsonMap)['reason'] as String,
      ...item as JsonMap,
      'creator': {'person': item['commenter'] as JsonMap},
    }, langCodeIdPairs: langCodeIdPairs));

    final modBannedCommunity = (json['banned_from_community'] as List<dynamic>).map((item) => ModlogItemModel.fromLemmy({
      'type': ModLogType.ban.name,
      'createdAt': (item['mod_ban_from_community'] as JsonMap)['when_'] as String,
      ...item,
      'reason': (item['mod_ban_from_community'] as JsonMap)['reason'] as String?,
      'expires': (item['mod_ban_from_community'] as JsonMap)['expires'] as String?,
    }, langCodeIdPairs: langCodeIdPairs));

    final items = [
      ...removedPosts,
      ...lockedPosts,
      ...featuredPosts,
      ...removedComments,
      ...modBannedCommunity,
    ];

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ModlogListModel(
      items: items,
      nextPage: json['next_page'] as String?
    );
  }
}