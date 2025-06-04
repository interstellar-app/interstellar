import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'server.freezed.dart';
part 'server.g.dart';

enum ServerSoftware {
  mbin,
  lemmy,
  piefed;

  String get apiPathPrefix => switch (this) {
    ServerSoftware.mbin => '/api',
    ServerSoftware.lemmy => '/api/v3',
    ServerSoftware.piefed => '/api/alpha',
  };

  String get title => switch (this) {
    ServerSoftware.mbin => 'Mbin',
    ServerSoftware.lemmy => 'Lemmy',
    ServerSoftware.piefed => 'PieFed',
  };

  Color get color => switch (this) {
    ServerSoftware.mbin => Color(0xff4f2696),
    ServerSoftware.lemmy => Color(0xff03a80e),
    ServerSoftware.piefed => Color(0xff0e6ef9),
  };
}

@freezed
class Server with _$Server {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Server({
    required ServerSoftware software,
    String? oauthIdentifier,
  }) = _Server;

  factory Server.fromJson(JsonMap json) => _$ServerFromJson(json);
}
