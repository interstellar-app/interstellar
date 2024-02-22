import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/models.dart';

part 'comment.freezed.dart';

@freezed
class CommentListModel with _$CommentListModel {
  const factory CommentListModel({
    required List<CommentModel> items,
    required String? nextPage,
  }) = _CommentListModel;

  factory CommentListModel.fromKbin(Map<String, Object?> json) =>
      CommentListModel(
        items: (json['items'] as List<dynamic>)
            .map((post) => CommentModel.fromKbin(post as Map<String, Object?>))
            .toList(),
        nextPage: kbinCalcNextPaginationPage(
            json['pagination'] as Map<String, Object?>),
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
    required String? image,
    required String? body,
    required String? lang,
    required int? upvotes,
    required int? downvotes,
    required int? boosts,
    required int? myVote,
    required bool? myBoost,
    required bool? isAdult,
    required DateTime createdAt,
    required DateTime? editedAt,
    required DateTime lastActive,
    required List<CommentModel>? children,
    required int childCount,
    required String visibility,
  }) = _CommentModel;

  factory CommentModel.fromKbin(Map<String, Object?> json) => CommentModel(
        id: json['commentId'] as int,
        user: UserModel.fromKbin(json['user'] as Map<String, Object?>),
        magazine:
            MagazineModel.fromKbin(json['magazine'] as Map<String, Object?>),
        postType:
            (json['postId'] != null ? PostType.microblog : PostType.thread),
        postId: (json['entryId'] ?? json['postId']) as int,
        rootId: json['rootId'] as int?,
        parentId: json['parentId'] as int?,
        image: kbinGetImageUrl(json['image'] as Map<String, Object?>?),
        body: json['body'] as String?,
        lang: json['lang'] as String,
        upvotes: json['favourites'] as int?,
        downvotes: json['dv'] as int?,
        boosts: json['uv'] as int?,
        myVote: (json['isFavourited'] as bool?) == true
            ? 1
            : ((json['userVote'] as int?) == -1 ? -1 : 0),
        myBoost: (json['userVote'] as int?) == 1,
        isAdult: json['isAdult'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        editedAt: optionalDateTime(json['editedAt'] as String?),
        lastActive: DateTime.parse(json['lastActive'] as String),
        children: (json['children'] as List<dynamic>)
            .map((c) => CommentModel.fromKbin(c as Map<String, Object?>))
            .toList(),
        childCount: json['childCount'] as int,
        visibility: json['visibility'] as String,
      );

  // factory CommentModel.fromLemmy(
  //     Map<String, Object?> json, List<dynamic> allCommentsJson) {
  //   final lemmyComment = json['comment'] as Map<String, Object?>;
  //   final lemmyCounts = json['counts'] as Map<String, Object?>;

  //   final lemmyPath = lemmyComment['path'] as String;
  //   final lemmyPathSegments =
  //       lemmyPath.split('.').map((e) => int.parse(e)).toList();

  //   return CommentModel(
  //     id: json['commentId'] as int,
  //     user: UserModel.fromLemmy(json['creator'] as Map<String, Object?>),
  //     magazine:
  //         MagazineModel.fromLemmy(json['community'] as Map<String, Object?>),
  //     postType: PostType.thread,
  //     postId: (json['post'] as Map<String, Object?>)['id'] as int,
  //     rootId: lemmyPathSegments.length > 2 ? lemmyPathSegments[1] : null,
  //     parentId: lemmyPathSegments.length > 2
  //         ? lemmyPathSegments[lemmyPathSegments.length - 2]
  //         : null,
  //     image: null,
  //     body: json['content'] as String,
  //     lang: null,
  //     upvotes: lemmyCounts['upvotes'] as int,
  //     downvotes: lemmyCounts['downvotes'] as int,
  //     boosts: null,
  //     myVote: json['my_vote'] as int?,
  //     myBoost: null,
  //     isAdult: json['isAdult'] as bool,
  //     createdAt: DateTime.parse(json['createdAt'] as String),
  //     editedAt: optionalDateTime(json['editedAt'] as String?),
  //     lastActive: DateTime.parse(json['lastActive'] as String),
  //     children: (json['children'] as List<dynamic>)
  //         .map((c) => CommentModel.fromKbin(c as Map<String, Object?>))
  //         .toList(),
  //     childCount: json['childCount'] as int,
  //     visibility: json['visibility'] as String,
  //   );
  // }
}
