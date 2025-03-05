import 'dart:convert';

import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/magazine.dart';

class APIMagazineModeration {
  final ServerClient client;

  APIMagazineModeration(this.client);

  Future<MagazineBanListModel> listBans(
    int magazineId, {
    String? page,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId/bans';
        final query = {'p': page};

        final response =
            await client.send(HttpMethod.get, path, queryParams: query);

        return MagazineBanListModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('List banned users not allowed on lemmy');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<MagazineBanModel> createBan(
    int magazineId,
    int userId, {
    String? reason,
    DateTime? expiredAt,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId/ban/$userId';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'reason': reason,
            'expiredAt': expiredAt?.toIso8601String(),
          },
        );

        return MagazineBanModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Ban update not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<MagazineBanModel> removeBan(int magazineId, int userId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId/ban/$userId';

        final response = await client.send(HttpMethod.delete, path);

        return MagazineBanModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Ban update not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<DetailedMagazineModel> create({
    required String name,
    required String title,
    required String description,
    required bool isAdult,
    required bool isPostingRestrictedToMods,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/new';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'name': name,
            'title': title,
            'description': description,
            'isAdult': isAdult,
            'isPostingRestrictedToMods': isPostingRestrictedToMods,
          },
        );

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        const path = '/community';

        final response = await client.send(
          HttpMethod.post,
          path,
          body: {
            'name': name,
            'title': title,
            'description': description,
            'nsfw': isAdult,
            'posting_restricted_to_mods': isPostingRestrictedToMods,
          },
        );

        return DetailedMagazineModel.fromLemmy(
            response.bodyJson['community_view'] as Map<String, Object?>);

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<DetailedMagazineModel> edit(
    int magazineId, {
    required String title,
    required String description,
    required bool isAdult,
    required bool isPostingRestrictedToMods,
  }) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId';

        final response = await client.send(
          HttpMethod.put,
          path,
          body: {
            'title': title,
            'description': description,
            'isAdult': isAdult,
            'isPostingRestrictedToMods': isPostingRestrictedToMods,
          },
        );

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Magazine edit not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<DetailedMagazineModel> updateModerator(
    int magazineId,
    int userId,
    bool state,
  ) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId/mod/$userId';

        final response = await client.send(
            state ? HttpMethod.post : HttpMethod.delete, path);

        return DetailedMagazineModel.fromMbin(response.bodyJson);

      case ServerSoftware.lemmy:
        throw Exception('Moderator update not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<void> removeIcon(int magazineId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId/icon';

        final response = await client.send(HttpMethod.delete, path);

        return;

      case ServerSoftware.lemmy:
        throw Exception('Remove icon not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }

  Future<void> delete(int magazineId) async {
    switch (client.software) {
      case ServerSoftware.mbin:
        final path = '/moderate/magazine/$magazineId';

        final response = await client.send(HttpMethod.delete, path);

        return;

      case ServerSoftware.lemmy:
        throw Exception('Magazine delete not implemented on Lemmy yet');

      case ServerSoftware.piefed:
        throw UnimplementedError();
    }
  }
}
