import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/bookmark_list.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/models/comment.dart';

enum BookmarkListSubject {
  thread,
  threadComment,
  microblog,
  microblogComment;

  factory BookmarkListSubject.fromPostType({
    required PostType postType,
    required bool isComment,
  }) => isComment
      ? switch (postType) {
          PostType.thread => BookmarkListSubject.threadComment,
          PostType.microblog => BookmarkListSubject.microblogComment,
        }
      : switch (postType) {
          PostType.thread => BookmarkListSubject.thread,
          PostType.microblog => BookmarkListSubject.microblog,
        };

  String toJson() => {
    BookmarkListSubject.thread: 'entry',
    BookmarkListSubject.threadComment: 'entry_comment',
    BookmarkListSubject.microblog: 'post',
    BookmarkListSubject.microblogComment: 'post_comment',
  }[this]!;
}

class APIBookmark {
  final ServerClient client;

  APIBookmark(this.client);

  Future<(List<Object>, String?)> list({String? list, String? page}) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/bookmark-lists/show';
        final query = {'list': list, 'sort': 'newest', 'p': page};

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;
        final itemList = json['items'] as List<dynamic>;
        final items = itemList
            .map((item) {
              var itemType = item['itemType'];
              if (itemType == 'entry') {
                return PostModel.fromMbinEntry(item as JsonMap);
              } else if (itemType == 'post') {
                return PostModel.fromMbinPost(item as JsonMap);
              } else if (itemType == 'entry_comment' ||
                  itemType == 'post_comment') {
                return CommentModel.fromMbin(item as JsonMap);
              }
            })
            .nonNulls
            .toList();

        return (
          items,
          mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
        );

      case ServerSoftware.lemmy:
        const postsPath = '/post/list';
        const commentsPath = '/comment/list';

        final query = {
          'type_': 'All',
          'sort': 'New',
          'page': page,
          'saved_only': 'true',
        };

        final [postResponse, commentResponse] = await Future.wait([
          client.get(postsPath, queryParams: query),
          client.get(commentsPath, queryParams: query),
        ]);

        final postJson = postResponse.bodyJson;
        postJson['next_page'] = lemmyCalcNextIntPage(
          postJson['posts'] as List<dynamic>,
          page,
        );

        final commentJson = commentResponse.bodyJson;
        commentJson['next_page'] = lemmyCalcNextIntPage(
          commentJson['comments'] as List<dynamic>,
          page,
        );

        final postLists = PostListModel.fromLemmy(
          postJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

        final commentLists = CommentListModel.fromLemmyToFlat(
          commentJson,
          langCodeIdPairs: await client.languageCodeIdPairs(),
        );

        return (
          [...postLists.items, ...commentLists.items],
          postLists.nextPage,
        );

      case ServerSoftware.piefed:
        throw UnimplementedError('Unimplemented');
    }
  }

  Future<BookmarkListModel> createBookmarkList(String name) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/bookmark-lists/$name';

        final response = await client.post(path);

        return BookmarkListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Bookmark lists not on Lemmy');
      case ServerSoftware.piefed:
        throw Exception('Bookmark lists not on piefed');
    }
  }

  Future<void> deleteBookmarkList(String name) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/bookmark-lists/$name';

        final response = await client.delete(path);

      case ServerSoftware.lemmy:
        throw Exception('Bookmark lists not on Lemmy');
      case ServerSoftware.piefed:
        throw Exception('Bookmark lists not on piefed');
    }
  }

  Future<BookmarkListModel> makeBookmarkListDefault(String name) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/bookmark-lists/$name/makeDefault';

        final response = await client.put(path);

        return BookmarkListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Bookmark lists not on Lemmy');
      case ServerSoftware.piefed:
        throw Exception('Bookmark lists not on piefed');
    }
  }

  Future<List<BookmarkListModel>> getBookmarkLists() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/bookmark-lists';

        final response = await client.get(path);

        return BookmarkListListModel.fromMbin(response.bodyJson).items;

      case ServerSoftware.lemmy:
        throw Exception('Bookmark lists not on Lemmy');

      case ServerSoftware.piefed:
        throw Exception('Bookmark lists not on piefed');
    }
  }

  Future<List<String>?> addBookmarkToDefault({
    required BookmarkListSubject subjectType,
    required int subjectId,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/bos/$subjectId/${subjectType.toJson()}';

        final response = await client.put(path);

        return optionalStringList((response.bodyJson['bookmarks']));

      case ServerSoftware.lemmy:
        final path = switch (subjectType) {
          BookmarkListSubject.thread => '/post/save',
          BookmarkListSubject.threadComment => '/comment/save',
          _ => throw Exception('Tried to bookmark microblog on Lemmy'),
        };

        final response = await client.put(
          path,
          body: {
            switch (subjectType) {
              BookmarkListSubject.thread => 'post_id',
              BookmarkListSubject.threadComment => 'comment_id',
              _ => throw Exception('Tried to bookmark microblog on Lemmy'),
            }: subjectId,
            'save': true,
          },
        );

        return [''];

      case ServerSoftware.piefed:
        final path = switch (subjectType) {
          BookmarkListSubject.thread => '/post/save',
          BookmarkListSubject.threadComment => '/comment/save',
          _ => throw Exception('Tried to bookmark microblog on piefed'),
        };

        final response = await client.put(
          path,
          body: {
            switch (subjectType) {
              BookmarkListSubject.thread => 'post_id',
              BookmarkListSubject.threadComment => 'comment_id',
              _ => throw Exception('Tried to bookmark microblog on piefed'),
            }: subjectId,
            'save': true,
          },
        );

        return [''];
    }
  }

  Future<List<String>?> addBookmarkToList({
    required BookmarkListSubject subjectType,
    required int subjectId,
    required String listName,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/bol/$subjectId/${subjectType.toJson()}/$listName';

        final response = await client.put(path);

        return optionalStringList((response.bodyJson['bookmarks']));

      case ServerSoftware.lemmy:
        throw Exception('Bookmark lists not on Lemmy');

      case ServerSoftware.piefed:
        throw Exception('Bookmark lists not on piefed');
    }
  }

  Future<List<String>?> removeBookmarkFromAll({
    required BookmarkListSubject subjectType,
    required int subjectId,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/rbo/$subjectId/${subjectType.toJson()}';

        final response = await client.delete(path);

        return optionalStringList((response.bodyJson['bookmarks']));

      case ServerSoftware.lemmy:
        final path = switch (subjectType) {
          BookmarkListSubject.thread => '/post/save',
          BookmarkListSubject.threadComment => '/comment/save',
          _ => throw Exception('Tried to bookmark microblog on Lemmy'),
        };

        final response = await client.put(
          path,
          body: {
            switch (subjectType) {
              BookmarkListSubject.thread => 'post_id',
              BookmarkListSubject.threadComment => 'comment_id',
              _ => throw Exception('Tried to bookmark microblog on Lemmy'),
            }: subjectId,
            'save': false,
          },
        );

        return [];

      case ServerSoftware.piefed:
        final path = switch (subjectType) {
          BookmarkListSubject.thread => '/post/save',
          BookmarkListSubject.threadComment => '/comment/save',
          _ => throw Exception('Tried to bookmark microblog on piefed'),
        };

        final response = await client.put(
          path,
          body: {
            switch (subjectType) {
              BookmarkListSubject.thread => 'post_id',
              BookmarkListSubject.threadComment => 'comment_id',
              _ => throw Exception('Tried to bookmark microblog on piefed'),
            }: subjectId,
            'save': false,
          },
        );

        return [];
    }
  }

  Future<List<String>?> removeBookmarkFromList({
    required BookmarkListSubject subjectType,
    required int subjectId,
    required String listName,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/rbol/$subjectId/${subjectType.toJson()}/$listName';

        final response = await client.delete(path);

        return optionalStringList((response.bodyJson['bookmarks']));

      case ServerSoftware.lemmy:
        throw Exception('Bookmark lists not on Lemmy');

      case ServerSoftware.piefed:
        throw Exception('Bookmark lists not on piefed');
    }
  }
}
