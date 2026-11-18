import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

enum FeedItemKind { thread, microblog, threadComment, microblogReply }

typedef FeedItemKey = (FeedItemKind, int);

/// A feed item keeps its original model and action target.
sealed class FeedItem {
  const new();
  PostModel? get post;
  CommentModel? get comment;
  PostType get type => post?.type ?? comment!.postType;
  int get id => post?.id ?? comment!.id;
  FeedItemKind get kind => switch ((type, comment != null)) {
    (PostType.thread, false) => FeedItemKind.thread,
    (PostType.microblog, false) => FeedItemKind.microblog,
    (PostType.thread, true) => FeedItemKind.threadComment,
    (PostType.microblog, true) => FeedItemKind.microblogReply,
  };
  FeedItemKey get key => (kind, id);
  String? get title => post?.title;
  String? get body => post?.body ?? comment?.body;
  CommunityModel get community => post?.community ?? comment!.community;
  DateTime get createdAt => post?.createdAt ?? comment!.createdAt;
  DateTime get lastActive =>
      post?.lastActive ?? comment!.lastActive ?? comment!.createdAt;
  int? get upvotes => post?.upvotes ?? comment?.upvotes;
  int? get downvotes => post?.downvotes ?? comment?.downvotes;
  int? get boosts => post?.boosts ?? comment?.boosts;
  int get numComments => post?.numComments ?? comment!.childCount;
  bool get isPinned => post?.isPinned ?? false;
  bool get read => post?.read ?? false;
}

final class FeedPost extends FeedItem {
  const new(this.post);
  @override
  final PostModel post;
  @override
  CommentModel? get comment => null;
}

final class FeedComment extends FeedItem {
  const new(this.comment);
  @override
  final CommentModel comment;
  @override
  PostModel? get post => null;
}

class FeedPage {
  const new({required this.items, required this.nextPage});
  factory fromPosts(PostListModel page) => FeedPage(
    items: page.items.map(FeedPost.new).toList(),
    nextPage: page.nextPage,
  );
  factory fromMbinCombined(JsonMap json) {
    final items = <FeedItem>[];
    for (final raw in json['items']! as List<dynamic>) {
      final content = raw as JsonMap;
      if (content['entry'] != null) {
        items.add(
          FeedPost(PostModel.fromMbinEntry(content['entry']! as JsonMap)),
        );
      } else if (content['post'] != null) {
        items.add(
          FeedPost(PostModel.fromMbinPost(content['post']! as JsonMap)),
        );
      } else if (content['entryComment'] != null) {
        items.add(
          FeedComment(
            CommentModel.fromMbin(content['entryComment']! as JsonMap),
          ),
        );
      } else if (content['postComment'] != null) {
        items.add(
          FeedComment(
            CommentModel.fromMbin(content['postComment']! as JsonMap),
          ),
        );
      }
    }
    return FeedPage(
      items: items,
      nextPage: mbinCalcNextPaginationPage(json['pagination']! as JsonMap),
    );
  }
  final List<FeedItem> items;
  final String? nextPage;
}
