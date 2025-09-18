import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:sembast/sembast_io.dart';

part 'drafts_controller.freezed.dart';
part 'drafts_controller.g.dart';

@freezed
abstract class Draft with _$Draft {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Draft({
    required DateTime at,
    required String body,
    String? resourceId,
  }) = _Draft;

  factory Draft.fromJson(JsonMap json) => _$DraftFromJson(json);
}

class DraftAutoController {
  final Draft? Function() read;
  final Future<void> Function(String body) save;
  final Future<void> Function() discard;

  const DraftAutoController({
    required this.read,
    required this.save,
    required this.discard,
  });
}

class DraftsController with ChangeNotifier {
  final _draftsStore = StoreRef<int, JsonMap>('draft');

  List<Draft> _drafts = [];
  List<Draft> get drafts => _drafts;

  DraftsController() {
    _init();
  }

  Future<void> _init() async {
    _drafts = (await _draftsStore.find(
      db,
    )).map((record) => Draft.fromJson(record.value)).toList();

    notifyListeners();
  }

  DraftAutoController auto(String resourceId) {
    return DraftAutoController(
      read: () {
        for (var draft in _drafts) {
          if (draft.resourceId == resourceId) return draft;
        }

        return null;
      },
      save: (body) async {
        _removeByResourceId(resourceId);

        final draft = Draft(
          at: DateTime.now(),
          body: body,
          resourceId: resourceId,
        );

        drafts.add(draft);

        notifyListeners();
        await _draftsStore.add(db, draft.toJson());
      },
      discard: () async {
        _removeByResourceId(resourceId);

        notifyListeners();
      },
    );
  }

  Draft? readByDate(DateTime at) {
    for (var draft in _drafts) {
      if (draft.at == at) return draft;
    }

    return null;
  }

  Future<void> manualSave(String body) async {
    final draft = Draft(at: DateTime.now(), body: body);

    drafts.add(draft);

    notifyListeners();
    await _draftsStore.add(db, draft.toJson());
  }

  Future<void> _removeByResourceId(String resourceId) async {
    drafts.removeWhere((draft) => draft.resourceId == resourceId);

    await _draftsStore.delete(
      db,
      finder: Finder(filter: Filter.equals('resourceId', resourceId)),
    );
  }

  Future<void> _removeByDate(DateTime at) async {
    drafts.removeWhere((draft) => draft.at == at);

    await _draftsStore.delete(
      db,
      finder: Finder(filter: Filter.equals('at', at.toIso8601String())),
    );
  }

  Future<void> removeByDate(DateTime at) async {
    _removeByDate(at);

    notifyListeners();
  }

  Future<void> removeAll() async {
    drafts.clear();

    notifyListeners();
    await _draftsStore.drop(db);
  }
}
