import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/api/community.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class APIUsers {
  APIUsers(this.client);

  final ServerClient client;

  Future<DetailedUserListModel> list({
    String? page,
    ExploreFilter? filter,
    APIExploreSort sort = APIExploreSort.hot,
    String? search,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/users${switch (filter) {
              null || ExploreFilter.all => '',
              ExploreFilter.subscribed => '/followed',
              ExploreFilter.moderated => '/followers',
              ExploreFilter.blocked => '/blocked',
              _ => throw Exception('Not allowed filter in users request'),
            }}';

        final query = {'p': page, 'q': search};

        final response = await client.get(path, queryParams: query);

        return DetailedUserListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/search';
        final query = {
          'type_': 'Users',
          'limit': '50',
          'sort': sort.nameBySoftware(client.software),
          'page': page,
          'q': search,
          'listing_type': switch (filter) {
            ExploreFilter.all => 'All',
            ExploreFilter.local => 'Local',
            _ => 'All',
          },
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;

        json['next_page'] = lemmyCalcNextIntPage(
          json['users'] as List<dynamic>,
          page,
        );

        return DetailedUserListModel.fromLemmy(json);

      case ServerSoftware.piefed:
        const path = '/search';
        final query = {
          'type_': 'Users',
          'limit': '50',
          'sort': sort.nameBySoftware(client.software),
          'page': page,
          'q': search,
          'listing_type': switch (filter) {
            ExploreFilter.all => 'All',
            ExploreFilter.local => 'Local',
            _ => 'All',
          },
        };

        final response = await client.get(path, queryParams: query);

        final json = response.bodyJson;

        json['next_page'] = lemmyCalcNextIntPage(
          json['users'] as List<dynamic>,
          page,
        );

        return DetailedUserListModel.fromPiefed(json);
    }
  }

  Future<DetailedUserModel> get(int userId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId';

        final response = await client.get(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user';
        final query = {'person_id': userId.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedUserModel.fromLemmy(
          response.bodyJson['person_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/user';
        final query = {'person_id': userId.toString()};

        final response = await client.get(path, queryParams: query);

        return DetailedUserModel.fromPiefed(
          response.bodyJson['person_view'] as JsonMap,
        );
    }
  }

  Future<DetailedUserModel> getByName(String username) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path =
            '/users/name/${username.contains('@') ? '@$username' : username}';

        final response = await client.get(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user';
        final query = {'username': username};

        final response = await client.get(path, queryParams: query);

        return DetailedUserModel.fromLemmy(
          response.bodyJson['person_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/user';
        final query = {'username': username};

        final response = await client.get(path, queryParams: query);

        return DetailedUserModel.fromPiefed(
          response.bodyJson['person_view'] as JsonMap,
        );
    }
  }

  Future<DetailedUserModel> getMe() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/me';

        final response = await client.get(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/site';

        final response = await client.get(path);

        return DetailedUserModel.fromLemmy(
          ((response.bodyJson as dynamic)['my_user']['local_user_view'])
              as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/site';

        final response = await client.get(path);

        return DetailedUserModel.fromPiefed(
          ((response.bodyJson as dynamic)['my_user']['local_user_view'])
              as JsonMap,
        );
    }
  }

  Future<DetailedUserModel> follow(int userId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/${state ? 'follow' : 'unfollow'}';

        final response = await client.put(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('User follow not allowed on lemmy');

      case ServerSoftware.piefed:
        throw Exception('User follow not allowed on piefed');
    }
  }

  Future<DetailedUserModel?> updateProfile(String about) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/profile';

        final response = await client.put(path, body: {'about': about});

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'bio': about});

        return null;

      case ServerSoftware.piefed:
        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'bio': about});

        return null;
    }
  }

  Future<DetailedUserModel> putBlock(int userId, bool state) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/${state ? 'block' : 'unblock'}';

        final response = await client.put(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user/block';

        final response = await client.post(
          path,
          body: {'person_id': userId, 'block': state},
        );

        return DetailedUserModel.fromLemmy(
          response.bodyJson['person_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/user/block';

        final response = await client.post(
          path,
          body: {'person_id': userId, 'block': state},
        );

        return DetailedUserModel.fromPiefed(
          response.bodyJson['person_view'] as JsonMap,
          blocked: response.bodyJson['blocked'] as bool? ?? false,
        );
    }
  }

  Future<DetailedUserModel?> updateAvatar(XFile image) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/avatar';

        final request = http.MultipartRequest(
          'POST',
          Uri.https(client.domain, client.software.apiPathPrefix + path),
        );
        final multipartFile = http.MultipartFile.fromBytes(
          'uploadImage',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        final response = await client.sendRequest(request);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const pictrsPath = '/pictrs/image';

        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.https(client.domain, pictrsPath),
        );
        final multipartFile = http.MultipartFile.fromBytes(
          'images[]',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        uploadRequest.files.add(multipartFile);
        final pictrsResponse = await client.sendRequest(uploadRequest);

        final imageName =
            ((pictrsResponse.bodyJson['files'] as List<Object?>).first
                    as JsonMap)['file']
                as String?;

        const path = '/user/save_user_settings';

        final response = await client.put(
          path,
          body: {'avatar': 'https://${client.domain}/pictrs/image/$imageName'},
        );

        return null;

      case ServerSoftware.piefed:
        const uploadPath = '/upload/user_image';

        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.https(client.domain, client.software.apiPathPrefix + uploadPath),
        );
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        uploadRequest.files.add(multipartFile);
        final uploadResponse = await client.sendRequest(uploadRequest);

        final imageUrl = uploadResponse.bodyJson['url'] as String?;

        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'avatar': imageUrl});

        return null;
    }
  }

  Future<DetailedUserModel?> deleteAvatar() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/avatar';
        final response = await client.delete(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'avatar': ''});

        return null;

      case ServerSoftware.piefed:
        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'avatar': ''});

        return null;
    }
  }

  Future<DetailedUserModel?> updateCover(XFile image) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/cover';

        final request = http.MultipartRequest(
          'POST',
          Uri.https(client.domain, client.software.apiPathPrefix + path),
        );
        final multipartFile = http.MultipartFile.fromBytes(
          'uploadImage',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        final response = await client.sendRequest(request);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const pictrsPath = '/pictrs/image';

        final request = http.MultipartRequest(
          'POST',
          Uri.https(client.domain, pictrsPath),
        );
        final multipartFile = http.MultipartFile.fromBytes(
          'images[]',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        request.files.add(multipartFile);
        final pictrsResponse = await client.sendRequest(request);

        final imageName =
            ((pictrsResponse.bodyJson['files'] as List<Object?>).first
                    as JsonMap)['file']
                as String?;

        const path = '/user/save_user_settings';

        final response = await client.put(
          path,
          body: {'banner': 'https://${client.domain}/pictrs/image/$imageName'},
        );

        return null;

      case ServerSoftware.piefed:
        const uploadPath = '/upload/user_image';

        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.https(client.domain, client.software.apiPathPrefix + uploadPath),
        );
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: basename(image.path),
          contentType: MediaType.parse(lookupMimeType(image.path)!),
        );
        uploadRequest.files.add(multipartFile);
        final uploadResponse = await client.sendRequest(uploadRequest);

        final imageUrl = uploadResponse.bodyJson['url'] as String?;

        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'cover': imageUrl});

        return null;
    }
  }

  Future<DetailedUserModel?> deleteCover() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/cover';
        final response = await client.delete(path);

        return DetailedUserModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'banner': ''});

        return null;

      case ServerSoftware.piefed:
        const path = '/user/save_user_settings';

        final response = await client.put(path, body: {'cover': ''});

        return null;
    }
  }

  Future<DetailedUserListModel> listFollowers(
    int userId, {
    String? page,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/followers';
        final query = {'p': page};

        final response = await client.get(path, queryParams: query);

        return DetailedUserListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('User followers not allowed on lemmy');

      case ServerSoftware.piefed:
        throw Exception('User followers not allowed on piefed');
    }
  }

  Future<DetailedUserListModel> listFollowing(
    int userId, {
    String? page,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/users/$userId/followed';
        final query = {'p': page};

        final response = await client.get(path, queryParams: query);

        return DetailedUserListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('List following not allowed on lemmy');

      case ServerSoftware.piefed:
        throw Exception('List following not allowed on piefed');
    }
  }

  Future<UserSettings> getUserSettings() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/settings';
        final response = await client.get(path);

        return UserSettings.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/site';

        final response = await client.get(path);

        return UserSettings.fromLemmy(
          ((response.bodyJson
                  as dynamic)['my_user']['local_user_view']['local_user'])
              as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/site';

        final response = await client.get(path);

        return UserSettings.fromPiefed(
          ((response.bodyJson
                  as dynamic)['my_user']['local_user_view']['local_user'])
              as JsonMap,
        );
    }
  }

  Future<UserSettings> saveUserSettings(UserSettings settings) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/users/settings';
        final response = await client.put(
          path,
          body: {
            'hideAdult': !settings.showNSFW,
            'showSubscribedUsers': settings.showSubscribedUsers,
            'showSubscribedMagazines': settings.showSubscribedCommunities,
            'showSubscribedDomains': settings.showSubscribedDomains,
            'showProfileSubscriptions': settings.showProfileSubscriptions,
            'showProfileFollowings': settings.showProfileFollowings,
            'notifyOnNewEntry': settings.notifyOnNewEntry,
            'notifyOnNewEntryReply': settings.notifyOnNewEntryReply,
            'notifyOnNewEntryCommentReply':
                settings.notifyOnNewEntryCommentReply,
            'notifyOnNewPost': settings.notifyOnNewPost,
            'notifyOnNewPostReply': settings.notifyOnNewPostReply,
            'notifyOnNewPostCommentReply': settings.notifyOnNewPostCommentReply,
          },
        );

        return UserSettings.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/user/save_user_settings';

        final response = await client.put(
          path,
          body: {
            'show_nsfw': settings.showNSFW,
            'blur_nsfw': settings.blurNSFW,
            'show_read_posts': settings.showReadPosts,
          },
        );

        return UserSettings.fromLemmy(
          ((response.bodyJson
                  as dynamic)['my_user']['local_user_view']['local_user'])
              as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/user/save_user_settings';

        final response = await client.put(
          path,
          body: {
            'show_nsfw': settings.showNSFW,
            'show_read_posts': settings.showReadPosts,
          },
        );

        return UserSettings.fromPiefed(
          ((response.bodyJson
                  as dynamic)['my_user']['local_user_view']['local_user'])
              as JsonMap,
        );
    }
  }
}
