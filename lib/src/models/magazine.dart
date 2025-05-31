import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/markdown/markdown_mention.dart';

part 'magazine.freezed.dart';

@freezed
class DetailedMagazineListModel with _$DetailedMagazineListModel {
  const factory DetailedMagazineListModel({
    required List<DetailedMagazineModel> items,
    required String? nextPage,
  }) = _DetailedMagazineListModel;

  factory DetailedMagazineListModel.fromMbin(JsonMap json) =>
      DetailedMagazineListModel(
        items: (json['items'] as List<dynamic>)
            .map((item) => DetailedMagazineModel.fromMbin(item as JsonMap))
            .toList(),
        nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
      );

  factory DetailedMagazineListModel.fromLemmy(JsonMap json) =>
      DetailedMagazineListModel(
        items: (json['communities'] as List<dynamic>)
            .map((item) => DetailedMagazineModel.fromLemmy(item as JsonMap))
            .toList(),
        nextPage: json['next_page'] as String?,
      );

  factory DetailedMagazineListModel.fromPiefed(JsonMap json) =>
      DetailedMagazineListModel(
        items: (json['communities'] as List<dynamic>)
            .map((item) => DetailedMagazineModel.fromPiefed(item as JsonMap))
            .toList(),
        nextPage: json['next_page'] as String?,
      );
}

@freezed
class DetailedMagazineModel with _$DetailedMagazineModel {
  const factory DetailedMagazineModel({
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
  }) = _DetailedMagazineModel;

  factory DetailedMagazineModel.fromMbin(JsonMap json) {
    final magazine = DetailedMagazineModel(
      id: json['magazineId'] as int,
      name: json['name'] as String,
      title: json['title'] as String,
      icon: mbinGetOptionalImage(json['icon'] as JsonMap?),
      description: json['description'] as String?,
      owner: json['owner'] == null
          ? null
          : UserModel.fromMbin(json['owner'] as JsonMap),
      moderators: ((json['moderators'] ?? []) as List<dynamic>)
          .map((user) => UserModel.fromMbin(user as JsonMap))
          .toList(),
      subscriptionsCount: json['subscriptionsCount'] as int,
      threadCount: json['entryCount'] as int,
      threadCommentCount: json['entryCommentCount'] as int,
      microblogCount: json['postCount'] as int,
      microblogCommentCount: json['postCommentCount'] as int,
      isAdult: json['isAdult'] as bool,
      isUserSubscribed: json['isUserSubscribed'] as bool?,
      isBlockedByUser: json['isBlockedByUser'] as bool?,
      isPostingRestrictedToMods:
          (json['isPostingRestrictedToMods'] ?? false) as bool,
      notificationControlStatus: json['notificationStatus'] == null
          ? null
          : NotificationControlStatus.fromJson(
              json['notificationStatus'] as String,
            ),
    );

    magazineMentionCache[magazine.name] = magazine;

    return magazine;
  }

  factory DetailedMagazineModel.fromLemmy(JsonMap json) {
    final lemmyCommunity = json['community'] as JsonMap;
    final lemmyCounts = json['counts'] as JsonMap;

    final magazine = DetailedMagazineModel(
      id: lemmyCommunity['id'] as int,
      name: getLemmyPiefedActorName(lemmyCommunity),
      title: lemmyCommunity['title'] as String,
      icon: lemmyGetOptionalImage(lemmyCommunity['icon'] as String?),
      description: lemmyCommunity['description'] as String?,
      owner: null,
      moderators: [],
      subscriptionsCount: lemmyCounts['subscribers'] as int,
      threadCount: lemmyCounts['posts'] as int,
      threadCommentCount: lemmyCounts['comments'] as int,
      microblogCount: null,
      microblogCommentCount: null,
      isAdult: lemmyCommunity['nsfw'] as bool,
      isUserSubscribed: (json['subscribed'] as String) != 'NotSubscribed',
      isBlockedByUser: json['blocked'] as bool?,
      isPostingRestrictedToMods:
          (lemmyCommunity['posting_restricted_to_mods']) as bool,
      notificationControlStatus: null,
    );

    magazineMentionCache[magazine.name] = magazine;

    return magazine;
  }

  factory DetailedMagazineModel.fromPiefed(JsonMap json) {
    final communityView = json['community_view'] as JsonMap? ?? json;
    final piefedCommunity = communityView['community'] as JsonMap;
    final piefedCounts = communityView['counts'] as JsonMap;

    final magazine = DetailedMagazineModel(
      id: piefedCommunity['id'] as int,
      name: getLemmyPiefedActorName(piefedCommunity),
      title: piefedCommunity['title'] as String,
      icon: lemmyGetOptionalImage(piefedCommunity['icon'] as String?),
      description: piefedCommunity['description'] as String?,
      owner: ((json['moderators'] ?? []) as List<dynamic>)
          .map(
            (user) =>
                UserModel.fromPiefed((user as JsonMap)['moderator'] as JsonMap),
          )
          .toList()
          .firstOrNull,
      moderators: ((json['moderators'] ?? []) as List<dynamic>)
          .map(
            (user) =>
                UserModel.fromPiefed((user as JsonMap)['moderator'] as JsonMap),
          )
          .toList(),
      subscriptionsCount: piefedCounts['subscriptions_count'] as int,
      threadCount: piefedCounts['post_count'] as int,
      threadCommentCount: piefedCounts['post_reply_count'] as int,
      microblogCount: null,
      microblogCommentCount: null,
      isAdult: piefedCommunity['nsfw'] as bool,
      isUserSubscribed:
          (communityView['subscribed'] as String) != 'NotSubscribed',
      isBlockedByUser: communityView['blocked'] as bool?,
      isPostingRestrictedToMods:
          (piefedCommunity['restricted_to_mods']) as bool,
      notificationControlStatus: communityView['activity_alert'] == null
          ? null
          : communityView['activity_alert'] as bool
          ? NotificationControlStatus.loud
          : NotificationControlStatus.default_,
    );

    magazineMentionCache[magazine.name] = magazine;

    return magazine;
  }
}

@freezed
class MagazineModel with _$MagazineModel {
  const factory MagazineModel({
    required int id,
    required String name,
    required ImageModel? icon,
  }) = _MagazineModel;

  factory MagazineModel.fromMbin(JsonMap json) => MagazineModel(
    id: json['magazineId'] as int,
    name: json['name'] as String,
    icon: mbinGetOptionalImage(json['icon'] as JsonMap?),
  );

  factory MagazineModel.fromLemmy(JsonMap json) => MagazineModel(
    id: json['id'] as int,
    name: getLemmyPiefedActorName(json),
    icon: lemmyGetOptionalImage(json['icon'] as String?),
  );

  factory MagazineModel.fromPiefed(JsonMap json) => MagazineModel(
    id: json['id'] as int,
    name: getLemmyPiefedActorName(json),
    icon: lemmyGetOptionalImage(json['icon'] as String?),
  );
}

@freezed
class MagazineBanListModel with _$MagazineBanListModel {
  const factory MagazineBanListModel({
    required List<MagazineBanModel> items,
    required String? nextPage,
  }) = _MagazineBanListModel;

  factory MagazineBanListModel.fromMbin(JsonMap json) => MagazineBanListModel(
    items: (json['items'] as List<dynamic>)
        .map((item) => MagazineBanModel.fromMbin(item as JsonMap))
        .toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
  );

  factory MagazineBanListModel.fromPiefed(JsonMap json) => MagazineBanListModel(
    items: (json['items'] as List<dynamic>)
        .map((item) => MagazineBanModel.fromPiefed(item as JsonMap))
        .toList(),
    // if next_page is None we have reached the end of the bans
    // so set nextPage to null. Otherwise set it to the next page number
    // to request
    nextPage: (json['next_page'] as String?) != 'None'
        ? json['next_page'] as String?
        : null,
  );
}

@freezed
class MagazineBanModel with _$MagazineBanModel {
  const factory MagazineBanModel({
    required String? reason,
    required DateTime? expiresAt,
    required MagazineModel magazine,
    required UserModel bannedUser,
    required UserModel bannedBy,
    required bool expired,
  }) = _MagazineBanModel;

  factory MagazineBanModel.fromMbin(JsonMap json) => MagazineBanModel(
    reason: json['reason'] as String?,
    expiresAt: optionalDateTime(json['expiresAt'] as String?),
    magazine: MagazineModel.fromMbin(json['magazine'] as JsonMap),
    bannedUser: UserModel.fromMbin(json['bannedUser'] as JsonMap),
    bannedBy: UserModel.fromMbin(json['bannedBy'] as JsonMap),
    expired: json['expired'] as bool,
  );

  factory MagazineBanModel.fromPiefed(JsonMap json) => MagazineBanModel(
    reason: json['reason'] as String?,
    expiresAt: optionalDateTime(json['expiresAt'] as String?),
    magazine: MagazineModel.fromPiefed(json['community'] as JsonMap),
    bannedUser: UserModel.fromPiefed(json['bannedUser'] as JsonMap),
    bannedBy: UserModel.fromPiefed(json['bannedBy'] as JsonMap),
    expired: json['expired'] as bool,
  );
}
