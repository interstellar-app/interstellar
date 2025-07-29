import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/models.dart';
import 'image.dart';

part 'feed.freezed.dart';

@freezed
class FeedListModel with _$FeedListModel {
  const factory FeedListModel({
    required List<FeedModel> items,
  }) = _FeedListModel;
  
  factory FeedListModel.fromPiefed(JsonMap json) {
    final items = (json['feeds'] as List<dynamic>).map((feed) => FeedModel.fromPiefed(feed)).toList();

    var children = items.fold(<FeedModel>[], (item, element) {
      item.addAll(element.children);
      return item;
    });
    while (children.isNotEmpty) {
      items.addAll(children);
      children = children.fold(<FeedModel>[], (item, element) {
        item.addAll(element.children);
        return item;
      });
    }

    
    return FeedListModel(items: items);
  }
}

@freezed
class FeedModel with _$FeedModel {
  const factory FeedModel({
    required int id,
    required int userId,
    required String title,
    required String name,
    required String description,
    required bool isNSFW,
    required bool isNSFL,
    required int subscriptionCount,
    required int communityCount,
    required bool public,
    required int? parentId,
    required bool isInstanceFeed,
    required ImageModel? icon,
    required ImageModel? banner,
    required bool subscribed,
    required bool owner,
    required DateTime published,
    required DateTime updated,
    required List<FeedModel> children,
  }) = _FeedModel;

  factory FeedModel.fromPiefed(JsonMap json) {
    return FeedModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isNSFW: json['nsfw'] as bool,
      isNSFL: json['nsfl'] as bool,
      subscriptionCount: json['subscriptions_count'] as int,
      communityCount: json['num_communities'] as int,
      public: json['public'] as bool,
      parentId: json['parent_feed_id'] as int?,
      isInstanceFeed: json['is_instance_feed'] as bool,
      icon: lemmyGetOptionalImage(json['icon'] as String?),
      banner: lemmyGetOptionalImage(json['banner'] as String?),
      subscribed: json['subscribed'] as bool,
      owner: json['owner'] as bool,
      published: DateTime.parse(json['published'] as String),
      updated: DateTime.parse(json['updated'] as String),
      children: json['children'] == null ? [] : (json['children'] as List<dynamic>).map((child) => FeedModel.fromPiefed(child)).toList()
    );
  }
}