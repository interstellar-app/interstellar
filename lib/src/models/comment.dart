import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'comment.freezed.dart';

@freezed
class CommentListModel with _$CommentListModel {
  const factory CommentListModel({
    required List<CommentModel> items,
    required String? nextPage,
  }) = _CommentListModel;

  factory CommentListModel.fromMbin(JsonMap json) => CommentListModel(
    items: (json['items'] as List<dynamic>)
        .map((post) => CommentModel.fromMbin(post as JsonMap))
        .toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
  );

  // Lemmy comment list that needs to be converted to tree format. Used for post comments and comment replies.
  factory CommentListModel.fromLemmyToTree(JsonMap json) => CommentListModel(
    items: (json['comments'] as List<dynamic>)
        .where((c) => (c['comment']['path'] as String).split('.').length == 2)
        .map(
          (c) => CommentModel.fromLemmy(
            c as JsonMap,
            possibleChildrenJson: json['comments'] as List<dynamic>,
          ),
        )
        .toList(),
    nextPage: json['next_page'] as String?,
  );

  // Lemmy comment list that needs to be converted to flat format. Used for a list of user comments.
  factory CommentListModel.fromLemmyToFlat(JsonMap json) => CommentListModel(
    items: (json['comments'] as List<dynamic>)
        .map((c) => CommentModel.fromLemmy(c as JsonMap))
        .toList(),
    nextPage: json['next_page'] as String?,
  );

  // Piefed comment list that needs to be converted to tree format. Used for post comments and comment replies.
  factory CommentListModel.fromPiefedToTree(JsonMap json) => CommentListModel(
    items: (json['comments'] as List<dynamic>)
        .where((c) => (c['comment']['path'] as String).split('.').length == 2)
        .map(
          (c) => CommentModel.fromPiefed(
            c as JsonMap,
            possibleChildrenJson: json['comments'] as List<dynamic>,
          ),
        )
        .toList(),
    nextPage: json['next_page'] as String?,
  );

  // Piefed comment list that needs to be converted to flat format. Used for a list of user comments.
  factory CommentListModel.fromPiefedToFlat(JsonMap json) => CommentListModel(
    items: (json['comments'] as List<dynamic>)
        .map((c) => CommentModel.fromPiefed(c as JsonMap))
        .toList(),
    nextPage: json['next_page'] as String?,
  );
}

@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    required int id,
    required UserModel user,
    required MagazineModel magazine,
    required PostType postType,
    required int postId,
    required int? rootId,
    required int? parentId,
    required ImageModel? image,
    required String? body,
    required String? lang,
    required int? upvotes,
    required int? downvotes,
    required int? boosts,
    required int? myVote,
    required bool? myBoost,
    required DateTime createdAt,
    required DateTime? editedAt,
    required List<CommentModel>? children,
    required int childCount,
    required String visibility,
    required bool? canAuthUserModerate,
    required NotificationControlStatus? notificationControlStatus,
    required List<String>? bookmarks,
  }) = _CommentModel;

  factory CommentModel.fromMbin(JsonMap json) => CommentModel(
    id: json['commentId'] as int,
    user: UserModel.fromMbin(json['user'] as JsonMap),
    magazine: MagazineModel.fromMbin(json['magazine'] as JsonMap),
    postType: (json['postId'] != null ? PostType.microblog : PostType.thread),
    postId: (json['entryId'] ?? json['postId']) as int,
    rootId: json['rootId'] as int?,
    parentId: json['parentId'] as int?,
    image: mbinGetOptionalImage(json['image'] as JsonMap?),
    body: json['body'] as String?,
    lang: json['lang'] as String,
    upvotes: json['favourites'] as int?,
    downvotes: json['dv'] as int?,
    boosts: json['uv'] as int?,
    myVote: (json['isFavourited'] as bool?) == true
        ? 1
        : ((json['userVote'] as int?) == -1 ? -1 : 0),
    myBoost: (json['userVote'] as int?) == 1,
    createdAt: DateTime.parse(json['createdAt'] as String),
    editedAt: optionalDateTime(json['editedAt'] as String?),
    children: (json['children'] as List<dynamic>)
        .map((c) => CommentModel.fromMbin(c as JsonMap))
        .toList(),
    childCount: json['childCount'] as int,
    visibility: json['visibility'] as String,
    canAuthUserModerate: json['canAuthUserModerate'] as bool?,
    notificationControlStatus: null,
    bookmarks: optionalStringList(json['bookmarks']),
  );

  factory CommentModel.fromLemmy(
    JsonMap json, {
    List<dynamic> possibleChildrenJson = const [],
  }) {
    final lemmyComment = json['comment'] as JsonMap;
    final lemmyCounts = json['counts'] as JsonMap;

    final lemmyPath = lemmyComment['path'] as String;
    final lemmyPathSegments = lemmyPath
        .split('.')
        .map((e) => int.parse(e))
        .toList();

    final children = possibleChildrenJson
        .where((c) {
          String childPath = c['comment']['path'];

          return childPath.startsWith('$lemmyPath.') &&
              (childPath.split('.').length == lemmyPathSegments.length + 1);
        })
        .map(
          (c) => CommentModel.fromLemmy(
            c,
            possibleChildrenJson: possibleChildrenJson,
          ),
        )
        .toList();

    return CommentModel(
      id: lemmyComment['id'] as int,
      user: UserModel.fromLemmy(json['creator'] as JsonMap),
      magazine: MagazineModel.fromLemmy(json['community'] as JsonMap),
      postType: PostType.thread,
      postId: (json['post'] as JsonMap)['id'] as int,
      rootId: lemmyPathSegments.length > 2 ? lemmyPathSegments[1] : null,
      parentId: lemmyPathSegments.length > 2
          ? lemmyPathSegments[lemmyPathSegments.length - 2]
          : null,
      image: null,
      body:
          (lemmyComment['deleted'] as bool) || (lemmyComment['removed'] as bool)
          ? null
          : lemmyComment['content'] as String,
      lang: null,
      upvotes: lemmyCounts['upvotes'] as int,
      downvotes: lemmyCounts['downvotes'] as int,
      boosts: null,
      myVote: json['my_vote'] as int?,
      myBoost: null,
      createdAt: DateTime.parse(lemmyComment['published'] as String),
      editedAt: optionalDateTime(json['updated'] as String?),
      children: children,
      childCount: lemmyCounts['child_count'] as int,
      visibility: 'visible',
      canAuthUserModerate: null,
      notificationControlStatus: null,
      bookmarks: [
        // Empty string indicates comment is saved. No string indicates comment is not saved.
        if (json['saved'] as bool) '',
      ],
    );
  }

  factory CommentModel.fromPiefed(
    JsonMap json, {
    List<dynamic> possibleChildrenJson = const [],
  }) {
    final piefedComment = json['comment'] as JsonMap;
    final piefedCounts = json['counts'] as JsonMap;

    final piefedPath = piefedComment['path'] as String;
    final piefedPathSegments = piefedPath
        .split('.')
        .map((e) => int.parse(e))
        .toList();

    final children = possibleChildrenJson
        .where((c) {
          String childPath = c['comment']['path'];

          return childPath.startsWith('$piefedPath.') &&
              (childPath.split('.').length == piefedPathSegments.length + 1);
        })
        .map(
          (c) => CommentModel.fromPiefed(
            c,
            possibleChildrenJson: possibleChildrenJson,
          ),
        )
        .toList();

    return CommentModel(
      id: piefedComment['id'] as int,
      user: UserModel.fromPiefed(json['creator'] as JsonMap),
      magazine: MagazineModel.fromPiefed(json['community'] as JsonMap),
      postType: PostType.thread,
      postId: (json['post'] as JsonMap)['id'] as int,
      rootId: piefedPathSegments.length > 2 ? piefedPathSegments[1] : null,
      parentId: piefedPathSegments.length > 2
          ? piefedPathSegments[piefedPathSegments.length - 2]
          : null,
      image: null,
      body:
          (piefedComment['deleted'] as bool) ||
              (piefedComment['removed'] as bool)
          ? null
          : piefedComment['body'] as String,
      lang: null,
      upvotes: piefedCounts['upvotes'] as int,
      downvotes: piefedCounts['downvotes'] as int,
      boosts: null,
      myVote: json['my_vote'] as int?,
      myBoost: null,
      createdAt: DateTime.parse(piefedComment['published'] as String),
      editedAt: optionalDateTime(json['updated'] as String?),
      children: children,
      childCount: piefedCounts['child_count'] as int,
      visibility: 'visible',
      canAuthUserModerate: null,
      notificationControlStatus: json['activity_alert'] == null
          ? null
          : json['activity_alert'] as bool
          ? NotificationControlStatus.loud
          : NotificationControlStatus.default_,
      bookmarks: [
        // Empty string indicates comment is saved. No string indicates comment is not saved.
        if (json['saved'] as bool) '',
      ],
    );
  }
}
