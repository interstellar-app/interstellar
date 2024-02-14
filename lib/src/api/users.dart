import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';

enum UsersFilter { all, followed, followers, blocked }

Future<UserListModel> fetchUsers(
  http.Client client,
  String instanceHost, {
  int? page,
  UsersFilter? filter,
}) async {
  final response = (filter == null || filter == UsersFilter.all)
      ? await client.get(Uri.https(instanceHost, '/api/users', {
          'p': page?.toString(),
        }))
      : await client.get(Uri.https(
          instanceHost, '/api/users/${filter.name}', {'p': page?.toString()}));

  httpErrorHandler(response, message: 'Failed to load users');

  return UserListModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}

Future<DetailedUserModel> fetchUser(
  http.Client client,
  String instanceHost,
  int userId,
) async {
  final response =
      await client.get(Uri.https(instanceHost, '/api/users/$userId'));

  httpErrorHandler(response, message: 'Failed to load user');

  return DetailedUserModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}

Future<DetailedUserModel> fetchUserByName(
    http.Client client,
    String instanceHost,
    String username,
    ) async {
  final response =
  await client.get(Uri.https(instanceHost, '/api/users/name/$username'));

  httpErrorHandler(response, message: 'Failed to load user');

  return DetailedUserModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}

Future<DetailedUserModel> fetchMe(
  http.Client client,
  String instanceHost,
) async {
  final response = await client.get(Uri.https(instanceHost, '/api/users/me'));

  httpErrorHandler(response, message: 'Failed to load user');

  return DetailedUserModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}

Future<DetailedUserModel> putFollow(
  http.Client client,
  String instanceHost,
  int userId,
  bool state,
) async {
  final response = await client.put(Uri.https(
    instanceHost,
    '/api/users/$userId/${state ? 'follow' : 'unfollow'}',
  ));

  httpErrorHandler(response, message: 'Failed to send follow');

  return DetailedUserModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>);
}
