import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/api/community_moderation.dart';
import 'package:interstellar/src/controller/database/database.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/markdown/markdown_mention.dart';

part 'community.freezed.dart';

@freezed
abstract class DetailedCommunityListModel with _$DetailedCommunityListModel {
  const factory DetailedCommunityListModel({
    required List<DetailedCommunityModel> items,
    required String? nextPage,
  }) = _DetailedCommunityListModel;

  factory DetailedCommunityListModel.fromMbin(JsonMap json) =>
      DetailedCommunityListModel(
        items: (json['items']! as List<dynamic>)
            .map((item) => DetailedCommunityModel.fromMbin(item as JsonMap))
            .toList(),
        nextPage: mbinCalcNextPaginationPage(json['pagination']! as JsonMap),
      );

  factory DetailedCommunityListModel.fromLemmy(JsonMap json) =>
      DetailedCommunityListModel(
        items: (json['communities']! as List<dynamic>)
            .map((item) => DetailedCommunityModel.fromLemmy(item as JsonMap))
            .toList(),
        nextPage: json['next_page'] as String?,
      );

  factory DetailedCommunityListModel.fromPiefed(JsonMap json) =>
      DetailedCommunityListModel(
        items: (json['communities']! as List<dynamic>)
            .map((item) => DetailedCommunityModel.fromPiefed(item as JsonMap))
            .toList(),
        nextPage: json['next_page'] as String?,
      );
}

@freezed
abstract class DetailedCommunityModel with _$DetailedCommunityModel {
  const factory DetailedCommunityModel({
    required int id,
    required String name,
    required String title,
    required ImageModel? icon,
    required String? description,
    required UserModel? owner,
    required List<UserModel> moderators,
    required int subscriptionsCount,
    required int threadCount,
    required int threadCommentCount,
    required int? microblogCount,
    required int? microblogCommentCount,
    required bool isAdult,
    required bool? isUserSubscribed,
    required bool? isBlockedByUser,
    required bool isPostingRestrictedToMods,
    required NotificationControlStatus? notificationControlStatus,
    required List<Tag> flairs,
    required String? apId,
  }) = _DetailedCommunityModel;

  factory DetailedCommunityModel.fromMbin(JsonMap json) {
    final community = DetailedCommunityModel(
      id: json['magazineId']! as int,
      name: json['name']! as String,
      title: json['title']! as String,
      icon: mbinGetOptionalImage(json['icon'] as JsonMap?),
      description: json['description'] as String?,
      owner: json['owner'] == null
          ? null
          : UserModel.fromMbin(json['owner']! as JsonMap),
      moderators: ((json['moderators'] ?? []) as List<dynamic>)
          .map((user) => UserModel.fromMbin(user as JsonMap))
          .toList(),
      subscriptionsCount: json['subscriptionsCount']! as int,
      threadCount: json['entryCount']! as int,
      threadCommentCount: json['entryCommentCount']! as int,
      microblogCount: json['postCount']! as int,
      microblogCommentCount: json['postCommentCount']! as int,
      isAdult: json['isAdult']! as bool,
      isUserSubscribed: json['isUserSubscribed'] as bool?,
      isBlockedByUser: json['isBlockedByUser'] as bool?,
      isPostingRestrictedToMods:
          (json['isPostingRestrictedToMods'] ?? false) as bool,
      notificationControlStatus: json['notificationStatus'] == null
          ? null
          : NotificationControlStatus.fromJson(
              json['notificationStatus']! as String,
            ),
      flairs: [],
      apId: json['apProfileId'] as String?,
    );

    communityMentionCache[community.name] = community;

    return community;
  }

  factory DetailedCommunityModel.fromLemmy(JsonMap json) {
    final lemmyCommunity = json['community']! as JsonMap;
    final lemmyCounts = json['counts']! as JsonMap;

    final community = DetailedCommunityModel(
      id: lemmyCommunity['id']! as int,
      name: getLemmyPiefedActorName(lemmyCommunity),
      title: lemmyCommunity['title']! as String,
      icon: lemmyGetOptionalImage(lemmyCommunity['icon'] as String?),
      description: lemmyCommunity['description'] as String?,
      owner: null,
      moderators: [],
      subscriptionsCount: lemmyCounts['subscribers']! as int,
      threadCount: lemmyCounts['posts']! as int,
      threadCommentCount: lemmyCounts['comments']! as int,
      microblogCount: null,
      microblogCommentCount: null,
      isAdult: lemmyCommunity['nsfw']! as bool,
      isUserSubscribed: (json['subscribed']! as String) != 'NotSubscribed',
      isBlockedByUser: json['blocked'] as bool?,
      isPostingRestrictedToMods:
          lemmyCommunity['posting_restricted_to_mods']! as bool,
      notificationControlStatus: null,
      flairs: [],
      apId: lemmyCommunity['actor_id']! as String,
    );

    communityMentionCache[community.name] = community;

    return community;
  }

  factory DetailedCommunityModel.fromPiefed(JsonMap json) {
    final communityView = json['community_view'] as JsonMap? ?? json;
    final piefedCommunity = communityView['community']! as JsonMap;
    final piefedCounts = communityView['counts']! as JsonMap;

    final community = DetailedCommunityModel(
      id: piefedCommunity['id']! as int,
      name: getLemmyPiefedActorName(piefedCommunity),
      title: piefedCommunity['title']! as String,
      icon: lemmyGetOptionalImage(piefedCommunity['icon'] as String?),
      description: piefedCommunity['description'] as String?,
      owner: ((json['moderators'] ?? []) as List<dynamic>)
          .map(
            (user) =>
                UserModel.fromPiefed((user as JsonMap)['moderator']! as JsonMap),
          )
          .toList()
          .firstOrNull,
      moderators: ((json['moderators'] ?? []) as List<dynamic>)
          .map(
            (user) =>
                UserModel.fromPiefed((user as JsonMap)['moderator']! as JsonMap),
          )
          .toList(),
      subscriptionsCount: piefedCounts['subscriptions_count']! as int,
      threadCount: piefedCounts['post_count']! as int,
      threadCommentCount: piefedCounts['post_reply_count']! as int,
      microblogCount: null,
      microblogCommentCount: null,
      isAdult: piefedCommunity['nsfw']! as bool,
      isUserSubscribed:
          (communityView['subscribed']! as String) != 'NotSubscribed',
      isBlockedByUser: communityView['blocked'] as bool?,
      isPostingRestrictedToMods:
          piefedCommunity['restricted_to_mods']! as bool,
      notificationControlStatus: communityView['activity_alert'] == null
          ? null
          : communityView['activity_alert']! as bool
          ? NotificationControlStatus.loud
          : NotificationControlStatus.default_,
      flairs:
          (communityView['flair_list'] as List<dynamic>?)
              ?.map(
                (flair) => Tag(
                  id: flair['id'] as int,
                  tag: flair['flair_title'] as String,
                  backgroundColor: getColorFromHex(
                    flair['background_color'] as String,
                  ),
                  textColor: getColorFromHex(flair['text_color'] as String),
                ),
              )
              .toList() ??
          [],
      apId: piefedCommunity['actor_id']! as String,
    );

    communityMentionCache[community.name] = community;

    return community;
  }
}

@freezed
abstract class CommunityModel with _$CommunityModel {
  const factory CommunityModel({
    required int id,
    required String name,
    required ImageModel? icon,
    required String? apId,
  }) = _CommunityModel;

  factory CommunityModel.fromMbin(JsonMap json) => CommunityModel(
    id: json['magazineId']! as int,
    name: json['name']! as String,
    icon: mbinGetOptionalImage(json['icon'] as JsonMap?),
    apId: json['apProfileId'] as String?,
  );

  factory CommunityModel.fromLemmy(JsonMap json) => CommunityModel(
    id: json['id']! as int,
    name: getLemmyPiefedActorName(json),
    icon: lemmyGetOptionalImage(json['icon'] as String?),
    apId: json['actor_id']! as String,
  );

  factory CommunityModel.fromPiefed(JsonMap json) => CommunityModel(
    id: json['id']! as int,
    name: getLemmyPiefedActorName(json),
    icon: lemmyGetOptionalImage(json['icon'] as String?),
    apId: json['actor_id']! as String,
  );

  factory CommunityModel.fromDetailedCommunity(
    DetailedCommunityModel community,
  ) => CommunityModel(
    id: community.id,
    name: community.name,
    icon: community.icon,
    apId: community.apId,
  );
}

@freezed
abstract class CommunityBanListModel with _$CommunityBanListModel {
  const factory CommunityBanListModel({
    required List<CommunityBanModel> items,
    required String? nextPage,
  }) = _CommunityBanListModel;

  factory CommunityBanListModel.fromMbin(JsonMap json) => CommunityBanListModel(
    items: (json['items']! as List<dynamic>)
        .map((item) => CommunityBanModel.fromMbin(item as JsonMap))
        .toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination']! as JsonMap),
  );

  factory CommunityBanListModel.fromPiefed(JsonMap json) =>
      CommunityBanListModel(
        items: (json['items']! as List<dynamic>)
            .map((item) => CommunityBanModel.fromPiefed(item as JsonMap))
            .toList(),
        nextPage: json['next_page'] as String?,
      );
}

@freezed
abstract class CommunityBanModel with _$CommunityBanModel {
  const factory CommunityBanModel({
    required String? reason,
    required DateTime? expiresAt,
    required CommunityModel community,
    required UserModel bannedUser,
    required UserModel? bannedBy,
    required bool expired,
  }) = _CommunityBanModel;

  factory CommunityBanModel.fromMbin(JsonMap json) => CommunityBanModel(
    reason: json['reason'] as String?,
    expiresAt: optionalDateTime(json['expiresAt'] as String?),
    community: CommunityModel.fromMbin(json['magazine']! as JsonMap),
    bannedUser: UserModel.fromMbin(json['bannedUser']! as JsonMap),
    bannedBy: UserModel.fromMbin(json['bannedBy']! as JsonMap),
    expired: json['expired']! as bool,
  );

  factory CommunityBanModel.fromLemmy(JsonMap json) {
    final expiration = json['expires'] != null
        ? DateTime.parse(json['expires']! as String)
        : null;

    return CommunityBanModel(
      reason: json['reason'] as String?,
      expiresAt: expiration,
      community: CommunityModel.fromLemmy(json['community']! as JsonMap),
      bannedUser: UserModel.fromLemmy(json['banned_person']! as JsonMap),
      bannedBy: json['moderator'] != null
          ? UserModel.fromLemmy(json['moderator']! as JsonMap)
          : null,
      expired: expiration?.isBefore(DateTime.now()) ?? false,
    );
  }

  factory CommunityBanModel.fromPiefed(JsonMap json) => CommunityBanModel(
    reason: json['reason'] as String?,
    expiresAt: optionalDateTime(json['expires_at'] as String?),
    community: CommunityModel.fromPiefed(json['community']! as JsonMap),
    bannedUser: UserModel.fromPiefed(json['banned_user']! as JsonMap),
    bannedBy: UserModel.fromPiefed(json['banned_by']! as JsonMap),
    expired: json['expired']! as bool,
  );
}

@freezed
abstract class CommunityReportListModel with _$CommunityReportListModel {
  const factory CommunityReportListModel({
    required List<CommunityReportModel> items,
    required String? nextPage,
  }) = _CommunityReportListModel;

  factory CommunityReportListModel.fromMbin(JsonMap json) =>
      CommunityReportListModel(
        items: (json['items']! as List<dynamic>)
            .map((item) => CommunityReportModel.fromMbin(item as JsonMap))
            .toList(),
        nextPage: mbinCalcNextPaginationPage(json['pagination']! as JsonMap),
      );
}

@freezed
abstract class CommunityReportModel with _$CommunityReportModel {
  const factory CommunityReportModel({
    required int id,
    required CommunityModel? community,
    required UserModel? reportedBy,
    required UserModel? reportedUser,
    required PostModel? subjectPost,
    required CommentModel? subjectComment,
    required String? reason,
    required ReportStatus status,
    required DateTime? createdAt,
    required DateTime? consideredAt,
    required UserModel? consideredBy,
    required int? weight,
  }) = _CommunityReportModel;

  factory CommunityReportModel.fromMbin(JsonMap json) {
    final type = json['type'] as String?;
    final subjectPost = switch (type) {
      'entry_report' => PostModel.fromMbinEntry(json['subject']! as JsonMap),
      'post_report' => PostModel.fromMbinPost(json['subject']! as JsonMap),
      null => null,
      String() => null,
    };

    final subjectComment = switch (type) {
      'entry_comment_report' => CommentModel.fromMbin(
        json['subject']! as JsonMap,
      ),
      'post_comment_report' => CommentModel.fromMbin(
        json['subject']! as JsonMap,
      ),
      null => null,
      String() => null,
    };

    return CommunityReportModel(
      id: json['reportId']! as int,
      community: CommunityModel.fromMbin(json['magazine']! as JsonMap),
      reportedBy: UserModel.fromMbin(json['reporting']! as JsonMap),
      reportedUser: UserModel.fromMbin(json['reported']! as JsonMap),
      subjectPost: subjectPost,
      subjectComment: subjectComment,
      reason: json['reason'] as String?,
      status: json['status'] == 'closed'
          ? ReportStatus.approved
          : ReportStatus.values.byName(json['status'] as String? ?? 'pending'),
      createdAt: optionalDateTime(json['createdAt'] as String?),
      consideredAt: optionalDateTime(json['consideredAt'] as String?),
      consideredBy: json['consideredBy'] != null
          ? UserModel.fromMbin(json['consideredBy']! as JsonMap)
          : null,
      weight: json['weight'] as int?,
    );
  }
}
