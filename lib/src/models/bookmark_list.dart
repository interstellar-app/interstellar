import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'bookmark_list.freezed.dart';

@freezed
abstract class BookmarkListListModel with _$BookmarkListListModel {
  const factory BookmarkListListModel({
    required List<BookmarkListModel> items,
  }) = _BookmarkListListModel;

  factory BookmarkListListModel.fromMbin(JsonMap json) => BookmarkListListModel(
    items: (json['items']! as List<dynamic>)
        .map((post) => BookmarkListModel.fromMbin(post as JsonMap))
        .toList(),
  );
}

@freezed
abstract class BookmarkListModel with _$BookmarkListModel {
  const factory BookmarkListModel({
    required String name,
    required bool isDefault,
    required int count,
  }) = _BookmarkListModel;

  factory BookmarkListModel.fromMbin(JsonMap json) => BookmarkListModel(
    name: json['name']! as String,
    isDefault: json['isDefault']! as bool,
    count: json['count']! as int,
  );
}
