import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/database/database.dart';
import 'package:drift/drift.dart';

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
  List<Draft> _drafts = [];
  List<Draft> get drafts => _drafts;

  DraftsController() {
    _init();
  }

  Future<void> _init() async {
    _drafts = await database.select(database.drafts).get();

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

        final draft = await database
            .into(database.drafts)
            .insertReturning(
              DraftsCompanion.insert(
                body: body,
                resourceId: Value(resourceId),
                at: Value(DateTime.now()),
              ),
            );

        drafts.add(draft);

        notifyListeners();
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
    final draft = await database
        .into(database.drafts)
        .insertReturning(
          DraftsCompanion.insert(body: body, at: Value(DateTime.now())),
        );

    drafts.add(draft);

    notifyListeners();
  }

  Future<void> _removeByResourceId(String resourceId) async {
    drafts.removeWhere((draft) => draft.resourceId == resourceId);

    await (database.delete(
      database.drafts,
    )..where((f) => f.resourceId.equals(resourceId))).go();
  }

  Future<void> _removeByDate(DateTime at) async {
    drafts.removeWhere((draft) => draft.at == at);
    await (database.delete(
      database.drafts,
    )..where((f) => f.at.equals(at))).go();
  }

  Future<void> removeByDate(DateTime at) async {
    _removeByDate(at);

    notifyListeners();
  }

  Future<void> removeAll() async {
    drafts.clear();
    await database.delete(database.drafts).go();

    notifyListeners();
  }
}
