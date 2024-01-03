import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/utils.dart';

import 'shared.dart';

class Comments {
  late List<Comment> items;
  late Pagination pagination;

  Comments({required this.items, required this.pagination});

  Comments.fromJson(Map<String, dynamic> json) {
    items = <Comment>[];
    json['items'].forEach((v) {
      items.add(Comment.fromJson(v));
    });

    pagination = Pagination.fromJson(json['pagination']);
  }
}

class Comment {
  late int commentId;
  late User user;
  late Magazine magazine;
  late int entryId;
  int? parentId;
  int? rootId;
  Image? image;
  late String body;
  late String lang;
  List<String>? mentions;
  late int uv;
  late int dv;
  late int favourites;
  bool? isFavourited;
  int? userVote;
  bool? isAdult;
  late DateTime createdAt;
  DateTime? editedAt;
  late DateTime lastActive;
  String? apId;
  List<Comment>? children;
  late int childCount;
  late String visibility;

  Comment(
      {required this.commentId,
      required this.user,
      required this.magazine,
      required this.entryId,
      this.parentId,
      this.rootId,
      this.image,
      required this.body,
      required this.lang,
      this.mentions,
      required this.uv,
      required this.dv,
      required this.favourites,
      this.isFavourited,
      this.userVote,
      this.isAdult,
      required this.createdAt,
      this.editedAt,
      required this.lastActive,
      this.apId,
      this.children,
      required this.childCount,
      required this.visibility});

  Comment.fromJson(Map<String, dynamic> json) {
    commentId = json['commentId'];
    user = User.fromJson(json['user']);
    magazine = Magazine.fromJson(json['magazine']);
    entryId = json['entryId'];
    parentId = json['parentId'];
    rootId = json['rootId'];
    image = json['image'] != null ? Image.fromJson(json['image']) : null;
    body = json['body'] ?? '';
    lang = json['lang'];
    mentions = json['mentions']?.cast<String>();
    uv = json['uv'] ?? 0;
    dv = json['dv'] ?? 0;
    favourites = json['favourites'] ?? 0;
    isFavourited = json['isFavourited'];
    userVote = json['userVote'];
    isAdult = json['isAdult'];
    createdAt = DateTime.parse(json['createdAt']);
    editedAt =
        json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null;
    lastActive = DateTime.parse(json['lastActive']);
    apId = json['apId'];
    if (json['children'] != null) {
      children = <Comment>[];
      json['children'].forEach((v) {
        children!.add(Comment.fromJson(v));
      });
    }
    childCount = json['childCount'];
    visibility = json['visibility'];
  }
}

enum CommentsSort { newest, top, hot, active, oldest }

Future<Comments> fetchComments(
  http.Client client,
  String instanceHost,
  int entryId, {
  int? page,
  CommentsSort? sort,
}) async {
  final response = await client.get(Uri.https(
      instanceHost,
      '/api/entry/$entryId/comments',
      removeNulls({'p': page?.toString(), 'sortBy': sort?.name})));

  if (response.statusCode == 200) {
    return Comments.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load comments');
  }
}

Future<Comment> putVote(
  http.Client client,
  String instanceHost,
  int commentId,
  int choice,
) async {
  final response = await client.put(Uri.https(
    instanceHost,
    '/api/comments/$commentId/vote/$choice',
  ));

  httpErrorHandler(response, message: 'Failed to send vote');

  return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

Future<Comment> putFavorite(
  http.Client client,
  String instanceHost,
  int commentId,
) async {
  final response = await client.put(Uri.https(
    instanceHost,
    '/api/comments/$commentId/favourite',
  ));

  httpErrorHandler(response, message: 'Failed to send vote');

  return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

Future<Comment> postComment(
  http.Client client,
  String instanceHost,
  String body,
  int entryId, {
  int? parentCommentId,
}) async {
  final response = await client.post(
    Uri.https(
      instanceHost,
      '/api/entry/$entryId/comments${parentCommentId != null ? '/$parentCommentId/reply' : ''}',
    ),
    body: jsonEncode({'body': body}),
  );

  httpErrorHandler(response, message: 'Failed to post comment');

  return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

Future<Comment> editComment(
    http.Client client,
    String instanceHost,
    int commentId,
    String body,
    String lang,
    bool? isAdult
    ) async {
  final response = await client.put(Uri.https(
      instanceHost,
      '/api/comments/$commentId'
  ),
      body: jsonEncode({
        'body': body,
        'lang': lang,
        'isAdult': isAdult ?? false
      }));

  httpErrorHandler(response, message: "Failed to edit comment");

  return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

Future<void> deleteComment(
    http.Client client,
    String instanceHost,
    int commentId,
    ) async {
  final response = await client.delete(Uri.https(
      instanceHost,
      '/api/comments/$commentId'
  ));

  httpErrorHandler(response, message: "Failed to delete comment");
}