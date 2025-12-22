import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/modlog.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/utils.dart';

const _postTypeMbin = {PostType.thread: 'entry', PostType.microblog: 'post'};
const _postTypeMbinComment = {
  PostType.thread: 'comments',
  PostType.microblog: 'post-comment',
};

enum ModLogType {
  all,
  postDeleted,
  postRestored,
  commentDeleted,
  commentRestored,
  postPinned,
  postUnpinned,
  post_deleted,
  post_restored,
  post_comment_deleted,
  post_comment_restored,
  ban,
  unban,
  moderatorAdded,
  moderatorRemoved,
  communityAdded,
  communityRemoved;

  static ModLogType fromMbin(String type) => switch (type) {
    'log_entry_deleted' => ModLogType.postDeleted,
    'log_entry_restored' => ModLogType.postRestored,
    'log_entry_comment_deleted' => ModLogType.commentDeleted,
    'log_entry_comment_restored' => ModLogType.commentRestored,
    'log_entry_pinned' => ModLogType.postPinned,
    'log_entry_unpinned' => ModLogType.postUnpinned,
    'log_post_deleted' => ModLogType.post_deleted,
    'log_post_restored' => ModLogType.post_restored,
    'log_post_comment_deleted' => ModLogType.post_comment_deleted,
    'log_post_comment_restored' => ModLogType.post_comment_restored,
    'log_ban' => ModLogType.ban,
    'log_unban' => ModLogType.unban,
    'log_moderator_add' => ModLogType.moderatorAdded,
    'log_moderator_remove' => ModLogType.moderatorRemoved,
    String() => ModLogType.all,
  };

  String get toMbin => switch (this) {
    ModLogType.all => 'all',
    ModLogType.postDeleted => 'entry_deleted',
    ModLogType.postRestored => 'entry_restored',
    ModLogType.commentDeleted => 'entry_comment_deleted',
    ModLogType.commentRestored => 'entry_comment_restored',
    ModLogType.postPinned => 'entry_pinned',
    ModLogType.postUnpinned => 'entry_unpinned',
    ModLogType.post_deleted => 'post_deleted',
    ModLogType.post_restored => 'post_restored',
    ModLogType.post_comment_deleted => 'post_comment_deleted',
    ModLogType.post_comment_restored => 'post_comment_restored',
    ModLogType.ban => 'ban',
    ModLogType.unban => 'unban',
    ModLogType.moderatorAdded => 'moderator_add',
    ModLogType.moderatorRemoved => 'moderator_remove',
    ModLogType.communityAdded => 'all',
    ModLogType.communityRemoved => 'all',
  };

  String get toLemmy => switch (this) {
    ModLogType.all => 'All',
    ModLogType.postDeleted => 'ModRemovePost',
    ModLogType.postRestored => 'All',
    ModLogType.commentDeleted => 'ModRemoveComment',
    ModLogType.commentRestored => 'All',
    ModLogType.postPinned => 'ModFeaturePost',
    ModLogType.postUnpinned => 'All',
    ModLogType.post_deleted => 'ModRemovePost',
    ModLogType.post_restored => 'All',
    ModLogType.post_comment_deleted => 'ModRemoveComment',
    ModLogType.post_comment_restored => 'All',
    ModLogType.ban => 'ModBan',
    ModLogType.unban => 'All',
    ModLogType.moderatorAdded => 'ModAdd',
    ModLogType.moderatorRemoved => 'All',
    ModLogType.communityAdded => 'ModAddCommunity',
    ModLogType.communityRemoved => 'ModRemoveCommunity',
  };
}

class APIModeration {
  final ServerClient client;

  APIModeration(this.client);

  Future<PostModel> postPin(PostType postType, int postId, bool pinned) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/${_postTypeMbin[postType]}/$postId/pin';

        final response = await client.put(path);

        return switch (postType) {
          PostType.thread => PostModel.fromMbinEntry(response.bodyJson),
          PostType.microblog => PostModel.fromMbinPost(response.bodyJson),
        };

      case ServerSoftware.lemmy:
        throw Exception('Moderation not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        final path = '/post/feature';

        final response = await client.post(
          path,
          body: {
            'post_id': postId,
            'featured': pinned,
            'feature_type': 'Community',
          },
        );

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<PostModel> postMarkNSFW(
    PostType postType,
    int postId,
    bool status,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/moderate/${_postTypeMbin[postType]}/$postId/adult/$status';

        final response = await client.put(path);

        return switch (postType) {
          PostType.thread => PostModel.fromMbinEntry(response.bodyJson),
          PostType.microblog => PostModel.fromMbinPost(response.bodyJson),
        };

      case ServerSoftware.lemmy:
        throw Exception('Moderation not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        final path = '/community/moderate/post/nsfw';
        final body = {'post_id': postId, 'nsfw_status': status};

        final response = await client.post(path, body: body);

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<PostModel> postDelete(
    PostType postType,
    int postId,
    bool status,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/moderate/${_postTypeMbin[postType]}/$postId/${status ? 'trash' : 'restore'}';

        final response = await client.put(path);

        return switch (postType) {
          PostType.thread => PostModel.fromMbinEntry(response.bodyJson),
          PostType.microblog => PostModel.fromMbinPost(response.bodyJson),
        };

      case ServerSoftware.lemmy:
        throw Exception('Moderation not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        final path = '/post/remove';

        final response = await client.post(
          path,
          body: {'post_id': postId, 'removed': status, 'reason': 'Moderated'},
        );

        return PostModel.fromPiefed(
          response.bodyJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<CommentModel> commentDelete(
    PostType postType,
    int commentId,
    bool status,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/moderate/${_postTypeMbinComment[postType]}/$commentId/${status ? 'trash' : 'restore'}';

        final response = await client.put(path);

        return CommentModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Moderation not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        final path = '/comment/remove';

        final response = await client.post(
          path,
          body: {
            'comment_id': commentId,
            'removed': status,
            'reason': 'Moderated',
          },
        );

        return CommentModel.fromPiefed(
          response.bodyJson['comment_view'] as JsonMap,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );
    }
  }

  Future<ModlogListModel> modLog({
    int? communityId,
    int? userId,
    ModLogType type = ModLogType.all,
    String? page,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        if (communityId != null) {
          final path = '/magazine/$communityId/log';
          final query = {'p': page};
          final response = await client.get(path, queryParams: query);
          return ModlogListModel.fromMbin(response.bodyJson);
        }
        final path = '/modlog';
        final query = {'p': page};
        final response = await client.get(path, queryParams: query);
        return ModlogListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/modlog';
        final query = {
          if (communityId != null) 'community_id': communityId.toString(),
          if (userId != null) 'mod_person_id': userId.toString(),
          'page': page,
          'type_': type.toLemmy,
        };
        final response = await client.get(path, queryParams: query);
        final json = response.bodyJson;
        return ModlogListModel.fromLemmy({
          'next_page':
              (int.parse(((page?.isNotEmpty ?? false) ? page : '0') ?? '0') + 1)
                  .toString(),
          ...json,
        }, langCodeIdPairs: await client.languageCodeIdPairs());

      case ServerSoftware.piefed:
        throw UnimplementedError('Not yet implemented for PieFed');
    }
  }
}
