import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/utils/utils.dart';

class APICommunityModeration {
  final ServerClient client;

  APICommunityModeration(this.client);

  Future<CommunityBanListModel> listBans(
    int communityId, {
    String? page,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId/bans';
        final query = {'p': page};

        final response = await client.get(path, queryParams: query);

        return CommunityBanListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('List banned users not allowed on lemmy');

      case ServerSoftware.piefed:
        final path = '/community/moderate/bans';

        final page_ = page ?? 1;

        final query = {
          'community_id': communityId.toString(),
          'page': page_.toString(),
        };

        final response = await client.get(path, queryParams: query);

        return CommunityBanListModel.fromPiefed(response.bodyJson);
    }
  }

  Future<CommunityBanModel> createBan(
    int communityId,
    int userId, {
    String? reason,
    DateTime? expiredAt,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId/ban/$userId';

        final response = await client.post(
          path,
          body: {'reason': reason, 'expiredAt': expiredAt?.toIso8601String()},
        );

        return CommunityBanModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Ban update not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        final path = '/community/moderate/ban';
        final body = {
          'community_id': communityId,
          'user_id': userId,
          'reason': reason,
          'expiredAt': expiredAt?.toIso8601String(),
        };

        final response = await client.post(path, body: body);

        return CommunityBanModel.fromPiefed(response.bodyJson);
    }
  }

  Future<CommunityBanModel> removeBan(int communityId, int userId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId/ban/$userId';

        final response = await client.delete(path);

        return CommunityBanModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Ban update not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        final path = '/community/moderate/unban';

        final body = {'community_id': communityId, 'user_id': userId};

        final response = await client.put(path, body: body);

        return CommunityBanModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedCommunityModel> create({
    required String name,
    required String title,
    required String description,
    required bool isAdult,
    required bool isPostingRestrictedToMods,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/new';

        final response = await client.post(
          path,
          body: {
            'name': name,
            'title': title,
            'description': description,
            'isAdult': isAdult,
            'isPostingRestrictedToMods': isPostingRestrictedToMods,
          },
        );

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community';

        final response = await client.post(
          path,
          body: {
            'name': name,
            'title': title,
            'description': description,
            'nsfw': isAdult,
            'posting_restricted_to_mods': isPostingRestrictedToMods,
          },
        );

        return DetailedCommunityModel.fromLemmy(
          response.bodyJson['community_view'] as JsonMap,
        );

      case ServerSoftware.piefed:
        const path = '/community';

        final response = await client.post(
          path,
          body: {
            'name': name,
            'title': title,
            'description': description,
            'nsfw': isAdult,
            'restricted_to_mods': isPostingRestrictedToMods,
          },
        );

        return DetailedCommunityModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedCommunityModel> edit(
    int communityId, {
    required String title,
    required String description,
    required bool isAdult,
    required bool isPostingRestrictedToMods,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId';

        final response = await client.put(
          path,
          body: {
            'title': title,
            'description': description,
            'isAdult': isAdult,
            'isPostingRestrictedToMods': isPostingRestrictedToMods,
          },
        );

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Community edit not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        const path = '/community';

        final response = await client.put(
          path,
          body: {
            'community_id': communityId,
            'title': title,
            'description': description,
            'nsfw': isAdult,
            'restricted_to_mods': isPostingRestrictedToMods,
          },
        );

        return DetailedCommunityModel.fromPiefed(response.bodyJson);
    }
  }

  Future<DetailedCommunityModel> updateModerator(
    int communityId,
    int userId,
    bool state,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId/mod/$userId';

        final response = state
            ? await client.post(path)
            : await client.delete(path);

        return DetailedCommunityModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Moderator update not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<void> removeIcon(int communityId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId/icon';

        final response = await client.delete(path);

        return;

      case ServerSoftware.lemmy:
        throw Exception('Remove icon not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        const path = '/community';

        final response = await client.put(path, body: {'icon_url': ''});

        return;
    }
  }

  Future<void> delete(int communityId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$communityId';

        final response = await client.delete(path);

        return;

      case ServerSoftware.lemmy:
        throw Exception('Community delete not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        const path = '/community/delete';

        final response = await client.post(
          path,
          body: {'community_id': communityId, 'deleted': true},
        );
    }
  }
}
