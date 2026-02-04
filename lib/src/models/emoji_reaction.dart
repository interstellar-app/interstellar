import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'emoji_reaction.freezed.dart';

@freezed
abstract class EmojiReactionModel with _$EmojiReactionModel {
  const factory EmojiReactionModel({
    required List<String> authors,
    required int count,
    required String token,
    required String url,
  }) = _EmojiReactionModel;

  factory EmojiReactionModel.fromPieFed(JsonMap json) => EmojiReactionModel(
    authors: (json['authors']! as List<dynamic>).cast<String>(),
    count: json['count']! as int,
    token: json['token']! as String,
    url: json['url']! as String,
  );
}
