import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'feed.freezed.dart';
part 'feed.g.dart';

@freezed
abstract class FeedInput with _$FeedInput {
  const FeedInput._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory FeedInput({
    required String name,
    required FeedSource sourceType,
    int? serverId,
  }) = _FeedInput;

  factory FeedInput.fromJson(JsonMap json) => _$FeedInputFromJson(json);
}

@freezed
abstract class Feed with _$Feed {
  const Feed._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Feed({required Set<FeedInput> inputs}) = _Feed;

  factory Feed.fromJson(JsonMap json) => _$FeedFromJson(json);

  bool get clientFeed {
    return !serverFeed;
  }

  bool get serverFeed {
    return inputs.every(
      (input) =>
          input.sourceType == FeedSource.feed ||
          input.sourceType == FeedSource.topic,
    );
  }
}
