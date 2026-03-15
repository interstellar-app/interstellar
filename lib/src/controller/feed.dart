import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'feed.freezed.dart';
part 'feed.g.dart';

@freezed
abstract class FeedInput with _$FeedInput {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory FeedInput({
    required String name,
    required FeedSource sourceType,
    int? serverId,
  }) = _FeedInput;
  const FeedInput._();

  factory FeedInput.fromJson(JsonMap json) => _$FeedInputFromJson(json);
}

@freezed
abstract class Feed with _$Feed {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Feed({
    required Set<FeedInput> inputs,
    required bool server,
    required String? owner,
  }) = _Feed;
  const Feed._();

  factory Feed.fromJson(JsonMap json) => _$FeedFromJson(json);

  factory Feed.fromModel(FeedModel feed, String instanceHost) {
    return Feed(
      inputs: feed.communities
          .map(
            (community) => FeedInput(
              name: normalizeName(community.name, instanceHost),
              sourceType: FeedSource.community,
              serverId: community.id,
            ),
          )
          .toSet(),
      server: true,
      owner: null,
    );
  }

  bool get clientFeed {
    return !serverFeed;
  }

  bool get serverFeed {
    return server;
    // return inputs.every(
    //   (input) =>
    //       input.sourceType == FeedSource.feed ||
    //       input.sourceType == FeedSource.topic,
    // );
  }
}
