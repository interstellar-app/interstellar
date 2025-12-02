import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/utils.dart';

const _postTypeMbin = {PostType.thread: 'entry', PostType.microblog: 'post'};
const _postTypeMbinComment = {
  PostType.thread: 'comments',
  PostType.microblog: 'post-comment',
};

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
}
