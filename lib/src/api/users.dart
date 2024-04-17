import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

enum UsersFilter { all, followed, followers, blocked }

class APIUsers {
  final ServerSoftware software;
  final http.Client httpClient;
  final String server;

  APIUsers(
    this.software,
    this.httpClient,
    this.server,
  );

  Future<DetailedUserListModel> list({
    String? page,
    UsersFilter? filter,
  }) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path = (filter == null || filter == UsersFilter.all)
            ? '/api/users'
            : '/api/users/${filter.name}';
        final query = queryParams({
          'p': page,
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load users');

        return DetailedUserListModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('List users not allowed on lemmy');
    }
  }

  Future<DetailedUserModel> get(int userId) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path = '/api/users/$userId';

        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to load user');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/user';
        final query = queryParams({
          'person_id': userId.toString(),
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: "Failed to load user");

        return DetailedUserModel.fromLemmy(
            jsonDecode(response.body) as Map<String, Object?>);
    }
  }

  Future<DetailedUserModel> getByName(String username) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path =
            '/api/users/name/${username.contains('@') ? '@$username' : username}';

        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to load user');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/user';
        final query = queryParams({
          'username': username,
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: "Failed to load user");

        return DetailedUserModel.fromLemmy(
            jsonDecode(response.body) as Map<String, Object?>);
    }
  }

  Future<UserModel> getMe() async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/me';

        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to load user');

        return UserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/site';

        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to load site info');

        return UserModel.fromLemmy((jsonDecode(response.body)['my_user']
            ['local_user_view']['person']) as Map<String, Object?>);
    }
  }

  Future<DetailedUserModel> follow(
    int userId,
    bool state,
  ) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path = '/api/users/$userId/${state ? 'follow' : 'unfollow'}';

        final response = await httpClient.put(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to send follow');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('User follow not allowed on lemmy');
    }
  }

  Future<DetailedUserModel?> updateProfile(String about) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/profile';

        final response = await httpClient.put(Uri.https(server, path),
            body: jsonEncode({'about': about}));

        httpErrorHandler(response, message: 'Failed to update profile');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/user/save_user_settings';

        final response = await httpClient.put(Uri.https(server, path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'bio': about}));

        httpErrorHandler(response, message: "Failed to load user");

        return null;
    }
  }

  Future<DetailedUserModel> putBlock(
    int userId,
    bool state,
  ) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path = '/api/users/$userId/${state ? 'block' : 'unblock'}';

        final response = await httpClient.put(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to send block');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/user/block';

        final response = await httpClient.post(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'person_id': userId,
            'block': state,
          }),
        );

        httpErrorHandler(response, message: "Failed to send block");

        return DetailedUserModel.fromLemmy(
            jsonDecode(response.body) as Map<String, Object?>);
    }
  }

  Future<DetailedUserModel?> updateAvatar(XFile image) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/avatar';

        var request = http.MultipartRequest('POST', Uri.https(server, path));
        var multipartFile = http.MultipartFile.fromBytes(
          'uploadImage',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        var response =
            await http.Response.fromStream(await httpClient.send(request));

        httpErrorHandler(response, message: 'Failed to update avatar');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const pictrsPath = '/pictrs/image';

        var request =
            http.MultipartRequest('POST', Uri.https(server, pictrsPath));
        var multipartFile = http.MultipartFile.fromBytes(
          'images[]',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        var pictrsResponse =
            await http.Response.fromStream(await httpClient.send(request));

        httpErrorHandler(pictrsResponse, message: 'Failed to upload avatar');

        final json = jsonDecode(pictrsResponse.body) as Map<String, Object?>;

        final imageName = ((json['files'] as List<Object?>).first
            as Map<String, Object?>)['file'] as String?;

        const path = '/api/v3/user/save_user_settings';

        final response = await httpClient.put(
          Uri.https(server, path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'avatar': 'https://$server/pictrs/image/$imageName',
          }),
        );

        httpErrorHandler(response, message: "Failed to update avatar");

        return null;
    }
  }

  Future<DetailedUserModel> deleteAvatar() async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/avatar';
        var response = await httpClient.delete(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to delete avatar');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('Not yet implemented for lemmy');
    }
  }

  Future<DetailedUserModel?> updateCover(XFile image) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/cover';

        var request = http.MultipartRequest('POST', Uri.https(server, path));
        var multipartFile = http.MultipartFile.fromBytes(
          'uploadImage',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        var response =
            await http.Response.fromStream(await httpClient.send(request));

        httpErrorHandler(response, message: 'Failed to update cover');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const pictrsPath = '/pictrs/image';

        var request =
            http.MultipartRequest('POST', Uri.https(server, pictrsPath));
        var multipartFile = http.MultipartFile.fromBytes(
          'images[]',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        var pictrsResponse =
            await http.Response.fromStream(await httpClient.send(request));

        httpErrorHandler(pictrsResponse, message: 'Failed to upload cover');

        final json = jsonDecode(pictrsResponse.body) as Map<String, Object?>;

        final imageName = ((json['files'] as List<Object?>).first
            as Map<String, Object?>)['file'] as String?;

        const path = '/api/v3/user/save_user_settings';

        final response = await httpClient.put(Uri.https(server, path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'banner': 'https://$server/pictrs/image/$imageName',
            }));

        httpErrorHandler(response, message: "Failed to update cover");

        return null;
    }
  }

  Future<DetailedUserModel> deleteCover() async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/cover';
        var response = await httpClient.delete(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to delete cover');

        return DetailedUserModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('Not yet implemented for lemmy');
    }
  }

  Future<DetailedUserListModel> listFollowers(
    int userId, {
    String? page,
  }) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path = '/api/users/$userId/followers';
        final query = queryParams({
          'p': page,
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load followers');

        return DetailedUserListModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('User followers not allowed on lemmy');
    }
  }

  Future<DetailedUserListModel> listFollowing(
    int userId, {
    String? page,
  }) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        final path = '/api/users/$userId/followed';
        final query = queryParams({
          'p': page,
        });

        final response = await httpClient.get(Uri.https(server, path, query));

        httpErrorHandler(response, message: 'Failed to load following');

        return DetailedUserListModel.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        throw Exception('List following not allowed on lemmy');
    }
  }

  Future<UserSettings> getUserSettings() async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/settings';
        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to get user settings');

        return UserSettings.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/site';

        final response = await httpClient.get(Uri.https(server, path));

        httpErrorHandler(response, message: 'Failed to load site info');

        return UserSettings.fromLemmy((jsonDecode(response.body)['my_user']
            ['local_user_view']['local_user']) as Map<String, Object?>);
    }
  }

  Future<UserSettings> saveUserSettings(UserSettings settings) async {
    switch (software) {
      case ServerSoftware.kbin:
      case ServerSoftware.mbin:
        const path = '/api/users/settings';
        final response = await httpClient.put(Uri.https(server, path),
            body: jsonEncode({
              'hideAdult': !settings.showNSFW,
              'showSubscribedUsers': settings.showSubscribedUsers,
              'showSubscribedMagazines': settings.showSubscribedMagazines,
              'showSubscribedDomains': settings.showSubscribedDomains,
              'showProfileSubscriptions': settings.showProfileSubscriptions,
              'showProfileFollowings': settings.showProfileFollowings,
              'notifyOnNewEntry': settings.notifyOnNewEntry,
              'notifyOnNewEntryReply': settings.notifyOnNewEntryReply,
              'notifyOnNewEntryCommentReply': settings.notifyOnNewEntryCommentReply,
              'notifyOnNewPost': settings.notifyOnNewPost,
              'notifyOnNewPostReply': settings.notifyOnNewPostReply,
              'notifyOnNewPostCommentReply': settings.notifyOnNewPostCommentReply,
            }));

        httpErrorHandler(response, message: 'Failed to save user settings');

        return UserSettings.fromKbin(
            jsonDecode(response.body) as Map<String, Object?>);

      case ServerSoftware.lemmy:
        const path = '/api/v3/user/save_user_settings';

        final response = await httpClient.put(Uri.https(server, path),
            body: jsonEncode({
              'show_nsfw': settings.showNSFW,
              'blur_nsfw': settings.blurNSFW,
              'show_read_posts': settings.showReadPosts
            }));

        httpErrorHandler(response, message: 'Failed to load site info');

        return UserSettings.fromLemmy((jsonDecode(response.body)['my_user']
            ['local_user_view']['local_user']) as Map<String, Object?>);
    }
  }
}
