import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/bookmark_list.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/utils/models.dart';

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
