import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'feed.freezed.dart';
part 'feed.g.dart';

@freezed
class FeedInput with _$FeedInput {
  const FeedInput._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory FeedInput({
    required String name,
    required FeedSource sourceType,
  }) = _FeedInput;

  factory FeedInput.fromJson(JsonMap json) => _$FeedInputFromJson(json);
}

@freezed
class Feed with _$Feed {
  const Feed._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Feed({
    required String name,
    required Set<FeedInput> inputs,
  }) = _Feed;

  factory Feed.fromJson(JsonMap json) => _$FeedFromJson(json);
}